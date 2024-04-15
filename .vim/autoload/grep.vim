"-----------------------------------------------------------------------------"
" Utilities for grepping
"-----------------------------------------------------------------------------"
" Helper function for parsing paths
" Note: If input directory is getcwd() then fnamemodify(getcwd(), ':~:.') returns
" only home directory shortened path (not dot or empty string). To match RelatvePath()
" and simplify grep results convert to empty string.
function! s:parse_paths(prompt, global, level, ...)
  let input = filter(copy(a:000), '!empty(v:val)')
  if !empty(input)  " manual input
    let paths = map(input, 'resolve(v:val)')
  elseif a:global  " global buffers
    let paths = map(reverse(tags#buffer_paths()), 'resolve(v:val[1])')
  else  " current buffer
    let paths = [resolve(expand('%:p'))]
  endif
  if empty(input) && a:level >= 2  " path projects
    let paths = map(paths, 'tag#find_root(v:val)')
  elseif empty(input) && a:level >= 1  " path folders
    let paths = map(paths, "empty(v:val) || isdirectory(v:val) ? v:val : fnamemodify(v:val, ':h')")
  else  " general paths and folders
    let paths = filter(paths, 'isdirectory(v:val) || filereadable(v:val)')
  endif
  let result = []
  let unique = 'index(paths, v:val, v:key + 1) == -1'
  let outer = 'len(v:val) < len(path) && strpart(path, 0, len(v:val)) ==# v:val'
  for path in filter(copy(paths), unique)  " unique
    if a:level > 2 && !empty(filter(copy(paths), outer))
      continue  " e.g. ignore plugged repos when searching dotfiles
    endif
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
  let args = [0, a:global, a:level] + a:000
  let regex = s:parse_pattern(a:pattern)
  let paths = call('s:parse_paths', args)
  let paths = empty(paths) ? paths : add(paths, 'dummy.fzf')  " fix bug described above
  return [regex, join(paths, ' '), flags]
endfunction
function! s:parse_pattern(pattern)
  let regex = substitute(a:pattern, '\\%\([$^]\)', '\1', 'g')  " file border to line border
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
  let regex = substitute(regex, '@\([(|)]\)', '\1', 'g')  " unmark grouping parentheses
  return fzf#shellescape(regex)  " similar to native but handles other shells
endfunction

" Call Ag or Rg from command
" Note: If commands called manually then always enable recursive search and disable
" custom '~/.ignore' file (e.g. in case want to search a .vim/plugged folder).
" Note: Both commands respect .gitignore by default and auto-read 'ignore' if in same
" directory e.g. dotfiles. Can disable .gitignore with --skip-vcs-ignores (ag) and
" --no-ignore-vcs (rg) but for now only use universal ignore-disabling options.
" Note: Native commands include final !a:bang argument toggling fullscreen but we
" use a:bang to indicate whether to search current buffer or global open buffers.
" Fzf matches paths: https://github.com/junegunn/fzf.vim/issues/346
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! grep#call_ag(global, level, pattern, ...) abort
  let flags = '--hidden --path-to-ignore ~/.wildignore'
  let flags .= a:0 || a:level > 2 ? ' --unrestricted' : ' --path-to-ignore ~/.ignore'
  let flags .= a:0 || a:level > 1 ? '' : ' --depth 0'  " files or file folders
  let args = [a:global, a:level, a:pattern] + a:000
  let [regex, paths, extra] = call('s:parse_grep', args)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(join([flags, extra, '--', regex, paths], ' '), opts, 0)  " 0 is no fullscreen
  redraw | echom 'Ag ' . regex . ' (level ' . a:level . ')'
endfunction
function! grep#call_rg(global, level, pattern, ...) abort
  let flags = '--hidden --ignore-file ~/.wildignore'
  let flags .= a:0 || a:level > 2 ? ' --no-ignore' : ' --ignore-file ~/.ignore'
  let flags .= a:0 || a:level > 1 ? '' : ' --max-depth 1'  " files or file folders
  let args = [a:global, a:level, a:pattern] + a:000
  let [regex, paths, extra] = call('s:parse_grep', args)
  let opts = fzf#vim#with_preview()
  let head = 'rg --column --line-number --no-heading --color=always'
  call fzf#vim#grep(join([head, flags, '--', regex, paths], ' '), opts, 0)  " 0 is no fullscreen
  redraw | echom 'Rg ' . regex . ' (level ' . a:level . ')'
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
  if a:level >= 3
    let name = 'file tree'
  elseif a:level >= 2
    let name = 'open project'
  elseif a:level >= 1
    let name = 'file folder'
  else
    let name = 'open buffer'
  endif
  if a:global && len(paths) > 1  " open files or folders across session
    let prompt = len(paths) . ' ' . name . 's'
  elseif len(paths) != 1  " multiple objects
    let prompt = name . 's ' . join(paths, ' ')
  else  " current or input files or folders
    let prompt = name . ' ' . paths[0]
  endi
  let prompt = toupper(a:cmd[0]) . a:cmd[1:] . ' search ' . prompt
  let regex = utils#input_default(prompt, @/, 'grep#complete_search')
  if empty(regex) | return | endif
  let args = [a:global, a:level, regex]
  call call('grep#call_' . tolower(a:cmd), args)
endfunction
