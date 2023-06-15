"-----------------------------------------------------------------------------"
" Utilities for vim windows and sessions
"-----------------------------------------------------------------------------"
" List buffers by most recent
" See: https://vi.stackexchange.com/a/22428/8084 (comment)
" Note: For some reason some edited files have 'nobuflisted' set (so ignored by
" e.g. :bnext). Maybe due to some plugin. Anyway do not use buflisted() filter.
function! s:recent_bufs() abort
  let info = getbufinfo()
  let info = sort(info, {val1, val2 -> val2.lastused - val1.lastused})
  return map(info, {idx, val -> val.bufnr})
  " return filter(nums, {val -> buflisted(val)})
endfunction

" Safely closing tabs and windows
" Note: This moves to the left tab after closure
" Note: Calling quit inside codei buffer triggers 'attempt to close buffer
" that is in use' error so instead return to main window and toggle codi.
function! vim#close_window() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  if &l:filetype ==# 'codi'
    wincmd p | Codi!!
  else
    silent! quit
  endif
  if ntabs != tabpagenr('$') && !islast
    silent! tabprevious
  endif
endfunction
function! vim#close_tab() abort
  let ntabs = tabpagenr('$')
  let islast = tabpagenr('$') == tabpagenr()
  if ntabs == 1
    silent! quitall
  else
    silent! tabclose
    if !islast
      silent! tabprevious
    endif
  endif
endfunction

" Current directory change
" Note: This can be useful for browsing files
function! vim#cd_previous() abort
  if exists('b:cd_prev')
    exe 'lcd ' . b:cd_prev
    unlet b:cd_prev
    echom 'Returned to previous directory.'
  else
    echom 'Previous directory is unset.'
  endif
endfunction

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

" Function that generates lists of tabs and their numbers
" Note: Here sorty by recently accessed to help replace :Buffers
" Warning: Need to keep up-to-date with tabline setting name
function! s:fzf_tab_source() abort
  let ndigits = len(string(tabpagenr('$')))
  let tabskip = get(g:, 'tabline_skip_filetypes', [])
  let unsorted = {}
  for tnr in range(tabpagenr('$')) " iterate through each tab
    let tabnr = tnr + 1 " the tab number
    let tbufs = tabpagebuflist(tabnr)
    for bnr in tbufs
      " Get 'primary' panel in tab, ignore 'helpers' even when focused
      " If there is *only* a 'helper' panel, use tnr for the title
      if index(tabskip, getbufvar(bnr, '&ft')) == -1
        let bufnr = bnr | break
      elseif bnr == tbufs[-1]
        let bufnr = bnr
      endif
    endfor
    let pad = repeat(' ', ndigits - len(string(tabnr)))
    let path = fnamemodify(bufname(bufnr), '%:t')
    let path = pad . tabnr . ': ' . path  " displayed string
    let unsorted[string(bufnr)] = path
  endfor
  let sorted = []
  let used = []
  let nums = keys(unsorted)
  for bnr in s:recent_bufs()
    let idx = index(nums, string(bnr))
    if idx >= 0
      call add(sorted, remove(unsorted, nums[idx]))
    endif
  endfor
  return sorted + values(unsorted)
endfunction

" Select from open tabs
" Note: This displays a list with the tab number and the file
function! vim#jump_tab() abort
  call fzf#run(fzf#wrap({
    \ 'source': s:fzf_tab_source(),
    \ 'options': '--no-sort --prompt="Tab> "',
    \ 'sink': function('s:jump_tab_sink'),
    \ }))
endfunction
function! s:jump_tab_sink(item) abort
  exe 'normal! ' . split(a:item, ':')[0] . 'gt'
endfunction

" Move to selected tab
" Note: This also displays the tab names in case user wants to
" group this file appropriately amongst similar open files.
function! vim#move_tab(...) abort
  if a:0
    call s:move_tab_sink(a:1)
  else
    call fzf#run(fzf#wrap({
      \ 'source': s:fzf_tab_source(),
      \ 'options': '--no-sort --prompt="Number> "',
      \ 'sink': function('s:move_tab_sink'),
      \ }))
  endif
endfunction
function! s:move_tab_sink(nr) abort
  if type(a:nr) == 0
    let nr = a:nr
  else
    let parts = split(a:nr, ':')  " fzf selection
    let nr = str2nr(parts[0])
  endif
  if nr == tabpagenr() || nr == 0 || nr ==# ''
    return
  elseif nr > tabpagenr() && v:version[0] > 7
    exe 'tabmove ' . nr
  else
    exe 'tabmove ' . (nr - 1)
  endif
endfunction

" Refresh config settings
" Todo: Expand to include all filetype files? Or not necessary?
function! vim#refresh_config() abort
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
    echom 'Sourcing ' . v:count . ' lines.'
    let lines = getline(line('.'), line('.') + v:count)
    exe join(lines, "\n")
  else
    echo "Sourcing '" . expand('%:p:t') . "'."
    update
    source %
  endif
endfunction

" Source input motion
" Todo: Add generalization for running chunks of arbitrary filetypes?
function! vim#source_motion() range abort
  update
  echom 'Sourcing lines ' . a:firstline . ' to ' . a:lastline . '.'
  let lines = getline(a:firstline, a:lastline)
  exe join(lines, "\n")
endfunction
" For <expr> map accepting motion
function! vim#source_motion_expr(...) abort
  return utils#motion_func('vim#source_motion', a:000)
endfunction

" Print currently open buffers
" Note: This should be used in conjunction with :WipeBufs
function! vim#show_bufs() abort
  let ndigits = len(string(bufnr('$')))
  let result = {}
  let lines = []
  for bufnr in s:recent_bufs()
    let pad = repeat(' ', ndigits - len(string(bufnr)))
    call add(lines, pad . bufnr . ': ' . bufname(bufnr))
  endfor
  echo join(lines, "\n")
endfunction

" Close buffers that do not appear in windows
" See: https://stackoverflow.com/a/7321131/4970632
" See: https://github.com/Asheq/close-buffers.vim
function! vim#wipe_bufs()
  let nums = []
  for t in range(1, tabpagenr('$'))
    call extend(nums, tabpagebuflist(t))
  endfor
  let names = []
  for b in range(1, bufnr('$'))
    if bufexists(b) && !getbufvar(b, '&mod') && index(nums, b) == -1
      call add(names, bufname(b))
      silent exe 'bwipeout ' b
    endif
  endfor
  if !empty(names)
    echom 'Closed ' . len(names) . ' hidden buffer(s): ' . join(names, ', ')
  endif
endfunction
