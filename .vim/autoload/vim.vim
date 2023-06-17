"-----------------------------------------------------------------------------"
" Utilities for sourcing vimscript
"-----------------------------------------------------------------------------"
" Source file or lines
" Note: Compare to python#run_content()
function! vim#source_content() abort
  if v:count
    echom 'Sourcing ' . v:count . ' lines'
    let lines = getline(line('.'), line('.') + v:count)
    exe join(lines, "\n")
  else
    echo "Sourcing '" . expand('%:p:t') . "'"
    update
    source %
  endif
endfunction

" Source input motion
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! vim#source_motion() range abort
  update
  echom 'Sourcing lines ' . a:firstline . ' to ' . a:lastline
  let lines = getline(a:firstline, a:lastline)
  exe join(lines, "\n")
endfunction
" For <expr> map accepting motion
function! vim#source_motion_expr(...) abort
  return utils#motion_func('vim#source_motion', a:000)
endfunction

" Refresh all other settings
" let files = substitute(files, '\(^\|\n\@<=\)\s*\d*:\s*\(.*\)\($\|\n\@=\)', '\2', 'g')
function! vim#refresh_config(...) abort
  filetype detect  " in case started with empty file and shebang changes this
  if !exists('g:refresh_times') | let g:refresh_times = {} | endif  " filetype specific
  let time = get(g:refresh_times, &filetype, g:refresh_times[''])
  let regexes = [
    \ '/.fzf/',
    \ '/plugged/',
    \ '/ftdetect/',
    \ '/\.\?vimsession*',
    \ '/\.\?vim/autoload/vim.vim',
    \ '/\(micro\|mini\|mamba\)\(forge\|conda\|mamba\)\d\?/'
    \ ]
  let regex = '\(' . join(regexes, '\|') . '\)'
  let paths = split(execute('scriptnames'), "\n")  " load order, distinct from &rtp
  let loaded = []
  for path in paths
    let path = substitute(path, '^\s*\d*:\s*\(.*\)$', '\1', 'g')
    let path = resolve(expand(path))  " then compare to home
    if path !~# expand('~')
      continue  " skip files outside of home
    endif
    if path =~# regex
      continue  " skip externally sourced files
    endif
    if a:0 && path !~# a:1
      continue  " skip files not matching input regex
    endif
    if path =~# '/ftplugin/' && path !~# '/' . &filetype . '.vim'
      continue  " only refresh current filetype
    endif
    if index(loaded, path) != -1
      continue  " already loaded this
    endif
    if path =~# '\(.vimrc\|init.vim\)'  " always load and trigger filetypes here
      doautocmd Filetype
    elseif getftime(path) < time
      continue  " skip others if not outdated
    endif
    exe 'so ' . path
    call add(loaded, path)
  endfor
  doautocmd BufEnter
  echom 'Loaded: ' . join(map(loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ') . '.'
  let g:refresh_times[&filetype] = localtime()
endfunction
