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
for s:pair in [
  \ ['n', '<Leader>'], ['n', '<Tab>'], ['n', '\'], ['i', '<C-s>'], ['i', '<C-z>'], ['i', '<C-b>']
  \ ]
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

" VIM-PLUG PLUGINS
" Don't load some plugins if not compatible
" Note: Plugin settings are defined in .vim/plugin/plugins.vim
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
