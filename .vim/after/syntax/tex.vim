"------------------------------------------------------------------------------"
" Author: Karl Yngve Lervåg
" Forked: Luke Davis
" Edited: 2018-07-26
" Tweak tex syntax. Adapted from vimtex. Builds upon native $VIMRUNTIME/syntax/tex.vim
" syntax highlighting sysstem. Should re-download vimtex in future.
"------------------------------------------------------------------------------"
if !exists('b:current_syntax')
  let b:current_syntax = 'tex'
elseif b:current_syntax !=# 'tex'
  finish
endif
scriptencoding utf-8  " non-ascii character below
syntax sync minlines=500  " increase highlight accuracy

" Conceal backslash commands. Only matchadd works for some reason. Also ignores e.g.
" \command1\command2, which would otherwise be unreadable and is common in macros.
" Warning: This will make highlight searches really weird if you make the 'priority'
" (third argument, default 10) higher than the :hlsearch priority of 0. Note conceal
" :syntax match instead of matchadd() fails, since wherever backslash is concealed,
" 'overwrites' existing match. See: https://vi.stackexchange.com/q/5696/8084
call matchadd(
  \ 'Conceal',
  \ '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@=', 0, -1, {'conceal': ''})

" Add highlighting for empty line preceding paragraph or section (i.e. ignoring empty
" lines before commands). Helpful for when navigating huge documents.
" Note: Here matchadd() is required instead of syntax match for some reason. Also
" note complex lookbehinds significantly slow things down so keep simple.
highlight Paragraph ctermfg=NONE ctermbg=Green | call matchadd(
  \ 'Paragraph',
  \ '^\s*\n\(\s*$\)\@!')

" Disable spellcheck within yellow-highlighted curly brace commands (e.g. preamble)
" but do not disable spellcheck within environments like textbf and naked braces {}.
" Note: Here just copied the :SyntaxFile line and removed the 'transparent'
" flag. Should revisit and consider expanding.
syntax region texMatcherNM matchgroup=Delimiter
  \ start='{' skip='\\\|\[{}]' end="}"
  \ contains=@texMatchNMGroup,texError,@NoSpell

" Enable syntax folding of abstracts authors and captions. By default only begin..end
" begin..end texAbstract environment is folded an only in the preamble
" Note: Adapted from texTitle and texAbstract in $VIMRUNTIME/syntax/tex.vim
syntax region texAbstracts matchgroup=texSection
  \ start='\\abstract\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texAuthors matchgroup=texSection
  \ start='\\authors\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax region texCaption transparent
  \ start='\\caption\s*{' end='}'
  \ contains=@texFoldGroup,@Spell fold
syntax cluster texFoldGroup add=texAbstracts
syntax cluster texFoldGroup add=texAuthors
syntax cluster texFoldGroup add=texCaption
syntax cluster texPreambleMatchGroup add=texAbstracts
syntax cluster texPreambleMatchGroup add=texAbstract
syntax cluster texPreambleMatchGroup add=texAuthors

" Enable syntax folding of figures and tables. By default only math environments
" are folded (see TexNewMathZone below and in $VIMRUNTIME/syntax.vim)
" Note: The 'keepend' is critical or else zone seems to persist beyond figures.
syntax region texFigureZone transparent
  \ start='\\begin\s*{\s*figure\*\?\s*}' end='\\end\s*{\s*figure\*\?\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texTableZone transparent
  \ start='\\begin\s*{\s*table\s*}' end='\\end\s*{\s*table\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax region texTabular transparent
  \ start='\\begin\s*{\s*tabular\s*}' end='\\end\s*{\s*tabular\s*}'
  \ keepend contains=@texFoldGroup,@Spell fold
syntax cluster texFoldGroup add=texFigureZone
syntax cluster texFoldGroup add=texTableZone
syntax cluster texFoldGroup add=texTabular

"------------------------------------------------------------------------------"
" Original plugin
"------------------------------------------------------------------------------"
" Perform spell checking when there is no syntax
" This will enable spell checking e.g. in toplevel of included files
syntax spell toplevel

" Improve handling of newcommand and newenvironment commands
" Allow arguments in newenvironments
syntax region texEnvName contained matchgroup=Delimiter
  \ start="{"rs=s+1 end="}"
  \ nextgroup=texEnvBgn,texEnvArgs contained skipwhite skipnl
syntax region texEnvArgs contained matchgroup=Delimiter
  \ start="\["rs=s+1 end="]"
  \ nextgroup=texEnvBgn,texEnvArgs
  \ skipwhite skipnl
syntax cluster texEnvGroup add=texDefParm,texNewEnv,texComment

" Add support for \renewcommand and \renewenvironment
syntax match texNewCmd "\\renewcommand\>"
  \ nextgroup=texCmdName skipwhite skipnl
syntax match texNewEnv "\\renewenvironment\>"
  \ nextgroup=texEnvName skipwhite skipnl

" Match nested DefParms
syntax match texDefParmNested contained "##\+\d\+"
syntax cluster texEnvGroup add=texDefParmNested
syntax cluster texCmdGroup add=texDefParmNested
syntax match texInputFile
  \ /\\includepdf\%(\[.\{-}\]\)\=\s*{.\{-}}/
  \ contains=texStatement,texInputCurlies,texInputFileOpt
highlight def link texDefParmNested Identifier

" Allow subequations (fixes #1019)
" This should be temporary, as it seems subequations is erroneously part of
" texBadMath from Charles Campbell's syntax plugin.
syntax match texBeginEnd
  \ "\(\\begin\>\|\\end\>\)\ze{subequations}" nextgroup=texBeginEndName

" Italic font, bold font, and conceals
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

" Add syntax highlighting for \url, \href, \hyperref

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

" Add support for biblatex and csquotes packages (cite commands)
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

" Add support for array package
" The following code changes inline math so as to support the column
" specifiers [0], e.g.
" \begin{tabular}{*{3}{>{$}c<{$}}}
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

" Add support for cleveref package
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

" Add support for varioref package
if get(g:, 'tex_fast', 'r') =~# 'r'
  syntax match texStatement '\\Vref\>' nextgroup=texVarioRefZone
  syntax region texVarioRefZone contained matchgroup=Delimiter
    \ start="{" end="}" contains=@texRefGroup,texRefZone
  highlight link texVarioRefZone texRefZone
endif

" Add support for listings package
syntax region texZone
  \ start="\\begin{lstlisting}"rs=s
  \ end="\\end{lstlisting}\|%stopzone\>"re=e
  \ keepend
  \ contains=texBeginEnd
syntax match texInputFile
  \ " \\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
  \ contains=texStatement,texInputCurlies,texInputFileOpt
syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

" Add support for moreverb package
if exists('g:tex_verbspell')
  syntax region texZone start="\\begin{verbatimtab}" end="\\end{verbatimtab}\|%stopzone\>" contains=@Spell
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>" contains=@Spell
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>" contains=@Spell
else
  syntax region texZone start="\\begin{verbatimtab}" end="\\end{verbatimtab}\|%stopzone\>"
  syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>"
  syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>"
endif

" Add support for beamer package
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

" Add support for amsmath package
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
  \ 'align',
  \ 'alignat',
  \ 'equation',
  \ 'flalign',
  \ 'gather',
  \ 'multline',
  \ 'xalignat',
  \ 'xxalignat'], '\|') . '\)\*\=\s*}'''

" Amsmath [lr][vV]ert (Holger Mitschke)
for s:texmath in [
  \ ['\\lvert', '|'],
  \ ['\\rvert', '|'],
  \ ['\\lVert', '‖'],
  \ ['\\rVert', '‖'],
  \ ]
  execute
    \ "syntax match texMathDelim '\\\\[bB]igg\\=[lr]\\="
    \ . s:texmath[0] . "' contained conceal cchar=" . s:texmath[1]
endfor

" Nested syntax highlighting for dot
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

" Nested syntax highlighting for lualatex
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

" Nested syntax highlighting for gnuplottex
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

" Nested syntax highlighting for asymptote
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

" Nested syntax highlighting for minted
" First set all minted environments to listings
syntax cluster texFoldGroup add=texZoneMinted
syntax region texZoneMinted
  \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
  \ end="\\end{minted}"re=e
  \ keepend
  \ contains=texMinted

" Next add nested syntax support for desired languages
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

" Finish
let b:current_syntax = 'tex'
syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
  \ contains=texBeginEnd,texMintedName
syntax match texMinted '\\end{minted}'
  \ contains=texBeginEnd
syntax match texMintedName '{\w\+}' contained
highlight link texMintedName texBeginEndName
