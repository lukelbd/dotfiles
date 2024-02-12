"-----------------------------------------------------------------------------"
" Utilities for grepping
"-----------------------------------------------------------------------------"
" Helper function for parsing paths
" Note: If input directory is getcwd() then fnamemodify(getcwd(), ':~:.') returns
" only home directory shortened path (not dot or empty string). To match RelatvePath()
" and simplify grep results convert to empty string.
function! s:parse_paths(prompt, global, level, ...)
  if a:0  " input paths
    let paths = map(copy(a:000), 'resolve(v:val)')
  elseif a:global  " global buffers
    let paths = map(window#buffer_sort(tags#buffer_paths()), 'resolve(v:val)')
  else  " current buffer
    let paths = [resolve(@%)]
  endif
  if a:0 || a:level <= 0  " input paths and folders
    let paths = filter(paths, 'isdirectory(v:val) || filereadable(v:val)')
  elseif a:level <= 1  " input path folders
    let paths = map(paths, "empty(v:val) || isdirectory(v:val) ? v:val : fnamemodify(v:val, ':h')")
  else  " input path projects
    let paths = map(paths, 'tag#find_root(v:val)')
  endif
  let result = []
  for path in filter(copy(paths), 'index(paths, v:val, v:key + 1) == -1')  " unique
    if exists('*RelativePath')  " returns empty string for getcwd()
      let path = RelativePath(path)
    else  " returns e.g. ~/dotfiles for getcwd()
      let path = getcwd() ==# fnamemodify(path, ':p') ? '' : fnamemodify(path, ':~:.')
    endif
    if empty(path) && (a:prompt || len(paths) > 1)
      let path = './'  " trailing slash as with other folders
    endif
    if !empty(path)  " otherwise return empty list
      call add(result, path)
    endif
  endfor
  return result
endfunction

" Helper functions for parsing grep input
" Warning: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! s:parse_grep(global, level, pattern, ...) abort
  let @/ = a:pattern  " set as the previous search
  let flags = ''  " additional pattern-dependent flags
  let flags .= a:pattern =~# '\\c' ? ' --ignore-case' : ''  " same in ag and rg
  let flags .= a:pattern =~# '\\C' ? ' --case-sensitive' : ''  " same in ag and rg
  let flags = empty(flags) ? '--smart-case' : trim(flags)
  let regex = s:parse_pattern(a:pattern)
  let paths = call('s:parse_paths', [0, a:global, a:level] + a:000)
  let paths = empty(paths) ? paths : add(paths, 'dummy.fzf')  " fix bug described above
  return [regex, join(paths, ' '), flags]
endfunction
function! s:parse_pattern(pattern)
  let regex = fzf#shellescape(a:pattern)  " similar to native but handles other shells
  let regex = substitute(regex, '\\%\([$^]\)', '\1', 'g')  " file border to line border
  let regex = substitute(regex, '\\%\([#V]\|[<>]\?''m\)', '', 'g')  " ignore markers
  let regex = substitute(regex, '\\%[<>]\?\(\.\|[0-9]\+\)[lcv]', '', 'g')  " ignore ranges
  let regex = substitute(regex, '\\[<>]', '\\b', 'g')  " sided word border to unsided
  let regex = substitute(regex, '\\[cvCV]', '', 'g')  " ignore case and magic markers
  let regex = substitute(regex, '\C\\S', "[^ \t]", 'g')  " non-whitespace characters
  let regex = substitute(regex, '\C\\s', "[ \t]",  'g')  " whitespace characters
  let regex = substitute(regex, '\C\\[IKF]', '[a-zA-Z_]', 'g')  " letters underscore
  let regex = substitute(regex, '\C\\[ikf]', '\\w', 'g')  " numbers letters underscore
  let regex = substitute(regex, '\\%\?\([(|)]\)', '@\1', 'g')  " mark grouping parentheses
  let regex = substitute(regex, '\(^\|[^@\\]\)\([(|)]\)', '\1\\\2', 'g')  " escape parentheses
  return substitute(regex, '@\([(|)]\)', '\1', 'g')  " unmark grouping parentheses
endfunction

" Call Ag or Rg from command
" Note: If commands called manually then always enable recursive search and disable
" custom '~/.ignore' file (e.g. in case want to search a .vim/plugged folder).
" Note: Native commands include final !a:bang argument toggling fullscreen but we
" use a:bang to indicate whether to search current buffer or global open buffers.
" Note: Use 'timer_start' to prevent issue where echom is hidden by fzf panel creation
" Delayed function calls: https://vi.stackexchange.com/a/27032/8084
" Fzf matches paths: https://github.com/junegunn/fzf.vim/issues/346
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! s:echo_grep(regex, ...) abort
  echom 'Grep ' . a:regex
endfunction
function! grep#call_ag(global, level, ...) abort
  let flags = '--hidden --path-to-ignore ~/.wildignore'
  let flags .= a:0 > 1 ? '' : ' --path-to-ignore ~/.ignore --skip-vcs-ignores'
  let flags .= a:0 > 1 || a:level > 1 ? '' : ' --depth 0'  " files or file folders
  let [regex, paths, extra] = call('s:parse_grep', [a:global, a:level] + a:000)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(join([flags, extra, '--', regex, paths], ' '), opts, 0)  " 0 is no fullscreen
  call timer_start(1, function('s:echo_grep', [regex]))
endfunction
function! grep#call_rg(global, level, ...) abort
  let flags = '--hidden --ignore-file ~/.wildignore'
  let flags .= a:0 > 1 ? '' : ' --ignore-file ~/.ignore --no-ignore-vcs'
  let flags .= a:0 > 1 || a:level > 1 ? '' : ' --max-depth 1'  " files or file folders
  let [regex, paths, extra] = call('s:parse_grep', [a:global, a:level] + a:000)
  let opts = fzf#vim#with_preview()
  let head = 'rg --column --line-number --no-heading --color=always'
  call fzf#vim#grep(join([head, flags, '--', regex, paths], ' '), opts, 0)  " 0 is no fullscreen
  call timer_start(1, function('s:echo_grep', [regex]))
endfunction

" Call Rg or Ag from mapping (see also file.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
" let prompt = a:level > 1 ? 'Current file' : a:level > 0 ? 'File directory' : 'Working directory'
function! grep#complete_search(lead, line, cursor)
  let regex = '\n\@<=>\?\s*[0-9]*\s*\([^\n]*\)\(\n\|$\)\@='
  let match = 'empty(a:lead) || v:val[:len(a:lead) - 1] ==# a:lead'
  let opts = execute('history search')  " remove number prompt
  let opts = substitute(opts, regex, '\1', 'g')
  let opts = split(opts, '\n')
  let opts = filter(opts, match)  " match to user input
  return reverse([@/] + opts[1:])
endfunction
function! grep#call_grep(cmd, global, level) abort
  let paths = s:parse_paths(1, a:global, a:level)
  let name = a:level >= 2 ? 'projects' : a:level >= 1 ? 'folders' : 'buffers'
  if a:global && len(paths) > 1  " open files or folders across session
    let prompt = len(paths) . ' open ' . name
  else  " current or input files or folders
    let prompt = join(paths, ' ')
  endif
  let prompt = toupper(a:cmd[0]) . a:cmd[1:] . ' search ' . prompt
  let pattern = utils#input_default(prompt, 'grep#complete_search', @/)
  if empty(pattern) | return | endif
  let func = 'grep#call_' . tolower(a:cmd)
  call call(func, [a:global, a:level, pattern])
endfunction
