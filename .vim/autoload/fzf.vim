"-----------------------------------------------------------------------------"
" FZF plugin utilties
"-----------------------------------------------------------------------------"
" Generate list of files in directory
function! s:list_files(path)
  let folder = substitute(fnamemodify(a:path, ':p'), '/$', '', '') " absolute path
  let files = split(glob(folder . '/*'), '\n') + split(glob(folder . '/.?*'),'\n') " the ? ignores the current directory '.'
  let files = map(files, '"' . fnamemodify(folder, ':t') . '/" . fnamemodify(v:val, ":t")')
  call insert(files, s:newfile, 0) " highest priority
  return files
endfunction

" Check if user FZF selection is directory and keep opening windows until
" user selects a file
let s:newfile = '[new file]' " dummy entry for requesting new file in current directory
function! fzf#null_list(A, L, P)
  return []
endfunction
function! fzf#open_continuous(path)
  if a:path == ''
    let path = '.'
  else
    let path = a:path
  endif
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
      if item == ''
        let path = ''
      else
        let path = path . '/' . item
      endif
      break
    else
      let tail = fnamemodify(item, ':t')
      if tail == '..' " fnamemodify :p does not expand the previous direcotry sign, so must do this instead
        let path = fnamemodify(path, ':h') " head of current directory
      else
        let path = path . '/' . tail
      endif
    endif
  endwhile
  " Open file or cancel operation
  if path != ''
    exe 'tabe ' . path
  endif
  return
endfunction

