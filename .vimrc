".vimrc
"------------------------------------------------------------------------------
" MOST IMPORTANT STUFF
" NOTE VIM SHOULD BE brew install'd WITHOUT YOUR ANACONDA TOOLS IN THE PATH; USE
" PATH="<original locations>" brew install ... AND EVERYTHING WORKS
" NOTE when you're creating a remap, `<CR>` is like literally pressing the Enter key,
" `\<CR>` is when you want to return a string whose result is like literally pressing
" the enter key e.g. in an <expr>, and `\<CR\>` is always a literal string containing `<CR>`.
"------------------------------------------------------------------------------
"BUTT-TONS OF CHANGES
augroup SECTION1 "a comment
augroup END
"------------------------------------------------------------------------------
"NOCOMPATIBLE -- changes other stuff, so must be first
set nocompatible
  "always use the vim default where vi and vim differ; for example, if you
  "put this too late, whichwrap will be resset
"------------------------------------------------------------------------------
"LEADER -- most important line
let mapleader = "\<Space>"
noremap <Space> <Nop>
noremap <CR> <Nop>
"------------------------------------------------------------------------------
"STANDARDIZE COLORS -- need to make sure background set to dark, and should be good to go
"See solution: https://unix.stackexchange.com/a/414395/112647
set background=dark
"------------------------------------------------------------------------------
"NO MORE SWAP FILES
"THIS IS DANGEROUS BUT I AM CONSTANTLY HITTING <CTRL-S> SO IS USUALLY FINE
set nobackup
set noswapfile
set noundofile
"------------------------------------------------------------------------------
"TAB COMPLETION OPENING NEW FILES
set wildignore=
set wildignore+=*.pdf,*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.o,*.mod
set wildignore+=*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4
set wildignore+=*.dmg,*.zip,*.sw[a-z],*.tmp,*.nc,*.DS_Store
  "never want to open these in VIM; includes GUI-only filetypes
  "and machine-compiled source code (.o and .mod for fortran, .pyc for python)
"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
"MOUSE SETTINGS
set mouse=a "mouse clicks and scroll wheel allowed in insert mode via escape sequences; these
if has('ttymouse') | set ttymouse=sgr | else | set ttymouse=xterm2 | endif
 "fail if you have an insert-mode remap of Esc; see: https://vi.stackexchange.com/q/15072/8084
"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
"DISABLE ANNOYING SPECIAL MODES/DANGEROUS ACTIONS
noremap K <Nop>
noremap Q <Nop>
  "the above 2 enter weird modes I don't understand...
noremap <C-z> <Nop>
noremap Z <Nop>
  "disable c-z and Z for exiting vim
set slm=
  "disable 'select mode' slm, allow only visual mode for that stuff
"-------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
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
noremap ` <Nop>
noremap " :echo "Setting mark q."<CR>mq
noremap ' `q
map s <Nop>
  "will use the s-prefix for SPELLING commands and SPELLCHECK stuff; never use
  "s for substitute anyway
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
" noremap <Right> ;
" noremap <Left> ,
"   "so i can still use the f, t stuff
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
"------------------------------------------------------------------------------
"REALLY BASIC NORMAL MODE/INSERT MODE STUFF
"CHANGE MOVEMENT (some options for presence of wrapped lines)
" noremap $ g$
" noremap 0 g0
  "go to visual line ends/starts
" noremap A g$a
" noremap I g^i
  "same for entering insert mode
  "don't do this because is awkward, and makes <C-v>I not work anymore
noremap H g^
noremap L g$geE
  "shortcuts for 'go to first char' and 'go to eol'
  "make these work for VISUAL movement
noremap m ge
noremap M gE
  "navigate by words
"BETTER NAVIGATION DEFAULTS
"Basic wrap-mode navigation, always move visually
"Still might occasionally want to navigate by lines though
noremap  k      gk
noremap  j      gj
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
"ROW/LINE MANIPULATION
"Unjoin lines/cut at cursor
" nnoremap <Leader>o mzA<CR><Esc>`z
" nnoremap <Leader>O mz<Up>A<CR><Esc>`z
nnoremap <Leader>o mzo<Esc>`z
nnoremap <Leader>O mzO<Esc>`z
"BETTER PNEUMONIC BEHAVIOR OF BASIC COMMANDS
"Better join behavior -- before 2J joined this line and next, now it
"means 'join the two lines below'; more intuitive. uses if statement
"in <expr> remap, and v:count the user input count
nnoremap <expr> J v:count > 1 ? 'JJ' : 'J'
nnoremap <expr> K v:count > 1 ? 'JdwJdw' : 'Jdw'
  "also remap K because not yet used; like J but adds no space
  "note gJ was insufficient because retains leading whitespace from next line
  "recall that the 'v' prefix indicated a VIM read-only builtin variable
"Yank, substitute, delete until end of current line
nnoremap Y y$
nnoremap D D
  "same behavior; NOTE use 'cc' instead to substitute whole line
nnoremap S s
  "restore use of substitute 's' key; then use s<stuff> for spellcheck
nnoremap vv ^v$gE
  "select the current 'line' of text; super handy
"NEAT IDEA FOR INSERT MODE REMAP; PUT CLOSING BRACES ON NEXT LINE
"Adapted from: https://blog.nickpierson.name/colemak-vim/
" inoremap (<CR> (<CR>)<Esc>ko
" inoremap {<CR> {<CR>}<Esc>ko
" inoremap ({<CR> ({<CR>});<Esc>ko
"-------------------------------------------------------------------------------
"SOME NORMAL MODE SPECIALTIES
nnoremap <C-c> <Nop>
nnoremap <Delete> <Nop>
nnoremap <Backspace> <Nop>
  "turns off common things in normal mode
  "also prevent Ctrl+c rining the bell
"-------------------------------------------------------------------------------
"SOME VISUAL MODE SPECIALTIES
"Cursor movement/scrolling while preserving highlights
"0) Need command-line ways to enter visual mode
"See answer: https://vi.stackexchange.com/a/3701/8084
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

"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
"LINE NUMBERING / NUMBERS IN TEXT
"Numbering
set number norelativenumber
"Basic maps
noremap <Leader>1 :setlocal number!<CR>
noremap <Leader>2 :setlocal relativenumber!<CR>
  "PREVIOUSLY had some NumberToggle algorithm; not necessary I think
"Incrementing numbers (C-x, C-a originally)
nnoremap <Leader>0 <C-x>
nnoremap <Leader>9 <C-a>h
  "for some reasons <C-a> by itself moves cursor to right; have to adjust
"------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
"-------------------------------------------------------------------------------
" COMPLICATED FUNCTIONS, MAPPINGS, FILETYPE MAPPINGS
"-------------------------------------------------------------------------------
"-------------------------------------------------------------------------------
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
" Plug 'vim-airline/vim-airline'
" Plug 'itchyny/lightline.vim'
" also consider vim-buftabline to use buffers instead
" Plug 'vim-scripts/EnhancedJumps'
  "provides commands for only jumping in the current file
  "actually seems to be BROKEN; forget it
if g:has_nowait | Plug 'tmhedberg/SimpylFold' | endif
Plug 'Konfekt/FastFold'
" Plug 'vim-scripts/matchit.zip'
  "this just points to a VimScript location; but have since edited this plugin
  "to not modify jumplist; so forget it
Plug 'scrooloose/nerdtree'
" Plug 'ctrlpvim/ctrlp.vim'
" Plug 'jistr/vim-nerdtree-tabs'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-obsession'
  "for session-saving functionality; mapped in my .bashrc vims to vim -S session.vim
  "and exiting vim saves the session there
" Plug 'tpope/vim-fugitive'
if g:compatible_tagbar | Plug 'majutsushi/tagbar' | endif
" Plug 'lifepillar/vim-mucomplete' "broken
" Plug 'Valloric/YouCompleteMe' "broken
" Plug 'ajh17/VimCompletesMe' "no auto-popup feature
if g:compatible_neocomplete | Plug 'shougo/neocomplete.vim' | endif
" if g:compatible_neocomplete | Plug 'ervandew/supertab' | endif
" if g:compatible_neocomplete | Plug 'davidhalter/jedi-vim' | endif "these need special support
" Plug 'vim-scripts/Toggle' "modified this myself
Plug 'tpope/vim-surround'
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
Plug 'metakirby5/codi.vim' "CODI appears to be broken, tried with other plugins disabled
" Plug 'Tumbler/highlightMarks' "modified this myself
Plug 'godlygeek/tabular'
Plug 'raimondi/delimitmate'
Plug 'gioele/vim-autoswap' "deals with swap files automatically
Plug 'triglav/vim-visual-increment' "visual incrementing
"The conda plugin is for changing anconda VIRTUALENV; probably don't need it
" Plug 'cjrh/vim-conda'
"Had issues with python plugins before; brew upgrading VIM fixed them magically
"Note you must choose between jedi-vim and python-mode; cannot use both! See github
" Plug 'ivanov/vim-ipython'
" Plug 'hdima/python-syntax' "does not seem to work
  "instead this function is put manually in syntax folder; vim-plug failed
" Plug 'klen/python-mode' "must make VIM compiled with anaconda for this to work
  "otherwise get weird errors; same with vim conda and vim ipython
call plug#end()
  "the plug#end also declares filetype syntax and indent on

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
"AIRLINE
" augroup airline
" augroup END
if has_key(g:plugs, "vim-airline")
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#tabline#formatter = 'default'
endif
if has_key(g:plugs, "lightline.vim")
  let g:lightline = { 'colorscheme': 'powerline' }
    " good ones: nord, PaperColor and PaperColor_dark (fave), OldHope, jellybeans,
    " and Tomorrow_Night, Tomorrow_Night_Eighties
endif

"-------------------------------------------------------------------------------
"DELIMITMATE (auto-generate closing delimiters)
augroup delimit
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

"-------------------------------------------------------------------------------
"SURROUND (place delimiters around stuff)
augroup surround
augroup END
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
"First a helper function
"Make cc behavior more intuitively for visual selection
"Just like change line in normal mode
vnoremap cc s
"Helper function for building my own
function! s:surround(original,new)
  "Function simply matches these builtin VIM methods with a new delimiter-identifier
  exe 'nnoremap da'.a:original.' da'.a:new
  exe 'nnoremap di'.a:original.' di'.a:new
  exe 'nnoremap ca'.a:original.' ca'.a:new
  exe 'nnoremap ci'.a:original.' ci'.a:new
  exe 'nnoremap ya'.a:original.' ya'.a:new
  exe 'nnoremap yi'.a:original.' yi'.a:new
  exe 'nnoremap <silent> va'.a:original.' :let b:v_mode="v"<CR>va'.a:new
  exe 'nnoremap <silent> vi'.a:original.' :let b:v_mode="v"<CR>vi'.a:new
endfunction
function! s:delims(map,left,right,...)
  "Function for adding ;-prefixed fancy delimiters, especially useful in LaTeX
  "First extra argument is whether map is buffer-local, second is optional override
  let a:offset = 0
  let a:prefix = ';'
  let a:extra = (a:0==2) ? a:2 : 0
  if type(a:extra)==type(0)
    let a:offset = a:extra
  else
    let a:prefix = a:extra
  endif
  if a:right =~ "|" "need special consideration when doing | maps
    let a:offset += 1
  endif
  let a:buffer = (a:0==1 || a:0==2) ? "<buffer>" : ""
  exe 'inoremap '.a:buffer.' '.a:prefix.a:map.' '.a:left.a:right.repeat('<Left>',len(a:right)-a:offset)
  exe 'nnoremap '.a:buffer.' '.a:prefix.a:map.' mzlbi'.a:left.'<Esc>hea'.a:right.'<Esc>`z'
  exe 'vnoremap '.a:buffer.' '.a:prefix.a:map.' <Esc>`>a'.a:right.'<Esc>`<i'.a:left.'<Esc>'.repeat('<Left>',len(a:left)-1-a:offset)
endfunction
function! s:delimscr(map,left,right,...)
  exe 'inoremap <buffer> ,'.a:map.' '.a:left.'<CR>'.a:right.'<Up><End><CR>'
  exe 'vnoremap <buffer> ,'.a:map.' <Esc>`>a<CR>'.a:right.'<Esc>`<i'.a:left.'<CR><Esc><Up><End>'.repeat('<Left>',len(a:left)-1)
endfunction
"Capitalization stuff in familiar syntax
noremap ;; ;
nnoremap ~ ~h
nnoremap ;u guiw
vnoremap ;u gu
nnoremap ;U gUiw
vnoremap ;U gU
"Quick function selection for stuff formatted like function(text)
"For functions the select/delete 'inner' stuff is already satisfied
nnoremap daf mzF(bdt(lda(`z
nnoremap dsf mzF(bdt(xf)x`z
nnoremap caf F(bdt(lca(
nnoremap <expr> csf 'mzF(bct('.input('Enter new function name: ').'<Esc>`z'
nnoremap yaf mzF(bvf(%y`z
nnoremap <silent> vaf F(bvf(%
"For selecting text in-between commented out lines
nnoremap <expr> vic "/^\\s*".b:NERDCommenterDelims['left']."<CR><Up>$vN<Down>0<Esc>:noh<CR>gv"
"More advanced 'delimiters' and aliases for creating delimiters
call s:delims('p', 'print(', ')')
call s:delims('b', '(', ')')
call s:delims('B', '{', '}')
call s:delims('r', '[', ']')
call s:delims('a', '<', '>')
call s:delims("'", "'", "'")
call s:delims('"', '"', '"')
call s:delims('$', '$', '$')
call s:delims('*', '*', '*')
call s:delims('`', '`', '`')
call s:delims('~', '“', '”')
"Match the VIM builtins like di[ etc. to SURROUND syntax used for csr etc.
for s in ["r[", "a<"] "most simple ones
  call s:surround(s[0], s[1])
endfor

"-------------------------------------------------------------------------------
"LATEX MACROS, lots of insert-mode stuff
"IDEA STEMMED FROM THE ABOVE: MAKE SHORTCUTS TO ys<stuff> WITH FEWER KEYSTROKES
"ANYWAY THE ORIGINAL PNEUMONIC FOR SURROUND.VIM "ys" KIND OF SUCKS
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
  call s:delims('\|', '\left\|', '\right\|', 1)
  call s:delims('{', '\left\{', '\right\}', 1)
  call s:delims('(', '\left(', '\right)', 1)
  call s:delims('[', '\left[', '\right]', 1)
  call s:delims('<', '\left<', '\right>', 1)
  call s:delims('o', '{\color{red}', '}', 1)
  call s:delims('t', '\textbf{', '}', 1)
  call s:delims('T', '\emph{', '}', 1) "for beamer
  call s:delims('y', '\texttt{', '}', 1) "typewriter text
  call s:delims('i', '\textit{', '}', 1)
  call s:delims('l', '\underline{', '}', 1) "l for line
  call s:delims('m', '\mathrm{', '}', 1)
  call s:delims('n', '\mathbf{', '}', 1)
  call s:delims('M', '\mathcal{', '}', 1)
  call s:delims('N', '\mathbb{', '}', 1)
  call s:delims('v', '\vec{', '}', 1)
  call s:delims('V', '\verb$', '$', 1) "verbatim
  call s:delims('d', '\dot{', '}', 1)
  call s:delims('D', '\ddot{', '}', 1)
  call s:delims('h', '\hat{', '}', 1)
  call s:delims('`', '\tilde{', '}', 1)
  call s:delims('-', '\overline{', '}', 1)
  call s:delims('\', '\cancelto{}{', '}', 1)
  call s:delims('x', '\boxed{', '}', 1)
  call s:delims('X', '\fbox{\parbox{\textwidth}{', '}}\medskip', 1) "don't remember this one
  call s:delims('/', '\sqrt{', '}', 1)
  call s:delims('q', '`', "'", 1)
  call s:delims('Q', '``', "''", 1)
  call s:delims('$', '$', '$', 1)
  call s:delims('e', '\times10^{', '}', 1)
  call s:delims('k', '^{', '}', 1)
  call s:delims('j', '_{', '}', 1)
  call s:delims('K', '\overset{}{', '}', 1)
  call s:delims('J', '\underset{}{', '}', 1)
  call s:delims('f', '\dfrac{', '}{}', 1)
  call s:delims('0', '\frametitle{', '}', 1)
  call s:delims('1', '\section{', '}', 1)
  call s:delims('2', '\subsection{', '}', 1)
  call s:delims('3', '\subsubsection{', '}', 1)
  call s:delims('4', '\section*{', '}', 1)
  call s:delims('5', '\subsection*{', '}', 1)
  call s:delims('6', '\subsubsection*{', '}', 1)
  "Shortcuts for citations and such
  call s:delims('7', '\ref{', '}', 1) "just the number
  call s:delims('8', '\autoref{', '}', 1) "name and number; autoref is part of hyperref package
  call s:delims('9', '\label{', '}', 1) "declare labels that ref and autoref point to
  call s:delims('*', '\tag{', '}', 1) "change the default 1-2-3 ordering; common to use *
  call s:delims('z', '\note{', '}', 1) "extra
  call s:delims('Z', '\strikeout{', '}', 1) "extra
  call s:delims('a', '\caption{', '}', 1) "amazingly a not used yet
  call s:delims('c', '\cite{', '}', 1) "most common
  call s:delims('C', '\citet{', '}', 1) "second most common one
    "other stuff like citenum/citep (natbib) and textcite/authorcite (biblatex) must be done manually
  "Shortcut for graphics
  call s:delims('g', '\includegraphics[width=\textwidth]{', '}', 1)
  call s:delims('G', '\makebox[\textwidth][c]{\includegraphics[width=\textwidth]{', '}}', 1) "center across margins
  " call s:delims('G', '\vcenteredhbox{\includegraphics[width=\textwidth]{', '}}', 1) "use in beamer talks
  "Comma-prefixed delimiters without newlines
  "Generally are more closely-related to the begin-end latex environments
  call s:delims('1', '{\tiny ', '}', 1, ',')
  call s:delims('2', '{\scriptsize ', '}', 1, ',')
  call s:delims('3', '{\footnotesize ', '}', 1, ',')
  call s:delims('4', '{\small ', '}', 1, ',')
  call s:delims('5', '{\normalsize ', '}', 1, ',')
  call s:delims('6', '{\large ', '}', 1, ',')
  call s:delims('7', '{\Large ', '}', 1, ',')
  call s:delims('8', '{\LARGE ', '}', 1, ',')
  call s:delims('9', '{\huge ', '}', 1, ',')
  call s:delims('0', '{\Huge ', '}', 1, ',')
  call s:delims('{', '\left\{\begin{matrix}[ll]', '\end{matrix}\right.', 1, ',')
  call s:delims('P', '\begin{pmatrix}', '\end{pmatrix}', 1, ',')
  call s:delims('B', '\begin{bmatrix}', '\end{bmatrix}', 1, ',')
  "Versions of the above, but this time puting them on own lines
  " call s:delimscr('P', '\begin{pmatrix}', '\end{pmatrix}')
  " call s:delimscr('B', '\begin{bmatrix}', '\end{bmatrix}')
  "Comma-prefixed delimiters with newlines
  "Many of these important for beamer presentations
  "The onlytextwidth option keeps two-columns (any arbitrary widths) aligned
  "with default single column; see: https://tex.stackexchange.com/a/366422/73149
  "Use command \rule{\textwidth}{<any height>} to visualize blocks/spaces in document
  call s:delimscr(';', '\begin{center}', '\end{center}') "because ; was available
  call s:delimscr('c', '\begin{columns}[t,onlytextwidth]', '\end{columns}')
  call s:delimscr('C', '\begin{column}{.5\textwidth}', '\end{column}')
  call s:delimscr('i', '\begin{itemize}', '\end{itemize}')
  call s:delimscr('I', '\begin{enumerate}[label=\roman*.]', '\end{enumerate}')
  call s:delimscr('n', '\begin{enumerate}', '\end{enumerate}')
  call s:delimscr('N', '\begin{enumerate}[label=\alph*.]', '\end{enumerate}')
  call s:delimscr('d', '\begin{description}', '\end{description}')
  call s:delimscr('t', '\begin{tabular}', '\end{tabular}')
  call s:delimscr('e', '\begin{equation*}', '\end{equation*}')
  call s:delimscr('a', '\begin{align*}', '\end{align*}')
  call s:delimscr('E', '\begin{equation}', '\end{equation}')
  call s:delimscr('A', '\begin{align}', '\end{align}')
  call s:delimscr('s', '\begin{frame}', '\end{frame}')
  call s:delimscr('m', '\begin{minipage}{\linewidth}', '\end{minipage}')
  call s:delimscr('f', '\begin{figure}', '\end{figure}')
  call s:delimscr('F', '\begin{subfigure}{.5\textwidth}', '\end{subfigure}')
  call s:delimscr('w', '\begin{wrapfigure}{r}{.5\textwidth}', '\end{wrapfigure}')
  "Single-character maps
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

"-------------------------------------------------------------------------------
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
  call s:delims('e', '<em>', '</em>', 1, ',')
  call s:delims('t', '<strong>', '</strong>', 1, ',')
endfunction
"Toggle mappings
autocmd FileType html call s:htmlmacros()

"-------------------------------------------------------------------------------
"SPELLCHECK (really is a BUILTIN plugin)
augroup spell
augroup END
"Off by default
"Turn on for certain filetypes
set nospell spelllang=en_us spellcapcheck=
autocmd FileType tex,html,xml,text,markdown setlocal spell
"Toggle on and off
nnoremap ss :setlocal spell!<CR>
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
nnoremap sn [s
nnoremap sN ]s
"Get suggestions, or choose first suggestion without looking
nnoremap s. z=1<CR><CR>
nnoremap sd z=
"Add/remove from dictionary
nnoremap sa zg
nnoremap sr zug

"-------------------------------------------------------------------------------
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
  noremap <buffer> <expr> QD ":!clear; set -x; pydoc "
        \.input("Enter python documentation keyword: ")."<CR>"
  noremap <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."python ".shellescape(@%)."<CR>"
  inoremap <buffer> <expr> <C-x> "<Esc>:w<CR>:!clear; set -x; "
        \."python ".shellescape(@%)."<CR>a"
endfunction
"Toggle mappings with autocmds...or disable because they suck for now
autocmd FileType python call s:pymacros()
"Skeleton-code templates...decided that's unnecessary for python
" autocmd BufNewFile *.py 0r ~/skeleton.py
"-------------------------------------------------------------------------------
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
"-------------------------------------------------------------------------------
"VIM python-mode
if has_key(g:plugs, "python-mode")
  let g:pymode_python='python3'
endif
"-------------------------------------------------------------------------------
"PYTHON-SYNTAX; these should be provided with VIM by default
au FileType python let g:python_highlight_all=1

"-------------------------------------------------------------------------------
"C MACROS
augroup c
augroup END
function! s:cmacros()
  "Will compile code, then run it and show user the output
  noremap  <buffer> <expr> <C-x> ":w<CR>:!clear; set -x; "
        \."gcc ".shellescape(@%)." -o ".expand('%:r')."; ./".expand('%:r')."<CR>"
endfunction
autocmd FileType c call s:cmacros()

"-------------------------------------------------------------------------------
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
let fortran_fold=1
let fortran_free_source=1
let fortran_more_precise=1

"-------------------------------------------------------------------------------
"NCL COMPLECTION
augroup ncl
augroup END
" set complete-=k complete+=k " Add dictionary search (as per dictionary option)
" au BufRead,BufNewFile *.ncl set dictionary=~/.vim/words/ncl.dic
au FileType * execute 'setlocal dict+=~/.vim/words/'.&ft.'.dic'
  "can put other stuff here; right now this is just for the NCL dict for NCL

"-------------------------------------------------------------------------------
"SHELL MACROS
"MANPAGES of stuff
" augroup shell
" augroup END
" noremap <expr> QM ":silent !clear; man "
"     \.input('Search manpages: ')."<CR>:redraw!<CR>"
" "--help info; pipe output into less for better interaction
" noremap <expr> QH ":!clear; "
"     \.input('Show --help info: ')." --help \| less<CR>:redraw!<CR>"

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
"CODI (MATHEMATICAL NOTEPAD)
augroup codi
augroup END
if has_key(g:plugs, "codi.vim")
  nnoremap <silent> <expr> <Leader>m ':Codi '.&ft.'<CR>'
    "turns current file into calculator; m stands for math
  nnoremap <silent> <expr> <Leader>M ':tabe '.input('Enter calculator name: ').'.py<CR>:Codi python<CR>'
    "turns
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20
endif

"-------------------------------------------------------------------------------
"HOWMUCH (SUMMING TABLE ELEMENTS)
"NO LONGER CONTROLLED BY PLUGIN MANAGER
augroup howmuch
augroup END
let g:HowMuch_auto_engines=['py', 'bc'] "python engine uses from math import *
let g:HowMuch_scale=3 "precision
" if has_key(g:plugs, "HowMuch")
"   "default maps are <Leader>?
" endif

"-------------------------------------------------------------------------------
"MUCOMPLETE
augroup mucomplete
augroup END
if has_key(g:plugs, "vim-mucomplete") "just check if activated
  let g:mucomplete#enable_auto_at_startup = 1
  let g:mucomplete#no_mappings = 1
  let g:mucomplete#no_popup_mappings = 1
endif

"-------------------------------------------------------------------------------
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
  "-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
"CURRENT DIRECTORY
"First of all match VIM 'current directory' to the file current directory; allows
"us e.g. to use git commands on files on the fly
" autocmd BufEnter * lcd %:p:h "messes up session restore
"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
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
      \."mzo<Esc>".col('.')."a<Space><Esc>xA".b:NERDCommenterDelims['left']."<Esc>".eval(79-col('.')+1)."a-<Esc>`z"
  nnoremap <expr> c_ ""
      \.""
      \."mzo<Esc>".col('.')."a<Space><Esc>x".eval(80-col('.')+1)."a".b:NERDCommenterDelims['left']."<Esc>`z"
  "Create python docstring
  nnoremap c' o'''<CR>.<CR>'''<Up><Esc>A<BS>
  nnoremap c" o"""<CR>.<CR>"""<Up><Esc>A<BS>
  " nnoremap c\| ox<BS><CR>x<BS><CR>x<BS><Esc>:call NERDComment('n', 'toggle')<CR>078a-<Esc><Up><Up>:call NERDComment('n', 'toggle')<CR>078a-<Esc><Down>:call NERDComment('n', 'toggle')<CR>0a<Space>
  "Set up custom remaps
  nnoremap co :call NERDComment('n', 'comment')<CR>
  nnoremap cO :call NERDComment('n', 'uncomment')<CR>
  nnoremap c. :call NERDComment('n', 'toggle')<CR>
  nnoremap c<CR> <Nop>
  vnoremap co :call NERDComment('v', 'comment')<CR>
  vnoremap cO :call NERDComment('v', 'uncomment')<CR>
  vnoremap c. :call NERDComment('v', 'toggle')<CR>
  vnoremap c<CR> s
  "common to want to select-then-change text
endif

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
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
        " normal! gg
        " while 1
        "   let a:line=search(g:tagbar#icon_open,"W","$")
        "   if empty(a:line)
        "     break
        "   endif
        "   exec "normal! ".a:line."gg"
        "   normal -
        " endwhile
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
      nmap <expr> <buffer> <Leader><Space> "/".input("Travel to this tagname regex: ")."<CR>:noh<CR><CR>"
    endif
  endfunction
  nnoremap <silent> <Tab>k :call <sid>tagbarsetup()<CR>
  nmap <expr> <Space><Space> ":TagbarOpen<CR><C-w>l/".input("Travel to this tagname regex: ")."<CR>:noh<CR><CR>"
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

"-------------------------------------------------------------------------------
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

"-------------------------------------------------------------------------------
"TABULAR - ALIGNING AROUND :,=,ETC.
augroup tabular
augroup END
if has_key(g:plugs, "tabular")
  "NOTE: e.g. for aligning text after colons, input character :\zs; aligns
  "first character after matching preceding character
  vnoremap <expr> -t ':Tabularize /'.input('Align character: ').'<CR>'
  nnoremap <expr> -t ':Tabularize /'.input('Align character: ').'<CR>'
    "arbitrary character
  vnoremap <expr> -c ':Tabularize /^\s*\S.*\zs'.b:NERDCommenterDelims['left'].'<CR>'
  nnoremap <expr> -c ':Tabularize /^\s*\S.*\zs'.b:NERDCommenterDelims['left'].'<CR>'
    "by comment character; ^ is start of line, . is any char, .* is any number, \\zs
    "is start match here (must escape backslash), then search for the comment
  vnoremap <expr> -C ':Tabularize /^.*\zs'.b:NERDCommenterDelims['left'].'<CR>'
  nnoremap <expr> -C ':Tabularize /^.*\zs'.b:NERDCommenterDelims['left'].'<CR>'
    "by comment character, but instead don't ignore comments on their own line
  nnoremap -, :Tabularize /,\zs/l0r1<CR>
  vnoremap -, :Tabularize /,\zs/l0r1<CR>
    "suitable for diag_table's in models
  vnoremap <expr> -<Space> ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
  nnoremap <expr> -<Space> ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
    "check out documentation on \@<! atom; difference between that and \@! is that \@<!
    "checks whether something doesn't match *anywhere before* what follows
    "also the \S has to come before the \(\) atom instead of after for some reason
  "TODO: Note the above still has limitations due to Tabularize behavior; if have
  "  a b c d e f
  "  a b # a comment
  "the c/d/e/f will be pushed past the comment since the b and everything that follows
  "are considered part of the same delimeted field. just make sure lines with comments
  "are longer than the lines we actually want to align
  vnoremap -- :Tabularize /^[^=]*\zs=<CR>
  nnoremap -- :Tabularize /^[^=]*\zs=<CR>
  vnoremap -= :Tabularize /^[^=]*\zs=\zs<CR>
  nnoremap -= :Tabularize /^[^=]*\zs=\zs<CR>
    "align assignments, and keep equals signs on the left; only first equals sign
  vnoremap -d :Tabularize /:\zs<CR>
  nnoremap -d :Tabularize /:\zs<CR>
    "align colon table, and keeps colon on the left; the zs means start match **after** colon
endif

"-------------------------------------------------------------------------------
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
".1) we haven't already loaded an available non-default file using ftplugin or
"2) there is no alternative file loaded by the ftplugin function

"------------------------------------------------------------------------------
"------------------------------------------------------------------------------
" GENERAL STUFF, BASIC REMAPS
"------------------------------------------------------------------------------
"------------------------------------------------------------------------------
augroup SECTION3
augroup END
"------------------------------------------------------------------------------
"BUFFER WRITING/SAVING
augroup saving
augroup END
nnoremap <C-s> :w!<CR>
  "use force write, in case old version exists
" inoremap <C-s> <Esc>:w<CR>a
au FileType help nnoremap <buffer> <C-s> <Nop>
nnoremap <C-q> :tabclose<CR>
nnoremap <C-a> :qa<CR>
" inoremap <C-q> <Esc>:q<CR>a

"------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
"SEARCHING
augroup searching
augroup END
"Basics; (showmode shows mode at bottom [default I think, but include it],
"incsearch moves to word as you begin searching with '/' or '?')
set hlsearch incsearch
  "show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase
au InsertEnter * set noignorecase
au InsertLeave * set ignorecase
  "smartcase makes search case insensitive, unless has capital letter
"Keep */# case-sensitive while '/' and '?' are smartcase case-insensitive
"Optional idea here to make # search by character
nnoremap <silent> * :let @/='\C\<'.expand('<cword>').'\>'<CR>:set hlsearch<CR>:let v:searchforward=1<CR>
nnoremap <silent> # :let @/='\C\<'.expand('<cword>').'\>'<CR>:set hlsearch<CR>:let v:searchforward=0<CR>
" nnoremap <silent> # :let b:position=winsaveview()<CR>xhp/<C-R>-<CR>N:call winrestview(b:position)<CR>
"------------------------------------------------------------------------------
"SPECIAL SEARCHING
"FIND AND REPLACE STUFF
" * Search func idea came from: http://vim.wikia.com/wiki/Search_in_current_function
" * Note jedi-vim 'variable rename' is sketchy and fails; should do my own
"   renaming, and do it by confirming every single instance
" * Below is copied from: https://stackoverflow.com/a/597932/4970632
" * This failed, BECAUSE gd 'goto definition where var declared' doesn't work in hello often
nnoremap <Leader>z /\<[A-Z]\+\><CR>
  "search all capital words
function! s:scopesearch(replace)
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
      return printf('%d,%ds', a:first-1, a:last+1)
        "simply the range for a :search and replace command
    else
      return printf('\%%>%dl\%%<%dl', a:first-1, a:last+1)
        "%% is literal % character, and backslashes do nothing inside
        "single-quotes (different story for double quotes)
        "check out documentation on %l atom for VIM regexes
    endif
  else
    return "\b"
      "backspace, because we failed, so forget the range limitation
  endif
endfunction
"Declare maps differently depending on file; for python almost always will
"want to search within-file for something
"* For that scopesearch function it is annoying to see entire line-selection
"  light up, so delay implementation of the map by waiting for user to input
"  first SUBSEQUENT character.
" nnoremap <Leader>f /
" nnoremap <Leader>F ?
" function! s:pythonmaps()
"   nnoremap <expr> <buffer> / '/<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>'.nr2char(getchar())
"   nnoremap <expr> <buffer> ? '?<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>'.nr2char(getchar())
"   nnoremap <buffer> <Leader>/ /
"   nnoremap <buffer> <Leader>? ?
"   nnoremap <buffer> <Leader>s :<C-r>=<sid>scopesearch(1)<CR>/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
"   nnoremap <buffer> <Leader>S :%s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
" endfunction
" au FileType python call s:pythonmaps()
" nnoremap <Leader>/ /<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>
" nnoremap <Leader>? ?<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>
nnoremap <expr> <Leader>/ '/<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>'.nr2char(getchar())
nnoremap <expr> <Leader>? '?<C-r>=<sid>scopesearch(0)<CR><CR>/<Up>'.nr2char(getchar())
nnoremap <Leader>r :%s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
nnoremap <Leader>R :<C-r>=<sid>scopesearch(1)<CR>/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
  "the <C-r> means paste from the expression register i.e. result of following expr
nnoremap <Leader>d :%s///gIc<Left><Left><Left><Left><Left>
nnoremap <Leader>D :<C-r>=<sid>scopesearch(1)<CR>///gIc<Left><Left><Left><Left><Left>
  "similar but delete stuff instead
" nnoremap <Leader>D :%s/<C-r>///gn<CR>
" nnoremap <Leader>s gd[{V%::s/<C-R>///gc<left><left><left>
" nnoremap <Leader>S gD:%s/<C-R>///gc<left><left><left>
  "first one searches current scope, second one parent-level scope
"Changing variables in the scope of function (small s) or globally (big S)
  "need recursion, because BUILTIN FTPLUGIN FUNCTIONATLIY remaps [[ and ]]
  "see: https://github.com/vim/vim/blob/master/runtime/ftplugin/python.vim
"Changing variable from current location to document end or before document
" nnoremap <Leader>/ :.,$s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
" nnoremap <Leader>? :0,.s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
  "use 'I' because WANT CASE-SENSITIVE SUBSTITUTIONS, INSENSITIVE SEARCHES
  "use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on
  "blank lines; also the 'c' means 'confirm' each replacement
"-------------------------------------------------------------------------------
"SPECIAL DELETION TOOLS
"see https://unix.stackexchange.com/a/12814/112647 for idea on multi-empty-line map
" au FileType bib nnoremap <buffer> <Leader>X :g/^\s*\(abstract\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=/d<CR>
" nnoremap <Leader>x :g//d<Left><Left>
nnoremap <Leader>q :s/\(^ *\)\@<! \{2,}/ /g<CR>
  "replace consecutive spaces on current line
nnoremap <Leader>Q :%s/\(\n\n\)\n\+/\1/gc<CR>
  "replace consecutive newlines with single newline
" nnoremap <expr> <Leader>X ':%s/^\s*'.b:NERDCommenterDelims['left'].'.*$\n//gc<CR>'
nnoremap <Leader>x :%s/\s\+$//g<CR>
vnoremap <Leader>x :s/\s\+$//g<CR>
  "replace trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
nnoremap <expr> <Leader>X ':%s/\(^\s*'.b:NERDCommenterDelims['left'].'.*$\n'
      \.'\\|^.*\S*\zs\s\+'.b:NERDCommenterDelims['left'].'.*$\)//gc<CR>'
  "replace commented lines
function! s:cutmaps()
  nnoremap <buffer> <Leader>b :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=.*$\n//gc<CR>
endfunction
au FileType bib,tex call s:cutmaps()
  "some bibtex lines

"------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
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
" noremap <Tab>J <C-w>j
" noremap <Tab>K <C-w>k
" noremap <Tab>H <C-w>h
" noremap <Tab>L <C-w>l
nnoremap <Tab>, <C-w><C-p>
  "switch to last window
noremap <Tab>t <C-w>t
  "put current window into tab
noremap <Tab>n <C-w>w
" noremap <Tab><Tab>. <C-w>w
  "next; this may be most useful one
  "just USE THIS instead of switching windows directionally

"------------------------------------------------------------------------------
"COPY/PASTING CLIPBOARD
augroup copypaste
augroup END
"-------------------------------------------------------------------------------
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
"-------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
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
  " noremap <Leader><Space> `.
  "   "location of last edit is there
  noremap <Leader>i gi
  noremap <Leader>v gv
   "return to last insert location and visual location
endif
"Decided to disable the rest because sometimes find myself wanting to use other
"g-prefix commands and can make use of more complex [[ and ]] funcs
if 0
  nnoremap <silent> <nowait> [ [[
  nnoremap <silent> <nowait> ] ]]
  function! s:bracketmaps()
    if &ft!="help" "want to use [ for something else then
    nmap <silent> <buffer> <nowait> [ :<C-u>exe 'normal '.v:count.'[['<CR>
    nmap <silent> <buffer> <nowait> ] :<C-u>exe 'normal '.v:count.']]'<CR>
    endif
  endfunction
  autocmd FileType * call s:bracketmaps()
endif

"------------------------------------------------------------------------------
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
"------------------------------------------------------------------------------
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

"------------------------------------------------------------------------------
"------------------------------------------------------------------------------
"EXIT
"------------------------------------------------------------------------------
"------------------------------------------------------------------------------
"silent! !echo 'Custom vimrc loaded.'
" au BufRead * clearjumps "forget the jumplist
  "do this so that we don't have stuff in plugin files and the vimrc populating
  "the jumplist when starting for the very first time
au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  "older versions of VIM have no clearjumps command, so this is a hack
  "see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
noh "run this at startup
echo 'Custom vimrc loaded.'
