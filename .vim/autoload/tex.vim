"-----------------------------------------------------------------------------"
" Utilities for tex files
"-----------------------------------------------------------------------------"
" Source for tex labels
" NOTE: To get multiple items hit <Shift><Tab>
function! s:label_source() abort
  let tags = get(b:, 'tags_by_name', [])
  let tags = filter(copy(tags), 'v:val[2] ==# "l"')
  let tags = map(tags, 'v:val[0] . " (" . v:val[1] . ")"')  " label (line number)
  if empty(tags)
    let msg = 'Error: No ' . (exists('b:tags_by_name') ? 'tags in file' : 'labels found')
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
  return tags
endfunction

" Fuzzy select tex labels
" WARNING: See notes in succinct/autoload/utils.vim for why fzf#wrap not allowed
function! s:label_sink(items) abort
  let items = map(copy(a:items), 'substitute(v:val, " (.*)$", "", "")')
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(join(items, ',')), 'tni')
  else
    let msg = 'Warning: No longer in insert mode. Not inserting labels.'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! tex#fzf_labels() abort
  let opts = '--height 100% --tiebreak length,index'
  call fzf#run({
    \ 'source': s:label_source(),
    \ 'options': opts . ' --prompt="Label> "',
    \ 'sink*': function('s:label_sink'),
  \ }) | return ''  " text inserted by sink function
endfunction
function! tex#fzf_labels_ref(...) abort
  return function('tex#fzf_labels', a:000)
endfunction

" Return filetype specific fold label
" NOTE: This concatenates python docstring lines and uses frametitle from
" beamer presentations or labels from tex figures. Should add to this.
let s:maxlines = 100  " maxumimum lines to search
function! tex#fold_text(lnum, ...) abort
  let [line1, line2] = [a:lnum + 1, a:lnum + s:maxlines]
  let label = fold#fold_label(a:lnum, 0)
  let regex = '^\([%\t ]*\)\(.*\)$'
  let [_, indent, label; rest] = matchlist(label, regex)
  let isframe = label =~# '^\\begingroup\|^\\begins*{\s*frame\*\?\s*}'
  let isfloat = label =~# '^\\begin\s*{\s*\%(figure\|table\|center\)\*\?\s*}'
  let iscomment = indent =~# '^\s*%'  " also support comments
  if isframe || isfloat
    let head = iscomment ? '^\s*%\s*' : '^\s*'
    let tail = isframe ? '\\frametitle' : '\\label'
    for lnum in range(line1, min([line2, a:0 ? a:1 : line2]))
      let bool = getline(lnum) =~# head . tail
      if bool | let label = fold#fold_label(lnum, 0) | break | endif
    endfor
  endif
  if label =~# '{\s*\(%.*\)\?$'  " append lines
    let [line1, line2] = [lnum + 1, lnum + s:maxlines]
    let label = substitute(label, '{%.*$', '{', label)
    for lnum in range(line1, min([line2, a:0 ? a:1 : line2]))
      let bool = lnum == line1 || label[-1:] ==# '{'
      let label .= (bool ? '' : ' ') . fold#fold_label(lnum, 1)
    endfor
  endif
  let label = substitute(label, '\\\@<!\\', '', 'g')  " remove backslashes
  let label = substitute(label, '\(textbf\|textit\|emph\){', '', 'g')  " remove style
  return indent . substitute(label, regex, '\2', 'g')
endfunction

"-----------------------------------------------------------------------------"
" Selecting citations from bibtex files
"-----------------------------------------------------------------------------"
" Return biligraphies using grep (copied from latexmk)
" NOTE: To get multiple items hit <Shift><Tab>
" See: https://github.com/msprev/fzf-bibtex
function! s:cite_source() abort
  let gsed = has('macunix') ? '/usr/local/bin/gsed' : '/usr/bin/sed'
  if !executable(gsed) | echoerr 'GNU sed not available.' | let gsed = '' | endif
  let cmd = 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | ' . gsed . ' -n '
    \ . '''s@^\s*\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}@\2@p'''
  let bibs = []
  let paths = systemlist(cmd)
  if v:shell_error == 0
    let local = expand('%:h')
    for path in paths
      if path !~? '.bib$'
        let path = path . '.bib'
      endif
      let path = substitute(path, '\\string', '', 'g')
      let path = path =~# '^\~\|^/' ? expand(path) : local . '/' . path
      if filereadable(path)
        call add(bibs, path)
      else
        let msg = 'Warning: Bib file ' . string(path) . ' does not exist.'
        redraw | echohl WarningMsg | echom msg | echohl None
      endif
    endfor
  endif
  if len(bibs) == 0
    echoerr 'Bibliography files not found.'
    return []
  elseif ! executable('bibtex-ls')  " see https://github.com/msprev/fzf-bibtex
    echoerr 'Command bibtex-ls not found.'
    return []
  else
    let $FZF_BIBTEX_SOURCES = join(bibs, ':')
    return 'bibtex-ls ' . join(bibs, ' ')
  endif
endfunction

" Fuzzy select citation
" WARNING: See notes in succinct/autoload/utils.vim for why fzf#wrap not allowed.
function! s:cite_sink(items) abort
  if !executable('bibtex-cite')  " see https://github.com/msprev/fzf-bibtex
    throw 'Command bibtex-cite not found.'
  endif
  let result = system("bibtex-cite -prefix='@' -postfix='' -separator=','", a:items)
  let result = substitute(result, '@', '', 'g')  " remove label markers
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(result), 'tni')
  else
    let msg = 'Warning: No longer in insert mode. Not inserting citations.'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! tex#fzf_cite() abort
  let opts = '--multi --height 100% --tiebreak length,index'
  call fzf#run({
    \ 'sink*': function('s:cite_sink'),
    \ 'source': s:cite_source(),
    \ 'options': opts . ' --prompt="Source> "',
  \ }) | return ''  " text inserted by sink function
endfunction
function! tex#fzf_cite_ref(...) abort
  return function('tex#fzf_cite', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Selecting from available graphics files
"-----------------------------------------------------------------------------"
" Related function that prints graphics files
function! s:graphic_source() abort
  let cmd = 'grep -o ''^[^%]*'' ' . shellescape(@%) . " | awk -v RS='[^\\n]*{' '"
    \ . 'inside && /}/ {path=$0; if(init) inside=0} {init=0} '
    \ . 'inside && /(\n|^)}/ {inside=0} '
    \ . 'path {sub(/}.*/, "}", path); print "{" path} '
    \ . 'RT ~ /graphicspath/ {init=1; inside=1}'
    \ . '/document}/ {exit} {path=""}' . "'"
  let paths = join(systemlist(cmd), '')
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
      let msg = 'Warning: Directory ' . string(abspath) . ' does not exist.'
      redraw | echohl WarningMsg | echom msg | echohl None
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

" Fuzzy select graphics
" WARNING: See notes in succinct/autoload/utils.vim for why fzf#wrap not allowed.
function! s:graphic_sink(items) abort
  let items = map(copy(a:items), 'fnamemodify(v:val, ":t")')
  if mode() =~# 'i'
    call feedkeys(succinct#process_value(join(items, ',')), 'tni')
  else
    let msg = 'Warning: No longer in insert mode. Not inserting graphics.'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! tex#fzf_graphics() abort
  let opts = '--multi --height=100% --tiebreak=length,index'
  call fzf#run({
    \ 'sink*': function('s:graphic_sink'),
    \ 'source': s:graphic_source(),
    \ 'options': opts . ' --prompt="Figure> "',
    \ })
  return ''  " text inserted by sink function
endfunction
function! tex#fzf_graphics_ref(...) abort
  return function('tex#fzf_graphics', a:000)
endfunction

"-----------------------------------------------------------------------------"
" Check math mode and contruct units
"-----------------------------------------------------------------------------"
" Wrap in math environment only if cursor is not already inside one
" NOTE: Check syntax to *left* of cursor because we add text to that environment
function! tex#ensure_math(value) abort
  let output = succinct#_pre_process(a:value)
  let output = succinct#process_value(output)
  if empty(output)
    return output
  endif
  let [lnum, cnum] = [line('.'), col('.') - 1]
  let stack = synstack(lnum, cnum)
  if empty(filter(stack, 'synIDattr(v:val, "name") =~? "math"'))
    let output = '$' . output . '$'
  endif
  return output
endfunction
function! tex#ensure_math_ref(...) abort
  return function('tex#ensure_math', a:000)
endfunction

" Format unit string for LaTeX
" NOTE: This includes standard \, spacing and \mathrm{} encasing. See also climopy
function! tex#format_units(value) abort
  let input = succinct#_pre_process(a:value)
  let input = succinct#process_value(input)
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
        let msg = 'Warning: Invalid units string.'
        redraw | echohl WarningMsg | echom msg | echohl None | return ''
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
      let part = part . '\,'
    endif
    let output .= part
  endfor
  return tex#ensure_math(output)
endfunction
function! tex#format_units_ref(...) abort
  return function('tex#format_units', a:000)
endfunction
