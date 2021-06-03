"-----------------------------------------------------------------------------"
" Advanced TeX configuration of shortcuts.vim
" Warning: File name cannot be shortcuts.vim. Maybe this only works with
" vim-plug plugins, not local plugins manually added to rtp?
"-----------------------------------------------------------------------------"
function! s:sed_cmd() abort
  if has('macunix')
    let gsed = '/usr/local/bin/gsed'  " Todo: defer to 'gsed' alias?
  elseif has('unix')
    let gsed = '/usr/bin/sed'
  else
    let gsed = ''
  endif
  if empty(gsed) || !executable(gsed)
    throw 'GNU sed not available.'
  endif
  return gsed
endfunction

"-----------------------------------------------------------------------------"
" Selecting from tex labels (integration with idetools)
"-----------------------------------------------------------------------------"
" Return graphics paths
function! s:label_source() abort
  if !exists('b:ctags_alph')
    return []
  endif
  let ctags = filter(copy(b:ctags_alph), 'v:val[2] ==# "l"')
  let ctags = map(ctags, 'v:val[0] . " (" . v:val[1] . ")"')  " label (line number)
  if empty(ctags)
    echoerr 'No ctag labels found.'
  endif
  return ctags
endfunction

" Return label text
" Note: To get multiple items hit <Shift><Tab>
function! s:label_select() abort
  let items = fzf#run({
    \ 'source': s:label_source(),
    \ 'options': '--multi --prompt="Label> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'substitute(v:val, " (.*)$", "", "")')
  return join(items, ',')
endfunction
function! textools#label_select(...) abort
  return function('s:label_select', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Selecting citations from bibtex files
" See: https://github.com/msprev/fzf-bibtex
"-----------------------------------------------------------------------------"
" Basic function called every time
function! s:cite_source() abort
  " Set the plugin source variables
  " Get biligraphies using grep, copied from latexmk
  " Easier than using search() because we want to get *all* results
  let biblist = []
  let bibfiles = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:sed_cmd() . ' -n ''s@^\s*\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}@\2@p'''
    \ )

  " Check that files all exist
  if v:shell_error == 0
    let filedir = expand('%:h')
    for bibfile in split(bibfiles, "\n")
      if bibfile !~? '.bib$'
        let bibfile .= '.bib'
      endif
      let bibpath = filedir . '/' . bibfile
      if filereadable(bibpath)
        call add(biblist, bibpath)
      else
        echohl WarningMsg
        echom "Warning: Bib file '" . bibpath . "' does not exist.'"
        echohl None
      endif
    endfor
  endif

  " Set the environment variable and return command-line command used to
  " generate fuzzy list from the selected files.
  let result = []
  if len(biblist) == 0
    echoerr 'Bib files were not defined or do not exist.'
  elseif ! executable('bibtex-ls')
    " Note: See https://github.com/msprev/fzf-bibtex
    echoerr 'Command bibtex-ls not found.'
  else
    let $FZF_BIBTEX_SOURCES = join(biblist, ':')
    let result = 'bibtex-ls ' . join(biblist, ' ')
  endif
  return result
endfunction

" Return citation text
" We can them use this function as an insert mode <expr> mapping
" Note: To get multiple items hit <Shift><Tab>
function! s:cite_select() abort
  let items = fzf#run({
    \ 'source': s:cite_source(),
    \ 'options': '--multi --prompt="Source> "',
    \ 'down': '~50%',
    \ })
  let result = ''
  if ! executable('bibtex-cite')
  " Note: See https://github.com/msprev/fzf-bibtex
    echoerr 'Command bibtex-cite not found.'
  else
    let result = system("bibtex-cite -prefix='@' -postfix='' -separator=','", items)
    let result = substitute(result, '@', '', 'g')
  endif
  return result
endfunction
function! textools#cite_select(...) abort
  return function('s:cite_select', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphic_source() abort
  " Get graphics paths
  " Note: Negative indexing evidently does not work with strings
  " Todo: Make this work when \graphicspath takes up more than one line
  " Not high priority because latexmk rarely accounts for this anyway
  let paths = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:sed_cmd() . ' -n ''s@\\graphicspath{\(.*\)}@\1@p'''
    \ )
  let paths = substitute(paths, "\n", '', 'g')  " in case multiple \graphicspath calls, even though this is illegal
  if !empty(paths) && (paths[0] !=# '{' || paths[len(paths) - 1] !=# '}')
    echohl WarningMsg
    echom "Incorrect syntax '" . paths . "'. Surround paths with curly braces."
    echohl None
    let paths = '{' . paths . '}'
  endif

  " Check syntax
  " Make paths relative to *latex file* not cwd
  let filedir = expand('%:h')
  let pathlist = []
  for path in split(paths[1:len(paths) - 2], '}{')
    let abspath = expand(filedir . '/' . path)
    if isdirectory(abspath)
      call add(pathlist, abspath)
    else
      echohl WarningMsg
      echom "Warning: Directory '" . abspath . "' does not exist."
      echohl None
    endif
  endfor

  " Get graphics files in each path
  let figlist = []
  call add(pathlist, expand('%:h'))
  for path in pathlist
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      call extend(figlist, globpath(path, '*.' . ext, v:true, v:true))
    endfor
  endfor
  let figlist = map(figlist, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')

  " Return figure files
  if len(figlist) == 0
    echoerr 'No graphics files found.'
  endif
  return figlist
endfunction

" Return graphics text
" We can them use this function as an insert mode <expr> mapping
function! s:graphic_select() abort
  let items = fzf#run({
    \ 'source': s:graphic_source(),
    \ 'options': '--prompt="Figure> "',
    \ 'down': '~50%',
    \ })
  let items = map(items, 'fnamemodify(v:val, ":t")')
  return join(items, ',')
endfunction
function! textools#graphic_select(...) abort
  return function('s:graphic_select', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Checking math mode and making units
"-----------------------------------------------------------------------------"
" Wrap in math environment only if cursor is not already inside one
" Use TeX syntax to detect any and every math environment
" Note: Check syntax of point to *left* of cursor because that's the environment
" where we are inserting text. Does not wrap if in first column.
function! s:ensure_math(...) abort
  let output = call('shortcuts#make_snippet_driver', a:000)
  if empty(filter(synstack(line('.'), col('.') - 1), 'synIDattr(v:val, "name") =~? "math"'))
    let output = '$' . output . '$'
  endif
  return output
endfunction
function! textools#ensure_math(...) abort
  return function('s:ensure_math', a:000)
endfunction

" Format unit string for LaTeX for LaTeX for LaTeX for LaTeX
function! s:format_units(...) abort
  let input = call('shortcuts#make_snippet_driver', a:000)
  if empty(input)
    return ''
  endif
  let input = substitute(input, '/', ' / ', 'g')  " pre-process
  let parts = split(input)
  let regex = '^\([a-zA-Z0-9.]\+\)\%(\^\|\*\*\)\?\([-+]\?[0-9.]\+\)\?$'
  let output = '\, '  " add space between number and unit
  for idx in range(len(parts))
    if parts[idx] ==# '/'
      let part = parts[idx]
    else
      let items = matchlist(parts[idx], regex)
      if empty(items)
        echohl WarningMsg | echom 'Warning: Invalid units string.' | echohl None
        return ''
      endif
      let part = '\textnormal{' . items[1] . '}'
      if !empty(items[2])
        let part .= '^{' . items[2] . '}'
      endif
    endif
    if idx != len(parts) - 1
      let part = part . ' \, '
    endif
    let output .= part
  endfor
  return s:ensure_math(output)
endfunction
function! textools#format_units(...) abort
  return function('s:format_units', a:000)
endfunction
