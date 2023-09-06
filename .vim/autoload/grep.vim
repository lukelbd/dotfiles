"-----------------------------------------------------------------------------"
" Utilities for grepping
"-----------------------------------------------------------------------------"
" Parse grep args and translate regex indicators
" Warning: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! s:parse_paths(level, ...)
  if a:0  " search input paths
    let paths = copy(a:000)
  elseif a:level > 1  " search current file only
    let paths = [@%]
  elseif a:level > 0  " search current file directory
    let paths = [expand('%:h')]
  else  " search current file project (file directory returned if no projects found)
    let paths = [tag#find_root(@%)]
  endif
  return map(paths, "fnamemodify(v:val, ':~:.')")
endfunction
function! s:parse_grep(pattern)
  let regex = fzf#shellescape(a:pattern)  " similar to native but handles other shells
  let regex = substitute(regex, '\\[cCvV]', '', 'g')  " unsure how to translate
  let regex = substitute(regex, '\\[<>]', '\\b', 'g')  " translate word borders
  let regex = substitute(regex, '\\S', "[^ \t]", 'g')  " non-whitespace characters
  let regex = substitute(regex, '\\s', "[ \t]",  'g')  " whitespace characters
  let regex = substitute(regex, '\\[ikf]', '\\w', 'g')  " keyword, identifier, filename
  let regex = substitute(regex, '\\[IKF]', '[a-zA-Z_]', 'g')  " same but no numbers
  let regex = substitute(regex, '\\\([(|)]\)', '\2', 'g')  " un-escape grouping indicators
  let regex = substitute(regex, '\([(|)]\)', '\\\1', 'g')  " escape literal parentheses
  return regex
endfunction
function! s:parse_input(level, pattern, ...) abort
  let @/ = a:pattern  " set as the previous search
  let flags = ''  " additional pattern-dependent flags
  let flags .= a:pattern =~# '\\c' ? ' --ignore-case' : ''  " same in ag and rg
  let flags .= a:pattern =~# '\\C' ? ' --case-sensitive' : ''  " same in ag and rg
  let flags = empty(flags) ? '--smart-case' : trim(flags)
  let regex = s:parse_grep(a:pattern)
  let paths = call('s:parse_paths', [a:level] + a:000)
  call add(paths, 'dummy.fzf')  " fix bug described above
  return [regex . ' ' . join(paths, ' '), flags]
endfunction

" Call Ag or Rg from command
" Todo: Only use search pattern? https://github.com/junegunn/fzf.vim/issues/346
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! grep#call_ag(bang, level, depth, ...) abort
  let flags = '--path-to-ignore ~/.ignore --path-to-ignore ~/.wildignore --skip-vcs-ignores --hidden'
  let [cmd, extra] = call('s:parse_input', [a:level] + a:000)
  let extra .= a:depth ? ' --depth ' . (a:depth - 1) : ''
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(join([flags, extra, '--', cmd], ' '), opts, a:bang)  " bang uses fullscreen
endfunction
function! grep#call_rg(bang, level, depth, ...) abort
  let flags = '--ignore-file ~/.ignore --ignore-file ~/.wildignore --no-ignore-vcs --hidden'
  let [cmd, extra] = call('s:parse_input', [a:level] + a:000)
  let extra .= a:depth ? ' --max-depth ' . a:depth : ''
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  let head = 'rg --column --line-number --no-heading --color=always'
  call fzf#vim#grep(join([head, flags, '--', cmd], ' '), opts, a:bang)  " bang uses fullscreen
endfunction

" Call Rg or Ag from mapping (see also file.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
" let prompt = a:level > 1 ? 'Current file' : a:level > 0 ? 'File directory' : 'Working directory'
function! grep#complete_pattern(lead, line, cursor)
  let opts = execute('history search')
  let opts = substitute(opts, '\n\@<=>\?\s*[0-9]*\s*\([^\n]*\)\(\n\|$\)\@=', '\1', 'g')
  let opts = split(opts, '\n')
  let opts = filter(opts, 'empty(a:lead) || v:val[:len(a:lead) - 1] ==# a:lead')
  return reverse([@/] + opts[1:])
endfunction
function! grep#call_grep(grep, level, depth) abort
  let prompt = s:parse_paths(a:level)[0]
  let prompt = toupper(a:grep[0]) . a:grep[1:] . ' search ' . prompt . ' (' . @/ . ')'
  let pattern = utils#input_complete(prompt, 'grep#complete_pattern', @/)
  if empty(pattern) | return | endif
  let func = 'grep#call_' . tolower(a:grep)
  call call(func, [0, a:level, a:depth, pattern])
endfunction
