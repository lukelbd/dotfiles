"-----------------------------------------------------------------------------"
" vint: -ProhibitSetNoCompatible
" An enormous vim configuration that does all sorts of magical things.
" Note: Use karabiner to convert ctrl-j/k/h/l into arrow keys. So anything
" mapped to these control combinations below must also be assigned to arrow keys.
" Note: Use iterm to convert some ctrl+key combinations that would otherwise
" be impossible into unused function key presses. Key codes and assignments are:
" F1: 1b 4f 50 (Ctrl-,)
" F2: 1b 4f 51 (Ctrl-.)
" F3: 1b 4f 52 (Ctrl-i)
" F4: 1b 4f 53 (Ctrl-m)
" F5: 1b 5b 31 35 7e (unused)
" F6: 1b 5b 31 37 7e (unused)
"-----------------------------------------------------------------------------"
" Critical stuff
" Note: See .vim/after/common.vim and .vim/after/filetype.vim for overrides of
" buffer-local syntax and 'conceal-', 'format-' 'linebreak', and 'joinspaces'.
" Note: The refresh variable used in .vim/autoload/vim.vim to autoload recently
" updated script and line length variable used in linting tools below.
let g:linelength = 88  " see below configuration
let g:mapleader = "\<Space>"  " see <Leader> mappings
let g:refresh = get(g:, 'refresh', localtime())
set nocompatible  " always use the vim defaults
set encoding=utf-8  " enable utf characters
scriptencoding utf-8
runtime autoload/repeat.vim
if has('gui_running') && $PATH !~# '/mambaforge/'  " enforce macvim path
  let $PATH = $HOME . '/mambaforge/bin:' . $PATH
endif

" Global settings
" Warning: Tried setting default 'foldmethod' and 'foldexpr' can cause buffer-local
" expression folding e.g. simpylfold to disappear and not retrigger, while using
" setglobal didn't work for filetypes with folding not otherwise auto-triggered (vim)
set autoindent  " indents new lines
set backspace=indent,eol,start  " backspace by indent - handy
set breakindent  " visually indent wrapped lines
set buflisted  " list all buffers by default
set cmdheight=1  " increse to avoid pressing enter to continue 
set colorcolumn=89,121  " color column after recommended length of 88
set complete+=k  " enable dictionary search through 'dictionary' setting
set completeopt-=preview  " use custom denops-popup-preview plugin
set confirm  " require confirmation if you try to quit
set cursorline  " highlight cursor line
set diffopt=filler,context:5,foldcolumn:0,vertical  " vim-difference display options
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " make sure enabled, allows keycodes
set fillchars=vert:\|,fold:\ ,foldopen:\>,foldclose:<,eob:~,lastline:@  " e.g. fold markers
set foldclose=  " use foldclose=all to auto-close folds when leaving
set foldenable  " toggle with zi, note plugins and fastfold handle foldmethod/foldexpr
set foldlevelstart=0  " hide folds when opening (then 'foldlevel' sets current status)
set foldnestmax=5  " allow only a few folding levels
set foldopen=block,jump,mark,percent,quickfix,search,tag,undo  " opening folds on cursor movement, disallow block folds
set foldtext=fold#fold_text()  " default function for generating text shown on fold line
set guicursor+=a:blinkon0  " skip blinking cursor
set guifont=Monaco:h12  " match iterm settings
set guioptions=M  " skip $VIMRUNTIME/menu.vim: https://vi.stackexchange.com/q/10348/8084
set history=100  " search history
set hlsearch  " highlight as you search forward
set ignorecase  " ignore case in search patterns
set iminsert=0  " disable language maps (used for caps lock)
set incsearch  " show match as typed so far
set lazyredraw  " skip redraws during macro and function calls
set list  " show hidden characters
set listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
set matchpairs=(:),{:},[:]  " exclude <> by default for use in comparison operators
set maxmempattern=50000  " from 1000 to 10000
set mouse=a  " mouse clicks and scroll allowed in insert mode via escape sequences
set noautochdir  " disable auto changing
set noautowrite  " disable auto write for file jumping commands (ask user instead)
set noautowriteall  " disable autowrite for :exit, :quit, etc. (ask user instead)
set nobackup  " no backups when overwriting files, use tabline/statusline features
set noerrorbells  " disable error bells (see also visualbell and t_vb)
set nohidden  " unload buffers when not open in window
set noinfercase  " do not replace insert-completion with case inferred from typed text
set nospell  " disable spellcheck by default
set nostartofline  " when switching buffers, doesn't move to start of line (weird default)
set noswapfile " no more swap files, instead use session
set notimeout  " wait forever when doing multi-key *mappings*
set nowrap  " global wrap setting possibly overwritten by wraptoggle
set nrformats=alpha  " never interpret numbers as 'octal'
set number  " show line numbers
set numberwidth=4  " number column minimum width
set path=.  " used in various built-in searching utilities, file_in_path complete opt
set previewheight=20  " default preview window height
set pumheight=10  " maximum popup menu height
set pumwidth=10  " minimum popup menu width
set redrawtime=5000  " sometimes takes a long time, let it happen
set relativenumber  " relative line numbers for navigation
set restorescreen  " restore screen after exiting vim
set scrolloff=4  " screen lines above and below cursor
set selectmode=  " disable 'select mode' slm, allow only visual mode for that stuff
set sessionoptions=tabpages,terminal,winsize  " restrict session options for speed
set shell=/usr/bin/env\ bash
set shiftround  " round to multiple of shift width
set shiftwidth=2  " default 2 spaces
set showcmd  " show operator pending command
set shortmess=atqcT  " snappy messages, 'a' does a bunch of common stuff
set showtabline=1  " default 2 spaces
set signcolumn=auto  " auto may cause lag after startup but unsure
set smartcase  " search case insensitive, unless has capital letter
set softtabstop=2  " default 2 spaces
set spellcapcheck=  " disable checking for capital start of sentence
set spelllang=en_us  " default to US english
set splitbelow  " splitting behavior
set splitright  " splitting behavior
set switchbuf=useopen,usetab,newtab,uselast  " when switching buffers use open tab
set tabpagemax=300  " allow opening shit load of tabs at once
set tabstop=2  " default 2 spaces
set tagcase=ignore  " ignore case when matching paths
set tagfunc=  " :tag, :pop, and <C-]> jumping function (requires physical tags file)
set tagrelative  " paths in tags file are relative to location
set tags=.vimtags,./.vimtags  " home, working dir, or file dir
set tagstack  " auto-add to tagstack with :tag commands
set timeoutlen=0  " othterwise do not wait at all
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set ttymouse=sgr  " different cursor shapes for different modes
set undodir=~/.vim_undo_hist  " ./setup enforces existence
set undofile  " save undo history
set undolevels=500  " maximum undo level
set updatetime=3000  " used for CursorHold autocmds and default is 4000ms
set viminfo='100,:100,<100,@100,s10,f0  " commands, marks (e.g. jump history), exclude registers >10kB of text
set virtualedit=block  " allow cursor to go past line endings in visual block mode
set visualbell  " prefer visual bell to beeps (see also 'noerrorbells')
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu  " command line completion
set wildmode=longest:list,full  " command line completion
let &g:breakat = ' 	!*-+;:,./?'  " break at single instances of several characters
let &g:expandtab = 1  " global expand tab
let &g:wildignore = join(tag#get_ignores(0, '~/.wildignore'), ',')
let &l:shortmess .= &buftype ==# 'nofile' ? 'I' : ''  " internal --help utility

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
  \ 'help', 'ale-info', 'ale-preview', 'checkhealth', 'codi', 'diff', 'fugitive', 'fugitiveblame',
  \ ]  " for popup toggle
let s:panel_filetypes += [
  \ 'git', 'gitcommit', 'netrw', 'job', '*lsp-hover', 'man', 'mru', 'qf', 'undotree', 'vim-plug'
  \ ]

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
" Stop cursor from changing when clicking on panes. Note this may no longer be
" necessary since tmux handles FocusLost signal itself.
" See: https://github.com/sjl/vitality.vim/issues/29
" See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
augroup cursor_fix
  au!
  au FocusLost * :      " stopinsert
augroup END

" Move cursor to end of insertion after leaving
" Note: Otherwise repeated i<Esc>i<Esc> will drift cursor to left
" Note: Critical to keep jumplist or else populated after every single insertion. Use
" 'zi' or changelist if you actually want to find previous insertion.
augroup insert_fix
  au!
  au InsertLeave * keepjumps normal! `^
augroup END

" Configure escape codes to restore screen after exiting
" Also disable visual bell when errors triggered because annoying
" See: :help restorescreen page
let &t_vb = ''  " disable visual bell
let &t_te = "\e[?47l\e8"
let &t_ti = "\e7\e[r\e[?47h"

" Support cursor shapes. Note neither Ptmux escape codes (e.g. through 'vitality'
" plugin) or terminal overrides seem necessary in newer versions of tmux.
" See: https://stackoverflow.com/a/44473667/4970632 (outdated terminal overrides)
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

" Helper function to suppress prefix maps. Prevents unexpected behavior due
" to entering wrong suffix, e.g. \x in visual mode deleting the selection.
function! s:gobble_map(prefix, mode)
  let char = nr2char(getchar())
  if empty(maparg(a:prefix . char, a:mode))  " return no-op
    return ''
  else  " re-direct to the active mapping
    return a:prefix . char
  endif
endfunction

" Helper function for repeat#set
" This is simpler than copy-pasting manual repeat#set calls
function! s:repeat_map(lhs, name, rhs, ...) abort
  let nore = a:0 > 1 && type(a:2) == 0 && a:2 ? '' : 'nore'
  let args = a:0 > 1 && type(a:2) != 0 ? a:2 : '<silent>'
  let mode = a:0 ? a:1 : ''
  if empty(a:name)  " disable repetition (e.g. needs user input so cannot repeat)
    let repeat = ':<C-u>call repeat#set("")<CR>'
    exe mode . nore . 'map ' . args . ' ' . a:lhs . ' ' . repeat . a:rhs
  else  " enable repetition (e.g. annoying-to-type initial commands)
    let plug = empty(a:name) ? '' : '<Plug>' . a:name
    let repeat = ':<C-u>call repeat#set("\' . plug . '")<CR>'
    exe mode . nore . 'map ' . args . ' ' . plug . ' ' . a:rhs . repeat
    exe mode . 'map ' . a:lhs . ' ' . plug
  endif
endfunction

" Remove weird Cheyenne maps, not sure how to isolate/disable /etc/vimrc without
" disabling other stuff we want e.g. synax highlighting
if !empty(mapcheck('<Esc>', 'n'))  " maps staring with escape
  silent! unmap <Esc>[3~
  let s:insert_maps = [
    \ '[3~', '[6;3~', '[5;3~', '[3;3~', '[2;3~',
    \ '[6;2~', '[5;2~', '[3;2~', '[2;2~',
    \ '[6;5~', '[5;5~', '[3;5~', '[2;5~',
    '[1;2A',
    '[1;2B',
    '[1;2C',
    '[1;2D'
    '[1;2F',
    '[1;2H',
    '[1;3A',
    '[1;3B',
    '[1;3C',
    '[1;3D',
    '[1;3F',
    '[1;3H',
    '[1;5A',
    '[1;5B',
    '[1;5C',
    '[1;5D',
    '[1;5F',
    '[1;5H',
    \ ]
  for s:insert_map in s:insert_maps
    exe 'silent! iunmap <Esc>' . s:insert_map
  endfor
endif

" Suppress all prefix mappings initially so that we avoid accidental actions
" due to entering wrong suffix, e.g. \x in visual mode deleting the selection.
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
        \ . " <sid>gobble_map('" . s:key . "', '" . s:mode . "')"
    endif
  endfor
endfor

" Disable normal mode stuff
" * q and @ are for macros, instead reserve for quitting popup windows and tags map
" * Q and K are weird modes never used
" * Z is save and quit shortcut, use for executing
" * ][ and [] can get hit accidentally
" * Ctrl-r is undo, use u and U instead
" * Ctrl-p and Ctrl-n used for menu items, use <C-,> and <C-.> or scroll instead
" * Ctrl-a and Ctrl-x used for incrementing, use + and - instead
" * Backspace scrolls to left and Delete removes character to right
" * Enter and Underscore scrolls down on first non-blank character
for s:key in [
  \ '@', 'q', 'Q', 'K', 'ZZ', 'ZQ', '][', '[]',
  \ '<C-r>', '<C-p>', '<C-n>', '<C-a>', '<C-x>',
  \ '<Delete>', '<Backspace>', '<CR>', '_',
  \ ]
  if empty(maparg(s:key, 'n'))
    exe 'nnoremap ' . s:key . ' <Nop>'
  endif
endfor

" Disable insert mode stuff
" * Ctrl-, and Ctrl-. do nothing, use for previous and next delimiter jumping
" * Ctrl-x scrolls or toggles insert-mode completion, use autocomplete instead
" * Ctrl-n, Ctrl-p cycles through menu options, use e.g. Ctrl-j and Ctrl-k instead
" * Ctrl-d, Ctrl-t deletes and inserts shiftwidths, use backspace and tab instead
" * Ctrl-h deletes character before cursor, use backspace instead
" * Ctrl-l used for special 'insertmode' always-insert-mode option
" * Ctrl-b enabled reverse insert-mode entry in older vim, disable in case
" * Ctrl-z sends vim to background, disable to prevent cursor change
augroup override_maps
  au!
augroup END
for s:key in [
  \ '<F1>', '<F2>', '<F3>', '<F4>',
  \ '<C-n>', '<C-p>', '<C-d>', '<C-t>', '<C-h>', '<C-l>', '<C-b>', '<C-z>',
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
nnoremap gn gE/<C-r>/<CR><Cmd>noh<CR>mzgn
nnoremap gN W?<C-r>/<CR><Cmd>noh<CR>mzgN
nnoremap <expr> <C-v> (&l:wrap ? '<Cmd>WrapToggle 0<CR>' : '') . 'mz<C-v>'
vnoremap <CR> <C-c>
vnoremap v <Esc>mzv
vnoremap V <Esc>mzV
vnoremap <expr> <C-v> '<Esc>' . (&l:wrap ? '<Cmd>WrapToggle 0<CR>' : '') . 'mz<C-v>'
vnoremap <LeftMouse> <LeftMouse>my`z<Cmd>exe 'normal! ' . visualmode()<CR>`y<Cmd>delmark y<CR>


"-----------------------------------------------------------------------------"
" File and window utilities
"-----------------------------------------------------------------------------"
" Save or quit the current session
" Note: To avoid accidentally closing vim do not use mapped shortcuts. Instead
" require manual closure using :qall or :quitall.
" nnoremap <C-q> <Cmd>quitall<CR>
command! -nargs=? Autosave call switch#autosave(<args>)
noremap <Leader>W <Cmd>call switch#autosave()<CR>
nnoremap <C-q> <Cmd>call window#close_tab()<CR>
nnoremap <C-w> <Cmd>call window#close_window()<CR>
nnoremap <C-s> <Cmd>call file#update()<CR>

" Refresh session or re-open previous files
" Note: Here :Mru shows tracked files during session, will replace current buffer.
command! -bang -nargs=? Refresh call vim#config_refresh(<bang>0, <q-args>)
command! -nargs=? Scripts call vim#config_scripts(0, <q-args>)
noremap <Leader>e <Cmd>edit \| doautocmd BufWritePost<CR>
noremap <Leader>r <Cmd>redraw! \| echo ''<CR>
noremap <Leader>R <Cmd>Refresh<CR>
let g:MRU_Open_File_Relative = 1

" Buffer selection and management
" Note: Here :WipeBufs replaces :Wipeout plugin since has more sources
command! -nargs=0 ShowBufs call window#show_bufs()
command! -nargs=0 WipeBufs call window#wipe_bufs()
noremap <Leader>q <Cmd>ShowBufs<CR>
noremap <Leader>Q <Cmd>WipeBufs<CR>

" Open file in current directory or some input directory
" Note: Anything that is not :Files gets passed to :Drop command
command! -nargs=* -complete=file Drop call file#open_drop(<f-args>)
command! -nargs=* -complete=file Open call file#open_continuous('Drop', <f-args>)
nnoremap <F3> <Cmd>exe 'Open ' . fnameescape(fnamemodify(resolve(@%), ':p:h'))<CR>
nnoremap <C-y> <Cmd>exe 'Files ' . fnameescape(fnamemodify(resolve(@%), ':p:h'))<CR>
nnoremap <C-o> <Cmd>exe 'Open ' . fnameescape(tag#find_root(@%))<CR>
nnoremap <C-p> <Cmd>exe 'Files ' . fnameescape(tag#find_root(@%))<CR>
nnoremap <C-g> <Cmd>GFiles<CR>
" nnoremap <C-g> <Cmd>Locate<CR>  " uses giant database from Unix 'locate'

" Open file with optional user input
" Note: Here :History includes v:oldfiles and open buffers
" Note: Currently no way to make :Buffers use custom opening command
nnoremap <Tab>e <Cmd>History<CR>
nnoremap <Tab>r <Cmd>call file#open_recent()<CR>
nnoremap <Tab>- <Cmd>call file#open_init('split', 1)<CR>
nnoremap <Tab>\ <Cmd>call file#open_init('vsplit', 1)<CR>
nnoremap <Tab>o <Cmd>call file#open_init('Drop', 0)<CR>
nnoremap <Tab>p <Cmd>call file#open_init('Files', 0)<CR>
nnoremap <Tab>i <Cmd>call file#open_init('Drop', 1)<CR>
nnoremap <Tab>y <Cmd>call file#open_init('Files', 1)<CR>

" Tab and window jumping
noremap g<Tab> <Nop>
nnoremap <expr> <Tab><Tab> v:count ? v:count . 'gt' : '<Cmd>call window#jump_tab()<CR>'
for s:num in range(1, 10) | exe 'nnoremap <Tab>' . s:num . ' ' . s:num . 'gt' | endfor
nnoremap <Tab>q <Cmd>Buffers<CR>
nnoremap <Tab>w <Cmd>Windows<CR>
nnoremap <Tab>, <Cmd>exe 'tabnext -' . v:count1<CR>
nnoremap <Tab>. <Cmd>exe 'tabnext +' . v:count1<CR>
nnoremap <Tab>' <Cmd>silent! tabnext #<CR>
nnoremap <Tab>; <C-w><C-p>
nnoremap <Tab>j <C-w>j
nnoremap <Tab>k <C-w>k
nnoremap <Tab>h <C-w>h
nnoremap <Tab>l <C-w>l

" Tab and window resizing and motion
nnoremap <Tab>> <Cmd>call window#move_tab(tabpagenr() + v:count1)<CR>
nnoremap <Tab>< <Cmd>call window#move_tab(tabpagenr() - v:count1)<CR>
nnoremap <Tab>m <Cmd>call window#move_tab()<CR>
nnoremap <Tab>= <Cmd>vertical resize 90<CR>
nnoremap <Tab>0 <Cmd>exe 'resize ' . (&lines * (len(tabpagebuflist()) > 1 ? 0.8 : 1.0))<CR>
nnoremap <Tab>( <Cmd>exe 'resize ' . (winheight(0) - 3 * v:count1)<CR>
nnoremap <Tab>) <Cmd>exe 'resize ' . (winheight(0) + 3 * v:count1)<CR>
nnoremap <Tab>_ <Cmd>exe 'resize ' . (winheight(0) - 6 * v:count1)<CR>
nnoremap <Tab>+ <Cmd>exe 'resize ' . (winheight(0) + 6 * v:count1)<CR>
nnoremap <Tab>[ <Cmd>exe 'vertical resize ' . (winwidth(0) - 5 * v:count1)<CR>
nnoremap <Tab>] <Cmd>exe 'vertical resize ' . (winwidth(0) + 5 * v:count1)<CR>
nnoremap <Tab>{ <Cmd>exe 'vertical resize ' . (winwidth(0) - 10 * v:count1)<CR>
nnoremap <Tab>} <Cmd>exe 'vertical resize ' . (winwidth(0) + 10 * v:count1)<CR>

" Related file utilities
" Mnemonic is 'inside' just like Ctrl + i map
" Note: Here :Rename is adapted from the :Rename2 plugin. Usage is :Rename! <dest>
command! -nargs=* -complete=file -bang Rename call file#rename(<q-args>, '<bang>')
command! -nargs=? Paths call file#print_paths(<f-args>)
command! -nargs=? Localdir call switch#localdir(<args>)
noremap <Leader>i <Cmd>Paths<CR>
noremap <Leader>I <Cmd>Localdir<CR>
noremap <Leader>p <Cmd>call file#print_exists()<CR>
noremap <Leader>P <Cmd>exe 'Drop ' . expand('<cfile>')<CR>
noremap <Leader>b <Cmd>exe 'leftabove 30vsplit ' . tag#find_root(@%)<CR>
noremap <Leader>B <Cmd>exe 'leftabove 30vsplit ' . fnamemodify(resolve(@%), ':p:h')<CR>

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

" Vim command windows, search windows, help windows, man pages, and 'cmd --help'. Also
" add shortcut to search for all non-ASCII chars (previously used all escape chars).
" See: https://stackoverflow.com/a/41168966/4970632
nnoremap <Leader>. :<C-u><Up><CR>
nnoremap <Leader>; <Cmd>History:<CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ <Cmd>History/<CR>
nnoremap <Leader>? q/
nnoremap <Leader>v <Cmd>Helptags<CR>
nnoremap <Leader>V <Cmd>call vim#vim_page()<CR>
nnoremap <Leader>n <Cmd>Maps<CR>
nnoremap <Leader>N <Cmd>Commands<CR>
nnoremap <Leader>m <Cmd>call shell#help_page(1)<CR>
nnoremap <Leader>M <Cmd>call shell#man_page(1)<CR>

" Cycle through location list options
" Note: ALE populates the window-local loc list rather than the global quickfix list.
command! -bar -count=1 Lnext execute iter#next_loc(<count>, 'loc', 0)
command! -bar -count=1 Lprev execute iter#next_loc(<count>, 'loc', 1)
command! -bar -count=1 Qnext execute iter#next_loc(<count>, 'qf', 0)
command! -bar -count=1 Qprev execute iter#next_loc(<count>, 'qf', 1)
noremap [x <Cmd>Lprev<CR>zv
noremap ]x <Cmd>Lnext<CR>zv
noremap [X <Cmd>Qprev<CR>zv
noremap ]X <Cmd>Qnext<CR>zv

" Cycle through wildmenu expansion with <C-,> and <C-.>
" Note: Mapping without <expr> will type those literal keys
cnoremap <F1> <C-p>
cnoremap <F2> <C-n>

" Terminal maps, map Ctrl-c to literal keypress so it does not close window
" Mnemonic is that '!' matches the ':!' used to enter shell commands
" Note: Must change local dir or use environment variable to make term pop up here:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>  " will prevent sending iTerm shortcuts
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>! <Cmd>let $VIMTERMDIR=expand('%:p:h') \| terminal<CR>cd $VIMTERMDIR<CR>


"-----------------------------------------------------------------------------"
" Search and navigation utilities
"-----------------------------------------------------------------------------"
" Ensure 'noignorecase' turned on when in insert mode, so that
" popup menu autocompletion respects input case.
" Note: Previously had issue before where InsertLeave ignorecase autocmd was getting
" reset because MoveToNext was called with au!, which resets InsertLeave commands.
augroup search_replace
  au!
  au InsertEnter * set noignorecase  " default ignore case
  au InsertLeave * set ignorecase
augroup END

" Search highlighting toggle
" This calls 'set hlsearch!' and prints a message
noremap <Leader>o <Cmd>call switch#hlsearch(1 - v:hlsearch, 1)<CR>

" Go to last and next changed text
" Note: F4 is mapped to Ctrl-m in iTerm
noremap <C-n> g;
noremap <F4> g,

" Go to last and next jump
" Note: This accounts for karabiner arrow key maps
noremap <C-h> <C-o>
noremap <C-l> <C-i>
noremap <Left> <C-o>
noremap <Right> <C-i>

" Move between alphanumeric groups of characters (i.e. excluding dots, dashes,
" underscores). This is consistent with tmux vim selection navigation
for s:char in ['w', 'b', 'e', 'm']  " use 'g' prefix of each
  exe 'noremap g' . s:char . ' '
    \ . '<Cmd>let b:iskeyword = &l:iskeyword<CR>'
    \ . '<Cmd>setlocal iskeyword=@,48-57,192-255<CR>'
    \ . (s:char ==# 'm' ? 'ge' : s:char) . '<Cmd>let &l:iskeyword = b:iskeyword<CR>'
endfor

" Go to previous end-of-word or previous end-of-WORD
" This makes ge/gE a single-keystroke motion alongside with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Search for special characters
" First searches for escapes second for non-ascii
noremap gr /[^\x00-\x7F]<CR>
noremap gR /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Go to start or end without opening folds
" Useful for e.g. python files with docsring at top and function at bottom
" Note: Mapped jumping commands do not open folds by default, hence the expr below
" Note: Could use e.g. :1<CR> or :$<CR> but that would exclude them from jumplist
noremap G G
noremap <expr> gg 'gg' . (v:count ? 'zv' : '')

" Screen motion mappings
" Note: This is consistent with 'zl', 'zL', 'zh', 'zH' horizontal scrolling and lets us
" use 'zt' for title case 'zb' for boolean toggle. Also make 'ze'/'zs' more intuitive.
noremap z. z.
noremap zj zb
noremap zk zt
noremap ze zs
noremap zs ze

" General fold commands to folds
" Todo: Remove this after restarting sessions.
noremap zf zf
noremap zF zF
noremap zn zn
noremap zN zN

" Change fold level
" Note: Also have 'zx' and 'zX' to reset manually-opened-closed folds.
" Note: Here 'zf' sets to input count while other commands increase or decrease by
" count. Every command echos the change. Also 'zf' without count simply prints level.
noremap zp <Cmd>call fold#set_level()<CR>
noremap zP <Cmd>call fold#set_level()<CR>
noremap zm <Cmd>call fold#set_level('m')<CR>
noremap zM <Cmd>call fold#set_level('M')<CR>
noremap zr <Cmd>call fold#set_level('r')<CR>
noremap zR <Cmd>call fold#set_level('R')<CR>

" Toggle folds under cursor non-recursively
" Note: FastFoldUpdate will auto-close new folds above level so use below to prevent
" confusing behavior where 'zz' pressed on seemingly-open undefined fold does nothing.
" Note: Previously toggled with recursive-open then non-recursive close but this is
" annoying e.g. for huge python classes. Now use 'zZ' to explicitly toggle nesting.
noremap <expr> zz '<Cmd>FastFoldUpdate<CR>' . (foldclosed('.') > 0 ? 'zo' : 'zc')
nnoremap zcc <Cmd>FastFoldUpdate<CR>zc
nnoremap zoo <Cmd>FastFoldUpdate<CR>zo
vnoremap <nowait> zc <Cmd>FastFoldUpdate<CR>zc
vnoremap <nowait> zo <Cmd>FastFoldUpdate<CR>zo
nnoremap <expr> za fold#toggle_range_expr(-1, 0)
nnoremap <expr> zc fold#toggle_range_expr(1, 0)
nnoremap <expr> zo fold#toggle_range_expr(0, 0)

" Toggle folds under cursor recursively
" Note: Here 'zZ' will close or open all nested folds under cursor up to
" level parent. Use :echom fold#get_current() for debugging.
" Note: Here 'zC' will close fold only up to current level or for definitions
" inside class (special case for python). Could also use e.g. noremap <expr>
" zC fold#toggle_range_expr(1, 1) for recursive motion mapping.
noremap zZ <Cmd>call fold#toggle_nested()<CR>
noremap zC <Cmd>call fold#toggle_current(1)<CR>
noremap zO <Cmd>call fold#toggle_current(0)<CR>

" Jump to next or previous fold or inside fold
" Note: This is more consistent with other bracket maps
" Note: Recursive map required for [Z or ]Z or else way more complicated
call s:repeat_map('[Z', 'FoldBackward', 'zkza')
call s:repeat_map(']Z', 'FoldForward', 'zjza')
noremap [z zk
noremap ]z zj
noremap z[ [z
noremap z] ]z

" Go to folds marks or jumps with fzf
" Note: :Marks does not handle file switching and :Jumps has an fzf error so override.
noremap gz <Cmd>Folds<CR>
noremap g' <Cmd>call mark#fzf_marks()<CR>
noremap g" <Cmd>call mark#fzf_jumps()<CR>
" noremap g' <Cmd>BLines<CR>

" Declare alphabetic marks using counts (navigate with ]` and [`)
" Note: Uppercase marks unlike lowercase marks work between files and are saved in
" viminfo, so use them. Also numbered marks are mostly internal, can be configured
" to restore cursor position after restarting, also used in viminfo.
command! -nargs=* SetMarks call mark#set_marks(<f-args>)
command! -nargs=* DelMarks call mark#del_marks(<f-args>)
noremap ~ <Cmd>call mark#set_marks(utils#translate_count('m'))<CR>
noremap ` <Cmd>call mark#goto_mark(utils#translate_count('`'))<CR>
noremap <Leader>~ <Cmd>call mark#del_marks()<CR>
noremap <expr> <Leader>` exists('g:mark_recent') ? '<Cmd>call mark#goto_mark(g:mark_recent)<CR>' : ''

" Interactive file jumping with grep commands
" Note: Maps use default search pattern '@/'. Commands can be called with arguments
" to explicitly specify path (without arguments each name has different default).
" Note: These redefinitions add flexibility to native fzf.vim commands, mnemonic
" for alternatives is 'local directory' or 'current file'. Also note Rg is faster and
" has nicer output so use by default: https://unix.stackexchange.com/a/524094/112647
command! -bang -nargs=+ Rg call grep#call_rg(<bang>0, 2, 0, <f-args>)  " all open files
command! -bang -nargs=+ Rd call grep#call_rg(<bang>0, 1, 0, <f-args>)  " project directory
command! -bang -nargs=+ Rf call grep#call_rg(<bang>0, 0, 0, <f-args>)  " file directory
command! -bang -nargs=+ R0 call grep#call_rg(<bang>0, 0, 1, <f-args>)
command! -bang -nargs=+ Ag call grep#call_ag(<bang>0, 2, 0, <f-args>)  " all open files
command! -bang -nargs=+ Ad call grep#call_ag(<bang>0, 1, 0, <f-args>)  " project directory
command! -bang -nargs=+ Af call grep#call_ag(<bang>0, 0, 0, <f-args>)  " file directory
command! -bang -nargs=+ A0 call grep#call_ag(<bang>0, 0, 1, <f-args>)
nnoremap g; <Cmd>call grep#call_grep('rg', 2, 0)<CR>
nnoremap g: <Cmd>call grep#call_grep('rg', 1, 0)<CR>

" Convenience grep maps and commands
" Note: Search open files for print statements and project files for others
" Note: Native 'gp' and 'gP' almost identical to 'p' and 'P' (just moves char to right)
let s:conflicts = '^' . repeat('[<>=|]', 7) . '\($\|\s\)'
command! -bang -nargs=* Notes call grep#call_ag(<bang>0, 1, 0, '\<note:', <f-args>)
command! -bang -nargs=* Todos call grep#call_ag(<bang>0, 1, 0, '\<todo:', <f-args>)
command! -bang -nargs=* Errors call grep#call_ag(<bang>0, 1, 0, '\<error:', <f-args>)
command! -bang -nargs=* Warnings call grep#call_ag(<bang>0, 1, 0, '\<warning:', <f-args>)
command! -bang -nargs=* Conflicts call grep#call_ag(<bang>0, 1, 0, s:conflicts, <f-args>)
command! -bang -nargs=* Prints call grep#call_ag(<bang>0, 2, 0, '^\s*print(', <f-args>)
command! -bang -nargs=* Debugs call grep#call_ag(<bang>0, 2, 0, '^\s*ic(', <f-args>)
noremap gp <Cmd>Prints<CR>
noremap gP <Cmd>Debugs<CR>
noremap gM <Cmd>Notes<CR>
noremap gB <Cmd>Todos<CR>
noremap gW <Cmd>Warnings<CR>
noremap gE <Cmd>Errors<CR>
noremap gG <Cmd>Conflicts<CR>

" Run replacement on this line alone
" Note: This works recursively with the below maps
nmap <expr> \\ '\' . nr2char(getchar()) . 'al'

" Sort input lines
" Note: Simply uses native ':sort' command.
noremap <expr> \s edit#sort_lines_expr()
noremap <expr> \\s edit#sort_lines_expr() . 'ip'

" Reverse input lines
" See: https://superuser.com/a/189956/506762
" See: https://vim.fandom.com/wiki/Reverse_order_of_lines
noremap <expr> \r edit#reverse_lines_expr()
noremap <expr> \\r edit#reverse_lines_expr() . 'ip'

" Remove trailing whitespace
" See: https://stackoverflow.com/a/3474742/4970632)
noremap <expr> \t edit#replace_regex_expr(
  \ 'Removed trailing whitespace.',
  \ '\s\+\ze$', '')

" Replace tabs with spaces
" Note: Could also use :retab?
noremap <expr> \<Tab> edit#replace_regex_expr(
  \ 'Fixed tabs.',
  \ '\t', repeat(' ', &tabstop))

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
noremap <expr> \w edit#replace_regex_expr(
  \ 'Squeezed redundant whitespace.',
  \ '\S\@<=\(^ \+\)\@<! \{2,}', ' ')
noremap <expr> \W edit#replace_regex_expr(
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
" Editing utilities
"-----------------------------------------------------------------------------"
" Insert and mormal mode undo and redo (see .vim/autoload/repeat.vim)
" Note: Here use <C-g> prefix similar to comment insert. Capital breaks the undo
" sequence. Tried implementing 'redo' but fails because history is lost after vim
" re-enters insert mode from the <C-o> command. Googled and no way to do it
" nnoremap u <Plug>RepeatUndo  " already applied
" nnoremap U <Plug>RepeatRedo  " causes weird issues
nnoremap U <C-r>
inoremap <C-g>u <C-o>u
inoremap <C-g>U <C-g>u

" Record macro by pressing Q (we use lowercase for quitting popup windows)
" and execute macro using ,. Also disable multi-window recordings.
" Note: Visual counts are ignored when starting recording
nnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_count('q') : '')
nnoremap <expr> , '@' . utils#translate_count('@')
vnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_count('q') : '')
vnoremap <expr> , '@' . utils#translate_count('@')

" Declare alphabetic registers with count (consistent with mark utilities)
" Note: Pressing ' or " followed by number uses numbered previous-deletion register,
" and pressing ' or " followed by normal-mode command uses black hole or clipboard.
" Note: Pressing double '' or "" triggers native or peekaboo register selection. This
" relies on g:peekaboo_prefix = '"' below so that double '"' opens selection panel.
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

" Single chacter maps
" Print info and Never save deletions to any register a
noremap x "_x
noremap X "_X
nmap gy <Plug>(Characterize)
nnoremap gY ga

" Swap characters or lines
" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
nnoremap cy "_s
nnoremap ch <Cmd>call edit#swap_characters(0)<CR>
nnoremap cl <Cmd>call edit#swap_characters(1)<CR>
nnoremap ck <Cmd>call edit#swap_lines(0)<CR>
nnoremap cj <Cmd>call edit#swap_lines(1)<CR>
nnoremap cL myi<CR><Esc>`y<Cmd>delmark y<CR>

" Toggle spell checking
" Turn on for filetypes containing text destined for users
augroup spell_toggle
  au!
  let s:filetypes = join(s:lang_filetypes, ',')
  exe 'au FileType ' . s:filetypes . ' setlocal spell'
augroup END
command! SpellToggle call switch#spellcheck(<args>)
command! LangToggle call switch#spelllang(<args>)
nnoremap <Leader>s <Cmd>call switch#spellcheck()<CR>
nnoremap <Leader>S <Cmd>call switch#spelllang()<CR>

" Replace misspelled words or define or identify words
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
call s:repeat_map(']S', 'SpellForward', '<Cmd>call edit#spell_next(0)<CR>')
call s:repeat_map('[S', 'SpellBackward', '<Cmd>call edit#spell_next(1)<CR>')
nnoremap gs <Cmd>call edit#spell_check()<CR>
nnoremap gS <Cmd>call edit#spell_check(v:count)<CR>
nnoremap gx zg
nnoremap gX zug

" Toggle capitalization or identify character
" Warning: <Plug> invocation cannot happen inside <Cmd>...<CR> pair.
call s:repeat_map('zy', 'CaseToggle', 'my~h`y<Cmd>delmark y<CR>', 'n')
call s:repeat_map('zt', 'CaseTitle', 'myguiw~h`y<Cmd>delmark y<CR>', 'n')
nnoremap <nowait> zu guiw
nnoremap <nowait> zU gUiw
vnoremap zy ~
vnoremap zt gu<Esc>`<~h
vnoremap <nowait> zu gu
vnoremap <nowait> zU gU

" Auto wrap lines or items within motion
" Note: Previously tried to make this operator map but not necessary, should
" already work with 'g@<motion>' invocation of wrapping operator function.
command! -range -nargs=? WrapLines <line1>,<line2>call edit#wrap_lines(<args>)
command! -range -nargs=? WrapItems <line1>,<line2>call edit#wrap_items(<args>)
noremap <expr> gq '<Esc>' . edit#wrap_lines_expr(v:count)
noremap <expr> gQ '<Esc>' . edit#wrap_items_expr(v:count)

" ReST section comment headers
" Warning: <Plug> name should not be subset of other name or results in delay!
call s:repeat_map('g-', 'DashSingle', "<Cmd>call comment#general_line('-', 0)<CR>")
call s:repeat_map('g_', 'DashDouble', "<Cmd>call comment#general_line('=', 1)<CR>")
call s:repeat_map('g=', 'EqualSingle', "<Cmd>call comment#general_line('=', 0)<CR>")
call s:repeat_map('g+', 'EqualDouble', "<Cmd>call comment#general_line('=', 1)<CR>")

" Insert various comment blocks
" Note: No need to repeat any of other commands
inoremap <expr> <C-g>c comment#get_insert()
let s:author = "'Author: Luke Davis (lukelbd@gmail.com)'"
let s:edited = "'Edited: ' . strftime('%Y-%m-%d')"
call s:repeat_map('gc;', 'HeadLine', "<Cmd>call comment#header_line('-', 77, 0)<CR>", 'n')
call s:repeat_map('gc/', 'HeadAuth', '<Cmd>call comment#general_note(' . s:author . ')<CR>', 'n')
call s:repeat_map('gc?', 'HeadEdit', '<Cmd>call comment#general_note(' . s:edited . ')<CR>', 'n')
call s:repeat_map('gc:', '', "<Cmd>call comment#header_line('-', 77, 1)<CR>", 'n')
call s:repeat_map("gc'", '', '<Cmd>call comment#header_inchar()<CR>', 'n')
call s:repeat_map('gc"', '', '<Cmd>call comment#header_inline(5)<CR>', 'n')

" Bracket commands inspired by 'unimpaired'
" Todo: Generalized utils.vim repeat function. See edit.vim
noremap [C <Cmd>call comment#next_block(1, 0)<CR>
noremap ]C <Cmd>call comment#next_block(0, 0)<CR>
noremap [c <Cmd>call comment#next_block(1, 1)<CR>
noremap ]c <Cmd>call comment#next_block(0, 1)<CR>
noremap <Plug>BlankUp <Cmd>call edit#blank_up(v:count1)<CR>
noremap <Plug>BlankDown <Cmd>call edit#blank_down(v:count1)<CR>
map [e <Plug>BlankUp
map ]e <Plug>BlankDown

" Enter insert mode above or below.
" Pressing enter on empty line preserves leading whitespace
nnoremap o oX<Backspace>
nnoremap O OX<Backspace>

" Caps lock toggle and insert mode map that toggles it on and off
" Note: When in paste mode this will trigger literal insert of next escape character
inoremap <expr> <C-v> edit#lang_map()
cnoremap <expr> <C-v> edit#lang_map()

" Insert mode with paste toggling
" Note: Switched easy-align mapping from ga for consistency here
noremap zi gi
noremap zI gI
nnoremap <expr> ga edit#paste_mode() . 'a'
nnoremap <expr> gA edit#paste_mode() . 'A'
nnoremap <expr> gC edit#paste_mode() . 'c'
nnoremap <expr> gi edit#paste_mode() . 'i'
nnoremap <expr> gI edit#paste_mode() . 'I'
nnoremap <expr> go edit#paste_mode() . 'o'
nnoremap <expr> gO edit#paste_mode() . 'O'

" Copy mode and conceal mode ('paste mode' accessible with 'g' insert mappings)
" Turn on for filetypes containing raw possibly heavily wrapped data
augroup copy_toggle
  au!
  let s:filetypes = join(s:data_filetypes + s:copy_filetypes, ',')
  exe 'au FileType ' . s:filetypes . ' call switch#copy(1, 1)'
  let s:filetypes = 'tmux'  " file sub types that otherwise inherit copy toggling
  exe 'au FileType ' . s:filetypes . ' call switch#copy(0, 1)'
augroup END
command! -nargs=? CopyToggle call switch#copy(<args>)
command! -nargs=? ConcealToggle call switch#conceal(<args>)  " mainly just for tex
nnoremap <Leader>c <Cmd>call switch#copy()<CR>
nnoremap <Leader>C <Cmd>call switch#conceal()<CR>

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

" Popup menu and preview window scrolling
" This should work with or without ddc
augroup pum_navigation
  au!
  au BufEnter,InsertLeave * let b:scroll_state = 0
augroup END
inoremap <expr> <Delete> iter#forward_delete()
inoremap <expr> <S-Tab> iter#forward_delete()
noremap <expr> <Up> iter#scroll_count(-0.25)
noremap <expr> <Down> iter#scroll_count(0.25)
noremap <expr> <C-k> iter#scroll_count(-0.25)
noremap <expr> <C-j> iter#scroll_count(0.25)
noremap <expr> <C-u> iter#scroll_count(-0.5)
noremap <expr> <C-d> iter#scroll_count(0.5)
noremap <expr> <C-b> iter#scroll_count(-1.0)
noremap <expr> <C-f> iter#scroll_count(1.0)
inoremap <expr> <Up> iter#scroll_count(-1)
inoremap <expr> <Down> iter#scroll_count(1)
inoremap <expr> <C-k> iter#scroll_count(-1)
inoremap <expr> <C-j> iter#scroll_count(1)
inoremap <expr> <C-u> iter#scroll_count(-0.5)
inoremap <expr> <C-d> iter#scroll_count(0.5)
inoremap <expr> <C-b> iter#scroll_count(-1.0)
inoremap <expr> <C-f> iter#scroll_count(1.0)


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
" Note: See https://vi.stackexchange.com/q/388/8084 for a comparison of plugin managers.
" Currently use junegunn/vim-plug but could switch to Shougo/dein.vim which was derived
" from Shougo/neobundle.vim which was based on vundle. Just a bit faster.
call plug#begin('~/.vim/plugged')

" Escape character handling
" Note: Previously used this to preserve colors in 'command --help' pages but now simply
" redirect git commands that include ANSI colors to their corresponding man pages.
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
call plug#('tpope/vim-repeat')  " basic repeat utility
call plug#('tpope/vim-eunuch')  " shell utils like chmod rename and move
call plug#('tpope/vim-characterize')  " print character info (nicer version of 'ga')

" Panel utilities
" Note: For why to avoid these plugins see https://shapeshed.com/vim-netrw/
" various shortcuts to test whole file, current test, next test, etc.
" call plug#('vim-scripts/EnhancedJumps')  " unnecessary
" call plug#('jistr/vim-nerdtree-tabs')  " unnecessary
" call plug#('scrooloose/nerdtree')  " unnecessary
" call plug#('preservim/tagbar')  " unnecessary
call plug#('junegunn/vim-peekaboo')  " popup display
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
let g:MRU_file = '~/.vim_mru_files'  " default (custom was ignored for some reason)

" Navigation, folding, and registers
" Note: SimPylFold seems to have nice improvements, but while vim-tex-fold adds
" environment folding support, only native vim folds document header, which is
" sometimes useful. Will stick to default unless things change.
" Note: FastFold simply keeps &l:foldmethod = 'manual' most of time and updates on
" saves or fold commands instead of continuously-updating with the highlighting as
" vim tries to do. Works with both native vim syntax folding and expr overrides.
" See: https://github.com/junegunn/vim-peekaboo/issues/84
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" call plug#('easymotion/vim-easymotion')  " extremely slow and overkill
" call plug#('kshenoy/vim-signature')  " unneeded and abandoned
" call plug#('pseewald/vim-anyfold')  " better indent folding (instead of vim syntax)
" call plug#('matze/vim-tex-fold')  " folding tex environments (but no preamble)
call plug#('tmhedberg/SimpylFold')  " python folding
call plug#('Konfekt/FastFold')  " speedup folding
call plug#('justinmk/vim-sneak')  " simple and clean
let g:peekaboo_prefix = '"'
let g:peekaboo_window = 'vertical topleft 30new'
let g:tex_fold_override_foldtext = 0  " disable foldtext() override
let g:SimpylFold_docstring_preview = 0  " disable foldtext() override

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
" Note: Test plugin works for every filetype (simliar to ale).
" Note: ALE plugin looks for all checkers in $PATH
" call plut#('scrooloose/syntastic')  " out of date: https://github.com/vim-syntastic/syntastic/issues/2319
if has('python3') | call plug#('fisadev/vim-isort') | endif
call plug#('vim-test/vim-test')
call plug#('dense-analysis/ale')
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

" User fuzzy selection stuff
" Note: For consistency, specify ctags command below and set 'tags' above accordingly,
" however this should generally not be used since ctags are managed by gutentags.
" Note: You must use fzf#wrap to apply global settings and cannot rely on fzf#run
" return values (will result in weird hard-to-debug issues).
" Note: 'Drop' opens selection in existing window, similar to switchbuf=useopen,usetab.
" However :Buffers still opens duplicate tabs even with fzf_buffers_jump=1.
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
call plug#('junegunn/fzf.vim')  " pin to version supporting :Drop
call plug#('roosta/fzf-folds.vim')  " jump to folds
let g:fzf_action = {
  \ 'ctrl-m': 'Drop', 'ctrl-t': 'Drop',
  \ 'ctrl-i': 'silent!', 'ctrl-x': 'split', 'ctrl-v': 'vsplit'
  \ }  " have file search and grep open to existing window if possible
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
" call plug#('vim-denops/denops.vim', {'commit': 'e641727'})  " ddc dependency
" call plug#('Shougo/ddc.vim', {'commit': 'db28c7d'})  " fourth generation (requires deno)
" call plug#('Shougo/ddc-ui-native', {'commit': 'cc29db3'})  " matching words near cursor
if s:enable_ddc
  call plug#('matsui54/denops-popup-preview.vim')  " show previews during pmenu selection
  call plug#('vim-denops/denops.vim')  " ddc dependency
  call plug#('Shougo/ddc.vim')  " fourth generation (requires deno)
  call plug#('Shougo/ddc-ui-native')  " matching words near cursor
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
" Todo: Generalized function converting text objects into navigation commands? Or
" could just rely on tag and fold jumping for most navigation.
" call plug#('bps/vim-textobj-python')  " not really ever used, just use indent objects
" call plug#('vim-scripts/argtextobj.vim')  " issues with this too
" call plug#('machakann/vim-textobj-functioncall')  " does not work
" call plug#('glts/vim-textobj-comment')  " does not work
call plug#('kana/vim-textobj-user')  " base requirement
call plug#('kana/vim-textobj-line')  " entire line, object is 'l'
call plug#('kana/vim-textobj-entire')  " entire file, object is 'e'
call plug#('kana/vim-textobj-fold')  " folding
call plug#('kana/vim-textobj-indent')  " matching indentation, object is 'i' for deeper indents and 'I' for just contiguous blocks, and using 'a' includes blanklines
call plug#('sgur/vim-textobj-parameter')  " function parameter, object is '='
let g:vim_textobj_parameter_mapping = '='  " avoid ',' conflict with latex

" Formatting stuff. Conjoin plugin removes line continuation characters and is awesome.
" Use vim-easy-align because tabular API is fugly and requires separate maps and does
" not support motions or text objects or ignoring comments by default.
" Note: Seems that mapping <Nop> just sends it to a black hole. Try :map <Nop> after.
" See: https://www.reddit.com/r/vim/comments/g71wyq/delete_continuation_characters_when_joining_lines/
" call plug#('vim-scripts/Align')  " outdated align plugin
" call plug#('vim-scripts/LargeFile')  " disable syntax highlighting for large files
" call plug#('tommcdo/vim-lion')  " alternative to easy-align
" call plug#('godlygeek/tabular')  " difficult to use
" call plug#('terryma/vim-multiple-cursors')  " article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" call plug#('dkarter/bullets.vim')  " list numbering but completely fails
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
let g:jupyter_highlight_cells = 1  " required to prevent error in non-python vim
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

" TeX utilities with syntax highlighting, indentation, mappings, and zotero integration
" Note: For better configuration see https://github.com/lervag/vimtex/issues/204
" Note: Now use https://github.com/msprev/fzf-bibtex with vim integration inside
" autoload/tex.vim rather than unite versions. This is consistent with our choice
" of using fzf over the shuogo unite/denite/ddu plugin series.
" call plug#('twsh/unite-bibtex')  " python 3 version
" call plug#('msprev/unite-bibtex')  " python 2 version
" call plug#('lervag/vimtex')
" call plug#('chrisbra/vim-tex-indent')
" call plug#('rafaqz/citation.vim')
let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {'envs' : {'whitelist': ['enumerate','itemize','math']}}

" Syntax highlighting
" Note impsort sorts import statements and highlights modules using an after/syntax
" call plug#('numirias/semshi',) {'do': ':UpdateRemotePlugins'}  " neovim required
" call plug#('tweekmonster/impsort.vim') " conflicts with isort plugin, also had major issues
" call plug#('vim-python/python-syntax')  " originally from hdima/python-syntax, manually copied version with match case
" call plug#('MortenStabenau/matlab-vim')  " requires tmux installed
" call plug#('daeyun/vim-matlab')  " alternative but project seems dead
" call plug#('neoclide/jsonc.vim')  " vscode-style expanded json syntax, but overkill
call plug#('vim-scripts/applescript.vim')  " applescript syntax support
call plug#('andymass/vim-matlab')  " recently updated vim-matlab fork from matchup author
call plug#('preservim/vim-markdown')  " see .vim/after/syntax.vim for kludge fix
call plug#('tmux-plugins/vim-tmux')
call plug#('anntzer/vim-cython')
call plug#('tpope/vim-liquid')
call plug#('cespare/vim-toml')
call plug#('JuliaEditorSupport/julia-vim')
let g:filetype_m = 'matlab'  " see $VIMRUNTIME/autoload/dist/ft.vim
let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 1
let g:vim_markdown_fenced_languages = ['html', 'python']

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
" call plug#('vim-scripts/Toggle')  " toggling stuff on/off (forked instead)
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

" Scroll wrapped lines
" Note: Use :WrapHeight and :WrapStarts for debugging.
" Note: Instead of native scrollwrapped#scroll() function use an iter#scroll_count()
" function that accounts for open popup windows. See insert-mode section above.
if s:plug_active('vim-scrollwrapped') || s:plug_active('vim-toggle')
  noremap zb <Cmd>Toggle<CR>
  noremap <Leader>w <Cmd>WrapToggle<CR>
  let g:toggle_map = 'zb'  " prevent overwriting <Leader>b
  let g:scrollwrapped_nomap = 1  " instead have advanced iter#scroll_count maps
  let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + ['tex', 'text']
  " let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + s:lang_filetypes
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
" Note: Tried easy motion but way too complicated / slows everything down
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
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
" Note: Custom plugin is similar to :Btags, but does not create or manage tag files,
" instead creating tags whenever buffer is loaded and tracking tags continuously.
" Note: Use .ctags config to ignore particular kinds. Include python imports (Ii),
" tex frame subtitles (g), and vim constants/variables/vimballs (Cvn).
" Warning: Critical to mamba install 'universal-ctags' instead of outdated 'ctags'
" or else will get warnings for non-existing kinds.
if s:plug_active('vim-tags')
  command! -nargs=? TagToggle call switch#tags(<args>)
  command! -bang -nargs=0 ShowTable echo tags#table_kinds(<bang>0) . tags#table_tags(<bang>0)
  nnoremap <Leader>t <Cmd>ShowTable<CR>
  nnoremap <Leader>T <Cmd>ShowTable!<CR>
  nnoremap gt <Cmd>BTags<CR>
  nnoremap gT <Cmd>Tags<CR>
  nnoremap <Leader>O <Cmd>call switch#tags()<CR>
  let g:tags_drop_map = 'g,'  " default is <Leader><Tab>
  let g:tags_jump_map = 'g.'  " default is <Leader><Leader>
  let g:tags_scope_kinds = {'fortran': 'fsmp', 'python': 'fmc', 'vim': 'af', 'tex': 'csub'}
endif

" Gutentag tag generation
" Note: Use gutentags for fancy navigation in buffer / across project, alongside
" custom vim-tags utility for simple navigation in buffer. In future may also support
" vim-tags navigation across open tabs.
" Todo: Update :Open and :Find so they also respect ignore files, consistent with
" bashrc grep/find utilities and with below grep/ctags utilities. For debugging
" parsing of ignore files use below :ShowIgnores command.
if s:plug_active('vim-gutentags')
  augroup guten_tags
    au!
    au User GutentagsUpdated call tag#set_tags()  " enforces &tags variable
  augroup END
  command! -nargs=? ShowIgnores echom 'Tag Ignores: ' . join(tag#get_ignores(0, <q-args>), ' ')
  nnoremap <Leader>< <Cmd>UpdateTags!<CR><Cmd>GutentagsUpdate!<CR><Cmd>echom 'Updated project tags.'<CR>
  nnoremap <Leader>> <Cmd>UpdateTags<CR><Cmd>GutentagsUpdate<CR><Cmd>echom 'Updated file tags.'<CR>
  " let g:gutentags_cache_dir = '~/.vim_tags_cache'  " alternative cache specification
  " let g:gutentags_ctags_tagfile = 'tags'  " used with cache dir
  " let g:gutentags_file_list_command = 'git ls-files'  " alternative to exclude ignores
  let g:gutentags_background_update = 1  " disable for debugging, printing updates
  let g:gutentags_ctags_auto_set_tags = 0  " tag#set_tags() handles this instead
  let g:gutentags_ctags_executable = 'ctags'  " note this respects .ctags config
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

" Enable syntax folding options
" Note: Use native mappings. zr reduces fold level by 1, zm folds more by 1 level,
" zR is big reduction (opens everything), zM is big increase (closes everything),
" zj and zk jump to start/end of *this* fold, [z and ]z jump to next/previous fold,
" zv is open folds enough to view cursor (useful when jumping lines or searching), and
" zn and zN fold toggle between no folds/previous folds without affecting foldlevel.
" Note: Also tried 'vim-lsp' folding but caused huge slowdowns. Should see folding as
" similar to linting/syntax/tags and use separate utility.
" Note: FastFold suggestion for python files is to locally set foldmethod=indent but
" this is constraining. Use SimpylFold instead (they recommend FastFold integration).
" See: https://www.reddit.com/r/vim/comments/c5g6d4/why_is_folding_so_slow/
" See: https://github.com/Konfekt/FastFold and https://github.com/tmhedberg/SimpylFold
if &g:foldenable || s:plug_active('FastFold')
  " Various folding plugins
  let g:fastfold_fold_command_suffixes =  []  " use custom maps instead
  let g:fastfold_fold_movement_commands = []  " or empty list
  let g:fastfold_savehook = 1
  " Native folding settings
  let g:baan_fold = 1
  let g:clojure_fold = 1
  let g:fortran_fold = 1
  let g:javaScript_fold = 1
  let g:markdown_folding = 1
  let g:perl_fold = 1
  let g:perl_fold_blocks = 1
  let g:php_folding = 1
  let g:r_syntax_folding = 1
  let g:rst_fold_enabled = 1
  let g:ruby_fold = 1
  let g:rust_fold = 1
  let g:sh_fold_enabled = 7
  let g:tex_fold_enabled = 1
  let g:vimsyn_folding = 'af'
  let g:xml_syntax_folding = 1
  let g:zsh_fold_enable = 1
endif

" Lsp integration settings
" Warning: foldexpr=lsp#ui#vim#folding#foldexpr() foldtext=lsp#ui#vim#folding#foldtext()
" cause insert mode slowdowns even with g:lsp_fold_enabled = 0. Now use fast fold with
" native syntax foldmethod. Also tried tagfunc=lsp#tagfunc but now use LspDefinition
" Todo: Servers are 'pylsp', 'bash-language-server', 'vim-language-server'. Tried
" 'jedi-language-server' but had issues on linux, and tried 'texlab' but was slow.
" Should install with mamba instead of vim-lsp-settings :LspInstallServer command.
" Todo: Implement server-specific settings on top of defaults via 'vim-lsp-settings'
" plugin, e.g. try to run faster version of 'texlab'. Can use g:lsp_settings or
" vim-lsp-settings/servers files in .config. See: https://github.com/mattn/vim-lsp-settings
" Note: The below autocmd gives signature popups the same borders as hover popups.
" Otherwise they have ugly double border. See: https://github.com/prabirshrestha/vim-lsp/issues/594
" Note: LspDefinition accepts <mods> and stays in current buffer for local definitions,
" so below behavior is close to 'Drop': https://github.com/prabirshrestha/vim-lsp/pull/776
" Note: Highlighting under keywords required for reference jumping with [d and ]d but
" monitor for updates: https://github.com/prabirshrestha/vim-lsp/issues/655
if s:plug_active('vim-lsp')
  " Autocommands and maps
  let s:popup_options = {'borderchars': ['──', '│', '──', '│', '┌', '┐', '┘', '└']}
  augroup lsp_style
    au!
    autocmd User lsp_float_opened call popup_setoptions(
      \ lsp#ui#vim#output#getpreviewwinid(), s:popup_options
    \ )  " apply border to popup
    " autocmd User lsp_setup call lsp#register_server(
    "   \ {'name': 'pylsp', 'cmd': {server_info->['pylsp']}, 'allowlist': ['python']}
    " \ )  " see vim-lsp readme (necessary?)
  augroup END
  command! -nargs=? LspToggle call switch#lsp(<args>)
  noremap gD gdzv<Cmd>noh<CR>
  noremap gd <Cmd>tab LspDefinition<CR>
  noremap [d <Cmd>LspPreviousReference<CR>
  noremap ]d <Cmd>LspNextReference<CR>
  noremap <Leader>f <Cmd>LspReferences<CR>
  noremap <Leader>d <Cmd>LspPeekDefinition<CR>
  noremap <Leader>D <Cmd>LspRename<CR>
  noremap <Leader>a <Cmd>LspHover --ui=float<CR>
  noremap <Leader>A <Cmd>LspSignatureHelp<CR>
  noremap <Leader>& <Cmd>call switch#lsp()<CR>
  noremap <Leader>% <Cmd>CheckHealth<CR>
  noremap <Leader>^ <Cmd>tabnew \| LspManage<CR><Cmd>file lspservers \| call utils#panel_setup(0)<CR>
  " Lsp and server settings
  " noremap <Leader>^ <Cmd>verbose LspStatus<CR>  " use :CheckHealth instead
  let g:lsp_ale_auto_enable_linter = v:false  " default is true
  let g:lsp_diagnostics_enabled = 0  " redundant with ale
  let g:lsp_diagnostics_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_code_action_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_highlight_enabled = 0  " used with reference navigation
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
  let g:denops_disable_version_check = 0  " skip check for recent versions
  let g:denops#deno = 'deno'  " deno executable should be on $PATH
  let g:denops#server#deno_args = [
    \ '--allow-env', '--allow-net', '--allow-read', '--allow-write',
    \ '--v8-flags=--max-heap-size=100,--max-old-space-size=100',
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
" https://mypy.readthedocs.io/en/stable/introduction.html  # type annotation checker
" https://github.com/creativenull/dotfiles/blob/1c23790/config/nvim/init.vim#L481-L487
if s:plug_active('ale')
  " map ]x <Plug>(ale_next_wrap)  " use universal circular scrolling
  " map [x <Plug>(ale_previous_wrap)  " use universal circular scrolling
  " 'python': ['python', 'flake8', 'mypy'],  " need to improve config
  noremap <C-e> <Cmd>cclose<CR><Cmd>lclose<CR>
  command! -nargs=? AleToggle call switch#ale(<args>)
  noremap <Leader>x <Cmd>cclose<CR><Cmd>exe 'lopen ' . float2nr(0.15 * &lines)<CR>
  noremap <Leader>X <Cmd>lclose<CR><Cmd>ALEPopulateQuickfix<CR><Cmd>exe 'copen ' . float2nr(0.15 * &lines)<CR>
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
  let g:ale_python_flake8_options =  '--max-line-length=' . g:linelength . ' --ignore=' . s:flake8_ignore
  let g:ale_set_balloons = 0  " no ballons
  let g:ale_sh_bashate_options = '-i E003 --max-line-length=' . g:linelength
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
  let g:autopep8_max_line_length = g:linelength
  let g:black_linelength = g:linelength
  let g:black_skip_string_normalization = 1
  let g:vim_isort_python_version = 'python3'
  let g:vim_isort_config_overrides = {
    \ 'include_trailing_comma': 'true',
    \ 'force_grid_wrap': 0,
    \ 'multi_line_output': 3,
    \ 'linelength': g:linelength,
    \ }
  let g:formatdef_mpython = '"isort '
    \ . '--trailing-comma '
    \ . '--force-grid-wrap 0 '
    \ . '--multi-line 3 '
    \ . '--line-length ' . g:linelength
    \ . ' - | black --quiet '
    \ . '--skip-string-normalization '
    \ . '--line-length ' . g:linelength . ' - "'
  let g:formatters_python = ['mpython']  " multiple formatters
  let g:formatters_fortran = ['fprettify']
endif

" Conflict highlight settings (warning: change below to 'BufEnter?')
" Shortcuts mirror zf/zF/zd/zD used for manual fold deletion and creation
" Todo: Figure out how to get highlighting closer to marks, without clearing background?
" May need to define custom :syn matches that are not regions. Ask stack exchange.
" Note: Need to remove syntax regions here because they are added on per-filetype
" basis and they wipe out syntax highlighting between the conflict markers. However
" following is unnecessary: silent! doautocmd ConflictMarkerDetect BufReadPost
" See: https://vi.stackexchange.com/q/31623/8084
" See: https://github.com/rhysd/conflict-marker.vim
if s:plug_active('conflict-marker.vim')
  augroup conflict_marker_kludge
    au!
    au BufEnter * silent! syntax clear ConflictMarkerOurs ConflictMarkerTheirs
  augroup END
  highlight ConflictMarker cterm=inverse gui=inverse
  let g:conflict_marker_highlight_group = 'ConflictMarker'
  let g:conflict_marker_begin = '^<<<<<<< .*$'
  let g:conflict_marker_separator = '^=======$'
  let g:conflict_marker_common_ancestors = '^||||||| .*$'
  let g:conflict_marker_end = '^>>>>>>> .*$'
  call s:repeat_map('[F', 'ConflictBackward',
    \ '<Plug>(conflict-marker-prev-hunk)<Plug>(conflict-marker-ourselves)', 'n', 1)
  call s:repeat_map(']F', 'ConflictForward',
    \ '<Plug>(conflict-marker-next-hunk)<Plug>(conflict-marker-ourselves)', 'n', 1)
  nmap [f <Plug>(conflict-marker-prev-hunk)
  nmap ]f <Plug>(conflict-marker-next-hunk)
  nmap gf <Plug>(conflict-marker-ourselves)
  nmap gF <Plug>(conflict-marker-themselves)
  nmap g[ <Plug>(conflict-marker-none)
  nmap g] <Plug>(conflict-marker-both)
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
  noremap <Leader>' <Cmd>BCommits<CR>
  noremap <Leader>" <Cmd>Commits<CR>
  noremap <Leader>j <Cmd>call git#run_command('diff -- %')<CR>
  noremap <Leader>k <Cmd>call git#run_command('diff --staged -- %')<CR>
  noremap <Leader>l <Cmd>call git#run_command('diff -- :/')<CR>
  noremap <Leader>J <Cmd>call git#run_command('stage %')<CR>
  noremap <Leader>K <Cmd>call git#run_command('reset %')<CR>
  noremap <Leader>L <Cmd>call git#run_command('stage :/')<CR>
  noremap <Leader>g <Cmd>call git#run_command('status')<CR>
  noremap <Leader>G <Cmd>call git#commit_run()<CR>
  noremap <Leader>u <Cmd>call git#run_command('push origin')<CR>
  noremap <Leader>U <Cmd>call git#run_command('pull origin')<CR>
  noremap <Leader>- <Cmd>call git#run_command('switch -')<CR>
  noremap <expr> gl git#run_command_expr('blame %', 1)
  noremap gll <Cmd>call git#run_command('blame %')<CR>
  noremap gL <Cmd>call git#run_command('blame')<CR>
  let g:fugitive_legacy_commands = 1  " include deprecated :Git status to go with :Git
  let g:fugitive_dynamic_colors = 1  " fugitive has no HighlightRecent option
endif

" Git gutter settings
" Note: Staging maps below were inspired by tcomment maps 'gc', 'gcc', 'etc.', and
" navigation maps ]g, ]G (navigate to hunks, or navigate and stage hunks) were inspired
" by spell maps ]s, ]S (navigate to spell error, or navigate and fix error). Also note
" <Leader>g both refreshes gutter (e.g. after staging) and previews any result.
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
  call s:repeat_map('[G', 'HunkBackward', '<Cmd>call git#hunk_jump(0, 1)<CR>')
  call s:repeat_map(']G', 'HunkForward', '<Cmd>call git#hunk_jump(1, 1)<CR>')
  noremap ]g <Cmd>call git#hunk_jump(1, 0)<CR>
  noremap [g <Cmd>call git#hunk_jump(0, 0)<CR>
  noremap <Leader>h <Cmd>call git#hunk_preview()<CR>
  noremap <Leader>H <Cmd>call switch#gitgutter()<CR>
  noremap <expr> gh git#hunk_action_expr(1)
  noremap <expr> gH git#hunk_action_expr(0)
  nnoremap <nowait> ghh <Cmd>call git#hunk_action(1)<CR>
  nnoremap <nowait> gHH <Cmd>call git#hunk_action(0)<CR>
endif

" Easy-align with delimiters for case/esac block parentheses and seimcolons, chained
" && and || symbols, or trailing comments. See file empty.txt for easy-align tests.
" Note: Use <Left> to stick delimiter to left instead of right and use * to align
" by all delimiters instead of the default of 1 delimiter.
" Note: Use :EasyAlign<Delim>is, id, or in for shallowest, deepest, or no indentation
" and use <Tab> in interactive mode to cycle through these.
if s:plug_active('vim-easy-align')
  augroup easy_align
    au!
    au BufEnter * let g:easy_align_delimiters['c']['pattern'] = comment#get_regex()
  augroup END
  map z; <Plug>(EasyAlign)
  let s:semi_group = {'pattern': ';\+'}
  let s:case_group = {'pattern': ')', 'stick_to_left': 1, 'left_margin': 0}
  let s:chain_group = {'pattern': '\(&&\|||\)'}  " hello world
  let s:comment_group = {'pattern': '\s#'}  " default value
  let g:easy_align_delimiters = {
    \ ';': s:semi_group,
    \ ')': s:case_group,
    \ '&': s:chain_group,
    \ 'c': s:comment_group,
  \ }
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

" The howmuch.vim plugin. Mnemonic for equation solving is just that parentheses
" show up in equations. Mnemonic for sums is the straight line at bottom of table.
" Note: Usage is HowMuch#HowMuch(isAppend, withEq, sum, engineType) where isAppend
" says whether to replace or append, withEq says whether to include equals sign, sum
" says whether to sum the numbers, and engine is one of 'py', 'bc', 'vim', 'auto'.
if s:plug_active('HowMuch')
  noremap g(( :call HowMuch#HowMuch(0, 0, 1, 'py')<CR>
  noremap g)) :call HowMuch#HowMuch(1, 1, 1, 'py')<CR>
  noremap <expr> g( edit#how_much_expr(0, 0, 1, 'py')
  noremap <expr> g) edit#how_much_expr(1, 1, 1, 'py')
endif

" Speed dating, support date increments
" Todo: Build intuition for how to use this things.
" Note: This overwrites default increment/decrement plugins declared above.
if s:plug_active('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
  noremap <Plug>SpeedDatingFallbackUp <C-a>
  noremap <Plug>SpeedDatingFallbackDown <C-x>
else
  noremap + <C-a>
  noremap - <C-x>
endif

" Undo tree mapping and settings
" Note: Preview window override fails with undotree so use below.
" Todo: Currently can only clear history with 'C' in active pane not externally. Need
" to submit PR for better command. See: https://github.com/mbbill/undotree/issues/158
if s:plug_active('undotree')
  function! Undotree_CustomMap() abort
    noremap <buffer> <nowait> u <C-u>
    noremap <buffer> <nowait> d <C-d>
  endfunc
  noremap gu <Cmd>UndotreeToggle<CR>
  let g:undotree_DiffAutoOpen = 0
  let g:undotree_RelativeTimestamp = 0
  let g:undotree_SetFocusWhenToggle = 1
  let g:undotree_ShortIndicators = 1
  let g:undotree_SplitWidth = 30
endif

" Session saving and updating (the $ matches marker used in statusline)
" Obsession .vimsession activates vim-obsession BufEnter and VimLeavePre
" autocommands and saved session files call let v:this_session=expand("<sfile>:p")
" (so that v:this_session is always set when initializing with vim -S .vimsession)
if s:plug_active('vim-obsession')  " must manually preserve cursor position
  augroup session
    au!
    au VimEnter * if !empty(v:this_session) | exe 'Obsession ' . v:this_session | endif
    au BufReadPost * if line('''"') > 0 && line('''"') <= line('$') | exe 'normal! g`"' | endif
  augroup END
  command! -nargs=* -complete=customlist,vim#session_list Session call vim#init_session(<q-args>)
  noremap <Leader>$ <Cmd>Session<CR>
endif


"-----------------------------------------------------------------------------"
" Final tasks
"-----------------------------------------------------------------------------"
" Color schcmes from flazz/vim-colorschemes
" Warning: This has to come after color schemes are loaded
let s:colorscheme = 'badwolf'
let s:colorscheme = 'fahrenheit'
let s:colorscheme = 'gruvbox'
let s:colorscheme = 'molokai'
let s:colorscheme = 'monokain'
let s:colorscheme = 'oceanicnext'
let s:colorscheme = 'papercolor'  " default

" Apply color scheme
" Note: Avoid triggering 'colorscheme'
if get(g:, 'colors_name', 'default') ==? 'default'
  noautocmd set background=dark  " standardize colors
endif
if has('gui_running') && get(g:, 'colors_name', '') !=? s:colorscheme
  exe 'noautocmd colorscheme ' . s:colorscheme
endif
if has('gui_running')  " revisit these?
  highlight! link vimMap Statement
  highlight! link vimNotFunc Statement
  highlight! link vimFuncKey Statement
  highlight! link vimCommand Statement
endif

" Pick color scheme and toggle hex coloring
" Note: Here :Colorize is from colorizer.vim and :Colors from fzf.vim. Note
" coloring hex strings can cause massive slowdowns so disable by default
noremap <Leader>0 <Cmd>Colors<CR>
noremap <Leader>8 <Cmd>Colorize<CR>

" Scroll over color schemes
" Todo: Finish terminal vim support. Currently sign column gets messed up
" Note: Colors uses fzf to jump between color schemes (fzf.vim command). These utils
" are mainly used for GUI vim, otherwise use terminal themes. Some scheme ideas:
" https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
augroup color_scheme
  au!
  exe 'au ColorScheme default,' . s:colorscheme . ' call vim#config_refresh(0)'
augroup END
command! ColorPrev call iter#next_scheme(1)
command! ColorNext call iter#next_scheme(0)
noremap <Leader>( <Cmd>ColorPrev<CR>
noremap <Leader>) <Cmd>ColorNext<CR>

" Show syntax under cursor and syntax types
" Note: Here 'groups' opens up the page
command! -nargs=0 SyntaxGroup call vim#syntax_group()
command! -nargs=? SyntaxList call vim#syntax_list(<q-args>)
command! -nargs=0 ShowGroups splitbelow help group-name | call search('\*Comment') | normal! zt
noremap <Leader>1 <Cmd>SyntaxGroup<CR>
noremap <Leader>2 <Cmd>SyntaxList<CR>
noremap <Leader>3 <Cmd>ShowGroups<CR>

" Show runtime filetype information
command! -nargs=0 ShowColors call vim#show_colors()
command! -nargs=0 ShowPlugin call vim#show_ftplugin()
command! -nargs=0 ShowSyntax call vim#show_syntax()
noremap <Leader>4 <Cmd>ShowSyntax<CR>
noremap <Leader>5 <Cmd>ShowPlugin<CR>
noremap <Leader>6 <Cmd>ShowColors<CR>

" Repair highlighting. Leveraging ctags integration almost always works.
" Note: This says get the closest tag to the first line in the window, all tags
" rather than top-level only, searching backward, and without circular wrapping.
command! -nargs=1 Sync syntax sync minlines=<args> maxlines=0  " maxlines is an *offset*
command! SyncStart syntax sync fromstart
command! SyncSmart exe 'Sync ' . max([0, line('.') - str2nr(tags#close_tag(line('w0'), 0, 0, 0)[1])])
noremap <Leader>y <Cmd>exe v:count ? 'Sync ' . v:count : 'SyncSmart'<CR>
noremap <Leader>Y <Cmd>SyncStart<CR>

" Show folds with dark against light
highlight Folded ctermbg=Black ctermfg=White cterm=Bold

" Use default colors for transparent conceal and terminal background
highlight Conceal ctermbg=NONE ctermfg=NONE
highlight Terminal ctermbg=NONE ctermfg=NONE

" Special characters
highlight NonText ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE

" Matching parentheses
highlight Todo ctermbg=Red ctermfg=NONE
highlight MatchParen ctermbg=Blue ctermfg=NONE

" Sneak and search highlighting
highlight Sneak ctermbg=DarkMagenta ctermfg=NONE
highlight Search ctermbg=Magenta ctermfg=NONE

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

" Popup menu highlighting
" Use same background as main
highlight Pmenu ctermbg=NONE ctermfg=White cterm=NONE
highlight PmenuSel ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE ctermfg=Black cterm=NONE

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

" Clear past jumps to ignore stuff from plugin files and vimrc and ignore
" outdated buffer marks loaded from .viminfo
" See: https://stackoverflow.com/a/2419692/4970632
" See: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clear_jumps
  au!
  au BufReadPost * clearjumps | delmarks a-z  " see help info on exists()
augroup END
noremap <Leader><Leader> <Cmd>echo system('curl https://icanhazdadjoke.com/')<CR>
delmarks a-z
nohlsearch  " turn off highlighting at startup
redraw!  " prevent statusline error
