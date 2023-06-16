"-----------------------------------------------------------------------------"
" Utilities for sourcing vimscript
"-----------------------------------------------------------------------------"
" Refresh config settings
" Todo: Expand to include all filetype files? Or not necessary?
function! vim#source_config() abort
  filetype detect  " if started with empty file, but now shebang makes filetype clear
  let loaded = []
  let files = [
    \ '~/.vimrc',
    \ '~/.vim/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/syntax/' . &filetype . '.vim',
    \ '~/.vim/after/ftplugin/' . &filetype . '.vim',
    \ '~/.vim/after/syntax/' . &filetype . '.vim'
    \ ]
  for i in range(len(files))
    if filereadable(expand(files[i]))
      exe 'so ' . files[i] | call add(loaded, files[i])
    endif
    if i == 0  " immediately after .vimrc completion
      doautocmd Filetype
    endif
    if i == 4
      doautocmd BufEnter
    endif
  endfor
  echom 'Loaded ' . join(map(loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ') . '.'
endfunction

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
