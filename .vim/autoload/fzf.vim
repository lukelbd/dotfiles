"-----------------------------------------------------------------------------"
" FZF plugin utilties
"-----------------------------------------------------------------------------"
" Tab drop plugin from: https://github.com/ohjames/tabdrop
" WARNING: For some reason :tab drop and even :<bufnr>wincmd w fails
" on monde so need to use the *tab jump* command instead!
function! s:tab_drop(file)
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

" Generate list of files in directory
function! s:list_files(path) abort
  let folder = substitute(fnamemodify(a:path, ':p'), '/$', '', '') " absolute path
  let files = split(glob(folder . '/*'), '\n') + split(glob(folder . '/.?*'),'\n') " the ? ignores the current directory '.'
  let files = map(files, '"' . fnamemodify(folder, ':t') . '/" . fnamemodify(v:val, ":t")')
  call insert(files, s:newfile, 0) " highest priority
  return files
endfunction

" Check if user FZF selection is directory and keep opening windows until
" user selects a file
let s:newfile = '[new file]' " dummy entry for requesting new file in current directory
function! fzf#null_list(A, L, P) abort
  return []
endfunction
function! fzf#open_continuous(path) abort
  let path = len(a:path) ? a:path : '.'
  let path = substitute(fnamemodify(path, ':p'), '/$', '', '')
  let path_orig = path
  while isdirectory(path)
    let pprev = path
    let items = fzf#run({
        \ 'source': s:list_files(path),
        \ 'options':'--no-sort',
        \ 'down':'~30%'})
    " User cancelled or entered invalid string
    if !len(items) " length of list
      let path = ''
      break
    endif
    " Build back selection into path
    let item = items[0]
    if item == s:newfile
      let item = input('Enter new filename (' . path . '): ', '', 'customlist,fzf#null_list')
      if ! len(item)
        let path = ''
      else
        let path = path . '/' . item
      endif
      break
    else
      let tail = fnamemodify(item, ':t')
      if tail ==# '..' " fnamemodify :p does not expand the previous direcotry sign, so must do this instead
        let path = fnamemodify(path, ':h') " head of current directory
      else
        let path = path . '/' . tail
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

