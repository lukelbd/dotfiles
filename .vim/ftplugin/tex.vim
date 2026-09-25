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
  let command = $HOME . '/bin/latexmk ' . flags . ' ' . linenum . ' ' . path
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
" \ 'k': function('tex#ensure_math', ['']"^{\1Superscript: \1}"]),
" \ 'j': function('tex#ensure_math', ['']"_{\1Subscript: \1}"]),
" \ 'E': function('tex#ensure_math', ['']"\times 10^{\1Exponent: \1}"]),
let b:succinct_snippets = {
  \ "\<CR>": ' \textCR\r',
  \ '.': function('tex#ensure_math', ['\leq']),
  \ ',': function('tex#ensure_math', ['\geq']),
  \ '0': function('tex#fzf_labels', []),
  \ '1': '\tiny',
  \ '2': '\scriptsize',
  \ '3': '\footnotesize',
  \ '4': '\small',
  \ '5': '\normalsize',
  \ '6': '\large',
  \ '7': '\Large',
  \ '8': '\LARGE',
  \ '9': function('tex#ensure_math', []),
  \ '!': '\item<1->',
  \ '@': '\item<2->',
  \ '#': '\item<3->',
  \ '$': '\item<4->',
  \ '%': '\%',
  \ '^': '\pause',
  \ '&': '\&',
  \ '*': '\item',
  \ ';': function('tex#ensure_math', ['\partial']),
  \ '-': function('tex#ensure_math', ['{-}']),
  \ '+': function('tex#ensure_math', ['{+}']),
  \ '=': function('tex#ensure_math', ['{=}']),
  \ '~': function('tex#ensure_math', ['\sim']),
  \ '_': function('tex#ensure_math', ['\equiv']),
  \ '/': function('tex#format_units', ['\1Units: \1']),
  \ '\': function('tex#ensure_math', ['\surd']),
  \ '?': function('tex#format_units', ['\1Units: \1']),
  \ "'": function('tex#ensure_math', ['\mathrm{d}']),
  \ '"': function('tex#ensure_math', ['\mathrm{D}']),
  \ '|': function('tex#ensure_math', ['\perp']),
  \ '(': function('tex#ensure_math', ['\subset']),
  \ ')': function('tex#ensure_math', ['\supset']),
  \ '[': function('tex#ensure_math', ['\longleftarrow']),
  \ ']': function('tex#ensure_math', ['\longrightarrow']),
  \ '{': function('tex#ensure_math', ['\Longleftarrow']),
  \ '}': function('tex#ensure_math', ['\Longrightarrow']),
  \ '<': function('tex#ensure_math', ['\ll']),
  \ '>': function('tex#ensure_math', ['\gg']),
  \ 'A': function('tex#ensure_math', ['\sum']),
  \ 'B': function('tex#ensure_math', ['\prod']),
  \ 'C': function('tex#ensure_math', ['\Gamma']),
  \ 'D': function('tex#ensure_math', ['\Delta']),
  \ 'E': function('tex#ensure_math', ['\1Exponent: \r..*\r\\times 10^{&}\1']),
  \ 'F': function('tex#ensure_math', ['\Phi']),
  \ 'G': function('tex#fzf_graphic', []),
  \ 'H': function('tex#ensure_math', ['^\circ']),
  \ 'I': function('tex#ensure_math', ['\iint']),
  \ 'J': function('tex#ensure_math', ['\1Subscript: \r..*\r_{&}\1']),
  \ 'K': function('tex#ensure_math', ['\1Superscript: \r..*\r^{&}\1']),
  \ 'L': function('tex#ensure_math', ['\Lambda']),
  \ 'M': function('tex#fzf_cite', []),
  \ 'N': function('tex#fzf_cite', []),
  \ 'O': function('tex#ensure_math', ['\oint']),
  \ 'P': function('tex#ensure_math', ['\Pi']),
  \ 'Q': function('tex#ensure_math', ['\Theta']),
  \ 'R': function('tex#ensure_math', ['\Xi']),
  \ 'S': function('tex#ensure_math', ['\Sigma']),
  \ 'T': function('tex#ensure_math', ['\top']),
  \ 'U': function('tex#ensure_math', ['\neq']),
  \ 'V': function('tex#ensure_math', ['\propto']),
  \ 'W': function('tex#ensure_math', ['\Omega']),
  \ 'X': function('tex#ensure_math', ['\times']),
  \ 'Y': function('tex#ensure_math', ['\Psi']),
  \ 'Z': function('tex#ensure_math', ['\cdot']),
  \ 'a': function('tex#ensure_math', ['\alpha']),
  \ 'b': function('tex#ensure_math', ['\beta']),
  \ 'c': function('tex#ensure_math', ['\gamma']),
  \ 'd': function('tex#ensure_math', ['\delta']),
  \ 'e': function('tex#ensure_math', ['\epsilon']),
  \ 'f': function('tex#ensure_math', ['\phi']),
  \ 'g': function('tex#fzf_graphic', []),
  \ 'h': function('tex#ensure_math', ['\eta']),
  \ 'i': function('tex#ensure_math', ['\int']),
  \ 'j': function('tex#ensure_math', ['\nabla']),
  \ 'k': function('tex#ensure_math', ['\kappa']),
  \ 'l': function('tex#ensure_math', ['\lambda']),
  \ 'm': function('tex#fzf_cite', []),
  \ 'n': function('tex#fzf_cite', []),
  \ 'o': function('tex#ensure_math', ['\rho']),
  \ 'p': function('tex#ensure_math', ['\pi']),
  \ 'q': function('tex#ensure_math', ['\theta']),
  \ 'r': function('tex#ensure_math', ['\xi']),
  \ 's': function('tex#ensure_math', ['\sigma']),
  \ 't': function('tex#ensure_math', ['\tau']),
  \ 'u': function('tex#ensure_math', ['\mu']),
  \ 'v': function('tex#ensure_math', ['\nu']),
  \ 'w': function('tex#ensure_math', ['\omega']),
  \ 'x': function('tex#ensure_math', ['\chi']),
  \ 'y': function('tex#ensure_math', ['\psi']),
  \ 'z': function('tex#ensure_math', ['\zeta']),
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
" \ 'G': '\hidecontent{\includegraphics{\r}}',
  \ 'P': '\begin{minipage}{\linewidth}\r\end{minipage}',
  \ 'Y': '\begin{python}\r\end{python}',
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
  \ 'A': '\mathcal{\r}',
  \ 'B': '\mathbb{\r}',
  \ 'C': '\pdfcomment{%\n\r\n}',
  \ 'D': '\ddot{\r}',
  \ 'E': '\textcolor{red}{\r}',
  \ 'F': '\begin{figure}[h]\n\centering\r\end{figure}',
  \ 'G': '\makebox[\textwidth][c]{%\n\includegraphics[scale=1]{\r}\n}',
  \ 'H': '\widehat{\r}',
  \ 'I': '\texttt{\r}',
  \ 'J': '\underset{}{\r}',
  \ 'K': '\overset{}{\r}',
  \ 'L': '\1Link: \r..*\r\\href{&}{\1\r\1\r..*\r}\1',
  \ 'M': '\footcite{\r}',
  \ 'N': '\citet{\r}',
  \ 'O': '\mathbf{\r}',
  \ 'P': '\captionof{figure}{\r}',
  \ 'R': '\mathrm{\r}',
  \ 'S': '\begingroup\n\usebackgroundtemplate{}\n\begin{frame}\r\end{frame}\n\endgroup',
  \ 'T': '\begin{table}\n\centering\r\end{table}',
  \ 'U': '\uncover<+->{%\r\}',
  \ 'V': '\begin{verbatim}\r\end{verbatim}',
  \ 'X': '\fbox{\parbox{\textwidth}{\r}}\medskip',
  \ 'Y': '\mathsf{\r}',
  \ 'Z': '\begin{columns}\r\end{columns}',
  \ 'd': '\dot{\r}',
  \ 'e': '\emph{\r}',
  \ 'f': '\begin{figure}\n\centering\r\end{figure}',
  \ 'g': '\includegraphics[scale=1]{\r}',
  \ 'h': '\hat{\r}',
  \ 'i': '\textit{\r}',
  \ 'j': '_{\r}',
  \ 'k': '^{\r}',
  \ 'l': '\url{\r}',
  \ 'm': '\cite{\r}',
  \ 'n': '\citep{\r}',
  \ 'o': '\textbf{\r}',
  \ 'p': '\caption{\r}',
  \ 's': '\begin{frame}\r\end{frame}',
  \ 't': '\1Alignment: \r..*\r\\begin{tabular}{&}\1\r\1\r..*\r\\end{tabular}\1',
  \ 'u': '\underline{\r}',
  \ 'v': '\verb$\r$',
  \ 'x': '\boxed{\r}',
  \ 'y': '\text{\r}',
  \ 'z': '\begin{column}{0.5\textwidth}\r\end{column}',
\ }  " }}}
