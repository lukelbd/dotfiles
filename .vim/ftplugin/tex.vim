"-----------------------------------------------------------------------------
" Builtin TeX settings
"-----------------------------------------------------------------------------
" Open document fold on startup
" Note: Not possible to set foldlevelstart=1 for specific filetype
let s:start = search('^\s*\\begin{document}', 'n')
if foldclosed(s:start) > 0 | exe s:start . 'foldopen' | endif

" Enable folds and adjust highlight regions
" Note: g:tex_fast indicates highlight regions to *enable* (so setting to empty string
" speeds things up). Here omit comment regions 'c' to prevent them from getting folded.
let g:tex_fast = 'bmMprsSvV'  " exclude 'c'
let g:tex_fold_enable = 1

" Restrict concealmeant to accents, Greek symbols, and math symbols. Also allow @ in
" makeatletter and 'math' outside of math zones (i.e. do not highlight [_^]).
let g:tex_conceal = 'agmdb'
let g:tex_stylish = 1

" Disable errors and disable spellcheck in verbatim and comments
let g:tex_no_error = 1
let g:tex_nospell = 0
let g:tex_verbspell = 0
let g:tex_comment_nospell = 1

" DelimitMate integration
let b:delimitMate_quotes = '$ |'
let b:delimitMate_matchpairs = "(:),{:},[:],`:'"

" Bibtex cache directory
let s:cache_dir = expand('~/Library/Caches/bibtex')
if isdirectory(s:cache_dir) | let $FZF_BIBTEX_CACHEDIR = s:cache_dir | endif

" Running custom or default latexmk command in background
" Note: When 'PREVIOUS_VERSION: file.tex' or 'PERVIOUS_VERSION=file.tex' is on first
" line, '--diff' flags passed to :Latexmk are replaced with '--prev=file.tex'.
function! s:latexmk(...) abort
  let opts = {}  " job options, empty by default
  let path = shellescape(expand('%'))
  let prev = matchstr(getline(1), 'PREVIOUS_VERSION\s*[:=]\s*\zs\S*\ze')
  let flags = trim(a:0 ? a:1 : '')
  let linenum = ' --line=' . string(line('.'))
  if !empty(prev)
    let flags = substitute(flags, '\(^\|\s\)\zs\(-d\|--diff\)\>', '--prev=' . prev, '')
  endif
  let command = 'latexmk ' . flags . ' ' . linenum . ' ' . path
  let popup = flags !~# '\(^\|\s\)\(-a\|--aux\)\>'
  call shell#job_win(command, popup)
endfunction

" Latexmk command and shortcuts
" Note: This map overwrites :TestVisit but no harm for tex files.
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <Leader>{ <Cmd>call <sid>latexmk('--diff')<CR>
noremap <buffer> <Leader>} <Cmd>call <sid>latexmk('--word')<CR>
noremap <buffer> <Leader>\| <Cmd>call <sid>latexmk('--diff --word')<CR>
noremap <buffer> <Leader>[ <Cmd>call <sid>latexmk('--aux')<CR>
noremap <buffer> <Leader>] <Cmd>call <sid>latexmk('--aux')<CR>
noremap <buffer> <Leader>\ <Cmd>call <sid>latexmk('--raw')<CR>
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>latexmk()<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>call <sid>latexmk('--nobbl')<CR>
noremap <buffer> <Plug>ExecuteFile3 <Cmd>call <sid>latexmk('--pdf')<CR>

" Snippet dictionaries. Each snippet is made into an <expr> map by prepending
" and appending the strings with single quotes. This lets us make input()
" dependent snippets as shown for the 'j', 'k', and 'E' mappings.
" * \xi looks like a funky squiggle, pronounced 'zai'
" * \chi looks like an x, pronounced 'kai'
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
  \ 'N': tex#cite_select(),
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
  \ 'n': tex#cite_select(),
  \ 'o': tex#ensure_math('\cdot'),
  \ 'p': tex#ensure_math('\pi'),
  \ 'q': tex#ensure_math('\theta'),
  \ 'r': tex#cite_select(),
  \ 's': tex#ensure_math('\sigma'),
  \ 't': tex#ensure_math('\tau'),
  \ 'T': tex#ensure_math('\nabla'),
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
" the 'f', 'p', and 'A' surrounds, and the '(', '[', '{', and '<' surrounds.
" Delimiters should also not overlap common text objects like 'w' and 'p'.
" Note: In ametsoc suffix is specified with \citep[suffix]{cite1,cite2} and prefix with
" e.g. \citep[prefix][]{cite1,cite2}. In ams this is \cite[suffix]{cite1,cite2} and
" \cite<prefix>{cite1,cite2} and commands are \cite and \citeA instead of \citep and
" \citep. Solution is to add \renewcommand to preamble and do not auto-insert empty
" brackets for filling later since synmtax is dependent on citation engine.
" Rejected maps:
" \ 'E': "{\\color{red}\r}",
" \ 'F': "\\begin{wrapfigure}{r}{0.5\\textwidth}\n\\centering\r\\end{wrapfigure}",
" \ 'G': "\\hidecontent{\\includegraphics{\r}}",
" \ 'L': "\\href{\1Link: \1}{\r}",
" \ 'P': "\\begin{minipage}{\\linewidth}\r\\end{minipage}",
" \ ',': "\\begin{\1\\begin{\1}\r\\end{\1\1}",
" \ '.': "\\\1\\\1{\r}",
call succinct#add_delims({
  \ "'": "`\r'",
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
  \ '1': "\\frametitle{\r}",
  \ '2': "\\framesubtitle{%\n\r\n}",
  \ '3': "\\section{\r}",
  \ '4': "\\subsection{\r}",
  \ '5': "\\subsubsection{\r}",
  \ '6': "\\section*{\r}",
  \ '7': "\\subsection*{\r}",
  \ '8': "\\subsubsection*{\r}",
  \ '!': "\\tag{\r}",
  \ '~': "\\label{\r}",
  \ '9': "\\ref{\r}",
  \ ':': "\\begin{alertblock}{}\r\\end{alertblock}",
  \ ';': "\\begin{block}{}\r\\end{block}",
  \ '<': "\\left\\langle \r\\right\\rangle",
  \ '>': "\\vec{\r}",
  \ '?': "\\dfrac{\r}{}",
  \ '@': "\\begin{enumerate}[label=\\alph*.]\r\\end{enumerate}",
  \ 'A': "\\captionof{figure}{\r}",
  \ 'D': "\\ddot{\r}",
  \ 'E': "\\textcolor{red}{\r}",
  \ 'F': "\\begin{figure}[h]\n\\centering\r\\end{figure}",
  \ 'G': "\\makebox[\\textwidth][c]{%\n\\includegraphics{\r}\n}",
  \ 'I': "\\texttt{\r}",
  \ 'J': "\\underset{}{\r}",
  \ 'K': "\\overset{}{\r}",
  \ 'L': "\1Link: \r..*\r\\\\href{&}{\1\r\1\r..*\r}\1",
  \ 'M': "\\mathbb{\r}",
  \ 'N': "\\pdfcomment{%\n\r\n}",
  \ 'O': "\\mathbf{\r}",
  \ 'R': "\\citet{\r}",
  \ 'S': "\\begingroup\n\\usebackgroundtemplate{}\n\\begin{frame}\r\\end{frame}\n\\endgroup",
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
  \ 'n': "\\footcite{\r}",
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
