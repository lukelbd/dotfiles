" .vimrc
"-----------------------------------------------------------------------------"
" A fancy vimrc that does all sorts of magical things.
" NOTE: Have iTerm map some ctrl+key combinations that would otherwise
" be impossible to the F1, F2 keys. Currently they are:
"     F1: 1b 4f 50 (Ctrl-,)
"     F2: 1b 4f 51 (Ctrl-.)
"     F3: 1b 4f 52 (Ctrl-i)
"     F4: 1b 4f 53 (Ctrl-m)
"     F5: 1b 5b 31 35 7e (shift-forward delete/shift-caps lock on macbook)
"     F6: 1b 5b 31 37 7e (Ctrl-;)
" Also use Karabiner 'map Ctrl-j/k/h/l to arrow keys', so be aware that if
" you map those keys in Vim, should also map arrows.
"-----------------------------------------------------------------------------"
" IMPORTANT STUFF and SETTINGS
" First the settings
let mapleader = "\<Space>"
set confirm " require confirmation if you try to quit
set nocompatible " always use the vim defaults
set cursorline
set tabpagemax=100 " allow opening shit load of tabs at once
set redrawtime=5000 " sometimes takes a long time, let it happen
set maxmempattern=50000 " from 1000 to 10000
set shortmess=a " snappy messages, from the avoid press enter doc
set shiftround " round to multiple of shift width
set viminfo='100,:100,<100,@100,s10,f0 " commands, marks (e.g. jump history), exclude registers >10kB of text
set history=100 " search history
set shell=/usr/bin/env\ bash
set nrformats=alpha " never interpret numbers as 'octal'
set scrolloff=4
let &g:colorcolumn = (has('gui_running') ? '0' : '80,120')
set slm= " disable 'select mode' slm, allow only visual mode for that stuff
set background=dark " standardize colors -- need to make sure background set to dark, and should be good to go
set updatetime=1000 " used for CursorHold autocmds
set nobackup noswapfile noundofile " no more swap files; constantly hitting C-s so it's safe
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:· " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set number numberwidth=4 " note old versions can't combine number with relativenumber
set relativenumber
set tabstop=2 " shoft default tabs
set shiftwidth=2
set softtabstop=2
set expandtab " says to always expand \t to their length in <SPACE>'s!
set autoindent " indents new lines
set backspace=indent,eol,start " backspace by indent - handy
set nostartofline " when switching buffers, doesn't move to start of line (weird default)
set nolazyredraw  " maybe slower, but looks super cool and pretty and stuff
set virtualedit=  " prevent cursor from going where no actual character
set noerrorbells visualbell t_vb= " enable internal bell, t_vb= means nothing is shown on the window
set esckeys " make sure enabled, allows keycodes
set notimeout timeoutlen=0 " wait forever when doing multi-key *mappings*
set ttimeout ttimeoutlen=0 " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set complete-=k complete+=k " add dictionary search, as per dictionary option
set splitright " splitting behavior
set splitbelow
set nospell spelllang=en_us spellcapcheck= " spellcheck off by default
set hlsearch incsearch " show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase " smartcase makes search case insensitive, unless has capital letter
set foldmethod=expr " fold methods
set foldlevel=99
set foldlevelstart=99
set foldnestmax=10 " avoids weird things
set foldopen=tag,mark " options for opening folds on cursor movement; disallow block
if has('gui_running')
  set number relativenumber guioptions= guicursor+=a:blinkon0 " no scrollbars or blinking
endif
if exists('&breakindent')
  set breakindent " map indentation when breaking
endif

" Forward delete by tabs
function! s:forward_delete()
  let line = getline('.')
  if line[col('.') - 1:col('.') - 1 + &tabstop - 1] == repeat(" ", &tabstop)
    return repeat("\<Delete>", &tabstop)
  else
    return "\<Delete>"
  endif
endfunction
inoremap <silent> <expr> <Delete> <sid>forward_delete()

" Enforce global settings that filetype options may try to override
set display=lastline " displays as much of wrapped lastline as possible;
let &breakat = " 	!*-+;:,./?" " break at single instances of several characters
let g:set_overrides = 'linebreak wrapmargin=0 textwidth=0 formatoptions=lroj'
augroup globals
  au!
  au BufEnter * exe 'setlocal ' . g:set_overrides
augroup END
exe 'setlocal ' . g:set_overrides

" Escape repair, needed when we allow h/l to change line number
set whichwrap=[,],<,>,h,l " <> = left/right insert, [] = left/right normal mode
augroup escapefix
  au!
  au InsertLeave * normal! `^
augroup END

" Detect features; variables are used to decide which plugins can be loaded
exe 'runtime autoload/repeat.vim'
let g:has_signs = has('signs') " for git gutter and syntastic maybe
let g:has_ctags = str2nr(system('type ctags &>/dev/null && echo 1 || echo 0'))
let g:has_nowait = (v:version >= 704 || v:version == 703 && has('patch1261'))
let g:has_repeat = exists('*repeat#set') " start checks for function existence
if !g:has_repeat
  echohl WarningMsg
  echom "Warning: vim-repeat unavailable, some features will be unavailable."
  echohl None
endif

" Wildmenu options
set wildmenu
set wildmode=longest:list,full
let &g:wildignore = '*.pdf,*.doc,*.docs,*.page,*.pages,'
  \ . '*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.svg,*.pyc,*.o,*.mod,'
  \ . '*.mp3,*.m4a,*.mp4,*.mov,*.flac,*.wav,*.mk4,'
  \ . '*.dmg,*.zip,*.sw[a-z],*.tmp,*.nc,*.DS_Store,'
function! s:wild_tab()
  call feedkeys("\<Tab>", 't') | return ''
endfunction
function! s:wild_stab()
  call feedkeys("\<S-Tab>", 't') | return ''
endfunction
cnoremap <expr> <F1> <sid>wild_stab()
cnoremap <expr> <F2> <sid>wild_tab()

" Remove weird Cheyenne maps, not sure how to isolate/disable /etc/vimrc without
" disabling other stuff we want e.g. syntax highlighting
if mapcheck('<Esc>', 'n') != ''
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

" Suppress all mappings with certain prefix
" Note that <C-b> prefix is used for citation inserts
function! Suppress(prefix, mode)
  let c = nr2char(getchar())
  if maparg(a:prefix . c, a:mode) != ''
    return a:prefix . c
  else
    return ''
  endif
endfunction
for s:pair in [['n', '<Leader>'], ['n', '<Tab>'], ['n', '\'], ['i', '<C-s>'], ['i', '<C-z>'], ['i', '<C-b>']]
  let s:mode = s:pair[0]
  let s:char = s:pair[1]
  if mapcheck(s:char) == ''
    exe "nmap <expr> " . s:char . " Suppress('" . s:char . "', '" . s:mode . "')"
  endif
endfor

" Toggle conceal on and off
function! s:conceal_toggle(...)
  if a:0
    let conceal_on = a:1
  else
    let conceal_on = (&conceallevel ? 0 : 2) " turn off and on
  endif
  exe 'set conceallevel=' . (conceal_on ? 2 : 0)
endfunction
command! -nargs=? ConcealToggle call s:conceal_toggle(<args>)
" Toggling tabs on and off
let g:tabtoggle_tab_filetypes = ['text', 'gitconfig', 'make']
augroup tab_toggle
  au!
  exe 'au FileType ' . join(g:tabtoggle_tab_filetypes, ',') . 'TabToggle 1'
augroup END
function! s:tab_toggle(...)
  if a:0
    let &l:expandtab = 1 - a:1 " toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:tab_mode = &l:expandtab
endfunction
command! -nargs=? TabToggle call s:tab_toggle(<args>)
nnoremap <Leader><Tab> :TabToggle<CR>

" CHANGE/ADD PROPERTIES/SHORTCUTS OF VERY COMMON ACTIONS
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
nnoremap <Leader>; :<C-u>RemoveHighlights<CR>
nnoremap <expr> <F6> "`" . nr2char(97+v:count)
nnoremap <expr> ; 'm' . nr2char(97+v:count) . ':HighlightMark ' . nr2char(97+v:count) . '<CR>'
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
" Maps for inserting blank lines
nnoremap <silent> ` :call append(line('.'),'')<CR>
nnoremap <silent> ~ :call append(line('.')-1,'')<CR>
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
" Mnemonic is 'cut line' at cursor; character under cursor will be deleted
nnoremap dL mzi<CR><Esc>`z
" Pressing enter on empty line preserves leading whitespace
nnoremap o ox<BS>
nnoremap O Ox<BS>
" Paste from the nth previously deleted or changed text
" Use 'yp' to paste last yanked, unchanged text, because cannot use zero
nnoremap yp "0p
nnoremap yP "0P
nnoremap <expr> p v:count == 0 ? 'p' : '<Esc>"'.v:count.'p'
nnoremap <expr> P v:count == 0 ? 'P' : '<Esc>"'.v:count.'P'
" Yank until end of line, like C and D
nnoremap Y y$
" Put last search into unnamed register
nnoremap <silent> y/ :let @" = @/<CR>
nnoremap <silent> y? :let @" = @/<CR>
" Better join behavior -- before 2J joined this line and next, now it
" means 'join the two lines below'; more intuitive
nnoremap <expr> J v:count > 1  ? 'JJ' : 'J'
nnoremap <expr> K v:count == 0 ? 'Jx' : repeat('Jx',v:count)
" Toggle highlighting
nnoremap <silent> <Leader>o :noh<CR>
nnoremap <silent> <Leader>O :set hlsearch<CR>
" Move to current directory
" Pneumonic is 'inside' just like Ctrl + i map
nnoremap <silent> <Leader>i :lcd %:p:h<CR>:echom "Descended into file directory."<CR>
" Enable left mouse click in visual mode to extend selection, normally this is impossible
" TODO: Modify enter-visual mode maps! See: https://stackoverflow.com/a/15587011/4970632
" Want to be able to *temporarily turn scrolloff to infinity* when enter visual
" mode, to do that need to map vi and va stuff
nnoremap v myv
nnoremap V myV
nnoremap <C-v> my<C-v>
nnoremap <silent> v/ hn:noh<CR>mygn
vnoremap <silent> <LeftMouse> <LeftMouse>mx`y:exe "normal! ".visualmode()<CR>`x
vnoremap <CR> <C-c>
" Visual mode p/P to replace selected text with contents of register
vnoremap p "_dP
vnoremap P "_dP
" Navigation, used to be part of idetools but too esoteric
" TODO: Integrate tags plugin with vim so we can use ctrl-]
" nnoremap <CR> <C-]>
noremap <expr> <silent> gc search('^\ze\s*' . Comment() . '.*$', '') . 'gg'
noremap <expr> <silent> gC search('^\ze\s*' . Comment() . '.*$', 'b') . 'gg'
noremap <expr> <silent> ge search('^\ze\s*$', '') . 'gg'
noremap <expr> <silent> gE search('^\ze\s*$', 'b') . 'gg'
" Alias single-key builtin text objects
for s:pair in ['r[', 'a<', 'c{']
  exe 'onoremap i' . s:pair[0] . ' i' . s:pair[1]
  exe 'xnoremap i' . s:pair[0] . ' i' . s:pair[1]
  exe 'onoremap a' . s:pair[0] . ' a' . s:pair[1]
  exe 'xnoremap a' . s:pair[0] . ' a' . s:pair[1]
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

" POPUP MENU RELATED MAPS
" Count number of tabs in popup menu so our position is always known
augroup popuphelper
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
" NOTE: Try let a = 1 ? 1 ? 'a' : 'b' : 'c', this works!
" WARNING: The space remap and tab remap break insert mode abbreviations!
" To use abbreviations you must trigger manually with <C-]> (see :help i_Ctrl-])
" First keystrokes that close popup menu
inoremap <expr> <BS> pumvisible() ? <sid>tab_reset() . "\<C-e>\<BS>" : "\<BS>"
inoremap <expr> <Space> pumvisible() ? <sid>tab_reset() . "\<C-]>\<Space>" : "\<C-]>\<Space>"
" Enter means 'accept' only when we have explicitly scrolled down to something
" Tab always means 'accept' and choose default menu item if necessary
inoremap <expr> <CR> pumvisible() ? b:menupos ? "\<C-y>" . <sid>tab_reset() : "\<C-e>\<C-]>\<CR>" : "\<C-]>\<CR>"
inoremap <expr> <Tab> pumvisible() ? b:menupos ? "\<C-y>" . <sid>tab_reset() : "\<C-n>\<C-y>" . <sid>tab_reset() : "\<C-]>\<Tab>"
" Incrementing items in menu
inoremap <expr> <C-k> pumvisible() ? <sid>tab_decrease() . "\<C-p>" : "\<Up>"
inoremap <expr> <C-j> pumvisible() ? <sid>tab_increase() . "\<C-n>" : "\<Down>"
inoremap <expr> <Up> pumvisible() ? <sid>tab_decrease() . "\<C-p>" : "\<Up>"
inoremap <expr> <Down> pumvisible() ? <sid>tab_increase() . "\<C-n>" : "\<Down>"
inoremap <expr> <ScrollWheelUp> pumvisible() ? <sid>tab_decrease() . "\<C-p>" : ""
inoremap <expr> <ScrollWheelDown> pumvisible() ? <sid>tab_increase() . "\<C-n>" : ""

" GLOBAL FUNCTIONS, FOR VIM SCRIPTING
" Test plugin status
function! PlugActive(key)
  return has_key(g:plugs, a:key) " change if (e.g.) switch plugin managers
endfunction
" Return whether inside list
function! In(list,item)
  return index(a:list,a:item) != -1
endfunction
" Reverse string
function! Reverse(text) " want this to be accessible!
  return join(reverse(split(a:text, '.\zs')), '')
endfunction
" Strip leading and trailing whitespace
function! Strip(text)
  return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction
" Null list for completion, so tab doesn't produce literal char
function! NullList(A, L, P)
  return []
endfunction
" Reverse selected lines
function! ReverseLines(l1, l2)
  let line1 = a:l1 " cannot overwrite input var names
  let line2 = a:l2
  if line1 == line2
    let line1 = 1
    let line2 = line('$')
  endif
  exec 'silent '.line1.','.line2.'g/^/m'.(line1 - 1)
endfunction
command! -range Reverse call ReverseLines(<line1>, <line2>)
" Better grep, with limited regex translation
function! Grep(regex) " returns list of matches
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
  if &ft != '' && &commentstring =~ '%s'
    return Strip(split(&commentstring, '%s')[0])
  else
    return ''
  endif
endfunction
" As above but return a character that is never matched if no comment char found
" This if for use in Tabular regex statements
function! RegexComment()
  let comment = Comment()
  if comment == ''
    let comment = ' '
  endif
  return comment
endfunction

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
if exists("&t_SI")
  let &t_SI = (exists('$TMUX') ? "\ePtmux;\e\e[6 q\e\\" : "\e[6 q")
endif
if exists("&t_SR")
  let &t_SR = (exists('$TMUX') ? "\ePtmux;\e\e[4 q\e\\" : "\e[4 q")
endif
if exists("&t_EI")
  let &t_EI = (exists('$TMUX') ? "\ePtmux;\e\e[2 q\e\\" : "\e[2 q")
endif

"-----------------------------------------------------------------------------"
" COMPLICATED MAPPINGS AND FILETYPE MAPPINGS
"-----------------------------------------------------------------------------"
" VIM-PLUG PLUGINS
" Don't load some plugins if not compatible
let g:compatible_tagbar = (g:has_ctags && (v:version >= 704 || v:version == 703 && has("patch1058")))
let g:compatible_codi = (v:version >= 704 && has('job') && has('channel'))
let g:compatible_workspace = (v:version >= 800) " needs Git 8.0, so not too useful
let g:compatible_neocomplete = has("lua") " try alternative completion library
if expand('$HOSTNAME') =~ 'cheyenne\?' | let g:compatible_neocomplete = 0 | endif " had annoying bugs with refactoring tools
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
Plug 'flazz/vim-colorschemes'
Plug 'fcpg/vim-fahrenheit'
Plug 'KabbAmine/yowish.vim'
" Plug 'altercation/vim-colors-solarized'

" Proper syntax highlighting for a few different things
" Note impsort sorts import statements, and highlights modules with an after/syntax script
Plug 'tmux-plugins/vim-tmux'
Plug 'plasticboy/vim-markdown'
Plug 'vim-scripts/applescript.vim'
Plug 'anntzer/vim-cython'
Plug 'tpope/vim-liquid'
" Plug 'tweekmonster/impsort.vim' " this fucking thing has an awful regex, breaks if you use comments, fuck that shit
" Plug 'hdima/python-syntax' " this failed for me; had to manually add syntax file; f-strings not highlighted, and other stuff!

" TeX utilities; better syntax highlighting, better indentation,
" and some useful remaps. Also zotero integration.
Plug 'Shougo/unite.vim'
Plug 'rafaqz/citation.vim'
" Plug 'twsh/unite-bibtex' " python 3 version
" Plug 'msprev/unite-bibtex' " python 2 version
" Plug 'lervag/vimtex'
" Plug 'chrisbra/vim-tex-indent'

" Julia support and syntax highlighting
Plug 'JuliaEditorSupport/julia-vim'

" Python wrappers
Plug 'vim-scripts/Pydiction' " just changes completeopt and dictionary and stuff
" Plug 'davidhalter/jedi-vim' " mostly autocomplete stuff
" Plug 'cjrh/vim-conda'       " for changing anconda VIRTUALENV; probably don't need it
" Plug 'klen/python-mode'     " incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython'   " same problem as python-mode

" Folding and matching
if g:has_nowait | Plug 'tmhedberg/SimpylFold' | endif
let g:loaded_matchparen = 1
Plug 'Konfekt/FastFold'
Plug 'andymass/vim-matchup'
let g:matchup_matchparen_enabled = 1
let g:matchup_transmute_enabled = 0 " breaks latex!

" Files and directories
Plug 'scrooloose/nerdtree'
if g:compatible_tagbar | Plug 'majutsushi/tagbar' | endif
" Plug 'jistr/vim-nerdtree-tabs' "unnecessary
" Plug 'vim-scripts/EnhancedJumps'

" Commenting and syntax checking
" NOTE: Syntastic looks for checker commands in your PATH! You must install
" them manually!
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'

" Sessions and swap files and reloading
" Mapped in my .bashrc vims to vim -S .vimsession and exiting vim saves the session there
" Also vim-obsession more compatible with older versions
" NOTE: Apparently obsession causes all folds to be closed
Plug 'tpope/vim-obsession'
" if g:compatible_workspace | Plug 'thaerkh/vim-workspace' | endif
" Plug 'gioele/vim-autoswap' "deals with swap files automatically; no longer use them so unnecessary
" Plug 'xolox/vim-reload' "better to write my own simple plugin

" Git wrappers and differencing tools
Plug 'tpope/vim-fugitive'
if g:has_signs | Plug 'airblade/vim-gitgutter' | endif

" Shell utilities, including Chmod and stuff
Plug 'tpope/vim-eunuch'

" Completion engines
" Plug 'Valloric/YouCompleteMe' "broken
" Plug 'ajh17/VimCompletesMe' "no auto-popup feature
" Plug 'lifepillar/vim-mucomplete' "broken, seriously, cannot get it to work, don't bother! is slow anyway.
" if g:compatible_neocomplete | Plug 'ervandew/supertab' | endif "haven't tried it
if g:compatible_neocomplete | Plug 'shougo/neocomplete.vim' | endif

" Delimiters
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'

" Custom text objects (inner/outer selections)
" a,b, asdfas, adsfashh
Plug 'kana/vim-textobj-user'   " base
Plug 'kana/vim-textobj-indent' " match indentation, object is 'i'
Plug 'kana/vim-textobj-entire' " entire file, object is 'e'
" Plug 'sgur/vim-textobj-parameter' " disable because this conflicts with latex
" Plug 'bps/vim-textobj-python' " not really ever used, just use indent objects
" Plug 'vim-scripts/argtextobj.vim' " arguments
" Plug 'machakann/vim-textobj-functioncall' " fucking sucks/doesn't work, fuck you

" Aligning things and stuff
" Alternative to tabular is: https://github.com/tommcdo/vim-lion
" But in defense tabular is *super* flexible
Plug 'godlygeek/tabular'

" Better motions
" Sneak plugin; see the link for helpful discussion:
" https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
Plug 'justinmk/vim-sneak'

" Calculators and number stuff
" No longer use codi, because had endless problems with it, and this cool 'Numi'
" desktop calculator will suffice
Plug 'triglav/vim-visual-increment' " visual incrementing/decrementing
" Plug 'vim-scripts/Toggle' "toggling stuff on/off; modified this myself
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
if g:compatible_codi | Plug 'metakirby5/codi.vim' | endif

" All of this rst shit failed; anyway can just do simple tables with == signs
" instead of those fancy grid cell tables.
" Plug 'nvie/vim-rst-tables'
" Plug 'ossobv/vim-rst-tables-py3'
" Plug 'philpep/vim-rst-tables'
" noremap <silent> \s :python ReformatTable()<CR>
" Try again; also adds ReST highlighting to docstrings
" Also fails! Fuck this shit.
" Plug 'Rykka/riv.vim'
" let g:riv_python_rst_hl = 1

" Single line/multiline transition; make sure comes after surround
" Hardly ever need this
" Plug 'AndrewRadev/splitjoin.vim'
" let g:splitjoin_split_mapping = 'cS' | let g:splitjoin_join_mapping  = 'cJ'

" Multiple cursors is awesome
" Article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" Plug 'terryma/vim-multiple-cursors'

" Indent line
" WARNING: Right now *totally* fucks up search mode, and cursorline overlaps. So not good.
" Requires changing Conceal group color, but doing that also messes up latex conceal
" backslashes (which we need to stay transparent); so forget it probably
" Plug 'yggdroot/indentline'

" Superman man pages (not really used currently)
" Plug 'jez/vim-superman'

" Thesaurus; appears broken
" Plug 'beloglazov/vim-online-thesaurus'

" Automatic list numbering; actually it mysteriously fails so fuck that shit
" let g:bullets_enabled_file_types = ['vim', 'markdown', 'text', 'gitcommit', 'scratch']
" Plug 'dkarter/bullets.vim'

" Easy tags, for easy integration
" Plug 'xolox/vim-misc' "depdency for easytags
" Plug 'xolox/vim-easytags' "kinda old and not that useful honestly
" Plug 'ludovicchabant/vim-gutentags' "slows shit down like crazy

" Colorize Hex strings
" Note this option is ***incompatible*** with iTerm minimum contrast above 0
" Actually tried with minimum contrast zero and colors *still* messed up; forget it
" Plug 'lilydjwg/colorizer'

" End of plugins
" The plug#end also declares filetype plugin, syntax, and indent on
" Note apparently every BufRead autocmd inside an ftdetect/filename.vim file
" is automatically made part of the 'filetypedetect' augroup; that's why it exists!
call plug#end()

" DELIMS and NAVIGATION
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
" Auto-generate delimiters
if PlugActive('delimitmate')
  " First filetype settings
  " Enable carat matching for filetypes where need tags (or keycode symbols)
  " Vim needs to disable matching ", or everything is super slow
  " Tex need | for verbatim environments; note you *cannot* do set matchpairs=xyz; breaks plugin
  " Markdown need backticks for code, and can maybe do LaTeX math
  augroup delims
    au!
    au FileType vim let b:delimitMate_quotes = "'" | let b:delimitMate_matchpairs = "(:),{:},[:],<:>"
    au FileType tex let b:delimitMate_quotes = "$ |" | let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
    au FileType html let b:delimitMate_matchpairs = "(:),{:},[:],<:>"
    au FileType markdown,rst let b:delimitMate_quotes = "\" ' $ `"
  augroup END
  " Set global defaults along with buffer-specific alternatives
  let g:delimitMate_expand_space = 1
  let g:delimitMate_expand_cr = 2 " expand even if it is not empty!
  let g:delimitMate_jump_expansion = 0
  let g:delimitMate_quotes = "\" '"
  let g:delimitMate_matchpairs = "(:),{:},[:]"
  let g:delimitMate_excluded_regions = "String" "by default is disabled inside, don't want that
endif

" SURROUND
" For now pretty empty, but we should add to this
" Note that tag delimiters are *built in* to vim-surround
" Just use the target 't', and prompt will ask for description
if PlugActive('vim-surround')
  augroup surround
    au!
    au FileType html call s:htmlmacros()
  augroup END
  " Define global, *insertable* vim-surround targets
  " Multichar Delims: Surround can 'put' them, but cannot 'find' them
  " e.g. in a ds<custom-target> or cs<custom-target><other-target> command.
  " Single Delims: Delims *can* be 'found' if they are single character, but
  " setting g:surround_does not do so -- instead, just map commands
  " Helper func
  function! s:target(map, start, end) " if final argument passed, this is buffer-local
    let g:surround_{char2nr(a:map)} = a:start . "\r" . a:end
  endfunction
  " Go
  call s:target('c', '{', '}')
  nmap dsc dsB
  nmap csc csB
  call s:target('\', '\"', '\"')
  nmap ds\ /\\"<CR>xxdN
  nmap cs\ /\\"<CR>xNx
  call s:target('p', 'print(', ')')
  call s:target('f', "\1function: \1(", ')') "initial part is for prompt, needs double quotes
  nnoremap dsf mzF(bdt(xf)x`z
  nnoremap <expr> csf 'F(hciw'.input('function: ').'<Esc>'
  " Define additional shortcuts like ys's' for the non-whitespace part
  " of this line -- use 'w' for <cword>, 'W' for <CWORD>, 'p' for current paragraph
  nmap ysw ysiw
  nmap ysW ysiW
  nmap ysp ysip
  nmap ys. ysis
  nmap ySw ySiw
  nmap ySW ySiW
  nmap ySp ySip
  nmap yS. ySis
  " Define HTML macros
  function! s:htmlmacros()
    call s:target('h', '<head>',   '</head>',   1)
    call s:target('o', '<body>',   '</body>',   1)
    call s:target('t', '<title>',  '</title>',  1)
    call s:target('e', '<em>',     '</em>',     1)
    call s:target('t', '<strong>', '</strong>', 1)
    call s:target('p', '<p>',      '</p>',      1)
    call s:target('1', '<h1>',     '</h1>',     1)
    call s:target('2', '<h2>',     '</h2>',     1)
    call s:target('3', '<h3>',     '</h3>',     1)
    call s:target('4', '<h4>',     '</h4>',     1)
    call s:target('5', '<h5>',     '</h5>',     1)
  endfunction
endif

" TEXT OBJECTS
" Many of these just copied, some ideas for future:
" https://github.com/kana/vim-textobj-lastpat/tree/master/plugin/textobj
if PlugActive('vim-textobj-user')
  " Functions for current line stuff
  function! s:current_line_a()
    normal! 0
    let head_pos = getpos('.')
    normal! $
    let tail_pos = getpos('.')
    return ['v', head_pos, tail_pos]
  endfunction
  function! s:current_line_i()
    normal! ^
    let head_pos = getpos('.')
    normal! g_
    let tail_pos = getpos('.')
    let non_blank_char_exists_p = (getline('.')[head_pos[2] - 1] !~# '\s')
    return (non_blank_char_exists_p ? ['v', head_pos, tail_pos] : 0)
  endfunction

  " Functions for blank line stuff
  function! s:lines_helper(pnb, nnb)
    let start_line = (a:pnb == 0) ? 1         : a:pnb + 1
    let end_line   = (a:nnb == 0) ? line('$') : a:nnb - 1
    let start_pos = getpos('.') | let start_pos[1] = start_line
    let end_pos   = getpos('.') | let end_pos[1]   = end_line
    return ['V', start_pos, end_pos]
  endfunction
  function! s:blank_lines()
    normal! 0
    let pnb = prevnonblank(line('.'))
    let nnb = nextnonblank(line('.'))
    if pnb == line('.') " also will be true for nextnonblank, if on nonblank
      return 0
    endif
    return s:lines_helper(pnb,nnb)
  endfunction

  " Functions for new and improved paragraph stuff
  function! s:nonblank_lines()
    normal! 0l
    let nnb = search('^\s*\zs$', 'Wnc') " the c means accept current position
    let pnb = search('^\ze\s*$', 'Wnbc') " won't work for backwards search unless to right of first column
    if pnb == line('.')
      return 0
    endif
    return s:lines_helper(pnb,nnb)
  endfunction

  " And the commented line stuff
  function! s:uncommented_lines()
    normal! 0l
    let nnb = search('^\s*'.Comment().'.*\zs$', 'Wnc')
    let pnb = search('^\ze\s*'.Comment().'.*$', 'Wncb')
    if pnb == line('.')
      return 0
    endif
    return s:lines_helper(pnb,nnb)
  endfunction

  " Method calls
  function! s:methodcall_a()
    return s:methodcall('a')
  endfunction
  function! s:methodcall_i()
    return s:methodcall('i')
  endfunction
  function! s:methodcall(motion)
    if a:motion == 'a'
        silent! normal! [(
    endif
    silent! execute "normal! w?\\v(\\.{0,1}\\w+)+\<cr>"
    let head_pos = getpos('.')
    normal! %
    let tail_pos = getpos('.')
    if tail_pos == head_pos
        return 0
    endif
    return ['v', head_pos, tail_pos]
  endfunction

  " Chained methodcall command
  function! s:methoddef_i()
    return s:methoddef('i')
  endfunction
  function! s:methoddef_a()
    return s:methoddef('a')
  endfunction
  function! s:char_under_cursor()
      return getline('.')[col('.') - 1]
  endfunction
  function! s:methoddef(motion)
    if a:motion == 'a'
      silent! normal! [(
    endif
    silent! execute 'normal! w?\v(\.{0,1}\w+)+' . "\<cr>"
    let head = getpos('.')
    while s:char_under_cursor() == '.'
      silent! execute "normal! ?)\<cr>%"
      silent! execute 'normal! w?\v(\.{0,1}\w+)+' . "\<cr>"
      let head = getpos('.')
    endwhile
    silent! execute "normal! %"
    let tail = getpos('.')
    silent! execute 'normal! /\v(\.{0,1}\w+)+' . "\<cr>"
    while s:char_under_cursor() == '.'
      silent! execute "normal! %"
      let tail = getpos('.')
      silent! execute 'normal! /\v(\.{0,1}\w+)+' . "\<cr>"
    endwhile
    call setpos('.', tail)
    if tail == head
      return 0
    endif
    return ['v', head, tail]
  endfunction

  " Dictionary of all universal text objects
  " Highlight current line, functions, arrays, and methods. Thesse use keyword
  " chars, i.e. what is considered a 'word' by '*', 'gd/gD', et cetera
  let s:universal_textobjs_dict = {
    \   'line': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 's:current_line_a',
    \     'select-a': 'al',
    \     'select-i-function': 's:current_line_i',
    \     'select-i': 'il',
    \   },
    \   'blanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 's:blank_lines',
    \     'select-a': 'a<Space>',
    \     'select-i-function': 's:blank_lines',
    \     'select-i': 'i<Space>',
    \   },
    \   'nonblanklines': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 's:nonblank_lines',
    \     'select-a': 'ap',
    \     'select-i-function': 's:nonblank_lines',
    \     'select-i': 'ip',
    \   },
    \   'uncommented': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a-function': 's:uncommented_lines',
    \     'select-i-function': 's:uncommented_lines',
    \     'select-a': 'au',
    \     'select-i': 'iu',
    \   },
    \   'methodcall': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a': 'af', 'select-a-function': 's:methodcall_a',
    \     'select-i': 'if', 'select-i-function': 's:methodcall_i',
    \   },
    \   'methodef': {
    \     'sfile': expand('<sfile>:p'),
    \     'select-a': 'aF', 'select-a-function': 's:methoddef_a',
    \     'select-i': 'iF', 'select-i-function': 's:methoddef_i'
    \   },
    \   'function': {
    \     'pattern': ['\<\h\w*(', ')'],
    \     'select-a': 'am',
    \     'select-i': 'im',
    \   },
    \   'array': {
    \     'pattern': ['\<\h\w*\[', '\]'],
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
  " Enable
  call textobj#user#plugin('universal', s:universal_textobjs_dict)
endif

" GIT GUTTER AND FUGITIVE
" TODO: Note we had to overwrite the gitgutter autocmds with a file in 'after'.
if PlugActive('vim-gitgutter')
  " Create command for toggling on/off; old VIM versions always show signcolumn
  " if signs present (i.e. no signcolumn option), so GitGutterDisable will remove signcolumn.
  " call gitgutter#disable() | silent! set signcolumn=no
  " In newer versions, have to *also* set the signcolumn option.
  silent! set signcolumn=no " silent ignores errors if not option
  let g:gitgutter_map_keys = 0 " disable all maps yo
  let g:gitgutter_enabled = 0 " whether enabled at *startup*
  function! s:gitgutter_toggle(...)
    " Either listen to input, turn on if switch not declared, or do opposite
    if a:0
      let toggle = a:1
    else
      let toggle = (exists('b:gitgutter_enabled') ? 1-b:gitgutter_enabled : 1)
    endif
    if toggle
      GitGutterEnable
      silent! set signcolumn=yes
      let b:gitgutter_enabled = 1
    else
      GitGutterDisable
      silent! set signcolumn=no
      let b:gitgutter_enabled = 0
    endif
  endfunction
  " Maps for toggling gitgutter on and off
  nnoremap <silent> go :call <sid>gitgutter_toggle(1)<CR>
  nnoremap <silent> gO :call <sid>gitgutter_toggle(0)<CR>
  nnoremap <silent> g. :call <sid>gitgutter_toggle()<CR>
  " Maps for showing/disabling changes under cursor
  nnoremap <silent> gs :GitGutterPreviewHunk<CR>:wincmd j<CR>
  nnoremap <silent> gS :GitGutterUndoHunk<CR>
  " Navigating between hunks
  nnoremap <silent> gN :GitGutterPrevHunk<CR>
  nnoremap <silent> gn :GitGutterNextHunk<CR>
endif
" Next some fugitive command aliases
" Just want to eliminate that annoying fucking capital G
if PlugActive('vim-fugitive')
  for gcommand in ['Gcd', 'Glcd', 'Gstatus', 'Gcommit', 'Gmerge', 'Gpull',
   \ 'Grebase', 'Gpush', 'Gfetch', 'Grename', 'Gdelete', 'Gremove', 'Gblame', 'Gbrowse',
   \ 'Ggrep', 'Glgrep', 'Glog', 'Gllog', 'Gedit', 'Gsplit', 'Gvsplit', 'Gtabedit', 'Gpedit',
   \ 'Gread', 'Gwrite', 'Gwq', 'Gdiff', 'Gsdiff', 'Gvdiff', 'Gmove']
    exe 'cnoreabbrev g'.gcommand[1:].' '.gcommand
  endfor
endif

" SPELLCHECK (really is a builtin plugin, hence why it's in this section)
" Turn on for certain filetypes
augroup spell
  au!
  au FileType tex,html,markdown,rst call s:spelltoggle(1)
augroup END
" Toggle spelling on and off
function! s:spelltoggle(...)
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - &l:spell
  endif
  let &l:spell = toggle
endfunction
" Toggle between UK and US English
function! s:langtoggle(...)
  if a:0
    let uk = a:1
  else
    let uk = (&l:spelllang == 'en_gb' ? 0 : 1)
  endif
  if uk
    setlocal spelllang=en_gb
    echo 'Current language: UK english'
  else
    setlocal spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction
" Change spelling
function! s:spellchange(direc)
  let nospell = 0
  if !&l:spell
    let nospell = 1
    setlocal spell
  endif
  let winview = winsaveview()
  exe 'normal! ' . (a:direc == ']' ? 'bh' : 'el')
  exe 'normal! ' . a:direc . 's'
  normal! 1z=
  call winrestview(winview)
  if nospell
    setlocal nospell
  endif
endfunction
command! SpellToggle call s:spelltoggle(<args>)
command! LangToggle call s:langtoggle(<args>)
" Toggle on and off
nnoremap <silent> <Leader>d :call <sid>spelltoggle(1)<CR>
nnoremap <silent> <Leader>D :call <sid>spelltoggle(0)<CR>
nnoremap <silent> <Leader>l :call <sid>langtoggle(1)<CR>
nnoremap <silent> <Leader>L :call <sid>langtoggle(0)<CR>
" Add and remove from dictionary
nnoremap <Leader>a zg
nnoremap <Leader>A zug
nnoremap <Leader>! \|m z=
" Similar to ]s and [s but also correct the word!
nnoremap <buffer> <silent> <Plug>forwardspell bh]s:call <sid>spellchange(']')<CR>:call repeat#set("\<Plug>forwardspell")<CR>
nnoremap <buffer> <silent> <Plug>backwardspell el[s:call <sid>spellchange('[')<CR>:call repeat#set("\<Plug>backwardspell")<CR>
nmap ]d <Plug>forwardspell
nmap [d <Plug>backwardspell

" CODI (MATHEMATICAL NOTEPAD)
if PlugActive('codi.vim')
  " Set custom buffer-local autocommands using codi autocommands
  " We want TextChanged and InsertLeave, not TextChangedI which is enabled
  " when setting g:codi#autocmd to 'TextChanged'
  " See issue: https://github.com/metakirby5/codi.vim/issues/90
  augroup math
    au!
    au User CodiEnterPre call s:codi_enter()
    au User CodiLeavePost call s:codi_leave()
  augroup END
  function! s:codi_enter()
    let cmds = (exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave')
    exe 'augroup codi_' . bufnr('%')
      au!
      exe 'au ' . cmds . ' <buffer> call codi#update()'
    augroup END
  endfunction
  function! s:codi_leave()
    exe 'augroup codi_' . bufnr('%')
      au!
    augroup END
  endfunction
  " New window function, command, and maps
  function! s:codi_new(name)
    if a:name != ''
      exe "tabe " . fnamemodify(a:name,':r') . ".py"
      Codi!!
    endif
  endfunction
  command! -nargs=1 NewCodi call s:codi_new(<q-args>)
  nnoremap <silent> <Leader>u :exe 'NewCodi ' . input('Calculator name (' . getcwd() . '): ', '', 'file')<CR>
  nnoremap <silent> <Leader>U :Codi!!<CR>
  " Various settings, interpreter without history
  " See issue and notes: https://github.com/metakirby5/codi.vim/issues/85
  let g:codi#autocmd = 'None'
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20
  let g:codi#log = '' " enable when debugging
  let g:codi#interpreters = {
    \ 'python': {
        \ 'bin': 'python',
        \ 'prompt': '^\(>>>\|\.\.\.\) ',
        \ 'quitcmd': "import readline; readline.clear_history(); exit()",
        \ },
    \ }
endif
" Increment plugin
if PlugActive('vim-visual-increment')
  vmap + <Plug>VisualIncrement
  vmap - <Plug>VisualDecrement
  nnoremap + <C-a>
  nnoremap - <C-x>
endif
" The howmuch.vim plugin, currently with minor modifications in .vim folder
" TODO: Add maps to all other versions, maybe use = key as prefix
if hasmapto('<Plug>AutoCalcAppendWithEqAndSum', 'v')
  vmap c+ <Plug>AutoCalcAppendWithEqAndSum
endif
if hasmapto('<Plug>AutoCalcReplaceWithSum', 'v')
  vmap c= <Plug>AutoCalcReplaceWithSum
endif

" NEOCOMPLETE (RECOMMENDED SETTINGS)
if PlugActive('neocomplete.vim') "just check if activated
  " Enable omni completion for different filetypes
  augroup neocomplete
    au!
    au FileType css setlocal omnifunc=csscomplete#CompleteCSS
    au FileType html,markdown,rst setlocal omnifunc=htmlcomplete#CompleteTags
    au FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
    au FileType python setlocal omnifunc=pythoncomplete#Complete
    au FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  augroup END
  " Basic behavior
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#max_list = 10
  let g:neocomplete#enable_auto_select = 0
  let g:neocomplete#auto_completion_start_length = 1
  let g:neocomplete#sources#syntax#min_keyword_length = 2
  let g:neocomplete#enable_smart_case = 0
  let g:neocomplete#enable_camel_case = 0
  let g:neocomplete#enable_ignore_case = 0
  " Disable python omnicompletion, from the Q+A section
  if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
  endif
  let g:neocomplete#sources#omni#input_patterns.python = ''
  " Define dictionary and keyword
  if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
  endif
  let g:neocomplete#keyword_patterns['default'] = '\h\w*'
  let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : $HOME . '/.vimshell_hist',
    \ 'scheme' : $HOME . '/.gosh_completions'
    \ }
endif

" NERDCommenter (comment out stuff)
" Note the default mappings, all prefixed by <Leader> (but we disable them)
" -cc comments line or selection
" -cn forces nesting (seems to be default though; maybe sometimes, is ignored)
" -ci toggles comment state of inidivudal lines
" -c<Space> toggles comment state based on topmost line state
" -cs comments line with block-format layout
" -cy yanks lines before commenting
" -c$ comments to eol
" -cu uncomments line
if PlugActive('nerdcommenter')
  " Custom delimiter overwrites, default python includes space for some reason
  " TODO: Why can't this just use &commentstring?
  let g:NERDCustomDelimiters = {
    \ 'julia': {'left': '#', 'leftAlt': '#=', 'rightAlt': '=#'},
    \ 'python': {'left': '#'}, 'cython': {'left': '#'}, 'pyrex': {'left': '#'},
    \ 'ncl': {'left': ';'},
    \ 'smarty': {'left': '<!--', 'right': '-->'},
    \ }
  " Default settings
  let g:NERDSpaceDelims = 1            " comments have leading space
  let g:NERDCreateDefaultMappings = 0  " disable default mappings (make my own)
  let g:NERDCompactSexyComs = 1        " compact syntax for prettified multi-line comments
  let g:NERDTrimTrailingWhitespace = 1 " trailing whitespace deletion
  let g:NERDCommentEmptyLines = 1      " allow commenting and inverting empty lines (useful when commenting a region)
  let g:NERDDefaultAlign = 'left'      " align line-wise comment delimiters flush left instead of following code indentation
  let g:NERDCommentWholeLinesInVMode = 2

  " Function for toggling comment while in insert mode
  function! s:comment_insert()
    if exists('b:NERDCommenterDelims')
      let left = b:NERDCommenterDelims['left']
      let right = b:NERDCommenterDelims['right']
      let left_alt = b:NERDCommenterDelims['leftAlt']
      let right_alt = b:NERDCommenterDelims['rightAlt']
      if (left != '' && right != '')
        return (left . '  ' . right . repeat("\<Left>", len(right) + 1))
      elseif (left_alt != '' && right_alt != '')
        return (left_alt . '  ' . right_alt . repeat("\<Left>", len(right_alt) + 1))
      else
        return (left . ' ')
      endif
    else
      return ''
    endif
  endfunction
  function! s:comment_indent()
    let col = match(getline('.'), '^\s*\S\zs') " location of first non-whitespace char
    return (col == -1 ? 0 : col-1)
  endfunction

  " Next separators of arbitrary length
  function! s:bar(fill, nfill, suffix) " inserts above by default; most common use
    let cchar = Comment()
    let nspace = s:comment_indent()
    let suffix = (a:suffix ? cchar : '')
    let nfill = (a:nfill - nspace)/len(a:fill) " divide by length of fill character
    normal! k
    call append(line('.'), repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix)
    normal! jj
  endfunction
  function! s:bar_surround(fill, nfill, suffix)
    let cchar = Comment()
    let nspace = s:comment_indent()
    let suffix = (a:suffix ? cchar : '')
    let nfill = (a:nfill - nspace)/len(a:fill) " divide by length of fill character
    let lines = [
     \ repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix,
     \ repeat(' ', nspace) . cchar . ' ',
     \ repeat(' ', nspace) . cchar . repeat(a:fill, nfill) . suffix
     \ ]
    normal! k
    call append(line('.'), lines)
    normal! jj$
  endfunction

  " Separator of dashes matching current line length
  function! s:header(fill)
    let cchar = Comment()
    let nspace = s:comment_indent()
    let nfill = (match(getline('.'), '\s*$') - nspace) " location of last non-whitespace char
    call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
  endfunction
  function! s:header_surround(fill)
    let cchar = Comment()
    let nspace = s:comment_indent()
    let nfill = (match(getline('.'), '\s*$') - nspace) " location of last non-whitespace char
    call append(line('.'), repeat(' ', nspace) . repeat(a:fill, nfill))
    call append(line('.') - 1, repeat(' ', nspace) . repeat(a:fill, nfill))
  endfunction

  " Inline style of format '# ---- Hello world! ----' and '# Hello world! #'
  function! s:inline(ndash)
    let nspace = s:comment_indent()
    let cchar = Comment()
    normal! k
    call append(line('.'), repeat(' ', nspace) . cchar . repeat(' ', a:ndash) . repeat('-', a:ndash) . '  ' . repeat('-', a:ndash))
    normal! j^
    call search('- \zs', '', line('.')) " search, and stop on this line (should be same one); no flags
  endfunction
  function! s:double()
    let nspace = s:comment_indent()
    let cchar = Comment()
    normal! k
    call append(line('.'), repeat(' ', nspace) . cchar . '  ' . cchar)
    normal! j$h
  endfunction

  " Arbtirary message above this line, matching indentation level
  function! s:message(message)
    let nspace = s:comment_indent()
    let cchar = Comment()
    normal! k
    call append(line('.'), repeat(' ', nspace) . cchar . ' ' . a:message)
    normal! jj
  endfunction

  " Docstring
  function! s:docstring(char)
    let nspace = (s:comment_indent() + &l:tabstop)
    call append(line('.'), [repeat(' ', nspace) . repeat(a:char, 3), repeat(' ', nspace), repeat(' ', nspace) . repeat(a:char, 3)])
    normal! jj$
  endfunction

  " The maps
  " Use NERDCommenterMinimal commenter to use left-right delimiters, or alternatively use
  " NERDCommenterSexy commenter for better alignment
  inoremap <expr> <C-c> <sid>comment_insert()
  map c. <Plug>NERDCommenterToggle
  map co <Plug>NERDCommenterSexy
  map cO <Plug>NERDCommenterUncomment

  " Apply remaps using functions
  " Section headers and dividers
  nnoremap <silent> <Plug>bar1 :call <sid>bar('-', 77, 1)<CR>:call repeat#set("\<Plug>bar1")<CR>
  nnoremap <silent> <Plug>bar2 :call <sid>bar('-', 71, 0)<CR>:call repeat#set("\<Plug>bar2")<CR>
  nnoremap <silent> c: :call <sid>bar_surround('-', 77, 1)<CR>A
  nmap c; <Plug>bar1
  nmap c, <Plug>bar2

  " Author information, date insert, misc inserts
  nnoremap <silent> cA :call <sid>message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
  nnoremap <silent> cY :call <sid>message('Date: '.strftime('%Y-%m-%d'))<CR>
  nnoremap <silent> cC :call <sid>double()<CR>i
  nnoremap <silent> cI :call <sid>inline(5)<CR>i

  " Add ReST section levels
  nnoremap <silent> c- :call <sid>header('-')<CR>
  nnoremap <silent> c_ :call <sid>header_surround('-')<CR>
  nnoremap <silent> c= :call <sid>header('=')<CR>
  nnoremap <silent> c+ :call <sid>header_surround('=')<CR>

  " Python docstring
  nnoremap c' :call <sid>docstring("'")<CR>A
  nnoremap c" :call <sid>docstring('"')<CR>A
endif

" NERDTREE
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
    au BufEnter * if (winnr('$') == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
  augroup END
  let g:NERDTreeWinPos = "right"
  let g:NERDTreeWinSize = 20 " instead of 31 default
  let g:NERDTreeShowHidden = 1
  let g:NERDTreeMinimalUI = 1 " remove annoying ? for help note
  let g:NERDTreeMapChangeRoot = "D" "C was annoying, because VIM will wait for 'CD'
  let g:NERDTreeSortOrder = [] " use default sorting
  let g:NERDTreeIgnore = split(&wildignore, ',')
  for s:index in range(len(g:NERDTreeIgnore))
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '*.', '\\.', '')
    let g:NERDTreeIgnore[s:index] = substitute(g:NERDTreeIgnore[s:index], '$', '\$', '')
  endfor
  nnoremap <Leader>n :NERDTree %<CR>
endif

" SYNTASTIC (syntax checking for code)
if PlugActive('syntastic')
  " Next error in location list
  " Copied from: https://vi.stackexchange.com/a/14359
  function! s:cmp(a, b)
    for i in range(len(a:a))
      if a:a[i] < a:b[i]
        return -1
      elseif a:a[i] > a:b[i]
        return 1
      endif
    endfor
    return 0
  endfunction
  function! s:cfnext(count, list, ...) abort
    let reverse = a:0 && a:1
    let func = 'get' . a:list . 'list'
    let params = a:list == 'loc' ? [0] : []
    let cmd = a:list == 'loc' ? 'll' : 'cc'
    let items = call(func, params)
    if len(items) == 0
      return 'echoerr ' . string('E42: No Errors')
    endif
    " Build up list of loc dictionaries
    call map(items, 'extend(v:val, {"idx": v:key + 1})')
    if reverse
      call reverse(items)
    endif
    let [bufnr, cmp] = [bufnr('%'), reverse ? 1 : -1]
    let context = [line('.'), col('.')]
    if v:version > 800 || has('patch-8.0.1112')
      let current = call(func, extend(copy(params), [{'idx':1}])).idx
    else
      redir => capture | execute cmd | redir END
      let current = str2nr(matchstr(capture, '(\zs\d\+\ze of \d\+)'))
    endif
    call add(context, current)
    " Jump to next loc circularly
    call filter(items, 'v:val.bufnr == bufnr')
    let nbuffer = len(get(items, 0, {}))
    call filter(items, 's:cmp(context, [v:val.lnum, v:val.col, v:val.idx]) == cmp')
    let inext = get(get(items, 0, {}), 'idx', 'E553: No more items')
    if type(inext) == type(0)
      return cmd . inext
    elseif nbuffer != 0
      exe '' . (reverse ? line('$') : 0)
      return s:cfnext(a:count, a:list, reverse)
    else
      return 'echoerr' . string(inext)
    endif
  endfunction
  " Commands for circular location-list (error) scrolling
  command! -bar -count=1 Cnext execute s:cfnext(<count>, 'qf')
  command! -bar -count=1 Cprev execute s:cfnext(<count>, 'qf', 1)
  command! -bar -count=1 Lnext execute s:cfnext(<count>, 'loc')
  command! -bar -count=1 Lprev execute s:cfnext(<count>, 'loc', 1)

  " Determine checkers from annoying human-friendly output; version suitable
  " for scripting does not seem available. Weirdly need 'silent' to avoid
  " printint to vim menu. The *last* value in array will be checker.
  function! s:syntastic_checkers(...)
    redir => output
    silent SyntasticInfo
    redir END
    let result = split(output, "\n")
    let checkers = split(split(result[-2], ':')[-1], '\s\+')
    if checkers[0]=='-'
      let checkers = []
    else
      call extend(checkers, split(split(result[-1], ':')[-1], '\s\+')[:1])
    endif
    if a:0 " just echo the result
      echo 'Checkers: '.join(checkers[:-2], ', ')
    else
      return checkers
    endif
  endfunction
  command! SyntasticCheckers call s:syntastic_checkers(1)

  " Helper function
  " Need to run Syntastic with noautocmd to prevent weird conflict with tabbar,
  " but that means have to change some settings manually
  function! s:syntastic_status()
    return (exists('b:syntastic_on') && b:syntastic_on)
  endfunction
  " Run checker
  function! s:syntastic_enable()
    let nbufs = len(tabpagebuflist())
    let checkers = s:syntastic_checkers()
    if len(checkers) == 0
      echom 'No checkers available.'
    else
      SyntasticCheck
      if (len(tabpagebuflist()) > nbufs && !s:syntastic_status())
          \ || (len(tabpagebuflist()) == nbufs && s:syntastic_status())
        wincmd j | set syntax=on | call s:popup_setup()
        wincmd k | let b:syntastic_on = 1 | silent! set signcolumn=no
      else
        echom 'No errors found with checker '.checkers[-1].'.'
        let b:syntastic_on = 0
      endif
    endif
  endfunction
  " Toggle and jump between errors
  nnoremap <silent> <Leader>x :update \| call <sid>syntastic_enable()<CR>
  nnoremap <silent> <Leader>X :let b:syntastic_on = 0 \| SyntasticReset<CR>
  nnoremap <silent> ]x :Lnext<CR>
  nnoremap <silent> [x :Lprev<CR>

  " Choose syntax checkers, disable auto checking
  " flake8 pep8 pycodestyle pyflakes pylint python
  " pylint adds style checks, flake8 is pep8 plus pyflakes, pyflakes is pure syntax
  " NOTE: Need 'python' checker in addition to these other ones, because python
  " tests for import-time errors and others test for runtime errors!
  let g:syntastic_mode_map = {'mode':'passive', 'active_filetypes':[], 'passive_filetypes':[]}
  let g:syntastic_stl_format = '' "disables statusline colors; they were ugly
  let g:syntastic_always_populate_loc_list = 1 " necessary, or get errors
  let g:syntastic_auto_loc_list = 1 " creates window; if 0, does not create window
  let g:syntastic_loc_list_height = 5
  let g:syntastic_mode = 'passive' " opens little panel
  let g:syntastic_check_on_open = 0
  let g:syntastic_check_on_wq = 0
  let g:syntastic_enable_signs = 1 " disable useless signs
  let g:syntastic_enable_highlighting = 1
  let g:syntastic_auto_jump = 0 " disable jumping to errors
  let g:syntastic_tex_checkers = ['lacheck']
  let g:syntastic_python_checkers = ['python', 'pyflakes']
  let g:syntastic_fortran_checkers = ['gfortran']
  let g:syntastic_vim_checkers = ['vimlint']
  " Syntax colors
  hi SyntasticErrorLine ctermfg=White ctermbg=Red cterm=None
  hi SyntasticWarningLine ctermfg=White ctermbg=Magenta cterm=None
endif

" TABULAR - ALIGNING AROUND :,=,ETC.
" By default, :Tabularize command provided *without range* will select the
" contiguous lines that contain specified delimiter; so this function only makes
" sense when applied for a visual range! So we don't need to worry about using Tabularize's
" automatic range selection/implementing it in this special command
if PlugActive('tabular')
  " Command for tabuarizing, but ignoring lines without delimiters
  function! s:table(arg) range
    " Remove the lines without matching regexes
    let dlines = [] " note we **cannot** use dictionary, because subsequent lines without matches will overwrite each other
    let lastline = a:lastline  " no longer read-only
    let firstline = a:firstline
    let searchline = a:firstline
    let regex = split(a:arg, '/')[0] " regex is first part; other arguments are afterward
    while searchline <= lastline
      if getline(searchline) !~# regex " if return value is zero, delete this line
        call add(dlines, [searchline, getline(searchline)])
        let lastline -= 1 " after deletion, the 'last line' of selection has changed
        exe searchline . 'd'
      else " leave it alone, increment search
        let searchline += 1
      endif
    endwhile
    " Execute tabularize function
    if firstline > lastline
      echohl WarningMsg
      echom 'Warning: No matches in selection.'
      echohl None
    else
      exe firstline.','.lastline.'Tabularize '.a:arg
    endif
    " Add back the lines that were deleted
    for pair in reverse(dlines) " insert line of text below where deletion occurred (line '0' adds to first line)
      call append(pair[0]-1, pair[1])
    endfor
  endfunction
  " Command
  " * Note odd concept (see :help args) that -nargs=1 will pass subsequent text, including
  "   whitespace, as single argument, but -nargs=*, et cetera, will aceept multiple arguments delimited by whitespace
  " * Be careful -- make sure to pass <args> in singly quoted string!
  command! -range -nargs=1 Table <line1>,<line2>call s:table(<q-args>)
  " Align arbitrary character, and suppress error message if user Ctrl-c's out of input line
  nnoremap <silent> <expr> \<Space> ':silent! Tabularize /' . input('Alignment regex: ') . '/l1c1<CR>'
  vnoremap <silent> <expr> \<Space> "<Esc>:silent! '<,'>Table /" . input('Alignment regex: ') . '/l1c1<CR>'
  " By commas, suitable for diag_table; does not ignore comment characters
  nnoremap <expr> \, ':Tabularize /,\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \, ':Table      /,\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  " Dictionary, colon on left
  nnoremap <expr> \d ':Tabularize /:\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \d ':Table      /:\(' . RegexComment() . '.*\)\@<!\zs/l0c1<CR>'
  " Dictionary, colon on right
  nnoremap <expr> \D ':Tabularize /\(' . RegexComment() . '.*\)\@<!\zs:/l0c1<CR>'
  vnoremap <expr> \D ':Table      /\(' . RegexComment() . '.*\)\@<!\zs:/l0c1<CR>'
  " Right-align by spaces, considering comments as one 'field'; other words are
  " aligned by space; very hard to ignore comment-only lines here, because we specify text
  " before the first 'field' (i.e. the entirety of non-matching lines) will get right-aligned
  nnoremap <expr> \r ':Tabularize /^\s*[^\t ' . RegexComment() . ']\+\zs\ /r0l0l0<CR>'
  vnoremap <expr> \r ':Table      /^\s*[^\t ' . RegexComment() . ']\+\zs\ /r0l0l0<CR>'
  " As above, but left align
  " See :help non-greedy to see what braces do; it is like *, except instead of matching
  " as many as possible, can match as few as possible in some range;
  " with braces, a minus will mean non-greedy
  nnoremap <expr> \l ':Tabularize /^\s*\S\{-1,}\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'
  vnoremap <expr> \l ':Table      /^\s*\S\{-1,}\(' . RegexComment() . '.*\)\@<!\zs\s/l0<CR>'
  " Just align by spaces
  " Check out documentation on \@<! atom; difference between that and \@! is that \@<!
  " checks whether something doesn't match *anywhere before* what follows
  " Also the \S has to come before the \(\) atom instead of after for some reason
  nnoremap <expr> \\ ':Tabularize /\S\(' . RegexComment() . '.*\)\@<!\zs\ /l0<CR>'
  vnoremap <expr> \\ ':Table      /\S\(' . RegexComment() . '.*\)\@<!\zs\ /l0<CR>'
  " Tables separted by | chars
  nnoremap <expr> \\| ':Tabularize /\|/l1c1<CR>'
  vnoremap <expr> \\| ':Table      /\|/l1c1<CR>'
  " Chained && statements, common in bash
  " Again param expansions are common so don't bother with comment detection this time
  nnoremap <expr> \& ':Tabularize /&&/l1c1<CR>'
  vnoremap <expr> \& ':Table      /&&/l1c1<CR>'
  " Case/esac blocks
  " The bottom pair don't align the double semicolons; just any comments that come after
  " Note the extra 1 is necessary to add space before comment characters
  " That regex following the RegexComment() is so tabularize will ignore the common
  " parameter expansions ${param#*pattern} and ${param##*pattern}
  " Common for this to come up: e.g. -x=*) x=${1#*=}
  " asdfda*|asd*) asdfjioajoidfjaosi"* ;; "comment 1S asdfjio *asdfjio*
  " a|asdfsa) asdjiofjoi""* ;; "coiasdfojiadfj asd asd asdf
  " asdf) asdjijoiasdfjoi ;;
  nnoremap <expr> \) ':Tabularize /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|\zs;;\)/l1l0l1<CR>'
  vnoremap <expr> \) ':Table      /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|\zs;;\)/l1l0l1<CR>'
  nnoremap <expr> \( ':Tabularize /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|;;\zs\)/l1l0l0<CR>'
  vnoremap <expr> \( ':Table      /\(' . RegexComment() . '[^*' . RegexComment() . '].*\)\@<!\(\S\+)\zs\\|;;\zs\)/l1l0l0<CR>'
  " By comment character; ^ is start of line, . is any char, .* is any number, \zs
  " is start match here (must escape backslash), then search for the comment
  " nnoremap <expr> \C ':Tabularize /^.*\zs' . RegexComment() . '/l1<CR>'
  " vnoremap <expr> \C ':Table      /^.*\zs' . RegexComment() . '/l1<CR>'
  " By comment character, but ignore comment-only lines
  nnoremap <expr> \C ':Tabularize /^\s*[^ \t' . RegexComment() . '].*\zs' . RegexComment() . '/l1<CR>'
  vnoremap <expr> \C ':Table      /^\s*[^ \t' . RegexComment() . '].*\zs' . RegexComment() . '/l1<CR>'
  " Align by the first equals sign either keeping it to the left or not
  " The eaiser to type one (-=) puts equals signs in one column
  " This selects the *first* uncommented equals sign that does not belong to
  " a logical operator or incrementer <=, >=, ==, %=, -=, +=, /=, *= (have to escape dash in square brackets)
  nnoremap <expr> \= ':Tabularize /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  vnoremap <expr> \= ':Table      /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  nnoremap <expr> \+ ':Tabularize /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
  vnoremap <expr> \+ ':Table      /^[^' . RegexComment() . ']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
endif

" CTAGS and TAGBAR (requires 'brew install ctags-exuberant')
" Mappings for vim-idetools command
if PlugActive('vim-idetools') || &rtp =~ 'vim-idetools'
  nnoremap <silent> <Leader>C :DisplayTags<CR>:redraw!<CR>
endif
" Next tagbar settings; note some mappings:
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
  let g:tagbar_map_openfold = "="
  let g:tagbar_map_closefold = "-"
  let g:tagbar_map_closeallfolds = "_"
  let g:tagbar_map_openallfolds = "+"
  " Open TagBar, make sure NerdTREE is flushed to right
  function! s:tagbar_setup()
    if &ft=="nerdtree"
      wincmd h
      wincmd h " move two places in case e.g. have help menu + nerdtree already
    endif
    let tabfts = map(tabpagebuflist(),'getbufvar(v:val, "&ft")')
    if In(tabfts,'tagbar')
      TagbarClose
    else
      TagbarOpen
      if In(tabfts,'nerdtree')
        wincmd l
        wincmd L
        wincmd p
      endif
    endif
  endfunction
  nnoremap <silent> <Leader>t :call <sid>tagbar_setup()<CR>
endif

" REFRESH FILE
" If you want to refresh some random global plugin in ~/.vim/autolaod or ~/.vim/plugin
" then just source it with the 'execute' shortcut Ctrl-z
function! s:refresh() " refresh sesssion, sometimes ~/.vimrc settings are overridden by ftplugin stuff
  filetype detect " if started with empty file, but now shebang makes filetype clear
  filetype plugin indent on
  let loaded = []
  let files = [
    \ '~/.vim/ftplugin/' . &ft . '.vim',
    \ '~/.vim/syntax/' . &ft . '.vim',
    \ '~/.vim/after/ftplugin/' . &ft . '.vim',
    \ '~/.vim/after/syntax/' . &ft . '.vim']
  for file in files
    if !empty(glob(file))
      exe 'so '.file
      call add(loaded, file)
    endif
  endfor
  echom "Loaded ".join(map(['~/.vimrc'] + loaded, 'fnamemodify(v:val, ":~")[2:]'), ', ').'.'
endfunction
command! Refresh so ~/.vimrc | call s:refresh()
" Refresh command, load from disk, redraw screen
nnoremap <silent> <Leader>s :Refresh<CR>
nnoremap <silent> <Leader>r :e<CR>
nnoremap <silent> <Leader>R :redraw!<CR>

" SESSION MANAGEMENT
" First, simple obsession session management
" * Jump to mark '"' without changing the jumplist (:help g`)
" * Mark '"' is the cursor position when last exiting the current buffer
if PlugActive('vim-obsession') "must manually preserve cursor position
  augroup session
    au!
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
    au VimEnter * Obsession .vimsession
  augroup END
endif
nnoremap <silent> <Leader>v :Obsession .vimsession<CR>:echom 'Manually refreshed .vimsession.'<CR>
" Manual autosave behavior
" Consider disabling
function! s:autosave_toggle(...)
  " Parse input
  if !exists('b:autosave_on')
    let b:autosave_on = 0
  endif
  if a:0
    let toggle = a:1
  else
    let toggle = 1 - b:autosave_on
  endif
  if toggle == b:autosave_on
    return
  endif
  " Toggle autocommands local to buffer as with codi
  " We use augroups with buffer-specific names to prevent conflict
  if toggle
    let cmds = (exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave')
    exe 'augroup autosave_' . bufnr('%')
      au! *
      exe 'au ' . cmds . ' <buffer> silent w'
    augroup END
    echom 'Autosave enabled.'
    let b:autosave_on = 1
  else
    exe 'augroup autosave_' . bufnr('%')
      au! *
    augroup END
    echom 'Autosave disabled.'
    let b:autosave_on = 0
  endif
endfunction
command! -nargs=? Autosave call s:autosave_toggle(<args>)
nnoremap <Leader>S :Autosave<CR>
" Vim workspace settings
" Had issues with this! Do not remember what though
if PlugActive('vim-workspace') "cursor positions automatically saved
  let g:workspace_session_name = '.vimsession'
  let g:workspace_session_disable_on_args = 1 " enter vim (without args) to load previous sessions
  let g:workspace_persist_undo_history = 0    " don't need to save undo history
  let g:workspace_autosave_untrailspaces = 0  " sometimes we WANT trailing spaces!
  let g:workspace_autosave_ignore = ['help', 'qf', 'diff', 'man']
endif
" Vimtex settings
" Turn off annoying warning; see: https://github.com/lervag/vimtex/issues/507
" See here for viewer configuration: https://github.com/lervag/vimtex/issues/175
if PlugActive('vimtex')
  let g:vimtex_compiler_latexmk = {'callback' : 0}
  let g:vimtex_mappings_enable = 0
  let g:vimtex_view_view_method = 'skim'
  let g:vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
  let g:vimtex_view_general_options = '-r @line @pdf @tex'
  let g:vimtex_fold_enabled = 0 " So large files can open more easily
endif

"-----------------------------------------------------------------------------"
" GENERAL STUFF, BASIC REMAPS
"-----------------------------------------------------------------------------"
" BUFFER QUITTING/SAVING
" Helper functions
" NOTE: Update only writes if file has been changed
function! s:vim_close()
  qa
  " tabdo windo
  "   \ if &ft == 'log' | q! | else | q | endif
endfunction
function! s:tab_close()
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') - tabpagenr())
  if ntabs == 1
    qa
  else
    tabclose
    if !islast
      silent! tabp
    endif
  endif
endfunction
function! s:window_close()
  let ntabs = tabpagenr('$')
  let islast = (tabpagenr('$') == tabpagenr())
  q
  if ntabs != tabpagenr('$') && !islast
    silent! tabp
  endif
endfunction
" Save and quit, also test whether the :q action closed the entire tab
nnoremap <silent> <C-s> :update<CR>
nnoremap <silent> <C-a> :call <sid>vim_close()<CR>
nnoremap <silent> <C-w> :call <sid>window_close()<CR>
nnoremap <silent> <C-q> :call <sid>tab_close()<CR>
" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" WARNING: Do not map escape or cannot send iTerm-shortcuts with escape codes!
" NOTE: Must change local directory to have term pop up in this dir: https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>T :silent! lcd %:p:h<CR>:terminal<CR>

" OPENING FILES
" Function that generates list of files in directory
function! s:fzfopen_files(path)
  let folder = substitute(fnamemodify(a:path, ':p'), '/$', '', '') " absolute path
  let files = split(glob(folder . '/*'), '\n') + split(glob(folder . '/.?*'),'\n') " the ? ignores the current directory '.'
  let files = map(files, '"' . fnamemodify(folder, ':t') . '/" . fnamemodify(v:val, ":t")')
  call insert(files, '[new file]', 0) " highest priority
  return files
endfunction
" Function that checks if user FZF selection is directory and keeps opening
" FZF windows until user selects a file.
function! s:fzfopen_run(path)
  if a:path == ''
    let path = '.'
  else
    let path = a:path
  endif
  let path = substitute(fnamemodify(path, ':p'), '/$', '', '')
  let path_orig = path
  while isdirectory(path)
    let pprev = path
    let items = fzf#run({'source':s:fzfopen_files(path), 'options':'--no-sort', 'down':'~30%'})
    " User cancelled or entered invalid string
    if !len(items) " length of list
      let path = ''
      break
    endif
    " Build back selection into path
    let item = items[0]
    if item == '[new file]'
      let item = input('Enter new filename (' . path . '): ', '', 'customlist,NullList')
      if item == ''
        let path = ''
      else
        let path = path . '/' . item
      endif
      break
    else
      let tail = fnamemodify(item, ':t')
      if tail == '..' " fnamemodify :p does not expand the previous direcotry sign, so must do this instead
        let path = fnamemodify(path, ':h') " head of current directory
      else
        let path = path . '/' . tail
      endif
    endif
  endwhile
  " Open file or cancel operation
  if path != ''
    exe 'tabe ' . path
  endif
  return
endfunction
" Note q-args evaluates to empty string if 'no args' were passed!
command! -nargs=? -complete=file Open call s:fzfopen_run(<q-args>)
" Maps for opening file in current directory, and opening file in some input directory
nnoremap <silent> <F3> :exe 'Open '.expand('%:h')<CR>
nnoremap <C-o> :Open 
nnoremap <silent> <C-p> :Files<CR>

" TABS and WINDOWS
augroup tabs
  au!
  au TabLeave * let g:lasttab = tabpagenr()
augroup END
" Disable default tab changing
noremap gt <Nop>
noremap gT <Nop>
" Move current tab to the exact place of tab number N
function! s:tab_move(n)
  if a:n == tabpagenr() || a:n == 0 || a:n == ''
    return
  elseif a:n > tabpagenr() && version[0] > 7
    echo 'Moving tab...'
    execute 'tabmove '.a:n
  else
    echo 'Moving tab...'
    execute 'tabmove '.eval(a:n-1)
  endif
endfunction
" Function that generates lists of tabs and their numbers
function! s:tab_select()
  if !exists('g:tabline_bufignore')
    let g:tabline_bufignore = ['qf', 'vim-plug', 'help', 'diff', 'man', 'fugitive', 'nerdtree', 'tagbar', 'codi'] " filetypes considered 'helpers'
  endif
  let items = []
  for i in range(tabpagenr('$')) " iterate through each tab
    let tabnr = i+1 " the tab number
    let buflist = tabpagebuflist(tabnr)
    for b in buflist " get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
      if !In(g:tabline_bufignore, getbufvar(b, "&ft"))
        let bufnr = b " we choose this as our 'primary' file for tab title
        break
      elseif b==buflist[-1] " occurs if e.g. entire tab is a help window; exception, and indeed use it for tab title
        let bufnr = b
      endif
    endfor
    if tabnr == tabpagenr()
      continue
    endif
    let items += [tabnr.': '.fnamemodify(bufname(bufnr),'%:t')] " actual name
  endfor
  return items
endfunction
" Function that jumps to the tab number from a line generated by tabselect
function! s:tabjump(item)
  exe 'normal! '.split(a:item,':')[0].'gt'
endfunction
" Function mappings
nnoremap <silent> <Tab><Tab> :call fzf#run({'source':<sid>tab_select(), 'options':'--no-sort', 'sink':function('<sid>tabjump'), 'down':'~50%'})<CR>
nnoremap <silent> <Tab>m :call <sid>tab_move(input('Move tab: ', '', 'customlist,NullList'))<CR>
nnoremap <silent> <Tab>> :call <sid>tab_move(eval(tabpagenr()+1))<CR>
nnoremap <silent> <Tab>< :call <sid>tab_move(eval(tabpagenr()-1))<CR>
" Add new tab changing
nnoremap <Tab>1 1gt
nnoremap <Tab>2 2gt
nnoremap <Tab>3 3gt
nnoremap <Tab>4 4gt
nnoremap <Tab>5 5gt
nnoremap <Tab>6 6gt
nnoremap <Tab>7 7gt
nnoremap <Tab>8 8gt
nnoremap <Tab>9 9gt
" Scroll tabs left-right
nnoremap <Tab>, gT
nnoremap <Tab>. gt
" Switch to previous tab
if !exists('g:lasttab') | let g:lasttab = 1 | endif
nnoremap <silent> <Tab>' :execute "tabn ".g:lasttab<CR>
" Switch to previous window
nnoremap <Tab>; <C-w><C-p>
" Open in split window
" TODO: Support with <C-o>
nnoremap <Tab>- :split 
nnoremap <Tab>\ :vsplit 
" Center the cursor in window
" nnoremap <Tab>0 M
nnoremap <Tab>0 mzz.`z
" Moving screen up/down, left/right
nnoremap <Tab>i zt
nnoremap <Tab>o zb
nnoremap <Tab>u zH
nnoremap <Tab>p zL
" Window selection
nnoremap <Tab>j <C-w>j
nnoremap <Tab>k <C-w>k
nnoremap <Tab>h <C-w>h
nnoremap <Tab>l <C-w>l
" Maps for resizing windows
nnoremap <silent> <Tab>= :vertical resize 80<CR>
nnoremap <expr> <silent> <Tab>( '<Esc>:resize '.(winheight(0)-3*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>) '<Esc>:resize '.(winheight(0)+3*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>_ '<Esc>:resize '.(winheight(0)-5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>+ '<Esc>:resize '.(winheight(0)+5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>[ '<Esc>:vertical resize '.(winwidth(0)-5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>] '<Esc>:vertical resize '.(winwidth(0)+5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>{ '<Esc>:vertical resize '.(winwidth(0)-10*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>} '<Esc>:vertical resize '.(winwidth(0)+10*max([1,v:count])).'<CR>'

" SIMPLE WINDOW SETTINGS
" Enable quitting windows with simple 'q' press and disable line numbers
augroup simple
  au!
  au BufEnter * let b:recording = 0
  au FileType qf,log,diff,man,fugitive,gitcommit,vim-plug call s:popup_setup()
  au FileType help call s:help_setup()
  au CmdwinEnter * call s:cmdwin_setup()
  au CmdwinLeave * setlocal laststatus=2
augroup END
" For popup windows
" For location lists, enter jumps to location. Restore this behavior.
function! s:popup_setup()
  nnoremap <silent> <buffer> <CR> <CR>
  nnoremap <silent> <buffer> <C-w> :q!<CR>
  nnoremap <silent> <buffer> q :q!<CR>
  setlocal nolist nonumber norelativenumber nospell nocursorline colorcolumn= buftype=nofile
  if len(tabpagebuflist()) == 1 | q | endif " exit if only one left
endfunction
" For help windows
function! s:help_setup()
  call s:popup_setup()
  wincmd L " moves current window to be at far-right (wincmd executes Ctrl+W maps)
  vertical resize 80 " always certain size
  nnoremap <buffer> <CR> <C-]>
  if g:has_nowait
    nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
    nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
  else
    nnoremap <nowait> <buffer> <silent> [[ :<C-u>pop<CR>
    nnoremap <nowait> <buffer> <silent> ]] :<C-u>tag<CR>
  endif
endfunction
" For command windows, make sure local maps work
function! s:cmdwin_setup()
  silent! unmap <CR>
  silent! unmap <C-c>
  nnoremap <buffer> <silent> q :q<CR>
  nnoremap <buffer> <C-z> <C-c><CR>
  inoremap <buffer> <C-z> <C-c><CR>
  inoremap <buffer> <expr> <CR> ""
  setlocal nonumber norelativenumber nolist laststatus=0
endfunction
" Vim command windows
nnoremap <Leader>: q:
nnoremap <Leader>/ q/
nnoremap <Leader>? q?
" Vim help windows
nnoremap <Leader>h :vert help 
nnoremap <Leader>H :Help<CR>
" Man pages
nnoremap <silent> <expr> <Leader>M ':!clear; search=' . input('Get man info: ', '', 'customlist,NullList') . '; '
  \.'if [ -n $search ] && command man $search &>/dev/null; then command man $search; fi<CR>:redraw!<CR>'
" Result of 'cmd --help', pipe output into less for better interaction
nnoremap <silent> <expr> <Leader>m ':!clear; search=' . input('Get help info: ', '', 'customlist,NullList') . '; '
  \.'if [ -n $search ] && builtin help $search &>/dev/null; then builtin help $search 2>&1 \| less; '
  \.'elif $search --help &>/dev/null; then $search --help 2>&1 \| less; fi<CR>:redraw!<CR>'

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
noremap <silent> \w :s/\s\+$//g \| noh<CR>:echom "Trimmed trailing whitespace."<CR>
noremap <silent> \W :s/\(\S\)\@<=\(^ \+\)\@<! \{2,}/ /g \| noh<CR>:echom "Squeezed consecutive spaces."<CR>
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
" The autocmd is confusing, but better than an autocmd that lmaps and lunmaps;
" that would cancel command-line queries (or I'd have to scroll up to resume them)
" don't think any other mapping type has anything like lmap; iminsert is unique
" yay insert mode WITH CAPS LOCK how cool is that THAT THAT!
augroup capslock
  au!
  au InsertLeave,CmdWinLeave * set iminsert=0
augroup END
" lmap == insert mode, command line (:), and regexp searches (/)
" See <http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock>; instead uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1 via
" <C-^> (not avilable for custom remap, since ^ is not alphabetical)
set iminsert=0
for s:c in range(char2nr('A'), char2nr('Z'))
  exe 'lnoremap ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
  exe 'lnoremap ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
endfor
" Caps lock toggle, uses iTerm mapping of impossible key combination to the
" F5 keypress. See top of file.
inoremap <F5> <C-^>
cnoremap <F5> <C-^>

" COPY MODE
" Eliminates special chars during copy
function! s:copy_toggle(...)
  if a:0
    let toggle = a:1
  else
    let toggle = !exists("b:number")
  endif
  let copyprops = ["number", "list", "relativenumber", "scrolloff"]
  if toggle
    for prop in copyprops
      if !exists("b:" . prop) "do not overwrite previously saved settings
        exe "let b:" . prop . " = &l:" . prop
      endif
      exe "let &l:" . prop . " = 0"
    endfor
    echo "Copy mode enabled."
  else
    for prop in copyprops
      exe "silent! let &l:" . prop . " = b:" . prop
      exe "silent! unlet b:" . prop
    endfor
    echo "Copy mode disabled."
  endif
endfunction
command! -nargs=? CopyToggle call s:copy_toggle(<args>)
nnoremap <Leader>c :call <sid>copy_toggle()<CR>

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
nnoremap <Leader>F <c-w>gf
nnoremap <expr> <Leader>f ":if len(glob('<cfile>'))>0 \| echom 'File(s) exist.' "
  \ . "\| else \| echom 'File \"'.expand('<cfile>').'\" does not exist.' \| endif<CR>"
" Now remap indentation commands. Why is this here? Just go with it.
" * Meant to mimick visual-mode > and < behavior.
" * Note the <Esc> is needed first because it cancels application of the number operator
"   to what follows; we want to use that number operator for our own purposes
if g:has_nowait
  nnoremap <expr> <nowait> > (v:count) > 1 ? '<Esc>'.repeat('>>',v:count) : '>>'
  nnoremap <expr> <nowait> < (v:count) > 1 ? '<Esc>'.repeat('<<',v:count) : '<<'
  nnoremap <nowait> = ==
else
  nnoremap <expr> >> v:count ? '<Esc>'.repeat('>>',v:count) : '>>'
  nnoremap <expr> << v:count ? '<Esc>'.repeat('<<',v:count) : '<<'
endif
" SimpylFold settings
let g:SimpylFold_docstring_preview = 1
let g:SimpylFold_fold_import = 0
let g:SimpylFold_fold_imports = 0
let g:SimpylFold_fold_docstring = 0
let g:SimpylFold_fold_docstrings = 0
" Delete, open, close all folds, to open/close under cursor use zo/zc
nnoremap zD zE
nnoremap zO zR
nnoremap zC zM

" SPECIAL SYNTAX HIGHLIGHTING OVERWRITES
" * See this thread (https://vi.stackexchange.com/q/9433/8084) on modifying syntax
"   for every file; we add our own custom highlighting for vim comments
" * For adding keywords, see: https://vi.stackexchange.com/a/11547/8084
" * Will also enforce shebang always has the same color, because it's annoying otherwise
" * And generally only want 'conceal' characters invisible for latex; otherwise we
"   probably want them to look like comment characters
" * The url regex was copied from the one used for .tmux.conf
" First coloring for ***GUI Vim versions***
" See: https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
if has('gui_running')
  " Declare colorscheme
  " gruvbox, kolor, dracula, onedark, molokai, yowish, tomorrow-night
  " atom, chlordane, papercolor, solarized, fahrenheit, slate, oceanicnext
  colorscheme oceanicnext
  " Bugfixes
  hi! link vimCommand Statement
  hi! link vimNotFunc Statement
  hi! link vimFuncKey Statement
  hi! link vimMap     Statement
endif

" Next coloring for **Terminal VIM versions***
" Have to use cTerm colors, and control the ANSI colors from your terminal settings
" WARNING: Cannot use filetype-specific elgl au Syntax *.tex commands to overwrite
" existing highlighting. An after/syntax/tex.vim file is necessary.
" WARNING: The containedin just tries to *guess* what particular comment and
" string group names are for given filetype syntax schemes. Verify that the
" regexes will match using :Group with cursor over a comment. For example, had
" to change .*Comment to .*Comment.* since Julia has CommentL name
augroup syn
  au!
  au Syntax  * call s:keywordsetup()
  au BufRead * set conceallevel=2 concealcursor=
  au InsertEnter * highlight StatusLine ctermbg=Black ctermbg=White ctermfg=Black cterm=NONE
  au InsertLeave * highlight StatusLine ctermbg=White ctermbg=Black ctermfg=White cterm=NONE
augroup END
" Keywords
function! s:keywordsetup()
   syn match customURL =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^'  <>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
   hi link customURL Underlined
   if &ft!="vim"
     syn match Todo '\<\%(WARNING\|ERROR\|FIXME\|TODO\|NOTE\|XXX\)\ze:\=\>' containedin=.*Comment.* " comments
     syn match Special '^\%1l#!.*$' " shebangs
   else
     syn clear vimTodo " vim instead uses the Stuff: syntax
   endif
endfunction
" Python syntax
highlight link pythonImportedObject Identifier
" HTML syntax
" highlight link htmlNoSpell
" Popup menu
highlight Pmenu     ctermbg=NONE    ctermfg=White cterm=NONE
highlight PmenuSel  ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE    ctermfg=Black cterm=NONE
" Status line
highlight StatusLine ctermbg=Black ctermfg=White cterm=NONE
" Create dummy group -- will be transparent, but use to add @Nospell
highlight Dummy ctermbg=NONE ctermfg=NONE
" Magenta is uncommon color, so change this
" Note if Sneak undefined, this won't raise error; vim thinkgs maybe we will define it later
highlight Sneak  ctermbg=DarkMagenta ctermfg=NONE
" And search/highlight stuff; by default foreground is black, make it transparent
highlight Search ctermbg=Magenta     ctermfg=NONE
" Fundamental changes, move control from LightColor to Color and DarkColor, because
" ANSI has no control over light ones it seems.
" Generally 'Light' is NormalColor and 'Normal' is DarkColor
highlight Type        ctermbg=NONE ctermfg=DarkGreen
highlight Constant    ctermbg=NONE ctermfg=Red
highlight Special     ctermbg=NONE ctermfg=DarkRed
highlight PreProc     ctermbg=NONE ctermfg=DarkCyan
highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold
" Make Conceal highlighting group ***transparent***, so that when you
" set the conceallevel to 0, concealed elements revert to their original highlighting.
highlight Conceal    ctermbg=NONE  ctermfg=NONE ctermbg=NONE  ctermfg=NONE
" Features that only work in iTerm with minimum contrast setting
" Disable by using 'Gray' highlighting
" highlight LineNR       cterm=NONE ctermbg=NONE ctermfg=Gray
" highlight Comment    ctermfg=Gray cterm=NONE
highlight LineNR       cterm=NONE ctermbg=NONE ctermfg=Black
highlight Comment    ctermfg=Black cterm=NONE
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
" Column stuff; color 80th column, and after 120
highlight ColorColumn  cterm=NONE ctermbg=Gray
highlight SignColumn  guibg=NONE cterm=NONE ctermfg=Black ctermbg=NONE
" Make sure terminal background is same as main background,
" for versions with :terminal command
highlight Terminal ctermbg=NONE ctermfg=NONE

" USEFUL COMMANDS
" Highlight group under cursor
function! s:group()
  echo ""
   \ . "actual <" . synIDattr(synID(line("."), col("."), 1), "name") . "> "
   \ . "appears <" . synIDattr(synID(line("."), col("."), 0), "name") . "> "
   \ . "group <" . synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") . ">"
endfunction
command! Group call s:group()
" The :syntax commands within that group
function! s:syntax(name)
  if a:name
    exe "verb syntax list " . a:name
  else
    exe "verb syntax list " . synIDattr(synID(line("."), col("."), 0), "name")
  endif
endfunction
command! -nargs=? Syntax call s:syntax(<q-args>)
" Get current plugin file
" Remember :scriptnames lists all loaded files
function! s:ftplugin()
  execute 'split $VIMRUNTIME/ftplugin/'.&ft.'.vim'
  silent call s:popup_setup()
endfunction
function! s:ftsyntax()
  execute 'split $VIMRUNTIME/syntax/'.&ft.'.vim'
  silent call s:popup_setup()
endfunction
command! PluginFile call s:ftplugin()
command! SyntaxFile call s:ftsyntax()
" Map to wraptoggle
nnoremap <silent> <Leader>w :WrapToggle<CR>
" Window displaying all colors
function! s:colors()
  source $VIMRUNTIME/syntax/colortest.vim
  silent call s:popup_setup()
endfunction
command! Colors call s:colors()
command! GroupColors vert help group-name

"-----------------------------------------------------------------------------"
" EXIT
"-----------------------------------------------------------------------------"
" Clear past jumps
" Don't want stuff from plugin files and the vimrc populating jumplist after statrup
" Simple way would be to use au BufRead * clearjumps
" But older versions of VIM have no 'clearjumps' command, so this is a hack
" see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clearjumps
  au!
  if exists(":clearjumps") | au BufRead * clearjumps "see help info on exists()
  else | au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  endif
augroup END
" Clear writeable registers
" On some vim versions [] fails (is ideal, because removes from :registers), but '' will at least empty them out
" See thread: https://stackoverflow.com/questions/19430200/how-to-clear-vim-registers-effectively
" WARNING: On cheyenne, get lalloc error when calling WipeReg, strange
if $HOSTNAME !~ 'cheyenne'
  command! WipeReg for i in range(34,122) | silent! call setreg(nr2char(i), '') | silent! call setreg(nr2char(i), []) | endfor
  WipeReg
endif
noh " turn off highlighting at startup
redraw! " weird issue sometimes where statusbar disappears
