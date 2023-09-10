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

" Global settings
set encoding=utf-8
set nocompatible  " always use the vim defaults
scriptencoding utf-8
let g:refresh_times = get(g:, 'refresh_times', {'global': localtime()})
let g:filetype_m = 'matlab'  " see $VIMRUNTIME/autoload/dist/ft.vim
let g:mapleader = "\<Space>"  " see below <Leader> mappings
let s:linelength = 88  " see below configuration
set autoindent  " indents new lines
set background=dark  " standardize colors -- need to make sure background set to dark, and should be good to go
set backspace=indent,eol,start  " backspace by indent - handy
set buflisted  " list all buffers by default
set cmdheight=1  " increse to avoid pressing enter to continue 
set complete+=k  " enable dictionary search through 'dictionary' setting
set completeopt-=preview  " use custom denops-popup-preview plugin
set confirm  " require confirmation if you try to quit
set cursorline  " highlight cursor line
set diffopt=filler,context:5,foldcolumn:0,vertical  " vim-difference display options
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " make sure enabled, allows keycodes
set foldlevel=99  " disable folds
set foldlevelstart=99  " disable folds
set foldmethod=expr  " fold methods
set foldnestmax=10  " avoids weird folding issues
set foldopen=tag,mark  " opening folds on cursor movement, disallow block folds
set guifont=Monaco:h12  " match iterm settings in macvim
set guioptions=M  " default gui options
set history=100  " search history
set hlsearch  " highlight as you go
set iminsert=0  " disable language maps (used for caps lock)
set incsearch  " show match as typed so far
set lazyredraw  " skip redraws during macro and function calls
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set matchpairs=(:),{:},[:]  " exclude <> by default for use in comparison operators
set maxmempattern=50000  " from 1000 to 10000
set mouse=a  " mouse clicks and scroll allowed in insert mode via escape sequences
set noautochdir  " disable auto changing
set noautowrite  " disable auto write for file jumping commands (ask user instead)
set noautowriteall  " disable autowrite for :exit, :quit, etc. (ask user instead)
set nobackup  " no backups when overwriting files, use tabline/statusline features
set noswapfile " no more swap files, instead use session
set noerrorbells visualbell t_vb=  " enable internal bell, t_vb= means nothing is shown on the window
set noinfercase ignorecase smartcase  " smartcase makes search case insensitive, unless has capital letter
set nospell spelllang=en_us spellcapcheck=  " spellcheck off by default
set nostartofline  " when switching buffers, doesn't move to start of line (weird default)
set nowrap  " global wrap setting possibly overwritten by wraptoggle
set notimeout timeoutlen=0  " wait forever when doing multi-key *mappings*
set nrformats=alpha  " never interpret numbers as 'octal'
set number numberwidth=4  " note old versions can't combine number with relativenumber
set path=.  " used in various built-in searching utilities, file_in_path complete opt
set pumwidth=10  " minimum popup menu width
set pumheight=10  " maximum popup menu height
set previewheight=30  " default preview window height
set redrawtime=5000  " sometimes takes a long time, let it happen
set relativenumber  " relative line numbers for navigation
set restorescreen  " restore screen after exiting vim
set scrolloff=4  " screen lines above and below cursor
set sessionoptions=tabpages,terminal,winsize  " restrict session options for speed
set selectmode=  " disable 'select mode' slm, allow only visual mode for that stuff
set signcolumn=auto  " auto may cause lag after startup but unsure
set shell=/usr/bin/env\ bash
set shiftround  " round to multiple of shift width
set shiftwidth=2  " default 2 spaces
set shortmess=atqcT  " snappy messages, 'a' does a bunch of common stuff
set showtabline=2  " default 2 spaces
set softtabstop=2  " default 2 spaces
set splitbelow  " splitting behavior
set splitright  " splitting behavior
set switchbuf=useopen,usetab,newtab,uselast  " when switching buffers use open tab
set tabpagemax=100  " allow opening shit load of tabs at once
set tabstop=2  " default 2 spaces
set tags=.vimtags,./.vimtags  " home, working dir, or file dir
set tagstack  " auto-add to tagstack with :tag commands
set tagcase=ignore  " ignore case when matching paths
set tagfunc=lsp#tagfunc  " use lsp for tag stack navigation
set tagrelative  " paths in tags file are relative to location
set ttymouse=sgr  " different cursor shapes for different modes
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set updatetime=3000  " used for CursorHold autocmds and default is 4000ms
set undofile  " save undo history
set undolevels=500  " maximum undo level
set undodir=~/.vim_undo_hist  " ./setup enforces existence
set viminfo='100,:100,<100,@100,s10,f0  " commands, marks (e.g. jump history), exclude registers >10kB of text
set virtualedit=block  " allow cursor to go past line endings in visual block mode
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu  " command line completion
set wildmode=longest:list,full  " command line completion
let &g:colorcolumn = '89,121'  " global color columns
let &g:breakindent = 1  " global indent behavior
let &g:breakat = ' 	!*-+;:,./?'  " break at single instances of several characters
let &g:expandtab = 1  " global expand tab
let &l:shortmess .= &buftype ==# 'nofile' ? 'I' : ''  " internal --help utility
let &g:wildignore = join(tag#get_ignores(0, '~/.wildignore'), ',')
if has('gui_running') | set guioptions=M | endif  " skip $VIMRUNTIME/menu.vim: https://vi.stackexchange.com/q/10348/8084)
if has('gui_running') | set guicursor+=a:blinkon0 | endif  " skip blinking

" File types for different unified settings
" Note: Here 'man' is for custom man page viewing utils, 'ale-preview' is used with
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
let s:panel_filetypes = [
  \ 'help', 'ale-preview', 'checkhealth', 'codi', 'diff', 'fugitive', 'fugitiveblame',
  \ ]  " for popup toggle
let s:panel_filetypes += [
  \ 'git', 'gitcommit', 'netrw', 'job', '*lsp-hover', 'man', 'mru', 'qf', 'undotree', 'vim-plug'
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
  let &l:textwidth = s:linelength
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

" Set escape codes to restore screen after exiting
" See: :help restorescreen page
let &t_ti = "\e7\e[r\e[?47h"
let &t_te = "\e[?47l\e8"

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
" Note: Marks y and z are reserved for internal map utilities.
" Todo: Modify enter-visual mode maps! See: https://stackoverflow.com/a/15587011/4970632
" Want to be able to *temporarily turn scrolloff to infinity* when
" enter visual mode, to do that need to map vi and va stuff.
nnoremap v mzv
nnoremap V mzV
nnoremap gn gE/<C-r>"/<CR><Cmd>noh<CR>mzgn
nnoremap gN W?<C-r>"?e<CR><Cmd>noh<CR>mzgN
nnoremap <expr> <C-v> (&l:wrap ? '<Cmd>WrapToggle 0<CR>' : '') . 'mz<C-v>'
vnoremap <CR> <C-c>
vnoremap v <Esc>mzv
vnoremap V <Esc>mzV
vnoremap <expr> <C-v> '<Esc>' . (&l:wrap ? '<Cmd>WrapToggle 0<CR>' : '') . 'mz<C-v>'
vnoremap <LeftMouse> <LeftMouse>my`z<Cmd>exe 'normal! ' . visualmode()<CR>`y<Cmd>delmark y<CR>

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
" Highlighting stuff
"-----------------------------------------------------------------------------"
" Macvim color schemes
let s:colorscheme = 'papercolor'
" let s:colorscheme = 'abra'
" let s:colorscheme = 'ayu'
" let s:colorscheme = 'badwolf'
" let s:colorscheme = 'fahrenheit'
" let s:colorscheme = 'gruvbox'
" let s:colorscheme = 'molokai'  " also molokai/monokain
" let s:colorscheme = 'oceanicnext'
" let s:colorscheme = 'papercolor'

" Macvim syntax overrides
" Todo: Figure out whether to declare colorscheme here or at bottom
if has('gui_running')  " revisit these?
  highlight! link vimCommand Statement
  highlight! link vimNotFunc Statement
  highlight! link vimFuncKey Statement
  highlight! link vimMap Statement
  " exe 'noautocmd colorscheme ' . s:colorscheme
endif

" Make terminal background same as main background
highlight Terminal ctermbg=NONE ctermfg=NONE

" Use original colors for transparent conceal group
highlight Conceal ctermbg=NONE ctermfg=NONE

" Special characters
highlight NonText ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE

" Matching parentheses
highlight Todo ctermbg=Red ctermfg=NONE
highlight MatchParen ctermbg=Blue ctermfg=NONE

" Sneak and search highlighting
highlight Sneak ctermbg=DarkMagenta ctermfg=NONE
highlight Search ctermbg=Magenta ctermfg=NONE

" Popup menu highlighting
highlight Pmenu ctermbg=NONE ctermfg=White cterm=NONE
highlight PmenuSel ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE ctermfg=Black cterm=NONE

" Color and sign column stuff
highlight ColorColumn ctermbg=Gray cterm=NONE
highlight SignColumn ctermbg=NONE ctermfg=Black cterm=NONE

" Cursor line or column highlighting
" Use the cterm color mapping
highlight CursorLine ctermbg=Black cterm=NONE
highlight CursorLineNR ctermbg=Black ctermfg=White cterm=NONE

" Comment highlighting
" Only works in iTerm with minimum contrast enabled (else use gray)
highlight LineNR ctermbg=NONE ctermfg=Black cterm=NONE
highlight Comment ctermfg=Black cterm=NONE

" ANSI has no control over light
" Switch from light to main and color to dark
highlight Type ctermbg=NONE ctermfg=DarkGreen
highlight Constant ctermbg=NONE ctermfg=Red
highlight Special ctermbg=NONE ctermfg=DarkRed
highlight PreProc ctermbg=NONE ctermfg=DarkCyan
highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold

" Error highlighting
" Use Red or Magenta for increased prominence
highlight ALEErrorLine ctermfg=NONE ctermbg=NONE cterm=NONE
highlight ALEWarningLine ctermfg=NONE ctermbg=NONE cterm=NONE

" Python highlighting
highlight BracelessIndent cterm=inverse ctermfg=0 ctermbg=0
highlight link pythonImportedObject Identifier

" Repair highlighting. Leveraging ctags integration almost always works.
" Note: This says get the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
command! -nargs=1 Sync syntax sync minlines=<args> maxlines=0  " maxlines is an *offset*
command! SyncStart syntax sync fromstart
command! SyncSmart exe 'Sync ' . max([0, line('.') - str2nr(tags#close_tag(line('w0'), 0, 0, 0)[1])])
noremap <Leader>y <Cmd>exe v:count ? 'Sync ' . v:count : 'SyncSmart'<CR>
noremap <Leader>Y <Cmd>SyncStart<CR>

" Color scheme scrolling
" Todo: Figure out whether to declare colorscheme here or at top
" Todo: Support terminal vim? Need command to restore defaults, e.g. source tabline.
" Note: This is mainly used for GUI vim, otherwise use terminal themes. Some ideas:
" https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
command! SchemePrev call iter#jump_colorschemes(0)
command! SchemeNext call iter#jump_colorschemes(1)
noremap <Leader>8 <Cmd>Colors<CR>
noremap <Leader>9 <Cmd>SchemeNext<CR>
noremap <Leader>0 <Cmd>SchemePrev<CR>
augroup color_scheme
  au!
  exe 'au ColorScheme default,' . s:colorscheme . ' call vim#config_refresh(0)'
augroup END

" General syntax commands
" Note: Mapping mnemonic for colorizer is # for hex string
command! -nargs=0 CurrentGroup call vim#syntax_group()
command! -nargs=? CurrentSyntax call vim#syntax_list(<q-args>)
command! -nargs=0 GroupColors vert help group-name | call search('\*Comment') | normal! zt
command! -nargs=0 ShowColors call vim#runtime_colors()
command! -nargs=0 ShowPlugin call vim#runtime_ftplugin()
command! -nargs=0 ShowSyntax call vim#runtime_syntax()
noremap <Leader>1 <Cmd>CurrentGroup<CR>
noremap <Leader>2 <Cmd>CurrentSyntax<CR>
noremap <Leader>3 <Cmd>GroupColors<CR>
noremap <Leader>4 <Cmd>ShowPlugin<CR>
noremap <Leader>5 <Cmd>ShowSyntax<CR>
noremap <Leader>6 <Cmd>ShowColors<CR>
noremap <Leader>7 <Cmd>ColorToggle<CR>


"-----------------------------------------------------------------------------"
" File and window utilities
"-----------------------------------------------------------------------------"
" Save or quit the current session
" Note: To avoid accidentally closing vim do not use mapped shortcuts. Instead
" require manual closure using :qall or :quitall.
" nnoremap <C-q> <Cmd>quitall<CR>
command! -nargs=? Autosave call switch#autosave(<args>)
noremap <Leader>W <Cmd>call switch#autosave()<CR>
nnoremap <C-w> <Cmd>call window#close_tab()<CR>
nnoremap <C-e> <Cmd>call window#close_window()<CR>
nnoremap <C-s> <Cmd>call file#update()<CR>

" Open file in current directory or some input directory
" Note: These are just convenience functions (see file#open_from) for details.
" Note: Use <C-x> to open in horizontal split and <C-v> to open in vertical split.
command! -nargs=* -complete=file Open call file#open_continuous(<q-args>)
command! -nargs=? -complete=file Drop call file#open_drop(<q-args>)
nnoremap <C-o> <Cmd>call file#open_from(0, 0)<CR>
nnoremap <F3>  <Cmd>call file#open_from(0, 1)<CR>
nnoremap <C-p> <Cmd>call file#open_from(1, 0)<CR>
nnoremap <C-y> <Cmd>call file#open_from(1, 1)<CR>
" nnoremap <C-g> <Cmd>Locate<CR>  " uses giant databsae from unix 'locate'
" nnoremap <C-g> <Cmd>Files<CR>  " see file#open_from(1, ...)
nnoremap <C-g> <Cmd>GFiles<CR>

" Related file utilities
" Mnemonic is 'inside' just like Ctrl + i map
" Note: Here :Rename is adapted from the :Rename2 plugin. Usage is :Rename! <dest>
command! -nargs=* -complete=file -bang Rename call file#rename(<q-args>, '<bang>')
command! -nargs=? Abspath call file#print_abspath(<f-args>)
command! -nargs=? Localdir call switch#localdir(<args>)
noremap <Leader>i <Cmd>Abspath<CR>
noremap <Leader>I <Cmd>Localdir<CR>
noremap <Leader>p <Cmd>call file#print_exists()<CR>
noremap <Leader>P <Cmd>exe 'Drop ' . expand('<cfile>')<CR>

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
command! -nargs=? Scripts call vim#config_scripts(0, <q-args>)
command! -bang -nargs=? Refresh call vim#config_refresh(<bang>0, <q-args>)
noremap <Leader>e <Cmd>edit<CR>
noremap <Leader>E <Cmd>FZFMru<CR>
noremap <Leader>r <Cmd>redraw!<CR>
noremap <Leader>R <Cmd>Refresh<CR>

" Buffer management
" Note: Here :WipeBufs replaces :Wipeout plugin since has more sources
" Note: Currently no way to make :Buffers use custom opening command
command! -nargs=0 ShowBufs call window#show_bufs()
command! -nargs=0 WipeBufs call window#wipe_bufs()
noremap <C-r> <Cmd>ShowBufs<CR>
noremap <Leader>q <Cmd>Buffers<CR>
noremap <Leader>Q <Cmd>WipeBufs<CR>

" Tab selection and movement
nnoremap <Tab>' <Cmd>tabnext #<CR>
nnoremap <Tab>, <Cmd>exe 'tabnext -' . v:count1<CR>
nnoremap <Tab>. <Cmd>exe 'tabnext +' . v:count1<CR>
nnoremap <Tab>> <Cmd>call window#move_tab(tabpagenr() + v:count1)<CR>
nnoremap <Tab>< <Cmd>call window#move_tab(tabpagenr() - v:count1)<CR>
nnoremap <Tab>m <Cmd>call window#move_tab()<CR>
nnoremap <expr> <Tab><Tab> v:count ? v:count . 'gt' : '<Cmd>call window#jump_tab()<CR>'
" nnoremap <Tab><Tab> <Cmd>Windows<CR>
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

" Helper window style adjustments with less-like shortcuts
" Note: Tried 'FugitiveIndex' and 'FugitivePager' but kept getting confusing issues
" due to e.g. buffer not loaded before autocmds trigger. Instead use below.
let g:tags_skip_filetypes = s:panel_filetypes
let g:tabline_skip_filetypes = s:panel_filetypes
augroup panel_setup
  au!
  au TerminalWinOpen * call utils#panel_setup(1)
  au CmdwinEnter * call vim#cmdwin_setup() | call utils#panel_setup(0)
  au FileType markdown.lsp-hover let b:lsp_hover_conceal = 1 | setlocal buftype=nofile | setlocal conceallevel=2
  au FileType undotree nmap <buffer> U <Plug>UndotreeRedo
  au FileType help call vim#vim_setup()
  au FileType man call shell#man_setup()
  au FileType gitcommit call git#commit_setup()
  au FileType git,fugitive,fugitiveblame call git#fugitive_setup()
  for s:ft in s:panel_filetypes
    let s:modifiable = s:ft ==# 'gitcommit'
    exe 'au FileType ' . s:ft . ' call utils#panel_setup(' . s:modifiable . ')'
  endfor
augroup END

" Interactive file jumping with grep commands
" Note: Each command can be called with more than one argument to specify path.
" Note: These redefinitions add flexibility to native fzf.vim commands, mnemonic
" for alternatives is 'local directory' or 'current file'. Also note Rg is faster
" so it gets lower case: https://unix.stackexchange.com/a/524094/112647
command! -bang -nargs=+ Grep call grep#call_ag(<bang>0, 0, 0, <f-args>)
command! -bang -nargs=+ Ag call grep#call_ag(<bang>0, 0, 0, <f-args>)
command! -bang -nargs=+ Rg call grep#call_ag(<bang>0, 0, 0, <f-args>)
command! -bang -nargs=+ Ad call grep#call_ag(<bang>0, 1, 0, <f-args>)
command! -bang -nargs=+ Rd call grep#call_rg(<bang>0, 1, 0, <f-args>)
command! -bang -nargs=+ Af call grep#call_ag(<bang>0, 2, 0, <f-args>)
command! -bang -nargs=+ Rf call grep#call_rg(<bang>0, 2, 0, <f-args>)
command! -bang -nargs=+ A0 call grep#call_ag(<bang>0, 0, 1, <f-args>)
command! -bang -nargs=+ R0 call grep#call_rg(<bang>0, 0, 1, <f-args>)

" Convenience grep maps and commands
" Note: Default pattern for maps is previous search @/
" Note: Commands match the todo(), note(), error(), warning() functions in bashrc
" nnoremap <Leader>n <Cmd>call grep#call_grep('ag', 1, 0)<CR>
" nnoremap <Leader>N <Cmd>call grep#call_grep('ag', 0, 0)<CR>
nnoremap <Leader>n <Cmd>call grep#call_grep('rg', 1, 0)<CR>
nnoremap <Leader>N <Cmd>call grep#call_grep('rg', 0, 0)<CR>
command! -bang -nargs=* Debug call grep#call_ag(<bang>0, 0, 0, '^\s*ic(', <f-args>)
command! -bang -nargs=* Print call grep#call_ag(<bang>0, 0, 0, '^\s*print(', <f-args>)
command! -bang -nargs=* Note call grep#call_ag(<bang>0, 0, 0, '\<note:', <f-args>)
command! -bang -nargs=* Todo call grep#call_ag(<bang>0, 0, 0, '\<todo:', <f-args>)
command! -bang -nargs=* Error call grep#call_ag(<bang>0, 0, 0, '\<error:', <f-args>)
command! -bang -nargs=* Warning call grep#call_ag(<bang>0, 0, 0, '\<warning:', <f-args>)

" Vim command windows, search windows, help windows, man pages, and 'cmd --help'
" Note: Mapping for 'repeat last search' is unnecessary (just press n or N)
" Note: Mnemonic for 'repeat command' is that it is on same key as :hlsearch
" nnoremap <Leader>. :<C-r><Up><CR>
nnoremap <Leader>; <Cmd>History:<CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ <Cmd>History/<CR>
nnoremap <Leader>? q/
nnoremap <Leader>m <Cmd>Maps<CR>
nnoremap <Leader>M <Cmd>Commands<CR>
nnoremap <Leader>v <Cmd>Helptags<CR>
nnoremap <Leader>V <Cmd>call vim#vim_page()<CR>
nnoremap <Leader>, <Cmd>call shell#help_page(1)<CR>
nnoremap <Leader>. <Cmd>call shell#man_page(1)<CR>

" Cycle through wildmenu expansion with these keys
" Note: Mapping without <expr> will type those literal keys
cnoremap <expr> <F1> "\<Tab>"
cnoremap <expr> <F2> "\<S-Tab>"

" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" Mnemonic is that '!' matches the ':!' used to enter shell commands
" Warning: Do not map escape or cannot send iTerm-shortcuts with escape codes!
" Note: Must change local dir or use environment variable to make term pop up here:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>
" silent! tnoremap <nowait> <Esc> <C-\><C-n>
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>! <Cmd>let $VIMTERMDIR=expand('%:p:h') \| terminal<CR>cd $VIMTERMDIR<CR>


"-----------------------------------------------------------------------------"
" Editing utilities
"-----------------------------------------------------------------------------"
" Reverse using command
" See: https://superuser.com/a/189956/506762
command! -range Reverse <line1>,<line2>call edit#reverse_lines()

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

" Jump to marks or lines with FZF
" Note: :Marks does not handle file switching and :Jumps has an fzf error so override.
" noremap <Leader>" <Cmd>BLines<CR>
noremap <Leader>' <Cmd>call mark#fzf_marks()<CR>
noremap <Leader>" <Cmd>call mark#fzf_jumps()<CR>

" Free up m keys, so ge/gE command belongs as single-keystroke
" words along with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Add 'g' version jumping keys that move by only alphanumeric characters
" (i.e. excluding dots, dashes, underscores). This is consistent with tmux.
for s:char in ['w', 'b', 'e', 'm']
  exe 'noremap g' . s:char . ' '
    \ . '<Cmd>let b:iskeyword = &l:iskeyword<CR>'
    \ . '<Cmd>setlocal iskeyword=@,48-57,192-255<CR>'
    \ . s:char . '<Cmd>let &l:iskeyword = b:iskeyword<CR>'
endfor

" Insert and mormal mode undo and redo (see .vim/autoload/repeat.vim)
" Note: Here use <C-g> prefix similar to comment insert. Capital breaks the undo
" sequence. Tried implementing 'redo' but fails because history is lost after vim
" re-enters insert mode from the <C-o> command. Googled and there is no way to do it.
nnoremap U <C-r>
nnoremap <Plug>RepeatRedo <C-r>
inoremap <C-g>u <C-o>u
inoremap <C-g>U <C-g>u
" inoremap <CR> <C-]><C-g>u<CR>
" inoremap <C-g>u <C-o>my<C-o>u<C-o>:delmark y<CR>
" inoremap <C-g>U <C-o><C-r><C-o>`y<Right><Cmd>delmark y<CR>

" Specify alphabetic marks using counts (navigate with ]` and [`)
" Note: Uppercase marks unlike lowercase marks work between files and are saved in
" viminfo, so use them. Also numbered marks are mostly internal, can be configured
" to restore cursor position after restarting, also used in viminfo.
command! -nargs=* SetMarks call mark#set_marks(<f-args>)
command! -nargs=* DelMarks call mark#del_marks(<f-args>)
noremap ~ <Cmd>call mark#set_marks(utils#translate_count('m'))<CR>
noremap ` <Cmd>call mark#goto_mark(utils#translate_count('`'))<CR>
noremap <Leader>~ <Cmd>call mark#del_marks()<CR>
noremap <expr> <Leader>` exists('g:mark_recent') ? '<Cmd>call mark#goto_mark(g:mark_recent)' : ''

" Record macro by pressing Q (we use lowercase for quitting popup windows) and disable
" multi-window recordings. The <Esc> below prevents q from retriggering a recording.
" Note: Visual counts are ignored when starting recording. And <Esc>
nnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_count('q') : '')
nnoremap <expr> , '@' . utils#translate_count('@')
vnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_count('q') : '')
vnoremap <expr> , '@' . utils#translate_count('@')

" Specify numbered registers using count, or alphabetic registers with double press,
" otherwise use black hole register "_ for ' and clipboard register "* for '""
" Note: This relies on g:peekaboo_prefix = '"' below so that double '"' press opens up
" register seleciton panel. Also this way double press of "'" is similar, just no popup.
nnoremap <expr> ' (v:count ? '<Esc>' : '') . utils#translate_count('', '_', 0)
nnoremap <expr> " (v:count ? '<Esc>' : '') . utils#translate_count('q', '*', 1)
vnoremap <expr> ' utils#translate_count('', '_', 0)
vnoremap <expr> " utils#translate_count('q', '*', 1)

" Change text, specify registers with counts.
" Note: Uppercase registers are same as lowercase but saved in viminfo.
nnoremap <expr> c (v:count ? '<Esc>' : '') . utils#translate_count('') . 'c'
nnoremap <expr> C (v:count ? '<Esc>' : '') . utils#translate_count('') . 'C'
vnoremap <expr> c utils#translate_count('') . 'c'
vnoremap <expr> C utils#translate_count('') . 'C'

" Delete text, specify registers with counts (no more dd mapping)
" Note: Visual counts are ignored, and cannot use <Esc> because that exits visual mode
nnoremap <expr> d (v:count ? '<Esc>' : '') . utils#translate_count('') . 'd'
nnoremap <expr> D (v:count ? '<Esc>' : '') . utils#translate_count('') . 'D'
vnoremap <expr> d utils#translate_count('') . 'd'
vnoremap <expr> D utils#translate_count('') . 'D'

" Yank text, specify registers with counts (no more yy mappings)
" Note: Here 'Y' yanks to end of line, matching 'C' and 'D' instead of 'yy' synonym
nnoremap <expr> y (v:count ? '<Esc>' : '') . utils#translate_count('') . 'y'
nnoremap <expr> Y (v:count ? '<Esc>' : '') . utils#translate_count('') . 'y$'
vnoremap <expr> y utils#translate_count('') . 'y'
vnoremap <expr> Y utils#translate_count('') . 'y'

" Paste from the nth previously deleted or changed text.
" Note: For visual paste without overwrite see https://stackoverflow.com/a/31411902/4970632
nnoremap <expr> p (v:count ? '<Esc>' : '') . utils#translate_count('') . 'p'
nnoremap <expr> P (v:count ? '<Esc>' : '') . utils#translate_count('') . 'P'
vnoremap <expr> p (v:count ? '<Esc>' : '') . utils#translate_count('') . 'p<Cmd>let @+=@0 \| let @"=@0<CR>'
vnoremap <expr> P (v:count ? '<Esc>' : '') . utils#translate_count('') . 'P<Cmd>let @+=@0 \| let @"=@0<CR>'

" Never save single-character deletions to any register
" Without this register fills up quickly and history is lost
noremap x "_x
noremap X "_X
nnoremap cy "_s

" Swap characters or lines
" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
nnoremap cL myi<CR><Esc>`y<Cmd>delmark y<CR>
nnoremap ch <Cmd>call edit#swap_characters(0)<CR>
nnoremap cl <Cmd>call edit#swap_characters(1)<CR>
nnoremap ck <Cmd>call edit#swap_lines(0)<CR>
nnoremap cj <Cmd>call edit#swap_lines(1)<CR>

" Indenting counts improvement. Before 2> indented this line or this motion repeated,
" now it means 'indent multiple times'. Press <Esc> to remove count from motion.
nnoremap == <Esc>==
nnoremap == <Esc>==
nnoremap <expr> >> '<Esc>' . repeat('>>', v:count1)
nnoremap <expr> << '<Esc>' . repeat('<<', v:count1)
nnoremap <expr> > '<Esc>' . edit#indent_items_expr(0, v:count1)
nnoremap <expr> < '<Esc>' . edit#indent_items_expr(1, v:count1)

" Joining counts improvement. Before 2J joined this line and next but now it means
" 'join the two lines below'. Also wrap conjoin plugin around this.
nnoremap <expr> J '<Esc>' . (v:count + (v:count > 1)) . '<Cmd>call conjoin#joinNormal("J")<CR>'
nnoremap <expr> K 'k' . (v:count + (v:count > 1)) . '<Cmd>call conjoin#joinNormal("J")<CR>'
nnoremap <expr> gJ '<Esc>' . (v:count + (v:count > 1)) . '<Cmd>call conjoin#joinNormal("gJ")<CR>'
nnoremap <expr> gK 'k' . (v:count . (v:count > 1)) . '<Cmd>call conjoin#joinNormal("gJ")<CR>'

" Circulation location scrolling
" Note: ALE populates the window-local loc list rather than the global quickfix list.
command! -bar -count=1 Lnext execute iter#jump_cyclic(<count>, 'loc')
command! -bar -count=1 Lprev execute iter#jump_cyclic(<count>, 'loc', 1)
command! -bar -count=1 Qnext execute iter#jump_cyclic(<count>, 'qf')
command! -bar -count=1 Qprev execute iter#jump_cyclic(<count>, 'qf', 1)
noremap [x <Cmd>Lprev<CR>
noremap ]x <Cmd>Lnext<CR>
noremap [X <Cmd>Qprev<CR>
noremap ]X <Cmd>Qnext<CR>

" Wrapping lines with arbitrary textwidth
" Wrapping lines accounting for bullet indentation and with arbitrary textwidth
command! -range -nargs=? WrapLines <line1>,<line2>call edit#wrap_lines(<args>)
command! -range -nargs=? WrapItems <line1>,<line2>call edit#wrap_items(<args>)
noremap <expr> gq '<Esc>' . edit#wrap_lines_expr(v:count)
noremap <expr> gQ '<Esc>' . edit#wrap_items_expr(v:count)

" ReST section comment headers
" Warning: <Plug> name should not be subset of other name or results in delay!
nnoremap <Plug>DividerSingle <Cmd>call comment#insert_divider('=', 0)<CR>:silent! call repeat#set("\<Plug>DividerSingle")<CR>
nnoremap <Plug>SubdividerSingle <Cmd>call comment#insert_divider('-', 0)<CR>:silent! call repeat#set("\<Plug>SubdividerSingle")<CR>
nnoremap <Plug>DividerDouble <Cmd>call comment#insert_divider('=', 1)<CR>:silent! call repeat#set("\<Plug>DividerDouble")<CR>
nnoremap <Plug>SubdividerDouble <Cmd>call comment#insert_divider('-', 1)<CR>:silent! call repeat#set("\<Plug>SubdividerDouble")<CR>
nmap g= <Plug>DividerSingle
nmap g- <Plug>SubdividerSingle
nmap g+ <Plug>DividerDouble
nmap g_ <Plug>SubdividerDouble

" Section headers, dividers, and other information
" Todo: Improve title headers
nmap gc; <Plug>CommentHeader
nnoremap <Plug>CommentHeader <Cmd>call comment#header_line('-', 77, 0)<CR>:call repeat#set("\<Plug>CommentHeader")<CR>
nnoremap gc: <Cmd>call comment#header_line('-', 77, 1)<CR>
nnoremap gc' <Cmd>call comment#header_incomment()<CR>
nnoremap gc" <Cmd>call comment#header_inline(5)<CR>
nnoremap gcA <Cmd>call comment#header_message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
nnoremap gcD <Cmd>call comment#header_message('  Date: ' . strftime('%Y-%m-%d'))<CR>

" Insert comment similar to gc
" Todo: Add more control insert mappings?
inoremap <expr> <C-g>c comment#insert_char()

" Default increment and decrement mappings
" Possibly overwritten by vim-speeddating
noremap + <C-a>
noremap - <C-x>

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

" Add or remove from dictionary
nnoremap <Leader>d zg
nnoremap <Leader>D zug
" Fix spelling under cursor auto or interactively
nnoremap <Leader>s 1z=
nnoremap <Leader>S z=

" Similar to ]s and [s but also corrects the word
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
nnoremap <silent> <Plug>forward_spell bh]s<Cmd>call edit#spell_apply(1)<CR>:call repeat#set("\<Plug>forward_spell")<CR>
nnoremap <silent> <Plug>backward_spell el[s<Cmd>call edit#spell_apply(0)<CR>:call repeat#set("\<Plug>backward_spell")<CR>
nmap ]S <Plug>forward_spell
nmap [S <Plug>backward_spell

" Capitalization stuff with g, a bit refined. Not currently used in normal mode, and
" fits better mnemonically (here y next to u, and t is for title case).
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
nnoremap <nowait> gu guiw
nnoremap <nowait> gU gUiw
nnoremap <silent> <Plug>cap1 ~h:call repeat#set("\<Plug>cap1")<CR>
nnoremap <silent> <Plug>cap2 myguiw~h`y<Cmd>delmark y<CR>:call repeat#set("\<Plug>cap2")<CR>
vnoremap gy ~
vnoremap gt gu<Esc>`<~h
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
inoremap <expr> <C-v> edit#lang_map()
cnoremap <expr> <C-v> edit#lang_map()

" Always open folds when starting files
" Note: For some reason vim ignores foldlevelstart
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

" Blank lines inspired by 'unimpaired'
noremap <Plug>BlankUp <Cmd>call edit#blank_up(v:count1)<CR>
noremap <Plug>BlankDown <Cmd>call edit#blank_down(v:count1)<CR>
map [e <Plug>BlankUp
map ]e <Plug>BlankDown

" Enter insert mode above or below.
" Pressing enter on empty line preserves leading whitespace
nnoremap o oX<Backspace>
nnoremap O OX<Backspace>

" Popup menu and preview window scrolling
" This should work with or without ddc
augroup pum_navigation
  au!
  au BufEnter,InsertLeave * let b:scroll_state = 0
augroup END
noremap <expr> <C-k> iter#scroll_count(-0.25)
noremap <expr> <C-j> iter#scroll_count(0.25)
noremap <expr> <C-u> iter#scroll_count(-0.5)
noremap <expr> <C-d> iter#scroll_count(0.5)
noremap <expr> <C-b> iter#scroll_count(-1.0)
noremap <expr> <C-f> iter#scroll_count(1.0)
inoremap <expr> <C-k> iter#scroll_count(-0.25)
inoremap <expr> <C-j> iter#scroll_count(0.25)
inoremap <expr> <C-u> iter#scroll_count(-0.5)
inoremap <expr> <C-d> iter#scroll_count(0.5)
inoremap <expr> <C-b> iter#scroll_count(-1.0)
inoremap <expr> <C-f> iter#scroll_count(1.0)

" Popup menu selection shortcuts
" Todo: Consider using Shuougo pum.vim but hard to implement <CR>/<Tab> features.
" Note: Enter is 'accept' only if we scrolled down, while tab always means 'accept'
" and default is chosen if necessary. See :h ins-special-special.
inoremap <expr> <Space> iter#scroll_reset()
  \ . (pumvisible() ? "\<C-e>" : '')
  \ . "\<C-]>\<Space>"
inoremap <expr> <Backspace> iter#scroll_reset()
  \ . (pumvisible() ? "\<C-e>" : '')
  \ . "\<Backspace>"
inoremap <expr> <CR>
  \ pumvisible() ? b:scroll_state ?
  \ "\<C-y>" . iter#scroll_reset()
  \ : "\<C-e>\<C-]>\<C-g>u\<CR>"
  \ : "\<C-]>\<C-g>u\<CR>"
inoremap <expr> <Tab>
  \ pumvisible() ? b:scroll_state ?
  \ "\<C-y>" . iter#scroll_reset()
  \ : "\<C-n>\<C-y>" . iter#scroll_reset()
  \ : "\<C-]>\<Tab>"

" Insert mode with paste toggling
" Note: switched easy-align mapping from ga to ge for consistency here
nnoremap <expr> ga edit#paste_mode() . 'a'
nnoremap <expr> gA edit#paste_mode() . 'A'
nnoremap <expr> gC edit#paste_mode() . 'c'
nnoremap <expr> gi edit#paste_mode() . 'i'
nnoremap <expr> gI edit#paste_mode() . 'I'
nnoremap <expr> go edit#paste_mode() . 'o'
nnoremap <expr> gO edit#paste_mode() . 'O'
nnoremap <expr> gR edit#paste_mode() . 'R'

" Forward delete by tabs
inoremap <expr> <Delete> edit#forward_delete()

" Search and find-replace stuff. Ensure 'noignorecase' turned on when
" in insert mode, so that popup menu autocompletion respects input case.
" Note: Previously had issue before where InsertLeave ignorecase autocmd was getting
" reset because MoveToNext was called with au!, which resets InsertLeave commands.
augroup search_replace
  au!
  au InsertEnter * set noignorecase  " default ignore case
  au InsertLeave * set ignorecase
augroup END

" Search highlight toggle
" Note: This just does 'set hlsearch!' and prints a message
noremap <Leader>o <Cmd>call switch#hlsearch()<CR>

" Search for non-ASCII escape chars
" See: https://stackoverflow.com/a/41168966/4970632
noremap gE /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Search for git commit conflict blocks
" Note: See also [f and ]f commands
noremap gG /^[<>=\|]\{7}[<>=\|]\@!<CR>

" Run replacement on this line alone
" Note: This works recursively with the below maps
nmap <expr> \\ '\' . nr2char(getchar()) . 'al'

" Replace tabs with spaces
" Remove trailing whitespace (see https://stackoverflow.com/a/3474742/4970632)
noremap <expr> \<Tab> edit#replace_regex_expr(
  \ 'Fixed tabs.',
  \ '\t', repeat(' ', &tabstop))
noremap <expr> \w edit#replace_regex_expr(
  \ 'Removed trailing whitespace.',
  \ '\s\+\ze$', '')

" Delete empty lines
" Replace consecutive newlines with single newline
noremap <expr> \e edit#replace_regex_expr(
  \ 'Squeezed consecutive newlines.',
  \ '\(\n\s*\n\)\(\s*\n\)\+', '\1')
noremap <expr> \E edit#replace_regex_expr(
  \ 'Removed empty lines.',
  \ '^\s*$\n', '')

" Replace consecutive spaces on current line with one space,
" only if they're not part of indentation
noremap <expr> \s edit#replace_regex_expr(
  \ 'Squeezed redundant whitespace.',
  \ '\S\@<=\(^ \+\)\@<! \{2,}', ' ')
noremap <expr> \S edit#replace_regex_expr(
  \ 'Removed all whitespace.',
  \ '\S\@<=\(^ \+\)\@<! \+', '')

" Delete first-level and second-level commented text
" Note: First is more 'strict' but more common so give it lower case
noremap <expr> \c edit#replace_regex_expr(
  \ 'Removed all comments.',
  \ '\(^\s*' . comment#get_char() . '.\+$\n\\|\s\+' . comment#get_char() . '.\+$\)', '')
noremap <expr> \C edit#replace_regex_expr(
  \ 'Removed second-level comments.',
  \ '\(^\s*' . comment#get_char() . '\s*' . comment#get_char() . '.\+$\n\\|\s\+'
  \ . comment#get_char() . '\s*' . comment#get_char() . '.\+$\)', '')

" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
noremap <expr> \- edit#replace_regex_expr(
  \ 'Fixed long dashes.',
  \ '–', '--')
noremap <expr> \_ edit#replace_regex_expr(
  \ 'Fixed wordbreak dashes.',
  \ '\(\w\)[-–] ', '\1')
noremap <expr> \' edit#replace_regex_expr(
  \ 'Fixed single quotes.',
  \ '‘', '`', '’', "'")
noremap <expr> \" edit#replace_regex_expr(
  \ 'Fixed double quotes.',
  \ '“', '``', '”', "''")

" Replace useless bibtex entries
" Previously localized to bibtex ftplugin but no major reason not to include here
noremap <expr> \x edit#replace_regex_expr(
  \ 'Removed bibtex entries.',
  \ '^\s*\(abstract\|annotate\|copyright\|file\|keywords\|note\|shorttitle\|url\|urldate\)\s*=\s*{\_.\{-}},\?\n',
  \ '')
noremap <expr> \X edit#replace_regex_expr(
  \ 'Removed bibtex entries.',
  \ '^\s*\(abstract\|annotate\|copyright\|doi\|file\|language\|keywords\|note\|shorttitle\|url\|urldate\)\s*=\s*{\_.\{-}},\?\n',
  \ '')


"-----------------------------------------------------------------------------"
" External plugins
"-----------------------------------------------------------------------------"
" Ad hoc enable or disable LSP for testing
" Note: Can also use switch#lsp() interactively
let s:enable_lsp = 1
let s:enable_ddc = 1

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
  let rtp = fnamemodify(expand(rtp), ':p')
  let esc = escape(rtp, ' ~')
  if !isdirectory(rtp)
    echohl WarningMsg
    echo "Warning: Path '" . rtp . "' not found."
    echohl None
  elseif &runtimepath !~# esc  " any remaining tildes
    exe 'set rtp^=' . esc
    exe 'set rtp+=' . esc . '/after'
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

" Anti-escape
" Note: This is used only to preserve stdin colors e.g. 'git add --help'. Previously
" invoked when opening command --help pages but now not needed since redirect small
" subset of commands that include ANSI colors back to their corresponding man pages.
" call plug#('powerman/vim-plugin-AnsiEsc')

" Inline code handling
" Note: Use :InlineEdit within blocks to open temporary buffer for editing. The buffer
" will have filetype-aware settings. See: https://github.com/AndrewRadev/inline_edit.vim
" call plug#('AndrewRadev/inline_edit.vim')

" Close unused buffers with Bdelete
" Note: Instead use custom utilities
" call plug#('Asheq/close-buffers.vim')  " e.g. Bdelete hidden, Bdelete select
" call plug#('artnez/vim-wipeout')  " utility overwritten with custom one

" Commenting stuff
" Note: tcomment_vim is nice minimal extension of vim-commentary, include explicit
" commenting and uncommenting and 'blockwise' commenting with g>b and g<b
" call plug#('scrooloose/nerdcommenter')
" call plug#('tpope/vim-commentary')  " too simple
call plug#('tomtom/tcomment_vim')

" General utilities
" Note: Select mode (e.g. by typing 'gh') is same as visual but enters insert mode
" when you start typing, to emulate typing after click-and-drag. Never use it.
" See: https://vi.stackexchange.com/a/4892/8084
" call plug#('Shougo/vimshell.vim')  " first generation :terminal add-ons
" call plug#('Shougo/deol.nvim')  " second generation :terminal add-ons
" call plug#('jez/vim-superman')  " replaced with vim.vim and bashrc utilities
" call plug#('tpope/vim-unimpaired')  " bracket maps that no longer use
call plug#('tpope/vim-repeat')  " shell utils like chmod rename and move
call plug#('tpope/vim-eunuch')  " shell utils like chmod rename and move
call plug#('tpope/vim-characterize')  " print character info (mnemonic is l for letter)
nmap g. <Plug>(characterize)

" Panel utilities
" Note: For why to avoid these plugins see https://shapeshed.com/vim-netrw/
" various shortcuts to test whole file, current test, next test, etc.
" call plug#('vim-scripts/EnhancedJumps')  " unnecessary
" call plug#('jistr/vim-nerdtree-tabs')  " unnecessary
" call plug#('scrooloose/nerdtree')  " unnecessary
" call plug#('preservim/tagbar')  " unnecessary
call plug#('mbbill/undotree')

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

" Navigation and marker and fold interface
" Todo: Use Lsp for expression folding? Or individual plugins? See lsp section.
" See: https://github.com/junegunn/vim-peekaboo/issues/84
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" call plug#('easymotion/vim-easymotion')  " extremely slow and overkill
" call plug#('tmhedberg/SimpylFold')  " slows things down
" call plug#('kshenoy/vim-signature')  " unneeded and abandoned
call plug#('junegunn/vim-peekaboo')  " popup display
call plug#('justinmk/vim-sneak')  " simple and clean
call plug#('Konfekt/FastFold')  " simpler
let g:peekaboo_prefix = '"'
let g:peekaboo_window = 'vertical topleft 30new'
" let g:SimpylFold_docstring_preview = 0
" let g:SimpylFold_fold_docstring = 0
" let g:SimpylFold_fold_import = 0

" Matching groups and searching
" Note: The vim-tags @#&*/?! mappings auto-integrate with vim-indexed-search
call plug#('andymass/vim-matchup')
call plug#('henrik/vim-indexed-search')
let g:matchup_matchparen_enabled = 1  " enable matchupt matching on startup
let g:matchup_transmute_enabled = 0  " issues in latex, use vim-succinct instead
let g:indexed_search_mappings = 1  " required even for <Plug>(mappings) to work
let g:indexed_search_colors = 0
let g:indexed_search_dont_move = 1  " irrelevant due to custom mappings
let g:indexed_search_line_info = 1  " show first and last line indicators
let g:indexed_search_max_lines = 100000  " increase from default of 3000 for log files
let g:indexed_search_shortmess = 1  " shorter message
let g:indexed_search_numbered_only = 1  " only show numbers
let g:indexed_search_n_always_searches_forward = 0  " disable for consistency with sneak

" Error checking and testing
" Note: Below test plugin works for every filetype (simliar to ale). Set up
" Note: syntastic looks for checkers in $PATH, must be installed manually
" call plut#('scrooloose/syntastic')  " out of date: https://github.com/vim-syntastic/syntastic/issues/2319
call plug#('vim-test/vim-test')
call plug#('dense-analysis/ale')
call plug#('fisadev/vim-isort')
call plug#('Chiel92/vim-autoformat')
call plug#('tell-k/vim-autopep8')
call plug#('psf/black')

" Git wrappers and differencing tools
" Note: vim-flog and gv.vim are heavyweight and lightweight commit branch viewing
" plugins. Probably not necessary unless in giant project with tons of branches.
" See: https://github.com/rbong/vim-flog/issues/15
" See: https://vi.stackexchange.com/a/21801/8084
" call plug#('rbong/vim-flog')  " view commit graphs with :Flog, filetype 'Flog' (?)
" call plug#('junegunn/gv.vim')  " view commit graphs with :GV, filetype 'GV'
call plug#('rhysd/conflict-marker.vim')  " highlight conflicts
call plug#('airblade/vim-gitgutter')
call plug#('tpope/vim-fugitive')
" let g:fugitive_no_maps = 1  " only disables nmap y<C-g> and cmap <C-r><C-g>
let g:conflict_marker_enable_highlight = 1
let g:conflict_marker_enable_mappings = 0

" Project-wide tags and auto-updating
" Note: This should work for both fzf ':Tags' (uses 'tags' since relies on tagfiles()
" for detection in autoload/vim.vim) and gutentags (uses only g:gutentags_ctags_tagfile
" for both detection and writing).
" call plug#('xolox/vim-misc')  " dependency for easytags
" call plug#('xolox/vim-easytags')  " kind of old and not that useful honestly
call plug#('ludovicchabant/vim-gutentags')  " note slows things down without config
let g:gutentags_enabled = 1
" let g:gutentags_enabled = 0

" User interface selection stuff
" Note: While specify ctags comamnd below, and set 'tags' accordingly above, this
" should generally not be used since tags managed by gutentags.
" Note: 'Drop' opens selection in existing window, similar to switchbuf=useopen,usetab.
" However :Buffers still opens duplicate tabs even with fzf_buffers_jump=1.
" Note: FZF can also do popup windows, similar to ddc/vim-lsp, but prefer windows
" centered on bottom so do not configure this way.
" Note: fzf#wrap is required to apply global settings and cannot
" rely on fzf#run return values (will result in weird hard-to-debug issues).
" See: https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
" See: https://www.reddit.com/r/vim/comments/9504rz/denite_the_best_vim_pluggin/e3pbab0/
" call plug#('mhinz/vim-grepper')  " for ag/rg but seems like easymotion, too much
" call plug#('Shougo/pum.vim')  " pum completion mappings, but mine are nicer
" call plug#('Shougo/unite.vim')  " first generation
" call plug#('Shougo/denite.vim')  " second generation
" call plug#('Shougo/ddu.vim')  " third generation
" call plug#('Shougo/ddu-ui-filer.vim')  " successor to Shougo/vimfiler and Shougo/defx.nvim
" call plug#('ctrlpvim/ctrlp.vim')  " replaced with fzf
call plug#('~/.fzf')  " fzf installation location, will add helptags and runtimepath
call plug#('junegunn/fzf.vim')  " this one depends on the main repo above, includes other tools
let g:fzf_action = {
  \ 'ctrl-m': 'Drop', 'ctrl-i': 'silent!',
  \ 'ctrl-t': 'tab split', 'ctrl-x': 'split', 'ctrl-v': 'vsplit'
  \ }  " have file search, grep open to existing window if possible
let g:fzf_layout = {'down': '~33%'}  " for some reason ignored (version 0.29.0)
let g:fzf_buffers_jump = 1  " have fzf jump to existing window if possible
let g:fzf_tags_command = 'ctags -R -f .vimtags ' . tag#get_ignores(1)  " added just for safety

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
  let g:lsp_float_max_width = 88  "  some reason results in wider windows
  let g:lsp_preview_max_width = 88  "  some reason results in wider windows
  let g:lsp_preview_max_height = 176
endif

" Completion engines
" Note: Autocomplete requires deno (install with mamba). Older verison requires pynvim
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
" call plug#('Shougo/deoplete.nvim')  " third generation (requires pynvim)
" call plug#('Shougo/neco-vim')  " deoplete dependency
" call plug#('roxma/nvim-yarp')  " deoplete dependency
" call plug#('roxma/vim-hug-neovim-rpc')  " deoplete dependency
" let g:neocomplete#enable_at_startup = 1  " needed inside plug#begin block
" let g:deoplete#enable_at_startup = 1  " needed inside plug#begin block
if s:enable_ddc
  call plug#('vim-denops/denops.vim')  " ddc dependency
  call plug#('matsui54/denops-popup-preview.vim')  " show previews during pmenu selection
  call plug#('Shougo/ddc.vim')  " fourth generation (requires deno)
  call plug#('Shougo/ddc-ui-native')  " matching words near cursor
  " call plug#('vim-denops/denops.vim', {'commit': 'e641727'})  " ddc dependency
  " call plug#('Shougo/ddc.vim', {'commit': 'db28c7d'})  " fourth generation (requires deno)
  " call plug#('Shougo/ddc-ui-native', {'commit': 'cc29db3'})  " matching words near cursor
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
if s:enable_ddc
  call plug#('tani/ddc-fuzzy')  " filter for fuzzy matching similar to fzf
  call plug#('matsui54/ddc-buffer')  " matching words from buffer (as in neocomplete)
  call plug#('shun/ddc-source-vim-lsp')  " language server protocol completion for vim 8+
  call plug#('Shougo/ddc-source-around')  " matching words near cursor
  call plug#('LumaKernel/ddc-source-file')  " matching file names
endif

" Delimiters and stuff. Use vim-surround rather than vim-sandwich because key mappings
" are better and API is simpler. Only miss adding numbers to operators, otherwise
" feature set is same (e.g. cannot delete and change arbitrary text objects)
" See discussion: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
" See also: https://github.com/wellle/targets.vim/issues/225
" call plug#('wellle/targets.vim')
" call plug#('machakann/vim-sandwich')
call plug#('tpope/vim-surround')
call plug#('raimondi/delimitmate')

" Snippets and stuff
" Todo: Investigate further, but so far primitive vim-succinct snippets are fine
" call plug#('SirVer/ultisnips')  " fancy snippet actions
" call plug#('honza/vim-snippets')  " reference snippet files supplied to e.g. ultisnips
" call plug#('LucHermitte/mu-template')  " file template and snippet engine mashup, not popular
" call plug#('Shougo/neosnippet.vim')  " snippets consistent with ddc
" call plug#('Shougo/neosnippet-snippets')  " standard snippet library
" call plug#('Shougo/deoppet.nvim')  " next generation snippets (does not work in vim8)
" call plug#('hrsh7th/vim-vsnip')  " snippets
" call plug#('hrsh7th/vim-vsnip-integ')  " integration with ddc.vim

" Additional text objects (inner/outer selections)
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

" Indent guides
" Note: Indentline completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes (which
" we need to stay transparent). Also indent-guides looks too busy and obtrusive.
" Instead use braceless.vim highlighting, appears only when cursor is there.
" call plug#('yggdroot/indentline')
" call plug#('nathanaelkane/vim-indent-guides')

" ReST utilities
" Use == tables instead of fancy ++ tables
" call plug#('nvie/vim-rst-tables')
" call plug#('ossobv/vim-rst-tables-py3')
" call plug#('philpep/vim-rst-tables')
" noremap <silent> \s :python ReformatTable()<CR>
" let g:riv_python_rst_hl = 1
" call plug#('Rykka/riv.vim')

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

" Formatting stuff
" The conjoin plugin removes line continuation characters and is awesome
" Note: Seems that mapping <Nop> just sends it to a black hole. Try :map <Nop> after.
" See: https://www.reddit.com/r/vim/comments/g71wyq/delete_continuation_characters_when_joining_lines/
" call plug#('dkarter/bullets.vim')  " list numbering but completely fails
" call plug#('ohjames/tabdrop')  " now apply similar solution with :Drop
" call plug#('beloglazov/vim-online-thesaurus')  " completely broken: https://github.com/beloglazov/vim-online-thesaurus/issues/44
" call plug#('terryma/vim-multiple-cursors')  " article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" call plug#('vim-scripts/LargeFile')  " disable syntax highlighting for large files
call plug#('AndrewRadev/splitjoin.vim')  " single-line multi-line transition hardly every needed
call plug#('flwyd/vim-conjoin')  " remove line continuation characters
let g:LargeFile = 1  " megabyte limit
let g:conjoin_map_J = '<Nop>'  " no nomap setting but this does fine
let g:conjoin_map_gJ = '<Nop>'  " no nomap setting but this does fine
let g:splitjoin_join_mapping  = 'cJ'
let g:splitjoin_split_mapping = 'cK'
let g:splitjoin_trailing_comma = 1
let g:splitjoin_normalize_whitespace = 1
let g:splitjoin_python_brackets_on_separate_lines = 1
"
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

" Calculators and number stuff
" call plug#('vim-scripts/Toggle')  " toggling stuff on/off, modified this myself
" call plug#('triglav/vim-visual-increment')  " superceded by vim-speeddating
call plug#('sk1418/HowMuch')
call plug#('tpope/vim-speeddating')  " dates and stuff
call plug#('metakirby5/codi.vim')  " calculators
let g:HowMuch_no_mappings = 1
let g:speeddating_no_mappings = 1

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
  let s:local = 0
  for s:root in ['~', '~/iCloud Drive']
    for s:sub in ['software', 'forks']
      let s:dir = expand(join([s:root, s:sub, s:name], '/'))
      if !s:local && isdirectory(s:dir)
        call s:plug_local(s:dir)
        let s:local = 1
      endif
    endfor
  endfor
  if !s:local
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
" Auto-complete delimiters
" Filetype-specific settings are in various ftplugin files
if s:plug_active('delimitmate')
  let g:delimitMate_expand_cr = 2  " expand even if it is not empty!
  let g:delimitMate_expand_space = 1
  let g:delimitMate_jump_expansion = 0
  let g:delimitMate_excluded_regions = 'String'  " by default is disabled inside, don't want that
endif

" Additional mappings powered by Karabiner. Note that custom delimiters
" are declared inside vim-succinct plugin functions rather than here.
if s:plug_active('vim-succinct')
  let g:succinct_surround_map = '<C-s>'
  let g:succinct_snippet_map = '<C-e>'
  let g:succinct_prevdelim_map = '<F1>'
  let g:succinct_nextdelim_map = '<F2>'
endif

" Additional mappings for scrollwrapped accounting for Karabiner <C-j> --> <Down>, etc.
" Also add custom filetype log and plugin filetype ale-preview to list.
if s:plug_active('vim-scrollwrapped')
  " let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + s:lang_filetypes
  let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + ['tex', 'text']
  let g:scrollwrapped_nomap = 1
  noremap <Leader>w <Cmd>WrapToggle<CR>
  noremap <expr> <Up> iter#scroll_count(-0.25)
  noremap <expr> <Down> iter#scroll_count(0.25)
  inoremap <expr> <Up> iter#scroll_count(-0.25)
  inoremap <expr> <Down> iter#scroll_count(0.25)
endif

" Comment toggling stuff
" Disable a few maps but keep many others
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

" Tag integration settings
" Add maps for vim-tags and gutentags plus use tags for default double bracket
" motion, except never overwrite potential single bracket mappings (e.g. help mode).
" Note: Custom plugin is similar to :Btags which generates ad hoc tag list, different
" from :FZF which uses universal file and :Gutentags which manages/updates the file.
if s:plug_active('vim-tags')
  augroup vim_tags
    au!
    au BufEnter * call s:bracket_maps()
  augroup END
  function! s:bracket_maps()  " defining inside autocommand not possible
    if empty(maparg('[')) && empty(maparg(']'))
      nmap <buffer> [[ <Plug>TagsBackwardTop
      nmap <buffer> ]] <Plug>TagsForwardTop
    endif
  endfunction
  command! -nargs=0 ShowTags echo tags#table_kinds(<bang>0) . tags#table_tags(<bang>0)
  noremap <C-t> <Cmd>ShowTags<CR>
" noremap <Leader>U <Cmd>UpdateTags<CR>  " use gutentags updates instead
  command! -nargs=? TagToggle call switch#tags(<args>)
  nnoremap <Leader>U <Cmd>call switch#tags()<CR>
  nnoremap <Leader>t <Cmd>call switch#tags(1)<CR><Cmd>BTags<CR>
  nnoremap <Leader>T <Cmd>call switch#tags(1)<CR><Cmd>Tags<CR>
  let g:tags_scope_kinds = {'fortran': 'fsmp', 'python': 'fmc', 'vim': 'af', 'tex': 'csub'}
  let g:tags_skip_kinds = {'python': 'I', 'tex': 'g', 'vim': 'vnC'}
endif

" Gutentag tag generation
" Note: Also include function for parsing ignore file contents
if s:plug_active('vim-gutentags')
  augroup guten_tags
    au!
    au User GutentagsUpdated call tag#set_tags()  " enforces &tags variable
  augroup END
  command! -nargs=? Ignores echom 'Ignores: ' . join(tag#get_ignores(0, <q-args>), ' ')
  nnoremap <Leader>< <Cmd>UpdateTags<CR><Cmd>GutentagsUpdate<CR><Cmd>echom 'Updated file tags.'<CR>
  nnoremap <Leader>> <Cmd>UpdateTags!<CR><Cmd>GutentagsUpdate!<CR><Cmd>echom 'Updated project tags.'<CR>
  " let g:gutentags_cache_dir = '~/.vim_tags_cache'  " alternative cache specification
  " let g:gutentags_ctags_tagfile = 'tags'  " use with cache dir
  let g:gutentags_background_update = 1  " disable for debugging, printing updates
  let g:gutentags_ctags_auto_set_tags = 0  " tag#set_tags() handles this instead
  let g:gutentags_ctags_exclude_wildignore = 1  " exclude &wildignore too
  let g:gutentags_ctags_exclude = tag#get_ignores(0)  " exclude all by default
  let g:gutentags_ctags_tagfile = '.vimtags'
  let g:gutentags_define_advanced_commands = 1  " debugging command
  let g:gutentags_generate_on_new = 0  " do not update tags when opening project file
  let g:gutentags_generate_on_write = 1  " update tags when file updated
  let g:gutentags_generate_on_missing = 1  " update tags when no vimtags file found
  let g:gutentags_generate_on_empty_buffer = 0  " do not update tags when opening vim
  let g:gutentags_project_root_finder = 'tag#find_root'
endif

" Lsp integration settings
" Todo: Implement server-specific settings on top of defaults via 'vim-lsp-settings'
" plugin, e.g. try to run faster version of 'texlab'. Can use g:lsp_settings or
" vim-lsp-settings/servers files in .config. See: https://github.com/mattn/vim-lsp-settings
" Note: Servers are 'pylsp', 'bash-language-server', 'vim-language-server'. Tried
" 'jedi-language-server' but had issues on linux, and tried 'texlab' but was slow.
" Should install with mamba instead of vim-lsp-settings :LspInstallServer command.
" Note: The below autocmd gives signature popups the same borders as hover popups.
" Otherwise they have ugly double border. See: https://github.com/prabirshrestha/vim-lsp/issues/594
" Note: LspDefinition accepts <mods> and stays in current buffer for local definitions,
" so below behavior is close to 'Drop': https://github.com/prabirshrestha/vim-lsp/pull/776
" Note: Highlighting under keywords required for reference jumping with [r and ]r but
" monitor for updates: https://github.com/prabirshrestha/vim-lsp/issues/655
" Note: <C-]> definition jumping relies on builtin vim tags file jumping so fails.
" https://www.reddit.com/r/vim/comments/78u0av/why_gd_searches_instead_of_going_to_the/
if s:plug_active('vim-lsp')
  let s:popup_options = {'borderchars': ['──', '│', '──', '│', '┌', '┐', '┘', '└']}
  augroup lsp_style
    au!
    autocmd User lsp_float_opened call popup_setoptions(lsp#ui#vim#output#getpreviewwinid(), s:popup_options)
  augroup END
  command! -nargs=? LspToggle call switch#lsp(<args>)
  noremap [r <Cmd>LspPreviousReference<CR>
  noremap ]r <Cmd>LspNextReference<CR>
  noremap <Leader>a <Cmd>LspHover --ui=float<CR>
  noremap <Leader>A <Cmd>LspSignatureHelp<CR>
  noremap <Leader>O <Cmd>LspReferences<CR>
  noremap <Leader>& <Cmd>call switch#lsp()<CR>
  noremap <Leader>% <Cmd>CheckHealth<CR>
  noremap <Leader>^ <Cmd>tabnew \| LspManage<CR><Cmd>file lspservers \| call utils#panel_setup(0)<CR>
  " noremap <Leader>^ <Cmd>verbose LspStatus<CR>  " not enough info
  nnoremap <CR> <Cmd>LspPeekDefinition<CR>
  nnoremap <Leader><CR> <Cmd>tab LspDefinition<CR>
  let &g:foldexpr = 'lsp#ui#vim#folding#foldexpr()'
  let &g:foldtext = 'lsp#ui#vim#folding#foldtext()'
  let g:lsp_ale_auto_enable_linter = v:false  " default is true
  let g:lsp_diagnostics_enabled = 0  " redundant with ale
  let g:lsp_diagnostics_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_code_action_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_highlight_enabled = 0  " used with [r and ]r
  let g:lsp_fold_enabled = 0  " not yet tested, requires 'foldlevel', 'foldlevelstart'
  let g:lsp_hover_ui = 'preview'  " either 'float' or 'preview'
  let g:lsp_hover_conceal = 1  " enable markdown conceale
  let g:lsp_max_buffer_size = 2000000  " decrease from 5000000
  let g:lsp_preview_float = 1  " floating window
  let g:lsp_preview_fixup_conceal = -1  " fix window size in terminal vim
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
" let s:ddc_sources = ['around', 'buffer', 'file', 'vim-lsp', 'vsnip']
" let s:ddc_options = {'sourceOptions': {'vsnip': {'mark': 'S', 'maxItems': 5}}}
" let g:popup_preview_config = {'border': v:false, 'maxWidth': 80, 'maxHeight': 30}
if s:plug_active('ddc.vim')
  command! -nargs=? DdcToggle call switch#ddc(<args>)
  noremap <Leader>* <Cmd>call switch#ddc()<CR>
  let g:popup_preview_config = {'border': v:false, 'maxWidth': 88, 'maxHeight': 176}
  let g:denops_disable_version_check = 1  " skip check for recent versions
  let g:denops#deno = has('gui_running') ? $HOME . '/mambaforge/bin/deno' : 'deno'
  let g:denops#server#deno_args = [
    \ '--allow-env', '--allow-net', '--allow-read', '--allow-write',
    \ '--v8-flags=--max-heap-size=1000,--max-old-space-size=1000',
    \ ]
  let g:ddc_sources = ['around', 'buffer', 'file', 'vim-lsp']
  let g:ddc_options = {
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
    \ }}
  call ddc#custom#patch_global('ui', 'native')
  call ddc#custom#patch_global('sources', g:ddc_sources)
  call ddc#custom#patch_global(g:ddc_options)
  call ddc#enable()
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
  command! -nargs=? AleToggle call switch#ale(<args>)
  " map ]x <Plug>(ale_next_wrap)  " use universal circular scrolling
  " map [x <Plug>(ale_previous_wrap)  " use universal circular scrolling
  noremap <C-q> <Cmd>cclose<CR><Cmd>lclose<CR>
  noremap <Leader>x <Cmd>cclose<CR><Cmd>lopen<CR>
  noremap <Leader>X <Cmd>lclose<CR><Cmd>ALEPopulateQuickfix<CR><Cmd>copen<CR>
  noremap <Leader>@ <Cmd>call switch#ale()<CR>
  noremap <Leader># <Cmd>ALEInfo<CR>
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
  let g:ale_list_window_size = 8
  let g:ale_open_list = 0  " open manually
  let g:ale_sign_column_always = 0
  let g:ale_sign_error = 'E>'
  let g:ale_sign_warning = 'W>'
  let g:ale_sign_info = 'I>'
  let g:ale_set_loclist = 1  " keep default
  let g:ale_set_quickfix = 0  " use manual command
  let g:ale_echo_msg_error_str = 'Err'
  let g:ale_echo_msg_info_str = 'Info'
  let g:ale_echo_msg_warning_str = 'Warn'
  let g:ale_echo_msg_format = '[%linter%] %code:% %s [%severity%]'
  let g:ale_python_flake8_options =  '--max-line-length=' . s:linelength . ' --ignore=' . s:flake8_ignore
  let g:ale_set_balloons = 0  " no ballons
  let g:ale_sh_bashate_options = '-i E003 --max-line-length=' . s:linelength
  let g:ale_sh_shellcheck_options = '-e ' . s:shellcheck_ignore
  let g:ale_update_tagstack = 0  " use ctags for this
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
  let g:autopep8_max_line_length = s:linelength
  let g:black_linelength = s:linelength
  let g:black_skip_string_normalization = 1
  let g:vim_isort_python_version = 'python3'
  let g:vim_isort_config_overrides = {
    \ 'include_trailing_comma': 'true',
    \ 'force_grid_wrap': 0,
    \ 'multi_line_output': 3,
    \ 'linelength': s:linelength,
    \ }
  let g:formatdef_mpython = '"isort '
    \ . '--trailing-comma '
    \ . '--force-grid-wrap 0 '
    \ . '--multi-line 3 '
    \ . '--line-length ' . s:linelength
    \ . ' - | black --quiet '
    \ . '--skip-string-normalization '
    \ . '--line-length ' . s:linelength . ' - "'
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

" Conflict highlight settings (warning: change below to 'BufEnter?')
" Todo: Figure out how to get highlighting closer to marks, without clearing background?
" May need to define custom :syn matches that are not regions. Ask stack exchange.
" Note: Need to remove syntax regions here because they are added on per-filetype
" basis and they wipe out syntax highlighting between the conflict markers. However
" following is unnecessary: silent! doautocmd ConflictMarkerDetect BufReadPost
" See: https://vi.stackexchange.com/q/31623/8084
" See: https://github.com/rhysd/conflict-marker.vim
if s:plug_active('conflict-marker.vim')
  augroup conflict_kludge
    au!
    au BufEnter * silent! syntax clear ConflictMarkerOurs ConflictMarkerTheirs
  augroup END
  highlight ConflictMarker cterm=inverse gui=inverse
  let g:conflict_marker_highlight_group = 'ConflictMarker'
  let g:conflict_marker_begin = '^<<<<<<< .*$'
  let g:conflict_marker_separator = '^=======$'
  let g:conflict_marker_common_ancestors = '^||||||| .*$'
  let g:conflict_marker_end = '^>>>>>>> .*$'
  nmap ]f <Plug>(conflict-marker-next-hunk)
  nmap [f <Plug>(conflict-marker-prev-hunk)
  nmap gf <Plug>(conflict-marker-ourselves)
  nmap gF <Plug>(conflict-marker-themselves)
  nmap gd <Plug>(conflict-marker-none)
  nmap gD <Plug>(conflict-marker-both)
endif

" Fugitive settings
" Note: The :Gdiffsplit command repairs annoying issue where Gdiff redirects to
" Gdiffsplit unlike other shorthand commands. For some reason 'delcommand Gdiffsplit'
" fails (get undefined command errors in :Gdiff) so instead just overwrite.
" Note: All of the file-opening commands throughout fugitive funnel them through
" commands like Gedit, Gtabedit, etc. So can prevent duplicate tabs by simply
" overwriting this with custom tab-jumping :Drop command (see also git.vim).
if s:plug_active('vim-fugitive')
  command! -bar -bang -range -nargs=* -complete=customlist,fugitive#EditComplete
    \ Gtabedit exe fugitive#Open('Drop', <bang>0, '', <q-args>)
  command! -nargs=* Gsplit Gvsplit <args>
  silent! delcommand Gdiffsplit
  command! -nargs=* -bang Gdiffsplit Git diff <args>
  noremap <Leader>j <Cmd>exe 'Git diff -- ' . @%<CR>
  noremap <Leader>J <Cmd>echom "Git add '" . @% . "'" \| Git add %<CR>
  noremap <Leader>k <Cmd>exe 'Git diff --staged -- ' . @%<CR>
  noremap <Leader>K <Cmd>echom "Git reset '" . @% . "'" \| Git reset %<CR>
  noremap <Leader>B <Cmd>Git blame<CR>
  noremap <Leader>g <Cmd>Git<CR>
  noremap <Leader>G <Cmd>call git#commit_run()<CR>
  noremap <Leader>f <Cmd>BCommits<CR>
  noremap <Leader>F <Cmd>Commits<CR>
  let g:fugitive_legacy_commands = 1  " include deprecated :Git status to go with :Git
  let g:fugitive_dynamic_colors = 1  " fugitive has no HighlightRecent option
endif

" Git gutter settings
" Note: Maps below were inspired by tcomment maps 'gc', 'gcc', 'etc.'. Also
" <Leader>g both refreshes the gutter (e.g. after staging) and previews anything.
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
  if !exists('g:gitgutter_enabled') | let g:gitgutter_enabled = 0 | endif  " disable startup
  let g:gitgutter_map_keys = 0  " disable all maps yo
  let g:gitgutter_max_signs = -1  " maximum number of signs
  let g:gitgutter_preview_win_floating = 0  " disable preview window
  let g:gitgutter_use_location_list = 0  " use for errors instead
  command! -nargs=? GitGutterToggle call switch#gitgutter(<args>)
  noremap ]g <Cmd>call git#hunk_jump(1, 0)<CR>
  noremap [g <Cmd>call git#hunk_jump(0, 0)<CR>
  noremap ]G <Cmd>call git#hunk_jump(1, 1)<CR>
  noremap [G <Cmd>call git#hunk_jump(0, 1)<CR>
  noremap <expr> gs git#hunk_action_expr(1)
  noremap <expr> gS git#hunk_action_expr(0)
  nnoremap gss <Cmd>call git#hunk_action(1)<CR>
  nnoremap gSS <Cmd>call git#hunk_action(0)<CR>
  noremap <Leader>h <Cmd>call git#hunk_preview()<CR>
  noremap <Leader>H <Cmd>call switch#gitgutter()<CR>
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
      \     empty(comment#get_char())
      \     ? nr2char(0) : comment#get_char()
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
    au User CodiEnterPre call calc#codi_setup(1)
    au User CodiLeavePost call calc#codi_setup(0)
  augroup END
  command! -nargs=? CodiNew call calc#codi_new(<q-args>)
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
        \ 'preprocess': function('calc#codi_preprocess'),
        \ 'rephrase': function('calc#codi_rephrase'),
        \ },
    \ 'julia': {
        \ 'bin': ['julia', '-q', '-i', '--color=no', '--history-file=no'],
        \ 'prompt': '^\(julia>\|      \)',
        \ 'quitcmd': 'exit()',
        \ 'preprocess': function('calc#codi_preprocess'),
        \ 'rephrase': function('calc#codi_rephrase'),
        \ },
    \ }
endif

" Undo tree settings
" Todo: Currently can only clear history with 'C' in active pane not externally. Need
" to submit PR for better command. See: https://github.com/mbbill/undotree/issues/158
if s:plug_active('undotree')
  let g:undotree_ShortIndicators = 1
  let g:undotree_RelativeTimestamp = 0
  noremap <Leader>u <Cmd>UndotreeToggle<CR>
  " noremap <Leader>U <Cmd>UndotreeToggle 1<CR>C
endif

" Speed dating, support date increments
" Todo: Build intuition for how to use this things.
" Note: This overwrites default increment/decrement plugins declared above.
if s:plug_active('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
  noremap <Plug>SpeedDatingFallbackUp <C-a>
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
    au VimEnter * if !empty(v:this_session) | exe 'Obsession ' . v:this_session | endif
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
  augroup END
  command! -nargs=* -complete=customlist,vim#session_list Session call vim#init_session(<q-args>)
  noremap <Leader>$ <Cmd>Session<CR>
endif

"-----------------------------------------------------------------------------"
" Exit
"-----------------------------------------------------------------------------"
" Clear past jumps to ignore stuff from plugin files and vimrc
" Also ignore outdated marks loaded from .viminfo
" See: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
if has('gui_running') | exe 'noautocmd colorscheme ' . s:colorscheme | endif
augroup clear_jumps
  au!
  au BufReadPost * clearjumps | delmarks a-z  " see help info on exists()
augroup END
doautocmd <nomodeline> BufEnter  " trigger buffer-local overrides for this file
delmarks a-z
nohlsearch  " turn off highlighting at startup
redraw!  " weird issue sometimes where statusbar disappears
