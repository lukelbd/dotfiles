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

" Bibtex cache directory
let s:cache_dir = expand('~/Library/Caches/bibtex')
if isdirectory(s:cache_dir)
  let $FZF_BIBTEX_CACHEDIR = s:cache_dir
endif

" Running custom or default latexmk command in background
" Warning: Trailing space will be escaped as flag! So trim unless we have any options
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')  " copied from autoreload/plug.vim
let s:path = expand('<sfile>:p:h')
function! s:latexmk(...) abort
  if !s:vim8
    echohl ErrorMsg
    echom 'Error: Latex compilation requires vim >= 8.0'
    echohl None
    return 1
  endif
  let opts = trim(a:0 ? a:1 : '') . ' -l=' . string(line('.'))
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.latexmk'
  let lognum = bufwinnr(logfile)
  if lognum == -1  " open a logfile window
    silent! exe string(winheight('.') / 4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else  " jump to logfile window and clean its contents
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d _
    silent! exe winnr('#') . 'wincmd w'
  endif
  let num = bufnr(logfile)
  let g:tex_job = job_start(
    \ 'latexmk ' . texfile . ' ' . opts,
    \ {'out_io': 'buffer', 'out_buf': num, 'err_io': 'buffer', 'err_buf': num}
    \ )  " run job in realtime
endfunction

" Latexmk command and shortcuts
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <silent> <Leader>\ :<C-u>call system(
  \ 'synctex view ' . @% . ' displayline -r ' . line('.') . ' ' . expand('%:r') . '.pdf ' . @%
  \ )<CR>
noremap <buffer> <silent> <Plug>Execute :<C-u>call <sid>latexmk()<CR>
noremap <buffer> <silent> <Plug>AltExecute1 :<C-u>call <sid>latexmk('--diff')<CR>
noremap <buffer> <silent> <Plug>AltExecute2 :<C-u>call <sid>latexmk('--word')<CR>

" Snippet dictionaries. Each snippet is made into an <expr> map by prepending
" and appending the strings with single quotes. This lets us make input()
" dependent snippets as shown for the 'j', 'k', and 'E' mappings.
" * \xi is the weird curly one, pronounced 'zai'
" * \chi looks like an x, pronounced 'kai'
" * the 'u' used for {-} and {+} is for 'unary'
" Rejected maps:
" \ "'": tex#make_snippet(tex#graphic_select(), '\includegraphics{', '}'),
" \ '"': tex#make_snippet(tex#graphic_select(), '\makebox[\textwidth][c]{\includegraphics{', '}}'),
" \ '/': tex#make_snippet(tex#label_select(), '\cref{', '}'),
" \ '?': tex#make_snippet(tex#label_select(), '\ref{', '}'),
" \ ':': tex#make_snippet(tex#cite_select(), '\citet{', '}'),
" \ ';': tex#make_snippet(tex#cite_select(), '\citep{', '}'),
" \ 'k': tex#ensure_math("^{\1Superscript: \1}"),
" \ 'j': tex#ensure_math("_{\1Subscript: \1}"),
" \ 'E': tex#ensure_math("\\times 10^{\1Exponent: \1}"),
call succinct#add_snippets({
  \ "\<CR>": " \\textCR\r",
  \ "'": tex#ensure_math('\mathrm{d}'),
  \ '"': tex#ensure_math('\mathrm{D}'),
  \ '*': '\item',
  \ '+': tex#ensure_math('\sum'),
  \ ',': tex#ensure_math('\Leftarrow'),
  \ '-': '\pause',
  \ '.': tex#ensure_math('\Rightarrow'),
  \ '/': tex#format_units("\1Units: \1"),
  \ '[': tex#ensure_math('{-}'),
  \ ']': tex#ensure_math('{+}'),
  \ '0': tex#label_select(),
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': tex#label_select(),
  \ ';': tex#ensure_math('\partial'),
  \ '<': tex#ensure_math('\Longleftarrow'),
  \ '=': tex#ensure_math('\equiv'),
  \ '>': tex#ensure_math('\Longrightarrow'),
  \ '_': tex#ensure_math('\prod'),
  \ 'C': tex#ensure_math('\Xi'),
  \ 'D': tex#ensure_math('\Delta'),
  \ 'E': tex#ensure_math("\1Exponent: \r..*\r\\\\times 10^{&}\1"),
  \ 'F': tex#ensure_math('\Phi'),
  \ 'G': tex#graphic_select(),
  \ 'H': tex#ensure_math('\rho'),
  \ 'I': tex#ensure_math('\iint'),
  \ 'K': tex#ensure_math('\kappa'),
  \ 'L': tex#ensure_math('\Lambda'),
  \ 'O': tex#ensure_math('^\circ'),
  \ 'P': tex#ensure_math('\Pi'),
  \ 'Q': tex#ensure_math('\Theta'),
  \ 'R': tex#cite_select(),
  \ 'S': tex#ensure_math('\Sigma'),
  \ 'U': tex#ensure_math('\Gamma'),
  \ 'W': tex#ensure_math('\Omega'),
  \ 'X': tex#ensure_math('\times'),
  \ 'Y': tex#ensure_math('\Psi'),
  \ 'a': tex#ensure_math('\alpha'),
  \ 'b': tex#ensure_math('\beta'),
  \ 'c': tex#ensure_math('\xi'),
  \ 'd': tex#ensure_math('\delta'),
  \ 'e': tex#ensure_math('\epsilon'),
  \ 'f': tex#ensure_math('\phi'),
  \ 'g': tex#graphic_select(),
  \ 'h': tex#ensure_math('\eta'),
  \ 'i': tex#ensure_math('\int'),
  \ 'j': tex#ensure_math("\1Subscript: \r..*\r_{&}\1"),
  \ 'k': tex#ensure_math("\1Superscript: \r..*\r^{&}\1"),
  \ 'l': tex#ensure_math('\lambda'),
  \ 'm': tex#ensure_math('\mu'),
  \ 'n': tex#ensure_math('\nabla'),
  \ 'o': tex#ensure_math('\cdot'),
  \ 'p': tex#ensure_math('\pi'),
  \ 'q': tex#ensure_math('\theta'),
  \ 'r': tex#cite_select(),
  \ 's': tex#ensure_math('\sigma'),
  \ 't': tex#ensure_math('\tau'),
  \ 'u': tex#ensure_math('\gamma'),
  \ 'v': tex#ensure_math('\nu'),
  \ 'w': tex#ensure_math('\omega'),
  \ 'x': tex#ensure_math('\chi'),
  \ 'y': tex#ensure_math('\psi'),
  \ 'z': tex#ensure_math('\zeta'),
  \ '~': tex#ensure_math('\sim'),
  \ },
  \ 1)

" Surround tools. Currently only overwrite 'r' and 'a' global bracket surrounds
" the 'f', 'p', and 'A' surrounds, and the '(', '[', '{', and '<' surrounds
" Delimiters should also not overlap common text objects like 'w' and 'p'
" Rejected maps:
" \ 'p': "\\begin{minipage}{\\linewidth}\r\\end{minipage}",
" \ 'F': "\\begin{wrapfigure}{r}{0.5\\textwidth}\n\\centering\r\\end{wrapfigure}",
" \ ',': "\\begin{\1\\begin{\1}\r\\end{\1\1}",
" \ '.': "\\\1\\\1{\r}",
" \ 'L': "\\href{\1Link: \1}{\r}",
call succinct#add_delims({
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
  \ ',': "\1Environment: \\begin{\r..*\r\\\\begin{&}\1\r\1\r..*\r\\\\end{&}\1",
  \ '.': "\1Command: \\\r..*\r\\\\&{\1\r\1\r..*\r}\1",
  \ '0': "\\cref{\r}",
  \ '1': "\\section{\r}",
  \ '2': "\\subsection{\r}",
  \ '3': "\\subsubsection{\r}",
  \ '4': "\\section*{\r}",
  \ '5': "\\subsection*{\r}",
  \ '6': "\\subsubsection*{\r}",
  \ '7': "\\tag{\r}",
  \ '8': "\\label{\r}",
  \ '9': "\\ref{\r}",
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
  \ },
  \ 1)

" " Text object integration
" " Adpated from: https://github.com/rbonvall/vim-textobj-latex/blob/master/ftplugin/tex/textobj-latex.vim
" " Also changed begin end modes so they make more sense.
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
