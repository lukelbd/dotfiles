"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" Create obsession file and possibly remove old one
" Note: Sets string for use with MacVim windows and possibly other GUIs
function! vim#init_session(...)
  if !exists(':Obsession')
    echoerr ':Obsession is not installed.'
    return
  endif
  let regex = '^\.vimsession[-_]*\(.*\)$'
  let current = v:this_session
  let session = a:0 ? a:1 : !empty(current) ? current : '.vimsession'
  let suffix = substitute(fnamemodify(session, ':t'), regex, '\1', '')
  exe 'Obsession ' . session
  if !empty(current) && fnamemodify(session, ':p') != fnamemodify(current, ':p')
    echom 'Removing old session file ' . fnamemodify(current, ':t')
    call delete(current)
  endif
  if !empty(suffix)
    echom 'Applying session title ' . suffix
    let &g:titlestring = suffix
  endif
endfunction
