"-----------------------------------------------------------------------------"
" vint: -ProhibitSetNoCompatible
" A fancy vimrc that does all sorts of magical things.
" Note: Have iTerm map some ctrl+key combinations that would otherwise
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
" Also we use 'x' for insert-related marks, 'y' for visual-related marks, and 'z'
" for normal-related marks in various complex maps.
" 'z' marks in various complicated remaps.
" Note when installing with anaconda, you may need to run
" conda install -y conda-forge::ncurses first
"-----------------------------------------------------------------------------"
" Critical stuff
let &t_Co=256
let s:textwidth = 88
exe 'runtime autoload/repeat.vim'
if !exists('*repeat#set')
  echohl WarningMsg
  echom 'Warning: vim-repeat unavailable, some features will be unavailable.'
  echohl None
endif

" Global settings
set nocompatible  " always use the vim defaults
set encoding=utf-8
scriptencoding utf-8
let mapleader = "\<Space>"
let &g:colorcolumn = has('gui_running') ? '0' : '89,120'
set autoindent  " indents new lines
set background=dark  " standardize colors -- need to make sure background set to dark, and should be good to go
set backspace=indent,eol,start  " backspace by indent - handy
set complete+=k  " enable dictionary search through 'dictionary' setting
set completeopt-=preview  " no popup window, for now
set confirm  " require confirmation if you try to quit
set cursorline
set diffopt=vertical,foldcolumn:0,context:5
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " make sure enabled, allows keycodes
set foldlevel=99
set foldlevelstart=99
set foldmethod=expr  " fold methods
set foldnestmax=10  " avoids weird things
set foldopen=tag,mark  " options for opening folds on cursor movement; disallow block
set history=100  " search history
set hlsearch incsearch  " show match as typed so far, and highlight as you go
set lazyredraw
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set matchpairs=(:),{:},[:]  " exclude <> by default for use in comparison operators
set maxmempattern=50000  " from 1000 to 10000
set nobackup noswapfile noundofile  " no more swap files; constantly hitting C-s so it's safe
set noerrorbells visualbell t_vb=  " enable internal bell, t_vb= means nothing is shown on the window
set noinfercase ignorecase smartcase  " smartcase makes search case insensitive, unless has capital letter
set nospell spelllang=en_us spellcapcheck=  " spellcheck off by default
set nostartofline  " when switching buffers, doesn't move to start of line (weird default)
set notimeout timeoutlen=0  " wait forever when doing multi-key *mappings*
set nrformats=alpha  " never interpret numbers as 'octal'
set number numberwidth=4  " note old versions can't combine number with relativenumber
set redrawtime=5000  " sometimes takes a long time, let it happen
set relativenumber
set scrolloff=4
set selectmode=  " disable 'select mode' slm, allow only visual mode for that stuff
set shell=/usr/bin/env\ bash
set shiftround  " round to multiple of shift width
set shiftwidth=2
set shortmess=atqcT  " snappy messages; 'a' does a bunch of common stuff
set showtabline=2
set softtabstop=2
set splitbelow
set splitright  " splitting behavior
set tabpagemax=100  " allow opening shit load of tabs at once
set tabstop=2  " shoft default tabs
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set updatetime=1000  " used for CursorHold autocmds
set viminfo='100,:100,<100,@100,s10,f0  " commands, marks (e.g. jump history), exclude registers >10kB of text
set virtualedit=  " prevent cursor from going where no actual character
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu
set wildmode=longest:list,full
let &g:breakat = ' 	!*-+;:,./?'  " break at single instances of several characters
let &g:wildignore =
  \ '*.pdf,*.doc,*.docs,*.page,*.pages,'
  \ . '*.svg,*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.o,*.mod,*.pyc,'
  \ . '*.mp3,*.m4a,*.mk4,*.mp4,*.mov,*.flac,*.wav,'
  \ . '*.nc,*.zip,*.dmg,*.sw[a-z],*.DS_Store,'
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

" Always override these settings, even buffer-local settings
let g:set_overrides = 'linebreak nojoinspaces wrapmargin=0 formatoptions=lrojcq textwidth=' . s:textwidth
augroup override_settings
  au!
  au User BufferOverrides exe 'setlocal ' . g:set_overrides
  au BufEnter * exe 'setlocal ' . g:set_overrides
augroup END

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


"-----------------------------------------------------------------------------"
" Repair unexpected behavior
"-----------------------------------------------------------------------------"
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

" Escape repair needed when we allow h/l to change line num
augroup escape_fix
  au!
  au InsertLeave * normal! `^
augroup END

" Remove weird Cheyenne maps, not sure how to isolate/disable /etc/vimrc without
" disabling other stuff we want e.g. syntax highlighting
if !empty(mapcheck('<Esc>', 'n'))  " maps staring with escape
  silent! unmap <Esc>[3~
  let s:insert_maps = [
    \ '[3~', '[6;3~', '[5;3~', '[3;3~', '[2;3~', '[1;3F',
    \ '[1;3H', '[1;3B', '[1;3A', '[1;3C', '[1;3D', '[6;5~', '[5;5~',
    \ '[3;5~', '[2;5~', '[1;5F', '[1;5H', '[1;5B', '[1;5A', '[1;5C',
    \ '[1;5D', '[6;2~', '[5;2~', '[3;2~', '[2;2~', '[1;2F', '[1;2H',
    \ '[1;2B', '[1;2A', '[1;2C', '[1;2D'
    \ ]
  for s:insert_map in s:insert_maps
    exe 'silent! iunmap <Esc>' . s:insert_map
  endfor
endif

" Suppress all prefix mappings initially so that we avoid accidental actions
" due to entering wrong suffix, e.g. \x in visual mode deleting the selection.
function! s:suppress(prefix, mode)
  let char = nr2char(getchar())
  if empty(maparg(a:prefix . char, a:mode))
    return ''  " no-op
  else
    return a:prefix . char  " re-direct to the active mapping
  endif
endfunction
for s:mapping in [
  \ ['<Tab>',    'n'],
  \ ['<Leader>', 'nv'],
  \ ['\',        'nv'],
  \ ]
  let s:key = s:mapping[0]
  let s:modes = split(s:mapping[1], '\zs')  " construct list
  for s:mode in s:modes
    if empty(maparg(s:key, s:mode))
      exe s:mode . 'map <expr> ' . s:key
        \ . " <sid>suppress('" . s:key . "', '" . s:mode . "')"
    endif
  endfor
endfor

" Disable normal mode stuff
" * Q and K are weird modes never used
" * Z is save and quit shortcut, use for something else
" * Ctrl-p and Ctrl-n used for scrolling, remap these instead
" * Ctrl-a and Ctrl-x used for incrementing, use + and - instead
" * Turn off common normal mode issues
" * q and @ are for macros, instead reserve for quitting popup windows and tagtools map
" * [p, ]p, [P, ]P pastes matching indent, remap this
" * ][ and [] can get hit accidentally
" * gt and gT replaced with <Tab> mappings
" * Ctrl-r is undo, remap this
for s:key in [
  \ '@', 'q', 'Q', 'K', 'ZZ', 'ZQ',
  \ '<C-r>', '<C-p>', '<C-n>', '<C-a>', '<C-x>',
  \ '<Delete>', '<Backspace>', '<CR>',
  \ '[p', ']p', '[P', ']P', '][', '[]',
  \ 'gt', 'gT',
  \ ]
  if empty(maparg(s:key, 'n'))
    exe 'noremap ' . s:key . ' <Nop>'
  endif
endfor

" Disable insert mode stuff
" * Ctrl-g used for builtin, surround, delimitmate insert-mode motion (against this)
" * Ctrl-x used for scrolling or insert-mode complection, use autocomplete instead
" * Ctrl-l used for special 'insertmode' always-insert-mode option
" * Ctrl-h, Ctrl-d, Ctrl-t used for deleting and tabbing, but use backspace and tab
" * Ctrl-p, Ctrl-n used for menu cycling, but use Ctrl-, and Ctrl-.
" * Ctrl-b and Ctrl-z do nothing but insert literal char
augroup override_maps
  au!
  au User BufferOverrides inoremap <buffer> <S-Tab> <C-d>
  au BufEnter * inoremap <buffer> <S-Tab> <C-d>
augroup END
for s:key in [
  \ '<F1>', '<F2>', '<F3>', '<F4>',
  \ '<C-n>', '<C-p>', '<C-b>', '<C-z>', '<C-t>', '<C-d>', '<C-g>', '<C-h>', '<C-l>',
  \ '<C-x><C-n>', '<C-x><C-p>', '<C-x><C-e>', '<C-x><C-y>',
  \ ]
  if empty(maparg(s:key, 'i'))
    exe 'inoremap ' . s:key . ' <Nop>'
  endif
endfor

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

" Automatically update binary spellfile
" See: https://vi.stackexchange.com/a/5052/8084
for s:spellfile in glob('~/.vim/spell/*.add', 1, 1)
  if filereadable(s:spellfile) && (
  \ !filereadable(s:spellfile . '.spl') ||
  \ getftime(s:spellfile) > getftime(s:spellfile . '.spl')
  \ )
    echom 'Update spellfile: ' . s:spellfile
    silent! exec 'mkspell! ' . fnameescape(s:spellfile)
  endif
endfor


"-----------------------------------------------------------------------------"
" Vim scripting utilities
"-----------------------------------------------------------------------------"
" Query whether plugin is loaded
" Used to use has_key(g:plugs) but now check runtimepath in case fork is loaded
function! Active(key) abort
  return &runtimepath =~# '/' . a:key . '\>'
endfunction

" Get comment character
function! Comment() abort
  let string = substitute(&commentstring, '%s.*', '', '')
  return substitute(string, '\s\+', '', 'g')
endfunction

" Better grep, with limited regex translation
function! Grep(regex) abort 
  let regex = a:regex
  let regex = substitute(regex, '\(\\<\|\\>\)', '\\b', 'g')
  let regex = substitute(regex, '\\s', "[ \t]",  'g')
  let regex = substitute(regex, '\\S', "[^ \t]", 'g')
  let result = split(system("grep '" . regex . "' " . shellescape(@%) . ' 2>/dev/null'), "\n")
  echo "Results:\n" . join(result, "\n")
  return result
endfunction
command! -nargs=1 Grep call Grep(<q-args>)

" Reverse selected lines
function! Reverse() range abort
  let line1 = a:firstline  " cannot overwrite input var names
  let line2 = a:lastline
  if line1 == line2
    let line1 = 1
    let line2 = line('$')
  endif
  exec 'silent '.line1.','.line2.'g/^/m'.(line1 - 1)
endfunction
command! -range Reverse <line1>,<line2>call Reverse()


"-----------------------------------------------------------------------------"
" File and window utilities
"-----------------------------------------------------------------------------"
" Opening file in current directory and some input directory
augroup tabs
  au!
  au TabLeave * let g:lasttab = tabpagenr()
augroup END
command! -nargs=* -complete=file Open call fzf#open_continuous(<f-args>)
noremap <C-o> :<C-u>Open 
noremap <C-p> :<C-u>Files 
noremap <C-g> :<C-u>GFiles<CR>
noremap <expr> <F3> ":\<C-u>Open " . expand('%:h') . '/'
noremap <expr> <C-y> ":\<C-u>Files " . expand('%:h') . '/'

" Default 'open file under cursor' to open in new tab; change for normal and vidual
" Remember the 'gd' and 'gD' commands go to local declaration, or first instance.
nnoremap <Leader>F <c-w>gf
nnoremap <silent> <Leader>f :<C-u>call utils#file_exists()<CR>

" Move to current directory
" Pneumonic is 'inside' just like Ctrl + i map
nnoremap <silent> <Leader>i :call utils#directory_descend()<CR>
nnoremap <silent> <Leader>I :call utils#directory_return()<CR>

" 'Execute' script with different options
" Note: Execute1 and Execute2 just defined for tex for now
nmap <nowait> Z <Plug>Execute
nmap <Leader>z <Plug>AltExecute1
nmap <Leader>Z <Plug>AltExecute2

" Save and quit, also test whether the :q action closed the entire tab
" SmartWrite is from tabline plugin
nnoremap <silent> <C-s> :SmartWrite<CR>
nnoremap <silent> <C-w> :call utils#tab_close()<CR>
nnoremap <silent> <C-q> :call utils#vim_close()<CR>
" nnoremap <silent> <C-a> :call utils#vim_close()<CR>
" nnoremap <silent> <C-w> :call utils#window_close()<CR>
" nnoremap <silent> <C-q> :call utils#tab_close()<CR>

" Renaming things
command! -nargs=* -complete=file -bang Rename :call utils#rename_file('<args>', '<bang>')

" Refreshing things
command! Refresh call utils#refresh()
nnoremap <silent> <Leader>s :Refresh<CR>
nnoremap <silent> <Leader>r :redraw!<CR>
nnoremap <silent> <Leader>R :e<CR>

" Autosave with SmartWrite using utils function
command! -nargs=? Autosave call utils#autosave_toggle(<args>)
nnoremap <silent> <Leader>S :Autosave<CR>

" Tab selection and movement
nnoremap <Tab>, gT
nnoremap <Tab>. gt
nnoremap <silent> <Tab>' :exe 'tabn ' . (exists('g:lasttab') ? g:lasttab : 1)<CR>
nnoremap <silent> <Tab><Tab> :call fzf#tab_select()<CR>
nnoremap <silent> <Tab>m :call fzf#tab_move()<CR>
nnoremap <silent> <Tab>> :call fzf#tab_move(tabpagenr() + 1)<CR>
nnoremap <silent> <Tab>< :call fzf#tab_move(tabpagenr() - 1)<CR>
for s:num in range(1, 10)
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
nnoremap <Tab>y zH
nnoremap <Tab>u zt
nnoremap <Tab>i mzz.`z
nnoremap <Tab>o zb
nnoremap <Tab>p zL
nnoremap <silent> <Tab>= :<C-u>vertical resize 90<CR>
nnoremap <silent> <Tab>( :<C-u>exe 'resize ' . (winheight(0) - 3 * v:count1)<CR>
nnoremap <silent> <Tab>) :<C-u>exe 'resize ' . (winheight(0) + 3 * v:count1)<CR>
nnoremap <silent> <Tab>_ :<C-u>exe 'resize ' . (winheight(0) - 5 * v:count1)<CR>
nnoremap <silent> <Tab>+ :<C-u>exe 'resize ' . (winheight(0) + 5 * v:count1)<CR>
nnoremap <silent> <Tab>[ :<C-u>exe 'vertical resize ' . (winwidth(0) - 5 * v:count1)<CR>
nnoremap <silent> <Tab>] :<C-u>exe 'vertical resize ' . (winwidth(0) + 5 * v:count1)<CR>
nnoremap <silent> <Tab>{ :<C-u>exe 'vertical resize ' . (winwidth(0) - 10 * v:count1)<CR>
nnoremap <silent> <Tab>} :<C-u>exe 'vertical resize ' . (winwidth(0) + 10 * v:count1)<CR>

" Enable quitting windows with simple 'q' press and disable line numbers
" Note: Some popups require buftype==file for writing temporary files. Used trial and error.
let s:popup_filetypes_file = ['__doc__', 'codi', 'fugitive', 'fugitiveblame', 'gitcommit', 'help', 'man', 'qf', 'tagbar', 'undotree']
let s:popup_filetypes_nofile = ['diff', 'latexmk', 'vim-plug']
augroup popup_setup
  au!
  au BufEnter * let b:recording = 0
  au FileType help call utils#help_setup()
  au CmdwinEnter * call utils#cmdwin_setup()
  au CmdwinLeave * setlocal laststatus=2
  exe 'au FileType ' . join(s:popup_filetypes_file, ',') . ' call utils#popup_setup(0)'
  exe 'au FileType ' . join(s:popup_filetypes_nofile, ',') . ' call utils#popup_setup(1)'
augroup END
let g:tagtools_filetypes_skip = s:popup_filetypes_file + s:popup_filetypes_nofile
let g:tabline_filetypes_ignore = s:popup_filetypes_file + s:popup_filetypes_nofile

" Window view and basic behavior
augroup tab_toggle
  au!
  au FileType xml,make,text,gitconfig TabToggle 1
  au FileType tex setlocal nolist nocursorline colorcolumn=
augroup END
command! -nargs=? PopupToggle call utils#popup_toggle(<args>)
command! -nargs=? ConcealToggle call utils#conceal_toggle(<args>)
command! -nargs=? TabToggle call utils#tab_toggle(<args>)
noremap <Leader><Tab> :TabToggle<CR>

" Vim command windows, help windows, man pages, and result of 'cmd --help'
nnoremap <Leader>; :<Up><CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ q/
nnoremap <Leader>? q?
nnoremap <silent> <Leader>h :call utils#show_cmd_help() \| redraw!<CR>
nnoremap <silent> <Leader>H :call utils#show_cmd_man() \| redraw!<CR>
nnoremap <silent> <Leader>v :Help<CR>
nnoremap <silent> <Leader>m :Maps<CR>
" nnoremap <silent> <Leader>h :call utils#show_vim_help()<CR>

" Cycle through wildmenu expansion with these keys
cnoremap <expr> <F1> utils#wild_tab(0)
cnoremap <expr> <F2> utils#wild_tab(1)

" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" Warning: Do not map escape or cannot send iTerm-shortcuts with escape codes!
" Note: Must change local directory to have term pop up in this dir:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>T :silent! lcd %:p:h<CR>:terminal<CR>


"-----------------------------------------------------------------------------"
" Editing utiltiies
"-----------------------------------------------------------------------------"
" Jump to points with FZF
noremap <silent> <Leader>' :<C-u>Marks<CR>
noremap <silent> <Leader>" :<C-u>BLines<CR>

" Jump to last changed text, note F4 is mapped to Ctrl-m in iTerm
noremap <C-n> g;
noremap <F4> g,

" Jump to last jump
" Note: Account for karabiner arrow key maps
noremap <C-h> <C-o>
noremap <C-l> <C-i>
noremap <Left> <C-o>
noremap <Right> <C-i>

" Free up m keys, so ge/gE command belongs as single-keystroke
" words along with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Highlight marks. Use '"' or '[1-8]"' to set some mark, use '9"' to delete it,
" and use ' or [1-8]' to jump to a mark.
" let g:highlightmark_colors = ['magenta']
" let g:highlightmark_cterm_colors = [5]
command! -nargs=* RemoveHighlights call highlightmark#remove_highlights(<f-args>)
command! -nargs=1 HighlightMark call highlightmark#highlight_mark(<q-args>)
nnoremap <expr> ` "`" . nr2char(97 + v:count)
nnoremap <expr> ~ 'm' . nr2char(97 + v:count) . ':HighlightMark ' . nr2char(97 + v:count) . '<CR>'
nnoremap <Leader>~ :<C-u>RemoveHighlights<CR>

" Alias single-key builtin text objects
for s:bracket in ['r[', 'a<', 'c{']
  exe 'onoremap i' . s:bracket[0] . ' i' . s:bracket[1]
  exe 'xnoremap i' . s:bracket[0] . ' i' . s:bracket[1]
  exe 'onoremap a' . s:bracket[0] . ' a' . s:bracket[1]
  exe 'xnoremap a' . s:bracket[0] . ' a' . s:bracket[1]
endfor

" Insert and mormal mode undo and redo. Also permit toggling blocks while in insert mode
nnoremap U <C-r>
inoremap <silent> <C-u> <C-o>mx<C-o>u
inoremap <silent> <C-y> <C-o><C-r><C-o>`x<Right>

" Record macro by pressing Q, the escapes prevent q from triggerering
" Avoid q mapping because we use that to quit popup windows
nnoremap , @a
nnoremap <silent> <expr> Q
  \ b:recording ? 'q<Esc>:let b:recording = 0<CR>' : 'qa<Esc>:let b:recording = 1<CR>'

" Use cc for s because use sneak plugin
nnoremap c<Backspace> <Nop>
nnoremap cc s
vnoremap cc s

" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
nnoremap cL mzi<CR><Esc>`z

" Swap adjacent characters or rows
nnoremap <silent> ch :call utils#swap_characters(0)<CR>
nnoremap <silent> cl :call utils#swap_characters(1)<CR>
nnoremap <silent> ck :call utils#swap_lines(0)<CR>
nnoremap <silent> cj :call utils#swap_lines(1)<CR>

" Pressing enter on empty line preserves leading whitespace
nnoremap o oX<Backspace>
nnoremap O OX<Backspace>

" Paste from the nth previously deleted or changed text. Use 'yp' to paste last yanked,
" unchanged text, because cannot use zero. Press <Esc> to remove count from motion.
nnoremap yp "0p
nnoremap yP "0P
nnoremap <silent> <Leader>v :Help<CR>
nnoremap <expr> p v:count == 0 ? 'p' : '<Esc>"' . v:count . 'p'
nnoremap <expr> P v:count == 0 ? 'P' : '<Esc>"' . v:count . 'P'
nnoremap <Leader>p ]p
nnoremap <Leader>P ]P

" Yank until end of line, like C and D
nnoremap Y y$

" Joining counts improvement. Before 2J joined this line and next, now it
" means 'join the two lines below'
nnoremap <expr> J v:count > 1 ? 'JJ' : 'J'
nnoremap <expr> K 'k' . v:count . (v:count > 1  ? 'JJ' : 'J')

" Indenting counts improvement. Before 2> indented this line or this motion repeated,
" now it means 'indent multiple times'. Press <Esc> to remove count from motion.
nnoremap <expr> >> '<Esc>' . repeat('>>', v:count1)
nnoremap <expr> << '<Esc>' . repeat('<<', v:count1)
nnoremap <expr> > '<Esc>' . utils#multi_indent_expr(0, v:count1)
nnoremap <expr> < '<Esc>' . utils#multi_indent_expr(1, v:count1)

" Maps to functions that accept motions
command! -range -nargs=0 WrapItemLines <line1>,<line2>call utils#wrap_item_lines()
noremap <expr> <silent> gQ utils#wrap_item_lines_expr()

" Toggle highlighting
nnoremap <silent> <Leader>o :noh<CR>
nnoremap <silent> <Leader>O :set hlsearch<CR>

" Never save single-character deletions to any register
noremap x "_x
noremap X "_X
" Maps for throwaaway and clipboard register
noremap ' "_
noremap " "*

" Copy mode ('paste mode' accessible with [v and ]v via unimpaired.vim)
command! -nargs=? CopyToggle call utils#copy_toggle(<args>)
nnoremap <Leader>c :call utils#copy_toggle()<CR>

" Caps lock toggle and insert mode map that toggles it on and off
" See <http://vim.wikia.com/wiki/Insert-mode_only_Caps_Lock>, instead uses
" iminsert to enable/disable lnoremap, with iminsert changed from 0 to 1
for s:c in range(char2nr('A'), char2nr('Z'))
  exe 'lnoremap ' . nr2char(s:c + 32) . ' ' . nr2char(s:c)
  exe 'lnoremap ' . nr2char(s:c) . ' ' . nr2char(s:c + 32)
endfor
set iminsert=0
augroup caps_lock
  au!
  au InsertLeave * setlocal iminsert=0
augroup END
inoremap <C-v> <C-^>
cnoremap <C-v> <C-^>

" Spellcheck (really is a builtin plugin, hence why it's in this section)
" Turn on for certain filetypes
augroup spell_toggle
  au!
  au FileType tex,html,markdown,rst
    \ if expand('<afile>') != '__doc__' |
    \ call spell#spell_toggle(1) |
    \ endif
augroup END

" Toggle spelling on and off
command! SpellToggle call spell#spell_toggle(<args>)
command! LangToggle call spell#lang_toggle(<args>)
nnoremap <silent> <Leader>l :call spell#spell_toggle(1)<CR>
nnoremap <silent> <Leader>L :call spell#spell_toggle(0)<CR>
nnoremap <silent> <Leader>k :call spell#lang_toggle(1)<CR>
nnoremap <silent> <Leader>K :call spell#lang_toggle(0)<CR>

" Add and remove from dictionary
nnoremap <Leader>d zg
nnoremap <Leader>D zug
nnoremap <Leader>! z=

" Similar to ]s and [s but also correct the word!
nnoremap <silent> <Plug>forward_spell bh]s:call spell#spell_change(']')<CR>:call repeat#set("\<Plug>forward_spell")<CR>
nnoremap <silent> <Plug>backward_spell el[s:call spell#spell_change('[')<CR>:call repeat#set("\<Plug>backward_spell")<CR>
nmap ]d <Plug>forward_spell
nmap [d <Plug>backward_spell

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

" Always open all folds
" NOTE: For some reason vim ignores foldlevelstart
augroup fold_open
  au!
  au BufReadPost * silent! foldopen!
augroup END

" Open *all* folds under cursor, not just this one
" noremap <expr> zo foldclosed('.') ? 'zA' : ''
" Open *all* folds recursively and update foldlevel
noremap zO zR
" Close *all* folds and update foldlevel
noremap zC zM
" Delete *all* manual folds
noremap zD zE

" Jump between folds with more consistent naming
noremap [z zk
noremap ]z zj
noremap [Z [z
noremap ]Z ]z

" Unimpaired blank lines
nnoremap <silent> <Plug>BlankUp :call utils#blank_up(v:count1)<CR>
nnoremap <silent> <Plug>BlankDown :call utils#blank_down(v:count1)<CR>
nmap [e <Plug>BlankUp
nmap ]e <Plug>BlankDown

" Maps and commands for circular location-list scrolling
command! -bar -count=1 Cnext execute utils#cyclic_next(<count>, 'qf')
command! -bar -count=1 Cprev execute utils#cyclic_next(<count>, 'qf', 1)
command! -bar -count=1 Lnext execute utils#cyclic_next(<count>, 'loc')
command! -bar -count=1 Lprev execute utils#cyclic_next(<count>, 'loc', 1)
nnoremap <silent> [x :Lprev<CR>
nnoremap <silent> ]x :Lnext<CR>
nnoremap <silent> [q :Cprev<CR>
nnoremap <silent> ]q :Cnext<CR>

" Insert mode with paste toggling
" nnoremap <expr> gc utils#setup_paste() . 'c'
nnoremap <expr> gi utils#setup_paste() . 'i'
nnoremap <expr> gI utils#setup_paste() . 'I'
nnoremap <expr> ga utils#setup_paste() . 'a'
nnoremap <expr> gA utils#setup_paste() . 'A'
nnoremap <expr> go utils#setup_paste() . 'o'
nnoremap <expr> gO utils#setup_paste() . 'O'
nnoremap <expr> gR utils#setup_paste() . 'R'

" Jump to definition of keyword under cursor, and show first line of occurence
" nnoremap <CR> <C-]>  " fails most of the time
nnoremap <CR> [<C-i>
nnoremap <Leader><CR> [I

" Improved popup menu navigation
augroup pum_navigation
  au!
  au BufEnter,InsertLeave * let b:pum_pos = 0
augroup END

" Keystrokes that always close the popup menu
inoremap <expr> <BS>    pumvisible() ? utils#pum_reset() . "\<C-e>\<Backspace>" : "\<Backspace>"
inoremap <expr> <Space> pumvisible() ? utils#pum_reset() . "\<C-e>\<C-]>\<Space>" : "\<C-]>\<Space>"

" Enter is 'accept' only if we explicitly scrolled down, tab is always 'accept' and
" choose default menu item if necessary. Also break undo history when adding linebreaks.
" See: :help ins-special-special
inoremap <expr> <CR>  pumvisible() ? b:pum_pos ? "\<C-y>" . utils#pum_reset() : "\<C-e>\<C-]>\<C-g>u\<CR>" : "\<C-]>\<C-g>u\<CR>"
inoremap <expr> <Tab> pumvisible() ? b:pum_pos ? "\<C-y>" . utils#pum_reset() : "\<C-n>\<C-y>" . utils#pum_reset() : "\<C-]>\<Tab>"

" Keystrokes that increment items in the menu
" Also disable scrolling in insert mode
inoremap <expr> <ScrollWheelUp>   pumvisible() ? utils#pum_prev() : ''
inoremap <expr> <ScrollWheelDown> pumvisible() ? utils#pum_next() : ''
inoremap <expr> <C-k>  pumvisible() ? utils#pum_prev() : "\<Up>"
inoremap <expr> <C-j>  pumvisible() ? utils#pum_next() : "\<Down>"
inoremap <expr> <Up>   pumvisible() ? utils#pum_prev() : "\<Up>"
inoremap <expr> <Down> pumvisible() ? utils#pum_next() : "\<Down>"

" Forward delete by tabs
inoremap <silent> <expr> <Delete> utils#forward_delete()

" Insert comment
inoremap <expr> <C-c> comments#comment_insert()

" Section headers, dividers, and other information
nnoremap <silent> gcA :call comments#message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
nnoremap <silent> gcY :call comments#message('Date: ' . strftime('%Y-%m-%d'))<CR>
nnoremap <silent> gc" :call comments#header_inline(5)<CR>
nnoremap <silent> gc' :call comments#header_incomment()<CR>
nnoremap <silent> gc: :call comments#header_line('-', 77, 1, 1)<CR>
nnoremap <silent> <Plug>CommentBar :call comments#header_line('-', 77, 1, 0)<CR>:call repeat#set("\<Plug>CommentBar")<CR>
nmap gc; <Plug>CommentBar

" ReST section comment headers
" Warninb: <Plug> name should not be subset of other name or results in delay!
nnoremap <silent> <Plug>SectionSingle :call comments#section_line('=', 0)<CR>:silent! call repeat#set("\<Plug>SectionSingle")<CR>
nnoremap <silent> <Plug>SubsectionSingle :call comments#section_line('-', 0)<CR>:silent! call repeat#set("\<Plug>SubsectionSingle")<CR>
nnoremap <silent> <Plug>SectionDouble :call comments#section_line('=', 1)<CR>:silent! call repeat#set("\<Plug>SectionDouble")<CR>
nnoremap <silent> <Plug>SubsectionDouble :call comments#section_line('-', 1)<CR>:silent! call repeat#set("\<Plug>SubsectionDouble")<CR>
nmap g= <Plug>SectionSingle
nmap g- <Plug>SubsectionSingle
nmap g+ <Plug>SectionDouble
nmap g_ <Plug>SubsectionDouble

" Python docstrings
nnoremap g' :call comments#python_docstring("'")<CR>A
nnoremap g" :call comments#python_docstring('"')<CR>A

" Search and find-replace stuff
" * Had issue before where InsertLeave ignorecase autocmd was getting reset; it was
"   because MoveToNext was called with au!, which resets all InsertLeave commands then adds its own
" * Make sure 'noignorecase' turned on when in insert mode, so *autocompletion* respects case.
augroup search_replace
  au!
  au InsertEnter * set noignorecase  " default ignore case
  au InsertLeave * set ignorecase
augroup END

" Search for git conflict blocks
noremap gG /^[<>=\|]\{2,}<CR>
" Search for non-ASCII chars
" Fails: https://stackoverflow.com/a/16987522/4970632
" noremap gA /[^\x00-\x7F]<CR>
" Works: https://stackoverflow.com/a/41168966/4970632
noremap gA /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Run replacement on this line alone
nmap <expr> \\ '\' . nr2char(getchar()) . 'al'

" Delete commented text. For some reason search screws up when using \(\) groups,
" maybe because first parts of match are identical?
" Note: Comment() doesn't get invoked either until entire expression is run
noremap <expr> \c utils#replace_regexes_expr('Removed comments.', '^\s*' . Comment() . '.\+$\n', '', '\s\+' . Comment() . '.\+$', '')

" Delete trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
noremap <expr> \w utils#replace_regexes_expr('Removed trailing whitespace.', '\s\+\ze$', '')

" Replace consecutive spaces on current line with one space, if they're not part of indentation
noremap <expr> \s utils#replace_regexes_expr('Squeezed redundant whitespace.', '\S\@<=\(^ \+\)\@<! \{2,}', ' ')
noremap <expr> \S utils#replace_regexes_expr('Removed all whitespace.', '\S\@<=\(^ \+\)\@<! \+', '')

" Delete empty lines
" Replace consecutive newlines with single newline
noremap <expr> \e utils#replace_regexes_expr('Squeezed consecutive newlines.', '\(\n\s*\n\)\(\s*\n\)\+', '\1')
noremap <expr> \E utils#replace_regexes_expr('Removed empty lines.', '^\s*$\n', '')

" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
noremap <expr> \' utils#replace_regexes_expr('Fixed single quotes.', '‘', '`', '’', "'")
noremap <expr> \" utils#replace_regexes_expr('Fixed double quotes.', '“', '``', '”', "''")
noremap <expr> \- utils#replace_regexes_expr('Fixed long dashes.', '–', '--')
noremap <expr> \_ utils#replace_regexes_expr('Fixed wordbreak dashes.', '\(\w\)[-–] ', '\1')

" Replace tabs with spaces
noremap <expr> \<Tab> utils#replace_regexes_expr('Fixed tabs.', '\t', repeat(' ', &tabstop))


"-----------------------------------------------------------------------------"
" VimPlug plugins
"-----------------------------------------------------------------------------"
" Find runtimepath
function! s:find_path(regex)
  return filter(split(&runtimepath, ','), "v:val =~# '" . a:regex . "'")
endfunction
command! -nargs=1 FindPath echo join(s:find_path(<q-args>), ', ')

" 'Install' a local plugin
function! s:plug_local(path)
  let rtp = expand(substitute(a:path, '[''"]', '', 'g'))
  if !isdirectory(rtp)
    echohl WarningMsg
    echo "Warning: Path '" . rtp . "' not found."
    echohl None
  elseif &runtimepath !~ escape(rtp, '~')
    exe 'set rtp^=' . rtp
    exe 'set rtp+=' . rtp . '/after'
  endif
endfunction
command! -nargs=1 PlugLocal call s:plug_local(<args>)

" Note: No longer worry about compatibility because we can install everything
" from conda-forge, including vim and ctags.
call plug#begin('~/.vim/plugged')

" Custom plugins or forks, try to load locally if possible!
" See: https://github.com/junegunn/vim-plug/issues/32
" Note ^= prepends to list, += appends
for s:name in [
  \ 'vim-shortcuts',
  \ 'vim-tagtools',
  \ 'vim-statusline',
  \ 'vim-tabline',
  \ 'vim-scrollwrapped',
  \ 'vim-toggle',
  \ 'codi.vim'
  \ ]
  let s:path_home = expand('~/' . s:name)
  let s:path_fork = expand('~/forks/' . s:name)
  if isdirectory(s:path_home)
    exe "PlugLocal '" . s:path_home . "'"
  elseif isdirectory(s:path_fork)
    exe "PlugLocal '" . s:path_fork . "'"
  else
    exe "Plug 'lukelbd/" . s:name . "'"
  endif
endfor
let g:tagtools_filetypes_all_tags = ['fortran']
let g:tagtools_filetypes_top_tags = {
  \ 'vim'     : 'afc',
  \ 'tex'     : 'bs',
  \ 'python'  : 'fcm',
  \ 'fortran' : 'smfp',
  \ }

" Hard requirements
" Plug 'tpope/vim-repeat' " now edit custom version in .vim/plugin/autoload
Plug '~/.fzf'  " fzf installation location, will add helptags and runtimepath
Plug 'junegunn/fzf.vim'  " this one depends on the main repo above, includes other tools
let g:fzf_layout = {'down': '~20%'} " make window smaller
let g:fzf_action = {
  \ 'ctrl-i': 'silent!',
  \ 'ctrl-m': 'tab split',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \ }

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
" Plug 'psf/black', {'tag': '19.10b0'}
" Plug 'fisadev/vim-isort'
Plug 'Chiel92/vim-autoformat'
Plug 'tell-k/vim-autopep8'
Plug 'tmux-plugins/vim-tmux'
Plug 'plasticboy/vim-markdown'
Plug 'vim-scripts/applescript.vim'
Plug 'anntzer/vim-cython'
Plug 'tpope/vim-liquid'
let g:formatdef_mpython = '"isort - | black -q -S -"'
let g:formatters_python = ['mpython']  " use multiple formatters
let g:formatters_fortran = ['fprettify']

" TeX utilities; better syntax highlighting, better indentation,
" and some useful remaps. Also zotero integration.
" For vimtex config see: https://github.com/lervag/vimtex/issues/204
" Plug 'twsh/unite-bibtex'  " python 3 version
" Plug 'msprev/unite-bibtex'  " python 2 version
" Plug 'lervag/vimtex'
" Plug 'chrisbra/vim-tex-indent'
" Plug 'Shougo/unite.vim'  " now use custom bibtex tool
" Plug 'rafaqz/citation.vim'

" Julia support and syntax highlighting
Plug 'JuliaEditorSupport/julia-vim'

" Python utilities
" Warning: jedi-vim horribly slow on monde
" Plug 'vim-scripts/Pydiction'  " just changes completeopt and dictionary and stuff
" Plug 'cjrh/vim-conda'  " for changing anconda VIRTUALENV; probably don't need it
" Plug 'klen/python-mode'  " incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython'  " dead
" let g:pydiction_location = expand('~') . '/.vim/plugged/Pydiction/complete-dict'  " for pyDiction plugin
" Plug 'jupyter-vim/jupyter-vim'  " hard to use jupyter console with proplot
Plug 'tweekmonster/braceless.vim'  " partial overlap with vim-textobj-indent, but these include header
let g:braceless_block_key = ':'  " captures if, for, def, etc.
Plug 'davidhalter/jedi-vim'  " disable autocomplete stuff in favor of deocomplete
Plug 'goerz/jupytext.vim'  " edit ipython notebooks
let g:jupytext_fmt = 'py:percent'

" Folding
" Warning: SimpylFold horribly slow on monde, instead use braceless
Plug 'Konfekt/FastFold'
" Plug 'tmhedberg/SimpylFold'
" let g:SimpylFold_docstring_preview = 0
" let g:SimpylFold_fold_docstring = 0
" let g:SimpylFold_fold_import = 0

" Matching groups
Plug 'andymass/vim-matchup'
let g:loaded_matchparen = 1
let g:matchup_matchparen_enabled = 1
let g:matchup_transmute_enabled = 0  " breaks latex!

" Useful panels
" For nerdtree-like file navigation see: https://shapeshed.com/vim-netrw/
" Plug 'vim-scripts/EnhancedJumps'
" Plug 'jistr/vim-nerdtree-tabs'  " unnecessary
" Plug 'scrooloose/nerdtree'
Plug 'majutsushi/tagbar'
Plug 'mbbill/undotree'

" Close unused buffers
" https://github.com/Asheq/close-buffers.vim
Plug 'Asheq/close-buffers.vim'

" Tabdrop fix for vim
" Note: Now apply similar solution in tabline#smart_write
" Plug 'ohjames/tabdrop'

" Commenting and syntax checking
" Note: syntastic looks for checkers in $PATH, must be installed manually
" Note: tcomment_vim is nice minimal extension of vim-commentary, include explicit
" commenting and uncommenting and 'blockwise' commenting with g>b and g<b
" Plug 'scrooloose/syntastic'
" Plug 'scrooloose/nerdcommenter'
" Plug 'tpope/vim-commentary'  " too simple
Plug 'dense-analysis/ale'
Plug 'tomtom/tcomment_vim'

" Inline code handling
" Use :InlineEdit within blocks to open temporary buffer for editing; buffer
" will have all filetype-aware settings. See: https://github.com/AndrewRadev/inline_edit.vim
Plug 'AndrewRadev/inline_edit.vim'

" Sessions and swap files and reloading. Mapped in my .bashrc
" to vim -S .vimsession and exiting vim saves the session there
" Plug 'thaerkh/vim-workspace'
" Plug 'gioele/vim-autoswap'  " deals with swap files automatically; no longer use them so unnecessary
" Plug 'xolox/vim-reload'  " better to write my own simple plugin
Plug 'tpope/vim-obsession'

" Git wrappers and differencing tools
" vim-flog and gv.vim are heavyweight and lightweight commit viewing plugins
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'  " view commit graphs with :GV
" Plug 'rbong/vim-flog'  " view commit graphs with :Flog

" Shell utilities, including Chmod and stuff
Plug 'tpope/vim-eunuch'

" Calculators and number stuff
" Plug 'vim-scripts/Toggle'  " toggling stuff on/off, modified this myself
" Plug 'triglav/vim-visual-increment'  " superceded by vim-speeddating
" Plug 'metakirby5/codi.vim'
Plug 'sk1418/HowMuch'
Plug 'tpope/vim-speeddating'  " dates and stuff
let g:speeddating_no_mappings = 1
let g:HowMuch_no_mappings = 1

" Completion engines
" Note: Disable for macvim because not sure how to control its python distro
" Plug 'ajh17/VimCompletesMe'  " no auto-popup feature
" Plug 'lifepillar/vim-mucomplete'  " broken, seriously, cannot get it to work, don't bother! is slow anyway.
" Plug 'Valloric/YouCompleteMe'  " broken
" Plug 'ervandew/supertab'
" Plug 'shougo/neocomplete.vim'  " needs lua!
" let g:neocomplete#enable_at_startup = 1
" Plug 'prabirshrestha/asyncomplete.vim'
if !has('gui_running')
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

" Snippets
" Todo: Investigate further, but so far primitive vim-shortcuts snippets are fine
" Plug 'SirVer/ultisnips'  " fancy snippet actions
" Plug 'honza/vim-snippets'  " reference snippet files supplied to e.g. ultisnips
" Plug 'LucHermitte/mu-template'  " file template and snippet engine mashup, not popular

" Delimiters, use vim-surround rather than vim-sandwich because key mappings
" are better and API is simpler. Only miss adding numbers to operators, otherwise
" feature set is same (e.g. cannot delete and change arbitrary text objects)
" See discussion: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
" See also: https://github.com/wellle/targets.vim/issues/225
" Plug 'wellle/targets.vim'
" Plug 'machakann/vim-sandwich'
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'

" Custom text objects (inner/outer selections)
" Todo: Generalized function converting text objects into navigation commands?
" Unsustainable to try to reproduce diverse plugin-supplied text objects as
" navigation commands... need to do this automatically!!!
" Plug 'bps/vim-textobj-python'  " not really ever used, just use indent objects
" Plug 'vim-scripts/argtextobj.vim'  " issues with this too
" Plug 'machakann/vim-textobj-functioncall'  " does not work
" Plug 'glts/vim-textobj-comment'  " does not work
Plug 'kana/vim-textobj-user'  " base requirement
Plug 'kana/vim-textobj-entire'  " entire file, object is 'e'
Plug 'kana/vim-textobj-line'  " entire line, object is 'l'
Plug 'kana/vim-textobj-indent'  " matching indentation, object is 'i' for deeper indents and 'I' for just contiguous blocks, and using 'a' includes blanklines
Plug 'sgur/vim-textobj-parameter'  " function parameter
let g:vim_textobj_parameter_mapping = '='  " avoid ',' conflict with latex

" Aligning things and stuff, use vim-easy-align because more tabular API is fugly AF
" and requires individual maps and docs suck. Also does not have built-in feature for
" ignoring comments or built-in aligning within motions or textobj blocks.
" Plug 'vim-scripts/Align'
" Plug 'tommcdo/vim-lion'
" Plug 'godlygeek/tabular'
Plug 'junegunn/vim-easy-align'

" Better motions with sneak plugin. Do not use easymotion because extremely slow
" over remote connections and overkill.
" See discussion: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" Plug 'easymotion/vim-easymotion'
Plug 'justinmk/vim-sneak'

" This RST shit all failed
" Just to simple == tables instead of fancy ++ tables
" Plug 'nvie/vim-rst-tables'
" Plug 'ossobv/vim-rst-tables-py3'
" Plug 'philpep/vim-rst-tables'
" noremap <silent> \s :python ReformatTable()<CR>
" let g:riv_python_rst_hl = 1
" Plug 'Rykka/riv.vim'
"
" Single line/multiline transition; make sure comes after surround
" Hardly ever need this
" Plug 'AndrewRadev/splitjoin.vim'
" let g:splitjoin_split_mapping = 'cS' | let g:splitjoin_join_mapping  = 'cJ'
"
" Multiple cursors is awesome
" Article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" Plug 'terryma/vim-multiple-cursors'
"
" Indent guides
" Note: Indentline completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes (which
" we need to stay transparent). Also indent-guides looks too busy and obtrusive.
" Instead use braceless.vim highlighting, appears only when cursor is there.
" Plug 'yggdroot/indentline'
" Plug 'nathanaelkane/vim-indent-guides'
"
" Miscellaneous
" Plug 'jez/vim-superman'  " man page
" Plug 'beloglazov/vim-online-thesaurus'  " broken
" Plug 'dkarter/bullets.vim'  " list numbering, fails too
"
" Easy tags, for easy integration
" Plug 'xolox/vim-misc'  "depdency for easytags
" Plug 'xolox/vim-easytags'  "kinda old and not that useful honestly
" Plug 'ludovicchabant/vim-gutentags'  "slows shit down like crazy
"
" End of plugins
" The plug#end also declares filetype plugin, syntax, and indent on
" Note apparently every BufRead autocmd inside an ftdetect/filename.vim file
" is automatically made part of the 'filetypedetect' augroup; that's why it exists!
call plug#end()


"-----------------------------------------------------------------------------"
" Plugin sttings
"-----------------------------------------------------------------------------"
" Mappings for vim-tagtools command
" Also use ctag brackets mapping for default double bracket motion, except never
" overwrite potential single bracket mappings (e.g. in help mode)mapping of single bracket
if Active('vim-tagtools') || &runtimepath =~# 'vim-tagtools'
  augroup double_bracket
    au!
    au BufEnter *
      \ if empty(maparg('[')) && empty(maparg(']')) |
      \ nmap <buffer> [[ [T | nmap <buffer> ]] ]T |
      \ endif
  augroup END
  nnoremap <silent> <Leader>C :CTagsDisplay<CR>
endif
if Active('black')
  let g:black_linelength = s:textwidth
  let g:black_skip_string_normalization = 1
endif

" Mappings for scrollwrapped accounting for Karabiner <C-j> --> <Down>, etc.
if Active('vim-scrollwrapped') || &runtimepath =~# 'vim-scrollwrapped'
  let g:scrollwrapped_wrap_filetypes = []
  nnoremap <silent> <Leader>w :WrapToggle<CR>
  nnoremap <silent> <Down> :call scrollwrapped#scroll(winheight(0)/4, 'd', 1)<CR>
  nnoremap <silent> <Up>   :call scrollwrapped#scroll(winheight(0)/4, 'u', 1)<CR>
  vnoremap <silent> <expr> <Down> (winheight(0) / 4) . '<C-e>' . (winheight(0) / 4) . 'gj'
  vnoremap <silent> <expr> <Up>   (winheight(0) / 4) . '<C-y>' . (winheight(0) / 4) . 'gk'
endif

" Auto-complete delimiters
" Filetype-specific settings are in various ftplugin files
if Active('delimitmate')
  let g:delimitMate_expand_cr = 2  " expand even if it is not empty!
  let g:delimitMate_expand_space = 1
  let g:delimitMate_jump_expansion = 0
  let g:delimitMate_excluded_regions = 'String'  " by default is disabled inside, don't want that
endif

" Add global delims with vim-shortcuts plugin functions and declare my weird
" mapping defaults due to Karabiner
if Active('vim-shortcuts') || &runtimepath =~# 'vim-shortcuts'
  " Set the cache directory for bibtex plugin
  let s:cache_dir = expand('~/Library/Caches/bibtex')
  if isdirectory(s:cache_dir)
    let $FZF_BIBTEX_CACHEDIR = s:cache_dir
  endif
  " Custom delimiter mappings
  " Note: Account for karabiner arrow key maps
  let g:shortcuts_surround_prefix = '<C-s>'
  let g:shortcuts_snippet_prefix = '<C-d>'
  let g:shortcuts_prevdelim_map = '<F1>'
  let g:shortcuts_nextdelim_map = '<F2>'
endif

" *Very* expensive for large files so only ever activate manually
" Mapping is # for hex string
if Active('colorizer')
  let g:colorizer_startup = 0
  let g:colorizer_nomap = 1
  nnoremap <Leader># :<C-u>ColorToggle<CR>
endif

" Undo tree
if Active('undotree')
  let g:undotree_ShortIndicators = 1
  let g:undotree_RelativeTimestamp = 0
  noremap <Leader>u :UndotreeToggle<CR>
  if has('persistent_undo')
    let &undodir=$HOME . '/.undodir'
    set undofile
  endif
endif

" Speed dating, support date increments
if Active('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
  noremap <Plug>SpeedDatingFallbackUp   <C-a>
  noremap <Plug>SpeedDatingFallbackDown <C-x>
else
  noremap + <C-a>
  noremap - <C-x>
endif

" The howmuch.vim plugin. Pneumonic for mapping is the straight line at bottom of
" sum table. Mapping options are:
" AutoCalcReplace
" AutoCalcReplaceWithSum
" AutoCalcAppend
" AutoCalcAppendWithEq
" AutoCalcAppendWithSum
" AutoCalcAppendWithEqAndSum
if Active('HowMuch')
  vmap <Leader>- <Plug>AutoCalcReplaceWithSum
  vmap <Leader>_ <Plug>AutoCalcAppendWithEqAndSum
endif

" Codi (mathematical notepad)
if Active('codi.vim')
  " See issue: https://github.com/metakirby5/codi.vim/issues/90
  " We want TextChanged and InsertLeave, not TextChangedI which is enabled
  " when setting g:codi#autocmd to 'TextChanged'
  augroup math
    au!
    au User CodiEnterPre call utils#codi_setup(1)
    au User CodiLeavePost call utils#codi_setup(0)
  augroup END
  command! -nargs=? CodiNew call utils#codi_new(<q-args>)
  nnoremap <silent> <Leader>= :CodiNew<CR>
  nnoremap <silent> <Leader>+ :Codi!!<CR>

  " Interpreter without history, various settings
  " See: https://github.com/metakirby5/codi.vim/issues/85
  " Note: Codi is broken for julia: https://github.com/metakirby5/codi.vim/issues/120
  let g:codi#autocmd = 'None'
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 20
  let g:codi#log = ''  " enable when debugging
  let g:codi#sync = 0  " disable async
  let g:codi#interpreters = {
    \ 'python': {
        \ 'bin': '/usr/bin/python',
        \ 'prompt': '^\(>>>\|\.\.\.\) ',
        \ 'quitcmd': 'exit()',
        \ },
    \ 'julia': {
        \ 'bin': $HOME . '/miniconda3/bin/python',
        \ 'prompt': '^\(julia>\|      \)',
        \ },
    \ }
  "        \ 'bin': $HOME . '/miniconda3/bin/python',
  "        \ 'quitcmd': 'import readline; readline.clear_history(); exit()',
endif

" Fugitive command aliases
" Used to alias G commands to lower case but upper case is more consistent
" with Tim Pope eunuch commands
if Active('vim-fugitive')
  cnoreabbrev Gdiff Gdiffsplit!
  cnoreabbrev Ghdiff Ghdiffsplit!
  cnoreabbrev Gvdiff Gvdiffsplit!
endif

" Git gutter
" Todo: Note we had to overwrite the gitgutter autocmds with a file in 'after'.
if Active('vim-gitgutter')
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

" Vim sneak
if Active('vim-sneak')
  map s <Plug>Sneak_s
  map S <Plug>Sneak_S
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  map <F1> <Plug>Sneak_,
  map <F2> <Plug>Sneak_;
endif

" Neocomplete and deoplete
if Active('deoplete.nvim')
  call deoplete#custom#option({
  \ 'max_list': 15,
  \ })
endif
if Active('neocomplete.vim')
  let g:neocomplete#max_list = 15
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#enable_auto_select = 0
endif

" Jedi vim
if Active('jedi-vim')
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

" Tagbar settings
" * p jumps to tag under cursor, in code window, but remain in tagbar
" * C-n and C-p browses by top-level tags
" * o toggles the fold under cursor, or current one
if Active('tagbar')
  " Customization, for more info see :help tagbar-extend
  " To list kinds, see :!ctags --list-kinds=<filetype>
  " The first number is whether to fold, second is whether to highlight location
  " \ 'r:refs:1:0',  "not useful
  " \ 'p:pagerefs:1:0'  "not useful
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
  let g:no_status_line = 1
  let g:tagbar_no_status_line = 1  " not sure which
  let g:tagbar_silent = 1  " no information echoed
  let g:tagbar_previewwin_pos = 'bottomleft'  " result of pressing 'P'
  let g:tagbar_left = 0  " open on left; more natural this way
  let g:tagbar_indent = -1  " only one space indent
  let g:tagbar_show_linenumbers = 0  " not needed
  let g:tagbar_autofocus = 0  " don't autojump to window if opened
  let g:tagbar_sort = 1  " sort alphabetically? actually much easier to navigate, so yes
  let g:tagbar_case_insensitive = 1  " make sorting case insensitive
  let g:tagbar_compact = 1  " no header information in panel
  let g:tagbar_width = 15  " better default
  let g:tagbar_zoomwidth = 15  " don't ever 'zoom' even if text doesn't fit
  let g:tagbar_expand = 0
  let g:tagbar_autoshowtag = 2  " never ever open tagbar folds automatically, even when opening for first time
  let g:tagbar_foldlevel = 1  " setting to zero will override the 'kinds' fields in below dicts
  let g:tagbar_map_openfold = '='
  let g:tagbar_map_closefold = '-'
  let g:tagbar_map_closeallfolds = '_'
  let g:tagbar_map_openallfolds = '+'
  nnoremap <silent> <Leader>t :TagbarToggle<CR>
endif

" Error highlighting with different plugins
hi ALEErrorLine ctermfg=White ctermbg=Red cterm=None
hi ALEWarningLine ctermfg=White ctermbg=Magenta cterm=None
hi SyntasticErrorLine ctermfg=White ctermbg=Red cterm=None
hi SyntasticWarningLine ctermfg=White ctermbg=Magenta cterm=None

" Flake8 ignore list (also apply to autopep8):
" * Allow line break before binary operator (W503)
" * Allow imports after statements, important for jupytext (E402)
" * Allow multiple spaces before operators for alignment (E221)
" * Allow multiple spaces after commas for alignment (E221)
" * Allow assigning lambda expressions instead of def (E731)
" * Permit 'l' and 'I' variable names (E741)
let s:pep8ignore = 'W503,E402,E221,E241,E731,E741'
let g:ale_python_flake8_options =  '--max-line-length=' . s:textwidth . ' --ignore=' . s:pep8ignore
let g:autopep8_ignore = s:pep8ignore
let g:autopep8_max_line_length = s:textwidth
let g:syntastic_python_flake8_post_args = g:ale_python_flake8_options
let g:vim_isort_config_overrides = {
  \ 'line_length': s:textwidth,
  \ 'multi_line_output': 3,
  \ 'include_trailing_comma': 'true',
  \ 'force_grid_wrap': 0
  \ }

" Shellcheck ignore list
" * Permit 'useless cat' because left-to-right command chain more intuitive (SC2002)
" * Allow sourcing from files (SC1090, SC1091)
" * Allow building arrays from unquoted result of command (SC2206, SC2207)
" * Allow quoting RHS of =~ e.g. for array comparison (SC2076)
" * Allow unquoted variables and array expansions, because we almost never deal with spaces (SC2068, SC2086)
" * Allow 'which' instead of 'command -v' (SC2230)
" * Allow unquoted variables in for loop (SC2231)
" * Allow dollar signs in single quotes, e.g. ncap2 commands (SC2016)
" * Allow looping through single strings (SC2043)
" * Allow assigning commands to variables (SC2209)
" * Allow unquoted glob pattern assignments (SC2125)
" * Allow defining aliases with .bashrc variables (SC2139)
let g:ale_sh_shellcheck_options =
  \ '-e SC1090,SC1091,SC2002,SC2068,SC2086,SC2206,SC2207,SC2230,SC2231,SC2016,SC2041,SC2043,SC2209,SC2125,SC2139'
let g:syntastic_sh_shellcheck_args = g:ale_sh_shellcheck_options

" Asynchronous linting engine
if Active('ale')
  " Mappings (note that ALE works with buffer contents unlike syntastic)
  noremap <silent> <Leader>x :<C-u>call utils#ale_toggle(1)<CR>
  noremap <silent> <Leader>X :<C-u>call utils#ale_toggle(0)<CR>
  map ]x <Plug>(ale_next_wrap)
  map [x <Plug>(ale_previous_wrap)

  " Settings and checkers
  " https://github.com/koalaman/shellcheck
  " https://github.com/Kuniwak/vint
  " https://pypi.org/project/doc8/
  " Todo: consider chktex and pylint
  " Todo: Add mypy type annotation checker
  " https://mypy.readthedocs.io/en/stable/introduction.html
  let g:ale_linters = {
    \ 'config': [],
    \ 'fortran': ['gfortran'],
    \ 'help': [],
    \ 'json': ['jsonlint'],
    \ 'python': ['python', 'flake8'],
    \ 'rst': [],
    \ 'sh': ['shellcheck'],
    \ 'tex': ['lacheck'],
    \ 'text': [],
    \ 'vim': ['vint'],
    \ }
  let g:ale_sign_column_always = 1
  let g:ale_lint_on_save = 0
  let g:ale_lint_on_text_changed = 'normal'
  let g:ale_lint_on_insert_leave = 1
  let g:ale_lint_on_filetype_changed = 1
  let g:ale_lint_on_enter = 0
endif

" Easy-align
if Active('vim-easy-align')
  " Align map (nice mnemonic similar to gq for wrapping)
  " Note: Use <Left> to stick delimiter to left instead of right
  " Note: Use :EasyAlign<Delim>is, id, or in for shallowest, deepest, or no indentation
  " and use <Tab> in interactive mode to cycle through these.
  nmap ga <Plug>(EasyAlign)
  " Custom alignment delimiters. Include aligning case/esac blocks, chained && and
  " || symbols, and trailing comments (with two spaces, ignoring commented lines).
  let g:easy_align_delimiters = {
    \   ')': {'pattern': ')', 'stick_to_left': 1, 'left_margin': 0},
    \   '&': {'pattern': '\(&&\|||\)'},
    \   ';': {'pattern': ';\+'},
    \ }
  augroup easy_align
    au!
    au BufEnter * call extend(g:easy_align_delimiters, {
      \   'c': {'pattern': '\s' . (empty(Comment()) ? nr2char(0) : Comment())},
      \ })  " use null character if no comment char defined (never matches)
  augroup END
endif

" Test lines for easy-align (uncomment when testing)
" foo, baasrdaasdfdas, asdfjoijiaosdfjioadsjoias, asdfasfasf
" asdfasdf, " hello world this is me
" asdfasdfsad, asfdjioasdjfioasda, asdfsadfasdfsa, asfd
"
" asdfas = asdfsadjfoaisdjfa
" sdfasfiojasdjigoads = asdfasd = asdfasdfk
"
" apple    = red = asdfjioajfd
"    grasses += green = fdasjfaiofjaisofijasdf
"    sky     -= blue = asdf
"
" asdsfad && asdfiojaojdfjaosdf && afsdiojjioa
" asdf && asdfjiaosdf && asd
"
" {
"   hello: goodbye
"   asdfasdfasdf: asdjioaidfoajisdf,
"   foi: asdfoijiaosdfjoasiojfaojidsa
" }
"
" asdfa) bar ;;
" asfdijadfjsioaoidf) fooo ;;
" asdfijas) foo bar ;;
"
" asfdiojiasod " yoyoyo
" " ahoasdfjioa
" asdfasdas " hello
" asdfjioadijoadjofiadoisf " world

" Session saving
" Obsession .vimsession triggers update on BufEnter and VimLeavePre
if Active('vim-obsession') "must manually preserve cursor position
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


"-----------------------------------------------------------------------------"
" Syntax stuff
"-----------------------------------------------------------------------------"
" Fix syntax highlighting
" Starting from the previous comment is pretty darn reliable
command! Sync syntax sync ccomment
command! SyncLong syntax sync fromstart
command! SyncShort syntax sync minlines=0
noremap <Leader>y :<C-u>SyncShort<CR>
noremap <Leader>Y :<C-u>SyncLong<CR>

" GUI vim colors
" See: https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
" gruvbox, molokai, papercolor, fahrenheit, oceanicnext, ayu, abra, badwolf,
if has('gui_running')
  " colorscheme abra
  " colorscheme ayu
  " colorscheme gruvbox
  " colorscheme molokai
  " colorscheme monokai  " larger variation
  " colorscheme monokain  " slight variation of molokai
  " colorscheme moody
  " colorscheme nazca
  " colorscheme northland
  " colorscheme oceanicnext
  " colorscheme papercolor
  " colorscheme sierra
  " colorscheme tender
  " colorscheme turtles
  " colorscheme underwater-mod
  " colorscheme vilight
  " colorscheme vim-material
  " colorscheme vimbrains
  " colorscheme void
  colorscheme papercolor
  hi! link vimCommand Statement
  hi! link vimNotFunc Statement
  hi! link vimFuncKey Statement
  hi! link vimMap     Statement
  command! SchemePrev call utils#iter_colorschemes(0)
  command! SchemeNext call utils#iter_colorschemes(1)
endif

" Terminal vim colors
" For adding keywords, see: https://vi.stackexchange.com/a/11547/8084
" The url regex was copied from the one used for .tmux.conf
" Warning: Cannot use filetype specific elgl au Syntax *.tex commands to overwrite
" existing highlighting. An after/syntax/tex.vim file is necessary.
" Warning: The containedin just tries to *guess* what particular comment and
" string group names are for given filetype syntax schemes. Verify that the
" regexes will match using :Group with cursor over a comment. For example, had
" to change .*Comment to .*Comment.* since Julia has CommentL name
augroup override_syntax
  au!
  au Syntax * call s:keyword_setup()
  au BufRead * set conceallevel=2 concealcursor=
  au InsertEnter * highlight StatusLine ctermbg=Black ctermbg=White ctermfg=Black cterm=NONE
  au InsertLeave * highlight StatusLine ctermbg=White ctermbg=Black ctermfg=White cterm=NONE
augroup END
function! s:keyword_setup()
  " Warnings, errors, and shebangs
  if &filetype ==# 'vim'
    syn clear vimTodo  " vim instead uses the Stuff: syntax
  else
    syn match Todo '\C\%(WARNINGS\=\|ERRORS\=\|FIXMES\=\|TODOS\=\|NOTES\=\|XXX\)\ze:\=' containedin=.*Comment.*  " comments
    syn match Special '^\%1l#!.*$'  " shebangs
  endif
  " URL highlighting
  syn match customURL =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
  hi link customURL Underlined
  " Markdown headers
  " syn match markdownHeader =^# \zs#\+.*$= containedin=.*Comment.*
  " hi link markdownHeader Special
endfunction

" Filetype specific commands
" highlight link htmlNoSpell
highlight link pythonImportedObject Identifier
highlight BracelessIndent ctermfg=0 ctermbg=0 cterm=inverse

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
command! ColorTest call utils#color_test()
command! ColorGroups vert help group-name


"-----------------------------------------------------------------------------"
" Exit
"-----------------------------------------------------------------------------"
" Clear past jumps
" Don't want stuff from plugin files and the vimrc populating jumplist after statrup
" Simple way would be to use au BufRead * clearjumps
" But older versions of VIM have no 'clearjumps' command, so this is a hack
" see this post: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clear_jumps
  au!
  if exists(':clearjumps')
    au BufRead * clearjumps  "see help info on exists()
  else
    au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  endif
augroup END
" Clear writeable registers
" On some vim versions [] fails (is ideal, because removes from :registers), but '' will at least empty them out
" See thread: https://stackoverflow.com/questions/19430200/how-to-clear-vim-registers-effectively
" Warning: On cheyenne, get lalloc error when calling WipeReg, strange
if $HOSTNAME !~# 'cheyenne'
  command! WipeReg for i in range(34, 122) | silent! call setreg(nr2char(i), '') | silent! call setreg(nr2char(i), []) | endfor
  WipeReg
endif
doautocmd User BufferOverrides  " trigger buffer-local overrides for this file
noh  " turn off highlighting at startup
redraw!  " weird issue sometimes where statusbar disappears
