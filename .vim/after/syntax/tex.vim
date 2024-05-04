"------------------------------------------------------------------------------" {{{1
" Improve tex syntax. Adapted from vimtex and builds on $VIMRUNTIME/syntax/tex.vim
"------------------------------------------------------------------------------"
" Perform spell checking when no syntax {{{2
" This will enable spell checking e.g. in toplevel of included files
if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  finish
endif
scriptencoding utf-8  " non-ascii character below
syntax sync minlines=500  " increase highlight accuracy
syntax spell toplevel

" Disable spellcheck within commands {{{2
" Avoid disabling spellcheck within environments like textbf and naked braces {}.
" Note: Here just copied the $VIMRUNTIME/syntax/tex.vim line and removed the
" 'transparent' flag. Could revisit and consider improving but so far so good.
syntax region texMatcherNM matchgroup=Delimiter
  \ start='{' skip='\\\|\[{}]' end="}"
  \ contains=@NoSpell,@texMatchNMGroup,texError

" Support comment block folding {{{2
" Ignores empty and comment-character-only lines when defining beginning and ends of
" folding regions. This is useful for revisions and templates with instruction blocks
" Note: Critical to use contains=texComment since contains=@texFoldGroup creates nested
" comment zones that require extra lookbehind 'start' regex. Not sure why this works.
" Note: Have to wrap 'start' in zero-length atom so end can be found on same line,
" and crazy 'end' was created through trial-and-error (not sure why \S\@= needed).
syntax region texCommentZone transparent
  \ start='\(^\s*%\([^ \t%-]\|\s\+\S\)\)\@='
  \ end='^\s*%\([^ \t%-]\|\s\+\S\).*\(\(\%$\|\n\s*\|%\s*$\)\+\(\%$\|^\s*\S\@=\([^%]\|%[%-]\)\)\)\@='
  \ keepend contains=@NoSpell,texComment fold
syntax cluster texFoldGroup add=texCommentZone
syntax cluster texPreambleMatchGroup add=texCommentZone

" Support figure and table folding {{{2
" Math regions are folded by default (see TexNewMathZone, $VIMRUNTIME/syntax/tex.vim)
" Note: The 'keepend' is critical or else zone can persist beyond figures. Not sure
" why... supposedly just ends nested environments when parent environment is found.
syntax region texAlertZone transparent
  \ start='\\begin\s*{\s*alertblock\s*}' end='\\end\s*{\s*alertblock\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texBlockZone transparent
  \ start='\\begin\s*{\s*block\s*}' end='\\end\s*{\s*block\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texCenterZone transparent
  \ start='\\begin\s*{\s*center\s*}' end='\\end\s*{\s*center\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texFigureZone transparent
  \ start='\\begin\s*{\s*figure\*\?\s*}' end='\\end\s*{\s*figure\*\?\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texFrameZone transparent
  \ start='\(^\s*\(%.*\)\?\n\)\@<=\\begin\s*{\s*frame\*\?\s*}' end='\\end\s*{\s*frame\*\?\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texGroupZone transparent
  \ start='\\begingroup' end='\\endgroup'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texTableZone transparent
  \ start='\\begin\s*{\s*table\s*}' end='\\end\s*{\s*table\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texTabular transparent
  \ start='\\begin\s*{\s*tabular\s*}' end='\\end\s*{\s*tabular\s*}'
  \ keepend contains=@texFoldGroup,@NoSpell fold
syntax cluster texFoldGroup add=texAlertZone
syntax cluster texFoldGroup add=texBlockZone
syntax cluster texFoldGroup add=texCenterZone
syntax cluster texFoldGroup add=texFigureZone
syntax cluster texFoldGroup add=texFrameZone
syntax cluster texFoldGroup add=texGroupZone
syntax cluster texFoldGroup add=texTableZone
syntax cluster texFoldGroup add=texTabular

" Support abstract author and caption folding {{{2
" Only begin..end texAbstract environment outside preamble is folded by default
" Note: Adapted from texTitle and texAbstract in $VIMRUNTIME/syntax/tex.vim. Here
" 'matchgroup' highlights the 'start' and 'end' patterns differently from region.
" Note: Caption texStatement is consistent with existing \label{} and \ref{} assignment
" to texStatement. Also without this folds end on \end{figure} (unsure why).
syntax region texAuthors matchgroup=texSection
  \ start='\\authors\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texAbstracts matchgroup=texSection
  \ start='\\abstract\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texCaption matchgroup=texStatement
  \ start='\\caption\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texFigureCaption matchgroup=texStatement
  \ start='\\captionof\s*{\s*figure\s*}\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texTableCaption matchgroup=texStatement
  \ start='\\captionof\s*{\s*table\s*}\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax cluster texFoldGroup add=texAuthors
syntax cluster texFoldGroup add=texAbstracts
syntax cluster texFoldGroup add=texCaption
syntax cluster texFoldGroup add=texFigureCaption
syntax cluster texFoldGroup add=texTableCaption
syntax cluster texPreambleMatchGroup add=texAuthors
syntax cluster texPreambleMatchGroup add=texAbstracts
syntax cluster texPreambleMatchGroup add=texAbstract

"------------------------------------------------------------------------------" {{{1
" Command improvements
"------------------------------------------------------------------------------"
" Improve handling of newcommand and newenvironment {{{2
" Allow arguments in newenvironments
syntax region texEnvName contained matchgroup=Delimiter
  \ start="{"rs=s+1 end="}"
  \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
syntax region texEnvArgs contained matchgroup=Delimiter
  \ start="\["rs=s+1 end="]"
  \ nextgroup=texEnvBgn,texEnvArgs
  \ skipwhite skipnl
syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

" Add support for \renewcommand, \renewenvironment, DefParams {{{2
syntax match texNewCmd "\\renewcommand\>"
  \ nextgroup=texCmdName skipwhite skipnl
syntax match texNewEnv "\\renewenvironment\>"
  \ nextgroup=texEnvName skipwhite skipnl
syntax match texDefParmNested contained "##\+\d\+"
syntax cluster texEnvGroup add=texDefParmNested
syntax cluster texCmdGroup add=texDefParmNested
syntax match texInputFile
  \ /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
  \ contains=texStatement,texInputCurlies,texInputFileOpt
highlight def link texDefParmNested Identifier

" Italic font, bold font, and conceals {{{2
if get(g:, 'tex_fast', 'b') =~# 'b'
  let s:conceal =
    \ (has('conceal') && get(g:, 'tex_conceal', 'b') =~# 'b')
    \ ? 'concealends' : ''
  for [s:style, s:group, s:commands] in [
      \ ['texItalStyle', 'texItalGroup', ['emph', 'textit']],
      \ ['texBoldStyle', 'texBoldGroup', ['textbf']],
      \ ]
    for s:cmd in s:commands
      execute 'syntax region' s:style 'matchgroup=texTypeStyle'
        \ 'start="\\' . s:cmd . '\s*{" end="}"'
        \ 'contains=@Spell,@' . s:group
        \ s:conceal
    endfor
    execute 'syntax cluster texMatchGroup add=' . s:style
  endfor
endif

" Add syntax highlighting for \url, \href, \hyperref {{{2
syntax match texStatement '\\url\ze[^\ta-zA-Z]' nextgroup=texUrlVerb
syntax region texUrlVerb matchgroup=Delimiter
      \ start='\z([^\ta-zA-Z]\)' end='\z1' contained

syntax match texStatement '\\url\ze\s*{' nextgroup=texUrl
syntax region texUrl matchgroup=Delimiter start='{' end='}' contained

syntax match texStatement '\\href' nextgroup=texHref
syntax region texHref matchgroup=Delimiter start='{' end='}' contained
      \ nextgroup=texMatcher

syntax match texStatement '\\hyperref' nextgroup=texHyperref
syntax region texHyperref matchgroup=Delimiter start='\[' end='\]' contained

highlight link texUrl Function
highlight link texUrlVerb texUrl
highlight link texHref texUrl
highlight link texHyperref texRefZone

"-----------------------------------------------------------------------------" {{{1
" Integration support
"-----------------------------------------------------------------------------"
" Add support for biblatex and csquotes packages {{{2
if get(g:, 'tex_fast', 'r') =~# 'r'
  for s:pattern in [
    \ 'bibentry',
    \ 'cite[pt]?\*?',
    \ 'citeal[tp]\*?',
    \ 'cite(num|text|url)',
    \ '[Cc]ite%(title|author|year(par)?|date)\*?',
    \ '[Pp]arencite\*?',
    \ 'foot%(full)?cite%(text)?',
    \ 'fullcite',
    \ '[Tt]extcite',
    \ '[Ss]martcite',
    \ 'supercite',
    \ '[Aa]utocite\*?',
    \ '[Ppf]?[Nn]otecite',
    \ '%(text|block)cquote\*?',
    \ ]
    execute 'syntax match texStatement'
      \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
      \ 'nextgroup=texRefOption,texCite'
  endfor
  for s:pattern in [
    \ '[Cc]ites',
    \ '[Pp]arencites',
    \ 'footcite%(s|texts)',
    \ '[Tt]extcites',
    \ '[Ss]martcites',
    \ 'supercites',
    \ '[Aa]utocites',
    \ '[pPfFsStTaA]?[Vv]olcites?',
    \ 'cite%(field|list|name)',
    \ ]
    execute 'syntax match texStatement'
      \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
      \ 'nextgroup=texRefOptions,texCites'
  endfor
  for s:pattern in [
    \ '%(foreign|hyphen)textcquote\*?',
    \ '%(foreign|hyphen)blockcquote',
    \ 'hybridblockcquote',
    \ ]
    execute 'syntax match texStatement'
      \ '/\v\\' . s:pattern . '\ze\s*%(\[|\{)/'
      \ 'nextgroup=texQuoteLang'
  endfor
  syntax region texRefOptions contained matchgroup=Delimiter
    \ start='\[' end=']'
    \ contains=@texRefGroup,texRefZone
    \ nextgroup=texRefOptions,texCites
  syntax region texCites contained matchgroup=Delimiter
    \ start='{' end='}'
    \ contains=@texRefGroup,texRefZone,texCites
    \ nextgroup=texRefOptions,texCites
  syntax region texQuoteLang contained matchgroup=Delimiter
    \ start='{' end='}'
    \ transparent
    \ contains=@texMatchGroup
    \ nextgroup=texRefOption,texCite
  highlight def link texRefOptions texRefOption
  highlight def link texCites texCite
endif

" Add support for array package {{{2
" The following code changes inline math so as to support the
" column specifiers [0], e.g. \begin{tabular}{*{3}{>{$}c<{$}}}
" [0]: https://en.wikibooks.org/wiki/LaTeX/Tables#Column_specification_using_.3E.7B.5Ccmd.7D_and_.3C.7B.5Ccmd.7D
if exists('b:vimtex.packages.array') && get(g:, 'tex_fast', 'M') =~# 'M'
  syntax clear texMathZoneX
  if has('conceal') && &encoding ==# 'utf-8' && get(g:, 'tex_conceal', 'd') =~# 'd'
    syntax region texMathZoneX
      \ matchgroup=Delimiter
      \ start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$"
      \ matchgroup=Delimiter
      \ end="\$" end="%stopzone\>"
      \ concealends contains=@texMathZoneGroup
  else
    syntax region texMathZoneX
      \ matchgroup=Delimiter start="\([<>]{\)\@<!\$" skip="\%(\\\\\)*\\\$"
      \ matchgroup=Delimiter end="\$" end="%stopzone\>"
      \ contains=@texMathZoneGroup
  endif
endif

" Add support for cleveref package {{{2
if get(g:, 'tex_fast', 'r') =~# 'r'
  syntax match texStatement '\\\(\(label\)\?c\(page\)\?\|C\|auto\)ref\>'
    \ nextgroup=texCRefZone
  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texStatement '\\c\(page\)\?refrange\>'
    \ nextgroup=texCRefZoneRange skipwhite skipnl
  " \label[xxx]{asd}
  syntax match texStatement '\\label\[.\{-}\]'
    \ nextgroup=texCRefZone skipwhite skipnl
    \ contains=texCRefLabelOpts
  syntax region texCRefZone contained matchgroup=Delimiter
    \ start="{" end="}"
    \ contains=@texRefGroup,texRefZone
  syntax region texCRefZoneRange contained matchgroup=Delimiter
    \ start="{" end="}"
    \ contains=@texRefGroup,texRefZone
    \ nextgroup=texCRefZone skipwhite skipnl
  syntax region texCRefLabelOpts contained matchgroup=Delimiter
    \ start='\[' end=']'
    \ contains=@texRefGroup,texRefZone
  highlight link texCRefZone texRefZone
  highlight link texCRefZoneRange texRefZone
  highlight link texCRefLabelOpts texCmdArgs
endif

" Add support for varioref package {{{2
if get(g:, 'tex_fast', 'r') =~# 'r'
  syntax match texStatement '\\Vref\>' nextgroup=texVarioRefZone
  syntax region texVarioRefZone contained matchgroup=Delimiter
    \ start="{" end="}" contains=@texRefGroup,texRefZone
  highlight link texVarioRefZone texRefZone
endif

" Add support for listings package {{{2
syntax region texZone
  \ start="\\begin{lstlisting}"rs=s
  \ end="\\end{lstlisting}\|%stopzone\>"re=e
  \ keepend
  \ contains=texBeginEnd
syntax match texInputFile
  \ " \\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
  \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

" Add support for moreverb package {{{2
if exists('g:tex_verbspell')
  syntax region texZone start="\\begin{verbatimtab}" end="\\end{verbatimtab}\|%stopzone\>" contains=@Spell
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>" contains=@Spell
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>" contains=@Spell
else
  syntax region texZone start="\\begin{verbatimtab}" end="\\end{verbatimtab}\|%stopzone\>"
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>"
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>"
endif

" Add support for beamer package {{{2
syntax match texBeamerDelimiter '<\|>' contained
syntax match texBeamerOpt '<[^>]*>' contained contains=texBeamerDelimiter
syntax match texStatementBeamer '\\only\(<[^>]*>\)\?' contains=texBeamerOpt
syntax match texStatementBeamer '\\item<[^>]*>' contains=texBeamerOpt
syntax match texInputFile
  \ '\\includegraphics<[^>]*>\(\[.\{-}\]\)\=\s*{.\{-}}'
  \ contains=texStatement,texBeamerOpt,texInputCurlies,texInputFileOpt
syntax cluster texDocGroup add=texStatementBeamer
highlight link texStatementBeamer texStatement
highlight link texBeamerOpt Identifier
highlight link texBeamerDelimiter Delimiter

" Add support for amsmath package {{{2
" This is based on Charles E. Campbell's amsmath.vba file dated 2017-10-12
call TexNewMathZone('Z', 'align', 1)
call TexNewMathZone('Y', 'alignat', 1)
call TexNewMathZone('X', 'equation', 1)
call TexNewMathZone('W', 'flalign', 1)
call TexNewMathZone('V', 'gather', 1)
call TexNewMathZone('U', 'multline', 1)
call TexNewMathZone('T', 'xalignat', 1)
call TexNewMathZone('S', 'xxalignat', 0)
execute 'syntax match texBadMath ''\\end\s*{\s*\(' . join([
  \ 'align', 'alignat', 'equation', 'flalign', 'gather', 'multline', 'xalignat', 'xxalignat'
  \ ], '\|') . '\)\*\=\s*}'''

" Amsmath [lr][vV]ert (Holger Mitschke)
for s:texmath in [
  \ ['\\lvert', '|'], ['\\rvert', '|'], ['\\lVert', '‖'], ['\\rVert', '‖'],
  \ ]
  execute "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
    \ . s:texmath[0] . "' contained conceal cchar=" . s:texmath[1]
endfor

"-----------------------------------------------------------------------------" {{{1
" Nested syntax support
"-----------------------------------------------------------------------------"
" Nested syntax highlighting for dot {{{2
unlet b:current_syntax
syntax include @DOT syntax/dot.vim
syntax cluster texDocGroup add=texZoneDot
syntax region texZoneDot
  \ start="\\begin{dot2tex}"rs=s
  \ end="\\end{dot2tex}"re=e
  \ keepend
  \ transparent
  \ contains=texBeginEnd,@DOT
let b:current_syntax = 'tex'

" Nested syntax highlighting for lualatex {{{2
unlet b:current_syntax
syntax include @LUA syntax/lua.vim
syntax cluster texDocGroup add=texZoneLua
syntax region texZoneLua
  \ start='\\begin{luacode\*\?}'rs=s
  \ end='\\end{luacode\*\?}'re=e
  \ keepend
  \ transparent
  \ contains=texBeginEnd,@LUA
syntax match texStatement '\\\(directlua\|luadirect\)' nextgroup=texZoneLuaArg
syntax region texZoneLuaArg matchgroup=Delimiter
  \ start='{'
  \ end='}'
  \ contained
  \ contains=@LUA
let b:current_syntax = 'tex'

" Nested syntax highlighting for gnuplottex {{{2
unlet b:current_syntax
syntax include @GNUPLOT syntax/gnuplot.vim
syntax cluster texDocGroup add=texZoneGnuplot
syntax region texZoneGnuplot
  \ start='\\begin{gnuplot}\(\_s*\[\_[\]]\{-}\]\)\?'rs=s
  \ end='\\end{gnuplot}'re=e
  \ keepend
  \ transparent
  \ contains=texBeginEnd,texBeginEndModifier,@GNUPLOT
let b:current_syntax = 'tex'

" Nested syntax highlighting for asymptote {{{2
let s:asypath = globpath(&runtimepath, 'syntax/asy.vim')
if !empty(s:asypath)
  unlet b:current_syntax
  syntax include @ASYMPTOTE syntax/asy.vim
  syntax cluster texDocGroup add=texZoneAsymptote
  syntax region texZoneAsymptote
    \ start='\\begin{asy}'rs=s
    \ end='\\end{asy}'re=e
    \ keepend
    \ transparent
    \ contains=texBeginEnd,texBeginEndModifier,@ASYMPTOTE
  syntax region texZoneAsymptote
    \ start='\\begin{asydef}'rs=s
    \ end='\\end{asydef}'re=e
    \ keepend
    \ transparent
    \ contains=texBeginEnd,texBeginEndModifier,@ASYMPTOTE
  let b:current_syntax = 'tex'
endif

" Nested syntax highlighting for minted {{{2
" Set all minted environments to listings
syntax cluster texFoldGroup add=texZoneMinted
syntax region texZoneMinted
  \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
  \ end="\\end{minted}"re=e
  \ keepend
  \ contains=texMinted

" Add minted syntax support for desired languages
for s:entry in get(g:, 'vimtex_syntax_minted', [])
  " Support for languages
  let s:lang = s:entry.lang
  let s:syntax = get(s:entry, 'syntax', s:lang)
  let s:group_name = 'texZoneMinted' . toupper(s:lang[0]) . s:lang[1:]
  execute 'syntax cluster texFoldGroup add=' . s:group_name
  unlet b:current_syntax
  execute 'syntax include @' . toupper(s:lang) 'syntax/' . s:syntax . '.vim'
  if has_key(s:entry, 'ignore')
    execute 'syntax cluster' toupper(s:lang)
      \ 'remove=' . join(s:entry.ignore, ',')
  endif
  execute 'syntax region' s:group_name
    \ 'start="\\begin{minted}\_[^}]\{-}{' . s:lang . '}"rs=s'
    \ 'end="\\end{minted}"re=e'
    \ 'keepend'
    \ 'transparent'
    \ 'contains=texMinted,@' . toupper(s:lang)
  " Support for custom environment names
  " Match starred environments with options
  for s:env in get(s:entry, 'environments', [])
    execute 'syntax region' s:group_name
      \ 'start="\\begin{' . s:env . '}"rs=s'
      \ 'end="\\end{' . s:env . '}"re=e'
      \ 'keepend'
      \ 'transparent'
      \ 'contains=texBeginEnd,@' . toupper(s:lang)
    execute 'syntax region' s:group_name
      \ 'start="\\begin{' . s:env . '\*}\s*{\_.\{-}}"rs=s'
      \ 'end="\\end{' . s:env . '\*}"re=e'
      \ 'keepend'
      \ 'transparent'
      \ 'contains=texMintedStarred,texBeginEnd,@' . toupper(s:lang)
    execute 'syntax match texMintedStarred'
      \ '"\\begin{' . s:env . '\*}\s*{\_.\{-}}"'
      \ 'contains=texBeginEnd,texDelimiter'
  endfor
endfor

" Finish minted syntax support
let b:current_syntax = 'tex'
syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
  \ contains=texBeginEnd,texMintedName
syntax match texMinted '\\end{minted}'
  \ contains=texBeginEnd
syntax match texMintedName '{\w\+}' contained
highlight link texMintedName texBeginEndName
