"-----------------------------------------------------------------------------"
" vint: -ProhibitSetNoCompatible
" A fancy vimrc that does all sorts of magical things.
" NOTE: Have iTerm map some ctrl+key combinations that would otherwise
" be impossible to the F1, F2 keys. Currently they are:
"     F1: 1b 4f 50 (Ctrl-,)
"     F2: 1b 4f 51 (Ctrl-.)
"     F3: 1b 4f 52 (Ctrl-i)
"     F4: 1b 4f 53 (Ctrl-m)
" Previously used the below but no longer
"     F5: 1b 5b 31 35 7e (shift-forward delete/shift-caps lock on macbook)
"     F6: 1b 5b 31 37 7e (Ctrl-;)
" Also use Karabiner 'map Ctrl-j/k/h/l to arrow keys', so be aware that if
" you map those keys in Vim, should also map arrows.
" Note when installing with anaconda, you may need to run
" conda install -y conda-forge::ncurses first
"-----------------------------------------------------------------------------"
" IMPORTANT STUFF and SETTINGS
let &t_Co=256
exe 'runtime autoload/repeat.vim'
if ! exists('*repeat#set')
  echohl WarningMsg
  echom 'Warning: vim-repeat unavailable, some features will be unavailable.'
  echohl None
endif

" Global settings
set nocompatible  " always use the vim defaults
set encoding=utf-8
scriptencoding utf-8
let mapleader = "\<Space>"
set confirm  " require confirmation if you try to quit
set cursorline
set showtabline=2
set tabpagemax=100  " allow opening shit load of tabs at once
set redrawtime=5000  " sometimes takes a long time, let it happen
set maxmempattern=50000  " from 1000 to 10000
set shortmess=atqcT  " snappy messages; 'a' does a bunch of common stuff
set shiftround  " round to multiple of shift width
set viminfo='100,:100,<100,@100,s10,f0  " commands, marks (e.g. jump history), exclude registers >10kB of text
set history=100  " search history
set shell=/usr/bin/env\ bash
set nrformats=alpha  " never interpret numbers as 'octal'
set scrolloff=4
let &g:colorcolumn = (has('gui_running') ? '0' : '80,120')
set slm=  " disable 'select mode' slm, allow only visual mode for that stuff
set background=dark  " standardize colors -- need to make sure background set to dark, and should be good to go
set updatetime=1000  " used for CursorHold autocmds
set nobackup noswapfile noundofile  " no more swap files; constantly hitting C-s so it's safe
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set number numberwidth=4  " note old versions can't combine number with relativenumber
set relativenumber
set tabstop=2  " shoft default tabs
set shiftwidth=2
set softtabstop=2
set autoindent  " indents new lines
set backspace=indent,eol,start  " backspace by indent - handy
set nostartofline  " when switching buffers, doesn't move to start of line (weird default)
set lazyredraw
set virtualedit=  " prevent cursor from going where no actual character
set noerrorbells visualbell t_vb=  " enable internal bell, t_vb= means nothing is shown on the window
set esckeys  " make sure enabled, allows keycodes
set notimeout timeoutlen=0  " wait forever when doing multi-key *mappings*
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set complete+=k  " enable dictionary search through 'dcitionary' setting
set completeopt-=preview  " no popup window, for now
set splitright  " splitting behavior
set splitbelow
set nospell spelllang=en_us spellcapcheck=  " spellcheck off by default
set hlsearch incsearch  " show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase  " smartcase makes search case insensitive, unless has capital letter
set foldmethod=expr  " fold methods
set foldlevel=99
set foldlevelstart=99
set foldnestmax=10  " avoids weird things
set foldopen=tag,mark  " options for opening folds on cursor movement; disallow block
set display=lastline  " displays as much of wrapped lastline as possible;
set diffopt=vertical,foldcolumn:0,context:5
set wildmenu
set wildmode=longest:list,full
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
let &g:breakat = ' 	!*-+;:,./?'  " break at single instances of several characters
let &g:wildignore = '*.pdf,*.doc,*.docs,*.page,*.pages,'
  \ . '*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.o,*.mod,'
  \ . '*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4,'
  \ . '*.dmg,*.zip,*.sw[a-z],*.tmp,*.nc,*.DS_Store,'
if exists('&diffopt')
  set diffopt^=filler
endif
if exists('&breakindent')
  set breakindent  " map indentation when breaking
endif
if !exists('b:expandtab')
  set expandtab  " only expand if TabToggle has not been called!
endif  " says to always expand \t to their length in <SPACE>'s!
if has('gui_running')
  set number relativenumber guioptions= guicursor+=a:blinkon0  " no scrollbars or blinking
endif

" Special settings
let g:set_overrides = 'linebreak wrapmargin=0 textwidth=0 formatoptions=lroj'
exe 'setlocal ' . g:set_overrides
augroup set_overrides
  au!
  au BufEnter * exe 'setlocal ' . g:set_overrides
augroup END

" Tab and conceal toggling
let g:tab_filetypes = ['text', 'gitconfig', 'make']
augroup tab_toggle
  au!
  exe 'au FileType ' . join(g:tab_filetypes, ',') . ' TabToggle 1'
augroup END
command! -nargs=? ConcealToggle call utils#conceal_toggle(<args>)
command! -nargs=? TabToggle call utils#tab_toggle(<args>)
nnoremap <Leader><Tab> :TabToggle<CR>

" Escape repair needed when we allow h/l to change line num
augroup escape_fix
  au!
  au InsertLeave * normal! `^
augroup END

" Global functions, for vim scripting
function! In(list,item)  " whether inside list
  return index(a:list,a:item) != -1
endfunction
function! Reverse(text)  " reverse string
  return join(reverse(split(a:text, '.\zs')), '')
endfunction
function! Strip(text)  " strip leading and trailing whitespace
  return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" Query whether plugin is loaded
function! PlugActive(key)
  return has_key(g:plugs, a:key)  " change as needed
endfunction

" Reverse selected lines
function! ReverseLines(l1, l2)
  let line1 = a:l1  " cannot overwrite input var names
  let line2 = a:l2
  if line1 == line2
    let line1 = 1
    let line2 = line('$')
  endif
  exec 'silent '.line1.','.line2.'g/^/m'.(line1 - 1)
endfunction
command! -range Reverse call ReverseLines(<line1>, <line2>)

" Better grep, with limited regex translation
function! Grep(regex)  " returns list of matches
  let regex = a:regex
  let regex = substitute(regex, '\(\\<\|\\>\)', '\\b', 'g') " not sure why double backslash needed
  let regex = substitute(regex, '\\s', "[ \t]",  'g')
  let regex = substitute(regex, '\\S', "[^ \t]", 'g')
  let result = split(system("grep '".regex."' ".@%.' 2>/dev/null'), "\n")
  echo result
  return result
endfunction
command! -nargs=1 Grep call Grep(<q-args>)

" Get comment character
" The placeholder is supposed to be a
function! Comment()
  if &ft !=# '' && &commentstring =~# '%s'
    return Strip(split(&commentstring, '%s')[0])
  else
    return ''
  endif
endfunction

" As above but return a character that is never matched if no comment char found
" This is for use in Tabular regex statements
function! RegexComment()
  let char = Comment()
  if ! len(char)  " empty
    let char = nr2char(0) " null string, never matched
  endif
  return char
endfunction

" Remove weird Cheyenne maps, not sure how to isolate/disable /etc/vimrc without
" disabling other stuff we want e.g. syntax highlighting
if len(mapcheck('<Esc>', 'n'))
  silent! unmap <Esc>[3~
  let s:insert_maps = ['[3~', '[6;3~', '[5;3~', '[3;3~', '[2;3~', '[1;3F',
    \ '[1;3H', '[1;3B', '[1;3A', '[1;3C', '[1;3D', '[6;5~', '[5;5~',
    \ '[3;5~', '[2;5~', '[1;5F', '[1;5H', '[1;5B', '[1;5A', '[1;5C',
    \ '[1;5D', '[6;2~', '[5;2~', '[3;2~', '[2;2~', '[1;2F', '[1;2H',
    \ '[1;2B', '[1;2A', '[1;2C', '[1;2D']
  for s:insert_map in s:insert_maps
    exe 'silent! iunmap <Esc>'.s:insert_map
  endfor
endif

" Suppress all prefix mappings initially so that we avoid accidental actions
" due to entering wrong suffix, e.g. \x in visual mode deleting the selection.
function! s:suppress(prefix, mode)
  let char = nr2char(getchar())
  if len(maparg(a:prefix . char, a:mode))
    return a:prefix . char
  else
    return ''
  endif
endfunction
for s:mapping in [
    \ ['<Tab>',    'n'],
    \ ['<Leader>', 'nv'],
    \ ['\',        'nv'],
    \ ['<C-s>',    'vi'],
    \ ['<C-z>',    'i'],
    \ ['<C-b>',    'i']
    \ ]
  let s:key = s:mapping[0]
  let s:modes = split(s:mapping[1], '\zs')  " construct list
  for s:mode in s:modes
    if ! len(mapcheck(s:key, s:mode))
      exe s:mode . 'map <expr> ' . s:key . ' <sid>suppress(''' . s:key . ''', ''' . s:mode . ''')'
    endif
  endfor
endfor

" Different cursor shape different modes
" First mouse stuff, make sure we are using vim, not vi
if v:version >= 500
  set mouse=a " mouse clicks and scroll wheel allowed in insert mode via escape sequences
endif
if has('ttymouse')
  set ttymouse=sgr
else
  set ttymouse=xterm2
endif
" Summary found here: http://vim.wikia.com/wiki/Change_cursor_shape_in_different_modes
" fail if you have an insert-mode remap of Esc; see: https://vi.stackexchange.com/q/15072/8084
" * Also according to this, don't need iTerm-specific Cursorshape stuff: https://stackoverflow.com/a/44473667/4970632
"   The TMUX stuff just wraps everything in \<Esc>Ptmux;\<Esc> CONTENT \<Esc>\\
" * Also see this for more compact TMUX stuff: https://vi.stackexchange.com/a/14203/8084
if exists('&t_SI')
  let &t_SI = (exists('$TMUX') ? "\ePtmux;\e\e[6 q\e\\" : "\e[6 q")
endif
if exists('&t_SR')
  let &t_SR = (exists('$TMUX') ? "\ePtmux;\e\e[4 q\e\\" : "\e[4 q")
endif
if exists('&t_EI')
  let &t_EI = (exists('$TMUX') ? "\ePtmux;\e\e[2 q\e\\" : "\e[2 q")
endif

" NORMAL and VISUAL MODE MAPS
" Disable keys
noremap <CR> <Nop>
noremap <Space> <Nop>
" Disable weird modes I don't understand
noremap Q <Nop>
noremap K <Nop>
" Disable Ctrl-z and Z for exiting vim
noremap Z <Nop>
noremap <C-z> <Nop>
" Disable extra scroll commands
noremap <C-p> <Nop>
noremap <C-n> <Nop>
" Disable default increment maps because use + and _ instead
noremap <C-a> <Nop>
noremap <C-x> <Nop>
inoremap <C-a> <Nop>
inoremap <C-x> <Nop>
" Turn off common things in normal mode
" Also prevent Ctrl+c ringing the bell
nnoremap <C-c> <Nop>
nnoremap <Delete> <Nop>
nnoremap <Backspace> <Nop>
" Easy mark usage -- use '"' or '[1-8]"' to set some mark, use '9"' to delete it,
" and use ' or [1-8]' to jump to a mark.
nnoremap <Leader>~ :<C-u>RemoveHighlights<CR>
nnoremap <expr> ` "`" . nr2char(97+v:count)
nnoremap <expr> ~ 'm' . nr2char(97+v:count) . ':HighlightMark ' . nr2char(97+v:count) . '<CR>'
" Reserve lower case q for quitting popup windows
nnoremap q <Nop>
" Record macro by pressing Q, the escapes prevent q from triggerering
nnoremap @ <Nop>
nnoremap , @a
nnoremap <silent> <expr> Q b:recording ?
  \ 'q<Esc>:let b:recording = 0<CR>' : 'qa<Esc>:let b:recording = 1<CR>'
" Redo map to capital U
nnoremap <C-r> <Nop>
nnoremap U <C-r>
" Use cc for s because use sneak plugin
nnoremap c<Backspace> <Nop>
nnoremap cc s
vnoremap cc s
" Swap with row above, and swap with row below
nnoremap <silent> ck k:let g:view = winsaveview() \| d
  \ \| call append(line('.'), @"[:-2]) \| call winrestview(g:view)<CR>
nnoremap <silent> cj :let g:view = winsaveview() \| d
  \ \| call append(line('.'), @"[:-2]) \| call winrestview(g:view)<CR>j
" Swap adjacent characters
nnoremap cl xph
nnoremap ch Xp
" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
nnoremap cL mzi<CR><Esc>`z
" Pressing enter on empty line preserves leading whitespace
nnoremap o ox<Backspace>
nnoremap O Ox<Backspace>
" Paste from the nth previously deleted or changed text
" Use 'yp' to paste last yanked, unchanged text, because cannot use zero
nnoremap yp "0p
nnoremap yP "0P
nnoremap <expr> p v:count == 0 ? 'p' : '<Esc>"'.v:count.'p'
nnoremap <expr> P v:count == 0 ? 'P' : '<Esc>"'.v:count.'P'
" Yank until end of line, like C and D
nnoremap Y y$
" Better join behavior -- before 2J joined this line and next, now it
" means 'join the two lines below'; more intuitive
nnoremap <expr> J v:count > 1  ? 'JJ' : 'J'
nnoremap <expr> K 'k' . v:count . (v:count > 1  ? 'JJ' : 'J')
" Toggle highlighting
nnoremap <silent> <Leader>o :noh<CR>
nnoremap <silent> <Leader>O :set hlsearch<CR>
" Move to current directory
" Pneumonic is 'inside' just like Ctrl + i map
nnoremap <silent> <Leader>i :lcd %:p:h<CR>:echom "Descended into file directory."<CR>
" Enable left mouse click in visual mode to extend selection, normally this is impossible
" Todo: Modify enter-visual mode maps! See: https://stackoverflow.com/a/15587011/4970632
" Want to be able to *temporarily turn scrolloff to infinity* when enter visual
" mode, to do that need to map vi and va stuff
nnoremap v myv
nnoremap V myV
nnoremap vc myvlh
nnoremap <C-v> my<C-v>
nnoremap <silent> v/ hn:noh<CR>mygn
vnoremap <silent> <LeftMouse> <LeftMouse>mx`y:exe "normal! ".visualmode()<CR>`x
vnoremap <CR> <C-c>
" Visual mode p/P to replace selected text with contents of register
vnoremap p d"1P
vnoremap P d"1P
" Alias single-key builtin text objects
for s:bracket in ['r[', 'a<', 'c{']
  exe 'onoremap i' . s:bracket[0] . ' i' . s:bracket[1]
  exe 'xnoremap i' . s:bracket[0] . ' i' . s:bracket[1]
  exe 'onoremap a' . s:bracket[0] . ' a' . s:bracket[1]
  exe 'xnoremap a' . s:bracket[0] . ' a' . s:bracket[1]
endfor
" Never save single-character deletions to any register
noremap x "_x
noremap X "_X
" Maps for throwaaway and clipboard register
noremap ' "_
noremap " "*
" Jump to last changed text, note F4 is mapped to Ctrl-m in iTerm
noremap <C-n> g;
noremap <F4> g,
" Jump to last jump
noremap <C-h> <C-o>
noremap <C-l> <C-i>
noremap <Left> <C-o>
noremap <Right> <C-i>
" Search for conflict blocks
noremap gc /^[<>=\|]\{2,}<CR>

" INSERT and COMMAND WINDOW MAPS
" Count number of tabs in popup menu so our position is always known
augroup popup_opts
  au!
  au BufEnter,InsertLeave * let b:menupos = 0
augroup END
function! s:tab_increase() " use this inside <expr> remaps
  let b:menupos += 1 | return ''
endfunction
function! s:tab_decrease()
  let b:menupos -= 1 | return ''
endfunction
function! s:tab_reset()
  let b:menupos = 0 | return ''
endfunction
" Enter means 'accept' only when we have explicitly scrolled down to something
" Tab always means 'accept' and choose default menu item if necessary
inoremap <expr> <CR>  pumvisible() ? b:menupos ? "\<C-y>" . <sid>tab_reset() : "\<C-e>\<C-]>\<CR>" : "\<C-]>\<CR>"
inoremap <expr> <Tab> pumvisible() ? b:menupos ? "\<C-y>" . <sid>tab_reset() : "\<C-n>\<C-y>" . <sid>tab_reset() : "\<C-]>\<Tab>"
" Certain keystrokes always close the popup menu
inoremap <expr> <Backspace> pumvisible() ? <sid>tab_reset() . "\<C-e>\<Backspace>" : "\<Backspace>"
inoremap <expr> <Space>     pumvisible() ? <sid>tab_reset() . "\<C-e>\<C-]>\<Space>" : "\<C-]>\<Space>"
" Commands that increment items in the menu
inoremap <expr> <C-k>  pumvisible() ? <sid>tab_decrease() . "\<C-p>" : "\<Up>"
inoremap <expr> <C-j>  pumvisible() ? <sid>tab_increase() . "\<C-n>" : "\<Down>"
inoremap <expr> <Up>   pumvisible() ? <sid>tab_decrease() . "\<C-p>" : "\<Up>"
inoremap <expr> <Down> pumvisible() ? <sid>tab_increase() . "\<C-n>" : "\<Down>"
" Disable scrolling in insert mode
inoremap <expr> <ScrollWheelUp>   pumvisible() ? <sid>tab_decrease() . "\<C-p>" : ""
inoremap <expr> <ScrollWheelDown> pumvisible() ? <sid>tab_increase() . "\<C-n>" : ""
" Special maps
inoremap <silent> <expr> <Delete> utils#forward_delete()
cnoremap <expr> <F1> utils#wild_tab(0)
cnoremap <expr> <F2> utils#wild_tab(1)

" VIM-PLUG PLUGINS
" Note: No longer worry about compatibility because we can install everything
" from conda-forge, including vim and ctags.
call plug#begin('~/.vim/plugged')

" Custom plugins, try to load locally if possible!
" See: https://github.com/junegunn/vim-plug/issues/32
" Note ^= prepends to list, += appends
for name in ['statusline', 'scrollwrapped', 'tabline', 'idetools', 'toggle', 'textools']
  let plug = expand('~/vim-' . name)
  if isdirectory(plug)
    if &rtp !~ plug
      exe 'set rtp^=' . plug
      exe 'set rtp+=' . plug . '/after'
    endif
  else
    Plug 'lukelbd/vim-' . name
  endif
endfor

" Hard requirements
" Plug 'tpope/vim-repeat' " now edit custom version in .vim/plugin/autoload
Plug '~/.fzf' " fzf installation location, will add helptags and runtimepath
Plug 'junegunn/fzf.vim' " this one depends on the main repo above, includes other tools
let g:fzf_layout = {'down': '~20%'} " make window smaller
let g:fzf_action = {'ctrl-i': 'silent!',
  \ 'ctrl-m': 'tab split', 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split', 'ctrl-v': 'vsplit'}

" Color schemes for MacVim
" Plug 'altercation/vim-colors-solarized'
Plug 'flazz/vim-colorschemes'
Plug 'fcpg/vim-fahrenheit'
Plug 'KabbAmine/yowish.vim'

" Colorize Hex strings
" Test: ~/.vim/plugged/colorizer/colortest.txt
" Works only in MacVim or when &t_Co == 256
Plug 'lilydjwg/colorizer'

" Proper syntax highlighting for a few different things
" Note impsort sorts import statements, and highlights modules with an after/syntax script
" Plug 'tweekmonster/impsort.vim' " this fucking thing has an awful regex, breaks if you use comments, fuck that shit
" Plug 'hdima/python-syntax' " this failed for me; had to manually add syntax file; f-strings not highlighted, and other stuff!
Plug 'psf/black'
Plug 'tell-k/vim-autopep8'
Plug 'tmux-plugins/vim-tmux'
Plug 'plasticboy/vim-markdown'
Plug 'vim-scripts/applescript.vim'
Plug 'anntzer/vim-cython'
Plug 'tpope/vim-liquid'

" TeX utilities; better syntax highlighting, better indentation,
" and some useful remaps. Also zotero integration.
" For vimtex config see: https://github.com/lervag/vimtex/issues/204
" Plug 'twsh/unite-bibtex' " python 3 version
" Plug 'msprev/unite-bibtex' " python 2 version
" Plug 'lervag/vimtex'
" Plug 'chrisbra/vim-tex-indent'
Plug 'Shougo/unite.vim'
Plug 'rafaqz/citation.vim'

" Julia support and syntax highlighting
Plug 'JuliaEditorSupport/julia-vim'

" Python wrappers
" Plug 'vim-scripts/Pydiction'  " just changes completeopt and dictionary and stuff
" Plug 'cjrh/vim-conda'  " for changing anconda VIRTUALENV; probably don't need it
" Plug 'klen/python-mode'  " incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython'  " dead
" Plug 'jupyter-vim/jupyter-vim'  " hard to use jupyter console with proplot
Plug 'davidhalter/jedi-vim'  " disable autocomplete stuff in favor of deocomplete

" Folding and matching
" Plug 'tmhedberg/SimpylFold'
" Plug 'Konfekt/FastFold'
Plug 'andymass/vim-matchup'
let g:loaded_matchparen = 1
let g:matchup_matchparen_enabled = 1
let g:matchup_transmute_enabled = 0 " breaks latex!

" Files and directories
" Plug 'jistr/vim-nerdtree-tabs' "unnecessary
" Plug 'vim-scripts/EnhancedJumps'
Plug 'scrooloose/nerdtree'
Plug 'majutsushi/tagbar'

" Tabdrop fix for vim
" Plug 'ohjames/tabdrop'

" Close unused buffers
" https://github.com/Asheq/close-buffers.vim
Plug 'Asheq/close-buffers.vim'

" Commenting and syntax checking
" Syntastic looks for checkers in $PATH, must be installed manually
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'

" Sessions and swap files and reloading. Mapped in my .bashrc
" to vim -S .vimsession and exiting vim saves the session there
" Plug 'thaerkh/vim-workspace'
" Plug 'gioele/vim-autoswap'  " deals with swap files automatically; no longer use them so unnecessary
" Plug 'xolox/vim-reload'  " better to write my own simple plugin
Plug 'tpope/vim-obsession'

" Git wrappers and differencing tools
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Shell utilities, including Chmod and stuff
Plug 'tpope/vim-eunuch'

" Completion engines
" Note: Disable for macvim because not sure how to control its python distro
" Plug 'ajh17/VimCompletesMe'  " no auto-popup feature
" Plug 'lifepillar/vim-mucomplete'  " broken, seriously, cannot get it to work, don't bother! is slow anyway.
" Plug 'Valloric/YouCompleteMe'  " broken
" Plug 'ervandew/supertab'
" Plug 'shougo/neocomplete.vim'  " needs lua!
" let g:neocomplete#enable_at_startup = 1
" Plug 'prabirshrestha/asyncomplete.vim'
if ! has('gui_running')
  " Main plugin
  Plug 'Shougo/deoplete.nvim'  " requires pip install pynvim
  Plug 'roxma/nvim-yarp'  " required for deoplete
  Plug 'roxma/vim-hug-neovim-rpc'  " required for deoplete
  let g:deoplete#enable_at_startup = 1  " must be inside plug#begin block
  " Omnifunc sources, these are not provided by engines
  " See: https://github.com/Shougo/deoplete.nvim/wiki/Completion-Sources
  Plug 'deoplete-plugins/deoplete-jedi'
  Plug 'Shougo/neco-syntax'
  Plug 'Shougo/neco-vim'
  Plug 'Shougo/echodoc.vim'
endif


" Delimiters
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'

" Custom text objects (inner/outer selections)
" Plug 'bps/vim-textobj-python' " not really ever used, just use indent objects
" Plug 'sgur/vim-textobj-parameter' " this conflicts with latex
" Plug 'vim-scripts/argtextobj.vim' " issues with this too
" Plug 'machakann/vim-textobj-functioncall' " does not work
Plug 'kana/vim-textobj-user'  " base
Plug 'kana/vim-textobj-indent'  " match indentation, object is 'i'
Plug 'kana/vim-textobj-entire'  " entire file, object is 'e'

" Aligning things and stuff, use Tabular because more powerful
" even though the API is fugly AF and the docs suck
" Plug 'tommcdo/vim-lion'
" Plug 'junegunn/vim-easy-align'
Plug 'godlygeek/tabular'

" Better motions
" Sneak plugin; see the link for helpful discussion:
" https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
Plug 'justinmk/vim-sneak'

" Calculators and number stuff
" Plug 'vim-scripts/Toggle' "toggling stuff on/off; modified this myself
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
" Plug 'triglav/vim-visual-increment'  " superceded by vim-speeddating
Plug 'metakirby5/codi.vim'
Plug 'tpope/vim-speeddating'  " dates and stuff

" This RST shit all failed
" Just to simple == tables instead of fancy ++ tables
" Plug 'nvie/vim-rst-tables'
" Plug 'ossobv/vim-rst-tables-py3'
" Plug 'philpep/vim-rst-tables'
" noremap <silent> \s :python ReformatTable()<CR>
" let g:riv_python_rst_hl = 1
" Plug 'Rykka/riv.vim'

" Single line/multiline transition; make sure comes after surround
" Hardly ever need this
" Plug 'AndrewRadev/splitjoin.vim'
" let g:splitjoin_split_mapping = 'cS' | let g:splitjoin_join_mapping  = 'cJ'

" Multiple cursors is awesome
" Article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" Plug 'terryma/vim-multiple-cursors'

" Indent line
" NOTE: This completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes (which
" we need to stay transparent). So forget it probably
" Plug 'yggdroot/indentline'

" Miscellaneous
" Plug 'jez/vim-superman'  " man page
" Plug 'beloglazov/vim-online-thesaurus'  " broken
" Plug 'dkarter/bullets.vim'  " list numbering, fails too

" Easy tags, for easy integration
" Plug 'xolox/vim-misc' "depdency for easytags
" Plug 'xolox/vim-easytags' "kinda old and not that useful honestly
" Plug 'ludovicchabant/vim-gutentags' "slows shit down like crazy

" End of plugins
" The plug#end also declares filetype plugin, syntax, and indent on
" Note apparently every BufRead autocmd inside an ftdetect/filename.vim file
" is automatically made part of the 'filetypedetect' augroup; that's why it exists!
call plug#end()

" Mappings for vim-idetools command
if PlugActive('vim-idetools') || &rtp =~# 'vim-idetools'
  augroup double_bracket
    au!
    au BufEnter * nmap <buffer> [[ [T
    au BufEnter * nmap <buffer> ]] ]T
  augroup END
  nnoremap <silent> <Leader>C :DisplayTags<CR>:redraw!<CR>
endif
if PlugActive('black')
  let g:black_linelength = 79
  let g:black_skip_string_normalization = 1
endif

" Mappings for scrollwrapped accounting for Karabiner <C-j> --> <Down>, etc.
if PlugActive('vim-scrollwrapped') || &rtp =~# 'vim-scrollwrapped'
  nnoremap <silent> <Leader>w :WrapToggle<CR>
  nnoremap <silent> <Down> :call scrollwrapped#scroll(winheight(0)/4, 'd', 1)<CR>
  nnoremap <silent> <Up>   :call scrollwrapped#scroll(winheight(0)/4, 'u', 1)<CR>
  vnoremap <silent> <expr> <Down> (winheight(0)/4) . '<C-e>' . (winheight(0)/4) . 'gj'
  vnoremap <silent> <expr> <Up>   (winheight(0)/4) . '<C-y>' . (winheight(0)/4) . 'gk'
endif

" Add global delims with vim-textools plugin functions and declare my weird
" mapping defaults due to Karabiner
if PlugActive('vim-textools') || &rtp =~# 'vim-textools'
  " Delimiter mappings
  " Note: Why is bibtextoggle_map a variable? Because otherwise we have to put
  " this in ftplugin/tex.vim or define an autocommand
  augroup textools_settings
    au!
    au FileType tex nnoremap <silent> <buffer> <Leader>b :BibtexToggle<CR>
  augroup END
  let g:textools_prevdelim_map = '<F1>'
  let g:textools_nextdelim_map = '<F2>'
  let g:textools_latexmk_maps = {
    \ '<C-z>': '',
    \ '<Leader>z': '--diff',
    \ '<Leader>Z': '--word',
    \ }
  " Command mappings
  " Surround mappings
  " The bracket maps are also defined in textools but make them global and
  " do not include the delete_delims and change_delims functionality
  function! s:add_delim(map, start, end)  " if final argument passed, this is global
    let g:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  endfunction
  nmap dsc dsB
  nmap csc csB
  vmap <C-s> <Plug>VSurround
  imap <C-s> <Plug>Isurround
  call s:add_delim("'", "'", "'")
  call s:add_delim('"', '"', '"')
  call s:add_delim('q', '‘', '’')
  call s:add_delim('Q', '“', '”')
  call s:add_delim('b', '(', ')')
  call s:add_delim('c', '{', '}')
  call s:add_delim('B', '{', '}')
  call s:add_delim('r', '[', ']')
  call s:add_delim('a', '<', '>')
  call s:add_delim('\', '\"', '\"')
  call s:add_delim('p', 'print(', ')')
  call s:add_delim('f', "\1function: \1(", ')')  " initial part is for prompt, needs double quotes
  nnoremap <silent> ds\ :call textools#delete_delims('\\["'."']", '\\["'."']")<CR>
  nnoremap <silent> cs\ :call textools#change_delims('\\["'."']", '\\["'."']")<CR>
  nnoremap <silent> dsf :call textools#delete_delims('\<\K\k*(', ')')<CR>
  nnoremap <silent> csf :call textools#change_delims('\<\K\k*(', ')', input('function: ') . "(\r)")<CR>
  nnoremap <silent> dsm :call textools#delete_delims('\_[^A-Za-z_.]\zs\h[0-9A-Za-z_.]*(', ')')<CR>
  nnoremap <silent> csm :call textools#change_delims('\_[^A-Za-z_.]\zs\h[0-9A-Za-z_.]*(', ')', input('method: ') . "(\r)")<CR>
  nnoremap <silent> dsA :call textools#delete_delims('\<\K\k*\[', '\]')<CR>
  nnoremap <silent> csA :call textools#change_delims('\<\K\k*\[', '\]', input('array: ') . "[\r]")<CR>
  nnoremap <silent> dsq :call textools#delete_delims("‘", "’")<CR>
  nnoremap <silent> csq :call textools#change_delims("‘", "’")<CR>
  nnoremap <silent> dsQ :call textools#delete_delims("“", "”")<CR>
  nnoremap <silent> csQ :call textools#change_delims("“", "”")<CR>
endif

" *Very* expensive for large files so only ever activate manually
" Mapping is # for hex string
if PlugActive('colorizer')
  let g:colorizer_startup = 0
  nnoremap <Leader># :<C-u>ColorToggle<CR>
endif

" Vim sneak
if PlugActive('vim-sneak')
  map s <Plug>Sneak_s
  map S <Plug>Sneak_S
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  map <F1> <Plug>Sneak_,
  map <F2> <Plug>Sneak_;
endif

" Vim surround
" Add shortcuts for surrounding text objects with delims
" NOTE: More global delims are found in textools plugin because I define
" some complex helper funcs there
if PlugActive('vim-surround')
  " Define text object shortcuts
  nmap ysw ysiw
  nmap ysW ysiW
  nmap ysp ysip
  nmap ys. ysis
  nmap ySw ySiw
  nmap ySW ySiW
  nmap ySp ySip
  nmap yS. ySis
endif

" Auto-generate delimiters
if PlugActive('delimitmate')
  " First filetype settings
  " Enable carat matching for filetypes where need tags (or keycode symbols)
  " Vim needs to disable matching ", or everything is super slow
  augroup delims
    au!
    au FileType vim
      \ let b:delimitMate_quotes = "'" |
      \ let b:delimitMate_matchpairs = "(:),{:},[:],<:>"
    au FileType tex
      \ let b:delimitMate_quotes = "$ |" |
      \ let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
    au FileType html let b:delimitMate_matchpairs = "(:),{:},[:],<:>"
    au FileType markdown,rst let b:delimitMate_quotes = "\" ' $ `"
  augroup END
  " Global defaults
  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 2  " expand even if it is not empty!
  let g:delimitMate_jump_expansion = 0
  let g:delimitMate_quotes = '" '''
  let g:delimitMate_matchpairs = '(:),{:},[:]'
  let g:delimitMate_excluded_regions = 'String'  " by default is disabled inside, don't want that
endif

" Text objects
" Many of these just copied, some ideas for future:
" https://github.com/kana/vim-textobj-lastpat/tree/master/plugin/textobj
" Note: Method definition needs that fancy regex instead of just \< because
" textobj looks for *narrowest* possible match so only catches tail of
" method call. Note that \@! fails but \zs works for some reason.
if PlugActive('vim-textobj-user')
  let s:universal_textobjs_dict = {
    \   'line': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'textobj#current_line_a',
    \     'select-a': 'al',
    \     'select-i-function': 'textobj#current_line_i',
    \     'select-i': 'il',
    \   },
    \   'blanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'textobj#blank_lines',
    \     'select-a': 'a<Space>',
    \     'select-i-function': 'textobj#blank_lines',
    \     'select-i': 'i<Space>',
    \   },
    \   'nonblanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'textobj#nonblank_lines',
    \     'select-a': 'aP',
    \     'select-i-function': 'textobj#nonblank_lines',
    \     'select-i': 'iP',
    \   },
    \   'uncommented': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 'textobj#uncommented_lines',
    \     'select-i-function': 'textobj#uncommented_lines',
    \     'select-a': 'aC',
    \     'select-i': 'iC',
    \   },
    \   'function': {
    \     'pattern': ['\<\K\k*(', ')'],
    \     'select-a': 'af',
    \     'select-i': 'if',
    \   },
    \   'method': {
    \     'pattern': ['\_[^A-Za-z_.]\zs\h[0-9A-Za-z_.]*(', ')'],
    \     'select-a': 'am',
    \     'select-i': 'im',
    \   },
    \   'array': {
    \     'pattern': ['\<\K\k*\[', '\]'],
    \     'select-a': 'aA',
    \     'select-i': 'iA',
    \   },
    \  'curly': {
    \     'pattern': ['‘', '’'],
    \     'select-a': 'aq',
    \     'select-i': 'iq',
    \   },
    \  'curly-double': {
    \     'pattern': ['“', '”'],
    \     'select-a': 'aQ',
    \     'select-i': 'iQ',
    \   },
    \ }

  " Enable and define related maps
  " Make sure to match [<letter> with the corresponding textobject va<letter>
  " Note: For some reason it is critical the '^' is outside the \(\) group
  " Next comment block
  call textobj#user#plugin('universal', s:universal_textobjs_dict)
  noremap <expr> [c textobj#search_block(
    \ '^\(' . textobj#regex_comment() . '\)\@!.*\n' . textobj#regex_comment(), 0)
  noremap <expr> ]c textobj#search_block(
    \ '^\(' . textobj#regex_comment() . '\)\@!.*\n' . textobj#regex_comment(), 1)
  " Next block at *parent indent level*
  noremap <expr> [i textobj#search_block(
    \ '^\(' . textobj#regex_current_indent() . '\)\@!.*\n^\zs\ze' . textobj#regex_current_indent(), 0)
  noremap <expr> ]i textobj#search_block(
    \ '^\(' . textobj#regex_current_indent() . '\)\@!.*\n^\zs\ze' . textobj#regex_current_indent(), 1)
  " Next block at *lower* indent level
  noremap <expr> [I textobj#search_block(
    \ '^\zs\ze' . textobj#regex_parent_indent(), 0)
  noremap <expr> ]I textobj#search_block(
    \ '^\zs\ze' . textobj#regex_parent_indent(), 1)
  nnoremap <CR> <C-]>
endif

" Fugitive command aliases
" Used to alias G commands to lower case but upper case is more consistent
" with Tim Pope eunuch commands
if PlugActive('vim-fugitive')
  cnoreabbrev Gdiff Gdiffsplit!
  cnoreabbrev Ghdiff Ghdiffsplit!
  cnoreabbrev Gvdiff Gvdiffsplit!
endif

" Git gutter
" TODO: Note we had to overwrite the gitgutter autocmds with a file in 'after'.
if PlugActive('vim-gitgutter')
  " Create command for toggling on/off; old VIM versions always show signcolumn
  " if signs present, so GitGutterDisable will remove signcolumn.
  let g:gitgutter_map_keys = 0  " disable all maps yo
  let g:gitgutter_max_signs = 5000
  if !exists('g:gitgutter_enabled')
    let g:gitgutter_enabled = 0  " whether enabled at *startup*
    silent! set signcolumn=no
  endif
  " Maps for toggling gitgutter on and off
  nnoremap <silent> <Leader>g :call utils#gitgutter_toggle(1)<CR>
  nnoremap <silent> <Leader>G :call utils#gitgutter_toggle(0)<CR>
  " Maps for showing/disabling changes under cursor
  noremap <silent> <Leader>q :GitGutterPreviewHunk<CR>:wincmd j<CR>
  noremap <silent> <Leader>A :GitGutterUndoHunk<CR>
  noremap <silent> <Leader>a :GitGutterStageHunk<CR>
  " Navigating between hunks
  noremap <silent> ]g :GitGutterNextHunk<CR>
  noremap <silent> [g :GitGutterPrevHunk<CR>
endif

" Codi (mathematical notepad)
if PlugActive('codi.vim')
  " See issue: https://github.com/metakirby5/codi.vim/issues/90
  " We want TextChanged and InsertLeave, not TextChangedI which is enabled
  " when setting g:codi#autocmd to 'TextChanged'
  augroup math
    au!
    au User CodiEnterPre call utils#codi_setup(1)
    au User CodiLeavePost call utils#codi_setup(0)
  augroup END
  command! -nargs=? CodiNew call utils#codi_new(<q-args>)
  nnoremap <silent> <Leader>u :CodiNew<CR>
  nnoremap <silent> <Leader>U :Codi!!<CR>
  " See issue: https://github.com/metakirby5/codi.vim/issues/85
  " Interpreter without history, various settings
  let g:codi#autocmd = 'None'
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20
  let g:codi#log = '' " enable when debugging
  let g:codi#interpreters = {
    \ 'python': {
        \ 'bin': 'python',
        \ 'prompt': '^\(>>>\|\.\.\.\) ',
        \ 'quitcmd': 'import readline; readline.clear_history(); exit()',
        \ },
    \ }
endif

" Speed dating, support date increments
if PlugActive('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
endif

" The howmuch.vim plugin, currently with minor modifications in .vim folder
if hasmapto('<Plug>AutoCalcAppendWithEqAndSum', 'v')
  vmap c+ <Plug>AutoCalcAppendWithEqAndSum
endif
if hasmapto('<Plug>AutoCalcReplaceWithSum', 'v')
  vmap c= <Plug>AutoCalcReplaceWithSum
endif

" Neocomplete and deoplete
if PlugActive('deoplete.nvim')
  call deoplete#custom#option({
  \ 'max_list': 15,
  \ })
endif
if PlugActive('neocomplete.vim')
  let g:neocomplete#max_list = 15
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#enable_auto_select = 0
endif

" Jedi vim
if PlugActive('jedi-vim')
  augroup jedi_fix
    au!
    au FileType python nnoremap <buffer> <silent> <Leader>s :Refresh<CR>
  augroup END
  let g:jedi#completions_enabled = 0
  let g:jedi#auto_vim_configuration = 0
  let g:jedi#completions_command = ''
  let g:jedi#goto_command = '<CR>'
  let g:jedi#documentation_command = '<Leader>p'
  let g:jedi#max_doc_height = 100
  let g:jedi#goto_assignments_command = ''
  let g:jedi#goto_definitions_command = ''
  let g:jedi#rename_command = ''
  let g:jedi#usages_command = '<Leader><CR>'
  let g:jedi#show_call_signatures = '1'
endif

" NERDCommenter
if PlugActive('nerdcommenter')
  " Custom delimiter overwrites, default python includes space for some reason
  " TODO: Why can't this just use &commentstring?
  let g:NERDCustomDelimiters = {
    \ 'julia':  {'left': '#', 'leftAlt': '#=', 'rightAlt': '=#'},
    \ 'python': {'left': '#'},
    \ 'cython': {'left': '#'},
    \ 'pyrex':  {'left': '#'},
    \ 'ncl':    {'left': ';'},
    \ 'smarty': {'left': '<!--', 'right': '-->'},
    \ }
  " Settings
  let g:NERDSpaceDelims = 1             " comments have leading space
  let g:NERDCreateDefaultMappings = 0   " disable default mappings (make my own)
  let g:NERDCompactSexyComs = 1         " compact syntax for prettified multi-line comments
  let g:NERDTrimTrailingWhitespace = 1  " trailing whitespace deletion
  let g:NERDCommentEmptyLines = 1       " allow commenting and inverting empty lines (useful when commenting a region)
  let g:NERDDefaultAlign = 'left'       " align line-wise comment delimiters flush left instead of following code indentation
  let g:NERDCommentWholeLinesInVMode = 2
  " Mappings
  " Use NERDCommenterMinimal commenter to use left-right delimiters, or alternatively use
  " NERDCommenterSexy commenter for better alignment
  inoremap <expr> <C-c> nerdcommenter#comment_insert()
  map c. <Plug>NERDCommenterToggle
  map co <Plug>NERDCommenterSexy
  map cO <Plug>NERDCommenterUncomment
  " Section headers and dividers
  nnoremap <silent> <Plug>bar1 :call nerdcommenter#comment_bar('-', 77, 1)<CR>:call repeat#set("\<Plug>bar1")<CR>
  nnoremap <silent> <Plug>bar2 :call nerdcommenter#comment_bar('-', 71, 0)<CR>:call repeat#set("\<Plug>bar2")<CR>
  nnoremap <silent> c: :call nerdcommenter#comment_bar_surround('-', 77, 1)<CR>A
  nmap c; <Plug>bar1
  nmap c, <Plug>bar2
  " Author information, date insert, misc inserts
  nnoremap <silent> cA :call nerdcommenter#comment_message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
  nnoremap <silent> cY :call nerdcommenter#comment_message('Date: '.strftime('%Y-%m-%d'))<CR>
  nnoremap <silent> cC :call nerdcommenter#comment_double()<CR>i
  nnoremap <silent> cI :call nerdcommenter#comment_inline(5)<CR>i
  " Add ReST section levels
  nnoremap <silent> c- :call nerdcommenter#comment_header('-')<CR>
  nnoremap <silent> c_ :call nerdcommenter#comment_header_surround('-')<CR>
  nnoremap <silent> c= :call nerdcommenter#comment_header('=')<CR>
  nnoremap <silent> c+ :call nerdcommenter#comment_header_surround('=')<CR>
  " Python docstring
  nnoremap c' :call nerdcommenter#insert_docstring("'")<CR>A
  nnoremap c" :call nerdcommenter#insert_docstring('"')<CR>A
endif

" NERDTree
" Most important commands: 'o' to view contents, 'u' to move up directory,
" 't' open in new tab, 'T' open in new tab but retain focus, 'i' open file in
" split window below, 's' open file in new split window VERTICAL, 'O' recursive open,
" 'x' close current nodes parent, 'X' recursive cose, 'p' jump
" to current nodes parent, 'P' jump to root node, 'K' jump to first file in
" current tree, 'J' jump to last file in current tree, <C-j> <C-k> scroll direct children
" of current directory, 'C' change tree root to selected dir, 'u' move up, 'U' move up
" and leave old root node open, 'r' recursive refresh, 'm' show menu, 'cd' change CWD,
" 'I' toggle hidden file display, '?' toggle help
if PlugActive('nerdtree')
  augroup nerdtree
    au!
    au BufEnter *
      \ if (winnr('$') == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) |
      \ q |
      \ endif
  augroup END
  let g:NERDTreeWinPos = 'right'
  let g:NERDTreeWinSize = 20  " instead of 31 default
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeMinimalUI = 1  " remove annoying ? for help note
  let g:NERDTreeMapChangeRoot = 'D'  " C was annoying, because VIM will wait for CD
  let g:NERDTreeSortOrder = []  " use default sorting
  let g:NERDTreeIgnore = split(&wildignore, ',')
  for s:index in range(len(g:NERDTreeIgnore))
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '*.', '\\.', '')
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '$', '\$', '')
  endfor
  nnoremap <Leader>n :NERDTree %<CR>
endif

" Syntastic
if PlugActive('syntastic')
  " Maps and commands for circular location-list scrolling
  command! -bar -count=1 Cnext execute syntastic#cyclic_next(<count>, 'qf')
  command! -bar -count=1 Cprev execute syntastic#cyclic_next(<count>, 'qf', 1)
  command! -bar -count=1 Lnext execute syntastic#cyclic_next(<count>, 'loc')
  command! -bar -count=1 Lprev execute syntastic#cyclic_next(<count>, 'loc', 1)
  command! SyntasticCheckers call syntastic#syntastic_checkers(1)
  nnoremap <silent> <Leader>x :update \| call syntastic#syntastic_enable()<CR>
  nnoremap <silent> <Leader>X :let b:syntastic_on = 0 \| SyntasticReset<CR>
  nnoremap <silent> [x :Lprev<CR>
  nnoremap <silent> ]x :Lnext<CR>
  nnoremap <silent> [q :Cprev<CR>
  nnoremap <silent> ]q :Cnext<CR>

  " No active syntax checking; only on manual trigger
  let g:syntastic_mode_map = {
      \ 'mode': 'passive',
      \ 'active_filetypes': [],
      \ 'passive_filetypes': []
      \ }

  " Choose syntax checkers, disable auto checking
  " flake8 pep8 pycodestyle pyflakes pylint python
  " pylint adds style checks, flake8 is pep8 plus pyflakes, pyflakes is pure syntax
  " NOTE: Need 'python' checker in addition to these other ones, because python
  " tests for import-time errors and others test for runtime errors!
  let g:syntastic_stl_format = ''  " disables statusline colors; they were ugly
  let g:syntastic_always_populate_loc_list = 1  " necessary, or get errors
  let g:syntastic_auto_loc_list = 1  " creates window; if 0, does not create window
  let g:syntastic_loc_list_height = 5
  let g:syntastic_mode = 'passive'  " opens little panel
  let g:syntastic_check_on_open = 0
  let g:syntastic_check_on_wq = 0
  let g:syntastic_enable_signs = 1  " disable useless signs
  let g:syntastic_enable_highlighting = 1
  let g:syntastic_auto_jump = 0  " disable jumping to errors
  let g:syntastic_sh_checkers = ['shellcheck']  " https://github.com/koalaman/shellcheck
  let g:syntastic_tex_checkers = ['lacheck']
  let g:syntastic_python_checkers = ['python', 'flake8']
  let g:syntastic_fortran_checkers = ['gfortran']
  let g:syntastic_vim_checkers = ['vint']  " https://github.com/Kuniwak/vint
  let g:syntastic_json_checkers = ['jsonlint']  " https://github.com/Kuniwak/vint

  " Flake8 ignore list:
  " * Allow imports after statements (E402)
  " * Allow multiple spaces before operators for alignment (E211)
  let g:syntastic_python_flake8_post_args='--ignore=W503,E402,E221,E731'

  " Syntastic ignore list:
  " * Allow sourcing from files (SC1090)
  " * Permit 'useless cat' because left-to-right command chain more intuitive (SC2002)
  " * Allow building arrays from unquoted result of command (SC2206, SC2207)
  " * Allow quoting RHS of =~ e.g. for array comparison (SC2076)
  " * Allow unquoted variables and array expansions, because we almost never deal with spaces (SC2068, SC2086)
  " * Allow 'which' instead of 'command -v' (SC2230)
  " * Allow unquoted variables in for loop (SC2231)
  " * Allow dollar signs in single quotes, e.g. ncap2 commands (SC2016)
  " * Allow looping through single strings
  let g:syntastic_sh_shellcheck_args='-e SC1090,SC2002,SC2068,SC2086,SC2206,SC2207,SC2230,SC2231,SC2016,SC2041'

  " Custom syntax colors
  hi SyntasticErrorLine ctermfg=White ctermbg=Red cterm=None
  hi SyntasticWarningLine ctermfg=White ctermbg=Magenta cterm=None
endif

" Tabular
" NOTE: Common approach below is to match the space 'following' the actual
" delimiter. Useful where we do not want to put delimiter on separate column.
if PlugActive('tabular')
  " Custom command, ignores lines in the selection that do not match delimiter
  " This is not necessary for invocations without a range
  command! -range -nargs=1 Table <line1>,<line2>call tabularize#smart_table(<q-args>)

  " Align arbitrary character, and suppress error message if user Ctrl-c's out of input line
  nnoremap <silent> <expr> \<Space> ':silent! Tabularize /' . input('Alignment regex: ') . '/l1c1<CR>'
  vnoremap <silent> <expr> \<Space> "<Esc>:silent! '<,'>Table /" . input('Alignment regex: ') . '/l1c1<CR>'

  " Commas, suitable for diag_table
  nnoremap <expr> \, ':Tabularize /,\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \, ':Table      /,\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'

  " Dictionary, colon on left or right
  nnoremap <expr> \d ':Tabularize /:\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \d ':Table      /:\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  nnoremap <expr> \D ':Tabularize /\(' . RegexComment() . '.*\)\@<!\zs:/l1c1<CR>'
  vnoremap <expr> \D ':Table      /\(' . RegexComment() . '.*\)\@<!\zs:/l1c1<CR>'

  " Left or right-align first field by spaces
  nnoremap <expr> \l ':Tabularize /^\s*\S\{-1,}\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'
  vnoremap <expr> \l ':Table      /^\s*\S\{-1,}\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'
  nnoremap <expr> \r ':Tabularize /^\s*[^\t ' . RegexComment() . ']\+\zs\ /r0l0l0<CR>'
  vnoremap <expr> \r ':Table      /^\s*[^\t ' . RegexComment() . ']\+\zs\ /r0l0l0<CR>'

  " Just align by spaces
  " Note the :help Tabularize suggestion is *way* more complicated
  nnoremap <expr> \\ ':Tabularize /\S\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'
  vnoremap <expr> \\ ':Table      /\S\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'

  " Tables separted by | chars
  nnoremap <expr> \\| ':Tabularize /\|/l1l1<CR>'
  vnoremap <expr> \\| ':Table      /\|/l1l1<CR>'

  " By comment character, ignoring comment-only lines
  nnoremap <expr> \C ':Tabularize /^\s*[^ \t' . RegexComment() . '].*\zs' . RegexComment() . '/l2l1<CR>'
  vnoremap <expr> \C ':Table      /^\s*[^ \t' . RegexComment() . '].*\zs' . RegexComment() . '/l2l1<CR>'

  " Chained && statements, common in bash
  nnoremap <expr> \& ':Tabularize /&&/l1l1<CR>'
  vnoremap <expr> \& ':Table      /&&/l1l1<CR>'

  " Case/esac blocks. The regex in square brackets ignores the parameter
  " expansions ${param#*pattern} and ${param##*pattern} e.g. var=${1#*=}.
  " Diagrams for \( maps and \) maps are as follows:
  " <item-right-paren> <zero-width-delim> <content-semicolons> <zero-width-delim> <inline-comment>
  " <item-right-paren> <zero-width-delim> <content>            <semicolons>       <inline-comment>
  " asdfda*|asd*) asdfjioajoidfjaosi"* ;; " comment 1S asdfjio *asdfjio*
  " a|asdfsa)     asdjiofjoi""* ;;        " coiasdfojiadfj asd asd asdf
  nnoremap <expr> \( ':Tabularize /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|\zs;;\)/l1l0l1l1<CR>'
  vnoremap <expr> \( ':Table      /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|\zs;;\)/l1l0l1l1<CR>'
  nnoremap <expr> \) ':Tabularize /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|;;\zs\)/l1l0l1l0<CR>'
  vnoremap <expr> \) ':Table      /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|;;\zs\)/l1l0l1l0<CR>'

  " Align by the first equals sign either keeping it to the left or not
  " The eaiser to type one (-=) puts equals signs in one column
  " This selects the *first* uncommented equals sign that does not belong to
  " a logical operator or incrementer <=, >=, ==, %=, -=, +=, /=, *= (have to escape dash in square brackets)
  nnoremap <expr> \= ':Tabularize /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!\zs==\@!/l1l1<CR>'
  vnoremap <expr> \= ':Table      /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!\zs==\@!/l1l1<CR>'
  nnoremap <expr> \+ ':Tabularize /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0l1<CR>'
  vnoremap <expr> \+ ':Table      /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0l1<CR>'
endif

" Tagbar settings
" * p jumps to tag under cursor, in code window, but remain in tagbar
" * C-n and C-p browses by top-level tags
" * o toggles the fold under cursor, or current one
if PlugActive('tagbar')
  " Customization, for more info see :help tagbar-extend
  " To list kinds, see :!ctags --list-kinds=<filetype>
  " The first number is whether to fold, second is whether to highlight location
  " \ 'r:refs:1:0', "not useful
  " \ 'p:pagerefs:1:0' "not useful
  let g:tagbar_type_tex = {
      \ 'ctagstype' : 'latex',
      \ 'kinds'     : [
          \ 's:sections',
          \ 'g:graphics:0:1',
          \ 'l:labels:0:1',
      \ ],
      \ 'sort' : 0
  \ }
  let g:tagbar_type_vim = {
      \ 'ctagstype' : 'vim',
      \ 'kinds'     : [
          \ 'a:augroups:0',
          \ 'f:functions:1',
          \ 'c:commands:1:0',
          \ 'v:variables:1:0',
          \ 'm:maps:1:0',
      \ ],
      \ 'sort' : 0
  \ }
  " Settings
  let g:tagbar_silent = 1 " no information echoed
  let g:tagbar_previewwin_pos = 'bottomleft' " result of pressing 'P'
  let g:tagbar_left = 0 " open on left; more natural this way
  let g:tagbar_indent = -1 " only one space indent
  let g:tagbar_show_linenumbers = 0 " not needed
  let g:tagbar_autofocus = 0 " don't autojump to window if opened
  let g:tagbar_sort = 1 " sort alphabetically? actually much easier to navigate, so yes
  let g:tagbar_case_insensitive = 1 " make sorting case insensitive
  let g:tagbar_compact = 1 " no header information in panel
  let g:tagbar_width = 15 " better default
  let g:tagbar_zoomwidth = 15 " don't ever 'zoom' even if text doesn't fit
  let g:tagbar_expand = 0
  let g:tagbar_autoshowtag = 2 " never ever open tagbar folds automatically, even when opening for first time
  let g:tagbar_foldlevel = 1 " setting to zero will override the 'kinds' fields in below dicts
  let g:tagbar_map_openfold = '='
  let g:tagbar_map_closefold = '-'
  let g:tagbar_map_closeallfolds = '_'
  let g:tagbar_map_openallfolds = '+'
  nnoremap <silent> <Leader>t :call utils#tagbar_setup()<CR>
endif

" Session saving
" Obsession .vimsession triggers update on BufEnter and VimLeavePre
if PlugActive('vim-obsession') "must manually preserve cursor position
  augroup session
    au!
    au BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$") |
      \ exe "normal! g`\"" |
      \ endif
    au VimEnter * Obsession .vimsession
  augroup END
  nnoremap <silent> <Leader>V :Obsession .vimsession<CR>:echom 'Manually refreshed .vimsession.'<CR>
endif
" Custom autosave plugin
command! Refresh call utils#refresh()
command! -nargs=? Autosave call utils#autosave_toggle(<args>)
nnoremap <Leader>S :Autosave<CR>
" Related utils
nnoremap <silent> <Leader>s :Refresh<CR>
nnoremap <silent> <Leader>r :e<CR>
nnoremap <silent> <Leader>R :syntax sync fromstart \| redraw!<CR>

" BUFFER QUITTING/SAVING
" Save and quit, also test whether the :q action closed the entire tab
" SmartWrite is from tabline plugin
nnoremap <silent> <C-s> :SmartWrite<CR>
nnoremap <silent> <C-a> :call utils#vim_close()<CR>
nnoremap <silent> <C-w> :call utils#window_close()<CR>
nnoremap <silent> <C-q> :call utils#tab_close()<CR>
" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" Warning: Do not map escape or cannot send iTerm-shortcuts with escape codes!
" Note: Must change local directory to have term pop up in this dir:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>T :silent! lcd %:p:h<CR>:terminal<CR>

" OPENING FILES
" TABS, WINDOWS, AND FILES
augroup tabs
  au!
  au TabLeave * let g:lasttab = tabpagenr()
augroup END
command! -nargs=? -complete=file Open call fzf#open_continuous(<q-args>)
" Opening file in current directory and some input directory
nnoremap <C-o> :Open 
nnoremap <C-y> :Open .<CR>
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <F3> :exe 'Open '.expand('%:h')<CR>
" Tab selection and movement
noremap gt <Nop>
noremap gT <Nop>
nnoremap <Tab>, gT
nnoremap <Tab>. gt
nnoremap <silent> <Tab>' :exe "tabn ".(exists('g:lasttab') ? g:lasttab : 1)<CR>
nnoremap <silent> <Tab><Tab> :call fzf#run({'source': utils#tab_select(), 'options': '--no-sort', 'sink':function('utils#tab_jump'), 'down':'~50%'})<CR>
nnoremap <silent> <Tab>m :call utils#tab_move()<CR>
nnoremap <silent> <Tab>> :call utils#tab_move(eval(tabpagenr()+1))<CR>
nnoremap <silent> <Tab>< :call utils#tab_move(eval(tabpagenr()-1))<CR>
for s:num in range(1,10)
  exe 'nnoremap <Tab>' . s:num . ' ' . s:num . 'gt'
endfor
" Window selection and creation
nnoremap <Tab>; <C-w><C-p>
nnoremap <Tab>j <C-w>j
nnoremap <Tab>k <C-w>k
nnoremap <Tab>h <C-w>h
nnoremap <Tab>l <C-w>l
nnoremap <Tab>- :split 
nnoremap <Tab>\ :vsplit 
" Moving screen and resizing windows
" nnoremap ;0 M " center in window
nnoremap <Tab>0 mzz.`z
nnoremap <Tab>i zt
nnoremap <Tab>o zb
nnoremap <Tab>u zH
nnoremap <Tab>p zL
nnoremap <silent> <Tab>= :<C-u>vertical resize 80<CR>
nnoremap <silent> <Tab>( :<C-u>exe 'resize ' . (winheight(0) - 3*max([1, v:count]))<CR>
nnoremap <silent> <Tab>) :<C-u>exe 'resize ' . (winheight(0) + 3*max([1, v:count]))<CR>
nnoremap <silent> <Tab>_ :<C-u>exe 'resize ' . (winheight(0) - 5*max([1, v:count]))<CR>
nnoremap <silent> <Tab>+ :<C-u>exe 'resize ' . (winheight(0) + 5*max([1, v:count]))<CR>
nnoremap <silent> <Tab>[ :<C-u>exe 'vertical resize ' . (winwidth(0) - 5*max([1, v:count]))<CR>
nnoremap <silent> <Tab>] :<C-u>exe 'vertical resize ' . (winwidth(0) + 5*max([1, v:count]))<CR>
nnoremap <silent> <Tab>{ :<C-u>exe 'vertical resize ' . (winwidth(0) - 10*max([1, v:count]))<CR>
nnoremap <silent> <Tab>} :<C-u>exe 'vertical resize ' . (winwidth(0) + 10*max([1, v:count]))<CR>

" SIMPLE WINDOW SETTINGS
" Enable quitting windows with simple 'q' press and disable line numbers
augroup simple
  au!
  au BufEnter * let b:recording = 0
  au BufEnter __doc__ call utils#pager_setup()
  au FileType diff,man,latexmk,vim-plug call utils#popup_setup(1)
  au FileType qf,gitcommit,fugitive call utils#popup_setup(0)
  au FileType help call utils#help_setup()
  au CmdwinEnter * call utils#cmdwin_setup()
  au CmdwinLeave * setlocal laststatus=2
augroup END
" Vim command windows, help windows, man pages, and result of 'cmd --help'
nnoremap <Leader>; :<Up><CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ q/
nnoremap <Leader>? q?
" nnoremap <silent> <Leader>h :call utils#show_vim_help()<CR>
nnoremap <silent> <Leader>h :call utils#show_cmd_help() \| redraw!<CR>
nnoremap <silent> <Leader>m :call utils#show_cmd_man() \| redraw!<CR>
nnoremap <silent> <Leader>v :Help<CR>

" SEARCHING AND FIND-REPLACE STUFF
" Basic stuff first
" * Had issue before where InsertLeave ignorecase autocmd was getting reset; it was
"   because MoveToNext was called with au!, which resets all InsertLeave commands then adds its own
" * Make sure 'noignorecase' turned on when in insert mode, so *autocompletion* respects case.
augroup search_replace
  au!
  au InsertEnter * set noignorecase " default ignore case
  au InsertLeave * set ignorecase
augroup END
" Delete commented text. For some reason search screws up when using \(\) groups, maybe
" because first parts of match are identical?
noremap <expr> <silent> \c ''
    \ . (mode() =~ '^n' ? 'V' : '') . ':<C-u>'
    \ . "'<,'>" . 's/^\s*' . Comment() . '.*$\n//ge \| '
    \ . "'<,'>" . 's/\s\s*' . Comment() . '.*$//ge \| noh<CR>'
" Delete trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
" Replace consecutive spaces on current line with one space, if they're not part of indentation
noremap <silent> \s :s/\(\S\)\@<=\(^ \+\)\@<! \{2,}/ /g \| noh<CR>:echom "Squeezed consecutive spaces."<CR>
noremap <silent> \S :s/\(\S\)\@<=\(^ \+\)\@<! //g \| noh<CR>:echom "Removed whitespace."<CR>
noremap <silent> \w :s/\s\+$//g \| noh<CR>:echom "Trimmed trailing whitespace."<CR>
" Delete empty lines
" Replace consecutive newlines with single newline
noremap <silent> \e :s/^\s*$\n//g \| noh<CR>:echom "Removed empty lines."<CR>
noremap <silent> \E :s/\(\n\s*\n\)\(\s*\n\)\+/\1/g \| noh<CR>:echom "Squeezed consecutive newlines."<CR>
" Replace tabs with spaces
noremap <expr> <silent> \<Tab> ':s/\t/'  . repeat(' ', &tabstop) . '/g \| noh<CR>'
" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
nnoremap <silent> \' :silent! %s/‘/`/g<CR>:silent! %s/’/'/g<CR>:echom "Fixed single quotes."<CR>
nnoremap <silent> \" :silent! %s/“/``/g<CR>:silent! %s/”/''/g<CR>:echom "Fixed double quotes."<CR>
nnoremap <silent> \- :silent! %s/–/--/g<CR>:echom "Fixed long dashes."<CR>
nnoremap <silent> \_ :silent! %s/\(\w\)[-–] /\1/g<CR>:echom "Fixed trailing dashes."<CR>

" CAPS LOCK
" See <http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock>, instead uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1
for s:c in range(char2nr('A'), char2nr('Z'))
  exe 'lnoremap ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
  exe 'lnoremap ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
endfor
" Caps lock toggle and insert mode maps that toggle it on and off
set iminsert=0
augroup caps_lock
  au!
  au InsertLeave * setlocal iminsert=0
augroup END
inoremap <C-v> <C-^>
cnoremap <C-v> <C-^>

" COPY MODE
command! -nargs=? CopyToggle call utils#copy_toggle(<args>)
nnoremap <Leader>c :call utils#copy_toggle()<CR>

" SPELLCHECK (really is a builtin plugin, hence why it's in this section)
" Turn on for certain filetypes
augroup spell_toggle
  au!
  au FileType tex,html,markdown,rst if @% != '__doc__' | call spell#spell_toggle(1) | endif
augroup END

" Toggle spelling on and off
command! SpellToggle call spell#spell_toggle(<args>)
command! LangToggle call spell#lang_toggle(<args>)

" Toggle on and off
nnoremap <silent> <Leader>d :call spell#spell_toggle(1)<CR>
nnoremap <silent> <Leader>D :call spell#spell_toggle(0)<CR>
nnoremap <silent> <Leader>k :call spell#lang_toggle(1)<CR>
nnoremap <silent> <Leader>K :call spell#lang_toggle(0)<CR>

" Add and remove from dictionary
nnoremap <Leader>l zg
nnoremap <Leader>L zug
nnoremap <Leader>! z=

" Similar to ]s and [s but also correct the word!
nnoremap <silent> <Plug>forward_spell bh]s:call spell#spell_change(']')<CR>:call repeat#set("\<Plug>forward_spell")<CR>
nnoremap <silent> <Plug>backward_spell el[s:call spell#spell_change('[')<CR>:call repeat#set("\<Plug>backward_spell")<CR>
nmap ]d <Plug>forward_spell
nmap [d <Plug>backward_spell

" Automatically update binary spellfile
" See: https://vi.stackexchange.com/a/5052/8084
for s:spellfile in glob('~/.vim/spell/*.add', 1, 1)
    if filereadable(s:spellfile) && (
      \ !filereadable(s:spellfile . '.spl') ||
      \ getftime(s:spellfile) > getftime(s:spellfile . '.spl')
      \ )
        echom 'Update spellfile!'
        silent! exec 'mkspell! ' . fnameescape(s:spellfile)
    endif
endfor

" g CONFIGURATION
" Free up m keys, so ge/gE command belongs as single-keystroke words along with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Capitalization stuff with g, a bit refined
" not currently used in normal mode, and fits better mnemonically
" Mnemonic is l for letter, t for title case
nnoremap gu guiw
nnoremap gU gUiw
vnoremap gl ~
nnoremap <silent> <Plug>cap1 ~h:call repeat#set("\<Plug>cap1")<CR>
nnoremap <silent> <Plug>cap2 mzguiw~h`z:call repeat#set("\<Plug>cap2")<CR>
nmap gl <Plug>cap1
nmap gt <Plug>cap2
vnoremap gt mzgu<Esc>`<~h

" Default 'open file under cursor' to open in new tab; change for normal and vidual
" Remember the 'gd' and 'gD' commands go to local declaration, or first instance.
function! s:file_exists()
  let files = glob(expand('<cfile>'))
  if len(files) > 0
    echom 'File(s) ' . join(map(a:0, '"''".v:val."''"'), ', ') . ' exist.'
  else
    echom "File or pattern '" . expand('<cfile>') . "' does not exist."
  endif
endfunction
nnoremap <Leader>F <c-w>gf
nnoremap <silent> <Leader>f :<C-u>call <sid>file_exists()<CR>

" Now remap indentation commands. Why is this here? Just go with it.
" Note the <Esc> is needed first because it cancels application of the number operator
" to what follows; we want to use that number operator for our own purposes
nnoremap <expr> <nowait> > (v:count) > 1 ? '<Esc>'.repeat('>>', v:count) : '>>'
nnoremap <expr> <nowait> < (v:count) > 1 ? '<Esc>'.repeat('<<', v:count) : '<<'
nnoremap <nowait> = ==

" Simpyl settings
let g:SimpylFold_docstring_preview = 1
let g:SimpylFold_fold_import = 0
let g:SimpylFold_fold_imports = 0
let g:SimpylFold_fold_docstring = 0
let g:SimpylFold_fold_docstrings = 0

" Delete, open, close all folds, to open/close under cursor use zo/zc
nnoremap zD zE
nnoremap zO zR
nnoremap zC zM

" GUI VIM COLORS
" See: https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
" gruvbox, kolor, dracula, onedark, molokai, yowish, tomorrow-night
" atom, chlordane, papercolor, solarized, fahrenheit, slate, oceanicnext
if has('gui_running')
  hi! link vimCommand Statement
  hi! link vimNotFunc Statement
  hi! link vimFuncKey Statement
  hi! link vimMap     Statement
  colorscheme oceanicnext
endif

" TERMINAL VIM COLORS
" For adding keywords, see: https://vi.stackexchange.com/a/11547/8084
" The url regex was copied from the one used for .tmux.conf
" Warning: Cannot use filetype specific elgl au Syntax *.tex commands to overwrite
" existing highlighting. An after/syntax/tex.vim file is necessary.
" Warning: The containedin just tries to *guess* what particular comment and
" string group names are for given filetype syntax schemes. Verify that the
" regexes will match using :Group with cursor over a comment. For example, had
" to change .*Comment to .*Comment.* since Julia has CommentL name
function! s:keywordsetup()
   syn match customURL =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^'  <>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
   syn match markdownHeader =^# \zs#\+.*$= containedin=.*Comment.*
   hi link customURL Underlined
   hi link markdownHeader Special
   if &ft !=# 'vim'
     syn match Todo '\C\%(WARNINGS\=\|ERRORS\=\|FIXMES\=\|TODOS\=\|NOTES\=\|XXX\)\ze:\=' containedin=.*Comment.* " comments
     syn match Special '^\%1l#!.*$' " shebangs
   else
     syn clear vimTodo " vim instead uses the Stuff: syntax
   endif
endfunction
augroup syntax_overrides
  au!
  au Syntax * call s:keywordsetup()
  au BufRead * set conceallevel=2 concealcursor=
  au InsertEnter * highlight StatusLine ctermbg=Black ctermbg=White ctermfg=Black cterm=NONE
  au InsertLeave * highlight StatusLine ctermbg=White ctermbg=Black ctermfg=White cterm=NONE
augroup END

" Filetype specific commands
" highlight link htmlNoSpell
highlight link pythonImportedObject Identifier

" Popup menu
highlight Pmenu     ctermbg=NONE    ctermfg=White cterm=NONE
highlight PmenuSel  ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE    ctermfg=Black cterm=NONE

" Magenta is uncommon color, so use it for sneak and highlighting
highlight Sneak ctermbg=DarkMagenta ctermfg=NONE
highlight Search ctermbg=Magenta ctermfg=NONE

" Fundamental changes, move control from LightColor to Color and DarkColor,
" because ANSI has no control over light ones it seems.
highlight Type        ctermbg=NONE ctermfg=DarkGreen
highlight Constant    ctermbg=NONE ctermfg=Red
highlight Special     ctermbg=NONE ctermfg=DarkRed
highlight PreProc     ctermbg=NONE ctermfg=DarkCyan
highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold

" Features that only work in iTerm with minimum contrast setting
" highlight LineNR       cterm=NONE ctermbg=NONE ctermfg=Gray
" highlight Comment    ctermfg=Gray cterm=NONE
highlight LineNR     cterm=NONE    ctermbg=NONE  ctermfg=Black
highlight Comment    ctermfg=Black cterm=NONE
highlight StatusLine ctermbg=Black ctermfg=White cterm=NONE

" Special characters
highlight NonText    ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE

" Matching parentheses
highlight Todo       ctermfg=NONE  ctermbg=Red
highlight MatchParen ctermfg=NONE ctermbg=Blue

" Cursor line or column highlighting using color mapping set by CTerm (PuTTY lets me set
" background to darker gray, bold background to black, 'ANSI black' to a slightly lighter
" gray, and 'ANSI black bold' to black). Note 'lightgray' is just normal white
highlight CursorLine   cterm=NONE ctermbg=Black
highlight CursorLineNR cterm=NONE ctermbg=Black ctermfg=White

" Column stuff, color 80th column and after 120
highlight ColorColumn  cterm=NONE ctermbg=Gray
highlight SignColumn  guibg=NONE cterm=NONE ctermfg=Black ctermbg=NONE

" Make sure terminal background is same as main background
highlight Terminal ctermbg=NONE ctermfg=NONE

" Make Conceal highlighting group transparent so when you set the conceallevel
" to 0, concealed elements revert to their original highlighting.
highlight Conceal ctermbg=NONE ctermfg=NONE ctermbg=NONE ctermfg=NONE

" Transparent dummy group used to add @Nospell
highlight Dummy ctermbg=NONE ctermfg=NONE

" Helper commands defined in utils
command! Group call utils#current_group()
command! -nargs=? Syntax call utils#current_syntax(<q-args>)
command! PluginFile call utils#show_ftplugin()
command! SyntaxFile call utils#show_syntax()
command! Colors call utils#show_colors()
command! GroupColors vert help group-name

"-----------------------------------------------------------------------------"
" EXIT
"-----------------------------------------------------------------------------"
" Clear past jumps
" Don't want stuff from plugin files and the vimrc populating jumplist after statrup
" Simple way would be to use au BufRead * clearjumps
" But older versions of VIM have no 'clearjumps' command, so this is a hack
" see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clear_jumps
  au!
  if exists(':clearjumps')
    au BufRead * clearjumps "see help info on exists()
  else
    au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  endif
augroup END
" Clear writeable registers
" On some vim versions [] fails (is ideal, because removes from :registers), but '' will at least empty them out
" See thread: https://stackoverflow.com/questions/19430200/how-to-clear-vim-registers-effectively
" WARNING: On cheyenne, get lalloc error when calling WipeReg, strange
if $HOSTNAME !~# 'cheyenne'
  command! WipeReg for i in range(34,122) | silent! call setreg(nr2char(i), '') | silent! call setreg(nr2char(i), []) | endfor
  WipeReg
endif
noh " turn off highlighting at startup
redraw! " weird issue sometimes where statusbar disappears
