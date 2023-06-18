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

" Refresh recently modified configuration files
" Note: This also tracks filetypes outside of current one and queues the
" update until next time function is called from within that filetype.
" let files = substitute(files, '\(^\|\n\@<=\)\s*\d*:\s*\(.*\)\($\|\n\@=\)', '\2', 'g')
function! vim#refresh_config(...) abort
  filetype detect  " in case started with empty file and shebang changes this
  let g:refresh_times = get(g:, 'refresh_times', {'global': localtime()})
  let default = get(g:refresh_times, 'global', 0)
  let current = localtime()
  let regexes = [
    \ '/.fzf/',
    \ '/plugged/',
    \ '/\.\?vimsession*',
    \ '/\.\?vim/autoload/vim.vim',
    \ '/\(micro\|mini\|mamba\)\(forge\|conda\|mamba\)\d\?/'
    \ ]
  let regex = '\(' . join(regexes, '\|') . '\)'
  let paths = split(execute('scriptnames'), "\n")  " load order, distinct from &rtp
  let loaded = []
  let updates = {}
  for path in paths
    let path = substitute(path, '^\s*\d*:\s*\(.*\)$', '\1', 'g')
    let path = resolve(expand(path))  " then compare to home
    if path !~# expand('~') || path =~# regex || a:0 && path !~# a:1
      continue  " skip files not edited by user or not matching input regex
    endif
    if index(loaded, path) != -1
      continue  " already loaded this
    endif
    if path =~# '/\(syntax\|ftplugin\)/'
      let ftype = fnamemodify(path, ':t:r')
    else
      let ftype = 'global'
    endif
    if path =~# '/\(\.\?vimrc\|init\.vim\)'  " always source and trigger filetypes here
      doautocmd Filetype
    elseif getftime(path) < get(g:refresh_times, ftype, default)
      continue  " only refresh if outdated
    endif
    if ftype ==# 'global' || ftype ==# &filetype
      exe 'so ' . path
      call add(loaded, path)
      let updates[ftype] = current
    else
      let updates[ftype] = get(g:refresh_times, ftype, default)
    endif
  endfor
  doautocmd BufEnter
  echom 'Loaded: ' . join(map(loaded, "fnamemodify(v:val, ':~')[2:]"), ', ') . '.'
  call extend(g:refresh_times, updates)
endfunction
