"-----------------------------------------------------------------------------
" Builtin TeX settings
"-----------------------------------------------------------------------------
" Configure syntax highlighting
" NOTE: g:tex_fast indicates highlight regions to *enable* (so setting to empty string
" speeds things up). Here omit comment regions 'c' to prevent them from getting folded.
let g:tex_fast = 'bmMprsSvV'  " exclude comment regions c to prevent folding
let g:tex_conceal = 'agmdb'  " conceal accents symbols and math symbols
let g:tex_stylish = 1  " allow @ in makeatletter and e.g. [_^] outside math

" Spell check settings
let g:tex_no_error = 1  " error highlights
let g:tex_nospell = 0  " general spellcheck
let g:tex_verbspell = 0  " verbatim spellcheck
let g:tex_comment_nospell = 1  " comment spellcheck

" External plugin settings
let b:delimitMate_quotes = '$ |'
let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
let s:cache_dir = expand('~/Library/Caches/bibtex')  " bibtex cache directory
if isdirectory(s:cache_dir) | let $FZF_BIBTEX_CACHEDIR = s:cache_dir | endif

" Run latexmk command and mappings
" NOTE: If 'PREVIOUS_VERSION: file.tex' or 'PERVIOUS_VERSION=file.tex' is on first
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
command! -buffer -nargs=* Latexmk call s:latexmk(<q-args>)
noremap <buffer> <Leader>{ <Cmd>call <sid>latexmk('--diff')<CR>
noremap <buffer> <Leader>} <Cmd>call <sid>latexmk('--word')<CR>
noremap <buffer> <Leader>\| <Cmd>call <sid>latexmk('--diff --word')<CR>
noremap <buffer> <Leader>[ <Cmd>call <sid>latexmk('--aux')<CR>
noremap <buffer> <Leader>] <Cmd>call <sid>latexmk('--aux')<CR>
noremap <buffer> <Leader>\ <Cmd>call <sid>latexmk('--raw')<CR>
noremap <buffer> <Plug>ExecuteFile0 <Cmd>call <sid>latexmk()<CR>
noremap <buffer> <Plug>ExecuteFile1 <Cmd>call <sid>latexmk('--nobbl')<CR>
noremap <buffer> <Plug>ExecuteFile2 <Cmd>call <sid>latexmk('--pdf')<CR>

" Add snippets. Each snippet is made into an <expr> map by prepending and
" appending the strings with single quotes. This lets us make input() dependent
" snippets as shown for the 'j', 'k', and 'E' mappings. Note \xi looks like
" squiggle (pronounced 'zai') and \chi looks like an x (pronounced 'kai').
" NOTE: Internal utility translates \r[^a-z]\@! and \1..\7 to literals. Recall that
" vim-surround interprets '\r' as separator and '\1[prompt]\r[match]\r[replace]\1' for
" requesting user-input and optionally formatting the input with regex (often using &).
" Snippet definitions: {{{
" \ '''': tex#make_snippet(tex#fzf_graphics_ref(), '\includegraphics{', '}'),
" \ '"': tex#make_snippet(tex#fzf_graphics_ref(), '\makebox[\textwidth][c]{\includegraphics{', '}}'),
" \ '/': tex#make_snippet(tex#fzf_labels_ref(), '\cref{', '}'),
" \ '?': tex#make_snippet(tex#fzf_labels_ref(), '\ref{', '}'),
" \ ':': tex#make_snippet(tex#fzf_cite_ref(), '\citet{', '}'),
" \ ';': tex#make_snippet(tex#fzf_cite_ref(), '\citep{', '}'),
" \ 'k': tex#ensure_math_ref("^{\1Superscript: \1}"),
" \ 'j': tex#ensure_math_ref("_{\1Subscript: \1}"),
" \ 'E': tex#ensure_math_ref("\times 10^{\1Exponent: \1}"),
let b:succinct_snippets = {
  \ "\<CR>": ' \textCR\r',
  \ "'": tex#ensure_math_ref('\mathrm{d}'),
  \ '"': tex#ensure_math_ref('\mathrm{D}'),
  \ '*': '\item',
  \ '+': tex#ensure_math_ref('\sum'),
  \ ',': tex#ensure_math_ref('\Leftarrow'),
  \ '-': '\pause',
  \ '.': tex#ensure_math_ref('\Rightarrow'),
  \ '/': tex#format_units_ref('\1Units: \1'),
  \ '[': tex#ensure_math_ref('{-}'),
  \ ']': tex#ensure_math_ref('{+}'),
  \ '0': tex#fzf_labels_ref(),
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': tex#fzf_labels_ref(),
  \ ';': tex#ensure_math_ref('\partial'),
  \ '<': tex#ensure_math_ref('\Longleftarrow'),
  \ '=': tex#ensure_math_ref('\equiv'),
  \ '>': tex#ensure_math_ref('\Longrightarrow'),
  \ '_': tex#ensure_math_ref('\prod'),
  \ 'C': tex#ensure_math_ref('\Xi'),
  \ 'D': tex#ensure_math_ref('\Delta'),
  \ 'E': tex#ensure_math_ref('\1Exponent: \r..*\r\\times 10^{&}\1'),
  \ 'F': tex#ensure_math_ref('\Phi'),
  \ 'G': tex#fzf_graphics_ref(),
  \ 'H': tex#ensure_math_ref('\rho'),
  \ 'I': tex#ensure_math_ref('\iint'),
  \ 'K': tex#ensure_math_ref('\kappa'),
  \ 'L': tex#ensure_math_ref('\Lambda'),
  \ 'N': tex#fzf_cite_ref(),
  \ 'O': tex#ensure_math_ref('^\circ'),
  \ 'P': tex#ensure_math_ref('\Pi'),
  \ 'Q': tex#ensure_math_ref('\Theta'),
  \ 'R': tex#fzf_cite_ref(),
  \ 'S': tex#ensure_math_ref('\Sigma'),
  \ 'U': tex#ensure_math_ref('\Gamma'),
  \ 'W': tex#ensure_math_ref('\Omega'),
  \ 'X': tex#ensure_math_ref('\times'),
  \ 'Y': tex#ensure_math_ref('\Psi'),
  \ 'a': tex#ensure_math_ref('\alpha'),
  \ 'b': tex#ensure_math_ref('\beta'),
  \ 'c': tex#ensure_math_ref('\xi'),
  \ 'd': tex#ensure_math_ref('\delta'),
  \ 'e': tex#ensure_math_ref('\epsilon'),
  \ 'f': tex#ensure_math_ref('\phi'),
  \ 'g': tex#fzf_graphics_ref(),
  \ 'h': tex#ensure_math_ref('\eta'),
  \ 'i': tex#ensure_math_ref('\int'),
  \ 'j': tex#ensure_math_ref('\1Subscript: \r..*\r_{&}\1'),
  \ 'k': tex#ensure_math_ref('\1Superscript: \r..*\r^{&}\1'),
  \ 'l': tex#ensure_math_ref('\lambda'),
  \ 'm': tex#ensure_math_ref('\mu'),
  \ 'n': tex#fzf_cite_ref(),
  \ 'o': tex#ensure_math_ref('\cdot'),
  \ 'p': tex#ensure_math_ref('\pi'),
  \ 'q': tex#ensure_math_ref('\theta'),
  \ 'r': tex#fzf_cite_ref(),
  \ 's': tex#ensure_math_ref('\sigma'),
  \ 't': tex#ensure_math_ref('\tau'),
  \ 'T': tex#ensure_math_ref('\nabla'),
  \ 'u': tex#ensure_math_ref('\gamma'),
  \ 'v': tex#ensure_math_ref('\nu'),
  \ 'w': tex#ensure_math_ref('\omega'),
  \ 'x': tex#ensure_math_ref('\chi'),
  \ 'y': tex#ensure_math_ref('\psi'),
  \ 'z': tex#ensure_math_ref('\zeta'),
  \ '~': tex#ensure_math_ref('\sim'),
\ }  " }}}

" Add delimiters. Currently only overwrite 'r' and 'a' global bracket surrounds, the
" 'f' and 'A' succinct surrounds, and the '(', '[', '{', and '<' native surrounds.
" NOTE: Internal utility translates \r\> and \1..\7 to literals before processing
" NOTE: For ametsoc suffix is specified with \citep[suffix]{cite1,cite2} and prefix with
" e.g. \citep[prefix][]{cite1,cite2}. In ams this is \cite[suffix]{cite1,cite2} and
" \cite<prefix>{cite1,cite2} and commands are \cite and \citeA instead of \citep and
" \citep. Solution is to add \renewcommand to preamble and do not auto-insert empty
" brackets for filling later since synmtax is dependent on citation engine.
" Delimiter definitions:  " {{{
" \ 'F': '\begin{wrapfigure}{r}{0.5\textwidth}\n\centering\r\end{wrapfigure}',
" \ 'G': '\hidecontent{\includegraphics{\r}}',
" \ 'L': '\href{\1Link: \1}{\r}',
" \ 'P': '\begin{minipage}{\linewidth}\r\end{minipage}',
" \ ',': '\begin{\1\begin{\1}\r\end{\1\1}',
" \ '.': '\1\1{\r}',
" \ 'Y': '\begin{python}\r\end{python}',
" \ 'y': '\pyth$\r$',
let b:succinct_delims = {
  \ '.': '\1Command: \\r..*\r\\&{\1\r\1\r..*\r}\1',
  \ ',': '\1Environment: \begin{\r..*\r\\begin{&}\1\r\1\r..*\r\\end{&}\1',
  \ '0': '\cref{\r}',
  \ '1': '\frametitle{\r}',
  \ '2': '\framesubtitle{%\n\r\n}',
  \ '3': '\section{\r}',
  \ '4': '\subsection{\r}',
  \ '5': '\subsubsection{\r}',
  \ '6': '\section*{\r}',
  \ '7': '\subsection*{\r}',
  \ '8': '\subsubsection*{\r}',
  \ '9': '\ref{\r}',
  \ '!': '\cancelto{}{\r}',
  \ '@': '\begin{enumerate}[label=\alph*.]\r\end{enumerate}',
  \ '#': '\begin{enumerate}\r\end{enumerate}',
  \ '%': '\begin{align*}\r\end{align*}',
  \ '^': '\begin{align}\r\end{align}',
  \ '&': '\begin{description}\r\end{description}',
  \ '*': '\begin{itemize}\r\end{itemize}',
  \ ';': '\begin{block}{}\r\end{block}',
  \ ':': '\begin{alertblock}{}\r\end{alertblock}',
  \ '_': '\begin{center}\n\r\end{center}',
  \ '-': '\overline{\r}',
  \ '/': '\frac{\r}{}',
  \ '\': '\sqrt{\r}',
  \ '?': '\dfrac{\r}{}',
  \ '=': '\tag{\r}',
  \ '`': '\label{\r}',
  \ '~': '\tilde{\r}',
  \ "'": '`\r''',
  \ '"': '``\r''''',
  \ '$': '$\r$',
  \ '|': '\left\|\r\right\|',
  \ '(': '\left(\r\right)',
  \ ')': '\begin{pmatrix}\r\end{pmatrix}',
  \ '[': '\left[\r\right]',
  \ ']': '\begin{bmatrix}\r\end{bmatrix}',
  \ '{': '\left\{\r\right\}',
  \ '}': '\left\{\begin{array}{ll}\r\end{array}\right.',
  \ '<': '\left\langle \r\right\rangle',
  \ '>': '\vec{\r}',
  \ 'A': '\captionof{figure}{\r}',
  \ 'B': '\mathbb{\r}',
  \ 'C': '\mathcal{\r}',
  \ 'D': '\ddot{\r}',
  \ 'F': '\begin{figure}[h]\n\centering\r\end{figure}',
  \ 'G': '\makebox[\textwidth][c]{%\n\includegraphics{\r}\n}',
  \ 'I': '\texttt{\r}',
  \ 'J': '\underset{}{\r}',
  \ 'K': '\overset{}{\r}',
  \ 'L': '\1Link: \r..*\r\\href{&}{\1\r\1\r..*\r}\1',
  \ 'M': '\textcolor{red}{\r}',
  \ 'O': '\mathbf{\r}',
  \ 'P': '\mathrm{\r}',
  \ 'Q': '\pdfcomment{%\n\r\n}',
  \ 'R': '\citet{\r}',
  \ 'S': '\begingroup\n\usebackgroundtemplate{}\n\begin{frame}\r\end{frame}\n\endgroup',
  \ 'T': '\begin{table}\n\centering\r\end{table}',
  \ 'U': '\uncover<+->{%\r\}',
  \ 'X': '\fbox{\parbox{\textwidth}{\r}}\medskip',
  \ 'Y': '\begin{verbatim}\r\end{verbatim}',
  \ 'Z': '\begin{columns}\r\end{columns}',
  \ 'a': '\caption{\r}',
  \ 'd': '\dot{\r}',
  \ 'f': '\begin{figure}\n\centering\r\end{figure}',
  \ 'g': '\includegraphics{\r}',
  \ 'h': '\hat{\r}',
  \ 'i': '\textit{\r}',
  \ 'j': '_{\r}',
  \ 'k': '^{\r}',
  \ 'm': '\emph{\r}',
  \ 'o': '\textbf{\r}',
  \ 'q': '\footcite{\r}',
  \ 'r': '\citep{\r}',
  \ 's': '\begin{frame}\r\end{frame}',
  \ 't': '\1Alignment: \r..*\r\\begin{tabular}{&}\1\r\1\r..*\r\\end{tabular}\1',
  \ 'u': '\underline{\r}',
  \ 'x': '\boxed{\r}',
  \ 'y': '\verb$\r$',
  \ 'z': '\begin{column}{0.5\textwidth}\r\end{column}',
\ }  " }}}
