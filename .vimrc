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
let &t_te=''
let &t_Co=256
exe 'runtime autoload/repeat.vim'
if !exists('*repeat#set')  " only plugin that needs to be copied manually
  echohl WarningMsg
  echom 'Warning: vim-repeat unavailable, some features will be unavailable.'
  echohl None
endif

" Global settings
set encoding=utf-8
scriptencoding utf-8
let s:line_length = 88  " used with plugins below and in 'pep8' + 'black' files
let g:filetype_m = 'matlab'  " see $VIMRUNTIME/autoload/dist/ft.vim
let g:mapleader = "\<Space>"
set nocompatible  " always use the vim defaults
set autoindent  " indents new lines
set background=dark  " standardize colors -- need to make sure background set to dark, and should be good to go
set backspace=indent,eol,start  " backspace by indent - handy
set buflisted  " list all buffers by default
set complete+=k  " enable dictionary search through 'dictionary' setting
set completeopt-=preview  " use custom denops-popup-preview plugin
set confirm  " require confirmation if you try to quit
set cursorline
set diffopt=filler,context:5,foldcolumn:0,vertical  " vim-difference display options
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " make sure enabled, allows keycodes
set foldlevel=99
set foldlevelstart=99
set foldmethod=expr  " fold methods
set foldnestmax=10  " avoids weird things
set foldopen=tag,mark  " options for opening folds on cursor movement; disallow block
set guifont=Monaco:h12  " match iterm settings in macvim
set guioptions=M  " use default value
set history=100  " search history
set hlsearch incsearch  " show match as typed so far, and highlight as you go
set iminsert=0  " disable language maps (used for caps lock)
set lazyredraw
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set matchpairs=(:),{:},[:]  " exclude <> by default for use in comparison operators
set maxmempattern=50000  " from 1000 to 10000
set mouse=a  " mouse clicks and scroll allowed in insert mode via escape sequences
set noautochdir  " disable auto changing
set nobackup  " no backups when overwriting files, use tabline/statusline features
set noswapfile " no more swap files, instead use session
set noerrorbells visualbell t_vb=  " enable internal bell, t_vb= means nothing is shown on the window
set noinfercase ignorecase smartcase  " smartcase makes search case insensitive, unless has capital letter
set nospell spelllang=en_us spellcapcheck=  " spellcheck off by default
set nostartofline  " when switching buffers, doesn't move to start of line (weird default)
set notimeout timeoutlen=0  " wait forever when doing multi-key *mappings*
set nrformats=alpha  " never interpret numbers as 'octal'
set number numberwidth=4  " note old versions can't combine number with relativenumber
set pumwidth=10  " minimum popup menu width
set pumheight=10  " maximum popup menu height
set previewheight=30  " default preview window height
set redrawtime=5000  " sometimes takes a long time, let it happen
set relativenumber
set scrolloff=4
set sessionoptions=tabpages,terminal,winsize  " restrict session options for speed
set selectmode=  " disable 'select mode' slm, allow only visual mode for that stuff
set signcolumn=auto  " auto may cause lag after startup but unsure
set shell=/usr/bin/env\ bash
set shiftround  " round to multiple of shift width
set shiftwidth=2
set shortmess=atqcT  " snappy messages; 'a' does a bunch of common stuff
set showtabline=2
set softtabstop=2
set splitbelow
set splitright  " splitting behavior
set switchbuf=usetab,newtab  " when switching buffers use open tab
set tabpagemax=100  " allow opening shit load of tabs at once
set tabstop=2  " shoft default tabs
set tags=~/.vimtags,.vimtags,./.vimtags  " home, working dir, or file dir
set ttymouse=sgr  " different cursor shapes for different modes
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set updatetime=3000  " used for CursorHold autocmds and default is 4000ms
set undofile  " save undo history
set undolevels=500  " maximum undo level
set undodir=~/.vim_undo_hist  " ./setup enforces existence
set viminfo='100,:100,<100,@100,s10,f0  " commands, marks (e.g. jump history), exclude registers >10kB of text
set virtualedit=block  " allow cursor to go past line endings in visual block mode
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu
set wildmode=longest:list,full
let &g:colorcolumn = '89,121'  " global color columns
let &g:breakindent = 1  " global indent behavior
let &g:breakat = ' 	!*-+;:,./?'  " break at single instances of several characters
let &g:expandtab = 1  " global expand tab
if has('gui_running') | set guioptions=M | endif  " skip $VIMRUNTIME/menu.vim: https://vi.stackexchange.com/q/10348/8084)
if has('gui_running') | set guicursor+=a:blinkon0 | endif  " skip blinking
let &g:wildignore = ''
  \ . '*.pdf,*.doc,*.docs,*.page,*.pages,'
  \ . '*.svg,*.jpg,*.jpeg,*.png,*.gif,*.tiff,*.o,*.mod,*.pyc,'
  \ . '*.mp3,*.m4a,*.mk4,*.mp4,*.mov,*.flac,*.wav,'
  \ . '*.nc,*.zip,*.dmg,*.sw[a-z],*.DS_Store'

" File types for different unified settings
" Note: Here 'man' is usually used with superman 'vman', 'ale-preview' is used with
" :ALEDetail output, 'diff' is used with :GitGutterPreviewHunk output, 'git' is used
" with :Fugitive [show|diff] displays, 'fugitive' is used with other :Fugitive comamnds,
" and 'markdown.lsp_hover' is used with vim-lsp. The remaining filetypes are obvious.
let s:copy_filetypes = [
  \ 'bib', 'log', 'qf'
  \ ]  " for wrapping and copy toggle
let s:data_filetypes = [
  \ 'csv', 'dosini', 'json', 'jsonc', 'text'
  \ ]  " for just copy toggle
let s:lang_filetypes = [
  \ 'html', 'liquid', 'markdown', 'rst', 'tex'
  \ ]  " for wrapping and spell toggle
let s:popup_filetypes = [
  \ 'help', 'ale-preview', 'checkhealth', 'codi', 'diff', 'fugitive', 'fugitiveblame',
  \ ]  " for popup toggle
let s:popup_filetypes += [
  \ 'git', 'gitcommit', 'job', '*lsp-hover', 'man', 'mru', 'qf', 'undotree', 'vim-plug'
  \ ]

" Override settings and syntax, even buffer-local. The URL regex was copied
" from the one in .tmux.conf. See: https://vi.stackexchange.com/a/11547/8084
" Warning: Cannot use filetype specific au Syntax *.tex commands to overwrite
" existing highlighting. An after/syntax/tex.vim file is necessary.
" Warning: The containedin just tries to *guess* what particular comment and string
" group names are for given filetype syntax schemes (use :Group for testing).
augroup buffer_overrides
  au!
  au BufEnter * call s:buffer_overrides()
augroup END
function! s:buffer_overrides() abort
  setlocal concealcursor=
  setlocal conceallevel=2
  setlocal formatoptions=lrojcq
  setlocal nojoinspaces
  setlocal linebreak
  let &l:textwidth = s:line_length
  let &l:wrapmargin = 0
  syntax match customShebang /^\%1l#!.*$/  " shebang highlighting
  syntax match customHeader /^# \zs#\+.*$/ containedin=.*Comment.*
  syntax match customTodo /\C\%(WARNINGS\?\|ERRORS\?\|FIXMES\?\|TODOS\?\|NOTES\?\|XXX\)\ze:\?/ containedin=.*Comment.*  " comments
  syntax match customURL =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^' 	<>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
  highlight link customHeader Special
  highlight link customShebang Special
  highlight link customTodo Todo
  highlight link customURL Underlined
endfunction

" Flake8 ignore list (also apply to autopep8):
" Note: Keep this in sync with 'pep8' and 'black' file
" * Allow line breaks before binary operators (W503)
" * Allow imports after statements for jupytext files (E402)
" * Allow assigning lambda expressions instead of def (E731)
" * Allow the variable names 'l' and 'I' (E741)
" * Allow no docstring on public methods (e.g. overrides) (D102) (flake8-docstrings)
" * Allow empty docstring after e.g. __str__ (D105) (flake8-docstrings)
" * Allow empty docstring after __init__ (D107) (flake8-docstrings)
" * Allow single-line docstring with multi-line quotes (D200) (flake8-docstrings)
" * Allow no blank line after class docstring (D204) (flake8-docstrings)
" * Allow no blank line between summary and description (D205) (flake8-docstrings)
" * Allow backslashes in docstring (D301) (flake8-docstring)
" * Allow multi-line summary sentence of docstring (D400) (flake8-docstrings)
" * Allow imperative mood properties (D401) (flake8-docstring)
" * Do not allow multiple spaces before operators for easy-align segments (E221)
" * Do not allow multiple spaces after commas for easy-align segments (E241)
let s:flake8_ignore =
  \ 'W503,E402,E731,E741,'
  \ . 'D102,D107,D105,D200,D204,D205,D301,D400,D401'

" Shellcheck ignore list
" Todo: Add this to seperate linting configuration file?
" * Permite two space indent consistent with other languages (E003)
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
let s:shellcheck_ignore =
  \ 'SC1090,SC1091,SC2002,SC2068,SC2086,SC2206,SC2207,'
  \ . 'SC2230,SC2231,SC2016,SC2041,SC2043,SC2209,SC2125,SC2139'


"-----------------------------------------------------------------------------"
" Repair unexpected behavior
"-----------------------------------------------------------------------------"
" Escape repair needed when we allow h/l to change line num
augroup escape_fix
  au!
  au InsertLeave * normal! `^
augroup END

" Support cursor shapes. Note neither Ptmux escape codes (e.g. through 'vitality'
" plugin) or terminal overrides seem necessary in newer versions of tmux.
" See: https://stackoverflow.com/a/44473667/4970632 (outdated terminal overrides)
" See: https://vi.stackexchange.com/a/22239/8084 (outdated terminal overrides)
" See: https://vi.stackexchange.com/a/14203/8084 (outdated Ptmux sequences)
" See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
" See: https://www.reddit.com/r/vim/comments/24g8r8/italics_in_terminal_vim_and_tmux/
" call plug#('sjl/vitality.vim')  # outdated
" let g:vitality_always_assume_iterm = 1
let &t_SI = "\e[6 q"
let &t_SR = "\e[4 q"
let &t_EI = "\e[2 q"
let &t_ZH = "\e[3m"
let &t_ZR = "\e[23m"

" Stop cursor from changing when clicking on panes. Note this is no longer
" necessary since tmux handles FocusLost signal itself.
" See: https://github.com/sjl/vitality.vim/issues/29
" See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
" augroup cursor_fix
"   au!
"   au FocusLost * stopinsert
" augroup END

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
" * Z is save and quit shortcut, use for executing
" * Ctrl-p and Ctrl-n used for scrolling, remap these instead
" * Ctrl-a and Ctrl-x used for incrementing, use + and - instead
" * Turn off common normal mode issues
" * q and @ are for macros, instead reserve for quitting popup windows and tags map
" * ][ and [] can get hit accidentally
" * gt and gT replaced with <Tab> mappings
" * Ctrl-r is undo, remap this
for s:key in [
  \ '@', 'q', 'Q', 'K', 'ZZ', 'ZQ',
  \ '<C-r>', '<C-p>', '<C-n>', '<C-a>', '<C-x>',
  \ '<Delete>', '<Backspace>', '<CR>',
  \ '][', '[]', 'gt', 'gT',
  \ ]
  if empty(maparg(s:key, 'n'))
    exe 'nnoremap ' . s:key . ' <Nop>'
  endif
endfor

" Disable insert mode stuff
" * Ctrl-x used for scrolling or insert-mode complection, use autocomplete instead
" * Ctrl-l used for special 'insertmode' always-insert-mode option
" * Ctrl-h, Ctrl-d, Ctrl-t used for deleting and tabbing, but use backspace and tab
" * Ctrl-p, Ctrl-n used for menu cycling, but use Ctrl-, and Ctrl-.
" * Ctrl-b and Ctrl-z do nothing but insert literal char
augroup override_maps
  au!
  au BufEnter * inoremap <buffer> <S-Tab> <C-d>
augroup END
for s:key in [
  \ '<F1>', '<F2>', '<F3>', '<F4>',
  \ '<C-n>', '<C-p>', '<C-b>', '<C-z>', '<C-t>', '<C-d>', '<C-h>', '<C-l>',
  \ '<C-x><C-n>', '<C-x><C-p>', '<C-x><C-e>', '<C-x><C-y>',
  \ ]
  if empty(maparg(s:key, 'i'))
    exe 'inoremap ' . s:key . ' <Nop>'
  endif
endfor

" Enable left mouse click in visual mode to extend selection, normally impossible
" Note: Mark z used when defining and jumping in same line, mark x used for insert
" mode undo maps, and mark y used for visual mode maps.
" Todo: Modify enter-visual mode maps! See: https://stackoverflow.com/a/15587011/4970632
" Want to be able to *temporarily turn scrolloff to infinity* when
" enter visual mode, to do that need to map vi and va stuff.
nnoremap v myv
nnoremap V myV
nnoremap <C-v> my<C-v>
vnoremap v <Esc>myv
vnoremap V <Esc>myV
vnoremap <C-v> <Esc>my<C-v>
nnoremap gn gE/<C-r>"/<CR><Cmd>noh<CR>mygn
nnoremap gN W?<C-r>"?e<CR><Cmd>noh<CR>mygN
vnoremap <LeftMouse> <LeftMouse>mz`y<Cmd>exe 'normal! ' . visualmode()<CR>`z
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
" File and window utilities
"-----------------------------------------------------------------------------"
" Save or quit the current session
" Note: To avoid accidentally closing vim do not use mapped shortcuts. Instead
" require manual closure using :qall or :quitall.
" nnoremap <C-q> <Cmd>quitall<CR>
command! -nargs=? Autosave call switch#autosave(<args>)
noremap <Leader>A <Cmd>call switch#autosave()<CR>
nnoremap <C-s> <Cmd>call tabline#write()<CR>
nnoremap <C-w> <Cmd>call session#close_tab()<CR>
nnoremap <C-e> <Cmd>call session#close_window()<CR>

" Open file in current directory or some input directory
" Note: These are just convenience functions (see file#open_from) for details.
" Note: Use <C-x> to open in horizontal split and <C-v> to open in vertical split.
command! -nargs=* -complete=file Open call file#open_continuous(<q-args>)
command! -nargs=? -complete=file Existing call file#open_existing(<q-args>)
nnoremap <C-o> <Cmd>call file#open_from(0, 0)<CR>
nnoremap <F3>  <Cmd>call file#open_from(0, 1)<CR>
nnoremap <C-p> <Cmd>call file#open_from(1, 0)<CR>
nnoremap <C-y> <Cmd>call file#open_from(1, 1)<CR>
" nnoremap <C-g> <Cmd>Locate<CR>  " uses giant databsae from unix 'locate'
" nnoremap <C-g> <Cmd>Files<CR>  " see file#open_from(1, ...)
nnoremap <C-g> <Cmd>GFiles<CR>

" Related file utilities
" Pneumonic is 'inside' just like Ctrl + i map
" Note: Here :Rename is adapted from :Rename2 plugin
command! -nargs=? Abspath call file#print_abspath(<f-args>)
command! -nargs=* -complete=file -bang Rename call file#rename_to(<q-args>, '<bang>')
noremap <Leader>i <Cmd>call switch#localdir()<CR>
noremap <Leader>f <Cmd>call file#print_exists()<CR>
noremap <Leader>F <Cmd>exe 'Existing ' . expand('<cfile>')<CR>

" 'Execute' script with different options
" Note: Current idea is to use 'ZZ' for running entire file and 'Z<motion>' for
" running chunks of code. Currently 'Z' only defined for python so use workaround.
" Note: Critical to label these maps so one is not a prefix of another
" or else we can get a delay. For example do not define <Plug>Execute
map Z <Plug>ExecuteMotion
nmap ZZ <Plug>ExecuteFile1
nmap <Leader>z <Plug>ExecuteFile2
nmap <Leader>Z <Plug>ExecuteFile3
noremap <Plug>ExecuteFile1 <Nop>
noremap <Plug>ExecuteFile2 <Nop>
noremap <Plug>ExecuteFile3 <Nop>
noremap <expr> <Plug>ExecuteMotion utils#null_operator_expr()

" Refresh session or re-opening previous files
" Note: Here :History includes v:oldfiles and open buffers.
" Note: Here :Mru shows tracked files during session, will replace current buffer.
" noremap <C-r> <Cmd>History<CR>  " redundant with other commands
command! -nargs=0 Refresh call vim#source_config()
noremap <C-r> <Cmd>redraw!<CR>
noremap <Leader>e <Cmd>edit<CR>
noremap <Leader>E <Cmd>FZFMru<CR>
noremap <Leader>R <Cmd>Refresh<CR>

" Buffer management
" Note: Here :WipeBufs replaces :Wipeout plugin since has more sources
command! -nargs=0 ShowBufs call session#show_bufs()
command! -nargs=0 WipeBufs call session#wipe_bufs()
" noremap <Leader>w <Cmd>ShowBufs<CR>
noremap <Leader>q <Cmd>Windows<CR>
noremap <Leader>Q <Cmd>Buffers<CR>
noremap <Leader>W <Cmd>WipeBufs<CR>

" Tab selection and movement
nnoremap <Tab>' <Cmd>tabnext #<CR>
nnoremap <Tab>, <Cmd>exe 'tabnext -' . v:count1<CR>
nnoremap <Tab>. <Cmd>exe 'tabnext +' . v:count1<CR>
nnoremap <Tab>> <Cmd>call session#move_tab(tabpagenr() + v:count1)<CR>
nnoremap <Tab>< <Cmd>call session#move_tab(tabpagenr() - v:count1)<CR>
nnoremap <Tab>m <Cmd>call session#move_tab()<CR>
nnoremap <expr> <Tab><Tab> v:count ? v:count . 'gt' : '<Cmd>call session#jump_tab()<CR>'
for s:num in range(1, 10) | exe 'nnoremap <Tab>' . s:num . ' ' . s:num . 'gt' | endfor

" Window selection and creation
nnoremap <Tab>; <C-w><C-p>
nnoremap <Tab>j <C-w>j
nnoremap <Tab>k <C-w>k
nnoremap <Tab>h <C-w>h
nnoremap <Tab>l <C-w>l
nnoremap <Tab>- :split 
nnoremap <Tab>\ :vsplit 

" Moving screen and resizing windows
" Note: Disable old maps to force-remember the more consistent maps
nnoremap zh <Nop>
nnoremap zH <Nop>
nnoremap zl <Nop>
nnoremap zL <Nop>
nnoremap zt <Nop>
nnoremap zb <Nop>
nnoremap z. <Nop>
nnoremap <Tab>y zH
nnoremap <Tab>u zt
nnoremap <Tab>i z.
nnoremap <Tab>o zb
nnoremap <Tab>p zL
nnoremap <Tab>= <Cmd>vertical resize 90<CR>
nnoremap <Tab>0 <Cmd>exe 'resize ' . ((len(tabpagebuflist()) > 1 ? 0.75 : 1.0) * &lines)<CR>
nnoremap <Tab>( <Cmd>exe 'resize ' . (winheight(0) - 3 * v:count1)<CR>
nnoremap <Tab>) <Cmd>exe 'resize ' . (winheight(0) + 3 * v:count1)<CR>
nnoremap <Tab>_ <Cmd>exe 'resize ' . (winheight(0) - 5 * v:count1)<CR>
nnoremap <Tab>+ <Cmd>exe 'resize ' . (winheight(0) + 5 * v:count1)<CR>
nnoremap <Tab>[ <Cmd>exe 'vertical resize ' . (winwidth(0) - 5 * v:count1)<CR>
nnoremap <Tab>] <Cmd>exe 'vertical resize ' . (winwidth(0) + 5 * v:count1)<CR>
nnoremap <Tab>{ <Cmd>exe 'vertical resize ' . (winwidth(0) - 10 * v:count1)<CR>
nnoremap <Tab>} <Cmd>exe 'vertical resize ' . (winwidth(0) + 10 * v:count1)<CR>

" Literal tabs for particular filetypes.
" Note: For some reason must be manually enabled for vim
augroup tab_toggle
  au!
  au FileType vim,tex call switch#expandtab(0, 1)
  au FileType xml,make,text,gitconfig call switch#expandtab(1, 1)
augroup END
command! -nargs=? TabToggle call switch#expandtab(<args>)
nnoremap <Leader><Tab> <Cmd>call switch#expandtab()<CR>

" Popup window style adjustments with less-like shortcuts
" Todo: Understand and use fugitive popups more often, figure out how to open git
" diffs in new tab instead of filling current window, or restoring old window.
" Note: Fugitive applies the fugitive mapping 'dq' to git diff/show display windows
" (other d-mappings only work with file display) which interferes with scrolling.
let g:tags_skip_filetypes = s:popup_filetypes
let g:tabline_skip_filetypes = s:popup_filetypes
augroup popup_setup
  au!
  au TerminalWinOpen * call popup#popup_setup(1)
  au CmdwinEnter * call popup#cmd_setup()
  au FileType fugitiveblame call git#blame_setup()
  au FileType fugitive call git#git_setup()
  au FileType markdown.lsp-hover let b:lsp_hover_conceal = 1 | setlocal buftype=nofile | setlocal conceallevel=2
  au FileType undotree nmap <buffer> U <Plug>UndotreeRedo
  au FileType help call popup#help_setup()  " additional setup steps
  au FileType man call popup#man_setup()  " additional setup steps
  au FileType checkhealth silent! bdelete checkhealth | file checkhealth  " set name to checkhealth
  au User FugitivePager silent! nunmap <buffer> dq
  for s:ft in s:popup_filetypes
    let s:modifiable = s:ft ==# 'gitcommit'
    exe 'au FileType ' . s:ft . ' call popup#popup_setup(' . s:modifiable . ')'
  endfor
augroup END

" Interactive file jumping with grep commands
" Note: These redefinitions add flexibility to native fzf.vim commands,
" mnemonic for alternatives is 'local directory' or 'current file'. Also note Rg
" is faster so it gets lower case: https://unix.stackexchange.com/a/524094/112647
" command! -bang -nargs=* Af call utils#grep_ag(<bang>0, 2, 0, <f-args>)
" command! -bang -nargs=* Rf call utils#grep_rg(<bang>0, 2, 0, <f-args>)
command! -bang -nargs=* Ag call utils#grep_ag(<bang>0, 0, 0, <f-args>)
command! -bang -nargs=* Rg call utils#grep_rg(<bang>0, 0, 0, <f-args>)
command! -bang -nargs=* Al call utils#grep_ag(<bang>0, 1, 0, <f-args>)
command! -bang -nargs=* Rl call utils#grep_rg(<bang>0, 1, 0, <f-args>)
command! -bang -nargs=* A1 call utils#grep_ag(<bang>0, 0, 1, <f-args>)
command! -bang -nargs=* R1 call utils#grep_rg(<bang>0, 0, 1, <f-args>)
" nnoremap <Leader>n <Cmd>call utils#grep_pattern('ag', 1, 0)<CR>
" nnoremap <Leader>N <Cmd>call utils#grep_pattern('ag', 0, 0)<CR>
nnoremap <Leader>n <Cmd>call utils#grep_pattern('rg', 1, 0)<CR>
nnoremap <Leader>N <Cmd>call utils#grep_pattern('rg', 0, 0)<CR>

" Vim command windows, search windows, help windows, man pages, and 'cmd --help'
" Note: Mapping for 'repeat last search' is unnecessary (just press n or N)
nnoremap <Leader>. :<Up><CR>
nnoremap <Leader>; <Cmd>History:<CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ <Cmd>History/<CR>
nnoremap <Leader>? q/
nnoremap <Leader>v <Cmd>Helptags<CR>
nnoremap <Leader>V <Cmd>call popup#help_page()<CR>
nnoremap <Leader>B <Cmd>call popup#man_page()<CR>
nnoremap <Leader>m <Cmd>Maps<CR>
nnoremap <Leader>M <Cmd>Commands<CR>

" Cycle through wildmenu expansion with these keys
" Note: Mapping without <expr> will type those literal keys
cnoremap <expr> <F1> "\<Tab>"
cnoremap <expr> <F2> "\<S-Tab>"

" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" Warning: Do not map escape or cannot send iTerm-shortcuts with escape codes!
" Note: Must change local dir or use environment variable to make term pop up here:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
" silent! tnoremap <nowait> <Esc> <C-\><C-n>
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>, <Cmd>let $VIMTERMDIR=expand('%:p:h') \| terminal<CR>cd $VIMTERMDIR<CR>


"-----------------------------------------------------------------------------"
" Editing utilities
"-----------------------------------------------------------------------------"
" Jump to last changed text
" Note: F4 is mapped to Ctrl-m in iTerm
noremap <C-n> g;
noremap <F4> g,

" Jump to last jump
" Note: Account for karabiner arrow key maps
noremap <C-h> <C-o>
noremap <C-l> <C-i>
noremap <Left> <C-o>
noremap <Right> <C-i>

" Navigate to marks or lines with FZF
" Note: BLines should be used more, easier than '/' sometimes
noremap <Leader>" <Cmd>BLines<CR>
noremap <Leader>' <Cmd>Marks<CR>

" Default increment and decrement mappings
" Possibly overwritten by vim-speeddating
noremap + <C-a>
noremap - <C-x>

" Free up m keys, so ge/gE command belongs as single-keystroke
" words along with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Add 'g' version jumping keys that move by only alhanumeric characters (i.e.
" excluding dots, dashes, underscores). This is consistent with tmux.
for s:char in ['w', 'b', 'e', 'm']
  exe 'noremap g' . s:char . ' '
    \ . '<Cmd>let b:iskeyword = &l:iskeyword<CR>'
    \ . '<Cmd>setlocal iskeyword=@,48-57,192-255<CR>'
    \ . s:char . '<Cmd>let &l:iskeyword = b:iskeyword<CR>'
endfor

" Highlight marks. Use '"' or '[1-8]"' to set some mark, use '9"' to delete it,
" and use ' or [1-8]' to jump to a mark.
" let g:highlightmark_colors = ['magenta']
" let g:highlightmark_cterm_colors = [5]
command! -nargs=1 HighlightMark call highlightmark#highlight_mark(<q-args>)
command! -nargs=* RemoveHighlights call highlightmark#remove_highlights(<f-args>)
noremap <expr> ` "`" . nr2char(97 + v:count)
noremap <expr> ~ 'm' . nr2char(97 + v:count) . ':HighlightMark ' . nr2char(97 + v:count) . '<CR>'
noremap <Leader>~ <Cmd>RemoveHighlights<CR>

" Insert and mormal mode undo and redo. Also permit toggling blocks while in insert mode
" Note: Here use <C-g> prefix similar to comment insert, and 'break squence' is
" capital. Must use manual methods that actually remove inserted text.
" inoremap <C-g>u <C-o><C-r><C-g>u
" inoremap <C-g>U <C-g>u
inoremap <C-g>u <C-o>mx<C-o>u
inoremap <C-g>U <C-o><C-r><C-o>`x<Right>
nnoremap U <C-r>

" Record macro by pressing Q (we use lowercase for quitting popup windows) and disable
" multi-window recordings. The <Esc> below prevents q from retriggering a recording.
" au BufLeave,WinLeave * exe 'normal! qZq' | let b:recording = 0
nnoremap , @z
nnoremap <expr> Q b:recording
  \ ? 'q<Esc><Cmd>let b:recording = 0<CR>'
  \ : 'qz<Esc><Cmd>let b:recording = 1<CR>'
augroup recording_tests
  au!
  au BufEnter * let b:recording = 0
augroup END

" Reverse with command based on https://superuser.com/a/189956/506762
command! -range Reverse <line1>,<line2>call utils#reverse_lines()

" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
nnoremap cL mzi<CR><Esc>`z

" Use cc for s because use sneak plugin
nnoremap c<Backspace> <Nop>
nnoremap cc s
vnoremap cc s

" Swap characters or lines
nnoremap ch <Cmd>call insert#swap_characters(0)<CR>
nnoremap cl <Cmd>call insert#swap_characters(1)<CR>
nnoremap ck <Cmd>call insert#swap_lines(0)<CR>
nnoremap cj <Cmd>call insert#swap_lines(1)<CR>

" Pressing enter on empty line preserves leading whitespace
nnoremap o oX<Backspace>
nnoremap O OX<Backspace>

" Paste from the nth previously deleted or changed text. Use 'yp' to paste last yanked,
" unchanged text, because cannot use zero. Press <Esc> to remove count from motion.
" Note: Use [p or ]p for P and p but adjusting to the current indent
" Note: For visual paste without overwrite see https://stackoverflow.com/a/31411902/4970632
nnoremap yp "0p
nnoremap yP "0P
nnoremap <expr> p v:count == 0 ? 'p' : '<Esc>"' . v:count . 'p'
nnoremap <expr> P v:count == 0 ? 'P' : '<Esc>"' . v:count . 'P'
vnoremap p p<Cmd>let @+=@0<CR><Cmd>let @"=@0<CR>
vnoremap P P<Cmd>let @+=@0<CR><Cmd>let @"=@0<CR>
" vnoremap p "_dP  " flickers and does not include special v_p handling
" vnoremap P "_dP

" Yank until end of line, like C and D
nnoremap Y y$

" Joining counts improvement. Before 2J joined this line and next, now it
" means 'join the two lines below'
nnoremap <expr> J v:count > 1 ? 'JJ' : 'J'
nnoremap <expr> K 'k' . v:count . (v:count > 1  ? 'JJ' : 'J')

" Indenting counts improvement. Before 2> indented this line or this motion repeated,
" now it means 'indent multiple times'. Press <Esc> to remove count from motion.
nnoremap <expr> >> "\<Esc>" . repeat('>>', v:count1)
nnoremap <expr> << "\<Esc>" . repeat('<<', v:count1)
nnoremap <expr> > "\<Esc>" . format#indent_items_expr(0, v:count1)
nnoremap <expr> < "\<Esc>" . format#indent_items_expr(1, v:count1)

" Wrapping lines with arbitrary textwidth
command! -range -nargs=? WrapLines <line1>,<line2>call format#wrap_lines(<args>)
noremap <expr> gq '<Esc>' . format#wrap_lines_expr(v:count)

" Wrapping lines accounting for bullet indentation and with arbitrary textwidth
command! -range -nargs=? WrapItems <line1>,<line2>call format#wrap_items(<args>)
noremap <expr> gQ '<Esc>' . format#wrap_items_expr(v:count)

" Toggle highlighting
noremap <Leader>o <Cmd>call switch#hlsearch()<CR>

" Never save single-character deletions to any register
noremap x "_x
noremap X "_X

" Maps for throwaaway and clipboard register
" Note: Use g:peekaboo_prefix = '"' below so can still use registers with '"' press
map '' ""
noremap ' "_
noremap " "*

" Maps and commands for circular location-list scrolling
" Note: ALE populates the window-local loc list rather than the global quickfix list.
command! -bar -count=1 Lnext execute utils#wrap_cyclic(<count>, 'loc')
command! -bar -count=1 Lprev execute utils#wrap_cyclic(<count>, 'loc', 1)
command! -bar -count=1 Qnext execute utils#wrap_cyclic(<count>, 'qf')
command! -bar -count=1 Qprev execute utils#wrap_cyclic(<count>, 'qf', 1)
noremap [x <Cmd>Lprev<CR>
noremap ]x <Cmd>Lnext<CR>
noremap [X <Cmd>Qprev<CR>
noremap ]X <Cmd>Qnext<CR>

" Spellcheck (really is a builtin plugin, hence why it's in this section)
" Turn on for filetypes containing text destined for users
augroup spell_toggle
  au!
  let s:filetypes = join(s:lang_filetypes, ',')
  exe 'au FileType ' . s:filetypes . ' setlocal spell'
augroup END
command! SpellToggle call switch#spellcheck(<args>)
command! LangToggle call switch#spelllang(<args>)
nnoremap <Leader>l <Cmd>call switch#spellcheck()<CR>
nnoremap <Leader>L <Cmd>call switch#spelllang()<CR>

" Add and remove from dictionary
nnoremap <Leader>d zg
nnoremap <Leader>D zug

" Fix spelling under cursor auto or interactively
nnoremap <Leader>s 1z=
nnoremap <Leader>S z=

" Similar to ]s and [s but also corrects the word
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
nnoremap <silent> <Plug>forward_spell bh]s<Cmd>call insert#spell_apply(1)<CR>:call repeat#set("\<Plug>forward_spell")<CR>
nnoremap <silent> <Plug>backward_spell el[s<Cmd>call insert#spell_apply(0)<CR>:call repeat#set("\<Plug>backward_spell")<CR>
nmap ]d <Plug>forward_spell
nmap [d <Plug>backward_spell

" Capitalization stuff with g, a bit refined. Not currently used in normal mode, and
" fits better mnemonically (here y next to u, and t is for title case).
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
nnoremap <nowait> gu guiw
nnoremap <nowait> gU gUiw
nnoremap <silent> <Plug>cap1 ~h:call repeat#set("\<Plug>cap1")<CR>
nnoremap <silent> <Plug>cap2 mzguiw~h`z:call repeat#set("\<Plug>cap2")<CR>
vnoremap gy ~
vnoremap gt mzgu<Esc>`<~h
nmap gy <Plug>cap1
nmap gt <Plug>cap2

" Copy mode and conceal mode ('paste mode' accessible with 'g' insert mappings)
" Turn on for filetypes containing raw possibly heavily wrapped data
augroup copy_toggle
  au!
  let s:filetypes = join(s:data_filetypes + s:copy_filetypes, ',')
  exe 'au FileType ' . s:filetypes . ' call switch#copy(1, 1)'
  let s:filetypes = 'tmux'  " file subtypes that otherwise inherit copy toggling
  exe 'au FileType ' . s:filetypes . ' call switch#copy(0, 1)'
augroup END
command! -nargs=? CopyToggle call switch#copy(<args>)
command! -nargs=? ConcealToggle call switch#conceal(<args>)  " mainly just for tex
nnoremap <Leader>c <Cmd>call switch#copy()<CR>
nnoremap <Leader>C <Cmd>call switch#conceal()<CR>

" Caps lock toggle and insert mode map that toggles it on and off
inoremap <expr> <C-v> insert#lang_map()
cnoremap <expr> <C-v> insert#lang_map()

" Always open folds when starting files
" Note: For some reason vim ignores foldlevelstart
augroup fold_open
  au!
  au BufReadPost * silent! foldopen!
augroup END

" Open *all* folds under cursor, not just this one
" Open *all* folds recursively and update foldlevel
" Close *all* folds and update foldlevel
" Delete *all* manual folds
" noremap <expr> zo foldclosed('.') ? 'zA' : ''
noremap zO zR
noremap zC zM
noremap zD zE

" Jump between folds with more consistent naming
noremap [z zk
noremap ]z zj
noremap [Z [z
noremap ]Z ]z

" Unimpaired blank lines
noremap <Plug>BlankUp <Cmd>call insert#blank_up(v:count1)<CR>
noremap <Plug>BlankDown <Cmd>call insert#blank_down(v:count1)<CR>
map [e <Plug>BlankUp
map ]e <Plug>BlankDown

" Insert mode with paste toggling
" Note: switched easy-align mapping from ga to ge for consistency here
nnoremap <expr> ga insert#paste_mode() . 'a'
nnoremap <expr> gA insert#paste_mode() . 'A'
nnoremap <expr> gC insert#paste_mode() . 'c'
nnoremap <expr> gi insert#paste_mode() . 'i'
nnoremap <expr> gI insert#paste_mode() . 'I'
nnoremap <expr> go insert#paste_mode() . 'o'
nnoremap <expr> gO insert#paste_mode() . 'O'
nnoremap <expr> gR insert#paste_mode() . 'R'

" Forward delete by tabs
inoremap <expr> <Delete> insert#forward_delete()

" Insert comment similar to gc
" Todo: Add more control insert mappings?
inoremap <expr> <C-g>c comment#comment_insert()

" Section headers, dividers, and other information
" Todo: Improve title headers
nmap gc; <Plug>CommentBar
nnoremap <Plug>CommentBar <Cmd>call comment#header_line('-', 77, 0)<CR>:call repeat#set("\<Plug>CommentBar")<CR>
nnoremap gc: <Cmd>call comment#header_line('-', 77, 1)<CR>
nnoremap gc' <Cmd>call comment#header_incomment()<CR>
nnoremap gc" <Cmd>call comment#header_inline(5)<CR>
nnoremap gcA <Cmd>call comment#message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
nnoremap gcY <Cmd>call comment#message('Date: ' . strftime('%Y-%m-%d'))<CR>

" ReST section comment headers
" Warning: <Plug> name should not be subset of other name or results in delay!
nnoremap <Plug>SectionSingle <Cmd>call comment#section_line('=', 0)<CR>:silent! call repeat#set("\<Plug>SectionSingle")<CR>
nnoremap <Plug>SubsectionSingle <Cmd>call comment#section_line('-', 0)<CR>:silent! call repeat#set("\<Plug>SubsectionSingle")<CR>
nnoremap <Plug>SectionDouble <Cmd>call comment#section_line('=', 1)<CR>:silent! call repeat#set("\<Plug>SectionDouble")<CR>
nnoremap <Plug>SubsectionDouble <Cmd>call comment#section_line('-', 1)<CR>:silent! call repeat#set("\<Plug>SubsectionDouble")<CR>
nmap g= <Plug>SectionSingle
nmap g- <Plug>SubsectionSingle
nmap g+ <Plug>SectionDouble
nmap g_ <Plug>SubsectionDouble

" Search and find-replace stuff
" * Had issue before where InsertLeave ignorecase autocmd was getting reset; it was
"   because MoveToNext was called with au!, which resets all InsertLeave commands then adds its own
" * Make sure 'noignorecase' turned on when in insert mode, so *autocompletion* respects case.
augroup search_replace
  au!
  au InsertEnter * set noignorecase  " default ignore case
  au InsertLeave * set ignorecase
augroup END

" Search for non-ASCII escape chars
" Fails: https://stackoverflow.com/a/16987522/4970632
" noremap gE /[^\x00-\x7F]<CR>
" Works: https://stackoverflow.com/a/41168966/4970632
noremap gE /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Search for git commit conflict blocks
noremap gG /^[<>=\|]\{7}[<>=\|]\@!<CR>

" Run replacement on this line alone
" Note: This works recursively with the below maps
nmap <expr> \\ '\' . nr2char(getchar()) . 'al'

" Replace tabs with spaces
" Remove trailing whitespace (see https://stackoverflow.com/a/3474742/4970632)
noremap <expr> \<Tab> format#replace_regex_expr(
  \ 'Fixed tabs.',
  \ '\t', repeat(' ', &tabstop))
noremap <expr> \w format#replace_regex_expr(
  \ 'Removed trailing whitespace.',
  \ '\s\+\ze$', '')

" Delete empty lines
" Replace consecutive newlines with single newline
noremap <expr> \e format#replace_regex_expr(
  \ 'Removed empty lines.',
  \ '^\s*$\n', '')
noremap <expr> \E format#replace_regex_expr(
  \ 'Squeezed consecutive newlines.',
  \ '\(\n\s*\n\)\(\s*\n\)\+', '\1')

" Replace consecutive spaces on current line with one space,
" only if they're not part of indentation
noremap <expr> \s format#replace_regex_expr(
  \ 'Removed all whitespace.',
  \ '\S\@<=\(^ \+\)\@<! \+', '')
noremap <expr> \S format#replace_regex_expr(
  \ 'Squeezed redundant whitespace.',
  \ '\S\@<=\(^ \+\)\@<! \{2,}', ' ')

" Delete first-level and second-level commented text
" Note: This is useful when editing tex files
noremap <expr> \c format#replace_regex_expr(
  \ 'Removed all comments.',
  \ '\(^\s*' . comment#comment_char() . '.\+$\n\\|\s\+' . comment#comment_char() . '.\+$\)', '')
noremap <expr> \C format#replace_regex_expr(
  \ 'Removed second-level comments.',
  \ '\(^\s*' . comment#comment_char() . '\s*' . comment#comment_char() . '.\+$\n\\|\s\+'
  \ . comment#comment_char() . '\s*' . comment#comment_char() . '.\+$\)', '')

" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
noremap <expr> \- format#replace_regex_expr(
  \ 'Fixed long dashes.',
  \ '–', '--')
noremap <expr> \_ format#replace_regex_expr(
  \ 'Fixed wordbreak dashes.',
  \ '\(\w\)[-–] ', '\1')
noremap <expr> \' format#replace_regex_expr(
  \ 'Fixed single quotes.',
  \ '‘', '`', '’', "'")
noremap <expr> \" format#replace_regex_expr(
  \ 'Fixed double quotes.',
  \ '“', '``', '”', "''")

" Replace useless bibtex entries
" Previously localized to bibtex ftplugin but no major reason not to include here
noremap <expr> \x format#replace_regex_expr(
  \ 'Removed bibtex entries.',
  \ '^\s*\(abstract\|annotate\|copyright\|file\|keywords\|note\|shorttitle\|url\|urldate\)\s*=\s*{\_.\{-}},\?\n',
  \ '')
noremap <expr> \X format#replace_regex_expr(
  \ 'Removed bibtex entries.',
  \ '^\s*\(abstract\|annotate\|copyright\|doi\|file\|language\|keywords\|note\|shorttitle\|url\|urldate\)\s*=\s*{\_.\{-}},\?\n',
  \ '')


"-----------------------------------------------------------------------------"
" External plugins
"-----------------------------------------------------------------------------"
" Ad hoc enable or disable LSP for testing
" Note: Can also use switch#lsp() interactively
let s:enable_lsp = 1

" Functions to find runtimepath and install plugins
" See: https://github.com/junegunn/vim-plug/issues/32
function! s:plug_active(key) abort
  return &runtimepath =~# '/' . a:key . '\>'
endfunction
function! s:plug_find(regex)
  return filter(split(&runtimepath, ','), "v:val =~# '" . a:regex . "'")
endfunction
function! s:plug_local(path)
  let rtp = substitute(a:path, '[''"]', '', 'g')
  let rtp = expand(rtp)
  if !isdirectory(rtp)
    echohl WarningMsg
    echo "Warning: Path '" . rtp . "' not found."
    echohl None
  elseif &runtimepath !~# escape(rtp, '~')
    exe 'set rtp^=' . rtp
    exe 'set rtp+=' . rtp . '/after'
  endif
endfunction
command! -nargs=1 PlugFind echo join(s:plug_find(<q-args>), ', ')
command! -nargs=1 PlugLocal call s:plug_local(<args>)

" Initialize plugin manager. Note we no longer worry about compatibility
" because we can install everything from conda-forge, including vim and ctags.
" Note: See https://vi.stackexchange.com/q/388/8084 for a comparison of plugin
" managers. Currently use junegunn/vim-plug but could switch to Shougo/dein.vim
" (with haya14busa/dein-command.vim for commands instead of functions) which was
" derived from Shougo/neobundle.vim which was based on vundle. Just a bit faster.
call plug#begin('~/.vim/plugged')

" Inline code handling
" Note: Use :InlineEdit within blocks to open temporary buffer for editing. The buffer
" will have filetype-aware settings. See: https://github.com/AndrewRadev/inline_edit.vim
" call plug#('AndrewRadev/inline_edit.vim')

" Close unused buffers with Bdelete
" Note: Instead use custom utilities
" call plug#('Asheq/close-buffers.vim')  " e.g. Bdelete hidden, Bdelete select
" call plug#('artnez/vim-wipeout')  " utility overwritten with custom one

" Tags integration with easytags
" Note: Instead use custom plugin
" call plug#('xolox/vim-misc')  " dependency for easytags
" call plug#('xolox/vim-easytags')  " kind of old and not that useful honestly
" call plug#('ludovicchabant/vim-gutentags')  " slows shit down like crazy

" Folding speedups
" Warning: SimpylFold horribly slow on monde, instead use braceless
" call plug#('tmhedberg/SimpylFold')
call plug#('Konfekt/FastFold')
" let g:SimpylFold_docstring_preview = 0
" let g:SimpylFold_fold_docstring = 0
" let g:SimpylFold_fold_import = 0

" Navigation and interaction
" Should consider peekaboo once custom maps are allowed
" See: https://github.com/junegunn/vim-peekaboo/issues/84
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" call plug#('easymotion/vim-easymotion')  " extremely slow and overkill
" call plug#('kshenoy/vim-signature')  " experimental
call plug#('junegunn/vim-peekaboo')
call plug#('justinmk/vim-sneak')
let g:peekaboo_prefix = '"'
let g:peekaboo_window = 'vertical topleft 30new'

" Matching groups and searching
" Note: The vim-tags @#&*/?! mappings auto-integrate with vim-indexed-search
call plug#('andymass/vim-matchup')
call plug#('henrik/vim-indexed-search')
let g:matchup_matchparen_enabled = 1  " enable matchupt matching on startup
let g:matchup_transmute_enabled = 0  " issues in latex, use vim-succinct instead
let g:indexed_search_mappings = 1  " required even for <call plug#( mappings) to work
let g:indexed_search_colors = 0
let g:indexed_search_dont_move = 1  " irrelevant due to custom mappings
let g:indexed_search_line_info = 1  " show first and last line indicators
let g:indexed_search_max_lines = 100000  " increase from default of 3000 for log files
let g:indexed_search_shortmess = 1  " shorter message
let g:indexed_search_numbered_only = 1  " only show numbers
let g:indexed_search_n_always_searches_forward = 1  " after ? still search forward

" Useful panel plugins
" Note: For why to avoid these plugins see https://shapeshed.com/vim-netrw/
" call plug#('vim-scripts/EnhancedJumps')  " unnecessary
" call plug#('jistr/vim-nerdtree-tabs')  " unnecessary
" call plug#('scrooloose/nerdtree')  " unnecessary
" call plug#('preservim/tagbar')  " unnecessary
call plug#('mbbill/undotree')

" Various utilities
" call plug#('Shougo/vimshell.vim')  " first generation :terminal add-ons
" call plug#('Shougo/deol.nvim')  " second generation :terminal add-ons
call plug#('jez/vim-superman')  " add the 'vman' command-line tool
call plug#('tpope/vim-eunuch')  " shell utils like chmod rename and move
call plug#('tpope/vim-characterize')  " print character info (mnemonic is l for letter)
nmap gl <Plug>(characterize)

" Syntax checking and formatting
" Note: syntastic looks for checkers in $PATH, must be installed manually
" call plut#('scrooloose/syntastic')  " out of date: https://github.com/vim-syntastic/syntastic/issues/2319
call plug#('dense-analysis/ale')
call plug#('fisadev/vim-isort')
call plug#('Chiel92/vim-autoformat')
call plug#('tell-k/vim-autopep8')
call plug#('psf/black')

" Commenting stuff
" Note: tcomment_vim is nice minimal extension of vim-commentary, include explicit
" commenting and uncommenting and 'blockwise' commenting with g>b and g<b
" call plug#('scrooloose/nerdcommenter')
" call plug#('tpope/vim-commentary')  " too simple
call plug#('tomtom/tcomment_vim')

" Running tests and stuff
" Note: This works for every filetype (simliar to ale). Set up various
" shortcuts to test whole file, current test, next test, etc.
call plug#('vim-test/vim-test')

" Restoring sessions and recent files. Use 'vim-session' bash function to restore from
" .vimsession or start new session with that file, or 'vim' then ':so .vimsession'.
" Note: Here mru can be used to replace current file in window with files from recent
" popup list. Useful e.g. if lsp or fugitive plugins accidentally replace buffer.
" call plug#('thaerkh/vim-workspace')
" call plug#('gioele/vim-autoswap')  " deals with swap files automatically; no longer use them so unnecessary
" call plug#('xolox/vim-reload')  " easier to write custom reload function
call plug#('tpope/vim-obsession')  " sparse features on top of built-in session behavior
call plug#('yegappan/mru')  " most recent file
" let g:MRU_file = '~/.vim-mru-files'  " ignored for some reason

" Git wrappers and differencing tools
" vim-flog and gv.vim are heavyweight and lightweight commit viewing plugins
call plug#('airblade/vim-gitgutter')
call plug#('tpope/vim-fugitive')
call plug#('junegunn/gv.vim')  " view commit graphs with :GV
" call plug#('rbong/vim-flog')  " view commit graphs with :Flog
let g:fugitive_no_maps = 1

" Calculators and number stuff
" call plug#('vim-scripts/Toggle')  " toggling stuff on/off, modified this myself
" call plug#('triglav/vim-visual-increment')  " superceded by vim-speeddating
call plug#('sk1418/HowMuch')
call plug#('tpope/vim-speeddating')  " dates and stuff
call plug#('metakirby5/codi.vim')  " calculators
let g:HowMuch_no_mappings = 1
let g:speeddating_no_mappings = 1

" User interface selection stuff
" Note: 'Existing' opens ag/rg in existing open tab/window, similar to switchbuf=usetab.
" However :Buffers still fails even with fzf_buffers_jump=1 (with the below :Existing
" override it loads duplicate tabs, otherwise overwrites window). Not meant for tabs.
" Note: FZF can also do popup windows, similar to ddc/vim-lsp, but prefer windows
" centered on bottom. Note fzf#wrap is required to apply global settings and cannot
" rely on fzf#run return values (will result in weird hard-to-debug issues).
" See: https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
" See: https://www.reddit.com/r/vim/comments/9504rz/denite_the_best_vim_pluggin/e3pbab0/
" call plug#('Shougo/pum.vim')  " pum completion mappings, but mine are nicer
" call plug#('Shougo/unite.vim')  " first generation
" call plug#('Shougo/denite.vim')  " second generation
" call plug#('Shougo/ddu.vim')  " third generation
" call plug#('Shougo/ddu-ui-filer.vim')  " successor to Shougo/vimfiler and Shougo/defx.nvim
" call plug#('ctrlpvim/ctrlp.vim')  " replaced with fzf
call plug#('~/.fzf')  " fzf installation location, will add helptags and runtimepath
call plug#('junegunn/fzf.vim')  " this one depends on the main repo above, includes other tools
let g:fzf_buffers_jump = 1
let g:fzf_tags_command = 'ctags -R -f .vimtags'
let g:fzf_layout = {'down': '~33%'}  " for some reason ignored (version 0.29.0)
let g:fzf_action = {
  \ 'ctrl-m': 'Existing',
  \ 'ctrl-i': 'silent!',
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit'
  \ }

" Language server integration
" Note: Seems vim-lsp can both detect servers installed separately in $PATH with
" e.g. mamba install python-lsp-server (needed for jupyterlab-lsp) or install
" individually in ~/.local/share/vim-lsp-settings/servers/<server> using the
" vim-lsp-settings plugin commands :LspInstallServer and :LspUninstallServer
" (servers written in python are installed with pip inside 'venv' virtual environment
" subfolders). Most likely harmless if duplicate installations but try to avoid.
" call plug#('natebosch/vim-lsc')  " alternative lsp client
if s:enable_lsp
  call plug#('rhysd/vim-lsp-ale')  " prevents duplicate language servers, zero config needed!
  call plug#('prabirshrestha/vim-lsp')  " ddc-vim-lsp requirement
  call plug#('mattn/vim-lsp-settings')  " auto vim-lsp settings
	call plug#('rhysd/vim-healthcheck')  " plugin help
  let g:popup_preview_config = {'border': v:false, 'maxWidth': 80, 'maxHeight': 30}
endif

" Completion engines
" Note: Install pynvim with 'mamba install pynvim'
" Note: Install deno with brew on mac and with conda on linux
" Warning: denops.vim frequently upgrades requirements to most recent vim
" distribution but conda-forge version is slower to update. Workaround by pinning
" to older commits: https://github.com/vim-denops/denops.vim/commits/main
" call plug#('neoclide/coc.nvim")  " vscode inspired
" call plug#('ervandew/supertab')  " oldschool, don't bother!
" call plug#('ajh17/VimCompletesMe')  " no auto-popup feature
" call plug#('hrsh7th/nvim-cmp')  " lua version
" call plug#('Valloric/YouCompleteMe')  " broken, don't bother!
" call plug#('prabirshrestha/asyncomplete.vim')  " alternative engine
" call plug#('Shougo/neocomplcache.vim')  " first generation (no requirements)
" call plug#('Shougo/neocomplete.vim')  " second generation (requires lua)
" let g:neocomplete#enable_at_startup = 1  " needed inside plug#begin block
" call plug#('Shougo/deoplete.nvim')  " third generation (requires pynvim)
" call plug#('Shougo/neco-vim')  " deoplete dependency
" call plug#('roxma/nvim-yarp')  " deoplete dependency
" call plug#('roxma/vim-hug-neovim-rpc')  " deoplete dependency
" let g:deoplete#enable_at_startup = 1  " needed inside plug#begin block
if s:enable_lsp
  call plug#('Shougo/ddc.vim')  " fourth generation (requires pynvim and deno)
  call plug#('Shougo/ddc-ui-native')  " matching words near cursor
  call plug#('vim-denops/denops.vim', {'commit': 'e641727'})  " ddc dependency
endif

" Omnifunc sources not provided by engines
" See: https://github.com/Shougo/deoplete.nvim/wiki/Completion-Sources
" call plug#('neovim/nvim-lspconfig')  " nvim-cmp source
" call plug#('hrsh7th/cmp-nvim-lsp')  " nvim-cmp source
" call plug#('hrsh7th/cmp-buffer')  " nvim-cmp source
" call plug#('hrsh7th/cmp-path')  " nvim-cmp source
" call plug#('hrsh7th/cmp-cmdline')  " nvim-cmp source
" call plug#('deoplete-plugins/deoplete-jedi')  " old language-specific completion
" call plug#('Shougo/neco-syntax')  " old language-specific completion
" call plug#('Shougo/echodoc.vim')  " old language-specific completion
" call plug#('Shougo/ddc-nvim-lsp')  " language server protocoal completion for neovim only
" call plug#('Shougo/ddc-matcher_head')  " filter for heading match
" call plug#('Shougo/ddc-sorter_rank')  " filter for sorting rank
if s:enable_lsp
  call plug#('shun/ddc-vim-lsp')  " language server protocol completion for vim 8+
  call plug#('Shougo/ddc-around')  " matching words near cursor
  call plug#('matsui54/ddc-buffer')  " matching words from buffer (as in neocomplete)
  call plug#('LumaKernel/ddc-file')  " matching file names
  call plug#('tani/ddc-fuzzy')  " filter for fuzzy matching similar to fzf
  call plug#('matsui54/denops-popup-preview.vim')  " show previews during pmenu selection
endif

" Snippets and stuff
" Todo: Investigate further, but so far primitive vim-succinct snippets are fine
" call plug#('SirVer/ultisnips')  " fancy snippet actions
" call plug#('honza/vim-snippets')  " reference snippet files supplied to e.g. ultisnips
" call plug#('LucHermitte/mu-template')  " file template and snippet engine mashup, not popular
" call plug#('Shougo/neosnippet.vim')  " snippets consistent with ddc
" call plug#('Shougo/neosnippet-snippets')  " standard snippet library
" call plug#('Shougo/deoppet.nvim')  " next generation snippets (does not work in vim8)
call plug#('hrsh7th/vim-vsnip')  " snippets
call plug#('hrsh7th/vim-vsnip-integ')  " integration with ddc.vim

" Delimiters and stuff. Use vim-surround rather than vim-sandwich because key mappings
" are better and API is simpler. Only miss adding numbers to operators, otherwise
" feature set is same (e.g. cannot delete and change arbitrary text objects)
" See discussion: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
" See also: https://github.com/wellle/targets.vim/issues/225
" call plug#('wellle/targets.vim')
" call plug#('machakann/vim-sandwich')
call plug#('tpope/vim-surround')
call plug#('raimondi/delimitmate')

" Custom text objects (inner/outer selections)
" Todo: Generalized function converting text objects into navigation commands?
" Unsustainable to try to reproduce diverse plugin-supplied text objects as
" navigation commands... need to do this automatically!!!
" call plug#('bps/vim-textobj-python')  " not really ever used, just use indent objects
" call plug#('vim-scripts/argtextobj.vim')  " issues with this too
" call plug#('machakann/vim-textobj-functioncall')  " does not work
" call plug#('glts/vim-textobj-comment')  " does not work
call plug#('kana/vim-textobj-user')  " base requirement
call plug#('kana/vim-textobj-entire')  " entire file, object is 'e'
call plug#('kana/vim-textobj-line')  " entire line, object is 'l'
call plug#('kana/vim-textobj-indent')  " matching indentation, object is 'i' for deeper indents and 'I' for just contiguous blocks, and using 'a' includes blanklines
call plug#('sgur/vim-textobj-parameter')  " function parameter
let g:vim_textobj_parameter_mapping = '='  " avoid ',' conflict with latex

" Aligning things and stuff, use vim-easy-align because more tabular API is fugly AF
" and requires individual maps and docs suck. Also does not have built-in feature for
" ignoring comments or built-in aligning within motions or textobj blocks.
" call plug#('vim-scripts/Align')
" call plug#('tommcdo/vim-lion')
" call plug#('godlygeek/tabular')
call plug#('junegunn/vim-easy-align')

" Python and related utilities
" Todo: Test vim-repl, seems to support all REPLs, but only :terminal is supported.
" Todo: Test vimcmdline, claims it can also run in tmux pane or 'terminal emulator'.
" call plug#('sillybun/vim-repl')  " run arbitrary code snippets
" call plug#('jalvesaq/vimcmdline')  " run arbitrary code snippets
" call plug#('vim-scripts/Pydiction')  " just changes completeopt and dictionary and stuff
" call plug#('cjrh/vim-conda')  " for changing anconda VIRTUALENV but probably don't need it
" call plug#('klen/python-mode')  " incompatible with jedi-vim and outdated
" call plug#('ivanov/vim-ipython')  " replaced by jupyter-vim
" let g:pydiction_location = expand('~') . '/.vim/plugged/Pydiction/complete-dict'  " for pyDiction plugin
" call plug#('davidhalter/jedi-vim')  " use vim-lsp with mamba install python-lsp-server
" call plug#('jeetsukumaran/vim-python-indent-black')  " black style indentexpr, but too buggy
call plug#('Vimjas/vim-python-pep8-indent')  " pep8 style indentexpr, actually seems to respect black style?
call plug#('tweekmonster/braceless.vim')  " partial overlap with vim-textobj-indent, but these include header
call plug#('jupyter-vim/jupyter-vim')  " pair with jupyter consoles, support %% highlighting
call plug#('goerz/jupytext.vim')  " edit ipython notebooks
let g:braceless_block_key = 'm'  " captures if, for, def, etc.
let g:braceless_generate_scripts = 1  " see :help, required since we active in ftplugin
let g:jupyter_cell_separators = ['# %%', '# <codecell>']
let g:jupyter_mapkeys = 0
let g:jupytext_fmt = 'py:percent'

" TeX utilities with better syntax highlighting, better
" indentation, and some useful remaps. Also zotero integration.
" Note: For better configuration see https://github.com/lervag/vimtex/issues/204
" Note: Now use https://github.com/msprev/fzf-bibtex with vim integration inside
" autoload/tex.vim rather than unite versions. This is consistent with our choice
" of using fzf over the shuogo unite/denite/ddu plugin series.
" call plug#('twsh/unite-bibtex')  " python 3 version
" call plug#('msprev/unite-bibtex')  " python 2 version
" call plug#('lervag/vimtex')
" call plug#('chrisbra/vim-tex-indent')
" call plug#('rafaqz/citation.vim')

" ReST utilities
" Use == tables instead of fancy ++ tables
" call plug#('nvie/vim-rst-tables')
" call plug#('ossobv/vim-rst-tables-py3')
" call plug#('philpep/vim-rst-tables')
" noremap <silent> \s :python ReformatTable()<CR>
" let g:riv_python_rst_hl = 1
" call plug#('Rykka/riv.vim')

" Indent guides
" Note: Indentline completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes (which
" we need to stay transparent). Also indent-guides looks too busy and obtrusive.
" Instead use braceless.vim highlighting, appears only when cursor is there.
" call plug#('yggdroot/indentline')
" call plug#('nathanaelkane/vim-indent-guides')

" Syntax highlighting
" Note impsort sorts import statements and highlights modules using an after/syntax
" call plug#('numirias/semshi',) {'do': ':UpdateRemotePlugins'}  " neovim required
" call plug#('tweekmonster/impsort.vim') " conflicts with isort plugin, also had major issues
" call plug#('vim-python/python-syntax')  " originally from hdima/python-syntax, manually copied version with match case
" call plug#('MortenStabenau/matlab-vim')  " requires tmux installed
" call plug#('daeyun/vim-matlab')  " alternative but project seems dead
" call plug#('neoclide/jsonc.vim')  " vscode-style expanded json syntax, but overkill
call plug#('andymass/vim-matlab')  " recently updated vim-matlab fork from matchup author
call plug#('vim-scripts/applescript.vim')
call plug#('preservim/vim-markdown')
call plug#('tmux-plugins/vim-tmux')
call plug#('anntzer/vim-cython')
call plug#('tpope/vim-liquid')
call plug#('cespare/vim-toml')
call plug#('JuliaEditorSupport/julia-vim')
let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 1

" Colorful stuff
" Test: ~/.vim/plugged/colorizer/colortest.txt
" Note: colorizer very expensive so disabled by default and toggled with shortcut
" call plug#('altercation/vim-colors-solarized')
call plug#('flazz/vim-colorschemes')  " for macvim
call plug#('fcpg/vim-fahrenheit')  " for macvim
call plug#('KabbAmine/yowish.vim')  " for macvim
call plug#('lilydjwg/colorizer')  " only in macvim or when &t_Co == 256
let g:colorizer_nomap = 1
let g:colorizer_startup = 0

" Helpful stuff
" call plug#('dkarter/bullets.vim')  " list numbering but completely fails
" call plug#('ohjames/tabdrop')  " now apply similar solution with tabline#write
" call plug#('beloglazov/vim-online-thesaurus')  " completely broken: https://github.com/beloglazov/vim-online-thesaurus/issues/44
" call plug#('terryma/vim-multiple-cursors')  " article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" call plug#('vim-scripts/LargeFile')  " disable syntax highlighting for large files
call plug#('AndrewRadev/splitjoin.vim')  " single-line multi-line transition hardly every needed
let g:LargeFile = 1  " megabyte limit
let g:splitjoin_split_mapping = 'cK'
let g:splitjoin_join_mapping  = 'cJ'
let g:splitjoin_trailing_comma = 1
let g:splitjoin_normalize_whitespace = 1
let g:splitjoin_python_brackets_on_separate_lines = 1
"
" Custom plugins or forks and try to load locally if possible!
" Note: ^= prepends to list and += appends. Also previously added forks here but
" probably simpler/consistent to simply source files.
" Note: This needs to come after or else (1) vim-succinct will not be able to use
" textobj#user#plugin, (2) the initial statusline will possibly be incomplete, and
" (3) cannot wrap indexed-search plugin with tags file.
for s:name in [
  \ 'vim-succinct',
  \ 'vim-tags',
  \ 'vim-statusline',
  \ 'vim-tabline',
  \ 'vim-scrollwrapped',
  \ 'vim-toggle',
  \ ]
  let s:path_code = expand('~/software/' . s:name)
  let s:path_fork = expand('~/forks/' . s:name)
  if isdirectory(s:path_code)
    call s:plug_local(s:path_code)
  elseif isdirectory(s:path_fork)
    call s:plug_local(s:path_fork)
  else
    call plug#('lukelbd/' . s:name)
  endif
endfor

" End plugin manager. Also declares filetype plugin, syntax, and indent on
" Note every BufRead autocmd inside an ftdetect/filename.vim file is automatically
" made part of the 'filetypedetect' augroup (that's why it exists!).
call plug#end()


"-----------------------------------------------------------------------------"
" Plugin sttings
"-----------------------------------------------------------------------------"
" Additional mappings powered by Karabiner. Note that custom delimiters
" are declared inside vim-succinct plugin functions rather than here.
if s:plug_active('vim-succinct')
  let g:succinct_surround_prefix = '<C-s>'
  let g:succinct_snippet_prefix = '<C-e>'
  let g:succinct_prevdelim_map = '<F1>'
  let g:succinct_nextdelim_map = '<F2>'
endif

" Additional mappings for scrollwrapped accounting for Karabiner <C-j> --> <Down>, etc.
" Also add custom filetype log and plugin filetype ale-preview to list.
if s:plug_active('vim-scrollwrapped')
  let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + s:lang_filetypes
  noremap <Up> <Cmd>call scrollwrapped#scroll(winheight(0) / 4, 'u', 1)<CR>
  noremap <Down> <Cmd>call scrollwrapped#scroll(winheight(0) / 4, 'd', 1)<CR>
  noremap <Leader>w <Cmd>WrapToggle<CR>
endif

" Add maps for vim-tags command and use tags for default double bracket motion,
" except never overwrite potential single bracket mappings (e.g. help mode).
" Todo: Currently <C-t> shows contents of tag stack, consider copying? Also :Tags
" fzf command offers to create file, consider adapating for vim-tags?
if s:plug_active('vim-tags')
  augroup double_bracket
    au!
    au BufEnter * call s:bracket_maps()
  augroup END
  function! s:bracket_maps()  " defining inside autocommand not possible
    if empty(maparg('[')) && empty(maparg(']'))
      nmap <buffer> [[ <Plug>TagsBackwardTop
      nmap <buffer> ]] <Plug>TagsForwardTop
    endif
  endfunction
  " nnoremap <Leader>t <Cmd>ShowTags<CR>
  nnoremap <Leader>t <Cmd>BTags<CR>
  nnoremap <Leader>T <Cmd>Tags<CR>
  nnoremap <Leader>U <Cmd>UpdateTags<CR>
  let g:tags_subtop_filetypes = ['fortran']
  let g:tags_scope_kinds = {
    \ 'vim': 'afc',
    \ 'tex': 'bs',
    \ 'python': 'fcm',
    \ 'fortran': 'smfp',
    \ }
  let g:tags_skip_kinds = {
    \ 'tex': 'g',
    \ 'vim': 'mvD',
    \ }
endif

" Comment toggling stuff
" Note: For once we like some of the default maps but disable others.
if s:plug_active('tcomment_vim')
  nmap g>> g>c
  nmap g<< g<c
  let g:tcomment_opleader1 = 'gc'  " default is 'gc'
  let g:tcomment_mapleader1 = ''  " disables <C-_> insert mode maps
  let g:tcomment_mapleader2 = ''  " disables <Leader><Space> normal mode maps
  let g:tcomment_textobject_inlinecomment = ''  " default of 'ic' disables text object
  let g:tcomment_mapleader_uncomment_anyway = 'g<'
  let g:tcomment_mapleader_comment_anyway = 'g>'
endif

" Auto-complete delimiters
" Filetype-specific settings are in various ftplugin files
if s:plug_active('delimitmate')
  let g:delimitMate_expand_cr = 2  " expand even if it is not empty!
  let g:delimitMate_expand_space = 1
  let g:delimitMate_jump_expansion = 0
  let g:delimitMate_excluded_regions = 'String'  " by default is disabled inside, don't want that
endif

" Vim sneak motion
" Note: easymotion is way too complicated
if s:plug_active('vim-sneak')
  map s <Plug>Sneak_s
  map S <Plug>Sneak_S
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  map <F1> <Plug>Sneak_,
  map <F2> <Plug>Sneak_;
endif

" Vim marks in sign column
" Note: Requires mappings consistent with 'm' change
if s:plug_active('vim-signature')
  let g:SignatureMap = {
    \ 'Leader': '~',
    \ 'PlaceNextMark': '~,',
    \ 'ToggleMarkAtLine': '~.',
    \ 'PurgeMarksAtLine': '~-',
    \ 'DeleteMark': 'dm',
    \ 'PurgeMarks': '~<Space>',
    \ 'PurgeMarkers': '~<BS>',
    \ 'GotoNextLineAlpha': "']",
    \ 'GotoPrevLineAlpha': "'[",
    \ 'GotoNextSpotAlpha': '`]',
    \ 'GotoPrevSpotAlpha': '`[',
    \ 'GotoNextLineByPos': "]'",
    \ 'GotoPrevLineByPos': "['",
    \ 'GotoNextSpotByPos': ']`',
    \ 'GotoPrevSpotByPos': '[`',
    \ 'GotoNextMarker': ']-',
    \ 'GotoPrevMarker': '[-',
    \ 'GotoNextMarkerAny': ']=',
    \ 'GotoPrevMarkerAny': '[=',
    \ 'ListBufferMarks': '~/',
    \ 'ListBufferMarkers': '~?'
    \ }
endif

" Lsp integration settings
" Todo: Implement server-specific settings on top of defaults via 'vim-lsp-settings'
" plugin, e.g. try to run faster version of 'texlab'. Can use g:lsp_settings or
" vim-lsp-settings/servers files in .config. See: https://github.com/mattn/vim-lsp-settings
" Note: Servers are 'pylsp', 'bash-language-server', 'vim-language-server'. Tried
" 'jedi-language-server' but had issues on linux, and tried 'texlab' but was slow.
" Should install with mamba instead of vim-lsp-settings :LspInstallServer command.
" Note: LspDefinition accepts <mods> and stays in current buffer for local definitions,
" so below behavior is close to 'Existing': https://github.com/prabirshrestha/vim-lsp/pull/776
" Note: Highlighting under keywords required for reference jumping with [r and ]r but
" monitor for updates: https://github.com/prabirshrestha/vim-lsp/issues/655
" Note: Previously had issues with markdown preview display in popup windows but
" fixed. See this thread: https://github.com/prabirshrestha/vim-lsp/pull/1086
" Note: <C-]> definition jumping relies on builtin vim tags file jumping so fails.
" https://www.reddit.com/r/vim/comments/78u0av/why_gd_searches_instead_of_going_to_the/
if s:plug_active('vim-lsp')
  command! -nargs=0 LspStartServer call lsp#activate()
  noremap [r <Cmd>LspPreviousReference<CR>
  noremap ]r <Cmd>LspNextReference<CR>
  noremap <Leader>a <Cmd>call switch#lsp()<CR>
  noremap <Leader>r <Cmd>LspReferences<CR>
  noremap <Leader>& <Cmd>LspSignatureHelp<CR>
  noremap <Leader>* <Cmd>LspHover --ui=float<CR>
  noremap <Leader>% <Cmd>tabnew \| LspManage<CR><Cmd>file lspservers \| call popup#popup_setup(0)<CR>
  noremap <Leader>^ <Cmd>verbose LspStatus<CR>
  noremap <Leader>` <Cmd>CheckHealth<CR>
  nnoremap <CR> <Cmd>LspPeekDefinition<CR>
  nnoremap <Leader><CR> <Cmd>tab LspDefinition<CR>
  " nnoremap <CR> [<C-i>  " jump to vim definition
  " nnoremap \<Space> [I  " display occurences
  let g:lsp_ale_auto_enable_linter = v:false  " default is true
  let g:lsp_diagnostics_enabled = 0  " redundant with ale
  let g:lsp_diagnostics_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_code_action_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_highlight_enabled = 0  " used with [r and ]r
  let g:lsp_fold_enabled = 0  " not yet tested
  let g:lsp_hover_ui = 'preview'  " either 'float' or 'preview'
  let g:lsp_hover_conceal = 1  " enable markdown conceale
  let g:lsp_preview_fixup_conceal = -1  " fix window size in terminal vim
  let g:lsp_preview_float = 1  " floating window
  let g:lsp_preview_max_width = -1  " no maximum
  let g:lsp_preview_max_height = -1  " no maximum
  let g:lsp_signature_help_enabled = 1  " sigature help
  let g:lsp_signature_help_delay = 100  " milliseconds
  let g:lsp_settings_servers_dir = '~/.vim_lsp_settings/servers'
  let g:lsp_settings_global_settings_dir = '~/.vim_lsp_settings'
  " let g:lsp_inlay_hints_enabled = 1  " use inline hints
  " let g:lsp_settings = {
  " \   'pylsp': {'workspace_config': {'pylsp': {}}}
  " \   'texlab': {'workspace_config': {'texlab': {}}}
  " \   'julia-language-server': {'workspace_config': {'julia-language-server': {}}}
  " \   'bash-language-server': {'workspace_config': {'bash-language-server': {}}}
  " \ }
endif

" Lsp completion settings (see :help ddc-options). Note underscore seems to
" indicate all sources, used for global filter options, and filetype-specific
" options can be added with ddc#custom#patch_filetype(filetype, ...).
" Note: Previously had installation permissions issues so used various '--allow'
" flags to support. See: https://github.com/Shougo/ddc.vim/issues/120
" Note: Try to limit memory to 50M. Engine flags are passed to '--v8-flags' flag
" as of deno 1.17.0? See: https://stackoverflow.com/a/72499787/4970632
" Note: Use 'converters': [], 'matches': ['matcher_head'], 'sorters': ['sorter_rank']
" to speed up or disable fuzzy completion. See: https://github.com/Shougo/ddc-ui-native
" and https://github.com/Shougo/ddc.vim#configuration. Also for general config
" inspiration see https://www.reddit.com/r/neovim/comments/sm2epa/comment/hvv13pe/.
if s:plug_active('ddc.vim')
  let g:denops#server#deno_args = [
    \ '--allow-env', '--allow-net', '--allow-read', '--allow-write',
    \ '--v8-flags=--max-heap-size=1000,--max-old-space-size=1000',
    \ ]
  call ddc#custom#patch_global('ui', 'native')
  call ddc#custom#patch_global({
    \ 'sources': ['around', 'buffer', 'file', 'vim-lsp', 'vsnip'],
    \ 'sourceParams': {'around': {'maxSize': 500}},
    \ 'filterParams': {'matcher_fuzzy': {'splitMode': 'word'}},
    \ 'sourceOptions': {
    \   '_': {
    \     'matchers': ['matcher_fuzzy'],
    \     'sorters': ['sorter_fuzzy'],
    \     'converters': ['converter_fuzzy'],
    \   },
    \   'vim-lsp': {
    \     'mark': 'L',
    \     'maxItems': 15,
    \     'isVolatile': v:true,
    \     'forceCompletionPattern': '\\.|:|->',
    \   },
    \   'vsnip': {
    \     'mark': 'S',
    \     'maxItems': 5,
    \   },
    \   'around': {
    \     'mark': 'A',
    \     'maxItems': 5,
    \   },
    \   'buffer': {
    \     'mark': 'B',
    \     'maxItems': 5,
    \   },
    \   'file': {
    \     'mark': 'F',
    \     'isVolatile': v:true,
    \     'forceCompletionPattern': '\S/\S*',
    \     'maxItems': 5,
    \   },
    \ }})
  call ddc#enable()
endif

" Related popup and preview mappings
" Todo: Consider using Shuougo pum.vim but hard to implement <CR>/<Tab> features.
" Note: Enter is 'accept' only if we scrolled down, while tab always means 'accept'
" and default is chosen if necessary. See :h ins-special-special.
if s:plug_active('ddc.vim')
  augroup pum_navigation
    au!
    au BufEnter,InsertLeave * let b:popup_scroll = 0
  augroup END
  inoremap <expr> <C-y> insert#popup_scroll(-1)
  inoremap <expr> <C-t> insert#popup_scroll(1)
  inoremap <expr> <Up> insert#popup_scroll(-0.25)
  inoremap <expr> <Down> insert#popup_scroll(0.25)
  inoremap <expr> <C-k> insert#popup_scroll(-0.25)
  inoremap <expr> <C-j> insert#popup_scroll(0.25)
  inoremap <expr> <C-u> insert#popup_scroll(-0.5)
  inoremap <expr> <C-d> insert#popup_scroll(0.5)
  inoremap <expr> <C-b> insert#popup_scroll(-1.0)
  inoremap <expr> <C-f> insert#popup_scroll(1.0)
  inoremap <expr> <Space> insert#popup_reset()
    \ . (pumvisible() ? "\<C-e>" : '')
    \ . "\<C-]>\<Space>"
  inoremap <expr> <Backspace> insert#popup_reset()
    \ . (pumvisible() ? "\<C-e>" : '')
    \ . "\<Backspace>"
  inoremap <expr> <CR>
    \ pumvisible() ? b:popup_scroll ?
    \ "\<C-y>" . insert#popup_reset()
    \ : "\<C-e>\<C-]>\<C-g>u\<CR>"
    \ : "\<C-]>\<C-g>u\<CR>"
  inoremap <expr> <Tab>
    \ pumvisible() ? b:popup_scroll ?
    \ "\<C-y>" . insert#popup_reset()
    \ : "\<C-n>\<C-y>" . insert#popup_reset()
    \ : "\<C-]>\<Tab>"
endif

" Asynchronous linting engine
" Note: bashate is equivalent to pep8, similar to prettier and beautify
" for javascript and html, also tried shfmt but not available.
" Note: black is not a linter (try :ALEInfo) but it is a 'fixer' and can be used
" with :ALEFix black. Or can use the black plugin and use :Black of course.
" Note: chktex is awful (e.g. raises errors for any command not followed
" by curly braces) so lacheck is best you are going to get.
" https://github.com/Kuniwak/vint  # vim linter and format checker (pip install vim-vint)
" https://github.com/PyCQA/flake8  # python linter and format checker
" https://pypi.org/project/doc8/  # python format checker
" https://github.com/koalaman/shellcheck  # shell linter
" https://github.com/mvdan/sh  # shell format checker
" https://github.com/openstack/bashate  # shell format checker
" https://mypy.readthedocs.io/en/stable/introduction.html  # annotation checker
" https://github.com/creativenull/dotfiles/blob/1c23790/config/nvim/init.vim#L481-L487
if s:plug_active('ale')
  " map ]x <Plug>(ale_next_wrap)  " use universal circular scrolling
  " map [x <Plug>(ale_previous_wrap)  " use universal circular scrolling
  " noremap <Leader>! <Cmd>ALEDetail<CR>  " redundant with :lopen
  noremap <Leader>x <Cmd>lopen<CR>
  noremap <Leader>X <Cmd>call switch#ale()<CR>
  noremap <Leader>! <Cmd>ALEInfo<CR>
  let g:ale_linters = {
    \ 'config': [],
    \ 'fortran': ['gfortran'],
    \ 'help': [],
    \ 'json': ['jsonlint'],
    \ 'jsonc': ['jsonlint'],
    \ 'python': ['python', 'flake8'],
    \ 'rst': [],
    \ 'sh': ['shellcheck', 'bashate'],
    \ 'tex': ['lacheck'],
    \ 'text': [],
    \ 'vim': ['vint'],
    \ }
  let g:ale_completion_enabled = 0
  let g:ale_completion_autoimport = 0
  let g:ale_cursor_detail = 0
  let g:ale_disable_lsp = 1  " vim-lsp and ddc instead
  let g:ale_fixers = {'*': ['remove_trailing_lines', 'trim_whitespace']}
  let g:ale_hover_cursor = 0
  let g:ale_linters_explicit = 1
  let g:ale_lint_on_enter = 1
  let g:ale_lint_on_filetype_changed = 1
  let g:ale_lint_on_insert_leave = 1
  let g:ale_lint_on_save = 0
  let g:ale_lint_on_text_changed = 'normal'
  let g:ale_sign_column_always = 0
  let g:ale_sign_error = 'E>'
  let g:ale_sign_warning = 'W>'
  let g:ale_sign_info = 'I>'
  let g:ale_echo_msg_error_str = 'Err'
  let g:ale_echo_msg_info_str = 'Info'
  let g:ale_echo_msg_warning_str = 'Warn'
  let g:ale_echo_msg_format = '[%linter%] %code:% %s [%severity%]'
  let g:ale_python_flake8_options =  '--max-line-length=' . s:line_length . ' --ignore=' . s:flake8_ignore
  let g:ale_set_balloons = 0  " no ballons
  let g:ale_sh_bashate_options = '-i E003 --max-line-length=' . s:line_length
  let g:ale_sh_shellcheck_options = '-e ' . s:shellcheck_ignore
  let g:ale_virtualtext_cursor = 0  " no error shown here
endif

" Related plugins using similar exceptions
" Isort plugin docs:
" https://github.com/fisadev/vim-isort
" Black plugin docs:
" https://black.readthedocs.io/en/stable/integrations/editors.html?highlight=vim#vim
" Autopep8 plugin docs (or :help autopep8):
" https://github.com/tell-k/vim-autopep8 (includes a few global variables)
" Autoformat plugin docs:
" https://github.com/vim-autoformat/vim-autoformat (expands native 'autoformat' utilities)
if s:plug_active('ale')
  let g:autopep8_disable_show_diff = 1
  let g:autopep8_ignore = s:flake8_ignore
  let g:autopep8_max_line_length = s:line_length
  let g:black_linelength = s:line_length
  let g:black_skip_string_normalization = 1
  let g:vim_isort_python_version = 'python3'
  let g:vim_isort_config_overrides = {
    \ 'include_trailing_comma': 'true',
    \ 'force_grid_wrap': 0,
    \ 'multi_line_output': 3,
    \ 'line_length': s:line_length,
    \ }
  let g:formatdef_mpython = '"isort '
    \ . '--trailing-comma '
    \ . '--force-grid-wrap 0 '
    \ . '--multi-line 3 '
    \ . '--line-length ' . s:line_length
    \ . ' - | black --quiet '
    \ . '--skip-string-normalization '
    \ . '--line-length ' . s:line_length . ' - "'
  let g:formatters_python = ['mpython']  " multiple formatters
  let g:formatters_fortran = ['fprettify']
endif

" Vim test settings
" Run tests near cursor or throughout file
if s:plug_active('vim-test')
  let g:test#python#pytest#options = '--mpl --verbose'
  " noremap <Leader>[ <Cmd>TestLast<CR>
  noremap <Leader>[ <Cmd>TestNearest --mpl-generate<CR>
  noremap <Leader>] <Cmd>TestNearest<CR>
  noremap <Leader>{ <Cmd>TestLast<CR>
  noremap <Leader>} <Cmd>TestFile<CR>
  noremap <Leader>\ <Cmd>TestVisit<CR>
endif

" Undo tree settings
" Todo: Currently can only clear history with 'C' in active pane not externally. Need
" to submit PR for better command. See: https://github.com/mbbill/undotree/issues/158
" Note: This sort of seems against the anti-nerdtree anti-tagbar minimalist principal
" but think unique utilities that briefly pop up on left are exception.
if s:plug_active('undotree')
  let g:undotree_ShortIndicators = 1
  let g:undotree_RelativeTimestamp = 0
  noremap <Leader>u <Cmd>UndotreeToggle<CR>
endif

" Fugitive settings
" Note: This repairs inconsistent Gdiff redirect to Gdiffsplit. For some reason
" 'delcommand' fails (get undefined command errors in :Gdiff) so intead overwrite.
if s:plug_active('vim-fugitive')
  silent! delcommand Gdiffsplit
  command! -nargs=* Gsplit Gvsplit
  command! -nargs=* -bang Gdiffsplit Git diff <args>
  command! -nargs=* Gstatus Git status <args>
  noremap <Leader>I <Cmd>Git blame<CR>
  noremap <Leader>g <Cmd>GitGutterStageHunk<CR>
  noremap <Leader>G <Cmd>echom "Git add '" . @% . "'" \| Git add %<CR>
  noremap <Leader>h <Cmd>Git<CR>
  noremap <Leader>H <Cmd>Git reset %<CR>
  noremap <Leader>j <Cmd>exe 'Gdiff -- ' . @%<CR>
  noremap <Leader>J <Cmd>BCommits<CR>
  noremap <Leader>k <Cmd>exe 'Gdiff --staged -- ' . @%<CR>
  noremap <Leader>K <Cmd>Commits<CR>
endif

" Git gutter settings
" Note: Add refresh autocommands since gitgutter natively relies on CursorHold and
" therefore requires setting 'updatetime' to a small value (which is annoying).
" Note: Use custom command for toggling on/off. Older vim versions always show
" signcolumn if signs present, so GitGutterDisable will remove signcolumn.
if s:plug_active('vim-gitgutter')
  augroup gitgutter_refresh
    au!
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    exe 'au ' . cmds . ' * GitGutter'
  augroup END
  let g:gitgutter_map_keys = 0  " disable all maps yo
  let g:gitgutter_max_signs = -1  " maximum number of signs
  let g:gitgutter_preview_win_floating = 0  " disable preview window
  if !exists('g:gitgutter_enabled') | let g:gitgutter_enabled = 0 | endif  " disable startup
  noremap ]g <Cmd>exe v:count1 . 'GitGutterNextHunk'<CR>
  noremap [g <Cmd>exe v:count1 . 'GitGutterPrevHunk'<CR>
  noremap <Leader>O <Cmd>call switch#gitgutter()<CR>
  noremap <Leader>P <Cmd>GitGutterUndoHunk<CR>
  noremap <Leader>p <Cmd>GitGutterPreviewHunk \| wincmd j<CR>
endif

" Easy-align with delimiters for case/esac block parens and seimcolons, chained &&
" and || symbols, and trailing comments (with two spaces ignoring commented lines).
" See file empty.txt for easy-align tests.
" Note: Use <Left> to stick delimiter to left instead of right and use * to align
" by all delimiters instead of the default of 1 delimiter.
" Note: Use :EasyAlign<Delim>is, id, or in for shallowest, deepest, or no indentation
" and use <Tab> in interactive mode to cycle through these.
if s:plug_active('vim-easy-align')
  map ge <Plug>(EasyAlign)
  let g:easy_align_delimiters = {
    \   ')': {'pattern': ')', 'stick_to_left': 1, 'left_margin': 0},
    \   '&': {'pattern': '\(&&\|||\)'},
    \   ';': {'pattern': ';\+'},
    \ }
  augroup easy_align
    au!
    au BufEnter * let g:easy_align_delimiters['c'] = {
      \   'pattern': '\s' . (
      \     empty(comment#comment_char())
      \     ? nr2char(0) : comment#comment_char()
      \   )
      \ }
  augroup END
endif

" Configure codi (mathematical notepad) interpreter without history and settings
" Julia usage bug: https://github.com/metakirby5/codi.vim/issues/120
" Python history bug: https://github.com/metakirby5/codi.vim/issues/85
" Syncing bug (kludge is workaround): https://github.com/metakirby5/codi.vim/issues/106
if s:plug_active('codi.vim')
  augroup codi_mods
    au!
    au User CodiEnterPre call popup#codi_setup(1)
    au User CodiLeavePost call popup#codi_setup(0)
  augroup END
  command! -nargs=? CodiNew call popup#codi_new(<q-args>)
  noremap <Leader>= <Cmd>CodiNew<CR>
  noremap <Leader>+ <Cmd>Codi!!<CR>
  let g:codi#autocmd = 'None'
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 30
  let g:codi#log = ''  " enable when debugging
  let g:codi#sync = 0  " enable async mode
  let g:codi#interpreters = {
    \ 'python': {
        \ 'bin': ['python3', '-i', '-c', 'import readline; readline.set_auto_history(False)'],
        \ 'prompt': '^\(>>>\|\.\.\.\) ',
        \ 'quitcmd': 'exit()',
        \ 'preprocess': function('popup#codi_preprocess'),
        \ 'rephrase': function('popup#codi_rephrase'),
        \ },
    \ 'julia': {
        \ 'bin': ['julia', '-q', '-i', '--color=no', '--history-file=no'],
        \ 'prompt': '^\(julia>\|      \)',
        \ 'quitcmd': 'exit()',
        \ 'preprocess': function('popup#codi_preprocess'),
        \ 'rephrase': function('popup#codi_rephrase'),
        \ },
    \ }
endif

" Speed dating, support date increments
" Note: This overwrites default increment/decrement plugins
if s:plug_active('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
  noremap <Plug>SpeedDatingFallbackUp   <C-a>
  noremap <Plug>SpeedDatingFallbackDown <C-x>
endif

" The howmuch.vim plugin. Mnemonic for equation solving is just that parentheses
" show up in equations. Mnemonic for sums is the straight line at bottom of table.
" Options: AutoCalcReplace, AutoCalcReplaceWithSum, AutoCalcAppend, AutoCalcAppendWithEq, AutoCalcAppendWithSum, AutoCalcAppendWithEqAndSum
if s:plug_active('HowMuch')
  vmap <Leader>( <Plug>AutoCalcReplace
  vmap <Leader>) <Plug>AutoCalcAppendWithEq
  vmap <Leader>- <Plug>AutoCalcReplaceWithSum
  vmap <Leader>_ <Plug>AutoCalcAppendWithEqAndSum
endif

" Session saving and updating (the $ matches marker used in statusline)
" Obsession .vimsession activates vim-obsession BufEnter and VimLeavePre
" autocommands and saved session files call let v:this_session=expand("<sfile>:p")
" (so that v:this_session is always set when initializing with vim -S .vimsession)
if s:plug_active('vim-obsession')  " must manually preserve cursor position
  augroup session
    au!
    au VimEnter * if !empty(v:this_session) | exe 'Session ' . v:this_session | endif
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
  augroup END
  command! -nargs=* Session call session#init_session(<q-args>)
  noremap <Leader>$ <Cmd>Session<CR>
endif

"-----------------------------------------------------------------------------"
" Syntax stuff
"-----------------------------------------------------------------------------"
" Fix syntax highlighting. Leverage ctags integration to almost always fix syncing
" Note: This says get the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
command! -nargs=1 Sync syntax sync minlines=<args> maxlines=0  " maxlines is an *offset*
command! SyncStart syntax sync fromstart
command! SyncSmart exe 'Sync ' . max([0, line('.') - str2nr(tags#close_tag(line('w0'), 0, 0, 0)[1])])
noremap <Leader>y <Cmd>exe v:count ? 'Sync ' . v:count : 'SyncSmart'<CR>
noremap <Leader>Y <Cmd>SyncStart<CR>

" Color scheme iteration
" Todo: Support terminal vim? Need command to restore defaults, e.g. source tabline.
" Note: This is mainly used for GUI vim (otherwise use terminal themes). Ideas:
" https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
if has('gui_running')
  noremap <Leader>8 <Cmd>Colors<CR>
  noremap <Leader>9 <Cmd>SchemeNext<CR>
  noremap <Leader>0 <Cmd>SchemePrev<CR>
  command! SchemePrev call utils#wrap_colorschemes(0)
  command! SchemeNext call utils#wrap_colorschemes(1)
endif

" GUI overrides and colors
" Note: Should play with different schemes here
if has('gui_running')
  hi! link vimCommand Statement
  hi! link vimNotFunc Statement
  hi! link vimFuncKey Statement
  hi! link vimMap Statement
  colorscheme papercolor
  " abra  " good one
  " ayu  " good one
  " badwolf  " good one
  " fahrenheit  " good one
  " gruvbox  " good one
  " molokai  " good one
  " monokai  " larger variation
  " monokain  " slight variation of molokai
  " moody  " other one
  " nazca  " other one
  " northland  " other one
  " oceanicnext  " good one
  " papercolor  " good one
  " sierra  " other one
  " tender  " other one
  " turtles  " other one
  " underwater-mod  " other one
  " vilight  " other one
  " vim-material  " other one
  " vimbrains  " other one
  " void  " other one
endif

" Make terminal background same as main background
highlight Terminal ctermbg=NONE ctermfg=NONE

" Transparent conceal group so when conceallevel=0 elements revert to original colors
highlight Conceal ctermbg=NONE ctermfg=NONE ctermbg=NONE ctermfg=NONE

" Comment highlighting (only works in iTerm with minimum contrast enabled, else use gray)
highlight LineNR cterm=NONE ctermbg=NONE ctermfg=Black
highlight Comment ctermfg=Black cterm=NONE

" Special characters
highlight NonText ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE

" Matching parentheses
highlight Todo ctermfg=NONE ctermbg=Red
highlight MatchParen ctermfg=NONE ctermbg=Blue

" Cursor line or column highlighting using cterm color mapping
highlight CursorLine cterm=NONE ctermbg=Black
highlight CursorLineNR cterm=NONE ctermbg=Black ctermfg=White

" Color and sign column stuff
highlight ColorColumn cterm=NONE ctermbg=Gray
highlight SignColumn guibg=NONE cterm=NONE ctermfg=Black ctermbg=NONE

" Sneak and search highlighting
highlight Sneak ctermbg=DarkMagenta ctermfg=NONE
highlight Search ctermbg=Magenta ctermfg=NONE

" Popup menu
highlight Pmenu ctermbg=NONE ctermfg=White cterm=NONE
highlight PmenuSel ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE ctermfg=Black cterm=NONE

" Switch from LightColor to Color and DarkColor because ANSI has no control over light
highlight Type ctermbg=NONE ctermfg=DarkGreen
highlight Constant ctermbg=NONE ctermfg=Red
highlight Special ctermbg=NONE ctermfg=DarkRed
highlight PreProc ctermbg=NONE ctermfg=DarkCyan
highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold

" Error highlighting (use Red and Magenta for increased prominence)
highlight ALEErrorLine ctermfg=NONE ctermbg=NONE cterm=NONE
highlight ALEWarningLine ctermfg=NONE ctermbg=NONE cterm=NONE

" Python highlighting
highlight link pythonImportedObject Identifier
highlight BracelessIndent ctermfg=0 ctermbg=0 cterm=inverse

" Syntax helper commands
" Note: Mapping mnemonic for colorizer is # for hex string
command! -nargs=0 CurrentColor vert help group-name
command! -nargs=0 CurrentGroup call popup#syntax_group()
command! -nargs=? CurrentSyntax call popup#syntax_list(<q-args>)
command! -nargs=0 ShowColors call popup#colors_win()
command! -nargs=0 ShowPlugin call popup#plugin_win()
command! -nargs=0 ShowSyntax call popup#syntax_win()
noremap <Leader>1 <Cmd>CurrentGroup<CR>
noremap <Leader>2 <Cmd>CurrentSyntax<CR>
noremap <Leader>3 <Cmd>CurrentColor<CR>
noremap <Leader>4 <Cmd>ShowPlugin<CR>
noremap <Leader>5 <Cmd>ShowSyntax<CR>
noremap <Leader>6 <Cmd>ShowColors<CR>

"-----------------------------------------------------------------------------"
" Exit
"-----------------------------------------------------------------------------"
" Clear past jumps to ignore stuff from plugin files and vimrc
" Older versions of vim have no 'clearjumps' command so include below hack
" See: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clear_jumps
  au!
  if exists(':clearjumps')
    au BufRead * clearjumps  " see help info on exists()
  else
    au BufRead * let i = 0 | while i < 100 | mark ' | let i = i + 1 | endwhile
  endif
augroup END
doautocmd <nomodeline> BufEnter  " trigger buffer-local overrides for this file
nohlsearch  " turn off highlighting at startup
redraw!  " weird issue sometimes where statusbar disappears
