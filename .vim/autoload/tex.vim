"-----------------------------------------------------------------------------"
" Utilities for tex files
"-----------------------------------------------------------------------------"
" Helper function to optionally wrap snippets with command
" NOTE: Check syntax to *left* of cursor because we add text to that environment
function! s:ensure_syntax(value, group, left, right, ...) abort
  let value = succinct#_pre_process(a:value)
  let value = succinct#process_value(value)
  let stack = synstack(line('.'), col('.') - 1)
  if a:0 && a:1
    call filter(stack, 'synIDattr(v:val, "name") ==# a:group')
  else
    call filter(stack, 'synIDattr(v:val, "name") =~? a:group')
  endif
  return empty(stack) && !empty(value) ? a:left . value . a:right : value
endfunction

" Return filetype-specific fold text
" NOTE: This uses frametitle from beamer presentations and labels from tex figures and
" manually escapes backslashes concealed with matchadd() (see also fold#fold_label)
function! tex#fold_text(lnum, ...) abort
  let nline = 100  " maxumimum lines to search
  let label = fold#fold_label(a:lnum, 0)
  let regex = '^\([%\t ]*\)\(.*\)$'
  let [_, indent, label; rest] = matchlist(label, regex)
  let isframe = label =~# '^\\\?begingroup\|^\\\?begin\s*{\s*frame\*\?\s*}'
  let isfloat = label =~# '^\\\?begin\s*{\s*\%(figure\|table\|center\)\*\?\s*}'
  let iscomment = indent =~# '^\s*%'  " also support comments
  let [line1, line2] = [a:lnum + 1, a:lnum + nline]
  if isframe || isfloat
    let head = iscomment ? '^\s*%\s*' : '^\s*'
    let tail = isframe ? 'frametitle' : 'label'
    for lnum in range(line1, min([line2, a:0 ? a:1 : line2]))
      let bool = getline(lnum) =~# head . '\\\?' . tail
      if bool | let label = fold#fold_label(lnum, 0) | break | endif
    endfor
  endif
  if label =~# '{\s*\(%.*\)\?$'  " append lines
    let [line1, line2] = [lnum + 1, lnum + nline]
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

" Translate and format physical input units
" NOTE: This includes standard \, spacing and \mathrm{} encasing. See also climopy
function! tex#format_units(value) abort
  let input = succinct#_pre_process(a:value)
  let input = succinct#process_value(input)
  if empty(input) | return '' | endif
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
        let msg = 'Warning: Invalid units string ' . string(input)
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
  endfor | return tex#ensure_math(output)
endfunction
function! tex#ensure_math(value) abort
  return s:ensure_syntax(a:value, 'math', '$', '$', 1)
endfunction

" Citation source and sink (copied from latexmk)
" NOTE: To get multiple items hit <Shift><Tab>
" See: https://github.com/msprev/fzf-bibtex
function! s:cite_sink(items) abort
  if !executable('bibtex-cite')
    let msg = 'Error: Command bibtex-cite not found'
    redraw | echohl WarningMsg | echom msg | echohl None | return
  endif
  let value = system("bibtex-cite -prefix='@' -postfix='' -separator=','", a:items)
  let value = substitute(value, '@', '', 'g')  " remove label markers
  if mode() =~# 'i'
    let value = succinct#process_value(value)
    call feedkeys(tex#ensure_cite(value), 'tni')
  else
    let msg = 'Warning: Cannot insert references (insert mode required)'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! s:cite_source() abort
  let gsed = has('macunix') ? '/usr/local/bin/gsed' : '/usr/bin/sed'
  if !executable('bibtex-ls')  " see https://github.com/msprev/fzf-bibtex
    let msg = 'Error: Command bibtex-ls not found (required for citations)'
    redraw | echohl ErrorMsg | echom msg | echohl None | return []
  elseif !executable(gsed)
    let msg = 'Error: GNU sed not available (required for citations)'
    redraw | echohl ErrorMsg | echom msg | echohl None | return []
  endif
  let cmd = 'grep -o ''^[^%]*'' ' . shellescape(@%) . ' | ' . gsed . ' -n '
    \ . '''s@^\s*\\\(bibliography\|nobibliography\|addbibresource\){\(.*\)}@\2@p'''
  let [bibs, warns] = [[], []]
  let paths = systemlist(cmd)
  if v:shell_error == 0
    let local = expand('%:h')
    for path in paths
      let path .= path =~? '.bib$' ? '' : '.bib'
      let path = substitute(path, '\\string', '', 'g')
      let path = path =~# '^\~\|^/' ? expand(path) : local . '/' . path
      call add(filereadable(path) ? bibs : warns, path)
    endfor
  endif
  let info = join(map(warns, 'string(v:val)'), ', ')
  let info = empty(info) ? ' not found' : ' ' . msg . ' not found'
  if empty(bibs)
    let msg = 'Error: Bibliography file(s)' . info
    redraw | echohl ErrorMsg | echom msg | echohl None | return []
  elseif !empty(warns)
    let msg = 'Warning: Bibliography file(s)' . info
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
  let $FZF_BIBTEX_SOURCES = join(bibs, ':')
  return 'bibtex-ls ' . join(bibs, ' ')
endfunction
function! tex#fzf_cite() abort
  let opts = {
    \ 'sink*': function('s:cite_sink'),
    \ 'source': s:cite_source(),
    \ 'options': '--multi --height 100% --tiebreak chunk,index --prompt="Source> "',
  \ }
  call fzf#run(opts) | return ''
endfunction
function! tex#ensure_cite(value) abort
  return s:ensure_syntax(a:value, 'texCite', '\citep{', '}')
endfunction

" Graphic path source and sink
" NOTE: This requires fancy awk script
function! s:graphic_sink(items) abort
  let items = map(copy(a:items), 'fnamemodify(v:val, ":t")')
  if mode() =~# 'i'
    let value = succinct#process_value(join(items, ','))
    call feedkeys(tex#ensure_graphic(value), 'tni')
  else
    let msg = 'Warning: Cannot insert graphics (insert mode required)'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! s:graphic_source() abort
  let code = [
    \ 'inside && /}/ {path=$0; if(init) inside=0} {init=0}',
    \ 'inside && /(\n|^)}/ {inside=0}',
    \ 'path {sub(/}.*/, "}", path); print "{" path}',
    \ 'RT ~ /graphicspath/ {init=1; inside=1}',
    \ '/document}/ {exit} {path=""}',
    \ ]
  let awk = has('macunix') ? 'gawk' : 'awk'
  let cmd = "grep -o '^[^%]*' " . shellescape(@%) . ' | '
  let cmd .= awk . " -v RS='[^\\n]*{' '" . join(code, ' ') . "'"
  let base = expand('%:h')
  let inputs = join(systemlist(cmd), '')
  let inputs = split(strpart(inputs, 1, len(inputs) - 2), '}{')
  let [paths, warns] = [[], []]
  for path in inputs
    let abspath = expand(path)  " e.g. $HOME/research/...
    let relpath = expand(base . '/' . path)  " e.g. ./figures/...
    if isdirectory(abspath)
      call add(paths, abspath)
    elseif isdirectory(relpath)
      call add(paths, relpath)
    else
      call add(warns, abspath)
    endif
  endfor
  let outputs = []
  for path in add(paths, base)
    for ext in ['png', 'jpg', 'jpeg', 'pdf', 'eps']
      let files = globpath(path, '*.' . ext, v:true, v:true)
      call map(files, 'fnamemodify(v:val, ":p:h:t") . "/" . fnamemodify(v:val, ":t")')
      call extend(outputs, files)
    endfor
  endfor
  if empty(outputs)
    let msg = join(map(paths + warns, 'string(v:val)'), ', ')
    let msg = 'Error: No figures found in folder(s) ' . msg
    redraw | echohl ErrorMsg | echom msg | echohl None
  elseif !empty(warns)
    let msg = join(map(copy(warns), 'string(v:val)'), ', ')
    let msg = 'Warning: Figure folder(s) ' . msg . ' do not exist'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif | return outputs
endfunction
function! tex#fzf_graphic() abort
  let opts = {
    \ 'sink*': function('s:graphic_sink'),
    \ 'source': s:graphic_source(),
    \ 'options': '--multi --height=100% --tiebreak=chunk,index --prompt="Figure> "',
  \ }
  call fzf#run(opts) | return ''
endfunction
function! tex#ensure_graphic(value) abort
  return s:ensure_syntax(a:value, 'texInputFile', '\includegraphics[scale=1]{', '}')
endfunction

" Reference label source and sink
" See notes in succinct/autoload/utils.vim for why fzf#wrap not allowed
" NOTE: To get multiple items hit <Shift><Tab>
function! s:label_sink(items) abort
  let items = map(copy(a:items), 'substitute(v:val, " (.*)$", "", "")')
  if mode() =~# 'i'
    let value = succinct#process_value(join(items, ','))
    call feedkeys(tex#ensure_label(value), 'tni')
  else
    let msg = 'Warning: Cannot insert labels (insert mode required)'
    redraw | echohl WarningMsg | echom msg | echohl None
  endif
endfunction
function! s:label_source() abort
  let labels = copy(get(b:, 'tags_by_name', []))
  call filter(labels, 'v:val[2] ==# "l"')
  call map(labels, 'v:val[0] . " (" . v:val[1] . ")"')  " label (line number)
  if empty(get(b:, 'tags_by_name', []))
    let msg = 'Error: Tags not found or not available'
    redraw | echohl ErrorMsg | echom msg | echohl None
  elseif empty(labels)
    let msg = 'Error: No document labels found'
    redraw | echohl ErrorMsg | echom msg | echohl None
  endif | return labels
endfunction
function! tex#fzf_labels() abort
  let opts = {
    \ 'sink*': function('s:label_sink'),
    \ 'source': s:label_source(),
    \ 'options': '--height 100% --tiebreak chunk,index --prompt="Label> "',
  \ }
  call fzf#run(opts) | return ''
endfunction
function! tex#ensure_label(value) abort
  return s:ensure_syntax(a:value, 'texC\?refZone', '\cref{', '}', 1)
endfunction
