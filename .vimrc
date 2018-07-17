".vimrc
"###############################################################################
" * Tab-prefix
" * Note vim should be brew install'd without your anaconda tools in the path; use
"   PATH="<original locations>" brew install
" * Note when you're creating a remap, `<CR>` is like literally pressing the Enter key,
"   while `\<CR>` inside a double-quote string is that literal keypress
" * Currently have iTerm map some ctrl+key combinations that would otherwise
"   be impossible to the F1, F2 keys. Currently they are:
"     F1: Ctrl-,
"     F2: Ctrl-.
"     F3: Ctrl-i
"###############################################################################
"IMPORTANT STUFF
"Says to always use the vim default where vi and vim differ; for example, if you
"put this too late, whichwrap will be reset
set nocompatible
let mapleader="\<Space>"
"Misc stuff
noremap <CR> <Nop>
noremap <Space> <Nop>
noremap <C-b> <Nop>
"The above 2 enter weird modes I don't understand...
noremap Q <Nop>
noremap K <Nop>
cnoremap <C-k> <Up>
cnoremap <C-j> <Down>
"Disable c-z and Z for exiting vim
noremap <C-z> <Nop>
noremap Z <Nop>
"See solution: https://unix.stackexchange.com/a/414395/112647
set slm= "disable 'select mode' slm, allow only visual mode for that stuff
set background=dark "standardize colors -- need to make sure background set to dark, and should be good to go
"Repeat previous command
nnoremap <Leader>: :<Up><CR>
nnoremap <Leader>? /<Up><CR>
set updatetime=1000 "used for CursorHold autocmds
set nobackup noswapfile noundofile "no more swap files; constantly hitting C-s so it's safe
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·
"other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
"Older versions can't combine number with relativenumber
set number numberwidth=4
set relativenumber
"Disable builtin, because we modified that shit yo
let g:loaded_matchparen=0

"###############################################################################
"ESCAPE REPAIR WHEN ENABLING H/L TO CHANGE LINE NUMBER
"First some functions and autocmds
"Let h, l move past end of line (<> = left/right insert, [] = left/right normal mode)
set whichwrap=[,],<,>,h,l
augroup escapefix
  au!
  au InsertLeave * normal! `^
augroup END

"##############################################################################"
"ALWAYS NAVIGATE BY word, GOT DAMNIT
"See: https://superuser.com/a/1150645/506762
"Some plugins make periods part of 'word' motions, which sucks balls
augroup keywordfix
  au!
  au BufEnter * set iskeyword=65-90,95,97-122,48-57 "the same: a-z,_,A-Z,0-9
augroup END

"###############################################################################
"USEFUL TOOLS THAT REQUIRE THEIR OWN FUNCTIONS
"Function for escaping current delimiter
" * Use my own instead of delimitmate defaults because e.g. <c-g>g only works
"   if no text between delimiters.
function! s:outofdelim(n) "get us out of delimiter cursos is inside
  for i in range(a:n)
    let pcol=col('.')
    let pline=line('.')
    keepjumps normal! %
    if pcol!=col('.') || pline!=line('.')
      keepjumps normal! %
    endif "only do the above if % moved the cursor
    if i+1!=a:n && col('.')+1!=col('$')
      normal! l
    endif
  endfor
endfunction
"Function for counting word under cursor
"Fails for mysterious reason
"See: https://stackoverflow.com/questions/1781329/count-the-number-of-occurrences-of-a-string-using-sed
" function! s:countcword(word)
"   redir => cnt
"     silent exe '%s/'.a:word.'//gn'
"   redir END
"   let res = strpart(cnt, 0, stridx(cnt, " "))
"   return res
" endfunction
" nnoremap <expr> <Leader>w 'mz:let b:count=<sid>countcword("'.expand('<cword>').'")<CR>`z'
"Try again with grep; way easier
nnoremap <silent> <expr> <Leader>w ':let b:count=system("grep -c \"\\b'.expand('<cword>').'\\b\" '.expand('%').'")<CR>:echo b:count[:-2]<CR>'

"###############################################################################
"INSERT MODE MAPS, IN CONTEXT OF POPUP MENU AND FOR 'ESCAPING' DELIMITER
augroup insertenter
  au!
  au InsertEnter * let b:insertenter=[line('.'), col('.')]
augroup END
"Simple maps first
inoremap <expr> <C-u> '<Esc>u:call cursor('.b:insertenter[0].','.b:insertenter[1].')<CR>a'
inoremap <C-p> <C-r>"
"Next popup manager; will count number of tabs in popup menu so our position is always known
augroup popuphelper
  au!
  au BufEnter * let b:tabcount=0
  au InsertEnter * let b:tabcount=0
augroup END
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
cnoremap <C-j> <Tab>
cnoremap <C-k> <S-Tab>
inoremap <expr> <C-c> pumvisible() ? "\<C-e>\<Esc>" : "\<Esc>"
inoremap <expr> <Space> pumvisible() ? "\<Space>".<sid>tabreset() : "\<Space>"
inoremap <expr> <BS> pumvisible() ? "\<C-e>\<BS>".<sid>tabreset() : "\<BS>"
inoremap <expr> <Tab> pumvisible() ? <sid>tabincrease()."\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? <sid>tabdecrease()."\<C-p>" : "\<BS>"
inoremap <expr> <C-j> pumvisible() ? <sid>tabincrease()."\<C-n>" : "\<Nop>"
inoremap <expr> <C-k> pumvisible() ? <sid>tabdecrease()."\<C-p>" : "\<Nop>"
inoremap <expr> <CR> pumvisible() ? b:tabcount==0 ? "\<C-e>\<CR>" : "\<C-y>".<sid>tabreset() : "\<CR>"
inoremap <expr> <ScrollWheelDown> pumvisible() ? <sid>tabincrease()."\<C-n>" : "\<ScrollWheelDown>"
inoremap <expr> <ScrollWheelUp> pumvisible() ? <sid>tabdecrease()."\<C-p>" : "\<ScrollWheelUp>"
"Now the commands that 'get cursor outside' of arbitrary delimiters
inoremap <expr> jk pumvisible() ? b:tabcount==0 ? "\<C-e>\<Esc>:call <sid>outofdelim(1)\<CR>a" :
  \ "\<C-y>\<Esc>:call <sid>outofdelim(1)\<CR>a" : "\<Esc>:call <sid>outofdelim(1)\<CR>a"
inoremap <expr> JK pumvisible() ? b:tabcount==0 ? "\<C-e>\<Esc>:call <sid>outofdelim(10)\<CR>a" :
  \ "\<C-y>\<Esc>:call <sid>outofdelim(10)\<CR>a" : "\<Esc>:call <sid>outofdelim(10)\<CR>a"
inoremap jj j
inoremap kk k

"###############################################################################
"CHANGE/ADD PROPERTIES/SHORTCUTS OF VERY COMMON ACTIONS
"MOSTLY NORMAL MODE MAPS
"First need helper function to toggle formatoptions (controls whether comment-char 
"inserted on newline)
" * See help fo-table for what these mean; this disables auto-wrapping lines.
" * The o and r options continue comment lines.
" * The n recognized numbered lists.
" * Note in the documentation, formatoptions is *local to buffer*. Also note we have
"   to set it explicitly or will be reset when .vimrc is sourced
"   every time vimrc loaded.
let g:formatoptions="lro"
exe 'setlocal formatoptions='.g:formatoptions
augroup formatopts
  au!
  au FileType * exe 'setlocal formatoptions='.g:formatoptions
augroup END
function! s:toggleformatopt()
  if len(&formatoptions)==0 | exe 'setlocal formatoptions='.g:formatoptions
  else | setlocal formatoptions=
  endif
endfunction
"These keys aren't used currently, and are in a really good spot,
"so why not? Fits mnemonically that insert above is Shift+<key for insert below>
" noremap <silent> ` :call <sid>toggleformatopt()<CR>mzo<Esc>`z:call <sid>toggleformatopt()<CR>
" noremap <silent> ~ :call <sid>toggleformatopt()<CR>mzO<Esc>`z:call <sid>toggleformatopt()<CR>
noremap <silent> ` :call append(line('.'),'')<CR>
noremap <silent> ~ :call append(line('.')-1,'')<CR>
"Mnemonic is 'cut line' at cursor; character under cursor (e.g. a space) will be deleted
"use ss/substitute instead of cl if you want to enter insert mode
noremap <silent> cL mzi<CR><Esc>`z
"Swap with row above, and swap with row below; awesome mnemonic, right?
"use same syntax for c/s because almost *never* want to change up/down
"The command-based approach make sthe cursor much less jumpy
" noremap <silent> ck mzkddp`z
" noremap <silent> cj jmzkddp`zj
noremap <silent> ck k:let g:view=winsaveview() \| d \| call append(line('.'), getreg('"')[:-2]) 
      \ \| call winrestview(g:view)<CR>
noremap <silent> cj :let g:view=winsaveview() \| d \| call append(line('.'), getreg('"')[:-2]) 
      \ \| call winrestview(g:view)<CR>j
"Useful for typos
noremap <silent> cl xph
noremap <silent> ch Xp
"Navigate changelist with c-j/c-k; navigate jumplist with <C-h>/<C-l>
noremap <C-l> <C-i>
noremap <C-h> <C-o>
"Enable shortcut so that recordings are taken by just toggling 'q' on-off
"the escapes prevent a weird error where sometimes q triggers command-history window
noremap <C-j> g;
noremap <C-k> g,
noremap <silent> <expr> q b:recording ?
  \ 'q<Esc>:let b:recording=0<CR>' : 'qq<Esc>:let b:recording=1<CR>'
"Delete entire line; never should use dl anyway, use x instead
"must be normal mode map, or get delay; remember map includes some kind of
"operator-pending mode (i.e. waiting for a motion)
nnoremap dh <Nop>
nnoremap dl 0d$
"Never really want to use f/t commands more than once; remap these later on
noremap ; <Nop>
noremap , <Nop>
"Easy mark usage
noremap " :echo "Setting mark."<CR>mq
noremap ' `q
"New macro useage; almost always just use one at a time
"also easy to remembers; dot is 'repeat last command', comma is 'repeat last macro'
map @ <Nop>
noremap , @q
"Redo map to capital U; means we cannot 'undo line', but who cares
nnoremap U <C-r>
"Use BACKSLASH FOR REGISTER KEY (easier to access) and use it to just ACTIVATE
"THE THROWAWAY REGISTER; THAT IS THE ONLY WAY I USE REGISTERS ANYWAY
nnoremap - :echo "Enabling throwaway register."<CR>"_
vnoremap - <Esc>:echo "Enabling throwaway register." <BAR> sleep 200m<CR>gv"_
nnoremap <expr> \| has("clipboard") ? ':echo "Enabling system clipboard."<CR>"*' : ':echo "VIM not compiled with +clipboard."<CR>'
vnoremap <expr> \| has("clipboard") ? '<Esc>:echo "Enabling system clipboard." <BAR> sleep 200m<CR>gv"*' : ':echo "VIM not compiled with +clipboard."<CR>'
"Don't save single-character deletions to any register
nnoremap x "_x
nnoremap X "_X
"Default behavior replaces selection with register after p, but puts
"deleted text in register; correct this behavior
vnoremap p "_dP
vnoremap P "_dP
"Pressing enter on empty line preserves leading whitespace (HACKY)
"works because Vim doesn't remove spaces when text has been inserted
nnoremap o ox<BS>
nnoremap O Ox<BS>
"Disable arrow keys because you're better than that
for s:map in ['noremap', 'inoremap'] "disable typical navigation keys
  for s:motion in ['<Up>', '<Down>', '<Home>', '<End>', '<Left>', '<Right>']
    exe s:map.' '.s:motion.' <Nop>'
  endfor
endfor
"Disabling dumb extra scroll commands
nnoremap <C-p> <Nop>
nnoremap <C-n> <Nop>
"Better join behavior -- before 2J joined this line and next, now it
"means 'join the two lines below'; more intuitive. uses if statement
"in <expr> remap, and v:count the user input count
nnoremap <expr> J v:count>1 ? 'JJ' : 'J'
nnoremap <expr> K v:count>1 ? 'gJgJ' : 'gJ'
" nnoremap <expr> K v:count > 1 ? 'JdwJdw' : 'Jdw'
"Yank, substitute, delete until end of current line
nnoremap Y y$
nnoremap D D
"For some reason this is necessary or there is a cursor delay when hitting cc
nnoremap cc cc
nnoremap c<CR> s
"Replace the currently highlighted text
vnoremap cc s
"**Neat idea for insert mode remap**; put closing braces on next line
"adapted from: https://blog.nickpierson.name/colemak-vim/
" inoremap (<CR> (<CR>)<Esc>ko
" inoremap {<CR> {<CR>}<Esc>ko
" inoremap ({<CR> ({<CR>});<Esc>ko
"Turn off common things in normal mode
"also prevent Ctrl+c rining the bell
nnoremap <C-c> <Nop>
nnoremap <Delete> <Nop>
nnoremap <Backspace> <Nop>

"###############################################################################
"VISUAL MODE BEHAVIOR
"Highlighting
"Figured it out finally!!! This actually makes sense - they're next to eachother on keyboard!
noremap <silent> <Leader>i :set hlsearch<CR>
noremap <silent> <Leader>o :noh<CR>
"Enable left mouse click in visual mode to extend selection; normally this is impossible
"Note we can't use `< and `> because those refer to start and end of last visual selection,
"while we actually want the place where we *last exited* visual mode, like '^ for insert mode
nnoremap v myv
nnoremap V myV
nnoremap <C-v> my<C-v>
vnoremap <silent> <LeftMouse> <LeftMouse>mx`y:exe "normal! ".visualmode()<CR>`x
" vnoremap <silent> <LeftMouse> <Esc>:echo 'Mode: '.visualmode() \| sleep 200 m<CR><LeftMouse>mx`y:exe 'normal! '.visualmode()<CR>`x
vnoremap <CR> <C-c>
"Some other useful visual mode maps
"Also prevent highlighting selection under cursor, unless on first character
nnoremap <silent> v$ v$h
nnoremap <silent> vv ^v$gE
nnoremap <silent> v/ hn:noh<CR>gn

"###############################################################################
"DIFFERENT CURSOR SHAPE DIFFERENT MODES; works for everything (Terminal, iTerm2, tmux)
"First mouse stuff
set mouse=a "mouse clicks and scroll wheel allowed in insert mode via escape sequences; these
if has('ttymouse')
  set ttymouse=sgr
else
  set ttymouse=xterm2
endif
"Summary found here: http://vim.wikia.com/wiki/Change_cursor_shape_in_different_modes
"fail if you have an insert-mode remap of Esc; see: https://vi.stackexchange.com/q/15072/8084
" * Also according to this, don't need iTerm-specific Cursorshape stuff: https://stackoverflow.com/a/44473667/4970632
"   The TMUX stuff just wraps everything in \<Esc>Ptmux;\<Esc> CONTENT \<Esc>\\
" * Also see this for more compact TMUX stuff: https://vi.stackexchange.com/a/14203/8084
if exists("&t_SI")
  if exists('$TMUX') | let &t_SI = "\ePtmux;\e\e[6 q\e\\"
  else | let &t_SI = "\e[6 q"
  endif
endif
if exists("&t_SR")
  if exists('$TMUX') | let &t_SR = "\ePtmux;\e\e[4 q\e\\"
  else | let &t_SR = "\e[4 q"
  endif
endif
if exists("&t_EI")
  if exists('$TMUX') | let &t_EI = "\ePtmux;\e\e[2 q\e\\"
  else | let &t_EI = "\e[2 q"
  endif
endif

"###############################################################################
"GUI OPTIONS
if has("gui_running")
  set guicursor+=a:blinkon0 "disable blinking for GUI version
  set number relativenumber guioptions= "no scrollbars
  colorscheme slate "no longer controlled through terminal colors
endif

"###############################################################################
"CHANGE COMMAND-LINE WINDOW SETTINGS i.e. q: q/ and q? mode
function! s:commandline_check()
  nnoremap <buffer> <silent> q :q<CR>
  setlocal nonumber norelativenumber nolist laststatus=0
endfunction
augroup cmdwin
  au!
  au CmdwinEnter * call s:commandline_check()
  au CmdwinLeave * setlocal laststatus=2
augroup END
  "commandline-window settings; when we are inside of q:, q/, and q?

"###############################################################################
"TAB COMPLETION OPENING NEW FILES
let &wildignore="*.pdf,*.doc,*.docs,*.page,*.pages,"
  \."*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.o,*.mod,"
  \."*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4,"
  \."*.dmg,*.zip,*.sw[a-z],*.tmp,*.nc,*.DS_Store,"
  "never want to open these in VIM; includes GUI-only filetypes
  "and machine-compiled source code (.o and .mod for fortran, .pyc for python)

"###############################################################################
"###############################################################################
" COMPLICATED FUNCTIONS, MAPPINGS, FILETYPE MAPPINGS
"###############################################################################
"###############################################################################
"INITIAL STUFF
"Default tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
"Requirements flag, and load repeat.vim right away because want to know if it exists
"and its functions are available
exe 'runtime autoload/repeat.vim'
let g:has_signs              = has("signs") "for git gutter and syntastic maybe
let g:has_ctags              = str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))
let g:has_repeat             = exists("*repeat#set") "start checks for function existence
let g:has_nowait             = (v:version>=704 || v:version==703 && has("patch1261"))
let g:compatible_tagbar      = (g:has_ctags && (v:version>=704 || v:version==703 && has("patch1058")))
let g:compatible_workspace   = (v:version>=800) "needs Git 8.0
let g:compatible_codi        = (v:version>=704 && has('job') && has('channel'))
let g:compatible_neocomplete = has("lua") "try alternative completion library
if !g:has_repeat
  echom "Warning: vim-repeat unavailable, some features will be unavailable."
  sleep 1
endif

"##############################################################################"
"VIM-PLUG PLUGINS
augroup plug
augroup END
call plug#begin('~/.vim/plugged')
"Indent line
"WARNING: Right now *totally* fucks up stuff search mode, and cursorline overlaps. So not good.
"Requires changing Conceal group color, but doing that also messes up latex conceal
"backslashes (which we need to stay transparent); so forget it probably
" Plug 'yggdroot/indentline'
"Colors
Plug 'altercation/vim-colors-solarized'
"Superman man pages
Plug 'jez/vim-superman'
"Thesaurus; appears broken
" Plug 'beloglazov/vim-online-thesaurus'
"Make mappings repeatable; critical
"Now we edit our own version in .vim/plugin/autoload
" Plug 'tpope/vim-repeat'
"Automatic list numbering; actually it mysteriously fails so fuck that shit
" let g:bullets_enabled_file_types = ['vim', 'markdown', 'text', 'gitcommit', 'scratch']
" Plug 'dkarter/bullets.vim'
"Appearence; use my own customzied statusline/tagbar stuff though, and it's way better
" Plug 'vim-airline/vim-airline'
" Plug 'itchyny/lightline.vim'
"* Decided this plugin was done and wrote my own pretty tabline/statusline plugins
"* I don't like having everything look the exact same between server; just want
"  to use the terminal colorscheme and let colors do their thing
"* Good lightline styles: nord, PaperColor and PaperColor_dark (fave), OldHope,
"  jellybeans, and Tomorrow_Night, Tomorrow_Night_Eighties
"Proper syntax highlighting for a few different things
"Right now .tmux.conf and .tmux files, and markdown files
Plug 'tmux-plugins/vim-tmux'
Plug 'plasticboy/vim-markdown'
Plug 'vim-scripts/applescript.vim'
Plug 'anntzer/vim-cython'
"Colorize Hex strings
"Note this option is ***incompatible*** with iTerm minimum contrast above 0
"Actually tried with minimum contrast zero and colors *still* messed up; forget it
" Plug 'lilydjwg/colorizer'
"TeX utilities; better syntax highlighting, better indentation,
"and some useful remaps. Also zotero integration.
Plug 'Shougo/unite.vim'
Plug 'rafaqz/citation.vim'
" Plug 'lervag/vimtex'
" Plug 'chrisbra/vim-tex-indent'
"Julia support and syntax highlighting
Plug 'JuliaEditorSupport/julia-vim'
"Python wrappers
" if g:compatible_neocomplete | Plug 'davidhalter/jedi-vim' | endif "these need special support
" Plug 'cjrh/vim-conda' "for changing anconda VIRTUALENV; probably don't need it
" Plug 'hdima/python-syntax' "this failed for me; had to manually add syntax file
" Plug 'klen/python-mode' "incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython' "same problem as python-mode
"Folding and matching
if g:has_nowait | Plug 'tmhedberg/SimpylFold' | endif
Plug 'Konfekt/FastFold'
" Plug 'vim-scripts/matchit.zip'
"Navigating between files and inside file; enhancedjumps seemed broken to me
Plug 'scrooloose/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
if g:compatible_tagbar | Plug 'majutsushi/tagbar' | endif
" Plug 'jistr/vim-nerdtree-tabs'
" Plug 'vim-scripts/EnhancedJumps'
"Commenting and syntax checking
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
"Sessions and swap files
"Mapped in my .bashrc vims to vim -S .session.vim and exiting vim saves the session there
"Also vim-obsession more compatible with older versions
"NOTE: Apparently obsession causes all folds to be closed
Plug 'tpope/vim-obsession'
" if g:compatible_workspace | Plug 'thaerkh/vim-workspace' | endif
" Plug 'gioele/vim-autoswap' "deals with swap files automatically; no longer use them so unnecessary
"Git wrappers and differencing tools
Plug 'tpope/vim-fugitive'
if g:has_signs | Plug 'airblade/vim-gitgutter' | endif
"Completion engines
" Plug 'lifepillar/vim-mucomplete' "broken
" Plug 'Valloric/YouCompleteMe' "broken
" Plug 'ajh17/VimCompletesMe' "no auto-popup feature
" if g:compatible_neocomplete | Plug 'ervandew/supertab' | endif
if g:compatible_neocomplete | Plug 'shougo/neocomplete.vim' | endif
"Simple stuff for enhancing delimiter management
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'
"Aligning things and stuff
"Alternative to tabular is: https://github.com/tommcdo/vim-lion
"But in defense tabular is *super* flexible
Plug 'godlygeek/tabular'
"Calculators and number stuff
"No longer use codi, because had endless problems with it, and this cool 'Numi'
"desktop calculator will suffice
Plug 'triglav/vim-visual-increment' "visual incrementing/decrementing
" Plug 'vim-scripts/Toggle' "toggling stuff on/off; modified this myself
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
if g:compatible_codi | Plug 'metakirby5/codi.vim' | endif "CODI appears to be broken, tried with other plugins disabled
"Single line/multiline transition; make sure comes after surround
"Hardly ever need this
" Plug 'AndrewRadev/splitjoin.vim'
" let g:splitjoin_split_mapping = 'cS' | let g:splitjoin_join_mapping  = 'cJ'
"Multiple cursors is awesome
"Article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" Plug 'terryma/vim-multiple-cursors'
"Sneak plugin; see the link for helpful discussion:
"https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
Plug 'justinmk/vim-sneak'
"End of plugins
call plug#end() "the plug#end also declares filetype syntax and indent on
  "note apparently every BufRead autocmd inside an ftdetect/filename.vim file
  "is automatically made part of the 'filetypedetect' augroup; that's why it exists!

"###############################################################################
"SESSION MANAGEMENT
"First, jump to mark '"' without changing the jumplist (:help g`)
"Mark '"' is the cursor position when last exiting the current buffer
"CursorHold is supper annoying to me; just use InsertLeave and TextChanged if possible
augroup session
  au!
  if has_key(g:plugs, "vim-obsession") "must manually preserve cursor position
    au BufReadPost * if line("'\"")>0 && line("'\"")<=line("$") | exe "normal! g`\"" | endif
    au VimEnter * Obsession .session.vim
  endif
  let s:autosave="InsertLeave" | if exists("##TextChanged") | let s:autosave.=",TextChanged" | endif
  " exe "au ".s:autosave." * w"
augroup END
" function! s:autosave_toggle(on)
"   if a:on "in future consider using this to disable autosave for large files
"     if exists('b:autosave_on') && b:autosave_on=1
"       return "already on
"     endif
"     let b:autosave_on=1
"     echom 'Enabling autosave.'
"     augroup autosave
"       au! * <buffer>
"       let g:autosave="InsertLeave"
"       if exists("##TextChanged") | let g:autosave.=",TextChanged" | endif
"       exe "au ".g:autosave." <buffer> * w"
"     augroup END
"   else
"     if !exists('b:autosave_on') || b:autosave_on=0
"       return "already off
"     endif
"     let b:autosave_on=0
"     echom 'Disabling autosave.'
"     augroup autosave
"       au! * <buffer>
"     augroup END
"   endif
" endfunction
if has_key(g:plugs, "thaerkh/vim-workspace") "cursor positions automatically saved
  let g:workspace_session_name = '.session.vim'
  let g:workspace_session_disable_on_args = 1 "enter vim (without args) to load previous sessions
  let g:workspace_persist_undo_history = 0 "don't need to save undo history
  let g:workspace_autosave_untrailspaces = 0 "sometimes we WANT trailing spaces!
  let g:workspace_autosave_ignore = ['gitcommit', 'rst', 'qf', 'diff', 'help'] "don't autosave these
endif
"Remember file position, so come back after opening to same spot

"##############################################################################"
"TEMPLATES
"***NOTE*** BufNewFile events don't work inside ftplugin, because by the time
"vim has reached that file, the BufNewFiel event is no longer valid!
"Prompt user to choose from a list of templates (located in ~/latex folder)
"when creating a new LaTeX file.
"See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
augroup templates
  au!
  au BufNewFile *.tex call <sid>textemplates()
augroup END
function! s:textemplates()
  function! TeXTemplates(A,L,P)
    let templates=split(globpath('~/latex/', '*.tex'),"\n")
    let names=[]
    for template in templates
      let name=fnamemodify(template, ":t:r")
      if name =~? '^'.a:A "if what user typed so far matches name
        call add(names, fnamemodify(template, ":t:r"))
      endif
    endfor
    return names
  endfunction
  " echo 'Current templates available: '.join(names, ', ').'.'
  while 1
    let template=expand("~")."/latex/".input("Template (tab to reveal options): ", "", "customlist,TeXTemplates").".tex"
    if filereadable(template)
      execute "0r ".template
      break
    endif
    echo "\nInvalid name."
  endwhile
endfunction

"##############################################################################"
"ZOTERO INTEGRATION
"Requires pybtex (pip install it) and unite.vim plugin
augroup unite
augroup END
if has_key(g:plugs,'unite.vim') && has_key(g:plugs,'citation.vim')
  "Settings
  " let g:citation_vim_mode="bibtex"
  " let g:citation_vim_bibtex_file="./refs.bib" "by default, make this your filename
  let g:citation_vim_mode="zotero" "default
  let g:citation_vim_zotero_path="~/Zotero" "location of sqlite
  let g:citation_vim_zotero_version=5
  let g:citation_vim_cache_path='~/.vim/zcache'
  let g:citation_vim_outer_prefix='\cite{'
  let g:citation_vim_inner_prefix=''
  let g:citation_vim_suffix='}'
  let g:citation_vim_et_al_limit=3 "show et al if more than 2 authors
  " let g:citation_vim_zotero_path="~/Google Drive"   "alternative
  "Mappings
  "We use the y prefix because it's mostly unused so far
  "yo for toggle spelling, yO for toggle citation
  nnoremap <silent> yO :<C-u>Unite citation<CR>
  "Insert citation
  nnoremap <silent> yc :<C-u>Unite -buffer-name=citation-start-insert -default-action=append citation/key<CR>
  "Open file directory
  nnoremap <silent> yd :<C-u>Unite -input=<C-R><C-W> -default-action=file -force-immediately citation/file<CR>
  "Open pdf
  nnoremap <silent> yp :<C-u>Unite -input=<C-R><C-W> -default-action=start -force-immediately citation/file<CR>
  "Open url
  nnoremap <silent> yu :<C-u>Unite -input=<C-R><C-W> -default-action=start -force-immediately citation/url<CR>
  "View citation info
  nnoremap <silent> yI :<C-u>Unite -input=<C-R><C-W> -default-action=preview -force-immediately citation/combined<CR>
  "Append information
  nnoremap <silent> yA :<C-u>Unite -default-action=yank citation/title<CR>
  "Search for word under cursor
  nnoremap <silent> ys :<C-u>Unite  -default-action=yank  citation/key:<C-R><C-W><CR>
  "Search for words, input prompt
  nnoremap <silent> yS :<C-u>exec "Unite  -default-action=start citation/key:" . escape(input('Search Key : '),' ')<CR>
endif

"##############################################################################"
"SNIPPETS
"TODO: Add these

"###############################################################################
"GIT GUTTER
"TODO: Note we had to overwrite the gitgutter autocmds with a file in 'after'.
augroup git
  au FileType * let b:gitgutter_enabled=0
augroup END
if has_key(g:plugs, "vim-gitgutter")
  "Create command for toggling on/off; old VIM versions always show signcolumn
  "if signs present (i.e. no signcolumn option), so GitGutterDisable will remove signcolumn.
  " call gitgutter#disable() | silent! set signcolumn=no
  "In newer versions, have to *also* set the signcolumn option.
  silent! set signcolumn=no "silent ignores errors if not option
  let g:gitgutter_map_keys=0 "disable all maps yo
  let g:gitgutter_enabled=0 "whether enabled at *startup*
  nnoremap <silent> <expr> <Leader>s b:gitgutter_enabled==0 ? 
    \  ':GitGutterEnable<CR>:silent! set signcolumn=yes<CR>:let b:gitgutter_enabled=1<CR>'
    \: ':GitGutterDisable<CR>:silent! set signcolumn=no<CR>:let b:gitgutter_enabled=0<CR>'
  " nnoremap <silent> <expr> <Leader>s &signcolumn=="no" ? ':set signcolumn=yes<CR>' : ':set signcolumn=no<CR>'
  nmap <silent> gw :GitGutterPreviewHunk<CR>:wincmd j<CR>
  nmap <silent> gd :GitGutterUndoHunk<CR>
  "d is for 'delete' change
  nmap <silent> gN :GitGutterPrevHunk<CR>
  nmap <silent> gn :GitGutterNextHunk<CR>
endif

"##############################################################################"
"VIM SNEAK
"Just configure the maps here
"Also disable highlighting when doing sneak operations, because
"want to same the use highlight group
augroup sneak
augroup END
if has_key(g:plugs, "vim-sneak")
  "F and T move
  map s <Plug>Sneak_s
  map S <Plug>Sneak_S
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  "Map ctrl , and ctrl ; to F1 and F2
  map <F1> <Plug>Sneak_,
  map <F2> <Plug>Sneak_;
endif

"###############################################################################
"DELIMITMATE (auto-generate closing delimiters)
if has_key(g:plugs, "delimitmate")
  "Set up delimiter paris; delimitMate uses these by default
  "Can set global defaults along with buffer-specific alternatives
  let g:delimitMate_quotes="\" '"
  let g:delimitMate_matchpairs="(:),{:},[:]"
  augroup delimitmate
    au!
    au FileType vim,html,markdown let b:delimitMate_matchpairs="(:),{:},[:],<:>"
    "override for formats that use carats
    au FileType markdown let b:delimitMate_quotes = "\" ' $ `"
    "vim needs to disable matching ", or everything is super slow
    au FileType vim let b:delimitMate_quotes = "'"
    "markdown need backticks for code, and can maybe do LaTeX
    au FileType tex let b:delimitMate_quotes = "$ |" | let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
    "tex need | for verbatim environments; note you *cannot* do set matchpairs=xyz; breaks plugin
  augroup END
endif

"###############################################################################
"SPELLCHECK (really is a BUILTIN plugin, hence why it's in this section)
"Turn on for certain filetypes
augroup spell
  au!
  au FileType tex,html,markdown call s:spelltoggle(1)
augroup END
"Off by default
set nospell spelllang=en_us spellcapcheck=
"Toggle on and off
"Also toggle UK/US languages
nnoremap <silent> yo :call <sid>spelltoggle()<CR>
nnoremap <silent> yl :call <sid>langtoggle()<CR>
function! s:spelltoggle(...)
  if a:0
    let toggle=a:1
  else
    let toggle=(exists("b:spellstatus") ? 1-b:spellstatus : 1)
  endif
  if toggle
    setlocal spell
    nnoremap <buffer> yn ]S
    nnoremap <buffer> yN [S
    let b:spellstatus=1
  else
    setlocal nospell
    nnoremap <buffer> yn <Nop>
    nnoremap <buffer> yN <Nop>
    let b:spellstatus=0
  endif
endfunction
function! s:langtoggle()
  if &spelllang=='en_us'
    set spelllang=en_gb
    echo 'Current language: UK english'
  else
    set spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction
"Get suggestions, or choose first suggestion without looking
"Use these conventions cause why not
nnoremap y, z=
nnoremap y. z=1<CR><CR><CR>
"Add/remove from dictionary
nnoremap ya zg
nnoremap yr zug
"Thesaurus stuff
"Plugin appears broken
"Use e key cause it's not used yet
" if has_key(g:plugs, "vim-online-thesaurus")
"   let g:online_thesaurus_map_keys = 0
"   inoremap <C-e> <Esc>:OnlineThesaurusCurrentWord<CR>
"   " help
" endif

"###############################################################################
"HELP WINDOW SETTINGS, and special settings for mini popup windows where we don't
"want to see line numbers or special characters a la :set list.
"Also enable quitting these windows with single 'q' press
augroup simple
  au!
  au BufEnter * let b:recording=0
  au FileType help call s:helpsetup()
  au FileType rst,qf,diff,man Simple 1
  au FileType gitcommit Simple 0
augroup END
"Next set the help-menu remaps
"The defalt 'fart' search= assignments are to avoid passing empty strings
"TODO If you're an insane person could also generate autocompletion for these ones, but nah
noremap <Leader>h :vert help 
noremap <silent> <expr> <Leader>m ':!clear; search='.input('Get man info: ').'; '
  \.'if [ -n $search ] && command man $search &>/dev/null; then command man $search; fi<CR>:redraw!<CR>'
"--help info; pipe output into less for better interaction
noremap <silent> <expr> <Leader>H ':!clear; search='.input('Get help info: ').'; '
  \.'if [ -n $search ] && builtin help $search &>/dev/null; then builtin help $search 2>&1 \| less; '
  \.'elif $search --help &>/dev/null; then $search --help 2>&1 \| less; fi<CR>:redraw!<CR>'
function! s:helpsetup()
  if len(tabpagebuflist())==1 | q | endif "exit from help window, if it is only one left
  wincmd L "moves current window to be at far-right; 'wincmd' executes Ctrl+W functions
  vertical resize 80
  nnoremap <silent> <buffer> q :q<CR>
  nnoremap <buffer> <CR> <C-]>
  " nnoremap <nowait> <buffer> <LeftMouse> <LeftMouse><C-]>
  if g:has_nowait | nnoremap <nowait> <buffer> [ :pop<CR>
  else | nnoremap <buffer> [[ :pop<CR>
  endif
  setlocal nolist nonumber norelativenumber nospell
  "better jumping behavior; note these must be C-], not Ctrl-]
endfunction
"The doc pages appear in rst files, so turn off extra chars for them
"Also the syntastic shows up as qf files so want extra stuff turned off there too
function! s:simplesetup(...)
  let nosave = 1 "default true
  if a:0 "override
    let nosave = a:1
  endif
  if nosave
    nnoremap <buffer> <C-s> <Nop>
  endif
  nnoremap <silent> <buffer> q :q<CR>
  setlocal nolist nonumber norelativenumber nospell
endfunction
command! -nargs=? Simple call <sid>simplesetup(<args>)

"###############################################################################
"VIM VISUAL INCREMENT; creating columns of 1/2/3/4 etc.
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
"CODI (MATHEMATICAL NOTEPAD)
"Now should just use 'Numi' instead; had too many issues with this
augroup codi
augroup END
if has_key(g:plugs, "codi.vim")
  "Update manually commands; o stands for codi
  nnoremap <C-n> :CodiUpdate<CR>
  inoremap <C-n> <Esc>:CodiUpdate<CR>a
  function! s:newcodi(name)
    if a:name==''
      echom "Cancelled."
    else
      exec "tabe ".fnamemodify(a:name,':r').".py"
      exec "Codi!! ".&ft
    endif
  endfunction
  "Create new calculator file, adds .py extension
  nnoremap <silent> <Leader>n :call <sid>newcodi(input('Calculator name: ('.getcwd().') ', '', 'file'))<CR>
  "Turn current file into calculator; m stands for math
  nnoremap <silent> <Leader>N :Codi!! &ft<CR>
  "Use builtin python2.7 on macbook to avoid creating history files
  " \ 'bin': '/usr/bin/python',
  let g:codi#interpreters = {
       \ 'python': {
           \ 'bin': '/usr/bin/python',
           \ 'prompt': '^\(>>>\|\.\.\.\) ',
           \ },
       \ } "see issue here: https://github.com/metakirby5/codi.vim/issues/85
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20 "simple window configuration
  "CursorHold sometimes caused errors/CPU spikes; this is weird because actually
  "shouldn't, get flickering cursor and codi still running even after 250ms; maybe some other option conflicts
  let g:codi#autocmd = "None"
  let g:codi#sync = 0 "probably easier
  let g:codi#log = "codi.log" "log everything, becuase you *will* have issues
endif

"###############################################################################
"MUCOMPLETE
"Compact alternative to neocomplete; try it again
augroup mucomplete
augroup END
if has_key(g:plugs, "vim-mucomplete") "just check if activated
  let g:mucomplete#enable_auto_at_startup = 1
  let g:mucomplete#no_mappings = 1
  let g:mucomplete#no_popup_mappings = 1
endif

"###############################################################################
"NEOCOMPLETE (RECOMMENDED SETTINGS)
if has_key(g:plugs, "neocomplete.vim") "just check if activated
  "Enable omni completion for different filetypes; sooper cool bro
  augroup neocomplete
    au!
    au FileType css setlocal omnifunc=csscomplete#CompleteCSS
    au FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
    au FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
    au FileType python setlocal omnifunc=pythoncomplete#Complete
    au FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  augroup END
  "Disable python omnicompletion
  "From the Q+A section
  if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
  endif
  let g:neocomplete#sources#omni#input_patterns.python = ''
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
  if !exists('g:neocomplete#keyword_patterns') | let g:neocomplete#keyword_patterns = {} | endif
  let g:neocomplete#keyword_patterns['default'] = '\h\w*'
endif
"Highlighting
highlight Pmenu ctermbg=Black ctermfg=Yellow cterm=None
highlight PmenuSel ctermbg=Black ctermfg=Black cterm=None
highlight PmenuSbar ctermbg=None ctermfg=Black cterm=None

"##############################################################################"
"INDENTLINE
if has_key(g:plugs, 'indentline.vim')
  let g:indentLine_char='¦' "¦│┆
  let g:indentLine_setColors=0
  let g:indentLine_setConceal=0
  let g:indentLine_fileTypeExclude = ['rst', 'qf', 'diff', 'man', 'help', 'gitcommit', 'tex']
endif

"###############################################################################
"EVENTS MANAGEMENT
"Need to make this mini-function for ctrlp plugin
" * Note storage variable g:eidefault must be *global* because otherwise
"   the ctrlp plugin can't see it.
augroup eventsrestore
  au!
  au BufEnter * call s:eioff()
augroup END
function! s:eioff()
  setlocal eventignore=
  silent! hi MatchParen ctermfg=None ctermbg=Blue
  silent! unmap <Esc>
endfunction
function! s:eion() "set autocommands to ignore, in consideration of older versions without TextChanged
  let events="CursorHold,CursorHoldI,CursorMoved,CursorMovedI"
  if exists("##TextChanged") | let events.=",TextChanged,TextChangedI" | endif
  exe "setlocal eventignore=".events
  silent! hi clear MatchParen "clear MatchLine from match.vim plugin, if it exists
endfunction
function! s:eimap()
  nnoremap <silent> <buffer> <Esc> :q<CR>:EIOff<CR>
  nnoremap <silent> <buffer> <C-c> :q<CR>:EIOff<CR>
endfunction
command! EIOn  call <sid>eion()
command! EIOff call <sid>eioff()
command! EIMap call <sid>eimap()

"###############################################################################
"CTRLP PLUGIN
"Make opening in new tab default behavior; see: https://github.com/kien/ctrlp.vim/issues/160
"Also scan dotfiles/directories, but *ignore* vim-plug directory tree and possibly others
"Encountered weird issue due to interactions of CursorMoved maps; here's my saga:
" * Calling :noautocmd CtrlP does not fix the problem either; what the fuck.
" * Note ctrlp 'enter' and 'exit' functions seem to have no effect
"   on eventignore. Has to be set manually before entering the buffer.
" * Note only CursorMoved autocommands are still triggered when entering
"   ctrlp window; the BufEnter stuff is sucessfully ignored, so you can't
"   create a BufEnter command expecting it to execute when we exit the ctrlp buffer.
" * Creating a CursorHold autocmd also seems to break ctrlp; so can't make
"   one that resets the eventignore options.
" * Amazingly a nnoremap works because we enter the ctrlp buffer in 'normal mode',
"   but all keys are mapped to print their actual values; so a nnoremap of some
"   :command actually works.
" * Frustratingly it seems impossible to declare mappings this way, however; it
"   will fail if you try e.g. nnoremap <C-p> :Ctrlp<CR>:nnoremap <buffer> <Esc> <Stuff><CR>
"   But we can call a function that declares this mapping. And *that* fixes the problem!
augroup ctrlp
augroup END
if has_key(g:plugs, "ctrlp.vim")
  " let g:ctrlp_buffer_func={'enter':'EIOn', 'exit':'EIoff'} "fails
  " nnoremap <silent> <C-p> :EIOn<CR>:CtrlP<CR>:echom "Hi"<CR>:nnoremap <buffer> \<Esc\> :q\<CR\>:EIoff\<CR\><CR> "fails
  function! s:ctrlpwrap()
    let dir=input("Directory for Ctrl-P (".getcwd()."): ", "", "dir")
    if dir!=""
      EIOn
      exe 'CtrlP '.dir
      EIMap
    else
      echom "Cancelled."
    endif
  endfunction
  "Make sure to map Ctrl i to F3 in iTerm
  nnoremap <silent> <C-p> :call <sid>ctrlpwrap()<CR>
  " nnoremap <silent> <F3> :call <sid>ctrlpwrap()<CR>
  " nnoremap <silent> <C-p> :EIOn<CR>:CtrlP<CR>:EIMap<CR>
  let g:ctrlp_map='' "disable default map; will use my special map
  let g:ctrlp_max_depth=5 "honestly, rarely need many
  let g:ctrlp_custom_ignore = '\v[\/](\.git|\.hg|\.svn|plugged)$'
  let g:ctrlp_show_hidden=1
  let g:ctrlp_by_filename=0
  let g:ctrlp_prompt_mappings = {
    \ 'PrtBS()':              ['<bs>', '<c-]>'],
    \ 'PrtDelete()':          ['<del>'],
    \ 'PrtDeleteWord()':      ['<c-w>'],
    \ 'PrtClear()':           ['<c-u>'],
    \ 'PrtSelectMove("j")':   ['<c-j>', '<down>'],
    \ 'PrtSelectMove("k")':   ['<c-k>', '<up>'],
    \ 'PrtSelectMove("t")':   ['<Home>', '<kHome>'],
    \ 'PrtSelectMove("b")':   ['<End>', '<kEnd>'],
    \ 'PrtSelectMove("u")':   ['<PageUp>', '<kPageUp>'],
    \ 'PrtSelectMove("d")':   ['<PageDown>', '<kPageDown>'],
    \ 'PrtHistory(-1)':       ['<c-n>'],
    \ 'PrtHistory(1)':        ['<c-p>'],
    \ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-s>'],
    \ 'AcceptSelection("e")': ['<c-t>'],
    \ 'AcceptSelection("t")': ['<cr>', '<2-LeftMouse>'],
    \ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>'],
    \ 'ToggleFocus()':        ['<s-tab>'],
    \ 'ToggleRegex()':        ['<c-r>'],
    \ 'ToggleByFname()':      ['<c-d>'],
    \ 'ToggleType(1)':        ['<c-f>', '<c-up>'],
    \ 'ToggleType(-1)':       ['<c-b>', '<c-down>'],
    \ 'PrtExpandDir()':       ['<tab>'],
    \ 'PrtInsert("c")':       ['<MiddleMouse>', '<insert>'],
    \ 'PrtInsert()':          ['<c-\>'],
    \ 'PrtCurStart()':        ['<c-a>'],
    \ 'PrtCurEnd()':          ['<c-e>'],
    \ 'PrtCurLeft()':         ['<c-h>', '<left>', '<c-^>'],
    \ 'PrtCurRight()':        ['<c-l>', '<right>'],
    \ 'PrtClearCache()':      ['<F5>'],
    \ 'PrtDeleteEnt()':       ['<F7>'],
    \ 'CreateNewFile()':      ['<c-y>'],
    \ 'MarkToOpen()':         ['<c-z>'],
    \ 'OpenMulti()':          ['<c-o>'],
    \ 'PrtExit()':            ['<esc>', '<c-c>', '<c-g>'],
    \ }
endif

"##############################################################################"
"FZF COMPLETION
"Maybe not necessary anymore because Ctrl-P access got way better
"Vim documentation is incomplete; also see readme file: https://github.com/junegunn/fzf/blob/master/README-VIM.md
"The ctrl-i map below prevents tab from doing anything
"Also in iterm ctrl-i keypress translates to F3, so use that below
" Plug 'junegunn/fzf.vim'
" if has_key(g:plugs, 'fzf.vim')
augroup fzf
augroup END
if !empty(glob("~/.fzf"))
  let g:fzf_layout = {'down': '~20%'} "make window smaller
  let g:fzf_action = {
  \ 'ctrl-i': 'silent!',
  \ 'ctrl-m': 'tab split',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
  set rtp+=~/.fzf
  helptags ~/.fzf/doc "have to update tags after change runtimepath; normally vim-plug does this
  function! s:fzf()
    let result=input("Directory for FZF (".getcwd()."): ", "", "dir")
    if result!=""
      exe 'FZF '.result
    else
      echom "Cancelled."
    endif
  endfunction
  noremap <F3> :call <sid>fzf()<CR>
endif

"###############################################################################
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
if has_key(g:plugs, "nerdtree")
  augroup nerdtree
    au!
    au BufEnter * if (winnr('$')==1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    au FileType nerdtree call s:nerdtreesetup()
  augroup END
  " f stands for files here
  " noremap <Leader>f :NERDTreeFind<CR>
  noremap <Leader>f :NERDTree %<CR>
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
  "Custom nerdtree maps here
  "See this thread for ideas: https://superuser.com/q/195022/506762
  function! s:nerdtreesetup()
    setlocal nolist
    exe 'vertical resize '.g:NERDTreeWinSize
    noremap <buffer> <Leader>f :NERDTreeClose<CR>
    if g:has_nowait | nmap <buffer> <nowait> d D | endif
    "prevents attempts to change it; this descends into directory
  endfunction
endif

"###############################################################################
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
if has_key(g:plugs, "nerdcommenter")
  "Create fancy shcmany maps, and make commenter work for NCL files
  augroup nerdcomment
    au!
    au FileType * call s:commentheaders()
  augroup END
  "Custom delimiter overwrites (default python includes space for some reason)
  let g:NERDCustomDelimiters = {'python': {'left': '#'}, 'cython': {'left': '#'},
    \ 'pyrex': {'left': '#'}, 'ncl': {'left': ';'}}
  let g:NERDCreateDefaultMappings = 0 " disable default mappings (make my own)
  let g:NERDSpaceDelims = 1           " comments led with spaces
  let g:NERDCompactSexyComs = 1       " use compact syntax for prettified multi-line comments
  let g:NERDTrimTrailingWhitespace=1  " trailing whitespace deletion
  let g:NERDCommentEmptyLines = 1     " allow commenting and inverting empty lines (useful when commenting a region)
  let g:NERDDefaultAlign = 'left'     " align line-wise comment delimiters flush left instead of following code indentation
  let g:NERDCommentWholeLinesInVMode = 1
  "Create python docstring
  nnoremap <silent> c' o'''<CR>.<CR>'''<Up><Esc>A<BS>
  nnoremap <silent> c" o"""<CR>.<CR>"""<Up><Esc>A<BS>
  "Add author information (tries to match indentation)
  nnoremap <silent> <expr> cA ':call <sid>toggleformatopt()<CR>A<CR>'.b:NERDCommenterDelims['left']
        \ .' Author: Luke Davis (lukelbd@gmail.com)<Esc>:call <sid>toggleformatopt()<CR>o'
  " nnoremap <silent> <Leader>a :call append(line('.'), b:NERDCommenterDelims['left'].' Author: Luke Davis')<CR>jA<CR>
  "Simple option -- 'inline' comment header
  nnoremap <silent> <expr> cI ':call <sid>toggleformatopt()<CR>A<CR>'.b:NERDCommenterDelims['left']
        \ .repeat(' ',5).repeat('-',5).'  '.repeat('-',5).'<Esc>5hi'
  "Declare mapping strings needed to build remaps
  "Then can *delcare mapping for custom keyboard* using exe 'nnoremap <expr> shortcut '.string,
  "and note that the expression is evaluated every time right before the map is executed (i.e. buffer-local comment chars are generated)
  "The below helper functions lets us change the table commands for different filetypes; very handy
  function! s:commentheaders()
    "Declare helper functions, and figure out initial settings
    "For new-style section header, just add another constructer-function
    function! s:bar(char) "inserts above by default; most common use
      return "':call <sid>toggleformatopt()<CR>"
        \."mzO<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(78-col('.')+1).'a".a:char."<Esc>a'.b:NERDCommenterDelims['left'].'<Esc>`z"
        \.":call <sid>toggleformatopt()<CR>'"
    endfunction
    function! s:section(char) "to make insert above, replace 'o' with 'O', and '<Up>' with '<Down>'
      return "':call <sid>toggleformatopt()<CR>"
        \."mzo<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(78-col('.')+1).'a".a:char."<Esc>a'.b:NERDCommenterDelims['left'].'<Esc>"
        \."o<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>"
        \."o<Esc>'.col('.').'a<Space><Esc>xA'.b:NERDCommenterDelims['left'].'<Esc>'.eval(78-col('.')+1).'a".a:char."<Esc>a'.b:NERDCommenterDelims['left'].'<Esc>"
        \."<Up>$a<Space><Esc>:call <sid>toggleformatopt()<CR>'"
    endfunction
    if &ft=="vim" | let fatchar="#" "literally says 'type a '#' character while in insert mode'
    else | let fatchar="'.b:NERDCommenterDelims['left'].'"
        "will be evaluated when <expr> is evaluted (we are catting to <expr> string)
        "will *not* evaluate on :exec command declaring initial map
    endif
    "Declare remaps; section-header types will be dependent on filetype, e.g.
    "if comment character is not 'fat' enough, does not make good section header character
    "Also temporarily disable/re-enable formatoptions here
    exe 'nnoremap <silent> <buffer> <expr> <Plug>fancy1 '.s:bar("-").".'".':call repeat#set("\<Plug>fancy1")<CR>'."'"
    exe 'nnoremap <silent> <buffer> <expr> <Plug>fancy2 '.s:bar(fatchar).".'".':call repeat#set("\<Plug>fancy2")<CR>'."'"
    exe 'nnoremap <silent> <buffer> <expr> <Plug>fancy3 '.s:section("-").".'".':call repeat#set("\<Plug>fancy3")<CR>'."'"
    exe 'nnoremap <silent> <buffer> <expr> <Plug>fancy4 '.s:section(fatchar).".'".':call repeat#set("\<Plug>fancy4")<CR>'."'"
    nmap c- <Plug>fancy1
    nmap c_ <Plug>fancy2
    nmap c\ <Plug>fancy3
    nmap c\| <Plug>fancy4
  endfunction
  "More basic NerdComment maps, just for toggling comments and stuff
  "Easy peasy
  " if g:has_repeat
  nnoremap <silent> <Plug>comment1 :call NERDComment('n', 'comment')<CR>:call repeat#set("\<Plug>comment1",v:count)<CR>
  nnoremap <silent> <Plug>comment2 :call NERDComment('n', 'uncomment')<CR>:call repeat#set("\<Plug>comment2",v:count)<CR>
  nnoremap <silent> <Plug>comment3 :call NERDComment('n', 'toggle')<CR>:call repeat#set("\<Plug>comment3",v:count)<CR>
  nmap co <Plug>comment1
  nmap cO <Plug>comment2
  nmap c. <Plug>comment3
  " nnoremap <silent> co :call NERDComment('n', 'comment')<CR>
  " nnoremap <silent> cO :call NERDComment('n', 'uncomment')<CR>
  " nnoremap <silent> c. :call NERDComment('n', 'toggle')<CR>
  vnoremap <silent> co :call NERDComment('v', 'comment')<CR>
  vnoremap <silent> cO :call NERDComment('v', 'uncomment')<CR>
  vnoremap <silent> c. :call NERDComment('v', 'toggle')<CR>
endif

"###############################################################################
"SYNTASTIC (syntax checking for code)
augroup syntastic
augroup END
if has_key(g:plugs, "syntastic")
  "Commands for circular location-list (error) scrolling
  command! Lnext try | lnext | catch | lfirst | catch | endtry
  command! Lprev try | lprev | catch | llast  | catch | endtry
  "Helper function
  "Need to run Syntastic with noautocmd to prevent weird conflict with tabbar,
  "but that means have to change some settings manually
  "Uses 'simplesetup' function (disables line numbers and stuff)
  function! s:syntastic_status()
    return (exists("b:syntastic_on") && b:syntastic_on)
  endfunction
  function! s:syntastic_enable()
    nnoremap <buffer> <silent> yn :Lnext<CR>
    nnoremap <buffer> <silent> yN :Lprev<CR>
      "use sn/sN to nagivate between syntastic errors, or between spelling errors when syntastic off
    let nbufs=len(tabpagebuflist())
    noh | w | noautocmd SyntasticCheck
    if len(tabpagebuflist())>nbufs
      wincmd j | set syntax=on
      Simple
      wincmd k | let b:syntastic_on=1 | silent! set signcolumn=no
    else | echom "No errors found, or no checkers available." | let b:syntastic_on=0
    endif
  endfunction
  function! s:syntastic_disable()
    SyntasticReset
    let b:syntastic_on=0
    nnoremap <buffer> <silent> yn <Nop>
    nnoremap <buffer> <silent> yN <Nop>
  endfunction
  "Set up custom remaps
  nnoremap <silent> <expr> yx <sid>syntastic_status() ? ':call <sid>syntastic_disable()<CR>'
    \ : ':call <sid>syntastic_enable()<CR>'
  "Disable auto checking (passive mode means it only checks when we call it)
  let g:syntastic_mode_map = {'mode':'passive', 'active_filetypes':[],'passive_filetypes':[]}
  let g:syntastic_stl_format = "" "disables statusline colors; they were ugly
  "Other defaults
  let g:syntastic_always_populate_loc_list = 1 "necessary, or get errors
  let g:syntastic_auto_loc_list = 1 "creates window; if 0, does not create window
  let g:syntastic_loc_list_height = 5
  let g:syntastic_mode = 'passive' "opens little panel
  let g:syntastic_check_on_open = 0
  let g:syntastic_check_on_wq = 0
  let g:syntastic_enable_signs = 1 "disable useless signs
  let g:syntastic_enable_highlighting = 1
  let g:syntastic_auto_jump = 0 "disable jumping to errors
  "Choose syntax checkers
  let g:syntastic_tex_checkers=['lacheck']
  let g:syntastic_python_checkers=['pyflakes'] "pylint very slow; pyflakes light by comparison
  let g:syntastic_fortran_checkers=['gfortran']
  let g:syntastic_vim_checkers=['vimlint']
  "Colors
  hi SyntasticErrorLine ctermfg=White ctermbg=Red cterm=None
  hi SyntasticWarningLine ctermfg=White ctermbg=Magenta cterm=None
endif

"##############################################################################"
"VIMTEX SETTINGS AND STUFF
augroup vimtex
augroup END
if has_key(g:plugs, 'vimtex')
  "Turn off annoying warning; see: https://github.com/lervag/vimtex/issues/507
  let g:vimtex_compiler_latexmk = {'callback' : 0}
  let g:vimtex_mappings_enable = 0
  "See here for viewer configuration: https://github.com/lervag/vimtex/issues/175
  " let g:vimtex_view_general_viewer = 'open'
  " let g:vimtex_view_general_options = '-a Skim'
  let g:vimtex_view_view_method = 'skim'
  "Try again
  let g:vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
  let g:vimtex_view_general_options = '-r @line @pdf @tex'
  let g:vimtex_fold_enabled = 0 "So large files can open more easily
endif

"###############################################################################
"WRAPPING AND LINE BREAKING
augroup wrap "For some reason both autocommands below are necessary; fuck it
  au!
  au VimEnter * exe 'WrapToggle '.(index(['bib','tex','markdown'],&ft)!=-1)
  au BufEnter * exe 'WrapToggle '.(index(['bib','tex','markdown'],&ft)!=-1)
augroup END
"Buffer amount on either side
"Can change this variable globally if want
let g:scrolloff=4
"Call function with anything other than 1/0 (e.g. -1) to toggle wrapmode
function! s:wraptoggle(...)
  if a:0 "if non-zer number of args
    let toggle=a:1
  elseif exists('b:wrap_mode')
    let toggle=1-b:wrap_mode
  else
    let toggle=1
  endif
  if toggle==1
    let b:wrap_mode=1
    "Display options that make more sense with wrapped lines
    setlocal wrap
    setlocal scrolloff=0
    setlocal colorcolumn=0
    "Basic wrap-mode navigation, always move visually
    "Still might occasionally want to navigate by lines though, so remap those to g
    noremap <buffer> k gk
    noremap <buffer> j gj
    noremap <buffer> ^ g^
    noremap <buffer> $ g$
    noremap <buffer> 0 g0
    nnoremap <buffer> A g$a
    nnoremap <buffer> I g^i
    noremap <buffer> gj j
    noremap <buffer> gk k
    noremap <buffer> g^ ^
    noremap <buffer> g$ $
    noremap <buffer> g0 0
    nnoremap <buffer> gA A
    nnoremap <buffer> gI I
  else
    let b:wrap_mode=0
    "Disable previous options
    setlocal nowrap
    execute 'setlocal scrolloff='.g:scrolloff
    execute 'setlocal colorcolumn=81,121'
    "Disable previous maps
    silent! unmap k
    silent! unmap j
    silent! unmap ^
    silent! unmap $
    silent! unmap 0
    silent! unmap A
    silent! unmap I
    silent! unmap gj
    silent! unmap gk
    silent! unmap g^
    silent! unmap g$
    silent! unmap g0
    silent! unmap gA
    silent! unmap gI
  endif
endfunction
command! -nargs=? WrapToggle call <sid>wraptoggle(<args>)

"###############################################################################
"TABULAR - ALIGNING AROUND :,=,ETC.
augroup tabular
augroup END
if has_key(g:plugs, "tabular")
  "Command for tabuarizing, but ignoring lines without delimiters
  function! s:table(arg) range
    "Remove the lines without matching regexes
    "* See: https://stackoverflow.com/a/40662545/4970632 for ideas
    "* One idea: try using :global/regex/# command inside a redir to direct the resulting
    "  message to a variable; will print lines with line numbers and newlines.
    "* Another idea: use :call search(...,line('.')), :delete, and exe <line> to successively move between
    "  lines, but better to use builtin vim text processing lines and not move the cursor.
    let dlines = [] "note we **cannot** use dictionary, because subsequent lines without matches will overwrite each other
    let firstline = a:firstline
    let lastline  = a:lastline  "no longer read-only
    let searchline = a:firstline
    let regex = split(a:arg, '/')[0] "regex is first part; other arguments are afterward
    while searchline <= lastline
      if getline(searchline) !~# regex "if return value is zero, delete this line
        "Delete <range> line; range is the line number
        let lastline -= 1 "after deletion, the 'last line' of selection has changed
        let dlines += [[searchline, getline(searchline)]]
        exe searchline.'d'
      else "leave it alone, increment search
        let searchline += 1
      endif
    endwhile
    "Execute tabularize function
    if firstline>lastline
      echom "Warning: No matches in selection."
    else
      exe firstline.','.lastline.'Tabularize '.a:arg
    endif
    "Add back the lines that were deleted
    for pair in reverse(dlines) "insert line of text below where deletion occurred (line '0' adds to first line)
      call append(pair[0]-1, pair[1])
    endfor
  endfunction
  "Command
  "* By default, :Tabularize command provided *without range* will select the
  "  contiguous lines that contain specified delimiter; so this function only makes
  "  sense when applied for a visual range! So we don't need to worry about using Tabularize's
  "  automatic range selection/implementing it in this special command
  "* Note odd concept (see :help args) that -nargs=1 will pass subsequent text, including
  "  whitespace, as single argument, but -nargs=*, et cetera, will aceept multiple arguments delimited by whitespace
  "* Be careful -- make sure to pass <args> in singly quoted string!
	command! -range -nargs=1 Table <line1>,<line2>call <sid>table('<args>')
  "NOTE: e.g. for aligning text after colons, input character :\zs; aligns first character after matching preceding regex
  "Align arbitrary character, and suppress error message if user Ctrl-c's out of input line
  nnoremap <silent> <expr> \<Space> ':silent! Tabularize /'.input('Align character(s): ').'/l1c1<CR>'
  vnoremap <silent> <expr> \<Space> "<Esc>:silent! '<,'>Table /".input('Align character(s): ').'/l1c1<CR>'
  "By commas; suitable for diag_table's in models; does not ignore comment characters
  nnoremap <expr> \, ':Tabularize /,\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \, ':Table      /,\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs/l0c1<CR>'
  "Dictionary, colon on right
  nnoremap <expr> \d ':Tabularize /\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs:/l0c1<CR>'
  vnoremap <expr> \d ':Table      /\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs:/l0c1<CR>'
  "Dictionary, colon on left
  nnoremap <expr> \D ':Tabularize /:\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \D ':Table      /:\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs/l0c1<CR>'
  "See :help non-greedy to see what braces do; it is like *, except instead of matching
  "as many as possible, can match as few as possible in some range;
  "with braces, a minus will mean non-greedy
  nnoremap <expr> \l ':Tabularize /^\s*\S\{-1,}\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\s/l0<CR>'
  vnoremap <expr> \l ':Table      /^\s*\S\{-1,}\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\s/l0<CR>'
  "Right-align by spaces, considering comments as one 'field'; other words are
  "aligned by space; very hard to ignore comment-only lines here, because we specify text
  "before the first 'field' (i.e. the entirety of non-matching lines) will get right-aligned
  nnoremap <expr> \r ':Tabularize /^\s*[^\t '.b:NERDCommenterDelims['left'].']\+\zs\ /r0l0l0<CR>'
  vnoremap <expr> \r ':Table      /^\s*[^\t '.b:NERDCommenterDelims['left'].']\+\zs\ /r0l0l0<CR>'
  "Check out documentation on \@<! atom; difference between that and \@! is that \@<!
  "checks whether something doesn't match *anywhere before* what follows
  "Also the \S has to come before the \(\) atom instead of after for some reason
  nnoremap <expr> \\ ':Tabularize /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
  vnoremap <expr> \\ ':Table      /\S\('.b:NERDCommenterDelims['left'].'.*\)\@<!\zs\ /l0<CR>'
  "As above, but include comments
  nnoremap <expr> \_ ':Tabularize /\S\zs\ /l0<CR>'
  vnoremap <expr> \_ ':Table      /\S\zs\ /l0<CR>'
  "By comment character; ^ is start of line, . is any char, .* is any number, \zs
  "is start match here (must escape backslash), then search for the comment
  nnoremap <expr> \C ':Tabularize /^.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  vnoremap <expr> \C ':Table      /^.*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  "By comment character, but this time ignore comment-only lines
  "Enforces that
  nnoremap <expr> \c ':Tabularize /^\s*[^ \t'.b:NERDCommenterDelims['left'].'].*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  vnoremap <expr> \c ':Table      /^\s*[^ \t'.b:NERDCommenterDelims['left'].'].*\zs'.b:NERDCommenterDelims['left'].'/l1<CR>'
  "Align by the first equals sign either keeping it to the left or not
  "The eaiser to type one (-=) puts equals signs in one column
  "This selects the *first* uncommented equals sign that does not belong to
  "a logical operator or incrementer <=, >=, ==, %=, -=, +=, /=, *= (have to escape dash in square brackets)
  nnoremap <expr> \= ':Tabularize /^[^'.b:NERDCommenterDelims['left'].']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  vnoremap <expr> \= ':Table      /^[^'.b:NERDCommenterDelims['left'].']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  nnoremap <expr> \+ ':Tabularize /^[^'.b:NERDCommenterDelims['left'].']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
  vnoremap <expr> \+ ':Table      /^[^'.b:NERDCommenterDelims['left'].']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
  " nnoremap <expr> \= ':Tabularize /^[^=]*\zs=/l1c1<CR>'
  " vnoremap <expr> \= ':Table      /^[^=]*\zs=/l1c1<CR>'
  " nnoremap <expr> \+ ':Tabularize /^[^=]*=\zs/l0c1<CR>'
  " vnoremap <expr> \+ ':Table      /^[^=]*=\zs/l0c1<CR>'
endif

"###############################################################################
"TAGBAR (requires 'brew install ctags-exuberant')
" * Note tagbar BufReadPost autocommand must come after the c:tags one, or
"   we end up just generating tags for the Tagbar sidebar buffer.
" * Note the default mappings:
"   -p jumps to tag under cursor, in code window, but remain in tagbar
"   -Enter jumps to tag, go to window (doesn't work for pseudo-tags, generic headers)
"   -C-n and C-p browses by top-level tags
"   - +,- open and close folds under cursor
"   -o toggles the fold under cursor, or current one
"   -q quits the window
if has_key(g:plugs, "tagbar")
  "Note to have tagbar open automatically FileType did not work; possibly some
  "conflict with Obsession; instead BufReadPost worked
  " augroup tagbar
  "   au!
  "   au BufReadPost * call s:tagbarmanager()
  " augroup END
  " function! s:tagbarmanager()
  "   if index(['.vimrc','.bashrc'], expand("%:t"))==-1
  "   if ".vimrc"=~expand("%:t") || (".py,.jl,.m,.tex"=~expand("%:e") && expand("%:e")!="")
  "   if ".vimrc"=~expand("%:t") || (".py,.jl,.m"=~expand("%:e") && expand("%:e")!="")
  "     call s:tagbarsetup()
  "   endif
  " endfunction
  "Setting up Tagbar with a custom configuration
  augroup tagbar
  augroup END
  function! s:tagbarsetup()
    "First toggle the tagbar; issues when toggling from NERDTree so switch
    "back if cursor is already there. No issues toggline from Help window.
    "Note toggling tagbar in a help menu appears to be fine
    if &ft=="nerdtree"
      wincmd h
      wincmd h "move two places in case e.g. have help menu + nerdtree already
    endif
    TagbarToggle
    if &ft=="tagbar"
      "Change the default open stuff for vimrc
      "Make sure normal commands align with maps
      let tabnms=map(tabpagebuflist(),'fnamemodify(bufname(v:val), ":t")')
      if index(tabnms,".vimrc")!=-1
        silent normal _
        call search("^\. autocommand groups$")
        silent normal =
        noh
      endif
      "Make sure NERDTree is always flushed to the far right
      "Do this by moving TagBar one spot to the left if it is opened
      "while NERDTree already open. If TagBar was opened first, NERDTree will already be far to the right.
      let tabfts=map(tabpagebuflist(),'getbufvar(v:val, "&ft")')
      if index(tabfts,"nerdtree")!=-1 | wincmd h | wincmd x | endif
      exe 'vertical resize '.g:tagbar_width
      wincmd p
    endif
  endfunction
  nnoremap <silent> <Leader>t :call <sid>tagbarsetup()<CR>
  "Global settings
  " let g:tagbar_iconchars = ['▸', '▾'] "prettier
  " let g:tagbar_iconchars = ['+', '-'] "simple
  let g:tagbar_silent=1 "no information echoed
  let g:tagbar_previewwin_pos="bottomleft" "result of pressing 'P'
  let g:tagbar_left=0 "open on left; more natural this way
  let g:tagbar_foldlevel=-1 "default none
  let g:tagbar_indent=-1 "only one space indent
  let g:tagbar_autoshowtag=0 "do not open tag folds when cursor moves over one
  let g:tagbar_show_linenumbers=0 "don't show line numbers
  let g:tagbar_autofocus=1 "don't autojump to window if opened
  let g:tagbar_sort=1 "sort alphabetically? actually much easier to navigate, so yes
  let g:tagbar_case_insensitive=1 "make sorting case insensitive
  let g:tagbar_compact=1 "no header information in panel
  let g:tagbar_singleclick=0 "one click select; annoying
  let g:tagbar_width=15 "better default
  let g:tagbar_zoomwidth=15 "don't ever 'zoom' even if text doesn't fit
  let g:tagbar_expand=0
  let g:tagbar_map_closefold="-"
  let g:tagbar_map_openfold="="
  let g:tagbar_map_closeallfolds="_"
  let g:tagbar_map_openallfolds="+"
endif

"###############################################################################
"###############################################################################
" GENERAL STUFF, BASIC REMAPS
"###############################################################################
"###############################################################################
"BUFFER WRITING/SAVING
"Just declare a couple maps here
augroup saving
augroup END
nnoremap <silent> <C-s> :w!<CR>
nnoremap <silent> <C-x> :echom "Ctrl-x reserved for tmux commands. Use Ctrl-b to compile instead."<CR>
nnoremap <silent> <C-r> :if &ft=="vim" \| so % \| echom "Sourced file." \| endif<CR>
"use force write, in case old version exists
nnoremap <silent> <C-a> :qa<CR> 
nnoremap <silent> <C-q> :let g:tabpagelast=(tabpagenr('$')==tabpagenr())<CR>:if tabpagenr('$')==1
      \\| qa \| else \| tabclose \| if !g:tabpagelast \| silent! tabp \| endif \| endif<CR>
nnoremap <silent> <C-w> :let g:tabpagenr=tabpagenr('$')<CR>:let g:tabpagelast=(tabpagenr('$')==tabpagenr())<CR>
      \:q<CR>:if g:tabpagenr!=tabpagenr('$') && !g:tabpagelast \| silent! tabp \| endif<CR>
"so we have close current window, close tab, and close everything
"last map has to test wither the :q action closed the entire tab
silent! tnoremap <silent> <C-c> <C-w>:q!<CR>
silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
silent! nnoremap <Leader>T :terminal<CR>
" silent! tnoremap <silent> <Esc> <C-\><C-n>
"exit terminal mode, if exists; or enter terminal normal mode

"###############################################################################
"IMPORTANT STUFF
"First line disables linebreaking no matter what ftplugin says, got damnit
augroup settings
  au!
  autocmd BufEnter * set textwidth=0
augroup END
"Tabbing
set expandtab "says to always expand \t to their length in <SPACE>'s!
set autoindent "indents new lines
set backspace=indent,eol,start "backspace by indent - handy
"VIM configures backspace-delete by tabs
"We implement our own function to forewards-delete by tabs
function! s:foreward_delete()
  "Return 'literal' delete keypresses using backslash in double quotes
  let line=getline('.')
  if line[col('.')-1:col('.')-1+&tabstop-1]==repeat(" ",&tabstop)
    return repeat("\<Delete>",&tabstop)
  else
    return "\<Delete>"
  endif
endfunction
inoremap <silent> <expr> <Delete> <sid>foreward_delete()
"Wrapping
set textwidth=0 "also disable it to start with dummy
set linebreak "breaks lines only in whitespace makes wrapping acceptable
set wrapmargin=0 "starts wrapping at the edge; >0 leaves empty bufferzone
set display=lastline "displays as much of wrapped lastline as possible;
"Global behavior
set nostartofline "when switching buffers, doesn't move to start of line (weird default)
set nolazyredraw  "maybe slower, but looks super cool and pretty and stuff
set virtualedit=  "prevent cursor from going where no actual character
set noerrorbells visualbell t_vb=
  "set visualbell ENABLES internal bell; but t_vb= means nothing is shown on the window
"Multi-key mappings and Multi-character keycodes
set esckeys "make sure enabled; allows keycodes
set notimeout timeoutlen=0 "so when timeout is disabled, we do this
set ttimeout ttimeoutlen=0 "no delay after pressing <Esc>
  "the first one says wait forever when doing multi-key mappings
  "the second one says wait 0seconds for multi-key keycodes e.g. <S-Tab>=<Esc>[Z
"Improve wildmenu behavior (command mode file/dir suggestions)
"From this: https://stackoverflow.com/a/14849216/4970632
set confirm "require confirmation if you try to quit
set wildmenu
set wildmode=longest:list,full
function! s:wildtab()
  call feedkeys("\<Tab>", 't') | return ''
endfunction
function! s:wildstab()
  call feedkeys("\<S-Tab>", 't') | return ''
endfunction
"Use ctrl-, and ctrl-. to navigate (mapped with iterm2)
cnoremap <expr> <F1> <sid>wildstab()
cnoremap <expr> <F2> <sid>wildtab()
cnoremap <C-h>   <Left>
cnoremap <C-l>   <Right>
cnoremap <C-k>   <Up>
cnoremap <C-j>   <Down>
cnoremap <C-p>   <Up>
cnoremap <C-n>   <Down>
cnoremap <Down>  <Nop>
cnoremap <Up>    <Nop>
cnoremap <Left>  <Nop>
cnoremap <Right> <Nop>

"###############################################################################
"SPECIAL TAB NAVIGATION
"Remember previous tab
augroup tabs
  au!
  au TabLeave * let g:lasttab=tabpagenr()
augroup END
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
noremap <Tab>, gT
noremap <Tab>. gt
let g:lasttab=1
noremap <silent> <Tab>' :execute "tabn ".g:lasttab<CR>
  "return to previous tab
"Moving around
nnoremap <Tab>u zt
nnoremap <Tab>o zb
nnoremap <Tab>i mzz.`z
nnoremap <Tab>q H
nnoremap <Tab>w M
nnoremap <Tab>e L
nnoremap <Tab>y zH
nnoremap <Tab>p zL
"Fix tab maps otherwise
noremap <Tab> <Nop>
noremap <Tab><Tab> <Nop>
"Move current tab to the exact place of tab no. N
"This is not default behavior
function! s:tabmove(n)
  if a:n==tabpagenr() || a:n==0
    return
  elseif a:n>tabpagenr() && version[0]>7 "may be version dependent behavior of tabmove;
    "on my version 8 seems to always position to left, but on Gauss server, different
    echo 'Moving tab...'
    execute 'tabmove '.a:n
  else
    echo 'Moving tab...'
    execute 'tabmove '.eval(a:n-1)
  endif
endfunction
function! s:tablist(A,L,P)
  return map(range(1,tabpagenr('$')),'string(v:val)')
endfunction
noremap <silent> <Tab>m :silent! call <sid>tabmove(input('Move tab: ', '', 'customlist,<sid>tablist'))<CR>
noremap <silent> <Tab>> :call <sid>tabmove(eval(tabpagenr()+1))<CR>
noremap <silent> <Tab>< :call <sid>tabmove(eval(tabpagenr()-1))<CR>
"Next a function for completing stuff, *including* hidden files god damnit
"Note allfiles function seems to have to be in local scope; otherwise can't find s:allfiles or <sid>allfiles
function! AllFiles(A,L,P)
  let path=(len(a:A)>0 ? a:A : '')
  let result=split(glob(path.'*'),'\n') + split(glob(path.'.*'),'\n')
  let final=[]
  for string in result "ignore 'this directory' and 'parent directory'
    if string !~ '^\(.*/\)\?\.\{1,2}$'
      call extend(final, [substitute((isdirectory(string) ? string.'/' : string ), '/\+', '/', 'g')])
    endif
  endfor
  return final
endfunction
function! s:openwrapper()
  let response=input('Open tab ('.getcwd().'): ', '', 'customlist,AllFiles')
  if response!=''
    exe 'tabe '.response
  else
    echom "Cancelled."
  endif
endfunction
nnoremap <silent> <C-o> :call <sid>openwrapper()<CR>
"Splitting -- make :sp and :vsp split to right and bottom
set splitright
set splitbelow
noremap <Tab>- :split 
noremap <Tab>\ :vsplit 
"Window selection
noremap <Tab>j <C-w>j
noremap <Tab>k <C-w>k
noremap <Tab>h <C-w>h
noremap <Tab>l <C-w>l
"Switch to last window
nnoremap <Tab>; <C-w><C-p>

"###############################################################################
"COPY/PASTING CLIPBOARD
"Pastemode toggling; pretty complicated
"Really really really want to toggle with <C-v> since often hit Ctrl-V, Cmd-V, so
"makes way more sense, but that makes inserting 'literal chars' impossible
"Workaround is to map cv to enter insert mode with <C-v>
nnoremap <expr> <silent> <Leader>v ":if &eventignore=='' \| setlocal eventignore=InsertEnter \| echom 'Ctrl-V pasting disabled for next InsertEnter.' "
  \." \| else \| setlocal eventignore= \| echom '' \| endif<CR>"
augroup copypaste
  au!
  au InsertLeave * set nopaste | setlocal eventignore= "if pastemode was toggled, turn off
  au InsertLeave * set pastetoggle=
  au InsertEnter * set pastetoggle=<C-v> "need to use this, because mappings don't work
  " au InsertEnter * set pastetoggle=
  "when pastemode is toggled; might be able to remap <set paste>, but cannot have mapping for <set nopaste>
augroup END
"Copymode to eliminate special chars during copy
"See :help &l:; this gives the local value of setting
function! s:copytoggle(...)
  if a:0
    let toggle = a:1
  else
    let toggle = !exists("b:number")
  endif
  let copyprops=["number", "list", "relativenumber", "scrolloff"]
  if toggle "save current settings to buffer variable
    for prop in copyprops
      if !exists("b:".prop) "do not overwrite previously saved settings
        exe "let b:".prop."=&l:".prop
      endif
      exe "let &l:".prop."=0"
    endfor
    echo "Copy mode enabled."
  else "want to restore a bunch of settings
    for prop in copyprops
      exe "silent! let &l:".prop."=b:".prop
      exe "silent! unlet b:".prop
    endfor
    echo "Copy mode disabled."
  endif
endfunction
nnoremap <C-c> :call <sid>copytoggle()<CR>
command! -nargs=? CopyToggle call <sid>copytoggle(<args>)
"yank because from Vim, we yank; but remember, c-v is still pastemode
"-nargs=? means 0 or 1

"###############################################################################
"SEARCHING AND FIND-REPLACE STUFF
"Basic stuff first
" * Had issue before where InsertLeave ignorecase autocmd was getting reset; it was
"   because MoveToNext was called with au!, which resets all InsertLeave commands then adds its own
" * Make sure 'noignorecase' turned on when in insert mode, so *autocompletion* respects case.
augroup searchreplace
  au!
  au InsertEnter * set noignorecase "default ignore case
  au InsertLeave * set ignorecase
augroup END
set hlsearch incsearch "show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase "smartcase makes search case insensitive, unless has capital letter

"###############################################################################
"DELETING STUFF TOOLS
"Will use the 'g' prefix for these, because why not
"see https://unix.stackexchange.com/a/12814/112647 for idea on multi-empty-line map
augroup delete
augroup END
"Replace commented lines; very useful when sharing manuscripts
nnoremap <silent> <expr> \n ':%s/\(^\s*'.b:NERDCommenterDelims['left'].'.*$\n'
      \.'\\|^.*\S*\zs\s\+'.b:NERDCommenterDelims['left'].'.*$\)//gc<CR>'
vnoremap <silent> <expr> \n ':s/\(^\s*'.b:NERDCommenterDelims['left'].'.*$\n'
      \.'\\|^.*\S*\zs\s\+'.b:NERDCommenterDelims['left'].'.*$\)//gc<CR>'
"Replace consecutive spaces on current line with one space
nnoremap <silent> \w :s/\(^ \+\)\@<! \{2,}/ /g<CR>:echom "Squeezed consecutive spaces."<CR>
"Replace trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
"Will probably be necessary after the comment trimming
nnoremap <silent> \W :%s/\s\+$//g<CR>:echom "Trimmed trailing whitespace."<CR>
vnoremap <silent> \W :s/\s\+$//g<CR>:echom "Trimmed trailing whitespace."<CR>
"Delete empty lines
nnoremap <silent> \E :%s/^\s*$\n//g<CR>:echom "Removed empty lines."<CR>
vnoremap <silent> \E :s/^\s*$\n//g<CR>:echom "Removed empty lines."<CR>
"Replace consecutive newlines with single newline
vnoremap <silent> \e :s/\(\n\s*\n\)\(\s*\n\)\+/\1/g<CR>:echom "Squeezed consecutive newlines."<CR>
nnoremap <silent> \e :%s/\(\n\s*\n\)\(\s*\n\)\+/\1/g<CR>:echom "Squeezed consecutive newlines."<CR>
"Replace all tabs
vnoremap <expr> <silent> \<Tab> ':s/\t/'.repeat(' ',&tabstop).'/g<CR>'
nnoremap <expr> <silent> \<Tab> ':%s/\t/'.repeat(' ',&tabstop).'/g<CR>'
"Fix unicode quotes and dashes, trailing dashes due to a pdf copy
nnoremap <silent> \' :silent! %s/‘/`/g<CR>:silent! %s/’/'/g<CR>:echom "Fixed single quotes."<CR>
nnoremap <silent> \" :silent! %s/“/``/g<CR>:silent! %s/”/'/g<CR>:echom "Fixed double quotes."<CR>
nnoremap <silent> \_ :silent! %s/–/--/g<CR>:echom "Fixed long dashes."<CR>
nnoremap <silent> \- :silent! %s/\(\w\)[-–] /\1/g<CR>:echom "Fixed trailing dashes."<CR>
"Replace useless BibTex entries
nnoremap <silent> \X :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=.*$\n//gc<CR>
" nnoremap <expr> gX ':%s/^\s*'.b:NERDCommenterDelims['left'].'.*$\n//gc<CR>'

"###############################################################################
"CAPS LOCK WITH C-a IN INSERT/COMMAND MODE
"The autocmd is confusing, but better than an autocmd that lmaps and lunmaps;
"that would cancel command-line queries (or I'd have to scroll up to resume them)
"don't think any other mapping type has anything like lmap; iminsert is unique
augroup capslock
  au!
  autocmd InsertLeave,CmdwinLeave * set iminsert=0
augroup END
"lmap == insert mode, command line (:), and regexp searches (/)
"See <http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock>; instead uses
"iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1 via
"<C-^> (not avilable for custom remap, since ^ is not alphabetical)
set iminsert=0
for c in range(char2nr('A'), char2nr('Z'))
  exe 'lnoremap '.nr2char(c+32).' '.nr2char(c)
  exe 'lnoremap '.nr2char(c).' '.nr2char(c+32)
endfor
inoremap <C-z> <C-^>
cnoremap <C-z> <C-^>
  "can't lnoremap the above, because iminsert is turning it on and off

"###############################################################################
"FOLDING STUFF AND Z-PREFIXED COMMANDS
augroup z
augroup END
"SimpylFold settings
let g:SimpylFold_docstring_preview=1
let g:SimpylFold_fold_import=0
let g:SimpylFold_fold_imports=0
let g:SimpylFold_fold_docstring=0
let g:SimpylFold_fold_docstrings=0
"Basic settings
" set nofoldenable
set foldmethod=expr
set foldlevel=99
set foldlevelstart=99
"More options
" set foldlevel=2
set foldnestmax=10 "avoids weird things
set foldopen=tag,mark "options for opening folds on cursor movement; disallow block
  "i.e. percent motion, horizontal motion, insert, jump
"Folding maps
nnoremap zD zE
  "delete all folds; delete fold at cursor is zd
nnoremap z> zM
nnoremap z< zR
  "never need the lower-case versions (which globally change fold levels), but
  "often want to open/close everything; this mnemonically makes sense because
  "folding is sort-of like indenting really
nnoremap zO zR
nnoremap zC zM
  "open and close all folds; to open/close under cursor, use zo/zc
"Overhaul z-remaps for controlling window state; make them Tab-prexied
"maps, because I *hate* inconsistency; want all window-related maps to have same prefix
noremap <expr> <silent> <Tab>9 '<Esc>:resize '.(winheight(0)-3*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>0 '<Esc>:resize '.(winheight(0)+3*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>( '<Esc>:resize '.(winheight(0)-5*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>) '<Esc>:resize '.(winheight(0)+5*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>[ '<Esc>:vertical resize '.(winwidth(0)-5*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>] '<Esc>:vertical resize '.(winwidth(0)+5*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>{ '<Esc>:vertical resize '.(winwidth(0)-10*max([1,v:count])).'<CR>'
noremap <expr> <silent> <Tab>} '<Esc>:vertical resize '.(winwidth(0)+10*max([1,v:count])).'<CR>'
noremap <silent> <Tab>= :vertical resize 80<CR>
  "and the z-prefix is a natural companion to the resizing commands
  "the Tab commands should just sort and navigate between panes
  "think of the 0 as 'original size', like cmd-0 on macbook
"To prevent delay; this is associated with FastFold or something
silent! unmap zuz
"Change fold levels, and make sure return to same place
"Never really use this feature so forget it
" nnoremap <silent> zl :let b:position=winsaveview()<CR>zm:call winrestview(b:position)<CR>
" nnoremap <silent> zh :let b:position=winsaveview()<CR>zr:call winrestview(b:position)<CR>

"###############################################################################
"g CONFIGURATION
"SINGLE-KEYSTROKE MOTION BETWEEN FUNCTIONS
"Single-keystroke indent, dedent, fix indentation
augroup g
augroup END
"Don't know why these are here but just go with it bro
nnoremap <silent> <Leader>r :redraw!<CR>
nnoremap <silent> <Leader>S :w \| filetype detect \| so ~/.vimrc<CR>:echom "Refreshed .vimrc and re-loaded syntax."<CR>
"Complete overview of g commands here; change behavior a bit to
"be more mnemonically sensible and make wrapped-line editing easier, but is great
"Undo these maps to avoid confusion
noremap gt <Nop>
noremap gT <Nop>
"Jumping between comments; pretty neat huh?
"Moves cursor in whatever mode you want
"Also, jump between empty lines
function! s:smartjump(regex,backwards) "jump to next comment
  let startline=line('.')
  let flag=(a:backwards ? 'Wnb' : 'Wn') "don't wrap around EOF, and don't jump yet
  let offset=(a:backwards ? 1 : -1) "actually want to jump to line *just before* comment
  let commentline=search(a:regex,flag)
  if getline('.') =~# a:regex
    return startline
  elseif commentline==0
    return startline "don't move
  else
    return commentline+offset
  endif
endfunction
noremap <expr> <silent> gc <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],0).'gg'
noremap <expr> <silent> gC <sid>smartjump('^\s*'.b:NERDCommenterDelims['left'],1).'gg'
noremap <expr> <silent> ge <sid>smartjump('^\s*$',0).'gg'
noremap <expr> <silent> gE <sid>smartjump('^\s*$',1).'gg'
"Select all maps
nnoremap gG ggVG
vnoremap gG <Esc>ggVG
"Analogue to gg; also opens up 'G' as a prefix
nnoremap GG G
"Default 'open file under cursor' to open in new tab; change for normal and vidual
noremap gf <c-w>gf
noremap <expr> gF ":if len(glob('<cfile>'))>0 \| echom 'File(s) exist.' "
  \."\| else \| echom 'File(s) do not exist.' \| endif<CR>"
"Capitalization stuff with g, a bit refined
"not currently used in normal mode, and fits better mnemonically
nnoremap gu guiw
vnoremap gu gu
nnoremap gU gUiw
vnoremap gU gU
vnoremap g. ~
nnoremap <Plug>cap1 ~h:call repeat#set("\<Plug>cap1")<CR>
nnoremap <Plug>cap2 mzguiw~h`z:call repeat#set("\<Plug>cap2")<CR>
nmap g. <Plug>cap1
nmap gt <Plug>cap2
" nnoremap g. ~h
" nnoremap gt mzguiw~h`z
"Free up m keys, so ge/gE command belongs as single-keystroke words along with e/E, w/W, and b/B
noremap m ge
noremap M gE
"Repeat last command
noremap <silent> g; :<Up><CR>
"Enter command window, execute stuff with enter key; that is the default but we want
"enter to not move cursor ordinarily, so have to unmap it after entering window.
"Oddly writing a function that declares maps, and calling it after using q:, did
"not work, and making all of the map commands one line with \| did not work. Only the below works.
noremap <silent> <Leader>; q::silent! unmap <lt>CR><CR>:silent! unmap <lt>C-c><CR>
  \:noremap <lt>buffer <lt>C-b> <lt>C-c><CR>:inoremap <lt>buffer> <lt>C-b> <lt>C-c><CR>
noremap <silent> <Leader>/ q/:silent! unmap <lt>CR><CR>:silent! unmap <lt>C-c><CR>
  \:noremap <lt>buffer <lt>C-b> <lt>C-c><CR>:inoremap <lt>buffer> <lt>C-b> <lt>C-c><CR>
"Now remap indentation commands. Why is this here? Just go with it.
" * Meant to mimick visual-mode > and < behavior.
" * Note the <Esc> is needed first because it cancels application of the number operator
"   to what follows; we want to use that number operator for our own purposes
if g:has_nowait
  nnoremap <expr> <nowait> > v:count > 1 ? '<Esc>'.repeat('>>',v:count) : '>>'
  nnoremap <expr> <nowait> < v:count > 1 ? '<Esc>'.repeat('<<',v:count) : '<<'
  nnoremap <nowait> = ==
else
  nnoremap <expr> >> v:count ? '<Esc>'.repeat('>>',v:count) : '>>'
  nnoremap <expr> << v:count ? '<Esc>'.repeat('<<',v:count) : '<<'
endif
"Moving between functions, from: https://vi.stackexchange.com/a/13406/8084
"Must be re-declared every time enter file because g<stuff>, [<stuff>, and ]<stuff> may get re-mapped
"DON'T DO THIS, THEY WERE RIGHT! NOT WORTH IT! START TO LOSE KEYBOARD-SPACE BECAUSE HAVE TO
"REMAP OTHER KEYS TO SOME OF THE LOST g<key> FUNCTIONS!
" nnoremap <silent> <nowait> g gg
" vnoremap <silent> <nowait> g gg
" function! s:gmaps()
"   " nmap <silent> <buffer> <nowait> g :<C-u>exe 'normal '.v:count.'gg'<CR>
"   nmap <silent> <buffer> <nowait> g gg
"   vmap <silent> <buffer> <nowait> g gg
"     "don't know why this works, but it does; just using nnoremap above fails
"     "and trying the <C-u> exe thing results in 'command too recursive'
" endfunction
" autocmd FileType * call s:gmaps()

"###############################################################################
"SPECIAL SYNTAX HIGHLIGHTING OVERWRITE (all languages; must come after filetype stuff)
"See this thread (https://vi.stackexchange.com/q/9433/8084) on modifying syntax
"for every file; we add our own custom highlighting for vim comments
"For adding keywords, see: https://vi.stackexchange.com/a/11547/8084
"Will also enforce shebang always has the same color, because it's annoying otherwise
"And generally only want 'conceal' characters invisible for latex; otherwise we
"probably want them to look like comment characters
set cursorline
augroup syntax
  au!
  " au Syntax *.tex syn match Ignore '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@=' conceal
  " au Syntax *.tex call matchadd('Conceal', '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@=', 0, -1, {'conceal': ''})
  au BufRead * set concealcursor=ncv conceallevel=2 "conceal stuff when in normal/command mode; only reveal when insert/visual
  au Syntax * if &ft!="vim" | syn match Todo '\<\%(WARNING\|FIXME\|TODO\|NOTE\|XXX\)\ze:\=\>' containedin=.*Comment | syn match Special '^\%1l#!.*$' | endif
  " au BufEnter * if &ft=="tex" | hi Conceal ctermbg=None ctermfg=None | else | hi Conceal ctermbg=None ctermfg=Black | endif
  au InsertEnter * highlight StatusLine ctermbg=White ctermfg=Black cterm=None
  au InsertLeave * highlight StatusLine ctermbg=Black ctermfg=White cterm=None
augroup END
"Status line
highlight StatusLine ctermbg=Black ctermfg=White cterm=None
"Create dummy group -- will be transparent, but use to add @Nospell
highlight Dummy ctermbg=None ctermfg=None
"Magenta is uncommon color, so change this
"Note if Sneak undefined, this won't raise error; vim thinkgs maybe we will define it later
highlight Sneak ctermbg=DarkMagenta ctermfg=None
"And search/highlight stuff; by default foreground is black, make it transparent
highlight Search ctermbg=Magenta ctermfg=None
"Fundamental changes, move control from LightColor to Color and DarkColor, because
"ANSI has no control over light ones it seems.
"Generally 'Light' is NormalColor and 'Normal' is DarkColor
highlight Type ctermbg=None ctermfg=DarkGreen
highlight Constant ctermbg=None ctermfg=Red
highlight Special ctermbg=None ctermfg=DarkRed
highlight Indentifier cterm=Bold ctermbg=None ctermfg=Cyan
highlight PreProc ctermbg=None ctermfg=DarkCyan
"Make Conceal highlighting group ***transparent***, so that when you
"set the conceallevel to 0, concealed elements revert to their original highlighting.
highlight Conceal ctermbg=None ctermfg=None
"Special characters
highlight Comment ctermfg=Black cterm=None
highlight NonText ctermfg=Black cterm=None
highlight SpecialKey ctermfg=Black cterm=None
"Matching parentheses
highlight Todo ctermfg=None ctermbg=Red
highlight MatchParen ctermfg=None ctermbg=Blue
"Cursor line or column highlighting using color mapping set by CTerm (PuTTY lets me set
"background to darker gray, bold background to black, 'ANSI black' to a slightly lighter
"gray, and 'ANSI black bold' to black).
"Note 'lightgray' is just normal white
highlight LineNR cterm=None ctermfg=Black ctermbg=None
highlight CursorLine cterm=None ctermbg=Black
highlight CursorLineNR cterm=None ctermfg=Yellow ctermbg=Black
"Column stuff; color 80th column, and after 120
highlight ColorColumn cterm=None ctermbg=Gray
highlight SignColumn cterm=None ctermfg=Black ctermbg=None
"Make sure terminal is black, for versions with :terminal command
highlight Terminal ctermbg=Black

"###############################################################################
"USEFUL COMMANDS
"Highlight group under cursor
function! s:group()
  echo "actual <".synIDattr(synID(line("."),col("."),1),"name")."> "
    \."appears <".synIDattr(synID(line("."),col("."),0),"name")."> "
    \."group <".synIDattr(synIDtrans(synID(line("."),col("."),1)),"name").">"
endfunction
command! Group call <sid>group()
"The :syntax commands within that group
function! s:syntax(name)
  if a:name
    exe "verb syntax list ".a:name
  else
    " echo "Name: ".synIDattr(synID(line("."),col("."),0),"name") | sleep 500 m
    exe "verb syntax list ".synIDattr(synID(line("."),col("."),0),"name")
  endif
endfunction
command! -nargs=? Syntax call <sid>syntax('<args>')
"Toggle conceal
function! s:concealtoggle(...)
  if a:0
    let conceal_on=a:1
  else
    let conceal_on=(&conceallevel ? 0 : 2) "turn off and on
  endif
  exe 'set conceallevel='.(conceal_on ? 2 : 0)
endfunction
command! -nargs=? ConcealToggle call <sid>concealtoggle(<args>)
"Get current plugin file
"Remember :scriptnames lists all loaded files
function! s:ftplugin()
  "Enable 'simple' mode
  execute 'split $VIMRUNTIME/ftplugin/'.&filetype.'.vim'
  silent Simple
endfunction
function! s:ftsyntax()
  execute 'split $VIMRUNTIME/syntax/'.&filetype.'.vim'
  silent Simple
endfunction
command! PluginFile call <sid>ftplugin()
command! SyntaxFile call <sid>ftsyntax()
"Window displaying all colors
function! s:colors()
  source $VIMRUNTIME/syntax/colortest.vim
  silent Simple
endfunction
command! Colors call <sid>colors()
command! GroupColors vert help group-name

"###############################################################################
"###############################################################################
"EXIT
"###############################################################################
"###############################################################################
"Clear past jumps
"Don't want stuff from plugin files and the vimrc populating jumplist after statrup
"Simple way would be to use au BufRead * clearjumps
"But older versions of VIM have no 'clearjumps' command, so this is a hack
"see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clearjumps
  au!
  if exists(":clearjumps") | au BufRead * clearjumps "see help info on exists()
  else | au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  endif
augroup END
"Clear writeable registers
"On some vim versions [] fails (is ideal, because removes from :registers), but '' will at least empty them out
"See thread: https://stackoverflow.com/questions/19430200/how-to-clear-vim-registers-effectively
"For some reason the setreg function fails
command! WipeReg for i in range(34,122) | silent! call setreg(nr2char(i), '') | silent! call setreg(nr2char(i), []) | endfor
WipeReg
" command! WipeReg let regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"' | let i=0 | while i<strlen(regs) | exec 'let @'.regs[i].'=""' | let i=i+1 | endwhile | unlet regs
noh "turn off highlighting at startup
redraw! "weird issue sometimes where statusbar disappears
" suspend
" echom 'Custom vimrc loaded.'
