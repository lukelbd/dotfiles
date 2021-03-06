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
" \ "'": textools#make_snippet(textools#graphic_select(), '\includegraphics{', '}'),
" \ '"': textools#make_snippet(textools#graphic_select(), '\makebox[\textwidth][c]{\includegraphics{', '}}'),
" \ '/': textools#make_snippet(textools#label_select(), '\cref{', '}'),
" \ '?': textools#make_snippet(textools#label_select(), '\ref{', '}'),
" \ ':': textools#make_snippet(textools#cite_select(), '\citet{', '}'),
" \ ';': textools#make_snippet(textools#cite_select(), '\citep{', '}'),
" \ 'k': textools#ensure_math("^{\1Superscript: \1}"),
" \ 'j': textools#ensure_math("_{\1Subscript: \1}"),
" \ 'E': textools#ensure_math("\\times 10^{\1Exponent: \1}"),
call shortcuts#add_snippets({
  \ "\<CR>": " \\textCR\r",
  \ "'": textools#graphic_select(),
  \ '*': '\item',
  \ '+': textools#ensure_math('\sum'),
  \ ',': textools#ensure_math('\Leftarrow'),
  \ '-': '\pause',
  \ '.': textools#ensure_math('\Rightarrow'),
  \ '/': textools#format_units("\1Units: \1"),
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
  \ 'E': textools#ensure_math("\1Exponent: \r..*\r\\\\times 10^{&}\1"),
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
  \ 'j': textools#ensure_math("\1Subscript: \r..*\r_{&}\1"),
  \ 'k': textools#ensure_math("\1Superscript: \r..*\r^{&}\1"),
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
  \ }, 1)

" Surround tools. Currently only overwrite 'r' and 'a' global bracket surrounds
" the 'f', 'p', and 'A' surrounds, and the '(', '[', '{', and '<' surrounds
" Delimiters should also not overlap common text objects like 'w' and 'p'
" Rejected maps:
" \ 'p': "\\begin{minipage}{\\linewidth}\r\\end{minipage}",
" \ 'F': "\\begin{wrapfigure}{r}{0.5\\textwidth}\n\\centering\r\\end{wrapfigure}",
" \ ',': "\\begin{\1\\begin{\1}\r\\end{\1\1}",
" \ '.': "\\\1\\\1{\r}",
" \ 'L': "\\href{\1Link: \1}{\r}",
call shortcuts#add_delims({
  \ "'": "`\r'",
  \ '!': "\\frametitle{\r}",
  \ '"': "``\r''",
  \ '#': "\\begin{enumerate}\r\\end{enumerate}",
  \ '$': "$\r$",
  \ '%': "\\begin{align*}\r\\end{align*}",
  \ '&': "\\begin{description}\r\\end{description}",
  \ '(': "\\left(\r\\right)",
  \ ')': "\\begin{pmatrix}\r\\end{pmatrix}",
  \ '*': "\\begin{itemize}\r\\end{itemize}",
  \ '-': "\\overline{\r}",
  \ '/': "\\frac{\r}{}",
  \ ',': "\1Environment: \r..*\r\\\\begin{&}\1\r\1\r..*\r\\\\end{&}\1",
  \ '.': "\1Command: \r..*\r\\\\&{\1\r\1\r..*\r}\1",
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
  \ ':': "\\begin{alertblock}{}\r\\end{alertblock}",
  \ ';': "\\begin{block}{}\r\\end{block}",
  \ '<': "\\left\\langle \r\\right\\rangle",
  \ '>': "\\vec{\r}",
  \ '?': "\\dfrac{\r}{}",
  \ '@': "\\begin{enumerate}[label=\\alph*.]\r\\end{enumerate}",
  \ 'A': "\\captionof{figure}{\r}",
  \ 'D': "\\ddot{\r}",
  \ 'E': "\{\\color{red}\r}",
  \ 'F': "\\begin{center}\n\\centering\r\\end{center}",
  \ 'G': "\\hidecontent{\\includegraphics{\r}}",
  \ 'I': "\\texttt{\r}",
  \ 'J': "\\underset{}{\r}",
  \ 'K': "\\overset{}{\r}",
  \ 'L': "\1Link: \r..*\r\\\\href{&}{\1\r\1\r..*\r}\1",
  \ 'M': "\\mathbb{\r}",
  \ 'O': "\\mathbf{\r}",
  \ 'R': "\\citet{\r}",
  \ 'S': "{\\usebackgroundtemplate{}\\begin{frame}\r\\end{frame}}",
  \ 'T': "\\begin{table}\n\\centering\r\\end{table}",
  \ 'U': "\\uncover<+->{%\r\}",
  \ 'V': "\\begin{verbatim}\r\\end{verbatim}",
  \ 'X': "\\fbox{\\parbox{\\textwidth}{\r}}\\medskip",
  \ 'Y': "\\begin{python}\r\\end{python}",
  \ 'Z': "\\begin{columns}\r\\end{columns}",
  \ '[': "\\left[\r\\right]",
  \ '\': "\\sqrt{\r}",
  \ ']': "\\begin{bmatrix}\r\\end{bmatrix}",
  \ '^': "\\begin{align}\r\\end{align}",
  \ '_': "\\cancelto{}{\r}",
  \ '`': "\\tilde{\r}",
  \ 'a': "\\caption{\r}",
  \ 'd': "\\dot{\r}",
  \ 'e': "\\emph{\r}",
  \ 'f': "\\begin{figure}\n\\centering\r\\end{figure}",
  \ 'g': "\\includegraphics{\r}",
  \ 'h': "\\hat{\r}",
  \ 'i': "\\textit{\r}",
  \ 'j': "_{\r}",
  \ 'k': "^{\r}",
  \ 'l': "\\mathcal{\r}",
  \ 'm': "\\mathrm{\r}",
  \ 'n': "\\pdfcomment{%\r}",
  \ 'o': "\\textbf{\r}",
  \ 'r': "\\citep{\r}",
  \ 's': "\\begin{frame}\r\\end{frame}",
  \ 't': "\1Alignment: \r..*\r\\\\begin{tabular}{&}\1\r\1\r..*\r\\\\end{tabular}\1",
  \ 'u': "\\underline{\r}",
  \ 'v': "\\verb$\r$",
  \ 'x': "\\boxed{\r}",
  \ 'y': "\\pyth$\r$",
  \ 'z': "\\begin{column}{0.5\\textwidth}\r\\end{column}",
  \ '{': "\\left\\{\r\\right\\}",
  \ '|': "\\left\\|\r\\right\\|",
  \ '}': "\\left\\{\\begin{array}{ll}\r\\end{array}\\right.",
  \ '~': "\\title{\r}",
  \ }, 1)

" " Text object integration
" " " Adpated from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
" " " Also changed begin end modes so they make more sense.
" let s:tex_textobjs_map = {
"   \  'dollar-math-a': {
"   \     'pattern': '[$][^$]*[$]',
"   \     'select': '<buffer> a$',
"   \   },
"   \  'dollar-math-i': {
"   \     'pattern': '[$]\zs[^$]*\ze[$]',
"   \     'select': '<buffer> i$',
"   \   },
"   \ }
" call textobj#user#plugin('latex', s:tex_textobjs_map)

" Running custom or default latexmk command in background
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
    \ 'latexmk ' . texfile . ' ' . opts,
    \ {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
    \ )
endfunction

" Latexmk command and shortcuts
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <silent> <Plug>Execute :<C-u>call <sid>latexmk()<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :<C-u>call <sid>latexmk('--diff')<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :<C-u>call <sid>latexmk('--word')<CR>
