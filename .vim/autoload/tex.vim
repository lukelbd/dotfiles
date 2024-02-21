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
  if !executable(gsed) | echoerr 'GNU sed not available.' | let gsed = '' | endif
  return gsed
endfunction

"-----------------------------------------------------------------------------"
" Selecting from tex labels (integration with idetools)
"-----------------------------------------------------------------------------"
" Source for tex labels
function! s:label_source() abort
  if !exists('b:tags_by_name')
    echoerr 'No tags present in file.'
    let tags = []
  else
    let tags = filter(copy(b:tags_by_name), 'v:val[2] ==# "l"')
    let tags = map(tags, 'v:val[0] . " (" . v:val[1] . ")"')  " label (line number)
    if empty(tags) | echoerr 'No tex labels found.' | endif
  endif
  return tags
endfunction

" Sink for tex labels
function! s:label_sink(items) abort
  let items = map(copy(a:items), 'substitute(v:val, " (.*)$", "", "")')
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(join(items, ',')), 'tni')
  else
    echohl WarningMsg
    echom 'Warning: No longer in insert mode. Not inserting labels.'
    echohl None
  endif
endfunction

" Fuzzy select tex labels
" Note: To get multiple items hit <Shift><Tab>
" Warning: See notes in succinct/autoload/internal.vim for why fzf#wrap not allowed.
function! s:label_select() abort
  call fzf#run({
    \ 'sink*': function('s:label_sink'),
    \ 'source': s:label_source(),
    \ 'options': '--multi --height=100% --prompt="Label> "',
    \ })
  return ''  " text inserted by sink function
endfunction
function! tex#label_select(...) abort
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
  let paths = []
  let result = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | '
    \ . s:sed_cmd() . ' -n ''s@^\s*\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}@\2@p'''
    \ )
  " Check that files all exist
  if v:shell_error == 0
    let local = expand('%:h')
    for path in split(result, "\n")
      if path !~? '.bib$'
        let path = path . '.bib'
      endif
      let path = substitute(path, '\\string', '', 'g')
      let path = path =~# '^\~\|^/' ? expand(path) : local . '/' . path
      if filereadable(path)
        call add(paths, path)
      else
        echohl WarningMsg
        echom "Warning: Bib file '" . path . "' does not exist.'"
        echohl None
      endif
    endfor
  endif
  " Set the environment variable and return command-line command used to
  " generate fuzzy list from the selected files.
  if len(paths) == 0
    echoerr 'Bibliography files not found.'
    return []
  elseif ! executable('bibtex-ls')  " see https://github.com/msprev/fzf-bibtex
    echoerr 'Command bibtex-ls not found.'
    return []
  else
    let $FZF_BIBTEX_SOURCES = join(paths, ':')
    return 'bibtex-ls ' . join(paths, ' ')
  endif
endfunction

" Sink for citations
function! s:cite_sink(items) abort
  if !executable('bibtex-cite')  " see https://github.com/msprev/fzf-bibtex
    throw 'Command bibtex-cite not found.'
  endif
  let result = system("bibtex-cite -prefix='@' -postfix='' -separator=','", a:items)
  let result = substitute(result, '@', '', 'g')  " remove label markers
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(result), 'tni')
  else
    echohl WarningMsg
    echom 'Warning: No longer in insert mode. Not inserting citations.'
    echohl None
  endif
endfunction

" Fuzzy select citation
" Note: To get multiple items hit <Shift><Tab>
" Warning: See notes in succinct/autoload/internal.vim for why fzf#wrap not allowed.
function! s:cite_select() abort
  call fzf#run({
    \ 'sink*': function('s:cite_sink'),
    \ 'source': s:cite_source(),
    \ 'options': '--multi --height=100% --prompt="Source> "',
    \ })
  return ''  " text inserted by sink function
endfunction
function! tex#cite_select(...) abort
  return function('s:cite_select', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphic_source() abort
  let paths = system(
    \ 'grep -o ''^[^%]*'' ' . shellescape(@%) . " | awk -v RS='[^\\n]*{' '"
    \ . 'inside && /}/ {path=$0; if(init) inside=0} {init=0} '
    \ . 'inside && /(\n|^)}/ {inside=0} '
    \ . 'path {sub(/}.*/, "}", path); print "{" path} '
    \ . 'RT ~ /graphicspath/ {init=1; inside=1}'
    \ . '/document}/ {exit} {path=""}'
    \ . "'")
  let paths = substitute(paths, "\n", '', 'g')  " in case of multiple lines
  let folder = expand('%:h')
  let pathlist = []
  for path in split(paths[1:len(paths) - 2], '}{')
    let abspath = expand(path)  " e.g. $HOME/research/...
    let relpath = expand(folder . '/' . path)  " e.g. ./figures/...
    if isdirectory(abspath)
      call add(pathlist, abspath)
    elseif isdirectory(relpath)
      call add(pathlist, relpath)
    else
      echohl WarningMsg
      echom "Warning: Directory '" . abspath . "' does not exist."
      echohl None
    endif
  endfor
  let files = []
  call add(pathlist, expand('%:h'))
  for path in pathlist
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      call extend(files, globpath(path, '*.' . ext, v:true, v:true))
    endfor
  endfor
  let files = map(files, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')
  if empty(files) | echoerr 'No graphics files found.' | endif
  return files
endfunction

" Sink for graphics
function! s:graphic_sink(items) abort
  let items = map(copy(a:items), 'fnamemodify(v:val, ":t")')
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(join(items, ',')), 'tni')
  else
    echohl WarningMsg
    echom 'Warning: No longer in insert mode. Not inserting graphics.'
    echohl None
  endif
endfunction

" Fuzzy select graphics
" Warning: See notes in succinct/autoload/internal.vim for why fzf#wrap not allowed.
function! s:graphic_select() abort
  call fzf#run({
    \ 'sink*': function('s:graphic_sink'),
    \ 'source': s:graphic_source(),
    \ 'options': '--multi --height=100% --prompt="Figure> "',
    \ })
  return ''  " text inserted by sink function
endfunction
function! tex#graphic_select(...) abort
  return function('s:graphic_select', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Checking math mode and making units
"-----------------------------------------------------------------------------"
" Wrap in math environment only if cursor is not already inside one
" Use TeX syntax to detect any and every math environment
" Note: Check syntax of point to *left* of cursor because that's the environment
" where we are inserting text. Does not wrap if in first column.
function! s:ensure_math(value) abort
  let output = succinct#process_value(a:value)
  if empty(output)
    return output
  endif
  if empty(filter(synstack(line('.'), col('.') - 1), 'synIDattr(v:val, "name") =~? "math"'))
    let output = '$' . output . '$'
  endif
  return output
endfunction
function! tex#ensure_math(...) abort
  return function('s:ensure_math', a:000)
endfunction

" Format unit string for LaTeX for LaTeX for LaTeX for LaTeX
function! s:format_units(value) abort
  let input = succinct#process_value(a:value)
  if empty(input)
    return ''
  endif
  let input = substitute(input, '/', ' / ', 'g')  " pre-process
  let parts = split(input, '\s\+', 1)  " keep empty parts e.g. leading spaces
  let regex = '^\([a-zA-Z0-9.]\+\)\%(\^\|\*\*\)\?\([-+]\?[0-9.]\+\)\?$'
  let output = ''  " add space between number and unit
  for idx in range(len(parts))
    if empty(parts[idx]) || parts[idx] ==# '/'
      let part = parts[idx]  " empty indicates space added below
    else
      let items = matchlist(parts[idx], regex)
      if empty(items)
        echohl WarningMsg
        echom 'Warning: Invalid units string.'
        echohl None
        return ''
      endif
      let part = items[1]
      if part !~# '^[+-]\?[0-9.]\+$'
        let part = '\mathrm{' . items[1] . '}'
      endif
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
function! tex#format_units(...) abort
  return function('s:format_units', a:000)
endfunction
