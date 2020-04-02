"-----------------------------------------------------------------------------"
" FZF plugin utilties
"-----------------------------------------------------------------------------"
" Function used with input() to prevent tab expansion
function! fzf#null_list(A, L, P) abort
  return []
endfunction

" Generate list of files in directory
function! s:list_files(dir) abort
  " Include both hidden and non-hidden
  let paths = split(globpath(a:dir, '*'), "\n") + split(globpath(a:dir, '.?*'), "\n")
  let paths = map(paths, 'fnamemodify(v:val, '':t'')')
  call insert(paths, s:newfile, 0) " highest priority
  return paths
endfunction

" Tab drop plugin from: https://github.com/ohjames/tabdrop
" WARNING: For some reason :tab drop and even :<bufnr>wincmd w fails
" on monde so need to use the *tab jump* command instead!
function! s:tab_drop(file) abort
  let visible = {}
  let path = fnamemodify(a:file, ':p')
  let tabjump = 0
  for t in range(tabpagenr('$')) " iterate through each tab
    let tabnr = t + 1 " the tab number
    for b in tabpagebuflist(tabnr)
      if fnamemodify(bufname(b), ':p') == path
        exe 'normal! ' . tabnr . 'gt'
        return
      endif
    endfor
  endfor
  if bufname('%') ==# '' && &modified == 0
    " Fill this window
    exec 'edit ' . a:file
  else
    " Create new tab
    exec 'tabnew ' . a:file
  end
endfunction

" Check if user selection is directory, descend until user selects a file
let s:newfile = '[new file]' " dummy entry for requesting new file in current directory
function! fzf#open_continuous(path) abort
  let path = substitute(a:path, '^\s*\(.\{-}\)\s*$', '\1', '')  " strip spaces
  if ! len(path)
    let path = '.'
  endif
  let path = substitute(fnamemodify(path, ':p'), '/$', '', '')
  let path_orig = path
  while isdirectory(path)
    " Get user selection
    let prompt = substitute(path, '^' . expand('~'), '~', '')
    let items = fzf#run({
      \ 'source': s:list_files(path),
      \ 'options': "--no-sort --prompt='" . prompt . "/'",
      \ 'down': '~30%'
      \ })
    if !len(items)  " user cancelled operation
      let path = ''
      break
    endif

    " Build back selection into path
    " Todo: Permit opening multiple files at once?
    let item = items[0]
    if item == s:newfile
      let item = input('Enter new filename (' . prompt . '): ', '', 'customlist,fzf#null_list')
      if !len(item)
        let path = ''
      else
        let path = path . '/' . item
      endif
      break
    else
      if item ==# '..' " fnamemodify :p does not expand the previous direcotry sign, so must do this instead
        let path = fnamemodify(path, ':h') " head of current directory
      else
        let path = path . '/' . item
      endif
    endif
  endwhile

  " Open file or cancel operation
  " If it is already open just jump to that tab
  if len(path)
    call s:tab_drop(path)
  endif
  return
endfunction

