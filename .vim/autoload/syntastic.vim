"-----------------------------------------------------------------------------"
" Syntastic plugin functions
"-----------------------------------------------------------------------------"
" Helper functions. Need to run Syntastic with noautocmd to prevent weird
" conflict with tabbar but that means have to change some settings manually
function! s:syntastic_status() abort
  return (exists('b:syntastic_on') && b:syntastic_on)
endfunction
function! s:cmp(a, b) abort
  for i in range(len(a:a))
    if a:a[i] < a:b[i]
      return -1
    elseif a:a[i] > a:b[i]
      return 1
    endif
  endfor
  return 0
endfunction

" Cyclic next error in location list
" Copied from: https://vi.stackexchange.com/a/14359
function! syntastic#cyclic_next(count, list, ...) abort abort
  let reverse = a:0 && a:1
  let func = 'get' . a:list . 'list'
  let params = a:list ==# 'loc' ? [0] : []
  let cmd = a:list ==# 'loc' ? 'll' : 'cc'
  let items = call(func, params)
  if len(items) == 0
    return 'echoerr ' . string('E42: No Errors')
  endif

  " Build up list of loc dictionaries
  call map(items, 'extend(v:val, {"idx": v:key + 1})')
  if reverse
    call reverse(items)
  endif
  let [bufnr, cmp] = [bufnr('%'), reverse ? 1 : -1]
  let context = [line('.'), col('.')]
  if v:version > 800 || has('patch-8.0.1112')
    let current = call(func, extend(copy(params), [{'idx':1}])).idx
  else
    redir => capture | execute cmd | redir END
    let current = str2nr(matchstr(capture, '(\zs\d\+\ze of \d\+)'))
  endif
  call add(context, current)

  " Jump to next loc circularly
  call filter(items, 'v:val.bufnr == bufnr')
  let nbuffer = len(get(items, 0, {}))
  call filter(items, 's:cmp(context, [v:val.lnum, v:val.col, v:val.idx]) == cmp')
  let inext = get(get(items, 0, {}), 'idx', 'E553: No more items')
  if type(inext) == type(0)
    return cmd . inext
  elseif nbuffer != 0
    exe '' . (reverse ? line('$') : 0)
    return syntastic#cyclic_next(a:count, a:list, reverse)
  else
    return 'echoerr' . string(inext)
  endif
endfunction

" Determine checkers from annoying human-friendly output; version suitable
" for scripting does not seem available. Weirdly need 'silent' to avoid
" printint to vim menu. The *last* value in array will be checker.
" Note: For files not written to disk, last line of SyntasticInfo is warning
" message that the file cannot be checked. Below filter ignores this line.
function! syntastic#syntastic_checkers(...) abort
  " Get available and activated checkers
  redir => output
  silent SyntasticInfo
  redir END
  let result = filter(split(output, "\n"), 'v:val =~# ":"')
  let checkers_avail = split(split(result[-2], ':')[-1], '\s\+')
  let checkers_active = split(split(result[-1], ':')[-1], '\s\+')
  if checkers_avail[0] ==# '-'
    let checkers_avail = []
  endif
  if checkers_active[0] ==# '-'
    let checkers_active = []
  endif

  " Return active checkers and print useulf message
  let checkers_avail = map(
    \ checkers_avail,
    \ 'index(checkers_active, v:val) == -1 ? v:val : "[" . v:val . "]"'
    \ )
  echom 'Available checker(s): ' . join(checkers_avail, ', ')
  return checkers_active
endfunction

" Run checker
function! syntastic#syntastic_enable() abort
  let nbufs = len(tabpagebuflist())
  let checkers = syntastic#syntastic_checkers()
  if len(checkers) == 0
    echom 'No checkers activated.'
  else
    SyntasticCheck
    if (len(tabpagebuflist()) > nbufs && !s:syntastic_status())
        \ || (len(tabpagebuflist()) == nbufs && s:syntastic_status())
      wincmd k " jump to main
      let b:syntastic_on = 1
      silent! set signcolumn=no
    else
      echom 'No errors found.'
      let b:syntastic_on = 0
    endif
  endif
endfunction
