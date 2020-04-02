"-----------------------------------------------------------------------------"
" Functions for selecting from available bibtex files
" See: https://github.com/msprev/fzf-bibtex
" Todo: Document these tools and incorporate them into the textools plugin
"-----------------------------------------------------------------------------"
" The gsed executable
let s:gsed = '/usr/local/bin/gsed'  " Todo: defer to 'gsed' alias?
if !executable(s:gsed)
  echohl ErrorMsg
  echom 'Error: gsed not available. Please install it with brew install gnu-sed.'
  echohl None
  finish
endif

" Basic function called every time
function! s:cite_source() abort
  " Set the cache directory
  " Makes sense to do this here
  let cache_dir = expand('~/Library/Caches/bibtex')
  if !isdirectory(cache_dir)
    echohl ErrorMsg
    echom 'Error: Cache directory ''' . cache_dir . '''does not exist.'
    echohl None
  endif
  let $FZF_BIBTEX_CACHEDIR = cache_dir

  " Set the plugin source variables
  " Get biligraphies using grep, copied from latexmk
  " Easier than using search() because we want to get *all* results
  let bibfiles = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:gsed . ' -n ''s/\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}/\2/p'''
    \ )
  if v:shell_error != 0
    echohl ErrorMsg
    echom 'Error: Failed to get list of bibliography files.'
    echohl None
  endif

  " Check that files all exist
  let filedir = expand('%:h')
  let biblist = []
  for bibfile in split(bibfiles, "\n")
    if bibfile !~? '.bib$'
      let bibfile .= '.bib'
    endif
    let bibpath = filedir . '/' . bibfile
    if filereadable(bibpath)
      call add(biblist, bibpath)
    else
      echohl WarningMsg
      echom 'Warning: Bibtex file ''' . bibpath . ''' does not exist.''
      echohl None
    endif
  endfor

  " Set the environment variable and return command-line command used to
  " generate fuzzy list from the selected files.
  let $FZF_BIBTEX_SOURCES = join(biblist, ':')
  if len(biblist) == 0
    echohl WarningMsg
    echom 'Warning: No bibtex files found.'
    echohl None
  endif
  if executable('bibtex-ls')
    return 'bibtex-ls ' . join(biblist, ' ')
  else
    echohl ErrorMsg
    echom 'Error: bibtex-ls not found.'
    echohl None
    return ''
  endif
  " return biblist
endfunction

" Return citation text
" We can them use this function as an insert mode <expr> mapping
" Note: To get multiple items just hit <Tab>
function! textools#cite_select() abort
  let result = ''
  let items = fzf#run({
    \ 'source': s:cite_source(),
    \ 'options': '--prompt="Article> "',
    \ 'down': '~50%',
    \ })
  if executable('bibtex-cite')
    let result = system('bibtex-cite ', items)
    let result = substitute(result, '@', '', 'g')
  else
    echohl ErrorMsg
    echom 'Error: bibtex-cite not found.'
    echohl None
  endif
  return result
endfunction

"-----------------------------------------------------------------------------"
" Functions for selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphics_source() abort
  " Get graphics paths
  " Todo: Make this work when \graphicspath takes up more than one line
  " Not high priority because latexmk rarely accounts for this anyway
  let paths = system(
  \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
  \ . s:gsed . ' -n ''s/\\graphicspath{\(.*\)}/\1/p'''
  \ )
  if v:shell_error != 0
    echohl ErrorMsg
    echom 'Error: Failed to get list of bibliography files.'
    echohl None
  endif
  let paths = substitute(paths, "\n", '', 'g')  " in case multiple \graphicspath calls, even though this is illegal

  " Check syntax
  " Note: Negative indexing evidently does not work with strings
  let filedir = expand('%:h')
  let pathlist = []
  if paths[0] !=# '{' || paths[len(paths) - 1] !=# '}'
    " Syntax is \graphicspath{{path1}{path2}}
    echohl WarningMsg
    echom 'Warning: Incorrect syntax ''' . paths . ''''
    echohl None
  else
    " Make paths relative to *latex file* not cwd
    let pathlist = []
    for path in split(paths[1:len(paths) - 2], '}{')
      let abspath = expand(filedir . '/' . path)
      if isdirectory(abspath)
        call add(pathlist, abspath)
      else
        echohl WarningMsg
        echom 'Warning: Directory ''' . abspath . ''' does not exist.'
        echohl None
      endif
    endfor
  endif

  " Get graphics files in each path
  let figlist = []
  echom join(pathlist, ', ')
  call add(pathlist, expand('%:h'))
  for path in pathlist
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      call extend(figlist, globpath(path, '*.' . ext, v:true, v:true))
    endfor
  endfor
  let figlist = map(figlist, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')

  " Return figure files
  if len(figlist) == 0
    echohl WarningMsg
    echom 'Warning: No graphics files found.'
    echohl None
  endif
  return figlist
endfunction

" Return graphics text
" We can them use this function as an insert mode <expr> mapping
function! textools#graphics_select() abort
  let items = fzf#run({
    \ 'source': s:graphics_source(),
    \ 'options': '--prompt="Figure> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'fnamemodify(v:val, ":t")')
  return join(items, ',')
endfunction
