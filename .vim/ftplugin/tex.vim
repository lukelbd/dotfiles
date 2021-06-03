"-----------------------------------------------------------------------------"
" Builtin TeX settings
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just accents, Greek symbols, and math symbols
let g:tex_conceal = 'agmd'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone)
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast = ''  " fast highlighting, but pretty ugly
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1

" DelimitMate integration
let b:delimitMate_quotes = '$ |'
let b:delimitMate_matchpairs = "(:),{:},[:],`:'"

" Snippet dictionaries. Each snippet is made into an <expr> map by prepending
" and appending the strings with single quotes. This lets us make input()
" dependent snippets as shown for the 'j', 'k', and 'E' mappings.
" * \xi is the weird curly one, pronounced 'zai'
" * \chi looks like an x, pronounced 'kai'
" * the 'u' used for {-} and {+} is for 'unary'
" Rejected maps:
" \ "'": shortcuts#make_snippet(shortcuts#graphic_select(), '\includegraphics{', '}'),
" \ '"': shortcuts#make_snippet(shortcuts#graphic_select(), '\makebox[\textwidth][c]{\includegraphics{', '}}'),
" \ '/': shortcuts#make_snippet(shortcuts#label_select(), '\cref{', '}'),
" \ '?': shortcuts#make_snippet(shortcuts#label_select(), '\ref{', '}'),
" \ ':': shortcuts#make_snippet(shortcuts#cite_select(), '\citet{', '}'),
" \ ';': shortcuts#make_snippet(shortcuts#cite_select(), '\citep{', '}'),
let s:snippet_map = {
  \ "\<CR>": " \\textCR\r",
  \ "'": textools#graphic_select(),
  \ '*': '\item',
  \ '+': textools#ensure_math('\sum'),
  \ ',': textools#ensure_math('\Leftarrow'),
  \ '-': '\pause',
  \ '.': textools#ensure_math('\Rightarrow'),
  \ '/': textools#format_units(shortcuts#user_input('Units'), ''),
  \ '0': '\Huge',
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': '\huge',
  \ ':': textools#label_select(),
  \ ';': textools#cite_select(),
  \ '<': textools#ensure_math('\Longleftarrow'),
  \ '=': textools#ensure_math('\equiv'),
  \ '>': textools#ensure_math('\Longrightarrow'),
  \ '_': textools#ensure_math('\prod'),
  \ 'C': textools#ensure_math('\Xi'),
  \ 'D': textools#ensure_math('\Delta'),
  \ 'E': textools#ensure_math(shortcuts#user_input('Exponent'), '\times 10^{', '}'),
  \ 'F': textools#ensure_math('\Phi'),
  \ 'G': textools#ensure_math('\Gamma'),
  \ 'I': textools#ensure_math('\iint'),
  \ 'K': textools#ensure_math('\kappa'),
  \ 'L': textools#ensure_math('\Lambda'),
  \ 'P': textools#ensure_math('\Pi'),
  \ 'Q': textools#ensure_math('\Theta'),
  \ 'S': textools#ensure_math('\Sigma'),
  \ 'T': textools#ensure_math('\chi'),
  \ 'U': textools#ensure_math('{-}'),
  \ 'W': textools#ensure_math('\Omega'),
  \ 'X': textools#ensure_math('\times'),
  \ 'Y': textools#ensure_math('\Psi'),
  \ '[': textools#ensure_math('\partial'),
  \ '\': textools#ensure_math('\mathrm{D}'),
  \ ']': textools#ensure_math('\mathrm{d}'),
  \ 'a': textools#ensure_math('\alpha'),
  \ 'b': textools#ensure_math('\beta'),
  \ 'c': textools#ensure_math('\xi'),
  \ 'd': textools#ensure_math('\delta'),
  \ 'e': textools#ensure_math('\epsilon'),
  \ 'f': textools#ensure_math('\phi'),
  \ 'g': textools#ensure_math('\gamma'),
  \ 'h': textools#ensure_math('\eta'),
  \ 'i': textools#ensure_math('\int'),
  \ 'j': textools#ensure_math(shortcuts#user_input('Subscript'), '_{', '}'),
  \ 'k': textools#ensure_math(shortcuts#user_input('Supersript'), '^{', '}'),
  \ 'l': textools#ensure_math('\lambda'),
  \ 'm': textools#ensure_math('\mu'),
  \ 'n': textools#ensure_math('\nabla'),
  \ 'o': textools#ensure_math('^\circ'),
  \ 'p': textools#ensure_math('\pi'),
  \ 'q': textools#ensure_math('\theta'),
  \ 'r': textools#ensure_math('\rho'),
  \ 's': textools#ensure_math('\sigma'),
  \ 't': textools#ensure_math('\tau'),
  \ 'u': textools#ensure_math('{+}'),
  \ 'v': textools#ensure_math('\nu'),
  \ 'w': textools#ensure_math('\omega'),
  \ 'x': textools#ensure_math('\cdot'),
  \ 'y': textools#ensure_math('\psi'),
  \ 'z': textools#ensure_math('\zeta'),
  \ '~': textools#ensure_math('\sim'),
\ }

" Define snippet variables (analogous to vim-surround approach)
for [s:key, s:snippet] in items(s:snippet_map)
  let b:snippet_{char2nr(s:key)} = s:snippet
endfor

" Surround tools. Currently only overwrite 'r' and 'a' global bracket surrounds
" the 'f', 'p', and 'A' surrounds, and the '(', '[', '{', and '<' surrounds
" Rejected maps:
" \ ':': ['\newpage\hspace{0pt}\vfill', "\n".'\vfill\hspace{0pt}\newpage'],
" \ 'y': ['\begin{python}',       "\n".'\end{python}'],
" \ 'v': ['\begin{verbatim}',     "\n".'\end{verbatim}'],
" \ 'a': ['<',                                '>'],
" \ ';': ['\citep{',                          '}'],
" \ ':': ['\citet{',                          '}'],
let s:surround_map = {
  \ "'": "`\r'",
  \ '!': "\\frametitle{\r}",
  \ '"': "``\r''",
  \ '#': "\\begin{enumerate}\r\n\\end{enumerate}",
  \ '$': "$\r$",
  \ '%': "\\begin{align*}\r\n\\end{align*}",
  \ '&': "\\begin{description}\r\n\\end{description}",
  \ '(': "\\left(\r\\right)",
  \ ')': "\\begin{pmatrix}\r\n\\end{pmatrix}",
  \ '*': "\\begin{itemize}\r\n\\end{itemize}",
  \ '-': "\\overline{\r}",
  \ '/': "\\frac{\r}{}",
  \ ',': "\\begin{\1\\begin{\1}\r\n\\end{\1\1}",
  \ '.': "\\\1\\\1{\r}",
  \ '0': "\\tag{\r}",
  \ '1': "\\section{\r}",
  \ '2': "\\subsection{\r}",
  \ '3': "\\subsubsection{\r}",
  \ '4': "\\section*{\r}",
  \ '5': "\\subsection*{\r}",
  \ '6': "\\subsubsection*{\r}",
  \ '7': "\\ref{\r}",
  \ '8': "\\cref{\r}",
  \ '9': "\\label{\r}",
  \ ':': "\\begin{alertblock}{}\r\n\\end{alertblock}",
  \ ';': "\\begin{block}{}\r\n\\end{block}",
  \ '<': "\\left\\langle \r\\right\\rangle",
  \ '>': "\\uncover<+->{%\r\n\}",
  \ '?': "\\dfrac{\r}{}",
  \ '@': "\\begin{enumerate}[label=\\alph*.]\r\n\\end{enumerate}",
  \ 'A': "\\captionof{figure}{\r}",
  \ 'D': "\\ddot{\r}",
  \ 'E': "\{\\color{red}\r}",
  \ 'F': "\\begin{center}\n\\centering\n\r\n\\end{center}",
  \ 'G': "\\hidecontent{\\includegraphics{\r}}",
  \ 'J': "\\underset{}{\r}",
  \ 'K': "\\overset{}{\r}",
  \ 'L': "\\href{\1Link: \1}{\r}",
  \ 'M': "\\mathbb{\r}",
  \ 'O': "\\mathbf{\r}",
  \ 'R': "\\citet{\r}",
  \ 'S': "{\\usebackgroundtemplate{}\\begin{frame}\r\n\\end{frame}}",
  \ 'T': "\\begin{table}\n\\centering\r\n\\end{table}",
  \ 'V': "\\verb$\r$",
  \ 'X': "\\fbox{\\parbox{\\textwidth}{\r}}\\medskip",
  \ 'Y': "\\pyth$\r$",
  \ 'Z': "\\begin{columns}\r\n\\end{columns}",
  \ '[': "\\left[\r\\right]",
  \ '\': "\\sqrt{\r}",
  \ ']': "\\begin{bmatrix}\r\n\\end{bmatrix}",
  \ '^': "\\begin{align}\r\n\\end{align}",
  \ '_': "\\cancelto{}{\r}",
  \ '`': "\\tilde{\r}",
  \ 'a': "\\caption{\r}",
  \ 'd': "\\dot{\r}",
  \ 'e': "\\emph{\r}",
  \ 'f': "\\begin{figure}\n\\centering\n\r\n\\end{figure}",
  \ 'g': "\\includegraphics{\r}",
  \ 'h': "\\hat{\r}",
  \ 'i': "\\textit{\r}",
  \ 'j': "_{\r}",
  \ 'k': "^{\r}",
  \ 'l': "\\mathcal{\r}",
  \ 'm': "\\mathrm{\r}",
  \ 'n': "\\pdfcomment{%\n\r\n}",
  \ 'o': "\\textbf{\r}",
  \ 'p': "\\begin{minipage}{\\linewidth}\r\n\\end{minipage}",
  \ 'r': "\\citep{\r}",
  \ 's': "\\begin{frame}\r\n\\end{frame}",
  \ 't': "\\begin{tabular}{\r}\n\\end{tabular}",
  \ 'u': "\\underline{\r}",
  \ 'v': "\\vec{\r}",
  \ 'w': "\\begin{wrapfigure}{r}{0.5\\textwidth}\n\\centering\n\r\n\\end{wrapfigure}",
  \ 'x': "\\boxed{\r}",
  \ 'y': "\\texttt{\r}",
  \ 'z': "\\begin{column}{0.5\\textwidth}\r\n\\end{column}",
  \ '{': "\\left\\{\r\\right\\}",
  \ '|': "\\left\\|\r\\right\\|",
  \ '}': "\\left\\{\\begin{array}{ll}\r\n\\end{array}\\right.",
  \ '~': "\\title{\r}",
\ }

" Define surround variables
for [s:key, s:pair] in items(s:surround_map)
  let b:surround_{char2nr(s:key)} = s:pair
endfor

" Text object integration
" " Adpated from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
" " Also changed begin end modes so they make more sense.
" " 'pattern': ['\\begin{[^}]\+}.*\n\s*', '\n^\s*\\end{[^}]\+}.*$'],
let s:tex_textobjs_map = {
  \   'environment': {
  \     'pattern': ['\\begin{[^}]\+}.*\n', '\\end{[^}]\+}'],
  \     'select-a': '<buffer> a,',
  \     'select-i': '<buffer> i,',
  \   },
  \  'command': {
  \     'pattern': ['\\\S\+{', '}'],
  \     'select-a': '<buffer> a.',
  \     'select-i': '<buffer> i.',
  \   },
  \  'paren-math': {
  \     'pattern': ['\\left(', '\\right)'],
  \     'select-a': '<buffer> a(',
  \     'select-i': '<buffer> i(',
  \   },
  \  'bracket-math': {
  \     'pattern': ['\\left\[', '\\right\]'],
  \     'select-a': '<buffer> a[',
  \     'select-i': '<buffer> i[',
  \   },
  \  'curly-math': {
  \     'pattern': ['\\left\\{', '\\right\\}'],
  \     'select-a': '<buffer> a{',
  \     'select-i': '<buffer> i{',
  \   },
  \  'angle-math': {
  \     'pattern': ['\\left\\langle ', '\\right\\rangle'],
  \     'select-a': '<buffer> a<',
  \     'select-i': '<buffer> i<',
  \   },
  \  'abs-math': {
  \     'pattern': ['\\left\\|', '\\right\\|'],
  \     'select-a': '<buffer> a\|',
  \     'select-i': '<buffer> i\|',
  \   },
  \  'dollar-math-a': {
  \     'pattern': '[$][^$]*[$]',
  \     'select': '<buffer> a$',
  \   },
  \  'dollar-math-i': {
  \     'pattern': '[$]\zs[^$]*\ze[$]',
  \     'select': '<buffer> i$',
  \   },
  \  'quote': {
  \     'pattern': ['`', "'"],
  \     'select-a': "<buffer> a'",
  \     'select-i': "<buffer> i'",
  \   },
  \  'quote-double': {
  \     'pattern': ['``', "''"],
  \     'select-a': '<buffer> a"',
  \     'select-i': '<buffer> i"',
  \   },
  \ }
call textobj#user#plugin('latex', s:tex_textobjs_map)

" " Text object integration harmonized with vim-surround (also permit lists or \r strings)
" " Todo: Finish this! You can do it! :) Also define general function and split things up
" " Adpated from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
" " Also changed begin end modes so they make more sense.
" function! s:pair_regex(pair)
"   let pair = escape(a:pair, '.*~$\')
"   let pair = substitute(pair, "\\([\1\2\3\4\5\6]\\).\\{-}\\1", '.\\{-}', 'g')  " replace user prompt indicators
"   let pair = substitute(pair, "\n", '', 'g')  " remove possible literal newline
"   return split(pair, "\r")
" endfunction
" if exists('*textobj#user#plugin')
"   let s:tex_textobjs_map = {}
"   for [s:key, s:pair] in items(s:surround_map)
"     echom s:key
"     echom 'Pair:'
"     echom s:pair
"     echom 'Fixed:'
"     echom s:pair_regex(s:pair)
"     let s:tex_textobjs_map[s:key] = {
"       \ 'pattern': s:pair_regex(s:pair),
"       \ 'select-a': '<buffer> a' . s:key,
"       \ 'select-i': '<buffer> i' . s:key,
"       \ }
"   endfor
"   call textobj#user#plugin('latex', s:tex_textobjs_map)
" endif

" Running latexmk in background
" The `latexmk` script included with this package typesets the document and opens the
" file in the [Skim PDF viewer](https://en.wikipedia.org/wiki/Skim_(software)).
" This script has the following features:
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
let s:path = expand('<sfile>:p:h')
function! s:latexmk(...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Latex compilation requires vim >= 8.0'
    echohl None
    return 1
  endif
  " Jump to logfile if it is open, else open one
  " Warning: Trailing space will be escaped as flag! So trim unless we have any options
  let opts = trim(a:0 ? a:1 : '') . ' -l=' . string(line('.'))
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.latexmk'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.') / 4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d _
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  let num = bufnr(logfile)
  let g:tex_job = job_start(
    \ s:path . '/../bin/latexmk ' . texfile . ' ' . opts,
    \ {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
    \ )
endfunction

" Latexmk command and shortcuts
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <silent> <Plug>Execute :<C-u>call <sid>latexmk()<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :<C-u>call <sid>latexmk('--diff')<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :<C-u>call <sid>latexmk('--word')<CR>
