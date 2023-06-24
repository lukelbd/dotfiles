"-----------------------------------------------------------------------------"
" Utilities for grepping
"-----------------------------------------------------------------------------"
" Call Rg or Ag grep commands (see also file.vim)
" Note: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! grep#call_grep(grep, level, depth) abort
  let prompt = a:level > 1 ? 'Current file' : a:level > 0 ? 'File directory' : 'Working directory'
  let prompt = prompt . ' ' . toupper(a:grep[0]) . a:grep[1:] . ' pattern'
  let search = utils#input_complete(prompt, 'grep#pattern_list', @/)
  if empty(search) | return | endif
  let func = 'grep#call_' . tolower(a:grep)
  call call(func, [0, a:level, a:depth, search])
endfunction
function! grep#pattern_list(lead, list, cursor)
  let opts = execute('history search')
  let opts = substitute(opts, '\n\@<=>\?\s*[0-9]*\s*\([^\n]*\)\(\n\|$\)\@=', '\1', 'g')
  let opts = split(opts, '\n')
  let opts = filter(opts, 'empty(a:lead) || v:val[:len(a:lead) - 1] ==# a:lead')
  return reverse([@/] + opts[1:])
endfunction

" Individual grep commands
" Todo: Only use search pattern? https://github.com/junegunn/fzf.vim/issues/346
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! grep#call_ag(bang, level, depth, ...) abort
  let flags = '--path-to-ignore ~/.ignore --path-to-ignore ~/.wildignore --skip-vcs-ignores --hidden'
  let [cmd, extra] = call('grep#parse_args', [a:level] + a:000)
  let extra .= a:depth ? ' --depth ' . (a:depth - 1) : ''
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(join([flags, extra, '--', cmd], ' '), opts, a:bang)  " bang uses fullscreen
endfunction
function! grep#call_rg(bang, level, depth, ...) abort
  let flags = '--ignore-file ~/.ignore --ignore-file ~/.wildignore --no-ignore-vcs --hidden'
  let [cmd, extra] = call('grep#parse_args', [a:level] + a:000)
  let extra .= a:depth ? ' --max-depth ' . a:depth : ''
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  let head = 'rg --column --line-number --no-heading --color=always'
  call fzf#vim#grep(join([head, flags, '--', cmd], ' '), opts, a:bang)  " bang uses fullscreen
endfunction

" Parse grep args and translate regex indicators
" Warning: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! s:parse_pattern(search)
  let regex = fzf#shellescape(a:search)  " similar to native but handles other shells
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
function! grep#parse_args(level, search, ...) abort
  let @/ = a:search  " set as the previous search
  let flags = ''  " additional pattern-dependent flags
  let flags .= a:search =~# '\\c' ? ' --ignore-case' : ''  " same in ag and rg
  let flags .= a:search =~# '\\C' ? ' --case-sensitive' : ''  " same in ag and rg
  let flags = empty(flags) ? '--smart-case' : trim(flags)
  let regex = s:parse_pattern(a:search)
  let paths = [a:level > 1 ? @% : a:level > 0 ? expand('%:h') : getcwd()]
  let paths = a:0 ? a:000 : paths
  let paths = map(paths, "fnamemodify(v:val, ':~:.')")
  call add(paths, 'dummy.fzf')  " fix bug described above
  return [regex . ' ' . join(paths, ' '), flags]
endfunction
