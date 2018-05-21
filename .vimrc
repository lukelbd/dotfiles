".vimrc
"###############################################################################
" MOST IMPORTANT STUFF
" NOTE VIM SHOULD BE brew install'd WITHOUT YOUR ANACONDA TOOLS IN THE PATH; USE
" PATH="<original locations>" brew install ... AND EVERYTHING WORKS
" NOTE when you're creating a remap, `<CR>` is like literally pressing the Enter key,
" `\<CR>` is when you want to return a string whose result is like literally pressing
" the enter key e.g. in an <expr>, and `\<CR\>` is always a literal string containing `<CR>`.
"###############################################################################
"BUTT-TONS OF CHANGES
augroup SECTION1 "a comment
augroup END
"###############################################################################
"NOCOMPATIBLE -- changes other stuff, so must be first
set nocompatible
  "always use the vim default where vi and vim differ; for example, if you
  "put this too late, whichwrap will be resset
"###############################################################################
"LEADER -- most important line
let mapleader = "\<Space>"
noremap <Space> <Nop>
noremap <CR> <Nop>
"###############################################################################
"STANDARDIZE COLORS -- need to make sure background set to dark, and should be good to go
"See solution: https://unix.stackexchange.com/a/414395/112647
set background=dark
"###############################################################################
"NO MORE SWAP FILES
"THIS IS DANGEROUS BUT I AM CONSTANTLY HITTING <CTRL-S> SO IS USUALLY FINE
set nobackup
set noswapfile
set noundofile
"###############################################################################
"TAB COMPLETION OPENING NEW FILES
set wildignore=
set wildignore+=*.pdf,*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.o,*.mod
set wildignore+=*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4
set wildignore+=*.dmg,*.zip,*.sw[a-z],*.tmp,*.nc,*.DS_Store
  "never want to open these in VIM; includes GUI-only filetypes
  "and machine-compiled source code (.o and .mod for fortran, .pyc for python)
"###############################################################################
"ESCAPE REPAIR WHEN ENABLING H/L TO CHANGE LINE NUMBER
"First some functions and autocmds
set whichwrap=[,],<,>,h,l
  "let h, l move past end of line (<> = left/right insert, [] = left/right normal mode)
function! s:escape() "preserve cursor column, UNLESS we were on the newline/final char
  if col('.')+1!=col('$') && col('.')!=1
    normal l
  endif
endfunction
augroup EscapeFix
  autocmd!
  autocmd InsertLeave * call s:escape() "fixes cursor position
  "this will work every time leave insert mode so eliminates need to call
  "the function explicitly in commands that bounce from insert to normal mode
augroup END
"###############################################################################
"MOUSE SETTINGS
set mouse=a "mouse clicks and scroll wheel allowed in insert mode via escape sequences; these
if has('ttymouse') | set ttymouse=sgr | else | set ttymouse=xterm2 | endif
 "fail if you have an insert-mode remap of Esc; see: https://vi.stackexchange.com/q/15072/8084
"###############################################################################
"INSERT MODE REMAPS
"SIMPLE ONES
inoremap <C-l> <Esc>$a
inoremap <C-h> <Esc>^i
inoremap <C-p> <C-r>"
" inoremap CC <Esc>C
" inoremap II <Esc>I
" inoremap AA <Esc>A
" inoremap OO <Esc>O
" inoremap SS <Esc>S
" inoremap DD <Esc>dd
" inoremap UU <Esc>u
"FUNCTION FOR ESCAPING CURRENT DELIMITER
" * Use my own instead of delimitmate defaults because e.g. <c-g>g only works
"   if no text between delimiters.
function! s:outofdelim(n) "get us out of delimiter cursos is inside
  for a:i in range(a:n)
    let a:pcol=col('.')
    let a:pline=line('.')
    keepjumps normal! %
    if a:pcol!=col('.') || a:pline!=line('.')
      keepjumps normal! %
    endif "only do the above if % moved the cursor
    if a:i+1!=a:n && col('.')+1!=col('$')
      normal! l
    endif
  endfor
endfunction
"MAPS IN CONTEXT OF POPUP MENU
au BufEnter * let b:tabcount=0
au InsertEnter * let b:tabcount=0
function! s:tabincrease() "use this inside <expr> remaps
  let b:tabcount+=1
  return "" "returns empty string so can be used inside <expr>
endfunction
function! s:tabdecrease() "use this inside <expr> remaps
  let b:tabcount-=1
  return "" "returns empty string so can be used inside <expr>
endfunction
function! s:tabreset() "use this inside <expr> remaps
  let b:tabcount=0
  return "" "returns empty string so can be used inside <expr>
endfunction
"Commands that when pressed expand to the default complete menu options:
"Want to prevent automatic use of CR for confirming entry
inoremap <expr> jk pumvisible() ? b:tabcount==0 ? "\<C-e>\<Esc>:call <sid>outofdelim(1)\<CR>a" :
      \ "\<C-y>\<Esc>:call <sid>outofdelim(1)\<CR>a" : "\<Esc>:call <sid>outofdelim(1)\<CR>a"
inoremap <expr> JK pumvisible() ? b:tabcount==0 ? "\<C-e>\<Esc>:call <sid>outofdelim(10)\<CR>a" :
      \ "\<C-y>\<Esc>:call <sid>outofdelim(10)\<CR>a" : "\<Esc>:call <sid>outofdelim(10)\<CR>a"
inoremap <expr> <C-u> neocomplete#undo_completion()
inoremap <expr> <C-c> pumvisible() ? "\<C-e>\<Esc>" : "\<Esc>"
inoremap <expr> <Space> pumvisible() ? "\<Space>".<sid>tabreset() : "\<Space>"
inoremap <expr> <CR> pumvisible() ? b:tabcount==0 ? "\<C-e>\<CR>" : "\<C-y>".<sid>tabreset() : "\<CR>"
inoremap <expr> <BS> pumvisible() ? "\<C-e>\<BS>".<sid>tabreset() : "\<BS>"
inoremap <expr> <Tab> pumvisible() ? <sid>tabincrease()."\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? <sid>tabdecrease()."\<C-p>" : "\<BS>"
inoremap <expr> <ScrollWheelDown> pumvisible() ? <sid>tabincrease()."\<C-n>" : "\<ScrollWheelDown>"
inoremap <expr> <ScrollWheelUp> pumvisible() ? <sid>tabdecrease()."\<C-p>" : "\<ScrollWheelUp>"
inoremap <expr> <CR> pumvisible() ? b:tabcount==0 ? "\<C-e>\<CR>" : "\<C-y>".<sid>tabreset() : "\<CR>"
" inoremap <expr> <Space> pumvisible() ? "\<C-e>\<Space>" : "\<Space>"
" inoremap <expr> <CR> pumvisible() ? "\<C-e>\<CR>" : "\<CR>"
" inoremap <expr> <BS> pumvisible() ? "\<C-e>\<BS>" : "\<BS>"
" inoremap <expr> kj pumvisible() ? "\<C-y>" : "kj"
" inoremap <expr> <C-j> pumvisible() ? "\<Down>" : ""
" inoremap <expr> <C-k> pumvisible() ? "\<Up>" : ""
"###############################################################################
"DISABLE ANNOYING SPECIAL MODES/DANGEROUS ACTIONS
noremap K <Nop>
noremap Q <Nop>
  "the above 2 enter weird modes I don't understand...
noremap <C-z> <Nop>
noremap Z <Nop>
  "disable c-z and Z for exiting vim
set slm=
  "disable 'select mode' slm, allow only visual mode for that stuff
"###############################################################################
"CHANGE COMMAND-LINE WINDOW SETTINGS i.e. q: q/ and q? mode
function! s:commandline_check()
  nnoremap <buffer> <silent> q :q<CR>
  setlocal nonumber
  setlocal nolist
  setlocal laststatus=0 "turns off statusline
endfunction
au CmdwinEnter * call s:commandline_check()
au CmdwinLeave * setlocal laststatus=2
  "commandline-window settings; when we are inside of q:, q/, and q?
"###############################################################################
"CHANGE/ADD PROPERTIES/SHORTCUTS OF VERY COMMON ACTIONS
" noremap q <Nop>
  "to prevent accidentally starting recordings
  "thought this would require the <nowait> but it doesn't; see https://stackoverflow.com/a/28501574/4970632
" noremap ~ q1
" noremap qq qQ
  "new macro toggle; almost always just use one at a time
  "press ~ again to quit; 1, 2, etc. do nothing in normal mode. clever, huh?
  "don't diable q; have that remapped to show window
" noremap `` @@
" noremap , @1
" noremap ` <Nop>
noremap <silent> ` mzo<Esc>`z
noremap <silent> ~ mzo<Esc>`z
  "these keys aren't used currently, and are in a really good spot,
  "so why not? fits mnemonically that insert above is Shift+<key for insert below>
noremap " :echo "Setting mark q."<CR>mq
noremap ' `q
map @ <Nop>
noremap , @q
  "new macro useage; almost always just use one at a time
  "also easy to remembers; dot is 'repeat last command', comma is 'repeat last macro'
nnoremap <C-r> :redraw<CR>
  "refresh screen; because C-r has a better pneumonic, and I map <C-r> to U for REDO
nnoremap U <C-r>
  "redo map to capital U; means we cannot 'undo line', but who cares
nnoremap \ :echo "Enabling throwaway register."<CR>"_
vnoremap \ <Esc>:echo "Enabling throwaway register." <BAR> sleep 200m<CR>gv"_
nnoremap <expr> \| has("clipboard") ? ':echo "Enabling system clipboard."<CR>"*' : ':echo "VIM not compiled with +clipboard."<CR>'
vnoremap <expr> \| has("clipboard") ? '<Esc>:echo "Enabling system clipboard." <BAR> sleep 200m<CR>gv"*' : ':echo "VIM not compiled with +clipboard."<CR>'
  "use BACKSLASH FOR REGISTER KEY (easier to access) and use it to just ACTIVATE
  "THE THROWAWAY REGISTER; THAT IS THE ONLY WAY I USE REGISTERS ANYWAY
nnoremap x "_x
nnoremap X "_X
  "don't save single-character deletions to any register
vnoremap p "_dP
vnoremap P "_dP
  "default behavior replaces selection with register after p, but puts
  "deleted text in register; correct this behavior
nnoremap o ox<BS>
nnoremap O Ox<BS>
  "pressing enter on empty line preserves leading whitespace (HACKY)
  "works because Vim doesn't remove spaces when text has been inserted
nnoremap A g$a
nnoremap I g^i
  "same for entering insert mode
noremap H g^
noremap L g$ge
  "shortcuts for 'go to first char' and 'go to eol'
  "works in both line-wrapped situations and unwrapped situations
noremap m ge
noremap M gE
  "navigate by words
"Basic wrap-mode navigation, always move visually
"Still might occasionally want to navigate by lines though
noremap k gk
noremap j gj
" noremap  <Up>    <Nop>
" noremap  <Down>  <Nop>
" noremap  <Home>  <Nop>
" noremap  <End>   <Nop>
" inoremap <Up>    <Nop>
" inoremap <Down>  <Nop>
" inoremap <Home>  <Nop>
" inoremap <End>   <Nop>
" inoremap <Left>  <Nop>
" inoremap <Right> <Nop>
  "consider disabling arrow keys
" noremap <Right> ;
" noremap <Left> ,
"   "or new use for them; this way can still use f,t repitition
"Better join behavior -- before 2J joined this line and next, now it
"means 'join the two lines below'; more intuitive. uses if statement
"in <expr> remap, and v:count the user input count
nnoremap <expr> J v:count > 1 ? 'JJ' : 'J'
nnoremap <expr> K v:count > 1 ? 'JdwJdw' : 'Jdw'
  "also remap K because not yet used; like J but adds no space
  "note gJ was insufficient because retains leading whitespace from next line
  "recall that the 'v' prefix indicated a VIM read-only builtin variable
nnoremap Y y$
nnoremap v$ v$h
nnoremap D D
  "yank, substitute, delete until end of current line
  "also make v$ no longer include the end-of-line character
noremap S <Nop>
noremap ss s
  "will use single-s map for spellcheck-related commands
  "restore use of substitute 's' key; then use s<stuff> for spellcheck
nnoremap vv ^v$gE
vnoremap cc s
vnoremap c<CR> s
  "select the current 'line' of text; super handy
  "also replace the currently highlighted text
" inoremap (<CR> (<CR>)<Esc>ko
" inoremap {<CR> {<CR>}<Esc>ko
" inoremap ({<CR> ({<CR>});<Esc>ko
  "**nead idea for insert mode remap**; put closing braces on next line
  "adapted from: https://blog.nickpierson.name/colemak-vim/
nnoremap <C-c> <Nop>
nnoremap <Delete> <Nop>
nnoremap <Backspace> <Nop>
  "turns off common things in normal mode
  "also prevent Ctrl+c rining the bell
"###############################################################################
"VISUAL MODE BEHAVIOR
"Cursor movement/scrolling while preserving highlights
"Needed command-line ways to enter visual mode; see answer: https://vi.stackexchange.com/a/3701/8084
"Why do this? Because had trouble storing <C-v> as variable, then issuing it as command
command! Visual      normal! v
command! VisualLine  normal! V
command! VisualBlock execute "normal! \<C-v>"
"1) create local variables, mark when entering visual mode
" nnoremap <silent> v :let b:v_mode='v'<CR>:setlocal mouse+=v<CR>mVv
" nnoremap <silent> V :let b:v_mode='V'<CR>:setlocal mouse+=v<CR>mVV
nnoremap <silent> v :let b:v_mode='Visual'<CR>mVv
nnoremap <silent> V :let b:v_mode='VisualLine'<CR>mVV
nnoremap <silent> <C-v> :let b:v_mode='VisualBlock'<CR>mV<C-v>
"2) using the above, let user click around to move selection
" vnoremap <expr> <LeftMouse> '<Esc><LeftMouse>mN`V'.b:v_mode.'`N'
vnoremap <expr> <LeftMouse> '<Esc><LeftMouse>mN`V:'.b:v_mode.'<CR>`N'
vnoremap <CR> <Esc>
"###############################################################################
"HIGHLIGHTING/SPECIAL CHARACTER MANAGEMENT
"highlight toggle
noremap <Leader>n :noh<CR>
  "o for 'highlight off'
"show whitespace chars, newlines, and define characters used
nnoremap <Leader>l :setlocal list!<CR>
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·
" set listchars=tab:▸\ ,eol:↘,trail:·
"other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
"browse Unicode tables for more
"###############################################################################
"LINE NUMBERING / NUMBERS IN TEXT
"Numbering
set number norelativenumber
set numberwidth=5
  "by default, make wide enough for single space plus 4-digit numbers
  "eliminates annoying effect when editing file and it goes over 1000 lines
"Basic maps
set relativenumber
noremap <Leader>1 :setlocal number!<CR>
noremap <Leader>2 :setlocal relativenumber!<CR>
"Re-enable Vi-compatible options; actually forget this, made traversing lines werid
" set cpoptions+=n
  "now continuation lines run into number column; easier to verify at a glance whether a zero-column
  "character is actually the start of the line, or just a line continuation
"Incrementing numbers (C-x, C-a originally)
nnoremap <Leader>0 <C-x>
nnoremap <Leader>9 <C-a>h
  "for some reasons <C-a> by itself moves cursor to right; have to adjust
"###############################################################################
"DIFFERENT CURSOR SHAPE DIFFERENT MODES; works for everything (Terminal, iTerm2, tmux)
" Summary found here: http://vim.wikia.com/wiki/Change_cursor_shape_in_different_modes
" Also according to this, don't need iTerm-specific Cursorshape stuff: https://stackoverflow.com/a/44473667/4970632
" The TMUX stuff just wraps everything in \<Esc>Ptmux;\<Esc> CONTENT \<Esc>\\
" Also see this for more compact TMUX stuff: https://vi.stackexchange.com/a/14203/8084
if exists("&t_SI")
  if exists('$TMUX')
    let &t_SI = "\ePtmux;\e\e[6 q\e\\"
  else
    let &t_SI = "\e[6 q"
  endif
endif
if exists("&t_SR")
  if exists('$TMUX')
    let &t_SR = "\ePtmux;\e\e[4 q\e\\"
  else
    let &t_SR = "\e[4 q"
  endif
endif
if exists("&t_EI")
  if exists('$TMUX')
    let &t_EI = "\ePtmux;\e\e[2 q\e\\"
  else
    let &t_EI = "\e[2 q"
  endif
endif

"###############################################################################
"###############################################################################
" COMPLICATED FUNCTIONS, MAPPINGS, FILETYPE MAPPINGS
"###############################################################################
"###############################################################################
augroup SECTION2
augroup END
let g:has_nowait=(v:version>703 || v:version==703 && has("patch1261"))
let g:compatible_neocomplete=has("lua") "try alternative completion library
let g:compatible_tagbar=((v:version>703 || v:version==703 && has("patch1058")) && 
      \ str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))) "need str2num
"WEIRD FIX
"see: https://github.com/kien/ctrlp.vim/issues/566
" set shell=/bin/bash "will not work with e.g. brew-installed shell
"VIM-PLUG PLUGINS
augroup plug
augroup END
call plug#begin('~/.vim/plugged')
"Appearence; use my own customzied statusline/tagbar stuff though, and it's way better
" Plug 'vim-airline/vim-airline'
" Plug 'itchyny/lightline.vim'
"Python wrappers
" if g:compatible_neocomplete | Plug 'davidhalter/jedi-vim' | endif "these need special support
" Plug 'cjrh/vim-conda' "for changing anconda VIRTUALENV; probably don't need it
" Plug 'hdima/python-syntax' "this failed for me; had to manually add syntax file
" Plug 'klen/python-mode' "incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython' "same problem as python-mode
"Julia support and syntax highlighting
Plug 'tpope/vim-repeat'
  "make mappings repeatable
Plug 'JuliaEditorSupport/julia-vim'
"Folding and matching
if g:has_nowait | Plug 'tmhedberg/SimpylFold' | endif
Plug 'Konfekt/FastFold'
" Plug 'vim-scripts/matchit.zip'
"Navigating between files and inside file; enhancedjumps seemed broken to me
Plug 'scrooloose/nerdtree'
if g:compatible_tagbar | Plug 'majutsushi/tagbar' | endif
" Plug 'jistr/vim-nerdtree-tabs'
" Plug 'ctrlpvim/ctrlp.vim'
" Plug 'vim-scripts/EnhancedJumps'
"Commenting and syntax checking
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
"Sessions and swap files
"Mapped in my .bashrc vims to vim -S .session.vim and exiting vim saves the session there
Plug 'tpope/vim-obsession'
Plug 'gioele/vim-autoswap' "deals with swap files automatically
"Git wrapper
" Plug 'tpope/vim-fugitive'
"Completion engines
" Plug 'lifepillar/vim-mucomplete' "broken
" Plug 'Valloric/YouCompleteMe' "broken
" Plug 'ajh17/VimCompletesMe' "no auto-popup feature
" if g:compatible_neocomplete | Plug 'ervandew/supertab' | endif
if g:compatible_neocomplete | Plug 'shougo/neocomplete.vim' | endif
"Simple stuff for enhancing delimiter management
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'
Plug 'godlygeek/tabular'
"Calculators and number stuff
Plug 'triglav/vim-visual-increment' "visual incrementing/decrementing
" Plug 'vim-scripts/Toggle' "toggling stuff on/off; modified this myself
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
Plug 'metakirby5/codi.vim' "CODI appears to be broken, tried with other plugins disabled
call plug#end() "the plug#end also declares filetype syntax and indent on

"###############################################################################
"JUMPS
augroup jumps
augroup END
"VIM documentation says a "jump" is one of the following commands:
"The G ? and n commands will be especially useful to jump back from
" "'", "`", "G", "/", "?", "n",
" "N", "%", "(", ")", "[[", "]]", "{", "}", ":s", ":tag", "L", "M", "H" and
"First some simple maps for navigating jumplist
"The l/h navigate jumplist (e.g. undoing an 'n' or 'N' keystroke), the j/k just
"navigate the changelist (i.e. where text last modified)
noremap <C-l> <Tab>
noremap <C-h> <C-o>
noremap <C-j> g;
noremap <C-k> g,
if has_key(g:plugs, "EnhancedJumps")
  map <C-o> g<C-o>
  map <C-i> g<C-i>
endif

"###############################################################################
"SESSION MANAGEMENT
augroup session
augroup END
"Remember file position, so come back after opening to same spot
autocmd BufReadPost *
   \ if line("'\"") > 0 && line("'\"") <= line("$") |
   \   exe "normal! g`\"" |
   \ endif
"Restore sessions
if has_key(g:plugs, "vim-obsession")
  " nnoremap <leader>S :ToggleWorkspace<CR>
  " let g:workspace_session_name = '.session.vim'
  autocmd VimEnter * Obsession .session.vim
endif

"###############################################################################
"AIRLINE
"* Decided this plugin was done and wrote my own pretty tabline/statusline plugins
"* I don't like having everything look the exact same between server; just want to use the
"  terminal colorscheme and let colors do their thing
"* Good lightline styles: nord, PaperColor and PaperColor_dark (fave), OldHope,
"  jellybeans, and Tomorrow_Night, Tomorrow_Night_Eighties
if has_key(g:plugs, "vim-airline")
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#tabline#formatter = 'default'
endif
if has_key(g:plugs, "lightline.vim")
  let g:lightline = { 'colorscheme': 'powerline' }
endif

"###############################################################################
"DELIMITMATE (auto-generate closing delimiters)
augroup delimitmate
augroup END
"Re-declare and overwrite an important remap
"Actually works without this line; perhaps delimitmate detects existing
"remaps and refused to overwrite them
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
"Set up delimiter paris; delimitMate uses these by default
"Can set global defaults along with buffer-specific alternatives
if has_key(g:plugs, "delimitmate")
  let g:delimitMate_quotes="\" '"
  let g:delimitMate_matchpairs="(:),{:},[:]"
    "if this unset looks for VIM &matchpairs variable; generally should be the
    "same but we just want to make sure
  au FileType vim,html,markdown let b:delimitMate_matchpairs="(:),{:},[:],<:>"
    "override for formats that use carats
  au FileType markdown let b:delimitMate_quotes = "\" ' $ `"
    "markdown need backticks for code, and can maybe do LaTeX
  au FileType tex let b:delimitMate_quotes = "$ |"
  au FileType tex let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
    "tex need | for verbatim environments
  "are different (but single-char) left-right delimiters... note you
  "CANNOT use 'set matchpairs', or plugin breaks! for some reason...
  "also, don't use <> because use them as comparison operators too much
endif

"###############################################################################
"SURROUND (place delimiters around stuff)
"I used this function as inspiration for my ;-style mappings
"For example, instead of ysiwb (ys=command prefix, iw=movement, b=delimit specifier)
"we just call ;b -- easy peasy!
augroup surround
augroup END
" See documentation in ~/.vim/doc for details, but the gist is:
" cs<delim><newdelim> to e.g. change surrounding { into (
" ds<delim> to e.g. delete the surrounding {
" ys<movement/inner something/block indicator><newdelim> to e.g. add quotes
"     around word iw, add parentheses between cursor and W movement, etc.
" yss is special case (should be memorized; ys"special"); performs for entire
"     line, ignoring leading/trailing whitespace
" yS<movement><newdelim> puts text on line of its own, and auto-indents
"     according to indent settings
" S<newdelim>, VISUAL MODE remap to place surroundings
"     if your <newdelim> is something like <a>, then by default the first one
"     will be <a> and the closing one </a>, for HTML useage
" t,< will generically refer to ANY HTML-environment
" ], [ are different; the first adds no space, the second *does* add space
" b, B, r, a correspond to ), }, ], > (second 2 should be memorized, first 2
"     are just like vim)
" p is a Vim-paragraph (block between blank lines)
"Alias the ds[, ds(, etc. behavior for new keys
"Function simply matches these builtin VIM methods with a new delimiter-identifier
function! s:surround(original,new)
  exe 'nnoremap da'.a:original.' da'.a:new
  exe 'nnoremap di'.a:original.' di'.a:new
  exe 'nnoremap ca'.a:original.' ca'.a:new
  exe 'nnoremap ci'.a:original.' ci'.a:new
  exe 'nnoremap ya'.a:original.' ya'.a:new
  exe 'nnoremap yi'.a:original.' yi'.a:new
  exe 'nnoremap <silent> va'.a:original.' :let b:v_mode="v"<CR>va'.a:new
  exe 'nnoremap <silent> vi'.a:original.' :let b:v_mode="v"<CR>vi'.a:new
endfunction
for s in ["r[", "a<"]
  call s:surround(s[0], s[1]) "most simple ones
endfor
"Quick function selection for stuff formatted like function(text)
"For functions the select/delete 'inner' stuff is already satisfied
nnoremap daf mzF(bdt(lda(`z
nnoremap dsf mzF(bdt(xf)x`z
nnoremap caf F(bdt(lca(
nnoremap <expr> csf 'mzF(bct('.input('Enter new function name: ').'<Esc>`z'
nnoremap yaf mzF(bvf(%y`z
nnoremap <silent> vaf F(bvf(%
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$vN<Down>0<Esc>:noh<CR>gv"
  "for selecting text in-between commented out lines
"Mimick the ysiwb command (i.e. adding delimiters to current word) for new delimiters
"The following functions create arbitrary delimtier maps; current convention is
"to prefix with ';' and ','; see below for details
function! s:delims(map,left,right,bmap,WORD)
  if a:bmap | let a:buffer=" <buffer> " | else | let a:buffer="" | endif
  if a:right =~ "|" | let a:offset=1 | else | let a:offset=0 | endif
    "need special consideration when doing | maps, but not sure why
  if !has_key(g:plugs, "vim-surround") "fancy repeatable maps
    "Simple map, but repitition will fail
    exe 'nnoremap '.a:buffer.' '.a:map.' mzlbi'.a:left.'<Esc>hea'.a:right.'<Esc>`z'
  else
    "Note that <silent> works, but putting :silent! before call to repeat does not, weirdly
    "The <Plug> maps are each named <Plug>(prefix)(key), for example <Plug>;b for normal mode bracket map
    "* Warning: it seems (the) movements within this remap can trigger MatchParen action,
    "  due to its CursorMovedI autocmd perhaps.
    "* Added eventignore manipulation because it makes things considerably faster
    "  especially when matchit regexes try to highlight unmatched braces. Considered
    "  changing :noautocmd but that can't be done for a remap; see :help <mod>
    "* For repeat.vim useage with <Plug> named plugin syntax, see: http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
    "  Here's a simpler example:
    "    nnoremap <Plug>deletehl :s/<C-r>//<CR>:call repeat#set("\<Plug>deletehl",v:count)<CR>
    "    nmap d/ <Plug>deletehl
    exe 'nnoremap <silent> '.a:buffer.' <Plug>n'.a:map.' :setlocal eventignore=CursorMoved,CursorMovedI<CR>'
      \.'mzlbi'.a:left.'<Esc>hea'.a:right.'<Esc>`z:call repeat#set("\<Plug>n'.a:map.'",v:count)<CR>:setlocal eventignore=<CR>'
    exe 'nmap '.a:map.' <Plug>n'.a:map
  endif
  exe 'vnoremap <silent> '.a:buffer.' '.a:map.' <Esc>:setlocal eventignore=CursorMoved,CursorMovedI<CR>'
    \.'`>a'.a:right.'<Esc>`<i'.a:left.'<Esc>'.repeat('<Left>',len(a:left)-1-a:offset).':setlocal eventignore=<CR>'
  exe 'inoremap '.a:buffer.' '.a:map.' '.a:left.a:right.repeat('<Left>',len(a:right)-a:offset)
endfunction
function! s:delimscr(map,left,right)
  exe 'inoremap <silent> <buffer> ,'.a:map.' '.a:left.'<CR>'.a:right.'<Up><End><CR>'
  exe 'vnoremap <silent> <buffer> ,'.a:map.' <Esc>`>a<CR>'.a:right.'<Esc>`<i'.a:left.'<CR><Esc><Up><End>'.repeat('<Left>',len(a:left)-1)
    "don't gotta worry about repeat command here, because cannot do that in visual
    "or insert mode; doesn't make sense anyway because we rarely have to do something like
    "100 times in insert mode/visual mode repeatedly, but often have to do so in normal mode
endfunction
"More advanced 'delimiters' and aliases for creating delimiters
"Arguments are as follows:
"1. Shortcut key
"2. Left-hand delimiter
"3. Right-hand delimiter
"4. Whether the map is buffer-local
"5. Whether the normal-mode map is for WORD instead of word
"   In this last case, only the normal-mode map is defined.
call s:delims(';p', 'print(', ')', 0, 0)
call s:delims(';P', 'print(', ')', 0, 0)
call s:delims(';b', '(', ')', 0, 0)
call s:delims(';c', '{', '}', 0, 0)
call s:delims(';r', '[', ']', 0, 0)
call s:delims(';a', '<', '>', 0, 0)
call s:delims(";'", "'", "'", 0, 0)
call s:delims(';"', '"', '"', 0, 0)
call s:delims(';$', '$', '$', 0, 0)
call s:delims(';*', '*', '*', 0, 0)
call s:delims(';`', '`', '`', 0, 0)
call s:delims(';~', '“', '”', 0, 0)
nnoremap ;f lbmzi(<Esc>hea)<Esc>`zi
  "special function that inserts brackets, then
  "puts your cursor in insert mode at the start so you can make a function call
nnoremap ;F lBmzi(<Esc>hEa)<Esc>`zi
  "specual function that inserts brackets, then
  "puts your cursor in insert mode at the start so you can make a function call
"Capitalization stuff in familiar syntax
nnoremap ;u guiw
vnoremap ;u gu
nnoremap ;U gUiw
vnoremap ;U gU
nnoremap ;; ~h
  "not currently used in normal mode, and fits better mnemonically
  "move to right preserves original cursor location
"Repair semicolon in insert mode
inoremap ;; ;

"###############################################################################
"LATEX MACROS, lots of insert-mode stuff
"Idea stemmed from the above: make shortcuts to ys<stuff> with fewer keystrokes
"Anyway the original pneumonic for surround.vim "ys" kind of sucks
augroup latex
augroup END
"Cannot use C-m or C-i, as the former produces an Enter and
"the latter... does something else weird, adds a space
function! s:texmacros()
  "Convenience, in context of other shortcuts
  inoremap <buffer> .<Space> .<Space>
  inoremap <buffer> ,<Space> ,<Space>
  inoremap <buffer> .. .
  inoremap <buffer> ,, ,
  nnoremap <buffer> ,, @q
    "special exception; otherwise my 'macro repitition' shortcut fails in LaTeX documents
  "Quick way of declaring \latex{} commands
  vnoremap <buffer> <expr> ;. '<Esc>mz`>a}<Esc>`<i\'.input('Enter \<name>{}-style environment name: ').'{<Esc>`z'
  nnoremap <buffer> <expr> ;. 'mzviw<Esc>`>a}<Esc>`<i\'.input('Enter \<name>{}-style environment name: ').'{<Esc>`z'
  inoremap <buffer> <expr> ;. '\'.input('Enter \<name>{}-style environment name: ').'{}<Left>'
  "Quick way of declaring begin-end environments
  "1) start newline and enter \begin{}, then exit, then input new environment name inside, then exit
  "2) paste name (line looks like \begin{name}name)
  "3) wrap pasted name in \end{}
  "4) place newlines in appropriate positions -- for the visual remap, adding new lines
  "   messes up the < and > marks, so need to do that at end
  nnoremap <buffer> <expr> ,. 'A<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
  " vnoremap <buffer> <expr> ,. '<Esc>mz`>a\end{'.input('Enter begin-end-style environment name: ').'}<Esc>yiB'
  "       \.'F\i<CR><Esc>==`<i\begin{}<Esc>"aPf}a<CR><Esc><Up>V/\\end{<CR>==:noh<CR>`z'
  vnoremap <buffer> <expr> ,. '<Esc>mz`>a<CR>\end{}<Esc>i'.input('Enter begin-end-style environment name: ').'<Esc>=='
        \.'`<i\begin{<C-r>.}<CR><Esc><Up>==`z'
        " \.'F\i<CR><Esc>==`<i\begin{}<Esc>"aPf}a<CR><Esc><Up>V/\\end{<CR>==:noh<CR>`z'
  inoremap <buffer> <expr> ,. '<CR>\begin{}<Esc>i'.input('Enter begin-end environment name: ').'<Esc>'
        \.'$".pF}a\end{<Esc>A}<Esc>F}a<CR><Esc><Up>A<CR>'
  "Apply 'inner'/'outer'/'surround' syntax to \command{text} and \begin{env}text\end{env}
  nmap <buffer> dsl F{F\dt{dsB
  nnoremap <buffer> <expr> csl 'mzF{F\lct{'.input('Enter new \<name>{}-style environment name: ').'<Esc>`z'
  nnoremap <buffer> dal F{F\dt{daB
  nnoremap <buffer> cal F{F\dt{caB
  nnoremap <buffer> yal F{F\vf{%y
  nnoremap <buffer> val F{F\vf{%
  nnoremap <buffer> dil diB
  nnoremap <buffer> cil ciB
  nnoremap <buffer> yil yiB
  nnoremap <buffer> vil viB
  "The below maps had to be done without marks at all, because need recursive map
  "to match '%' pairs but also disabled 'marking' functionality in this script
  nmap <silent> <buffer> viL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>
  nmap <silent> <buffer> diL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>d
  nmap <silent> <buffer> ciL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>cc
  nmap <silent> <buffer> vaL /\\end{<CR>:noh<CR>V^%
  nmap <silent> <buffer> daL /\\end{<CR>:noh<CR>V^%d
  nmap <silent> <buffer> caL /\\end{<CR>:noh<CR>V^%cc
  nmap <silent> <buffer> dsL /\\end{<CR>:noh<CR><Up>V<Down>^%<Down>dp<Up>V<Up>d
  nmap <silent> <buffer> <expr> csL '/\\end{<CR>:noh<CR>APLACEHOLDER<Esc>^%f{<Right>ciB'
    \.input('Enter new begin-end environment name: ').'<Esc>/PLACEHOLDER<CR>:noh<CR>A {<C-r>.}<Esc>2F{dt{'
  " nnoremap <buffer> dsL ?begin<CR>hdf}/end<CR>hdf}
  " nnoremap <buffer> <expr> csL 'mz?\\begin{<CR>t}ciB'.input('Enter new begin-end environment name: ')
  "   \.'<Esc>/\\end{<CR>t}diB".P`z:noh<CR>'
  " nnoremap <buffer> viL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$
  " nnoremap <buffer> diL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$d
  " nnoremap <buffer> ciL ?\\begin{<CR><Down>0v/\\end{<CR><Up>$d<Up>$<CR>
  " nnoremap <buffer> vaL ?\\begin{<CR>0v/\\end<CR>$
  " nnoremap <buffer> daL ?\\begin{<CR>0v/\\end<CR>$d
  " nnoremap <buffer> caL ?\\begin{<CR>0v/\\end<CR>$s
  "Same, but for special Latex quotes
  nnoremap <buffer> dsq f'xF`x
  nnoremap <buffer> daq F`df'
  nnoremap <buffer> diq T`dt'
  nnoremap <buffer> caq F`cf'
  nnoremap <buffer> ciq T`ct'
  nnoremap <buffer> yaq F`yf'
  nnoremap <buffer> yiq T`yt'
  nnoremap <buffer> vaq F`vf'
  nnoremap <buffer> viq T`vt'
  nnoremap <buffer> dsQ 2f'F'2x2F`2x
  nnoremap <buffer> daQ 2F`d2f'
  nnoremap <buffer> diQ T`dt'
  nnoremap <buffer> caQ 2F`c2f'
  nnoremap <buffer> ciQ T`ct'
  nnoremap <buffer> yaQ 2F`y2f'
  nnoremap <buffer> yiQ T`yt'
  nnoremap <buffer> vaQ 2F`v2f'
  nnoremap <buffer> viQ T`vt'
  "Delimiters (advanced)/quick environments
  "First the delimiters without newlines
  " call s:delims('\|', '\left\\|', '\right\\|', 1)
  call s:delims(';\|', '\left\|',      '\right\|', 1, 0)
  call s:delims(';{',  '\left\{',      '\right\}', 1, 0)
  call s:delims(';(',  '\left(',       '\right)',  1, 0)
  call s:delims(';[',  '\left[',       '\right]',  1, 0)
  call s:delims(';<',  '\left<',       '\right>',  1, 0)
  call s:delims(';o', '{\color{red}', '}', 1, 0)
  call s:delims(';i', '\textit{',     '}', 1, 0)
  call s:delims(';t', '\textbf{',     '}', 1, 0) "now use ;i for various cite commands
  call s:delims(';y', '\texttt{',     '}', 1, 0) "typewriter text
  call s:delims(';l', '\underline{',  '}', 1, 0) "l for line
  call s:delims(';m', '\mathrm{',     '}', 1, 0)
  call s:delims(';n', '\mathbf{',     '}', 1, 0)
  call s:delims(';M', '\mathcal{',    '}', 1, 0)
  call s:delims(';N', '\mathbb{',     '}', 1, 0)
  call s:delims(';v', '\vec{',        '}', 1, 0)
  call s:delims(';V', '\verb$',       '$', 1, 0) "verbatim
  call s:delims(';d', '\dot{',        '}', 1, 0)
  call s:delims(';D', '\ddot{',       '}', 1, 0)
  call s:delims(';h', '\hat{',        '}', 1, 0)
  call s:delims(';`', '\tilde{',      '}', 1, 0)
  call s:delims(';-', '\overline{',   '}', 1, 0)
  call s:delims(';\', '\cancelto{}{', '}', 1, 0)
  call s:delims(';x', '\boxed{',      '}', 1, 0)
  call s:delims(';X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1, 0)
    "the second one allows stuff to extend into margins, possibly
  call s:delims(';/', '\sqrt{',     '}',  1, 0)
  call s:delims(';q', '`',          "'",  1, 0)
  call s:delims(';Q', '``',         "''", 1, 0)
  call s:delims(';$', '$',          '$',  1, 0)
  call s:delims(';e', '\times10^{', '}',  1, 0)
  call s:delims(';k', '^{',         '}',  1, 0)
  call s:delims(';j', '_{',         '}',  1, 0)
  call s:delims(';K', '\overset{}{', '}', 1, 0)
  call s:delims(';J', '\underset{}{',     '}',   1, 0)
  call s:delims(';f', '\dfrac{',          '}{}', 1, 0)
  call s:delims(';0', '\frametitle{',     '}',   1, 0)
  call s:delims(';1', '\section{',        '}',   1, 0)
  call s:delims(';2', '\subsection{',     '}',   1, 0)
  call s:delims(';3', '\subsubsection{',  '}',   1, 0)
  call s:delims(';4', '\section*{',       '}',   1, 0)
  call s:delims(';5', '\subsection*{',    '}',   1, 0)
  call s:delims(';6', '\subsubsection*{', '}',   1, 0)
  "Shortcuts for citations and such
  call s:delims(';7', '\ref{',     '}', 1, 0) "just the number
  call s:delims(';8', '\autoref{', '}', 1, 0) "name and number; autoref is part of hyperref package
  call s:delims(';9', '\label{',   '}', 1, 0) "declare labels that ref and autoref point to
  call s:delims(';!', '\tag{',     '}', 1, 0) "change the default 1-2-3 ordering; common to use *
  call s:delims(';z', '\note{',    '}', 1, 0) "notes are for beamer presentations, appear in separate slide
  call s:delims(';a', '\caption{', '}', 1, 0) "amazingly a not used yet
  call s:delims(';*', '\cite{',    '}', 1, 0) "most common
  call s:delims(';&', '\citet{',   '}', 1, 0) "second most common one
  call s:delims(';@', '\citep{',   '}', 1, 0) "second most common one
  call s:delims(';#', '\citenum{', '}', 1, 0) "most common
    "other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
    "have been rethinking this
  "Shortcuts for graphics
  call s:delims(';g', '\includegraphics{', '}', 1, 0)
  call s:delims(';G', '\makebox[\textwidth][c]{\includegraphicsawidth=\textwidth]{', '}}', 1, 0) "center across margins
  " call s:delims('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks
  "Comma-prefixed delimiters without newlines
  "Generally are more closely-related to the begin-end latex environments
  call s:delims(',1', '{\tiny ',         '}', 1, 0)
  call s:delims(',2', '{\scriptsize ',   '}', 1, 0)
  call s:delims(',3', '{\footnotesize ', '}', 1, 0)
  call s:delims(',4', '{\small ',        '}', 1, 0)
  call s:delims(',5', '{\normalsize ',   '}', 1, 0)
  call s:delims(',6', '{\large ',        '}', 1, 0)
  call s:delims(',7', '{\Large ',        '}', 1, 0)
  call s:delims(',8', '{\LARGE ',        '}', 1, 0)
  call s:delims(',9', '{\huge ',         '}', 1, 0)
  call s:delims(',0', '{\Huge ',         '}', 1, 0)
  call s:delims(',{', '\left\{\begin{matrix}[ll]', '\end{matrix}\right.', 1, 0)
  call s:delims(',P', '\begin{pmatrix}',           '\end{pmatrix}',       1, 0)
  call s:delims(',B', '\begin{bmatrix}',           '\end{bmatrix}',       1, 0)
  "Versions of the above, but this time puting them on own lines
  " call s:delimscr('P', '\begin{pmatrix}', '\end{pmatrix}')
  " call s:delimscr('B', '\begin{bmatrix}', '\end{bmatrix}')
  "Comma-prefixed delimiters with newlines; these have separate special function because
  "it does not make sense to have normal-mode maps for multiline begin/end environments
  "* The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "  with default single column; see: https://tex.stackexchange.com/a/366422/73149
  "* Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  call s:delimscr(';', '\begin{center}', '\end{center}') "because ; was available
  call s:delimscr('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
  call s:delimscr('C', '\begin{column}{.5\textwidth}', '\end{column}')
  call s:delimscr('i', '\begin{itemize}', '\end{itemize}')
  call s:delimscr('I', '\begin{description}', '\end{description}') "d is now open
  call s:delimscr('n', '\begin{enumerate}', '\end{enumerate}')
  call s:delimscr('N', '\begin{enumerate}[label=\alph*.]', '\end{enumerate}')
  call s:delimscr('t', '\begin{tabular}', '\end{tabular}')
  call s:delimscr('e', '\begin{equation*}', '\end{equation*}')
  call s:delimscr('a', '\begin{align*}', '\end{align*}')
  call s:delimscr('E', '\begin{equation}', '\end{equation}')
  call s:delimscr('A', '\begin{align}', '\end{align}')
  call s:delimscr('v', '\begin{verbatim}', '\end{verbatim}')
  call s:delimscr('V', '\begin{verbatim}', '\end{verbatim}')
  call s:delimscr('s', '\begin{frame}', '\end{frame}')
  call s:delimscr('S', '\begin{frame}[fragile]', '\end{frame}')
    "fragile option makes verbatim possible (https://tex.stackexchange.com/q/136240/73149)
    "note that fragile make compiling way slower
  call s:delimscr('m', '\begin{minipage}{\linewidth}', '\end{minipage}')
  call s:delimscr('f', '\begin{figure}', '\end{figure}')
  call s:delimscr('F', '\begin{subfigure}{.5\textwidth}', '\end{subfigure}')
  call s:delimscr('w', '\begin{wrapfigure}{r}{.5\textwidth}', '\end{wrapfigure}')
  "Single-character maps
  "THIS NEEDS WORK; right now maybe just too confusing
  inoremap <expr> <buffer> .m '\mathrm{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .M '\mathbf{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .h '\hat{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .v '\vec{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .` '\tilde{'.nr2char(getchar()).'}'
  inoremap <expr> <buffer> .= '\overline{'.nr2char(getchar()).'}'
  " inoremap <expr> <buffer> .M '\mathcal{'.nr2char(getchar()).'}'
  " inoremap <expr> <buffer> .N '\mathbb{'.nr2char(getchar()).'}'
  "Arrows
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  inoremap <buffer> ., \pause
  "Misc symbotls
  inoremap <buffer> ., \pause
  inoremap <buffer> .i \item 
  "Math symbols
  inoremap <buffer> .a \alpha 
  inoremap <buffer> .b \beta 
  inoremap <buffer> .c \xi 
  inoremap <buffer> .C \Xi 
    "weird curly one
    "the upper case looks like 3 lines
  inoremap <buffer> .x \chi 
    "looks like an x so want to use this map
    "pronounced 'zi', the 'i' in 'tide'
  inoremap <buffer> .d \delta 
  inoremap <buffer> .D \Delta 
  inoremap <buffer> .f \phi 
  inoremap <buffer> .F \Phi 
  inoremap <buffer> .g \gamma 
  inoremap <buffer> .G \Gamma 
  " inoremap <buffer> .k \kappa
  inoremap <buffer> .l \lambda 
  inoremap <buffer> .L \Lambda 
  inoremap <buffer> .u \mu 
  inoremap <buffer> .n \nabla 
  inoremap <buffer> .N \nu 
  inoremap <buffer> .e \epsilon 
  inoremap <buffer> .E \eta 
  inoremap <buffer> .p \pi 
  inoremap <buffer> .P \Pi 
  inoremap <buffer> .q \theta 
  inoremap <buffer> .Q \Theta 
  inoremap <buffer> .r \rho 
  inoremap <buffer> .s \sigma 
  inoremap <buffer> .S \Sigma 
  inoremap <buffer> .t \tau 
  inoremap <buffer> .y \psi 
  inoremap <buffer> .Y \Psi 
  inoremap <buffer> .w \omega 
  inoremap <buffer> .W \Omega 
  inoremap <buffer> .z \zeta 
  inoremap <buffer> .1 \partial 
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
  inoremap <buffer> .o \cdot 
  inoremap <buffer> .O \circ 
  inoremap <buffer> .- {-}
  inoremap <buffer> .+ {+}
  inoremap <buffer> .~ {\sim}
  inoremap <buffer> .k ^
  inoremap <buffer> .j _
  inoremap <buffer> ., \,
  inoremap <buffer> ._ {\centering\noindent\rule{\paperwidth/2}{0.7pt}}
    "centerline (can modify this; \rule is simple enough to understand)
  "Commands for compiling latex
  "-use clear, because want to clean up previous output first
  "-use set -x to ECHO LAST COMMAND
  "-use c-x for compile/run, and c-w for creating Word document
  noremap <silent> <buffer> <C-x> :w<CR>:exec("!clear; set -x; "
        \.'~/dotfiles/compile '.shellescape(@%).' false')<CR>
  noremap <silent> <buffer> <C-w> :w<CR>:exec("!clear; set -x; "
        \.'~/dotfiles/compile '.shellescape(@%).' true')<CR>
  inoremap <silent> <buffer> <C-x> <Esc>:w<CR>:exec("!clear; set -x; "
        \.'~/dotfiles/compile '.shellescape(@%).' false')<CR>a
  inoremap <silent> <buffer> <C-w> <Esc>:w<CR>:exec("!clear; set -x; "
        \.'~/dotfiles/compile '.shellescape(@%).' true')<CR>a
endfunction
"Function for loading templates
"See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
function! s:textemplates()
  let templates=split(globpath('~/latex/', '*.tex'),"\n")
  let names=[]
  for template in templates
    call add(names, '"'.fnamemodify(template, ":t:r").'"')
      "expand does not work, for some reason... because expand is used with one argument
      "with a globalfilename, e.g. % (current file)... fnamemodify is for strings
  endfor
  while 1
    echo "Current templates available: ".join(names, ", ")."."
    let template=expand("~")."/latex/".input("Enter choice: ").".tex"
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
  "no worries since ever TeX file should end in .tex; can't
  "think of situation where that's not true

"###############################################################################
"HTML MACROS, lots of insert-mode stuff
augroup html
augroup END
function! s:htmlmacros()
  call s:delimscr('h', '<head>', '</head>')
  call s:delimscr('b', '<body>', '</body>')
  call s:delimscr('t', '<title>', '</title>')
  call s:delimscr('p', '<p>', '</p>')
  call s:delimscr('1', '<h1>', '</h1>')
  call s:delimscr('2', '<h2>', '</h2>')
  call s:delimscr('3', '<h3>', '</h3>')
  call s:delimscr('4', '<h4>', '</h4>')
  call s:delimscr('5', '<h5>', '</h5>')
  call s:delims(',e', '<em>', '</em>', 1, 0)
  call s:delims(',t', '<strong>', '</strong>', 1, 0)
endfunction
"Toggle mappings
autocmd FileType html call s:htmlmacros()

"###############################################################################
"SPELLCHECK (really is a BUILTIN plugin)
augroup spell
augroup END
"Off by default
"Turn on for certain filetypes
set nospell spelllang=en_us spellcapcheck=
autocmd FileType tex,html,xml,text,markdown setlocal spell
"Toggle on and off
nnoremap so :setlocal spell!<CR>
nnoremap sl :call <sid>spelltoggle()<CR>
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
nnoremap sN [s
nnoremap sn ]s
"Get suggestions, or choose first suggestion without looking
nnoremap s. z=1<CR><CR>
nnoremap sd z=
"Add/remove from dictionary
nnoremap sa zg
nnoremap sr zug

"###############################################################################
"CUSTOM PYTHON MACROS
augroup python
augroup END
"Experimental feature
function! s:dconvert()
  " See: http://vim.wikia.com/wiki/Using_normal_command_in_a_script_for_searching
  let a:line=line('.')
  exe "normal! /=\<CR>"
  while line('.')==a:line
    "note the h after <Esc> only works if you have turned on the InsertLeave autocmd
    "that preserves the cursor position
    exe "normal! r:bi'\<Esc>hea'\<Esc>"
    exe "normal! /=\<CR>"
  endwhile
  exe "normal! \<C-o>"
endfunction
nnoremap <Leader>d :call <sid>dconvert()<CR>
"Macros for compiling code
function! s:pymacros()
  "Simple shifting
  setlocal tabstop=4
  setlocal softtabstop=4
  setlocal shiftwidth=4
  "Simple remaps
  nnoremap <buffer> <Leader>q o"""<CR>"""<Esc><Up>o
  "Maps that call shell commands
  " noremap <buffer> <expr> QD ":!clear; set -x; pydoc "
  "       \.input("Enter python documentation keyword: ")."<CR>"
  noremap <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."python ".shellescape(@%)."<CR>"
  inoremap <buffer> <expr> <C-x> "<Esc>:w<CR>:!clear; set -x; "
        \."python ".shellescape(@%)."<CR>a"
endfunction
"Toggle mappings with autocmds...or disable because they suck for now
autocmd FileType python call s:pymacros()
"Skeleton-code templates...decided that's unnecessary for python
" autocmd BufNewFile *.py 0r ~/skeleton.py
"###############################################################################
"MACROS FROM JEDI-VIM
"See: https://github.com/davidhalter/jedi-vim
if has_key(g:plugs, "jedi-vim")
  " let g:jedi#force_py_version=3
  let g:jedi#auto_vim_configuration = 0
    " set these myself instead
  let g:jedi#rename_command = ""
    "jedi-vim recommended way of disabling commands
    "note jedi auto-renaming sketchy, sometimes fails good example is try renaming 'debug'
    "in metadata function; jedi skips f-strings, skips its re-assignment in for loop,
    "skips where it appeared as default kwarg in function
  let g:jedi#usages_command = "QJ"
    "open up list of places where variable appears; then can 'goto'
  let g:jedi#goto_assignments_command = "QK"
    "goto location where definition/class defined
  let g:jedi#documentation_command = "QW"
    "use 'W' for 'what is this?'
  autocmd FileType python setlocal completeopt-=preview
    "disables docstring popup window
endif
"###############################################################################
"VIM python-mode
if has_key(g:plugs, "python-mode")
  let g:pymode_python='python3'
endif
"###############################################################################
"PYTHON-SYNTAX; these should be provided with VIM by default
au FileType python let g:python_highlight_all=1

"###############################################################################
"C MACROS
augroup c
augroup END
function! s:cmacros()
  "Will compile code, then run it and show user the output
  noremap  <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."gcc ".shellescape(@%)." -o ".expand('%:r')."; ./".expand('%:r')."<CR>"
endfunction
autocmd FileType c call s:cmacros()

"###############################################################################
"FORTRAN MACROS
augroup fortran
augroup END
function! s:fortranmacros()
  "Will compile code, then run it and show user the output
  noremap  <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."gfortran ".shellescape(@%)." -o ".expand('%:r')."; ./".expand('%:r')."<CR>"
endfunction
autocmd FileType fortran call s:fortranmacros()
"Also fix coloring issues; see :help fortran
let fortran_have_tabs=1
let fortran_fold=1
let fortran_free_source=1
let fortran_more_precise=1

"###############################################################################
"NCL COMPLECTION
augroup ncl
augroup END
" set complete-=k complete+=k " Add dictionary search (as per dictionary option)
" au BufRead,BufNewFile *.ncl set dictionary=~/.vim/words/ncl.dic
au FileType * execute 'setlocal dict+=~/.vim/words/'.&ft.'.dic'
  "can put other stuff here; right now this is just for the NCL dict for NCL

"###############################################################################
"SHELL MACROS
"MANPAGES of stuff
" augroup shell
" augroup END
" noremap <expr> QM ":silent !clear; man "
"     \.input('Search manpages: ')."<CR>:redraw!<CR>"
" "--help info; pipe output into less for better interaction
" noremap <expr> QH ":!clear; "
"     \.input('Show --help info: ')." --help \| less<CR>:redraw!<CR>"

"###############################################################################
"DISABLE LINE NUMBERS AND SPECIAL CHARACTERS IN SPECIAL WINDOWS; ENABLE q-QUITTING
"AND SOME HELP SETTINGS
augroup help
augroup END
noremap Q :vert help 
" function! s:helpclick()
"   "If LeftClick did not remove us from help-menu, then jump to tag
"   if &ft=="help"
"     normal! <C-]>
"       "weirdly :normal causes error< and :normal! does nothing
"   endif
" endfunction
function! s:helpsetup()
  if len(tabpagebuflist())==1 | q | endif "exit from help window, if it is only one left
  wincmd L "moves current window to be at far-right; 'wincmd' executes Ctrl+W functions
  vertical resize 79
  noremap <buffer> q :q<CR>
  nnoremap <buffer> <CR> <C-]>
  if g:has_nowait
    nnoremap <nowait> <buffer> [ :pop<CR>
    " nnoremap <buffer> <nowait> <LeftMouse> <LeftMouse>:call <sid>helpclick()<CR>
  endif
  setlocal nolist
  setlocal nonumber
  setlocal nospell
  "better jumping behavior; note these must be C-], not Ctrl-]
endfunction
au FileType help call s:helpsetup()
"The doc pages appear in rst files, so turn off extra chars for them
"Also the syntastic shows up as qf files so want extra stuff turned off there too
function! s:simplesetup()
  setlocal nolist
  setlocal nonumber
  setlocal nospell
endfunction
au FileType gitcommit,rst,qf call s:simplesetup()

"###############################################################################
"VIM visual increment; creating columns of 1/2/3/4 etc.
"Disable all remaps
augroup increment
augroup END
"Disable old ones
if has_key(g:plugs, "vim-visual-increment")
  silent! vunmap <C-a>
  silent! vunmap <C-x>
  vmap + <Plug>VisualIncrement
  vmap _ <Plug>VisualDecrement
  nnoremap + <C-a>
  nnoremap _ <C-x>
endif

"###############################################################################
"JULIA SUPPORT
augroup julia
augroup END
"jula custom here

"###############################################################################
"CODI (MATHEMATICAL NOTEPAD)
augroup codi
augroup END
if has_key(g:plugs, "codi.vim")
  nnoremap <C-p> <Nop>
  nnoremap <C-n> <Nop>
    "C-p already mapped to paste in insert mode; want these to do nothing
  nnoremap <C-o> :CodiUpdate<CR>
  inoremap <C-o> <Esc>:CodiUpdate<CR>a
    "update manually commands; o stands for codi
  nnoremap <silent> <expr> <Leader>o ':Codi!! '.&ft.'<CR>'
    "turns current file into calculator; m stands for math
  nnoremap <silent> <expr> <Leader>O ':tabe '.input('Enter python calculator name: ').'.py<CR>:Codi python<CR>'
    "creates new calculator file, adds .py extension
  let g:codi#interpreters = {
       \ 'python': {
           \ 'bin': '/usr/bin/python',
           \ 'prompt': '^\(>>>\|\.\.\.\) ',
           \ },
       \ } "see issue here: https://github.com/metakirby5/codi.vim/issues/85
    "use builtin python2.7 on macbook to avoid creating history files
     " \ 'bin': '/usr/bin/python',
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20
    "simple window configuration
  let g:codi#autocmd = "None"
    "CursorHold sometimes caused errors/CPU spikes; this is weird because actually
    "shouldn't, get flickering cursor and codi still running even after 250ms; maybe some other option conflicts
  let g:codi#sync = 0
    "probably easier
  let g:codi#log = "codi.log"
    "log everything, becuase you *will* have issues
endif

"###############################################################################
"HOWMUCH (SUMMING TABLE ELEMENTS)
"NO LONGER CONTROLLED BY PLUGIN MANAGER; USE REMAPS
"<Leader>s and <Leader>S TO SUM EQUATIONS IN SINGLE COLUMN
augroup howmuch
augroup END
let g:HowMuch_auto_engines=['py', 'bc'] "python engine uses from math import *
let g:HowMuch_scale=3 "precision
" if has_key(g:plugs, "HowMuch")
"   "default maps are <Leader>?
" endif

"###############################################################################
"MUCOMPLETE
augroup mucomplete
augroup END
if has_key(g:plugs, "vim-mucomplete") "just check if activated
  let g:mucomplete#enable_auto_at_startup = 1
  let g:mucomplete#no_mappings = 1
  let g:mucomplete#no_popup_mappings = 1
endif

"###############################################################################
"NEOCOMPLETE (RECOMMENDED SETTINGS)
augroup neocomplete
augroup END
if has_key(g:plugs, "neocomplete.vim") "just check if activated
  "Disable python omnicompletion
  "From the Q+A section
  if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
  endif
  let g:neocomplete#sources#omni#input_patterns.python = ''
  "###############################################################################
  "OTHER SETTINGS
  "Important behavior; allows us to use neocomplete without mapping everything to <C-e> stuff
  "Basic behavior
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#max_list = 10
  let g:neocomplete#enable_auto_select = 0
  let g:neocomplete#auto_completion_start_length = 1
  let g:neocomplete#sources#syntax#min_keyword_length = 2
  " let g:neocomplete#disable_auto_complete = 1 "useful only if above is zero
  "Do not use smartcase.
  let g:neocomplete#enable_smart_case = 0
  let g:neocomplete#enable_camel_case = 0
  let g:neocomplete#enable_ignore_case = 0
  "Define dictionary.
  let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
        \ }
  "Define keyword.
  if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
  endif
  let g:neocomplete#keyword_patterns['default'] = '\h\w*'
endif
"Highlighting
highlight Pmenu ctermbg=Black ctermfg=Yellow cterm=None
highlight PmenuSel ctermbg=Black ctermfg=Black cterm=None
highlight PmenuSbar ctermbg=None ctermfg=Black cterm=None
"Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
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

"###############################################################################
"CURRENT DIRECTORY
"First of all match VIM 'current directory' to the file current directory; allows
"us e.g. to use git commands on files on the fly
" autocmd BufEnter * lcd %:p:h "messes up session restore
"###############################################################################
"NERDTREE
augroup nerdtree
augroup END
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
if has_key(g:plugs, "nerdtree")
  " noremap <Tab>j :NERDTreeFind<CR>
  noremap <Tab>j :NERDTree %<CR>
  noremap <Tab>J :NERDTreeTabsToggle<CR>
  let g:NERDTreeWinPos="right"
  let g:NERDTreeWinSize=20 "instead of 31 default
  let g:NERDTreeShowHidden=1
  let g:NERDTreeMinimalUI=1 "remove annoying ? for help note
  let g:NERDTreeMapChangeRoot="D" "C was annoying, because VIM will wait for 'CD'
  "Sorting and filetypes ignored
  let g:NERDTreeSortOrder=[] "use default sorting
  let g:NERDTreeIgnore=split(&wildignore, ',')
  for s:index in range(len(g:NERDTreeIgnore))
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '*.', '\\.', '')
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '$', '\$', '')
  endfor
  "Close nerdtree if last in tab
  autocmd BufEnter * if (winnr('$')==1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
  "Setup maps
  "See this thread for ideas: https://superuser.com/q/195022/506762
  function! s:nerdtreesetup()
    " normal! <C-w>r
    setlocal nolist
    nmap <buffer>  <Tab><Tab> :let g:PreTab=tabpagenr()<CR>T:exe 'tabn '.g:PreTab<CR>
    noremap <buffer> <Tab>j :NERDTreeClose<CR>
  endfunction
  autocmd FileType nerdtree call s:nerdtreesetup()
endif

"###############################################################################
"NERDCommenter (comment out stuff)
augroup nerdcomment
augroup END
"Note the default mappings, all prefixed by <Leader> (but we disable them)
" -cc comments line or selection
" -cn forces nesting (seems to be default though; maybe sometimes, is ignored)
" -ci toggles comment state of inidivudal lines
" -c<Space> toggles comment state based on topmost line state
" -cs comments line with block-format layout
" -cy yanks lines before commenting
" -c$ comments to eol
" -cu uncomments line
if has_key(g:plugs, "nerdcommenter")
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
  "Create python docstring
  nnoremap c' o'''<CR>.<CR>'''<Up><Esc>A<BS>
  nnoremap c" o"""<CR>.<CR>"""<Up><Esc>A<BS>
  "Set up custom remaps
  nnoremap c<CR> <Nop>
  "Declare mapping strings needed to build remaps
  "Then can *delcare mapping for custom keyboard* using exe 'nnoremap <expr> shortcut '.string,
  "and note that the expression is evaluated every time right before the map is executed (i.e. buffer-local comment chars are generated)
  "The below helper functions lets us change the table commands for different filetypes; very handy
  function! s:commentheaders()
    "Declare helper functions, and figure out initial settings
    "For new-style section header, just add another constructer-function
    function! s:bar(char)
      return "'mzo<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(79-col('.')+1).'a".a:char."<Esc>`z'"
    endfunction
    function! s:section(char)
      return "'mzo<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(79-col('.')+1).'a".a:char."<Esc>"
        \."o<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>"
        \."o<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(79-col('.')+1).'a".a:char."<Esc>"
        \."<Up>$a<Space><Esc>'"
    endfunction
    if &ft=="vim" | let a:fatchar="#" "literally says 'type a '#' character while in insert mode'
    else | let a:fatchar="'.b:NERDCommenterDelims['left'].'"
        "will be evaluated when <expr> is evaluted (we are catting to <expr> string)
        "will *not* evaluate on :exec command declaring initial map
    endif
    "Declare remaps; section-header types will be dependent on filetype, e.g.
    "if comment character is not 'fat' enough, does not make good section header character
    if has_key(g:plugs, "vim-repeat")
      exe 'nnoremap <buffer> <expr> <Plug>fancy1 '.s:bar("-").".'".':call repeat#set("\<Plug>fancy1")<CR>'."'"
      exe 'nnoremap <buffer> <expr> <Plug>fancy2 '.s:bar(a:fatchar).".'".':call repeat#set("\<Plug>fancy2")<CR>'."'"
      exe 'nnoremap <buffer> <expr> <Plug>fancy3 '.s:section("-").".'".':call repeat#set("\<Plug>fancy3")<CR>'."'"
      exe 'nnoremap <buffer> <expr> <Plug>fancy4 '.s:section(a:fatchar).".'".':call repeat#set("\<Plug>fancy4")<CR>'."'"
      nmap c- <Plug>fancy1
      nmap c_ <Plug>fancy2
      nmap c\ <Plug>fancy3
      nmap c\| <Plug>fancy4
    else
      exe 'nnoremap <buffer> <expr> c- '.s:bar("-")
      exe 'nnoremap <buffer> <expr> c_ '.s:bar(a:fatchar)
      exe 'nnoremap <buffer> <expr> c\ '.s:section("-")
      exe 'nnoremap <buffer> <expr> c\| '.s:section(a:fatchar)
    endif
  endfunction
  au FileType * call s:commentheaders()
  "More basic NerdComment maps, just for toggling comments and stuff
  "Easy peasy
  if has_key(g:plugs, "vim-repeat")
    nnoremap <Plug>comment1 :call NERDComment('n', 'comment')<CR>:call repeat#set("\<Plug>comment1",v:count)<CR>
    nnoremap <Plug>comment2 :call NERDComment('n', 'uncomment')<CR>:call repeat#set("\<Plug>comment2",v:count)<CR>
    nnoremap <Plug>comment3 :call NERDComment('n', 'toggle')<CR>:call repeat#set("\<Plug>comment3",v:count)<CR>
    nmap co <Plug>comment1
    nmap cO <Plug>comment2
    nmap c. <Plug>comment3
  else
    nnoremap co :call NERDComment('n', 'comment')<CR>
    nnoremap cO :call NERDComment('n', 'uncomment')<CR>
    nnoremap c. :call NERDComment('n', 'toggle')<CR>
  endif
  vnoremap co :call NERDComment('v', 'comment')<CR>
  vnoremap cO :call NERDComment('v', 'uncomment')<CR>
  vnoremap c. :call NERDComment('v', 'toggle')<CR>
endif

"###############################################################################
"SYNTASTIC (syntax checking for code)
augroup syntastic
augroup END
if has_key(g:plugs, "syntastic")
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
endif

"###############################################################################
"TAGBAR (requires 'brew install ctags-exuberant')
augroup tagbar
augroup END
"Neat idea for function; just call this whenever Tagbar is toggled
"Can put other things in here too; the buffer remaps can be declared
"in separate FileType autocmds but this is nice too
" * Note LEADER does not work as first key for the Tagbar Space-Space remap;
"   since it already has a single-space-press command. Need to declare 'Leader' specifically.
" * Best approach for this situation; make GLOBAL remap, but allow overriding
"   buffer-specific remap. Seems to be cleanest way.
" * Note I tried doing the below with autocmd FileType tagbar but didn't really work
"   perhaps because we need other FileType cmds to act first.
if has_key(g:plugs, "tagbar")
  function! s:tagbarsetup()
    "Helper function
    " noremap <buffer> = zo
      "doesn't work because Tagbar maps = to something else
    "First toggle the tagbar; issues when toggling from NERDTree so switch
    "back if cursor is already there. No issues toggline from Help window.
    "Note toggling tagbar in a help menu appears to be fine
    if &ft=="nerdtree"
      wincmd h
      wincmd h "move two places in case e.g. have help menu + nerdtree already
    endif
    TagbarToggle "you just state commands like these
    "Then some fancy stuff, if the command just activated Tagbar
    if &ft=="tagbar"
      "Initial stuff
      let tabfts=[]
      let tabnms=[]
      for b in tabpagebuflist()
        call add(tabfts, getbufvar(b, "&ft"))
        call add(tabnms, fnamemodify(bufname(b),":t"))
      endfor
      "Change the default open stuff for vimrc
      "Do so by testing names of files in this tab
      if index(tabnms,".vimrc")!=-1
        keepjumps silent normal =
        silent exec "/^\. autocommand groups$"
        keepjumps normal +
      endif
      "Make sure NERDTree is always flushed to the far right
      "Do this by moving TagBar one spot to the left if it is opened
      "while NERDTree already open. If TagBar was opened first, NERDTree will already be far to the right.
      if index(tabfts,"nerdtree")!=-1
        wincmd h
        wincmd x
      endif
      "The remap to travel to tag on typing
      nmap <expr> <buffer> <Space><Space> "/".input("Travel to this tagname regex: ")."<CR>:noh<CR><CR>"
    endif
  endfunction
  nnoremap <silent> <Tab>k :call <sid>tagbarsetup()<CR>
  nmap <expr> <Space><Space> ":TagbarOpen<CR><Tab>L/".input("Travel to this tagname regex: ")."<CR>:noh<CR><CR>"
    "be careful -- need to use default window-switching shortcut here!
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
  " let g:tagbar_iconchars = ['▸', '▾'] "prettier
  let g:tagbar_silent=1 "no information echoed
  let g:tagbar_previewwin_pos="bottomleft" "result of pressing 'P'
  let g:tagbar_left=0 "open on left; more natural this way
    "nevermind right is better; left is in the way
  let g:tagbar_zoomwidth=0 "zoom to width of longest tag, not infinity!
  let g:tagbar_foldlevel=0 "default none
  let g:tagbar_indent=-1 "only one space indent
  let g:tagbar_autoshowtag=0 "expand when new tags
    "never opens tag folds automatically
  let g:tagbar_show_linenumbers=0 "don't show line numbers
  let g:tagbar_autofocus=1 "autojump to window if opened
    "somewhat annoying but probably want this
  let g:tagbar_sort=1 "sort alphabetically? actually much easier to navigate, so yes
  let g:tagbar_case_insensitive=1 "make sorting case insensitive
  let g:tagbar_compact=1 "no header information in panel
  let g:tagbar_singleclick=0 "one click select 
    "(don't use this; inconsistent with help menu and makes it impossible to switch windows by clicking)
  let g:tagbar_width=25 "better default
  " au FileType python :TagbarOpen | :syntax on
  " au BufEnter * nested :call tagbar#autoopen(0)
  " au BufEnter python nested :TagbarOpen
  " au VimEnter * nested :TagbarOpen
  " au BufRead python normal }
  "the vertical line, because it wasn't used and tagbar makes a 'panel'
  "...no, instead } because it shows up on right
endif

"###############################################################################
"WRAPPING AND LINE BREAKING
augroup wrap
augroup END
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
  if 'bib,tex,html,xml,text,markdown'=~&ft
    call s:wraptoggle(1)
  else
    call s:wraptoggle(0)
  endif
endfunction
autocmd BufEnter * call s:autowrap()
"Declare mapping, to toggle on and off
" noremap <silent> <Leader>w :call <sid>wraptoggle(-1)<CR>
"Create word counting map instead
nnoremap <Leader>w g<C-g>
vnoremap <Leader>w g<C-g>

"###############################################################################
"TABULAR - ALIGNING AROUND :,=,ETC.
augroup tabular
augroup END
if has_key(g:plugs, "tabular")
  "NOTE: e.g. for aligning text after colons, input character :\zs; aligns
  "first character after matching preceding character
  vnoremap <expr> -t ':Tabularize /'.input('Align character: ').'<CR>'
  nnoremap <expr> -t ':Tabularize /'.input('Align character: ').'<CR>'
    "arbitrary character
  vnoremap <expr> -C ':Tabularize /^.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  nnoremap <expr> -C ':Tabularize /^.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
    "by comment character; ^ is start of line, . is any char, .* is any number, \zs
    "is start match here (must escape backslash), then search for the comment
  vnoremap <expr> -c ':Tabularize /^\s*\S.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  nnoremap <expr> -c ':Tabularize /^\s*\S.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
    "by comment character; but this time, ignore comment-only lines (must be non-comment non-whitespace character)
  nnoremap -, :Tabularize /,\zs/l0r1<CR>
  vnoremap -, :Tabularize /,\zs/l0r1<CR>
    "by commas; suitable for diag_table's in models; does not ignore comment characters
  vnoremap  -- :Tabularize /^\s*\S\{-1,}\zs\s/l0<CR>
  nnoremap  -- :Tabularize /^\s*\S\{-1,}\zs\s/l0<CR>
    "see :help non-greedy to see what braces do; it is like *, except instead of matching
    "as many as possible, can match as few as possible in some range; with braces, a minus will mean non-greedy
  " nnoremap <expr> Tab/^\S*\s\+\zs/r1l0l0
  vnoremap <expr> -r ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /r1l0l0<CR>'
  nnoremap <expr> -r ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /r1l0l0<CR>'
    "right-align by spaces, but ignoring any commented lines
  vnoremap <expr> -<Space> ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
  nnoremap <expr> -<Space> ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
    "check out documentation on \@<! atom; difference between that and \@! is that \@<!
    "checks whether something doesn't match *anywhere before* what follows
    "also the \S has to come before the \(\) atom instead of after for some reason
  "TODO: Note the above still has limitations due to Tabularize behavior; if have
  "the c/d/e/f will be pushed past the comment since the b and everything that follows
  "are considered part of the same delimeted field. just make sure lines with comments
  "are longer than the lines we actually want to align
  vnoremap -= :Tabularize /^[^=]*\zs=<CR>
  nnoremap -= :Tabularize /^[^=]*\zs=<CR>
  vnoremap -+ :Tabularize /^[^=]*\zs=\zs<CR>
  nnoremap -+ :Tabularize /^[^=]*\zs=\zs<CR>
    "align assignments, and keep equals signs on the left; only first equals sign
  vnoremap -d :Tabularize /:\zs<CR>
  nnoremap -d :Tabularize /:\zs<CR>
    "align colon table, and keeps colon on the left; the zs means start match **after** colon
endif
"###############################################################################
"FTPLUGINS
augroup ftplugin
augroup END
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
"1) we haven't already loaded an available non-default file using ftplugin or
"2) there is no alternative file loaded by the ftplugin function

"###############################################################################
"###############################################################################
" GENERAL STUFF, BASIC REMAPS
"###############################################################################
"###############################################################################
augroup SECTION3
augroup END
"###############################################################################
"BUFFER WRITING/SAVING
augroup saving
augroup END
nnoremap <silent> <C-s> :w!<CR>
"use force write, in case old version exists
au FileType help nnoremap <buffer> <C-s> <Nop>
nnoremap <silent> <C-q> :try \| tabclose \| catch \| qa \| endtry<CR>
nnoremap <silent> <C-a> :qa<CR>
nnoremap <silent> <C-w> :q<CR>
" nnoremap <C-q> :silent! tabclose<CR>
"make tabclose silent, so no error raised if last tab present
"so we have close current window, close tab, and close everything
"but make sure q always closes everything in a tab

"###############################################################################
"IMPORTANT STUFF
augroup settings
augroup END
"Tabbing
set expandtab "says to always expand \t to their length in <SPACE>'s!
set autoindent "indents new lines
set backspace=indent,eol,start "backspace by indent - handy
nnoremap <Space><Tab> :set expandtab!<CR>
"Wrapping
autocmd BufEnter * set textwidth=0 "hate auto-linebreaking, this disables it no matter what ftplugin says
set textwidth=0 "also disable it to start with... dummy
set linebreak "breaks lines only in whitespace... makes wrapping acceptable
set wrapmargin=0 "starts wrapping at the edge; >0 leaves empty bufferzone
set display=lastline "displays as much of wrapped lastline as possible;
"Global behavior
set nostartofline  "when switching buffers, doesn't move to start of line (weird default)
set lazyredraw "so maps aren't jumpy
set virtualedit= "prevent cursor from going where no actual character
set noerrorbells visualbell t_vb=
  "set visualbell ENABLES internal bell; but t_vb= means nothing is shown on the window
"Multi-key mappings and Multi-character keycodes
set esckeys "make sure enabled; allows keycodes
set notimeout timeoutlen=0 "so when timeout is disabled, we do this
set ttimeout ttimeoutlen=0 "no delay after pressing <Esc>
  "the first one says wait forever when doing multi-key mappings
  "the second one says wait 0seconds for multi-key keycodes e.g. <S-Tab>=<Esc>[Z
"Command-line behavior e.g. when openning new files
"Also improve wildmenu (command mode file/dir suggestions) behavior
set confirm "require confirmation if you try to quit
set wildmenu
set wildmode=longest:list,full
function! s:entersubdir()
  call feedkeys("\<Down>", 't')
  return ''
endfunction
function! s:enterpardir()
  call feedkeys("\<Up>", 't')
  return ''
endfunction
cnoremap <expr> <C-d> <sid>entersubdir()
cnoremap <expr> <C-u> <sid>enterpardir()
  "note that <C-k> will ALWAYS trigger moving UP the directory tree while
  "<C-j> will ALWAYS trigger moving DEEPER INSIDE the directory tree; so if
  "you press <C-j> without completion options while inside ../, the .. will be deleted

"###############################################################################
"SEARCHING AND FIND-REPLACE STUFF
augroup searching
augroup END
"Searching within scope of current function or environment
" * Search func idea came from: http://vim.wikia.com/wiki/Search_in_current_function
" * Below is copied from: https://stackoverflow.com/a/597932/4970632
" * Note jedi-vim 'variable rename' is sketchy and fails; should do my own
"   renaming, and do it by confirming every single instance
function! g:scopesearch(replace) "global one for testing
  let saveview=winsaveview()
  keepjumps normal [[
    "allow recursion here
    "also assumes we did the match below
  let a:first=line('.')
  keepjumps normal ][
  let a:last=line('.')
  call winrestview(saveview)
  if a:first<a:last
    if a:replace
      return printf('%d,%ds', a:first-1, a:last+1) "simply the range for a :search and replace command
    else
      return printf('\%%>%dl\%%<%dl', a:first-1, a:last+1)
        "%% is literal % character, and backslashes do nothing in single quote; check out %l atom documentation
    endif
  else
    return "\b" "backspace, because we failed, so forget the range limitation
  endif
endfunction
function! s:scopesearch(replace)
  let a:start=line('.')
  let saveview=winsaveview()
  "Loop through possible jumping commands
  "In future, consider detecting separately for python indentation level
  "Could just search until we encounter text at wrong indentation
  " for a:endjump in ['normal ][', 'normal ]]k', 'normal G', 'call search('^\S')']
  for a:endjump in ['normal ][', 'normal ]]k', 'call search("^\\S")']
    " echom 'Trying '.a:endjump
    keepjumps normal [[
    let a:first=line('.')
    exe 'keepjumps '.a:endjump
    let a:last=line('.')
    " echom a:first.' to '.a:last | sleep 1
    if a:first<a:last | break | endif
    exe 'normal '.a:start.'g'
    "return to initial state at the end, important
  endfor
  "Return stuff or whatever
  call winrestview(saveview)
  if a:first<a:last
    echom "Scopesearch selected lines ".a:first." to ".a:last."."
    if !a:replace
      return printf('\%%>%dl\%%<%dl', a:first-1, a:last+1)
        "%% is literal % character, and backslashes do nothing in single quote; check out %l atom documentation
    else
      return printf('%d,%ds', a:first-1, a:last+1) "simply the range for a :search and replace command
    endif
  else
    echom "Warning: Scopesearch failed to find function range (first line ".a:first." >= second line ".a:last.")."
    sleep 1
    return "" "empty string; will not limit scope anymore
  endif
endfunction
"###############################################################################
"BASICS; (showmode shows mode at bottom [default I think, but include it],
"incsearch moves to word as you begin searching with '/' or '?')
set hlsearch incsearch "show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase "smartcase makes search case insensitive, unless has capital letter
au InsertEnter * set noignorecase
au InsertLeave * set ignorecase
"Map to search by character; never use default ! map so why not!
"By default ! waits for a motion, then starts :<range> command
nnoremap <silent> ! :let b:position=winsaveview()<CR>xhp/<C-R>-<CR>N:call winrestview(b:position)<CR>
"###############################################################################
"MAGICAL FUNCTION; performs n.n.n. style replacement in one keystroke
"Copied from: https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
let g:should_inject_replace_occurences = 0
function! MoveToNext()
  if g:should_inject_replace_occurences
    call feedkeys("n")
    call repeat#set("\<Plug>ReplaceOccurences")
  endif
  let g:should_inject_replace_occurences = 0
endfunction
augroup auto_move_to_next
  autocmd! InsertLeave * :call MoveToNext()
augroup END
nmap <silent> <Plug>ReplaceOccurences :call ReplaceOccurence()<CR>
nmap <silent> <Leader>* :let @/='\C\<'.expand('<cword>').'\>'<CR>:set hlsearch<CR>:let g:should_inject_replace_occurences=1<CR>cgn
vmap <silent> <Leader>* :<C-u>let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>gvy
      \ :let @/ = substitute(escape(@",'/\.*$^~['),'\_s\+','\\_s\\+','g')<CR>:set hlsearch<CR>
      \ :let g:should_inject_replace_occurences=1<CR>gV
      \ :call setreg('"', old_reg, old_regtype)<CR>cgn
function! ReplaceOccurence()
  "Check if we are on top of an occurence
  let l:winview = winsaveview()
  let l:save_reg = getreg('"')
  let l:save_regmode = getregtype('"')
  let [l:lnum_cur, l:col_cur] = getpos(".")[1:2] 
  normal! ygn
  let [l:lnum1, l:col1] = getpos("'[")[1:2]
  let [l:lnum2, l:col2] = getpos("']")[1:2]
  call setreg('"', l:save_reg, l:save_regmode)
  call winrestview(winview)
  "If we are on top of an occurence, replace it
  if l:lnum_cur >= l:lnum1 && l:lnum_cur <= l:lnum2 && l:col_cur >= l:col1 && l:col_cur <= l:col2
    exe "normal! cgn\<c-a>\<esc>"
  endif
  call feedkeys("n")
  call repeat#set("\<Plug>ReplaceOccurences")
endfunction
"###############################################################################
"AWESOME REFACTORING STUFF I MADE MYSELF
"Remap ? for function-wide searching; follows convention of */# and &/@
"The \(\) makes text after the scope-atoms a bit more readable
nnoremap <silent> <expr> ? '/<C-r>=<sid>scopesearch(0)<CR>\(\)'.nr2char(getchar())
" nnoremap <silent> <expr> ? '/'.<sid>scopesearch(0).nr2char(getchar())
"Keep */# case-sensitive while '/' and '?' are smartcase case-insensitive
nnoremap <silent> * :let @/='\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
nnoremap <silent> & :let @/='\_s\@<='.expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
"Equivalent of * and # (each one key to left), but limited to function scope
" nnoremap <silent> & /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``
" nnoremap <silent> @ /<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\C<CR>``
nnoremap <silent> # :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
nnoremap <silent> @ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
  "note the @/ sets the 'last search' register to this string value
" * Also expand functionality to <cWORD>s -- do this by using \_s
"   which matches an EOL (from preceding line or this line) *or* whitespace
" * Use ':let @/=STUFF<CR>' instead of '/<C-r>=STUFF<CR><CR>' because this prevents
"   cursor from jumping around right away, which is more betterer
"Restore some important functionality
"Makes mnemonic sense, also would never ever want to 'select
"all the text up to the next match', which is current meaning of vn/vN
"The below will enter visual mode on the next/previous match
nnoremap vN gN
nnoremap vn gn
"Next there are a few mnemonically similar maps
"1) Delete currently highlighted text
" * For repeat.vim useage with <Plug> named plugin syntax, see: http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
" * Note that omitting the g means only *first* occurence is replaced
"   if use %, would replace first occurence on every line
" * Options for accessing register in vimscript, where we can't immitate user <C-r> keystroke combination:
"     exe 's/'.@/.'//' OR exe 's/'.getreg('/').'//'
"2) Replace current word, then hit dot to repeat on subsequent instance
"Should use THIS instead of ciw then dot-n-dot-n et cetera
" * From thread: https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
" * By default & repeats last :s command
" * Use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on empty lines
" * gn and gN move to next hlsearch, then *visually selects it*, so cgn says to change in this selection
" nnoremap c@ ?<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgN
" nnoremap c# ?\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgN
" nnoremap q gn "temporary to understand stuff
nnoremap c# /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgn
nnoremap c@ /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``cgn
nnoremap c* /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgn
nnoremap c& /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``cgn
if 1 && has_key(g:plugs, "vim-repeat")
  " nnoremap <Plug>search2 ?<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgNn:call repeat#set("\<Plug>search2",v:count)<CR>
  " nnoremap <Plug>search4 ?\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgNn:call repeat#set("\<Plug>search4",v:count)<CR>
  " nnoremap <Plug>search6 ?<C-r>/<CR>``dgNn:call repeat#set("\<Plug>search6",v:count)<CR>
  nnoremap <Plug>search1 /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgnn:call repeat#set("\<Plug>search1",v:count)<CR>
  nnoremap <Plug>search2 /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgnn:call repeat#set("\<Plug>search2",v:count)<CR>
  nnoremap <Plug>search3 /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgnn:call repeat#set("\<Plug>search3",v:count)<CR>
  nnoremap <Plug>search4 /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgnn:call repeat#set("\<Plug>search4",v:count)<CR>
  nnoremap <Plug>search5 /<C-r>/<CR>``dgnn:call repeat#set("\<Plug>search5",v:count)<CR>
  nmap d# <Plug>search1
  nmap d@ <Plug>search2
  nmap d* <Plug>search3
  nmap d& <Plug>search4
  nmap d/ <Plug>search5
else "with these ones, cursor will remain on word just replaced
  " nnoremap d@ ?<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgN
  " nnoremap d# ?\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgN
  " nnoremap d? ?<C-r>/<CR>``dgN
  nnoremap d# /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgn
  nnoremap d@ /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgn
  nnoremap d* /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgn
  nnoremap d& /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgn
  nnoremap d/ /<C-r>/<CR>``dgn
endif
"Search all capital words
nnoremap cz /\<[A-Z]\+\><CR>
"Colon search replacements -- not as nice as the above ones, which stay in normal mode
" * Consider opinion guy who made above maps expressed in this thread:
" https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
" "Replace current word with <this string>
" nnoremap <Leader>r :%s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
" nnoremap <Leader>R :<C-r>=<sid>scopesearch(1)<CR>/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
"   "the <C-r> means paste from the expression register i.e. result of following expr
" "Delete <this string>
" nnoremap <Leader>d :%s///gIc<Left><Left><Left><Left><Left>
" nnoremap <Leader>D :<C-r>=<sid>scopesearch(1)<CR>///gIc<Left><Left><Left><Left><Left>
"###############################################################################
"SPECIAL DELETION TOOLS
"see https://unix.stackexchange.com/a/12814/112647 for idea on multi-empty-line map
"Replace consecutive spaces on current line with one space
nnoremap <Leader>q :s/\(^ *\)\@<! \{2,}/ /g<CR>
"Replace consecutive newlines with single newline
nnoremap <Leader>Q :%s/\(\n\n\)\n\+/\1/gc<CR>
"Replace trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
nnoremap <Leader>x :%s/\s\+$//g<CR>
vnoremap <Leader>x :s/\s\+$//g<CR>
"Replace commented lines
" nnoremap <expr> <Leader>X ':%s/^\s*'.b:NERDCommenterDelims['left'].'.*$\n//gc<CR>'
nnoremap <expr> <Leader>X ':%s/\(^\s*'.b:NERDCommenterDelims['left'].'.*$\n'
      \.'\\|^.*\S*\zs\s\+'.b:NERDCommenterDelims['left'].'.*$\)//gc<CR>'
"Replace useless BibTex entries; replace long dash unicode with --, which will be rendered to long dash
function! s:cutmaps()
  nnoremap <buffer> <Leader>b :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=.*$\n//gc<CR>
  nnoremap <buffer> <Leader>- :%s/–/--/gc<CR>
endfunction
au FileType bib,tex call s:cutmaps() "some bibtex lines

"###############################################################################
"CAPS LOCK WITH C-a IN INSERT/COMMAND MODE
augroup capslock
augroup END
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

"###############################################################################
"TAB NAVIGATION
augroup tabs
augroup END
let g:LastTab=1
au TabLeave * let g:LastTab=tabpagenr()
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
  "this lets us open several files in glob pattern (e.g. all python files)
  "must be executed RIGHT AFTER OPENING VIM; other stuff
noremap <silent> <Tab>. :execute "tabn ".g:LastTab<CR>
  "return to previous tab
"###############################################################################
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
"###############################################################################
"WINDOW MANAGEMENT
noremap <Tab> <Nop>
noremap <Tab><Tab> <Nop>
noremap <Tab>q <C-w>o
" noremap <Tab><Tab>q <C-w>o
  "close all but current window
"Splitting -- make :sp and :vsp split to right and bottom
set splitright
set splitbelow
"Size-changing remaps
" noremap <Tab>J :exe 'resize '.(winheight(0)*3/2)<CR>
" noremap <Tab>K :exe 'resize '.(winheight(0)*2/3)<CR>
" noremap <Tab>H :exe 'vertical resize '.(winwidth(0)*3/2)<CR>
" noremap <Tab>L :exe 'vertical resize '.(winwidth(0)*2/3)<CR>
noremap <Tab><Down> :exe 'resize '.(winheight(0)*3/2)<CR>
noremap <Tab><Up> :exe 'resize '.(winheight(0)*2/3)<CR>
noremap <Tab><Left> :exe 'vertical resize '.(winwidth(0)*3/2)<CR>
noremap <Tab><Right> :exe 'vertical resize '.(winwidth(0)*2/3)<CR>
noremap <Tab>= <C-w>=
" noremap <Tab><Tab>= <C-w>=
  "set all windows to equal size
noremap <Tab>M <C-w>_
  "maximize window
"Window selection
" noremap <Tab><Left> <C-w>h
" noremap <Tab><Down> <C-w>j
" noremap <Tab><Up> <C-w>k
" noremap <Tab><Right> <C-w>l
noremap <Tab>J <C-w>j
noremap <Tab>K <C-w>k
noremap <Tab>H <C-w>h
noremap <Tab>L <C-w>l
  "window motion; makes sense so why not
nnoremap <Tab>, <C-w><C-p>
  "switch to last window
noremap <Tab>t <C-w>t
  "put current window into tab
noremap <Tab>n <C-w>w
" noremap <Tab><Tab>. <C-w>w
  "next; this may be most useful one
  "just USE THIS instead of switching windows directionally

"###############################################################################
"COPY/PASTING CLIPBOARD
augroup copypaste
augroup END
"###############################################################################
"PASTE STUFF
"Pastemode for pasting from clipboard; so no weird indents
"also still want to be able to insert LITERAL CHACTERS with C-v
"...first, declare it
"...and that's ALL WE WILL DO; had resorted before to this complicated stuff
"just so we could simultaneously toggle pasting with c-v and still use c-v
"for literal characters; just plain dumb
au InsertEnter * set pastetoggle=<C-v> "need to use this, because mappings don't work
    "when pastemode is toggled; might be able to remap <set paste>, but cannot return
    "to <set nopaste>
au InsertLeave * set pastetoggle=
au InsertLeave * set nopaste "if pastemode was toggled, turn off
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
"###############################################################################
"COPY STUFF
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

"###############################################################################
"FOLDING STUFF
augroup folds
augroup END
"SimpylFold settings
let g:SimpylFold_fold_docstring=0
let g:SimpylFold_fold_import=0
let g:SimpylFold_fold_docstrings=0
let g:SimpylFold_fold_imports=0
"Basic settings
set foldmethod=expr
set foldlevelstart=20
set nofoldenable
au BufRead * setlocal foldmethod=expr nofoldenable
  "options syntax, indent, manual (e.g. entering zf), marker
  "for some reason re-starting VIM session sets fold methods to manual; use
  "this to change it back
" au BufRead * setlocal nofoldenable
"   "disable/open all folds; do this by default when opening file
"   "need to use an autocmd because otherwise setting nofoldenable will only work
"   "on the PARTICULAR TAB on which we open up VIM
"More options
set foldopen=tag,mark
  "options for opening folds on cursor movement; disallow block,
  "i.e. percent motion, horizontal motion, insert, jump
set foldnestmax=10
  "avoids weird things
" set foldlevel=2
"   "by default only 2nd-level folds are collapsed
"Some maps
nnoremap z. za
  "toggle fold at cursor
nnoremap zD zd
  "'delete fold at cursor'
nnoremap zm <Nop>
nnoremap zr <Nop>
  "almost never need to use this
au BufRead * nnoremap <buffer> zC zM
au BufRead * nnoremap <buffer> zO zR
  "better pneumonics for these
  "means we open/close everything, seriously
"Changing fold level (increase, reduce)
" nnoremap zl :let b:position=winsaveview()<CR>zm:call winrestview(b:winfold)<CR>
" nnoremap zh :let b:position=winsaveview()<CR>zr:call winrestview(b:winfold)<CR>

"###############################################################################
"SINGLE-KEYSTROKE MOTION BETWEEN FUNCTIONS
"Single-keystroke indent, dedent, fix indentation
augroup onekeystroke
augroup END
if g:has_nowait
  nnoremap <nowait> > >>
  nnoremap <nowait> < <<
  nnoremap <nowait> = ==
endif
"Moving between functions, from: https://vi.stackexchange.com/a/13406/8084
"Must be re-declared every time enter file because g<stuff>, [<stuff>, and ]<stuff>
"may get re-mapped
if 1
  nnoremap <silent> <nowait> g gg
  vnoremap <silent> <nowait> g gg
  function! s:gmaps()
    " nmap <silent> <buffer> <nowait> g :<C-u>exe 'normal '.v:count.'gg'<CR>
    nmap <silent> <buffer> <nowait> g gg
    vmap <silent> <buffer> <nowait> g gg
      "don't know why this works, but it does; just using nnoremap above fails
      "and trying the <C-u> exe thing results in 'command too recursive'
  endfunction
  autocmd FileType * call s:gmaps()
  "And restore some useful 'g' commands
  noremap <Leader>i gi
  noremap <Leader>v gv
   "return to last insert location and visual location
endif
"Decided to disable the rest because sometimes find myself wanting to use other
"g-prefix commands and can make use of more complex [[ and ]] funcs
if 1
  nnoremap <silent> <nowait> [ [[
  nnoremap <silent> <nowait> ] ]]
  function! s:bracketmaps()
    if &ft!="help" "want to use [ for something else then
    nmap <silent> <buffer> <nowait> [ :exe 'normal '.v:count.'[['<CR>
    nmap <silent> <buffer> <nowait> ] :exe 'normal '.v:count.']]'<CR>
    endif
  endfunction
  autocmd FileType * call s:bracketmaps()
endif

"###############################################################################
"SPECIAL SYNTAX HIGHLIGHTING OVERWRITE (all languages; must come after filetype stuff)
augroup colors
augroup END
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
highlight CursorLineNR cterm=None ctermfg=Yellow ctermbg=Black
highlight LineNR cterm=None ctermfg=Black ctermbg=NONE
"Column stuff; color 80th column, and after 120
highlight ColorColumn cterm=None ctermbg=Black
highlight SignColumn cterm=None ctermbg=Black
"sign define hold text=\
"sign place 1 name=hold line=1
"###############################################################################
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

"###############################################################################
"###############################################################################
"EXIT
"###############################################################################
"###############################################################################
"silent! !echo 'Custom vimrc loaded.'
" au BufRead * clearjumps "forget the jumplist
  "do this so that we don't have stuff in plugin files and the vimrc populating
  "the jumplist when starting for the very first time
au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  "older versions of VIM have no clearjumps command, so this is a hack
  "see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
noh "run this at startup
echo 'Custom vimrc loaded.'
