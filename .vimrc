".vimrc
"------------------------------------------------------------------------------
" MOST IMPORTANT STUFF
" NOTE VIM SHOULD BE brew install'd WITHOUT YOUR ANACONDA TOOLS IN THE PATH; USE
" PATH="<original locations>" brew install ... AND EVERYTHING WORKS
"------------------------------------------------------------------------------
"NOCOMPATIBLE -- changes other stuff, so must be first
set nocompatible
  "always use the vim default where vi and vim differ; for example, if you
  "put this too late, whichwrap will be resset

"LEADER -- most important line
let mapleader = "\<Space>"
noremap <Space> <Nop>

"TAB COMPLETION OPENING NEW FILES
set wildignore=
set wildignore+=*.pdf,*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.ipynb,*.o,*.mod
set wildignore+=*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4
set wildignore+=*.dmg,*.zip
  "never want to open these in VIM; includes GUI-only filetypes
  "and machine-compiled source code (.o and .mod for fortran, .pyc for python)

"DIFFERENT CURSOR SHAPE DIFFERENT MODES; works in iTerm2
" let &t_SI = "\<Esc>]50;CursorShape=1\x7"
" let &t_SR = "\<Esc>]50;CursorShape=2\x7"
" let &t_EI = "\<Esc>]50;CursorShape=0\x7"

"ESCAPE and MOUSE ACTION REPAIR
set whichwrap=[,],<,>,h,l
  "let h, l move past end of line (<> = left/right insert, [] = left/right normal mode)
function! s:escape()
  if col('.')+1 != col('$') && col('.') != 1
    normal l
    let b:delete_fix='i'
  elseif col('.')==1
    let b:delete_fix='i'
  else
    let b:delete_fix='a'
  endif
endfunction
  "preserve cursor column, UNLESS we were on the newline/final char; this prevents weird
  "behavior caused by allowing l/h to change lines
nnoremap <Esc> <Nop>
nnoremap <C-c> <Nop>
nnoremap <Delete> <Nop>
nnoremap <Backspace> <Nop>
  "turns off common things in normal mode
nnoremap <expr> [3~ b:delete_fix."<Delete>"
  "fixes insert mode delete, supposedly (delete read as "[3~"  on mac)
  "detects the unique SUBSEQUENT [3~, puts us back in insert mode, and deletes
nnoremap <Esc>[3~ <Nop>
  "necessary to fix weird mouse behavior in normal mode, and make "<Delete>"
  "on mac do nothing; for some reason, if you don't have this line, LeftMouse is broken
  "note that [3~ is triggered only if we left insert mode, but this is triggered if
  "pressing delete from normal mode only... also means that VIM now waits when you press
  "Escape in normal mode, but no big deal
set mouse=a
autocmd InsertEnter * set mouse=
autocmd InsertLeave * set mouse=a
  "...weird things happen if don't disable mouse in insert mode, especially with neocomplete
  "enables left-click movement

"DISABLE ANNOYING SPECIAL MODES/DANGEROUS ACTIONS
noremap K <Nop>
noremap Q <Nop>
  "the above 2 enter weird modes I don't understand...
noremap <C-z> <Nop>
noremap Z <Nop>
  "disable c-z and Z for exiting vim
set slm=
  "disable 'select mode' slm, allow only visual mode for that stuff
noremap <nowait> q <Nop>
  "macro recording; we changed this to tilde ~

"MOVING BETWEEN FUNCTIONS
nnoremap <silent><nowait> [ [[
nnoremap <silent><nowait> ] ]]
function! MakeBracketMaps()
  " nunmap <buffer> []
  " nunmap <buffer> ["
  " nunmap [3~
  " nunmap [%
  " nunmap <buffer> ][
  " nunmap <buffer> ]"
  " nunmap ]%
  nnoremap <silent><nowait><buffer> [ :<c-u>exe 'normal '.v:count.'[['<cr>
  nnoremap <silent><nowait><buffer> ] :<c-u>exe 'normal '.v:count.']]'<cr>
endfunction
augroup bracketmaps
  autocmd!
  autocmd FileType * call MakeBracketMaps()
augroup END

"CHANGE MOVEMENT/MOVEMENT (some options for presence of wrapped lines)
" noremap $ g$
" noremap 0 g0
  "go to visual line ends/starts
noremap m ge
noremap M gE
  "navigate by ends of words backwards; logic is m was available, and
  "it is to left of b just like e is to left of w
noremap A g$a
noremap I g^i
  "same for entering insert mode
noremap H g^
noremap L g$geE
  "shortcuts for 'go to first char' and 'go to eol'
  "make these work for VISUAL movement

"CHANGE/ADD PROPERTIES/SHORTCUTS OF VERY COMMON ACTIONS
nnoremap <C-r> :redraw<CR>
  "refresh screen; because C-r has a better pneumonic, and I map <C-r> to U for REDO
noremap <Leader><Space> q:
  "view last command-window stuff
function! s:commandline_check()
  nnoremap <buffer> <silent> q :q<CR>
  setlocal nonumber
  setlocal nolist
  setlocal laststatus=0 "turns off statusline
endfunction
au CmdwinEnter * call s:commandline_check()
au CmdwinLeave * setlocal laststatus=2
  "commandline-window settings
nnoremap U <C-r>
  "redo map to capital U; means we cannot 'undo line', but who cares
" noremap <C-a> :
"   "command for entering command-mode
noremap ~ q1
noremap q <Nop>
  "new macro toggle; almost always just use one at a time
  "press ~ again to quit; 1, 2, etc. do nothing in normal mode. clever, huh?
" noremap `` @@
noremap , @1
noremap @ <Nop>
  "new macro useage; almost always just use one at a time
  "also easy to remembers; dot is 'repeat last command', comma is 'repeat last macro'
noremap \\ "
  "use BACKSLASH FOR REGISTER KEY (easier to access)
map " mq:echo "Throwaway mark was set."<CR>
map 1" mi:echo "Mark 1 was set."<CR>
map 2" mj:echo "Mark 2 was set."<CR>
map 3" mk:echo "Mark 3 was set."<CR>
map 4" mm:echo "Mark 4 was set."<CR>
map 5" mn:echo "Mark 5 was set."<CR>
  "allow recursion, so can use mark-highlighting plugin
noremap ' `q:echo "Travelled to throwaway mark."<CR>
noremap 1' `i:echo "Travelled to mark 1."<CR>
noremap 2' `j:echo "Travelled to mark 2."<CR>
noremap 3' `k:echo "Travelled to mark 3."<CR>
noremap 4' `m:echo "Travelled to mark 4."<CR>
noremap 5' `n:echo "Travelled to mark 5."<CR>
  "new mark setting/getting; almost always will use one at a time
  "use 1, because why not
noremap ` :RemoveMarkHighlights<CR>
  "remove the highlights
noremap <Right> ;
noremap <Left> ,
  "so i can still use the f, t stuff
nnoremap x "_x
nnoremap X "_X
  "don't save single-character deletions to any register
vnoremap p "_dP
vnoremap P "_dP
  "default behavior replaces selection with register after p, but puts
  "deleted text in register; correct this behavior
" nnoremap o ox<BS>
" nnoremap O Ox<BS>
"   "pressing enter on empty line preserves leading whitespace (HACKY)
"   "works because Vim doesn't remove spaces when text has been inserted
nnoremap <nowait> > >>
nnoremap <nowait> < <<
nnoremap <nowait> = ==
nnoremap <nowait> ] ]]
nnoremap <nowait> [ [[
  "single-keystroke indent, dedent, fix indentation, and function navigation

"------------------------------------------------------------------------------
" COMPLICATED FUNCTIONS, MAPPINGS, FILETYPE MAPPINGS
"------------------------------------------------------------------------------
"SCROLLING
function! s:scroll(num,mode,toggle)
if (line('.')!=1 && a:mode==1) || (line('.')!=line('$') && a:mode==0)
  "First stuff
  let a:oldscrolloff=&scrolloff
  let a:oldwinline=winline()
  setlocal scrolloff=0
  "Go to top/bottom of file, and coerce window movement with scrolling
  "(have to coerce in this way because <c-y>/<c-e> doesn't work in functions)
  let a:count=a:num
  if a:mode == 1
    execute 'normal! ' . eval(winline()-1) . 'gk'
      "must enclose :execute and <expr> numbers in eval()
    while line('.') != 1 && a:count
      execute 'normal!  gk'
      let a:count-=1
    endwhile
  else
    execute 'normal! ' . eval(winheight(0)-winline()). 'gj'
    while line('.') != line('$') && a:count
      execute 'normal!  gj'
      let a:count-=1
    endwhile
  endif
  "Fix position
  if a:oldwinline > winline()
    execute 'normal! ' . eval(a:oldwinline-winline()) . 'gj'
  elseif winline() > a:oldwinline
    execute 'normal! ' . eval(winline()-a:oldwinline) . 'gk'
  endif
  "If at top/bottom, keep scrolling by some amount; assuming the
  "toggle option is turned on
  if a:count>0 && a:toggle==1
    while line('.') != line('0') && line('.') != line('$') && a:count
      if a:mode == 1
        execute 'normal! gk'
      else
        execute 'normal! gj'
      endif
      let a:count-=1
    endwhile
  endif
  "Restore scrolloff
  execute 'setlocal scrolloff='.a:oldscrolloff
endif
endfunction
"Create normal mode maps
noremap <silent> <C-h> :call <sid>scroll(winheight(0)/4,0,1)<CR>
noremap <silent> <C-j> :call <sid>scroll(winheight(0)/2,0,1)<CR>
noremap <silent> <C-l> :call <sid>scroll(winheight(0)/4,1,1)<CR>
noremap <silent> <C-k> :call <sid>scroll(winheight(0)/2,1,1)<CR>
noremap <C-f> [[
noremap <C-g> ]]
"noremap <silent> <C-b> :call <sid>scroll(winheight(0),1,1)<CR>
"noremap <silent> <C-f> :call <sid>scroll(winheight(0),0,1)<CR>
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(winheight(0)/12+1,1)<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(winheight(0)/12+1,0)<CR>
noremap <silent> <ScrollWheelUp> :call <sid>scroll(1,1,0)<CR>
noremap <silent> <ScrollWheelDown> :call <sid>scroll(1,0,0)<CR>
"And visual mode scrolling; never really use with wrapping toggled, so
"will use standard <C-e> <C-y> scrolling here
vnoremap <expr> <C-h> eval(winheight(0)/4).'<C-e>'.eval(winheight(0)/4).'gj'
vnoremap <expr> <C-j> eval(winheight(0)/2).'<C-e>'.eval(winheight(0)/2).'gj'
vnoremap <expr> <C-l> eval(winheight(0)/4).'<C-y>'.eval(winheight(0)/4).'gk'
vnoremap <expr> <C-k> eval(winheight(0)/2).'<C-y>'.eval(winheight(0)/2).'gk'
vnoremap <C-f> [[
vnoremap <C-g> ]]
"vnoremap <expr> <C-f> eval(winheight(0)).'<C-e>'.eval(winheight(0)).'gj'
"vnoremap <expr> <C-b> eval(winheight(0)).'<C-y>'.eval(winheight(0)).'gk'
vnoremap <ScrollWheelDown> <C-e>gj
vnoremap <ScrollWheelUp> <C-y>gk
"So don't confuse myself, make sure <C-d> and <C-u> then don't work
noremap <C-d> <Nop>
noremap <C-u> <Nop>
vnoremap <C-d> <Nop>
vnoremap <C-u> <Nop>

"WRAPPING AND LINE BREAKING
"Buffer amount on either side
let g:scrolloff=4
"Function
function! s:wraptoggle(function_mode)
  "RECALL <buffer> makes these mappings local
if a:function_mode==1
  let a:toggle=1
elseif a:function_mode==0
  let a:toggle=0
elseif exists('b:wrap_mode')
  let a:toggle=1-b:wrap_mode
else
  let a:toggle=1
endif
if a:toggle==1
  let b:wrap_mode=1
  "visual/display-based motion across wrapped lines
  setlocal wrap
  setlocal scrolloff=0
  setlocal colorcolumn=0
else
  let b:wrap_mode=0
  "disable visual/display-based motion
  setlocal nowrap
  execute 'setlocal scrolloff='.g:scrolloff
  execute 'setlocal colorcolumn=81,121'
  " execute 'setlocal colorcolumn=81,'.join(range(120,999),",")
endif
endfunction
"Wrapper function; for some infuriating reason, setlocal scrolloff sets
"the value globally, no matter what; not so for wrap or colorcolumn
function! s:autowrap()
  if 'tex,html,xml,text,markdown'=~&ft
    call s:wraptoggle(1)
  else
    call s:wraptoggle(0)
  endif
endfunction
autocmd BufEnter * call s:autowrap()
"Declare mapping, to toggle on and off
noremap <silent> <Leader>w :call <sid>wraptoggle(-1)<CR>
"Basic wrap-mode navigation, always move visually
"Still might occasionally want to navigate by lines though
noremap  gj     j
noremap  gk     k
noremap  k      gk
noremap  j      gj
noremap  <Up>   gk
noremap  <Down> gj
noremap  <Home> g<Home>
noremap  <End>  g<End>
inoremap <Up>   <C-o>gk
inoremap <Down> <C-o>gj
inoremap <Home> <C-o>g<Home>
inoremap <End>  <C-o>g<End>

" "INSERT-MODE MAPS
" "Work-arounds for things I use as mappings
" inoremap :: :
" inoremap :<Space> :<Space>
" "Quick commands for movement
" "..those that move to different lines
" inoremap :i <Esc>I
"   "go to first non-whitespace
" inoremap :a <Esc>A
"   "go to last non-whitespace whitespace
" inoremap :o <Esc>o
"   "go to new line below
" inoremap :O <Esc>O
"   "go to new line above
" inoremap :p <C-r>"
" "...undo latest text insertion
" inoremap :u <Esc>ua
" "...and those sensitive to column position
" inoremap := <Esc>==A
" inoremap :c <Esc>cc
" inoremap :d <Esc>:call Escape()<CR>c$
" inoremap :e <Esc>:call Escape()<CR>Ea
" inoremap :m <Esc>:call Escape()<CR>gEa

"SURROUNDING STUFF and INSERT-MODE MAPS
"i remapped S to c$, to behave more like Y and D
"Case changing
nnoremap ;u guiw
vnoremap ;u gu
nnoremap ;U gUiw
vnoremap ;U gU
"Wrap in print statement
inoremap ;p print()<Left>
nnoremap ;p mAlbiprint(<Esc>ea)<Esc>`A
vnoremap ;p mA<Esc>`>a)<Esc>`<iprint(<Esc>`Al
"Parentheses ('b' for default vim)
inoremap ;b ()<Left>
nnoremap ;b mAlbi(<Esc>ea)<Esc>`A
vnoremap ;b mA<Esc>`>a)<Esc>`<i(<Esc>`Al
"Curly brackets {} ('c' for curly)
inoremap ;B {}<Left>
nnoremap ;B mAlbi{<Esc>ea}<Esc>`A
vnoremap ;B mA<Esc>`>a}<Esc>`<i{<Esc>`Al
"Brackets ('r' for brackets)
inoremap ;r []<Left>
nnoremap ;r mAlbi[<Esc>ea]<Esc>`A
vnoremap ;r mA<Esc>`>a]<Esc>`<i[<Esc>`Al
"Triangles <> ('a' for carats)
inoremap ;a <><Left>
nnoremap ;a mAlbi<<Esc>ea><Esc>`A
vnoremap ;a mA<Esc>`>a><Esc>`<i<<Esc>`Al
"Simple quotes <> ('a' for carats)
" inoremap ;' ''<Left>
nnoremap ;' mAlbi'<Esc>ea'<Esc>`A
vnoremap ;' mA<Esc>`>a'<Esc>`<i'<Esc>`Al
"Double quotes <> ('a' for carats)
" inoremap ;" ""<Left>
nnoremap ;" mAlbi"<Esc>ea"<Esc>`A
vnoremap ;" mA<Esc>`>a"<Esc>`<i"<Esc>`Al
"WORD Parentheses ('b' for default vim)
" nnoremap ;B mAlBi(<Esc>Ea)<Esc>`A
"WORD Brackets ('r' for brackets)
" nnoremap ;R mAlBi[<Esc>Ea]<Esc>`A
"WORD Curly brackets {} ('c' for curly)
" nnoremap ;C mAlBi{<Esc>Ea}<Esc>`A
"WORD Triangles <> ('a' for carats)
" nnoremap ;A mAlBi<<Esc>Ea><Esc>`A

"LATEX MACROS, lots of insert-mode stuff
"Cannot use C-m or C-i, as the former produces an Enter and
"the latter... does something else weird, adds a space
function! s:texmacros()
  "CONVENIENCE, IN CONTEXT OF OTHER SHORTCUTS
  inoremap <buffer> .. .
  inoremap <buffer> ,, ,
  inoremap <buffer> .<Space> .<Space>
  inoremap <buffer> ,<Space> ,<Space>
  "QUICK WAY OF DECLARING \latex{} COMMANDs
  vnoremap <buffer> <expr> ;. '<Esc>mA`>a}<Esc>`<i\'.input('Enter new \<name>{}-style environment name: ').'{<Esc>`A'
  nnoremap <buffer> <expr> ;. 'mAviw<Esc>`>a}<Esc>`<i\'.input('Enter new \<name>{}-style environment name: ').'{<Esc>`A'
  inoremap <buffer> <expr> ;. '\'.input('Enter new \<name>{}-style environment name: ').'{}<Left>'
  "QUICK WAY OF DECLARING BEGIN-END ENVIRONMENTS; makes sense because
  "comma-prefix denotes many of these, but use comma-period if you forgot
  " nnoremap <buffer> <expr> ,. 'i'.<sid>beginend(input('Enter block name: ')).'<Up><End>'
  " nnoremap <buffer> ,. i\begin{}<CR><CR>\end{}<Up><Up><End><Left>
  nnoremap <buffer> <expr> ,. 'A<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
  vnoremap <buffer> <expr> ,. '<Esc>mA`>a\end{'.input('Enter begin-end-style environment name: ').'}<Esc>"ayiB'
        \.'F\i<CR><Esc>==`<i\begin{}<Esc>"aPf}a<CR><Esc>' . '<Up>V/\\end{<CR>==:noh<CR>`A'
        " \.'F\mB`<i\begin{}<Esc>"aPf}a<CR><Esc>`Bi<CR><Esc>`A'
  inoremap <buffer> <expr> ,. '<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
    "properly-indented begin-end environment, places cursor in middle
    "first start newline and enter \begin{}, then exit, then input new environment name inside, then exit
    "then paste name (line looks like \begin{name}name, then wrap pasted name in \end{}, and add new lines
    "for the visual remap, adding new lines messes up the < and > marks, so need to do that t end
    "some of these use the ". register ('last insterted text'), others just yank the word into the 'a' register
    "for the visual selection version, hard to get indent correct, so let Vim do it

  "LATEX 'INNER'/'OUTER'/'SURROUND' SYNTAX
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> daq F`df'
  nnoremap <buffer> diq T`dt'
  nnoremap <buffer> caq F`cf'
  nnoremap <buffer> ciq T`ct'
  nnoremap <buffer> yaq F`yf'
  nnoremap <buffer> yiq T`yt'
  nnoremap <buffer> vaq F`vf'
  nnoremap <buffer> viq T`vt'
    "single LaTeX quotes
  nnoremap <buffer> dsQ 2f'F'2x2F`2x
  nnoremap <buffer> daQ 2F`d2f'
  nnoremap <buffer> diQ T`dt'
  nnoremap <buffer> caQ 2F`c2f'
  nnoremap <buffer> ciQ T`ct'
  nnoremap <buffer> yaQ 2F`y2f'
  nnoremap <buffer> yiQ T`yt'
  nnoremap <buffer> vaQ 2F`v2f'
  nnoremap <buffer> viQ T`vt'
    "double LaTeX quotes (can't handle nesting)
  nnoremap <buffer> <expr> csl 'mAF{F\lct{'.input('Enter new \<name>{}-style environment name: ').'<Esc>`A'
  nmap <buffer> dsl F{F\dt{dsB
    "change e.g. textbf to textit
    "for dsl, use nmap instead of nnoremap, because want recursion to SURROUND utility
  nnoremap <buffer> dal F{F\dt{daB
  nnoremap <buffer> cal F{F\dt{caB
  nnoremap <buffer> yal F{F\vf{%y
  nnoremap <buffer> val F{F\vf{%
  nnoremap <buffer> dil diB
  nnoremap <buffer> cil ciB
  nnoremap <buffer> yil yiB
  nnoremap <buffer> vil viB
    "remaps for manipulating \textbf{}-type environments; 
    "yanking/deleting/changing/selecting inner/outer content
  nnoremap <buffer> dsL ?begin<CR>hdf}/end<CR>hdf}
  nnoremap <buffer> <expr> csL 'mA?\\begin{<CR>t}ciB'.input("Enter new begin-end environment name: ")
        \.'<Esc>/\\end{<CR>t}diB".P`A:noh<CR>'
    "fancy begin-end editing; see :help registers, the ". register contains
    "last-inserted text; registers ordinarily easy
  " nnoremap <buffer> diL ?begin<CR>f}lv/end<CR>hhd
  " nnoremap <buffer> daL ?begin<CR>hv/end<CR>f}d
  " nnoremap <buffer> ciL ?begin<CR>f}lv/end<CR>hhs
  " nnoremap <buffer> caL ?begin<CR>hv/end<CR>f}s
  nnoremap <buffer> viL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$
  nnoremap <buffer> diL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$d
  nnoremap <buffer> ciL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$d<Up>$<CR>
  nnoremap <buffer> vaL ?\\begin{<CR>0v/\\end<CR>$
  nnoremap <buffer> daL ?\\begin{<CR>0v/\\end<CR>$d
  nnoremap <buffer> caL ?\\begin{<CR>0v/\\end<CR>$s
    "remaps for manipulating \begin{a}\end{a}-type environments; 
    "yanking/deleting/selecting inner/outer content
    "note these only work reliably if can use left-right arrow to switch to newline

  "MATH SYMBOLS
  "USES THE GREEK ALPHABET CONVERSION WHERE POSSIBLE
  "...greek letters, symbols, operators
  inoremap <buffer> .i \item 
    "this is an exception
  inoremap <buffer> .a \alpha 
  inoremap <buffer> .b \beta 
  inoremap <buffer> .c \chi 
  inoremap <buffer> .d \delta 
  inoremap <buffer> .D \Delta 
  inoremap <buffer> .e \epsilon 
  inoremap <buffer> .f \phi 
  inoremap <buffer> .F \Phi 
  inoremap <buffer> .g \gamma 
  inoremap <buffer> .G \Gamma 
  inoremap <buffer> .h \eta 
  inoremap <buffer> .k \kappa 
  inoremap <buffer> .l \lambda 
  inoremap <buffer> .L \Lambda 
  inoremap <buffer> .m \mu 
  inoremap <buffer> .n \nabla 
  inoremap <buffer> .N \nu 
  inoremap <buffer> .p \pi 
  inoremap <buffer> .P \Pi 
  inoremap <buffer> .q \theta 
  inoremap <buffer> .Q \Theta 
  inoremap <buffer> .r \rho 
  inoremap <buffer> .s \sigma 
  inoremap <buffer> .S \Sigma 
  inoremap <buffer> .t \tau 
  inoremap <buffer> .u \psi 
  inoremap <buffer> .U \Psi 
  inoremap <buffer> .u \tau 
  inoremap <buffer> .w \omega 
  inoremap <buffer> .W \Omega 
  inoremap <buffer> .X \xi 
    "xi is the one that looks like zeta, but extra squiggly ;)
  inoremap <buffer> .z \zeta 
    "lambda looks like a y
  inoremap <buffer> .1 \partial 
    "this is sometimes subscripted; is never the dx in integral, so no space
  inoremap <buffer> .2 \mathrm{d}
  inoremap <buffer> .3 \mathrm{D}
    "3 levels of differentiation; each one stronger
  inoremap <buffer> .4 \sum 
  inoremap <buffer> .5 \prod 
  inoremap <buffer> .6 \int 
  inoremap <buffer> .7 \iint 
  inoremap <buffer> .8 \oint 
  inoremap <buffer> .9 \oiint 
  inoremap <buffer> .x \times 
    "./ because it's very common
  inoremap <buffer> .o \cdot 
  inoremap <buffer> .O \circ 
  "...modifiers indicating case/approximation
  inoremap <buffer> .- {-}
  inoremap <buffer> .+ {+}
  inoremap <buffer> .~ {\sim}
  "AMBIGUOUS CATEGORY; PREFIX WITH . IN PRACTICE IS FASTER, BECAUSE OFTEN DO
  "SUB/SUPER SCRIPTS OF SYMBOLS, OR FRACTIONS LOADED WITH SYMBOLS
  "Sub/super scripts (logic: k is 'up', j is 'down'),
  "and oversets/undersets (e.g. above operators)... pretty neat/logical!
  inoremap <buffer> ;k ^{}<Left>
  inoremap <buffer> ;j _{}<Left>
  inoremap <buffer> ;J \underset{}{}<Left><Left><Left>
  vnoremap <buffer> ;J <Esc>`>a}{}<Esc>`<i\underset{<Esc>%<Right>a
  inoremap <buffer> ;K \overset{}{}<Left><Left><Left>
  vnoremap <buffer> ;K \overset{}{}<Left><Left><Left>
  inoremap <buffer> ;e \times10^{}<Left>
  inoremap <buffer> ., \,
    "...easier to use
  "Cases array
  inoremap <buffer> ;c \left\{\begin{matrix}[ll]<Esc>mAa\end{matrix}\right.<Esc>`Aa
    "works...because disabled ;c for curly bracket
  "Make fraction
  inoremap <buffer> ;f \frac{}{}<Left><Left><Left>
  "Cancelto
  inoremap <buffer> ;0 \cancelto{}{}<Left><Left><Left>
  "Centerline (can modify this; \rule is simple enough to understand)
  inoremap <buffer> ._ {\centering\noindent\rule{\paperwidth/2}{0.7pt}}
  "DELIMITERS (ADVANCED)/QUICK ENVIRONMENTS
  inoremap <buffer> ;\| \left\|\right\|<Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;\| mAlbi\left\|<Esc>ea\right\|<Esc>`A
  vnoremap <buffer> ;\| mA<Esc>`>a\right\|<Esc>`<i\left\|<Esc>`AF\
  inoremap <buffer> ;( \left(\right)<Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;( mAlbi\left(<Esc>ea\right)<Esc>`A
  vnoremap <buffer> ;( mA<Esc>`>a\right)<Esc>`<i\left(<Esc>`AF\
  inoremap <buffer> ;[ \left[\right]<Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;[ mAlbi\left[<Esc>ea\right]<Esc>`A
  vnoremap <buffer> ;[ mA<Esc>`>a\right)<Esc>`<i\left(<Esc>`AF\
  inoremap <buffer> ;{ \left\{\right\}<Left><Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;{ mAlbi\left\{<Esc>ea\right\}<Esc>`A
  vnoremap <buffer> ;{ mA<Esc>`>a\right\}<Esc>`<i\left\{<Esc>`AF\
  inoremap <buffer> ;< \left<\right><Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;< mAlbi\left<<Esc>ea\right><Esc>`A
  vnoremap <buffer> ;< mA<Esc>`>a\right><Esc>`<i\left<<Esc>`AF\
  " "Emphasized text
  " inoremap <buffer> ;E \emph{}<Left>
  " nnoremap <buffer> ;E mAlbi\emph{<Esc>ea}<Esc>`A
  " vnoremap <buffer> ;E mA<Esc>`>a}<Esc>`<i\emph{<Esc>`AF\
  "Quotes
  inoremap <buffer> ;` ``''<Left><Left>
  nnoremap <buffer> ;` mAlbi``<Esc>ea''<Esc>`A
  vnoremap <buffer> ;` mA<Esc>`>a''<Esc>`<i''<Esc>`A2l
  "Color ('o' for color)
  inoremap <buffer> ;o \color{red}{}<Left>
  nnoremap <buffer> ;o mAlbi\color{red}{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;o mA<Esc>`>a}<Esc>`<i\color{red}{<Esc>`AF\
  "Bold (t for textbf, most common modifier anyway)
  inoremap <buffer> ;t \textbf{}<Left>
  nnoremap <buffer> ;t mAciW\textbf{<C-r>"}<Esc>`A
  vnoremap <buffer> ;t c\textbf{<C-r>"}<Esc>
  " nnoremap <buffer> ;t mAlbi\textbf{<Esc>ea}<Esc>`A
  " vnoremap <buffer> ;t mA<Esc>`>a}<Esc>`<i\textbf{<Esc>`AF\
  "Regular text (explanations/annotations)
  inoremap <buffer> ;T \text{}<Left>
  nnoremap <buffer> ;T mAlbi\text{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;T mA<Esc>`>a}<Esc>`<i\text{<Esc>`AF\
  "tYpewriter text; think 'Y' command in ipython notebooks
  inoremap <buffer> ;y \texttt{}<Left>
  nnoremap <buffer> ;y mAlbi\texttt{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;y mA<Esc>`>a}<Esc>`<i\texttt{<Esc>`AF\
  "Italics
  inoremap <buffer> ;i \textit{}<Left>
  nnoremap <buffer> ;i mAlbi\textit{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;i mA<Esc>`>a}<Esc>`<i\textit{<Esc>`AF\
  "Underline
  inoremap <buffer> ;u \underline{}<Left>
  nnoremap <buffer> ;u mAlbi\underline{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;u mA<Esc>`>a}<Esc>`<i\underline{<Esc>`AF\
  "Math, regular font
  inoremap <buffer> ;m \mathrm{}<Left>
  nnoremap <buffer> ;m mAlbi\mathrm{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;m mA<Esc>`>a}<Esc>`<i\mathrm{<Esc>`AF\
  "Math bold
  inoremap <buffer> ;M \mathbf{}<Left>
  nnoremap <buffer> ;M mAlbi\mathbf{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;M mA<Esc>`>a}<Esc>`<i\mathbf{<Esc>`AF\
  "Math regular text (symbols; n because it's close to m)
  inoremap <buffer> ;n \mathcal{}<Left>
  nnoremap <buffer> ;n mAlbi\mathcal{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;n mA<Esc>`>a}<Esc>`<i\mathcal{<Esc>`AF\
  "Math caligraphy (symbols; N because it's close to m)
  inoremap <buffer> ;N \mathbb{}<Left>
  nnoremap <buffer> ;N mAlbi\mathbb{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;N mA<Esc>`>a}<Esc>`<i\mathbb{<Esc>`AF\
  "Vector
  inoremap <buffer> ;v \vec{}<Left>
  nnoremap <buffer> ;v mAlbi\vec{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;v mA<Esc>`>a}<Esc>`<i\vec{<Esc>`AF\
  "Boxed
  inoremap <buffer> ;x \boxed{}<Left>
  nnoremap <buffer> ;x mAlbi\boxed{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;x mA<Esc>`>a}<Esc>`<i\boxed{<Esc>`AF\
  "Special box
  inoremap <buffer> ;X \fbox{\parbox{\textwidth}{}}\medskip<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>
  nnoremap <buffer> ;X mAlbi\fbox{\parbox{\textwidth}{<Esc>ea}}\medskip<Esc>`A
  vnoremap <buffer> ;X mA<Esc>`>a}}\medskip<Esc>`<i\fbox{\parbox{\textwidth}{<Esc>`AF\
  " "Square root
  inoremap <buffer> ;Q \sqrt{}<Left>
  nnoremap <buffer> ;Q mAlbi\sqrt{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;Q mA<Esc>`>a}<Esc>`<i\sqrt{<Esc>`AF\
  "Quotes (never really use singles, so forget that)
  " inoremap <buffer> ;q `'<Left>
  " nnoremap <buffer> ;q mAlbi`<Esc>ea'<Esc>`A
  " vnoremap <buffer> ;q mA<Esc>`>a'<Esc>`<i`<Esc>`AF\
  inoremap <buffer> ;q ``''<Left><Left>
  nnoremap <buffer> ;q mAlbi``<Esc>ea''<Esc>`A
  vnoremap <buffer> ;q mA<Esc>`>a''<Esc>`<i``<Esc>`AF\
  "Hat (use =, because don't happen to be using it; does not require Shift)
  inoremap <buffer> ;h \hat{}<Left>
  nnoremap <buffer> ;h mAlbi\hat{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;h mA<Esc>`>a}<Esc>`<i\hat{<Esc>`AF\
  "Tilde (= so I don't have to hit shift)
  inoremap <buffer> ;= \tilde{}<Left>
  nnoremap <buffer> ;= mAlbi\tilde{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;= mA<Esc>`>a}<Esc>`<i\tilde{<Esc>`AF\
  "Overline
  inoremap <buffer> ;- \overline{}<Left>
  nnoremap <buffer> ;- mAlbi\overline{<Esc>ea}<Esc>`A
  vnoremap <buffer> ;- mA<Esc>`>a}<Esc>`<i\overline{<Esc>`AF\
  "Basic math/inline math
  inoremap <buffer> ;$ $$<Left>
  nnoremap <buffer> ;$ mAlbi$<Esc>ea$<Esc>`A
  vnoremap <buffer> ;$ mA<Esc>`>a$<Esc>`<i$<Esc>`AF\
  "ENVIRONMENTS TRIGGERS BY SWITCHES INSIDE CURLY BRACKETS, OR begin/end statements
  "Very small
  inoremap <buffer> ;1 {\footnotesize }<Left>
  nnoremap <buffer> ;1 mAlbi{\footnotesize<Esc>ea}<Esc>`A
  vnoremap <buffer> ;1 mA<Esc>`>a}<Esc>`<i{\footnotesize<Esc>`AF\
  "Small
  inoremap <buffer> ;2 {\small }<Left>
  nnoremap <buffer> ;2 mAlbi{\small<Esc>ea}<Esc>`A
  vnoremap <buffer> ;2 mA<Esc>`>a}<Esc>`<i{\small<Esc>`AF\
  "Normal
  inoremap <buffer> ;3 {\normalsize }<Left>
  nnoremap <buffer> ;3 mAlbi{\normalsize<Esc>ea}<Esc>`A
  vnoremap <buffer> ;3 mA<Esc>`>a}<Esc>`<i{\normalsize<Esc>`AF\
  "Big
  inoremap <buffer> ;4 {\large }<Left>
  nnoremap <buffer> ;4 mAlbi{\large<Esc>ea}<Esc>`A
  vnoremap <buffer> ;4 mA<Esc>`>a}<Esc>`<i{\large<Esc>`AF\
  "Very big
  inoremap <buffer> ;5 {\Large }<Left>
  nnoremap <buffer> ;5 mAlbi{\Large<Esc>ea}<Esc>`A
  vnoremap <buffer> ;5 mA<Esc>`>a}<Esc>`<i{\Large<Esc>`AF\
  "BEGIN/END FORMAT ENVIRONMENTS, ENVIRONMENTS THAT CAN'T BE DESCRIBE AS 'FANCY DELIMITERS'
  "0 is the middle number?
  " inoremap <buffer> ,0 \centering
  inoremap <buffer> ,0 \frametitle{}<Left>
  "Sections (generally only in insert mode)
  inoremap <buffer> ,1 \section{}<Left>
  inoremap <buffer> ,2 \section*{}<Left>
  inoremap <buffer> ,3 \subsection{}<Left>
  inoremap <buffer> ,4 \subsection*{}<Left>
  inoremap <buffer> ,5 \subsubsection{}<Left>
  inoremap <buffer> ,6 \subsubsection*{}<Left>
  vnoremap <buffer> ,1 <Esc>mA`>a}<Esc>`<i\section{<Esc>`A
  vnoremap <buffer> ,2 <Esc>mA`>a}<Esc>`<i\section*{<Esc>`A
  vnoremap <buffer> ,3 <Esc>mA`>a}<Esc>`<i\subsection{<Esc>`A
  vnoremap <buffer> ,4 <Esc>mA`>a}<Esc>`<i\subsection*{<Esc>`A
  vnoremap <buffer> ,5 <Esc>mA`>a}<Esc>`<i\subsubsection{<Esc>`A
  vnoremap <buffer> ,6 <Esc>mA`>a}<Esc>`<i\subsubsection*{<Esc>`A
  "Lists
  inoremap <buffer> ,i \begin{itemize}<CR>\end{itemize}<Up><End><CR>
  vnoremap <buffer> ,i mA<Esc>`>a<CR>\end{itemize}<Esc>`<i\begin{itemize}<CR><Esc>`AF\
  inoremap <buffer> ,n \begin{enumerate}<CR>\end{enumerate}<Up><Esc>A[]<Left>
  vnoremap <buffer> ,n mA<Esc>`>a<CR>\end{enumerate}<Esc>`<i\begin{enumerate}<CR><Esc>`AF\
  inoremap <buffer> ,d \begin{description}<CR>\end{description}<Up><Esc>A<CR>
  vnoremap <buffer> ,d mA<Esc>`>a<CR>\end{description}<Esc>`<i\begin{description}<CR><Esc>`AF\
  "Special math modes
  inoremap <buffer> ,p \begin{pmatrix}\end{pmatrix}<Esc>F}a
  vnoremap <buffer> ,p mA<Esc>`>a\end{pmatrix}<Esc>`<i\begin{pmatrix}<Esc>`AF\
  inoremap <buffer> ,P \begin{pmatrix}<CR>\end{pmatrix}<Up><Esc>A<CR>
  vnoremap <buffer> ,P mA<Esc>`>a<CR>\end{pmatrix}<Esc>`<i\begin{pmatrix}<CR><Esc>`AF\
  inoremap <buffer> ,b \begin{bmatrix}\end{bmatrix}<Esc>F}a
  vnoremap <buffer> ,b mA<Esc>`>a\end{bmatrix}<Esc>`<i\begin{bmatrix}<Esc>`AF\
  inoremap <buffer> ,B \begin{bmatrix}<CR>\end{bmatrix}<Up><Esc>A<CR>
  vnoremap <buffer> ,B mA<Esc>`>a<CR>\end{bmatrix}<Esc>`<i\begin{bmatrix}<CR><Esc>`AF\
  inoremap <buffer> ,T \begin{tabular}<CR>\end{tabular}<Up><Esc>A[]<Left>
  vnoremap <buffer> ,T mA<Esc>`>a<CR>\end{tabular}<Esc>`<i\begin{tabular}<CR><Esc>`AF\
  "Math environments (generally only in insert mode and visual mode)
  inoremap <buffer> ,e \begin{equation*}<CR>\end{equation*}<Up><Esc>A<CR>
  vnoremap <buffer> ,e mA<Esc>`>a<CR>\end{equation*}<Esc>`<i\begin{equation*}<CR><Esc>`AF\
  inoremap <buffer> ,a \begin{align*}<CR>\end{align*}<Up><Esc>A<CR>
  vnoremap <buffer> ,a mA<Esc>`>a<CR>\end{align*}<Esc>`<i\begin{align*}<CR><Esc>`AF\
  inoremap <buffer> ,E \begin{equation}<CR>\end{equation}<Up><Esc>A<CR>
  vnoremap <buffer> ,E mA<Esc>`>a<CR>\end{equation}<Esc>`<i\begin{equation}<CR><Esc>`AF\
  inoremap <buffer> ,A \begin{align}<CR>\end{align}<Up><Esc>A<CR>
  vnoremap <buffer> ,A mA<Esc>`>a<CR>\end{align}<Esc>`<i\begin{align}<CR><Esc>`AF\
  "Frames/figures
  "s is for 'slide' below
  inoremap <buffer> ,s \begin{frame}<CR>\end{frame}<Up><Esc>A<CR>
  vnoremap <buffer> ,s mA<Esc>`>a<CR>\end{frame}<Esc>`<i\begin{frame}<CR><Esc>`AF\
  inoremap <buffer> ,c \begin{columns}<CR>\end{columns}<Up><Esc>A<CR>
  vnoremap <buffer> ,c mA<Esc>`>a<CR>\end{columns}<Esc>`<i\begin{columns}<CR><Esc>`AF\
  inoremap <buffer> ,C \begin{column}{.5\textwidth}<CR>\end{column}<Up><Esc>A<CR>
  vnoremap <buffer> ,C mA<Esc>`>a<CR>\end{column}<Esc>`<i\begin{column}{.5\textwidth}<CR><Esc>`AF\

  inoremap <buffer> ,m \begin{minipage}{\linewidth}<CR>\end{minipage}<Up><Esc>A<CR>
  vnoremap <buffer> ,m mA<Esc>`>a<CR>\end{minipage}<Esc>`<i\begin{minipage}<CR><Esc>`AF\
  " inoremap <buffer> ,F \begin{figure}<CR>\end{figure}<Up><Esc>A[]<Left>
  inoremap <buffer> ,f \begin{figure}<CR>\end{figure}<Up><End><CR>\centering<CR>
  vnoremap <buffer> ,f mA<Esc>`>a<CR>\end{figure}<Esc>`<i\begin{figure}<CR>\centering<CR><Esc>`AF\
  inoremap <buffer> ,F \begin{subfigure}{.5\textwidth}<CR>\end{subfigure}<Up><Esc>A<CR>
  vnoremap <buffer> ,F mA<Esc>`>a<CR>\end{subfigure}<Esc>`<i\begin{subfigure}{.5\textwidth}<CR><Esc>`AF\
  inoremap <buffer> ,w \begin{wrapfigure}{r}{.5\textwidth}<CR>\center<CR>\end{wrapfigure}<Up><End><CR>
  "ENVIRONMENTS THAT MIGHT BE CLASSIFIED AS 'FANCY DELIMITERS', BUT RELATED STRONGLY
  "TO BEGIN-END ENVIRONMENTS SO WILL USE ',' INSTEAD OF ';'
  "Special
  inoremap <buffer> ,g \includegraphics[width=]{}<Left><Left><Left>
  inoremap <buffer> ,G \makebox[\textwidth][c]{\includegraphics[width=\textwidth]{}}<Left><Left><Left>
    "x for 'box'
  inoremap <buffer> ,t \caption{}<Left>
  inoremap <buffer> ,l \label{}<Left>
  inoremap <buffer> ,L \tag{}<Left>
    "tagging is to change from the default 1-2-3 ordering of equations, figures, etc.
  inoremap <buffer> ,r \autoref{}<Left>
  inoremap <buffer> ,R \cite{}<Left>
    "centering generally only used inside other environments

"COMMANDS FOR COMPILING LATEX
"-use clear, because want to clean up previous output first
"-use set -x to ECHO LAST COMMAND
  noremap <silent> <buffer> <C-x> :w<CR>:exec("!clear; set -x; "
        \."~/.vim/compile false ".shellescape(@%))<CR>
  noremap <silent> <buffer> <C-z> :w<CR>:exec("!clear; set -x; "
        \."~/.vim/compile true ".shellescape(@%))<CR>
    "must store script in .VIM FOLDER
  " inoremap <silent> <buffer> <C-x> <Esc>:w<CR>:exec("!clear; set -x; which latex; "
        " \."latex ".shellescape(@%))<CR>a
"WORD COUNT
  " vnoremap <C-c> g<C-g>
  vnoremap <C-w> g<C-g>
endfunction
"FUNCTION FOR LOADING TEMPLATES
"See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
function! s:textemplates()
  let templates=split(globpath('~/.vim/templates/', '*.tex'),"\n")
  let names=[]
  for template in templates
    call add(names, '"'.fnamemodify(template, ":t:r").'"')
      "expand does not work, for some reason... because expand is used with one argument
      "with a globalfilename, e.g. % (current file)... fnamemodify is for strings
  endfor
  while 1
    echo "Current templates available: ".join(names, ", ")."."
    let template=expand("~")."/.vim/templates/".input("Enter choice: ").".tex"
    if filereadable(template)
      execute "0r ".template
      break
    endif
    echo "\nInvalid name."
  endwhile
endfunction
"Toggle all these mappings
autocmd FileType tex call s:texmacros()
autocmd BufNewFile *.tex call s:textemplates()

"FORTRAN MACROS
function! s:fortranmacros()
  "Will compile code, then run it and show user the output
  noremap  <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."gfortran ".shellescape(@%)." -o ".expand('%:r')."; ./".expand('%:r')."<CR>"
endfunction
autocmd FileType fortran call s:fortranmacros()
"Also fix coloring issues; see :help fortran
let fortran_fold=1
let fortran_free_source=1
let fortran_more_precise=1

"PYTHON MACROS
"Macros for compiling code
function! s:pymacros()
  "Simple shifting
  setlocal tabstop=4
  setlocal softtabstop=4
  setlocal shiftwidth=4
  "Get simple pydoc string (space, because manpage/help page shortcuts start with space)
  "Now obsolute because have jedi-vim
  noremap <buffer> <expr> ?p ":!clear; set -x; pydoc "
        \.input("Enter python documentation keyword: ")."<CR>"
  "Run current file (rename to tmp, because couldn't figure out how to use magic code there)
  noremap <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."python ".shellescape(@%)."<CR>"
        " \."ipython --no-banner --no-confirm-exit -c 'run ".shellescape(@%)."'<CR>"
endfunction
"Toggle mappings with autocmds...or disable because they suck for now
autocmd FileType python call s:pymacros()
"Skeleton-code templates...decided that's unnecessary for python
" autocmd BufNewFile *.py 0r ~/skeleton.py

"HTML MACROS, lots of insert-mode stuff
function! s:htmlmacros()
  "Basic stuff
  inoremap <buffer> ,h <head><CR><CR></head><Up>
  vnoremap <buffer> ,h mA<Esc>`>a<CR></head><Esc>`<i<head><CR><Esc>`AF\
  inoremap <buffer> ,b <body><CR><CR></body><Up>
  vnoremap <buffer> ,b mA<Esc>`>a<CR></body><Esc>`<i<body><CR><Esc>`AF\
endfunction
"Toggle mappings
autocmd FileType html call s:htmlmacros()

"SHELL MACROS
"MANPAGES of stuff
noremap <expr> ?m ":silent !clear; man "
    \.input('Search manpages: ')."<CR>:redraw!<CR>"
"--help info; pipe output into less for better interaction
noremap <expr> ?h ":!clear; "
    \.input('Show --help info: ')." --help \| less<CR>:redraw!<CR>"

"------------------------------------------------------------------------------
" SESSION MANAGEMENT
"------------------------------------------------------------------------------
"REMEMBER FILE POSITION, SO RETURN TO SAME SPOT AFTER RE-OPNENING
autocmd BufReadPost *
   \ if line("'\"") > 0 && line("'\"") <= line("$") |
   \   exe "normal! g`\"" |
   \ endif

" SESSION MANAGEMENT
" nnoremap <leader>S :ToggleWorkspace<CR>
" let g:workspace_session_name = '.session.vim'
autocmd VimEnter * Obsession .session.vim

"SESSION MANAGEMENT
" fu! SaveSess()
"     execute 'mksession! ' . getcwd() . '/.session.vim'
" endfunction
" fu! RestoreSess()
" if filereadable(getcwd() . '/.session.vim')
"     execute 'so ' . getcwd() . '/.session.vim'
"     if bufexists(1)
"         for l in range(1, bufnr('$'))
"             if bufwinnr(l) == -1
"                 exec 'sbuffer ' . l
"             endif
"         endfor
"     endif
" endif
" endfunction
" autocmd BufEnter,VimLeavePre * call SaveSess()
" autocmd VimEnter * nested call RestoreSess()

"------------------------------------------------------------------------------
" PLUGIN RELATED STUFF
"------------------------------------------------------------------------------
"VIM-PLUG PLUGINS
call plug#begin('~/.vim/plugged')
Plug 'vim-scripts/matchit.zip'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-obsession'
if v:version >= 800
  Plug 'majutsushi/tagbar'
  "VIM had major issues with tagbar on remote servers
endif
if has("lua")
  Plug 'shougo/neocomplete.vim'
  Plug 'davidhalter/jedi-vim'
  "These need special support
endif
Plug 'vim-scripts/Toggle'
Plug 'tpope/vim-surround'
Plug 'metakirby5/codi.vim'
Plug 'Tumbler/highlightMarks'
Plug 'godlygeek/tabular'
Plug 'raimondi/delimitmate'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'gioele/vim-autoswap' "deals with swap files automatically
Plug 'triglav/vim-visual-increment' "visual incrementing
"The conda plugin is for changing anconda VIRTUALENV; probably don't need it
" Plug 'cjrh/vim-conda'
"Had issues with python plugins before; brew upgrading VIM fixed them magically
"Note you must choose between jedi-vim and python-mode; cannot use both! See github
" Plug 'ivanov/vim-ipython'
" Plug 'hdima/python-syntax' "does not seem to work
  "INSTEAD THIS FUNCTION IS PUT MANUALLY IN SYNTAX FOLDER; VIM-PLUG FAILED
" Plug 'klen/python-mode' "must make VIM compiled with anaconda for this to work
  "otherwise get weird errors; same with vim conda and vim ipython
call plug#end()
  "the plug#end also declares filetype syntax and indent on

"DISABLE LINE NUMBERS AND SPECIAL CHARACTERS IN SPECIAL WINDOWS; ENABLE q-QUITTING
"AND SOME HELP SETTINGS
noremap ?? :vert help 
au FileType help wincmd L
au FileType help noremap <buffer> q :q<CR>
autocmd BufEnter help if len(tabpagebuflist())==1 | q | endif
  "exit from help window, if it is only one left
" autocmd FileType help wincmd T
"   "using vsplit help doesn't work when i tried it; also need to
"   "turn off spelling
"The doc pages appear in rst files, so turn off extra chars for them
"Also the syntastic shows up as qf files
autocmd FileType rst setlocal nolist
autocmd FileType rst setlocal nonumber
autocmd FileType rst setlocal nospell
autocmd FileType help setlocal nolist
autocmd FileType help setlocal nonumber
autocmd FileType help setlocal nospell
autocmd FileType qf setlocal nolist
autocmd FileType qf setlocal nonumber
autocmd FileType qf setlocal nospell

"Jedi-VIM
"See: https://github.com/davidhalter/jedi-vim
"The autocmd line disables docstring popup window
" let g:jedi#force_py_version=3
let g:jedi#auto_vim_configuration = 0
  " set these myself instead
let g:jedi#rename_command = ""
  "jedi-vim recommended way of disabling commands
  "NOTE JEDI AUTO-RENAMING SKETCHY, SOMETIMES FAILS
  "GOOD EXAMPLE IS TRY RENAMING 'debug' IN METADATA FUNCTION;
  "JEDI SKIPS F-STRINGS, SKIPS ITS RE-ASSIGNMENT IN FOR LOOP,
  "SKIPS WHERE IT APPEARED AS DEFAULT KWARG IN FUNCTION
let g:jedi#usages_command = "?g"
  "open up list of places where variable appears; then can 'goto'
let g:jedi#goto_assignments_command = "?G"
  "goto location where definition/class defined
let g:jedi#documentation_command = "?d"
autocmd FileType python setlocal completeopt-=preview
"VIM python-mode
" let g:pymode_python='python3'

"MARK HIGHLIGHTING
" let g:highlightMarks_colors=['orange', 'yellow', 'green', 'blue', 'purple', '#00BB33']
" let g:highlightMarks_cterm_colors=[3, 2, 4, 1]
  "above is default
let g:highlightMarks_colors=['blue']
let g:highlightMarks_cterm_colors=[4] "4 and 1 are best

"PYTHON SYNTAX
"...must enable some options manually
au FileType python let python_highlight_all=1
" au FileType python Python3Syntax
"python3 is enabled by default; see doc info
"...might also try the default... was it better? think it was worse

"VIM visual increment; creating columns of 1/2/3/4 etc.
"Disable all remaps
imap <Left> <Nop>
imap <Right> <Nop>
imap <Up> <Nop>
imap <Down> <Nop>
"Disable old ones
silent! vunmap <C-a>
silent! vunmap <C-x>
vmap <Left> <Nop>
vmap <Right> <Nop>
vmap <Up> <Plug>VisualIncrement
vmap <Down> <Plug>VisualDecrement

"CODI (MATHEMATICAL NOTEPAD)
nnoremap <silent> <expr> <Space>C ':tabe '.input('Enter calculator name: ').'.py<CR>:Codi python<CR>'
nnoremap <silent> <expr> <Space>c ':Codi '.eval('&ft').'<CR>'
  "turns current file into calculator
let g:codi#rightalign = 0
let g:codi#rightsplit = 0
let g:codi#width = 20

"NEOCOMPLETE (RECOMMENDED SETTINGS)
"CRITICAL KEY MAPPINGS
" inoremap <silent> <expr> [3~ pumvisible() ? neocomplete#smart_close_popup()."\<Delete>" : "\<Delete>"
  "ruins bracket autofill in insert mode, so forget it; idea was make delete
  "close popup menu, but ALREADY DOES, because <Delete> actually escapes us from
  "normal mode, then the [3~ gets triggered
inoremap <silent> <expr> jk pumvisible() ? neocomplete#smart_close_popup()."\<Esc>:call <sid>escape()\<CR>%%a" : "\<Esc>:call <sid>escape()\<CR>%%a"
" inoremap <silent> <expr> l; pumvisible() ? neocomplete#smart_close_popup()."\<Esc>:call <sid>escape()\<CR>%%a" : "\<Esc>:call <sid>escape()\<CR>%%a"
  "above remaps let me bang on those keys in ANY ORDER! they don't interfere with each other
inoremap <silent> <expr> kj pumvisible() ? "\<C-y>" : "kj"
  "complete_common_string keeps popup open, for some reason
" inoremap <silent> <expr> ;l neocomplete#complete_common_string()
" inoremap <silent> <expr> :u neocomplete#undo_completion()
inoremap <silent> <expr> <C-c> pumvisible() ? neocomplete#smart_close_popup()."<Esc>:call <sid>escape()<CR>" : "<Esc>:call <sid>escape()<CR>"
inoremap <silent> <expr> <Esc> pumvisible() ? neocomplete#smart_close_popup()."<Esc>:call <sid>escape()<CR>" : "<Esc>:call <sid>escape()<CR>"
" inoremap <silent> <expr> <C-c> pumvisible() ? neocomplete#smart_close_popup() : "<Esc>:call <sid>escape()<CR>"
" inoremap <silent> <expr> <Esc> pumvisible() ? neocomplete#smart_close_popup() : "<Esc>:call <sid>escape()<CR>"
"...tab completion
inoremap <expr> <Tab>  pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> `  pumvisible() ? "\<C-p>" : "`"
"...undo menu selection with Enter; will only use ;l for that
inoremap <expr> <CR> neocomplete#smart_close_popup()."\<CR>"
" installatio
" inoremap <expr> <BS> neocomplete#smart_close_popup()."\<BS>"
" inoremap <expr> <Space> neocomplete#smart_close_popup()."\<Space>"
"OTHER SETTINGS
let g:acp_enableAtStartup = 1
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Do not use smartcase.
let g:neocomplete#enable_smart_case = 0
let g:neocomplete#enable_camel_case = 0
let g:neocomplete#enable_ignore_case = 0
"Auto complete (turn below on and off)
let g:neocomplete#enable_auto_select = 1
let g:neocomplete#auto_completion_start_length = 2
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 2
" Define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
  \ 'default' : '',
  \ 'vimshell' : $HOME.'/.vimshell_hist',
  \ 'scheme' : $HOME.'/.gosh_completions'
      \ }
" Define keyword.
if !exists('g:neocomplete#keyword_patterns')
  let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'
"Shell like behavior(not recommended).
" set completeopt+=longest
" let g:neocomplete#enable_auto_select = 1
" let g:neocomplete#disable_auto_complete = 1
" inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"
"Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"GENERAL AUTO-COMPLETE SETTINGS
" "Complete settings
" set complete=. "adds dictionary opts
" "   "default is .,w,b,u,t,i which uses .=current buffer, w=buffers other
" "   "windows, u=unloaded buffers, t=tags, i=included files
" set completeopt+=longest
"^^ longest means Vim doesn't V select first completion item, and just fills
"in text to 'longest common string'; can also use menuone, show menu always
" "Fancy popup-window remaps
" inoremap <expr> <C-n> pumvisible() ? "<C-n>" :
"   \ '<C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
"   "keeps menu highlighted so you can press <Enter> to make selection
"   "(changed <c-n> to <c-p> because want to search backward, not forwards)
" inoremap <expr> <C-g> pumvisible() ? '<C-n>' :
"   \ '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
"   "same as above, but OMNICOMPLETION or 'smart completion' -- shows variables
"   "g for 'get', or something
" inoremap <expr> <C-f> pumvisible() ? "<C-x><C-f><Down>" :
"   \ '<C-x><C-f><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
"   "filenames
" inoremap <expr> <C-d> pumvisible() ? "<C-x><C-k><Down>" :
"   \ '<C-x><C-k><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
"   "definitions
"Highlighting
highlight Pmenu ctermbg=Black ctermfg=Yellow cterm=None
highlight PmenuSel ctermbg=Black ctermfg=Black cterm=None
highlight PmenuSbar ctermbg=None ctermfg=Black cterm=None
"Navigating popup menu
inoremap <expr> <C-j> pumvisible() ? "<Down>" : "<Esc>gja"
inoremap <expr> <C-k> pumvisible() ? "<Up>" : "<Esc>gka"
" inoremap <expr> <ScrollWheelUp> pumvisible() ? "<Up>" : "<Nop>"
" inoremap <expr> <ScrollWheelDown> pumvisible() ? "<Down>" : "<Nop>"
" inoremap <ScrollWheelUp> <Nop>
" inoremap <ScrollWheelDown> <Nop>

"NERDTREE
"Most important commands: 'o' to view contents, 'u' to move up directory,
"'t' open in new tab, 'T' open in new tab but retain focus, 'i' open file in 
"split window below, 's' open file in new split window VERTICAL, 'O' recursive open, 
"'x' close current nodes parent, 'X' recursive cose, 'p' jump
"to current nodes parent, 'P' jump to root node, 'K' jump to first file in 
"current tree, 'J' jump to last file in current tree, <C-j> <C-k> scroll direct children
"of current directory, 'C' change tree root to selected dir, 'u' move up, 'U' move up
"and leave old root node open, 'r' recursive refresh, 'm' show menu, 'cd' change CWD,
"'I' toggle hidden file display, '?' toggle help
"Remap NerdTree command
" noremap <expr> { exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName)!=-1 ? ":NERDTreeClose<CR>" : ":NERDTree<CR>"
" noremap <expr> { exists("t:NERDTreeBufName") && bufwinnr(t:NERDTreeBufName)!=-1 ? ":NERDTreeTabsClose<CR>" : ":NERDTreeTabsOpen<CR>"
noremap <Tab>j :NERDTreeTabsToggle<CR>
" noremap { :NERDTreeToggle<CR>
  "had some issues with NERDTreeToggle; failed/gave weird results
"slash, because directory hierarchies have slashes?
"...no, confusing; instead { because it shows up on left
let g:NERDTreeWinSize=20 "instead of 31 default
let NERDTreeShowHidden=1
let NERDTreeMinimalUI=1
  "remove annoying ? for help note
let NERDTreeMapChangeRoot="D"
  "C was annoying, because VIM will wait for 'CD'
autocmd BufEnter * if (winnr('$')==1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
  "Close nerdtree if last in tab

"'TOGGLE' PLUGIN for BOOLEANS
"plugin for boolean things: yes/no, true/false, True/False, +/-
"...mostly like the default maps
"applied to number, will change its sign
nmap <C-t> +
" nmap <Leader>. +
"...and already works in insert mode

"TAGBAR (requires 'brew install ctags-exuberant')
"Switch updatetime (necessary for Tagbar highlights to follow cursor)
set updatetime=250 "good default; see https://github.com/airblade/vim-gitgutter#when-are-the-signs-updated
"Note the default mappings:
" -p jumps to tag under cursor, in code window, but remain in tagbar
" -Enter jumps to tag, go to window (doesn't work for pseudo-tags, generic headers)
" -C-n and C-p browses by top-level tags
" - +,- open and close folds under cursor
" -o toggles the fold under cursor, or current one
" -q quits the window
"Some settings
let g:tagbar_show_linenumbers=0 "don't show line numbers
let g:tagbar_autofocus=1 "autojump to window if opened
let g:tagbar_sort=1 "sort alphabetically? actually much easier to navigate, so yes
let g:tagbar_case_insensitive=1 "make sorting case insensitive
let g:tagbar_compact=1 "no header information in panel
let g:tagbar_singleclick=1 "one click select 
  "(don't use this; inconsistent with help menu and makes it impossible to switch windows by clicking)
let g:tagbar_width=25 "better default
noremap <silent> <Tab>k :TagbarToggle<CR>
" au FileType python :TagbarOpen | :syntax on
" au BufEnter * nested :call tagbar#autoopen(0)
" au BufEnter python nested :TagbarOpen
" au VimEnter * nested :TagbarOpen
" au BufRead python normal }
"the vertical line, because it wasn't used and tagbar makes a 'panel'
"...no, instead } because it shows up on right

"NERDCommenter (comment out stuff)
"Note the default mappings, all prefixed by <Leader> (but we disable them)
" -cc comments line or selection
" -cn forces nesting (seems to be default though; maybe sometimes, is ignored)
" -ci toggles comment state of inidivudal lines
" -c<Space> toggles comment state based on topmost line state
" -cs comments line with block-format layout
" -cy yanks lines before commenting
" -c$ comments to eol
" -cu uncomments line
"Disable default mappings (make my own)
let g:NERDCreateDefaultMappings = 0
"NCL delimiters
au FileType ncl set commentstring=;\ %s
  "don't know why %s is necessary
"Custom delimiter overwrites (default python includes space for some reason)
let g:NERDCustomDelimiters = {'python': {'left': '#'}}
"Comments led with spaces
let g:NERDSpaceDelims = 1
"Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1
"Trailing whitespace deletion
let g:NERDTrimTrailingWhitespace=1
"Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1
"Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'
let g:NERDCommentWholeLinesInVMode = 1
"Set up *dividers* using the NerdComment() command (arg1 is mode [1 for normal], arg2 is type)
"below will extend divider to 79th column from current column position
nnoremap <expr> c\ ""
    \.""
    \."o<Esc>".col('.')."a<Space><Esc>x".eval(80-col('.')+1)."a".b:NERDCommenterDelims['left']."<Esc>"
    \."o<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>"
    \."o<Esc>".col('.')."a<Space><Esc>x".eval(80-col('.')+1)."a".b:NERDCommenterDelims['left']."<Esc>"
    \."<Up>A"
nnoremap <expr> c\| ""
    \.""
    \."o<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>".eval(79-col('.')+1)."a-<Esc>"
    \."o<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>"
    \."o<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>".eval(79-col('.')+1)."a-<Esc>"
    \."<Up>A"
nnoremap <expr> c- ""
    \.""
    \."mAo<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>".eval(79-col('.')+1)."a-<Esc>`A"
nnoremap <expr> c_ ""
    \.""
    \."mAo<Esc>".col('.')."a<Space><Esc>x".eval(80-col('.')+1)."a".b:NERDCommenterDelims['left']."<Esc>`A"
"Create python docstring
nnoremap c' o"""<CR>.<CR>"""<Up><Esc>A<BS>

" nnoremap c\| ox<BS><CR>x<BS><CR>x<BS><Esc>:call NERDComment('n', 'toggle')<CR>078a-<Esc><Up><Up>:call NERDComment('n', 'toggle')<CR>078a-<Esc><Down>:call NERDComment('n', 'toggle')<CR>0a<Space>
"Set up custom remaps
nnoremap co :call NERDComment('n', 'comment')<CR>
nnoremap cO :call NERDComment('n', 'uncomment')<CR>
nnoremap c. :call NERDComment('n', 'toggle')<CR>
vnoremap co :call NERDComment('v', 'comment')<CR>
vnoremap cO :call NERDComment('v', 'uncomment')<CR>
vnoremap c. :call NERDComment('v', 'toggle')<CR>

"SYNTASTIC (syntax checking for code)
"Turn off signcolumn (ugly; much better to just HIGHLIGHT LINES IN RED)
if exists("&signcolumn")
  set signcolumn=no
endif
"Commands for circular location-list (error) scrolling
command! Lnext try | lnext | catch | lfirst | catch | endtry
command! Lprev try | lprev | catch | llast | catch | endtry
  "the capital L are circular versions
"Helper function; checks status
function! s:syntastic_status() 
  if exists("b:syntastic_loclist")
    if empty(b:syntastic_loclist)
      return 0
    else
      return 1
    endif
  else
    return 0
  endif
endfunction
"Set up custom remaps; there are some letters that i pretty much never use after
"yanking (y), so can use 'y' for sYntax
" nnoremap yn :Lnext<CR>
" nnoremap yN :Lprev<CR>
nnoremap yo :noh<CR>:SyntasticCheck<CR>
nnoremap yO :SyntasticReset<CR>
nnoremap <expr> y. <sid>syntastic_status() ? ":SyntasticReset<CR>" : ":noh<CR>:SyntasticCheck<CR>"
  "toggle state
nnoremap <expr> n <sid>syntastic_status() ? ":Lnext<CR>" : "n"
nnoremap <expr> N <sid>syntastic_status() ? ":Lprev<CR>" : "N"
  "moving between errors
"Disable auto checking (passive mode means it only checks when we call it)
let g:syntastic_mode_map = {'mode': 'passive', 'active_filetypes': [],'passive_filetypes': []}
" au BufEnter * let b:syntastic_mode='passive'
" let g:syntastic_stl_format = "[%E{Err: %fe #%e}%B{, }%W{Warn: %fw #%w}]"
let g:syntastic_stl_format = "" "disables statusline colors; they were ugly
" nnoremap y. :SyntasticToggleMode<CR>
"And options, statusline management
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
"Other defaults
let g:syntastic_always_populate_loc_list = 1
  "necessary, or get errors
let g:syntastic_auto_loc_list = 1
  "creates window; if 0, does not create window
let g:syntastic_loc_list_height = 5
let g:syntastic_mode = 'passive'
  "opens little panel
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
"Choose syntax checkers
"and pylint location, add checker
let g:syntastic_tex_checkers=['lacheck']
" let g:syntastic_python_checkers=['pyflakes', 'pylint', 'pep8']
" let g:syntastic_python_checkers=['pyflakes', 'pylint']
let g:syntastic_python_checkers=['pyflakes']
  "PYLINT IS VERY SLOW! pyflakes is supposed to be light by comparison
let g:syntastic_fortran_checkers=['gfortran']
let g:syntastic_vim_checkers=['vimlint']
"overwrite locations
" let g:syntastic_python_pylint_exec=$HOME.'/anaconda3/bin/pylint'
" let g:syntastic_python_pyflakes_exec=$HOME.'/anaconda3/bin/pyflakes'
" let g:syntastic_python_pep8_exec=$HOME.'/anaconda3/bin/pep8'
"colors
hi SyntasticErrorLine ctermfg=White ctermbg=Red cterm=None
hi SyntasticWarningLine ctermfg=White ctermbg=Magenta cterm=None

"SPELLCHECK (really a BUILTIN plugin)
"Off by default
set nospell
"Turn on for certain filetypes
autocmd FileType tex,html,xml,text,markdown setlocal spell
"Basic stuff
set spelllang=en
set spellcapcheck=
"no capitalization check
"Toggle on and off
nnoremap ss :setlocal spell!<CR>
nnoremap sl :call <sid>spelltoggle()<CR>
set spelllang=en_us
function! s:spelltoggle()
  if &spelllang=='en_us'
    set spelllang=en_gb
    echo 'Current language: UK english'
  else
    set spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction
"navigate between words with [s and ]s (seems ok to me)
nnoremap sn [s
nnoremap sN ]s
"Get suggestions, or choose first suggestion without looking
nnoremap s. z=1<CR><CR>
nnoremap sd z=
"Add/remove from dictionary
nnoremap sa zg
nnoremap sr zug

"SURROUND (place delimiters around stuff)
"...ok with default remaps now
"...idea: this thing works will at CHANGING/DELETING surrounding stuff, but
"adding them is a simple command, and too long... will use my own commands maybe
" see documentation in ~/.vim/doc for details, but the gist is:
" cs<delim><newdelim> to e.g. change surrounding { into (
" ds<delim> to e.g. delete the surrounding {
" ys<movement/inner something/block indicator><newdelim> to e.g. add quotes
"     around word iw, add parentheses between cursor and W movement, etc.
" yss is special case (should be memorized; ys"special"); performs for entire
"     line, ignoring leading/trailing whitespace
" yS<movement><newdelim> puts text on line of its own, and auto-indents
"     according to indent settings
" S<newdelim>, VISUAL MODE remap to place surroundings
"     ...if your <newdelim> is something like <a>, then by default the first one
"     will be <a> and the closing one </a>, for HTML useage
" t,< will generically refer to ANY HTML-environment
" ], [ are different; the first adds no space, the second *does* add space
" b, B, r, a correspond to ), }, ], > (second 2 should be memorized, first 2
"     are just like vim)
" p is a Vim-paragraph (block between blank lines)
"EXPANSIONS OF NORMAL dab, daB, etc. for SURROUND syntax
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$vN<Down>0<Esc>:noh<CR>gv"
  "means 'select inner comment'; get stuff between commented out lines
nnoremap dar da[
nnoremap dir di[
nnoremap daa da<
nnoremap dia di<
nnoremap car ca[
nnoremap cir ci[
nnoremap caa ca<
nnoremap cia ci<
nnoremap yar ya[
nnoremap yir yi[
nnoremap yaa ya<
nnoremap yia yi<
nnoremap <silent> var :let b:v_mode='v'<Cr>va[
nnoremap <silent> vir :let b:v_mode='v'<Cr>vi[
nnoremap <silent> vaa :let b:v_mode='v'<Cr>va<
nnoremap <silent> via :let b:v_mode='v'<Cr>vi<
  "simple ones; allow a for carat, [ for bracket

"DELIMITMATE (auto-generate closing delimiters)
"...ok with default behavior now, few remaps
" au BufEnter * let b:delimitMate_quotes = "\" ' $ |"
au BufEnter * let b:delimitMate_quotes = "\" '"
au BufEnter * let b:delimitMate_matchpairs = "(:),{:},[:]"
"_quotes are identical left-right delimiters, and _matchpairs
"are different (but single-char) left-right delimiters... note you
"CANNOT use 'set matchpairs', or plugin breaks! for some reason...
"also, don't use <> because use them as comparison operators too much

"TABULAR - ALIGNING AROUND :,=,ETC.
"aligns around character
"NOTE: e.g. for aligning text after colons, input character :\zs; aligns
"first character after matching preceding character
vnoremap <expr> -t ":Tabularize /".input("Align character: ")."<CR>"
nnoremap <expr> -t ":Tabularize /".input("Align character: ")."<CR>"
  "arbitrary character
vnoremap <expr> -c ":Tabularize /^\\s*\\S.*\\zs".b:NERDCommenterDelims['left']."<CR>"
nnoremap <expr> -c ":Tabularize /^\\s*\\S.*\\zs".b:NERDCommenterDelims['left']."<CR>"
  "by comment character; ^ is start of line, . is any char, .* is any number, \\zs
  "is start match here (must escape backslash), then search for the comment
vnoremap <expr> -C ":Tabularize /^.*\\zs".b:NERDCommenterDelims['left']."<CR>"
nnoremap <expr> -C ":Tabularize /^.*\\zs".b:NERDCommenterDelims['left']."<CR>"
  "by comment character, but instead don't ignore comments on their own line
nnoremap -, :Tabularize /,\zs/l0r2<CR>
vnoremap -, :Tabularize /,\zs/l0r2<CR>
  "suitable for diag_table's in models
vnoremap -= :Tabularize /^[^=]*\zs=<CR>
nnoremap -= :Tabularize /^[^=]*\zs=<CR>
vnoremap -- :Tabularize /^[^=]*\zs=\zs<CR>
nnoremap -- :Tabularize /^[^=]*\zs=\zs<CR>
  "align assignments, and keep equals signs on the left; only first equals sign
vnoremap -d :Tabularize /:\zs<CR>
nnoremap -d :Tabularize /:\zs<CR>
  "align colon table, and keeps colon on the left; the zs means start match **after** colon

"VIM-CONDA
"make it require manual load, but doesn't work
"autocmd FileType python source ~/.vim/ipython_plugin/vim-conda.vimm

"VIM-IPYTHON
"requires manual load, as opposed to others
" autocmd FileType python source ~/.vim/ipython_plugin/ipy.vim

"FTPLUGINS
"Set default tabbing (then plugins will setlocal these)
set tabstop=2
set shiftwidth=2
set softtabstop=2
"Load ftplugin and syntax files
filetype plugin on
syntax on
filetype indent on
"Disable latex spellchecking in comments (works for default syntax file)
let g:tex_comment_nospell=1
"Loads default $VIMRUNTIME syntax highlighting and indent if
"...1) we haven't already loaded an available non-default file using ftplugin or
"...2) there is no alternative file loaded by the ftplugin function

"NCL completion for its weird functions
" set complete-=k complete+=k " Add dictionary search (as per dictionary option)
" au BufRead,BufNewFile *.ncl set dictionary=~/.vim/words/ncl.dic
au FileType * execute 'setlocal dict+=~/.vim/words/'.&filetype.'.dic'

"------------------------------------------------------------------------------
" GENERAL STUFF, BASIC REMAPS
"------------------------------------------------------------------------------
"BUFFER WRITING/SAVING
nnoremap <C-s> :w<CR>
" inoremap <C-s> <Esc>:w<CR>a
au FileType help nnoremap <buffer> <C-s> <Nop>
nnoremap <C-q> :tabclose<CR>
nnoremap <C-a> :qa<CR>
" inoremap <C-q> <Esc>:q<CR>a

"IMPORTANT STUFF
"Tabbing
set expandtab "says to always expand \t to their length in <SPACE>'s!
set autoindent "indents new lines
set backspace=indent,eol,start "backspace by indent - handy
nnoremap <Leader><Tab> :set expandtab!<CR>
"Wrapping
autocmd BufEnter * set textwidth=0 "hate auto-linebreaking, this disables it no matter what ftplugin says
set linebreak "breaks lines only in whitespace... makes wrapping acceptable
set wrapmargin=0 "starts wrapping at the edge; >0 leaves empty bufferzone
set display=lastline "displays as much of wrapped lastline as possible;
"Global behavior
set nostartofline  "when switching buffers, doesn't move to start of line (weird default)
set virtualedit= "prevent cursor from going where no actual character
set notimeout "turn off timeout altogether; like sticky keys!
set timeoutlen=0 "so when timeout is disabled, we do this
" set timeoutlen=1000 "multi-keystroke commands, wait 1000ms before cancelling
"use 1s... gives enough time
set ttimeoutlen=0 "no delay after pressing <Esc>
set lazyredraw "so maps aren't jumpy
set noerrorbells visualbell t_vb=
"set visualbell ENABLES INTERNAL BELL; but t_vb= means nothing is shown on the window
"I think the visualbell (if we have status line enabled) prints what is going wrong below
"Eliminating super-weird behavior of scrolling/mouse click
if has('ttymouse')
  set ttymouse=sgr
endif
"Command-line behavior
set confirm "require confirmation if you try to quit
set wildmenu
set wildmode=longest:list,full
  "tab-completion settings in vim
"Improved wildmenu (command mode file/dir suggestions) behavior
function! s:entersubdir()
  call feedkeys("\<Down>", 't')
  return ''
endfunction
function! s:enterpardir()
  call feedkeys("\<Up>", 't')
  return ''
endfunction
cnoremap <expr> <C-j> <sid>entersubdir()
cnoremap <expr> <C-k> <sid>enterpardir()

"SEARCHING
"Basics; (showmode shows mode at bottom [default I think, but include it],
"incsearch moves to word as you begin searching with '/' or '?')
set hlsearch
set incsearch
  "show match as typed so far, and highlight as you go
"Don't ignore case in completions
set noinfercase
set ignorecase
set smartcase
  "smartcase makes search case insensitive, unless has capital letter
"Set smartcase only when issuing '/' commands
au InsertEnter * set noignorecase
au InsertLeave * set ignorecase
"Exact case */# searching -- use when smartcase and ignorecase are on.
"If ignorecase is off, then this does nothing
"But we decided we like ignorecase for casual '/' searches, just not for
"* searches, / searches, :s searches and in auto-completions (i.e. the popup menu)
"Now I'm also disabling 'backwards search'; not really useful, and not sure what the g* was useful for
nnoremap <silent>  * :let b:position=winsaveview()<CR>:let @/='\C\<' . expand('<cword>') . '\>'<CR>:let v:searchforward=1<CR>nN:call winrestview(b:position)<Cr>
nnoremap <silent>  # :let b:position=winsaveview()<CR>xhp/<C-R>-<CR>N:call winrestview(b:position)<CR>
" nnoremap <silent> g* :let @/='\C'   . expand('<cword>')       <CR>:let v:searchforward=1<CR>nNzz
" nnoremap <silent>  # :let @/='\C\<' . expand('<cword>') . '\>'<CR>:let v:searchforward=0<CR>nNzz
" nnoremap <silent> g# :let @/='\C'   . expand('<cword>')       <CR>:let v:searchforward=0<CR>nNzz
" nnoremap <silent>  * :let @/='\C\<' . expand('<cword>') . '\>'<CR>:let v:searchforward=1<CR>nN
" nnoremap <silent>  # :let @/='\C\<' . expand('<cword>') . '\>'<CR>:let v:searchforward=0<CR>nN
" nnoremap <silent> g* :let @/='\C'   . expand('<cword>')       <CR>:let v:searchforward=1<CR>nN
" nnoremap <silent> g# :let @/='\C'   . expand('<cword>')       <CR>:let v:searchforward=0<CR>nN

"SCOPE SEARCHING AND REPLACE STUFF
" nnoremap <Leader>s :%s/\<<C-r>=expand('<cword>')<CR>\>//gI<Left><Left><Left>
" nnoremap <Leader>s [[V]]k<Esc>:`<,`>s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
  "the above failes, because don't want <cword>, want word before we moved cursor
"Below is Copied from: http://vim.wikia.com/wiki/Search_in_current_function
"TODO: DOESN'T SEEM TO WORK, NEED TO FIX
" " Search within top-level block for word at cursor, or selected text.
" nnoremap <Leader># /<C-R>=<SID>ScopeSearch('[[', 1)<CR><CR>
" vnoremap <Leader># <Esc>/<C-R>=<SID>ScopeSearch('[[', 2)<CR><CR>gV
" " Search within current block for word at cursor, or selected text.
" nnoremap <Leader>* /<C-R>=<SID>ScopeSearch('[{', 1)<CR><CR>
" vnoremap <Leader>* <Esc>/<C-R>=<SID>ScopeSearch('[{', 2)<CR><CR>gV
" " Return a pattern to search within a specified scope, or
" " return a backslash to cancel search if scope not found.
" " navigator: a command to jump to the beginning of the desired scope
" " mode: 0=scope only; 1=scope+current word; 2=scope+visual selection
" function! s:ScopeSearch(navigator, mode)
"   if a:mode == 0
"     let pattern = ''
"   elseif a:mode == 1
"     let pattern = '\<' . expand('<cword>') . '\>'
"   else
"     let old_reg = getreg('@')
"     let old_regtype = getregtype('@')
"     normal! gvy
"     let pattern = escape(@@, '/\.*$^~[')
"     call setreg('@', old_reg, old_regtype)
"   endif
"   let a:saveview = winsaveview()
"   execute 'normal! ' . a:navigator
"   let first = line('.')
"   normal %
"   let last = line('.')
"   normal %
"   call winrestview(a:saveview)
"   if first < last
"     return printf('\%%>%dl\%%<%dl%s', first-1, last+1, pattern)
"   endif
"   return "\b"
" endfunction

"FIND AND REPLACE STUFF
"NOTE JEDI-VIM 'VARIABLE RENAME' IS SKETCHY AND FAILS; SHOULD DO MY OWN
"RENAMING, AND DO IT BY CONFIRMING EVERY SINGLE INSTANCE
"Below is copied from: https://stackoverflow.com/a/597932/4970632
"NOTE: BELOW FAILED, BECAUSE gd 'goto definition where var declared' doesn't work in python often
" nnoremap <Leader>s gd[{V%::s/<C-R>///gc<left><left><left>
" nnoremap <Leader>S gD:%s/<C-R>///gc<left><left><left>
  "first one searches current scope, second one parent-level scope
"Some simple ones I wrote
" nnoremap <Leader>s "ayiw[[V]]kk<Esc>:'<,'>s/\<<C-r>a\>//gIc<Left><Left><Left><Left>
" nnoremap <Leader>s "ayiw[[V]]kk:s/\<<C-r>a\>//gIc<Left><Left><Left><Left>
nmap <Leader>s yiw[[V]]k<Esc>:'<,'>s/\<<C-r>"\>//gIc<Left><Left><Left><Left>
nmap <Leader>S :%s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
  "need recursion, because BUILTIN FTPLUGIN FUNCTIONATLIY remaps [[ and ]]
  "see: https://github.com/vim/vim/blob/master/runtime/ftplugin/python.vim
nnoremap <Leader>/ :.,$s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
nnoremap <Leader>? :0,.s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
  "use 'I' because WANT CASE-SENSITIVE SUBSTITUTIONS, INSENSITIVE SEARCHES
  "use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on
  "blank lines; also the 'c' means 'confirm' each replacement
nnoremap <Leader>& /\<[A-Z]\+\><CR>
  "search all capital words

"INSERT MODE stuff
"Return to normal mode but keep cursor position same
cnoremap <LeftMouse> <C-c><LeftMouse>
  "cancels command-mode with mouse
"Navigation in insert mode (up-down navigation discouraged)
inoremap <C-h> <Left>
inoremap <C-l> <Right>
"Quick text insertion (keeps cursor in same position)
nnoremap <expr> <Leader>I 'i'.input('').'<Esc>'

"VISUAL MODE stuff
"Cursor movement/scrolling while preserving highlights
"...1) create local variables, mark when entering visual mode
nnoremap <silent> v :let b:v_mode='v'<CR>mVv
nnoremap <silent> V :let b:v_mode='V'<CR>mVV
"...2) using the above, let user click around to move selection
vnoremap <expr> <LeftMouse> '<Esc><LeftMouse>mN`V'.b:v_mode.'`N'
"Enter to exit visual mode, much more natural
vnoremap <CR> <Esc>

"CAPS LOCK WITH C-a IN INSERT/COMMAND MODE
"lmap == insert mode, command line (:), and regexp searches (/)
"See <http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock>; instead uses
"iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1 via
"<C-^> (not avilable for custom remap, since ^ is not alphabetical)
set iminsert=0
for c in range(char2nr('A'), char2nr('Z'))
  execute 'lnoremap ' . nr2char(c+32) . ' ' . nr2char(c)
  execute 'lnoremap ' . nr2char(c) . ' ' . nr2char(c+32)
endfor
inoremap <C-z> <C-^>
cnoremap <C-z> <C-^>
  "can't lnoremap the above, because iminsert is turning it on and off
autocmd InsertLeave,CmdwinLeave * set iminsert=0
"the above is confusing, but better than an autocmd that lmaps and lunmaps;
"that would cancel command-line queries (or I'd have to scroll up to resume them)
"don't think any other mapping type has anything like lmap; iminsert is unique

"TAB NAVIGATION
au TabLeave * let g:LastTab = tabpagenr()
"Basic switching, and shortcut for 'last active tab'
noremap <Tab>1 1gt
noremap <Tab>2 2gt
noremap <Tab>3 3gt
noremap <Tab>4 4gt
noremap <Tab>5 5gt
noremap <Tab>6 6gt
noremap <Tab>7 7gt
noremap <Tab>8 8gt
noremap <Tab>9 9gt
noremap <Tab>h gT
noremap <Tab>l gt
noremap <Tab>o :tabe 
noremap <expr> <Tab>O ":argadd ".input('Enter filename or glob pattern: ')."<CR>:tab all<CR>"
  "this is useful, but MUST BE EXECUTED RIGHT AFTER OPENING VIM; other stuff
  "is not in arglist
noremap <silent> <Tab>. :execute "tabn ".g:LastTab<CR>
  "return to previous tab
"FUNCTION -- MOVE CURRENT TAB TO THE EXACT PLACE OF TAB NO. X
"this is not default behavior
function! s:tabmove(n)
  echo 'Moving tab...'
  if a:n==tabpagenr()
    return
  elseif a:n>tabpagenr() && version[0]>7
      "may be version dependent behavior of tabmove... on my version 8 seems to
      "always position to left, but on Gauss server, different
    execute 'tabmove '.a:n
  else
    execute 'tabmove '.eval(a:n-1)
  endif
endfunction
" noremap <silent> <expr> <Tab>m ":tabm ".eval(input('Move tab: ')-1)."<CR>"
noremap <silent> <expr> <Tab>m ":call <sid>tabmove(".eval(input('Move tab: ')).")<CR>"

"WINDOW MANAGEMENT
noremap <Tab>q <C-w>o
" noremap <Tab><Tab>q <C-w>o
  "close all but current window
"splitting -- make :sp and :vsp split to right and bottom
set splitright
set splitbelow
"size-changing remaps
noremap <Tab>J :exe 'resize '.(winheight(0)*3/2)<CR>
noremap <Tab>K :exe 'resize '.(winheight(0)*2/3)<CR>
noremap <Tab>H :exe 'vertical resize '.(winwidth(0)*3/2)<CR>
noremap <Tab>L :exe 'vertical resize '.(winwidth(0)*2/3)<CR>
noremap <Tab>= <C-w>=
" noremap <Tab><Tab>= <C-w>=
  "set all windows to equal size
noremap <Tab>t <C-w>t
  "put current window into tab
noremap <Tab>n <C-w>w
" noremap <Tab><Tab>. <C-w>w
  "next
noremap <Tab>M <C-w>_
  "maximize window
" noremap <Tab><Tab>h <C-w>h
" noremap <Tab><Tab>j <C-w>j
" noremap <Tab><Tab>k <C-w>k
" noremap <Tab><Tab>l <C-w>l
noremap <Tab><Left> <C-w>h
noremap <Tab><Down> <C-w>j
noremap <Tab><Up> <C-w>k
noremap <Tab><Right> <C-w>l
  "selection
nnoremap <Tab>, <C-w><C-p>
  "switch to last window

"COLOR HIGHLIGHTING
"NO LONGER SHOULD LOOK IN THE DEFAULT matchit, BECAUSE NOW DOWNLOAD WITH VIM-PLUG
"Highlight group under cursor
nnoremap <Leader>c :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name")
  \.'> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
  \.synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>
"Syntax highlighting
nnoremap <expr> <Leader>C ":source $VIMRUNTIME/syntax/colortest.vim<CR>"
  \.":setlocal nolist<CR>:setlocal nonumber<CR>:noremap <buffer> q :q\<CR\><CR>"
  "could not get this to work without making the whole thing an <expr>, then escaping the CR in the subsequent map
"Below has been giving me really weird errors but is more accurate
" nnoremap <Leader>5 :source $VIMRUNTIME/syntax/hitest.vim<CR>
" nnoremap <Leader>7 :split $VIMRUNTIME/pack/dist/opt/matchit/plugin/matchit.vim<CR>
" "Get current plugin file
" nnoremap <Leader>8 :execute 'split $VIMRUNTIME/ftplugin/'.&filetype.'.vim'<CR>
" "Get scriptnames
" nnoremap <Leader>4 :scriptnames<CR>

"LINE NUMBERING / NUMBERS IN TEXT
"Numbering
set number
set norelativenumber
"Basic maps
noremap <Leader>1 :setlocal number!<CR>
noremap <Leader>2 :setlocal relativenumber!<CR>
  "PREVIOUSLY had some NumberToggle algorithm; not necessary I think
"Incrementing numbers (C-x, C-a originally)
nnoremap <Leader>0 <C-x>
nnoremap <Leader>9 <C-a>h
  "for some reasons <C-a> by itself moves cursor to right; have to adjust

"ROW/LINE MANIPULATION
"Unjoin lines/cut at cursor
" nnoremap <Leader>o mAA<CR><Esc>`A
" nnoremap <Leader>O mA<Up>A<CR><Esc>`A
nnoremap <Leader>o mAo<Esc>`A
nnoremap <Leader>O mAO<Esc>`A
nnoremap <Leader>i i<CR><Esc>k$
"Better join behavior -- before 2J joined this line and next, now it
"means 'join the two lines below'; more intuitive. uses if statement
"in <expr> remap, and v:count the user input count
nnoremap <expr> J v:count > 1 ? 'JJ' : 'J'
"Yank, substitute, delete until end of current line
nnoremap Y y$
nnoremap D D
nnoremap S c$
  "same behavior; NOTE use 'cc' instead to substitute whole line

"COPY/PASTING CLIPBOARD
"Pastemode for pasting from clipboard; so no weird indents
"also still want to be able to insert LITERAL CHACTERS with C-v
"...first, declare it
"...and that's ALL WE WILL DO; had resorted before to this complicated stuff
"just so we could simultaneously toggle pasting with c-v and still use c-v
"for literal characters; just plain dumb
augroup Paste
  autocmd!
  au InsertEnter * set pastetoggle=<C-v> "need to use this, because mappings don't work
      "when pastemode is toggled; might be able to remap <set paste>, but cannot return
      "to <set nopaste>
  au InsertLeave * set pastetoggle=
  au InsertLeave * set nopaste "if pastemode was toggled, turn off
augroup END
" "...next initialize
" set pastetoggle=<C-p>
" let g:paste=1
" "...and set up toggle
" function! s:pastetoggle()
"   if g:paste==1
"     let g:paste=0
"     set pastetoggle=
"     echom 'Pasting disabled.'
"   else
"     let g:paste=1
"     set pastetoggle=<C-v>
"     echom 'Pasting enabled.'
"   endif
" endfunction
" nnoremap <C-p> :call <sid>pastetoggle()<CR>
" inoremap <C-p> <C-o>:call <sid>pastetoggle()<CR>
"Copymode to eliminate special chars during copy
function! s:copytoggle()
  if exists("b:prevlist") && exists("b:prevnum") && exists("b:prevrelnum") && exists("b:prevscrolloff")
      "then we disabled all the 'extra' terminal characters, and want
      "to restore previous settings
    if b:prevlist != &list
      setlocal list!
    endif
    if b:prevnum != &number
      setlocal number!
    endif
    if b:prevrelnum != &relativenumber
      setlocal relativenumber!
    endif
    if b:prevscrolloff != &scrolloff
      execute 'setlocal scrolloff='.b:prevscrolloff
    endif
    unlet b:prevnum
    unlet b:prevlist
    unlet b:prevrelnum
    unlet b:prevscrolloff
    echo "Copy mode enabled."
  else
    let b:prevlist = &list
    let b:prevnum = &number
    let b:prevrelnum = &relativenumber
    let b:prevscrolloff = &scrolloff
    setlocal nolist
    setlocal nonumber
    setlocal norelativenumber
    setlocal scrolloff=0
      "need this too, because if relativenumber can be on with number off
      "(with current line marked '0') endif
    echo "Copy mode disabled."
  endif
endfunction
nnoremap <C-c> :call <sid>copytoggle()<CR>
  "yank because from Vim, we yank; but remember, c-v is still pastemode

"FOLDING STUFF
"Basic settings
set foldmethod=indent
  "options syntax, indent, manual (e.g. entering zf), marker
set foldnestmax=10
  "avoids weird things
set nofoldenable
  "disable/open all folds; do this by default when opening file
  "NOTE foldenable turned back on whenever you want to show the folds
set foldlevel=2
  "by default only 2nd-level folds are collapsed
"Delete folding
nnoremap zD zd
  "'delete fold at cursor'
"Changing fold level (increase, reduce)
nnoremap <Leader>] zm
nnoremap <Leader>[ zr
"Folding toggle
nnoremap <Leader>F :setlocal foldenable!<CR>
nnoremap <Leader>f zf

"HIGHLIGHTING/SPECIAL CHARACTER MANAGEMENT
"highlight toggle
noremap <Leader>n :noh<CR>
  "o for 'highlight off'
"show whitespace chars, newlines, and define characters used
set list
nnoremap <Leader>l :setlocal list!<CR>
set listchars=tab:▸\ ,eol:↘,trail:·
" set listchars=tab:▸\ ,eol:↘,trail:·
"other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
"browse Unicode tables for more

"SPECIAL SYNTAX HIGHLIGHTING OVERWRITE (all languages; must come after filetype stuff)
"Special characters
highlight NonText ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE
"Matching parentheses
highlight Todo ctermfg=None ctermbg=Red
highlight MatchParen ctermfg=Yellow ctermbg=Blue
"Cursor line or column highlighting using color mapping set by CTerm (PuTTY lets me set
  "background to darker gray, bold background to black, 'ANSI black' to a slightly lighter
  "gray, and 'ANSI black bold' to black).
set cursorline
highlight CursorLine cterm=None ctermbg=Black
highlight CursorLineNR cterm=bold ctermfg=Yellow ctermbg=Black
highlight LineNR cterm=bold ctermfg=Black ctermbg=NONE
"Column stuff; color 80th column, and after 120
highlight ColorColumn cterm=None ctermbg=Black
highlight SignColumn cterm=None ctermbg=Black
"sign define hold text=\
"sign place 1 name=hold line=1

"END THE MYSTERIOUS HIGHLIGHTING WHENEVER .VIMRC IS RUN
noh "run this at startup

"------------------------------------------------------------------------------
"SEND MESSAGE
"------------------------------------------------------------------------------
"silent! !echo 'Custom vimrc loaded.'
echo 'Custom vimrc loaded.'
