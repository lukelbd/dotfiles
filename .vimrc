"-----------------------------------------------------------------------------"
" An enormous vim configuration that does all sorts of magical things.
" Note: Use karabiner to convert ctrl-j/k/h/l into arrow keys. So anything
" mapped to these control combinations below must also be assigned to arrow keys.
" Note: Use iterm to convert impossible or normal-mode-incompatible ctrl+key combos
" to function keys (settings -> keys -> key bindings -> 'send hex codes') various hex codes.
" Note: Select mode (e.g. by typing 'gh') is same as visual but enters insert mode
" when you start typing, to emulate typing after click-and-drag. Never use it.
" See: https://github.com/c-bata/go-prompt/blob/82a9122/input.go#L94-L125
" See: https://eevblog.com/forum/microcontrollers/mystery-of-vt100-keyboard-codes/
" F1: 0x1b 0x4f 0x50 (Ctrl-,) (5-digit codes failed)
" F2: 0x1b 0x4f 0x51 (Ctrl-.)
" F3: 0x1b 0x4f 0x52 (Ctrl-[)
" F4: 0x1b 0x4f 0x53 (Ctrl-])
" F5: 0x1b 0x5b 0x31 0x35 0x7e (Ctrl-/) (3-digit codes failed)
" F6: 0x1b 0x5b 0x31 0x37 0x7e (Ctrl-\)
" F7: 0x1b 0x5b 0x31 0x38 0x7e (Ctrl--)
" F8: 0x1b 0x5b 0x31 0x39 0x7e (Ctrl-=)
" F9: 0x1b 0x5b 0x32 0x30 0x7e (Ctrl-;)
" F10: 0x1b 0x5b 0x32 0x31 0x7e (Ctrl-')
" F11: 0x1b 0x5b 0x32 0x33 0x7e (Ctrl-i) (forum codes required)
" F12: 0x1b 0x5b 0x32 0x34 0x7e (Ctrl-m)
"-----------------------------------------------------------------------------"
" Critical stuff
" Note: See .vim/after/common.vim and .vim/after/filetype.vim for overrides of
" buffer-local syntax and 'conceal-', 'format-' 'linebreak', and 'joinspaces'.
" Note: The refresh variable used in .vim/autoload/vim.vim to autoload recently
" updated script and line length variable used in linting tools below.
" vint: -ProhibitSetNoCompatible
set nocompatible
set encoding=utf-8
scriptencoding utf-8
let g:linelength = 88  " see below configuration
let g:mapleader = "\<Space>"  " see <Leader> mappings
let g:refresh = get(g:, 'refresh', localtime())
let s:conda = $HOME . '/mambaforge/bin'  " gui vim support
let $PATH = ($PATH !~# s:conda ? s:conda : '') . $PATH

" Global settings
" Warning: Tried setting default 'foldmethod' and 'foldexpr' can cause buffer-local
" expression folding e.g. simpylfold to disappear and not retrigger, while using
" setglobal didn't work for filetypes with folding not otherwise auto-triggered (vim)
set autoindent  " indents new lines
set backspace=indent,eol,start  " backspace by indent
set breakindent  " visually indent wrapped lines
set buflisted  " list all buffers by default
set cmdheight=1  " increse to avoid pressing enter to continue 
set colorcolumn=89,121  " color column after recommended length of 88
set complete=.,w,b,u,t,i,k  " prevent slowdowns with ddc
set completeopt-=preview  " use custom denops-popup-preview plugin
set confirm  " require confirmation if you try to quit
set cpoptions=aABceFs  " vim compatibility options
set cursorline  " highlight cursor line
set diffopt=filler,context:5,foldcolumn:2,vertical  " vim-difference display options
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " make sure enabled, allows keycodes
set fillchars=vert:\|,fold:\ ,foldopen:\>,foldclose:<,eob:~,lastline:@  " e.g. fold markers
set foldclose=  " use foldclose=all to auto-close folds when leaving
set foldcolumn=2  " show fold boundaries on column
set foldlevelstart=0  " hide folds when opening (then 'foldlevel' sets current status)
set foldnestmax=5  " allow only a few folding levels
set foldopen=insert,mark,quickfix,tag,undo  " opening folds on cursor movement, disallow block folds
set foldtext=fold#fold_text()  " default function for generating text shown on fold line
set guicursor+=a:blinkon0  " skip blinking cursor
set guifont=Monaco:h12  " match iterm settings
set guioptions=M  " skip $VIMRUNTIME/menu.vim https://vi.stackexchange.com/q/10348/8084
set history=500  " remember 500 previous searches / commands and save in .viminfo
set hlsearch  " highlight as you search forward
set ignorecase  " ignore case in search patterns
set iminsert=0  " disable language maps (used for caps lock)
set incsearch  " show matches incrementally when using e.g. :sub
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
set nofileignorecase  " disable ignoring case (needed for color scheme iteration)
set nohidden  " unload buffers when not open in window
set noinfercase  " do not replace insert-completion with case inferred from typed text
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
set showcmd  " show operator pending command
set shortmess=atqcT  " snappy messages, 'a' does a bunch of common stuff
set showtabline=1  " default 2 spaces
set signcolumn=number  " show signs in number column
set smartcase  " search case insensitive, unless has capital letter
set smartindent  " additional indentation options
set spellcapcheck=  " disable checking for capital start of sentence
set spelllang=en_us  " default to US english
set splitbelow  " splitting behavior
set splitright  " splitting behavior
set splitkeep=screen  " preserve relative position
set switchbuf=useopen,usetab,newtab,uselast  " when switching buffers use open tab
set tabpagemax=300  " allow opening shit load of tabs at once
set tagcase=match  " match case when searching tags
set tagrelative  " paths in tags file are relative to location
set tags=.vimtags,./.vimtags  " home, working dir, or file dir
set tagstack  " auto-add to tagstack with :tag commands
set timeoutlen=0  " othterwise do not wait at all
set ttimeout ttimeoutlen=0  " wait zero seconds for multi-key *keycodes* e.g. <S-Tab> escape code
set ttymouse=sgr  " different cursor shapes for different modes
set undodir=~/.vim_undo_hist  " ./setup enforces existence
set undofile  " save undo history
set undolevels=1000  " maximum undo level
set undoreload=0  " disable reloading
set updatetime=1500  " used for CursorHold autocmds and default is 4000ms
set verbose=0  " increment for debugging, e.g. verbose=2 prints sourced files, extremely useful
set viminfo='500,s50  " remember marks for 500 files (e.g. jumps), exclude registers >10kB of text
set virtualedit=block  " allow cursor to go past line endings in visual block mode
set visualbell  " prefer visual bell to beeps (see also 'noerrorbells')
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu  " command line completion
set wildmode=longest:list,full  " command line completion
let &g:breakat = '  !*-+;:,./?'  " break lines following punctuation
let &g:expandtab = 1  " global expand tab (respect tab toggling)
let &g:foldenable = 1  " global fold enable (respect 'zn' toggling)
let &g:shortmess .= &buftype ==# 'nofile' ? 'I' : ''  " no intro when starting vim
let &g:shiftwidth = 2  " default 2 spaces
let &g:softtabstop = 2  " default 2 spaces
let &g:spell = 0  " global spell disable (only use text files)
let &g:tabstop = 2  " default 2 spaces
let &g:wildignore = join(tag#parse_ignores(0, '~/.wildignore'), ',')

" File types for different unified settings
" Note: Can use plugins added to '~/forks' by adding to s:fork_plugins below
" Note: Here 'man' is for custom man page viewing utils, 'ale-preview' is used with
" :ALEDetail output, 'diff' is used with :GitGutterPreviewHunk output, 'git' is used
" with :Fugitive [show|diff] displays, 'fugitive' is used with other :Fugitive comamnds,
" and 'markdown.lsp_hover' is used with vim-lsp. The remaining filetypes are obvious.
let s:fork_plugins = []  " add to this during development!
let s:vim_plugins = [
  \ 'vim-succinct', 'vim-tags', 'vim-statusline', 'vim-tabline', 'vim-scrollwrapped', 'vim-toggle',
\ ]  " custom vim plugins
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
  \ 'ale-info', 'ale-preview', 'checkhealth', 'codi', 'diff', 'fugitive', 'fugitiveblame', 'git', 'gitcommit',
\ ]  " for popup toggle
let s:panel_filetypes += [
  \ 'help', 'netrw', 'job', '*lsp-hover', 'man', 'mru', 'panel', 'qf', 'undotree', 'taglist', 'vim-plug'
\ ]

" Flake8 ignore list (also apply to autopep8):
" Note: Keep this in sync with 'pep8' and 'black' file
" * Allow line breaks before binary operators (W503)
" * Allow imports after statements for jupytext files (E402)
" * Allow assigning lambda expressions, variable names 'l' and 'I'  (E731, E741)
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
" * Allow two space indent consistent with other languages (E003)
" * Allow sourcing from existing files (SC1090, SC1091)
" * Allow 'useless cat' because left-to-right command chain more intuitive (SC2002)
" * Allow chained '&& ||' operators because sometimes intentional (SC2015)
" * Allow dollar signs in single quotes, looking through single strings (SC2016, SC2043)
" * Allow commas inside arrays and quoting RHS of =~ e.g. for array comparison (SC2054, SC2076)
" * Allow unquoted variables and array expansions, since rarely deal with spaces (SC2068, SC2086)
" * Allow unquoted glob pattern assignments, for loop variables (SC2125, SC2231)
" * Allow defining aliases with variables, 'which' instead of 'command -v' (SC2139, SC2230)
" * Allow building arrays from unquoted result of command (SC2206, SC2207)
" * Allow assigning commands to bash variables (SC2209)
let s:shellcheck_ignore =
  \ 'SC1090,SC1091,SC2002,SC2015,SC2016,SC2041,SC2043,SC2054,SC2076,SC2068,SC2086,'
  \ . 'SC2125,SC2139,SC2206,SC2207,SC2209,SC2230,SC2231'

" Configure cursor shape escapes and screen-restore escapes
" Note: In tmux cursor shape support requires either Ptmux escape codes (e.g. through
" 'vitality') or terminal overrides. Previously used FocusLost autocommand below.
" See: https://github.com/sjl/vitality.vim/issues/29 (cursor changing in tmux panes)
" See: https://stackoverflow.com/a/44473667/4970632 (outdated terminal overrides)
" See: https://vi.stackexchange.com/a/14203/8084 (outdated Ptmux sequences)
" See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
" See: https://www.reddit.com/r/vim/comments/24g8r8/italics_in_terminal_vim_and_tmux/
" call plug#('sjl/vitality.vim')  " outdated
" autocmd FocusLost * exe 'stopinsert'  " outdated
" let g:vitality_always_assume_iterm = 1  " outdated
let &t_vb = ''  " disable visual bell
let &t_ti = "\e7\e[r\e[?47h"  " termcap start (restore screen)
let &t_te = "\e[?47l\e8"  " termcap end (restore screen)
let &t_SI = "\e[6 q"  " insert start
let &t_SR = "\e[4 q"  " replace start
let &t_EI = "\e[2 q"  " insert/replace end
let &t_ZH = "\e[3m"  " italics start
let &t_ZR = "\e[23m"  " italics end

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
  \ '<C-p>', '<C-n>', '<C-a>', '<C-x>', '<C-t>',
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
for s:key in [
  \ '<F1>', '<F2>', '<F3>', '<F4>', '<F5>', '<F6>', '<F7>', '<F8>', '<F9>', '<F10>', '<F11>', '<F12>',
  \ '<C-n>', '<C-p>', '<C-d>', '<C-t>', '<C-h>', '<C-l>', '<C-b>', '<C-z>',
  \ '<C-x><C-n>', '<C-x><C-p>', '<C-x><C-e>', '<C-x><C-y>',
\ ]
  if empty(maparg(s:key, 'i'))
    exe 'inoremap ' . s:key . ' <Nop>'
  endif
endfor

" Remove weird Cheyenne maps, not sure how to isolate/disable /etc/vimrc without
" disabling other stuff we want e.g. synax highlighting
let s:insert_maps = [
  \ '[2;2~', '[2;3~', '[2;5~', '[3;2~', '[3;3~', '[3;5~',
  \ '[5;2~', '[5;3~', '[5;5~', '[6;2~', '[6;3~', '[6;5~',
  \ '[1;2A', '[1;2B', '[1;2C', '[1;2D', '[1;2F', '[1;2H',
  \ '[1;3A', '[1;3B', '[1;3C', '[1;3D', '[1;3F', '[1;3H',
  \ '[1;5A', '[1;5B', '[1;5C', '[1;5D', '[1;5F', '[1;5H',
\ ]
if !empty(mapcheck('<Esc>', 'n'))  " maps staring with escape
  exe 'silent! unmap <Esc>[3~'
  for s:key in s:insert_maps | exe 'silent! iunmap <Esc>' . s:key | endfor
endif

" Suppress all prefix mappings initially so that we avoid accidental actions
" due to entering wrong suffix, e.g. \x in visual mode deleting the selection.
function! s:gobble_map(prefix, mode)
  let char = getcharstr()  " input character
  return empty(maparg(a:prefix . char, a:mode)) ? '' : a:prefix . char
endfunction
for s:pair in [
  \ ['\', 'nv'], ['<Tab>', 'n'], ['<Leader>', 'nv'],
\ ]
  let s:key = s:pair[0]
  for s:mode in split(s:pair[1], '\zs')  " construct list
    if empty(maparg(s:key, s:mode))
      let s:func = "<sid>gobble_map('" . s:key . "', '" . s:mode . "')"
      exe s:mode . 'map <expr> ' . s:key . ' ' . s:func
    endif
  endfor
endfor


"-----------------------------------------------------------------------------"
" File and window utilities
"-----------------------------------------------------------------------------"
" Terminal settings
" Mnemonic is that '!' matches the ':!' used to enter shell commands
" Note: Map Ctrl-c to literal keypress so it does not close window
" Note: Must change local dir or use environment variable to make term pop up here:
" https://vi.stackexchange.com/questions/14519/how-to-run-internal-vim-terminal-at-current-files-dir
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>  " disables all iTerm shortcuts
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>! <Cmd>let $VIMTERMDIR=expand('%:p:h') \| terminal<CR>cd $VIMTERMDIR<CR>

" Save or quit the current session
" Note: To avoid accidentally closing vim do not use mapped shortcuts. Instead
" require manual closure with :qall or :quitall.
command! -nargs=? Autosave call switch#autosave(<args>)
noremap <Leader>W <Cmd>call switch#autosave()<CR>
nnoremap <C-s> <Cmd>call file#update()<CR>
nnoremap <C-q> <Cmd>call window#close_tab()<CR>
nnoremap <C-w> <Cmd>call window#close_pane()<CR>
nnoremap <C-e> <Cmd>call window#close_panes()<CR>

" Refresh session or re-open previous files
" Note: Here :Mru shows tracked files during session, will replace current buffer.
command! -bang -nargs=? Refresh runtime autoload/vim.vim | call vim#config_refresh(<bang>0, <q-args>)
command! -nargs=? Scripts call utils#get_scripts(0, <q-args>)
noremap <leader>e <Cmd>call git#safe_edit()<CR>
noremap <Leader>r <Cmd>redraw! \| echo ''<CR>
noremap <Leader>R <Cmd>Refresh<CR>
let g:MRU_Open_File_Relative = 1

" Buffer selection and management
" Note: Here :WipeBufs replaces :Wipeout plugin since has more sources
command! -nargs=0 ShowBufs call window#show_bufs()
command! -nargs=0 WipeBufs call window#wipe_bufs()
noremap <Leader>q <Cmd>ShowBufs<CR>
noremap <Leader>Q <Cmd>WipeBufs<CR>
nnoremap <F5> <Cmd>Windows<CR>
nnoremap <F6> <Cmd>Buffers<CR>

" Tab selection and management
" Note: Previously used e.g. '<tab>1' maps but not parse count on one keypress
" Note: Here :History includes v:oldfiles and open buffers
for s:key in range(1, 10) | exe 'silent! unmap <Tab>' . s:key | endfor
for s:key in ['.', ',', '>', '<'] | exe 'silent! xunmap z' . s:key | endfor
nnoremap g. <Cmd>call window#jump_tab(v:count)<CR>
nnoremap g> <Cmd>call window#move_tab(v:count)<CR>
nnoremap g, <Cmd>History<CR>
nnoremap g< <Cmd>call file#open_used()<CR>

" Tab and window jumping
nnoremap <Tab>' <Cmd>silent! tabnext #<CR><Cmd>call file#echo_path('tab')<CR>
nnoremap <Tab>; <Cmd>silent! wincmd p<CR><Cmd>call file#echo_path('window')<CR>
nnoremap <Tab>, <Cmd>silent! exe 'tabnext -' . v:count1<CR>
nnoremap <Tab>. <Cmd>silent! exe 'tabnext +' . v:count1<CR>
nnoremap <Tab>j <Cmd>silent! wincmd j<CR>
nnoremap <Tab>k <Cmd>silent! wincmd k<CR>
nnoremap <Tab>h <Cmd>silent! wincmd h<CR>
nnoremap <Tab>l <Cmd>silent! wincmd l<CR>

" Tab and window resizing
nnoremap <Tab>1 <Cmd>exe 'resize ' . window#default_height()<CR>
  \<Cmd>exe 'vert resize ' . window#default_width()<CR>
nnoremap <Tab>2 <Cmd>exe 'resize ' . window#default_height(0.5)<CR>
  \<Cmd>exe 'vert resize ' . window#default_width(0.5)<CR>
nnoremap <Tab>3 <Cmd>exe 'resize ' . window#default_height(0)<CR>
  \<Cmd>exe 'vert resize ' . window#default_width(0)<CR>
nnoremap <Tab>9 <Cmd>call window#change_height(-3 * v:count1)<CR>
nnoremap <Tab>0 <Cmd>call window#change_height(3 * v:count1)<CR>
nnoremap <Tab>( <Cmd>call window#change_height(-6 * v:count1)<CR>
nnoremap <Tab>) <Cmd>call window#change_height(6 * v:count1)<CR>
nnoremap <Tab>[ <Cmd>call window#change_width(-5 * v:count1)<CR>
nnoremap <Tab>] <Cmd>call window#change_width(5 * v:count1)<CR>
nnoremap <Tab>{ <Cmd>call window#change_width(-10 * v:count1)<CR>
nnoremap <Tab>} <Cmd>call window#change_width(10 * v:count1)<CR>
nnoremap <Tab>> <Cmd>call window#move_tab(tabpagenr() + v:count1)<CR>
nnoremap <Tab>< <Cmd>call window#move_tab(tabpagenr() - v:count1)<CR>

" Open file with optional user input
" Note: The <Leader> maps open up views of the current file directory
for s:key in ['q', 'w', 'e', 'r'] | silent! exe 'unmap <Tab>' . s:key | endfor
nnoremap <Tab>o <Cmd>call file#open_init('Drop', 0)<CR>
nnoremap <Tab>p <Cmd>call file#open_init('Files', 0)<CR>
nnoremap <Tab>i <Cmd>call file#open_init('Drop', 1)<CR>
nnoremap <Tab>y <Cmd>call file#open_init('Files', 1)<CR>
nnoremap <Tab>- <Cmd>call file#open_init('Split', 1)<CR>
nnoremap <Tab>= <Cmd>call file#open_init('Split', 0)<CR>
nnoremap <Tab>/ <Cmd>call file#open_dir('topleft vsplit', 1)<CR>
nnoremap <Tab>\ <Cmd>call file#open_dir('topleft vsplit', 0)<CR>

" Open file in current directory or some input directory
" Note: Anything that is not :Files gets passed to :Drop command
" nnoremap <C-g> <Cmd>Locate<CR>  " uses giant database from Unix 'locate'
command! -nargs=* -complete=file Drop call file#open_drop(<f-args>)
command! -nargs=* -complete=file Open call file#open_continuous('Drop', <f-args>)
command! -nargs=* -complete=file Split call file#open_continuous('botright split', <f-args>)
command! -nargs=* -complete=file Vsplit call file#open_continuous('botright vsplit', <f-args>)
nnoremap <F7> <Cmd>exe 'Split ' . fnameescape(fnamemodify(resolve(@%), ':p:h'))<CR>
nnoremap <F8> <Cmd>exe 'Split ' . fnameescape(tag#find_root(@%))<CR>
nnoremap <F11> <Cmd>exe 'Open ' . fnameescape(fnamemodify(resolve(@%), ':p:h'))<CR>
nnoremap <C-y> <Cmd>exe 'Files ' . fnameescape(fnamemodify(resolve(@%), ':p:h'))<CR>
nnoremap <C-o> <Cmd>exe 'Open ' . fnameescape(tag#find_root(@%))<CR>
nnoremap <C-p> <Cmd>exe 'Files ' . fnameescape(tag#find_root(@%))<CR>
nnoremap <C-g> <Cmd>GFiles<CR>

" Related file utilities
" Note: Here :Rename is adapted from the :Rename2 plugin. Usage is :Rename! <dest>
command! -nargs=* -complete=file -bang Rename call file#rename(<q-args>, '<bang>')
command! -nargs=? Paths call file#print_paths(<f-args>)
command! -nargs=? Local call switch#localdir(<args>)
noremap zp <Cmd>Paths<CR>
noremap zP <Cmd>Local<CR>
noremap gp <Cmd>call file#print_exists()<CR>
noremap gP <Cmd>call file#open_drop(expand('<cfile>'))<CR>

" 'Execute' script with different options
" Note: Current idea is to use 'ZZ' for running entire file and 'Z<motion>' for
" running chunks of code. Currently 'Z' only defined for python so use workaround.
" Note: Critical to label these maps so one is not a prefix of another
" or else we can get a delay. For example do not define <Plug>Execute
map Z <Plug>ExecuteMotion
nmap ZZ <Plug>ExecuteFile0
nmap <Leader>z <Plug>ExecuteFile1
nmap <Leader>Z <Plug>ExecuteFile2
noremap <Plug>ExecuteFile0 <Nop>
noremap <Plug>ExecuteFile1 <Nop>
noremap <Plug>ExecuteFile2 <Nop>
noremap <expr> <Plug>ExecuteMotion utils#null_operator_expr()

" Cycle through location list options
" Note: ALE populates the window-local loc list rather than the global quickfix list.
command! -count=1 Lprev call iter#next_loc(<count>, 'loc', 1)
command! -count=1 Lnext call iter#next_loc(<count>, 'loc', 0)
command! -count=1 Qprev call iter#next_loc(<count>, 'qf', 1)
command! -count=1 Qnext call iter#next_loc(<count>, 'qf', 0)
noremap [x <Cmd>exe v:count1 . 'Lprev'<CR>
noremap ]x <Cmd>exe v:count1 . 'Lnext'<CR>
noremap [X <Cmd>exe v:count1 . 'Qprev'<CR>
noremap ]X <Cmd>exe v:count1 . 'Qnext'<CR>

" Helper window style adjustments with less-like shortcuts
" Note: Also
" tried 'FugitiveIndex' and 'FugitivePager' but kept getting confusing issues due
" to e.g. buffer not loaded before autocmds trigger. Instead use below.
let g:tags_skip_filetypes = s:panel_filetypes
let g:tabline_skip_filetypes = s:panel_filetypes
augroup panel_setup
  au!
  au CmdwinEnter * call vim#setup_cmdwin() | call window#setup_panel(1)
  au TerminalWinOpen * call window#setup_panel(1)
  au BufRead,BufEnter fugitive://* if &filetype !=# 'fugitive' | call window#setup_panel() | endif
  au BufEnter *__Tag_List__* call iter#setup_taglist() | call window#setup_panel()
  au FileType help call vim#setup_help()
  au FileType qf call iter#setup_quickfix()
  au FileType taglist call iter#setup_taglist()
  au FileType netrw call file#setup_dir()
  au FileType man call shell#setup_man()
  au FileType gitcommit call git#setup_commit()
  au FileType fugitiveblame call git#setup_blame() | call git#setup_fugitive()
  au FileType git,fugitive call git#setup_fugitive()
  for s:ftype in s:panel_filetypes
    let s:modifiable = s:ftype ==# 'gitcommit'
    exe 'au FileType ' . s:ftype . ' call window#setup_panel(' . s:modifiable . ')'
  endfor
augroup END

" Mapping and command windows
" This uses iterm mapping of <F6> to <C-;> and works in all modes
" See: https://stackoverflow.com/a/41168966/4970632
omap <F9> <Plug>(fzf-maps-o)
xmap <F9> <Plug>(fzf-maps-x)
imap <F9> <Plug>(fzf-maps-i)
nnoremap <F9> <Cmd>Maps<CR>
cnoremap <F9> <Esc><Cmd>Commands<CR>

" Vim help and history windows
" Note: For some reason even though :help :mes claims count N shows the N most recent
" message, for some reason using 1 shows empty line and 2 shows previous plus newline.
for s:key in ['[[', ']]'] | silent! exe 'unmap! g' . s:key | endfor
noremap g] <Cmd>call switch#reveal(1)<CR>
noremap g[ <Cmd>call switch#reveal(0)<CR>
noremap g<Space> <Cmd>call switch#message()<CR>
noremap <Leader><CR> @:
nnoremap <Leader>; q:
nnoremap <Leader>/ q/
nnoremap <Leader>: <Cmd>History:<CR>
nnoremap <Leader>? <Cmd>History/<CR>
nnoremap <Leader>v <Cmd>call vim#show_help()<CR>
nnoremap <Leader>V <Cmd>Helptags<CR>

" Shell commands, search windows, help windows, man pages, and 'cmd --help'. Also
" add shortcut to search for all non-ASCII chars (previously used all escape chars).
" Note: Here 'Man' overrides buffer-local 'Man' command defined on man filetypes, so
" must use autoload function. Also see: https://stackoverflow.com/a/41168966/4970632
command! -complete=shellcmd -nargs=? Help call stack#push_stack('help', 'shell#help_page', <f-args>)
command! -complete=shellcmd -nargs=? Man call stack#push_stack('man', 'shell#man_page', <f-args>)
command! -nargs=0 ClearMan call stack#clear_stack('man')
command! -nargs=0 ShowHelp call stack#show_stack('help')
command! -nargs=0 ShowMan call stack#show_stack('man')
command! -nargs=? PopMan call stack#pop_stack('man', <f-args>)
nnoremap <Leader>n <Cmd>call stack#push_stack('help', 'shell#help_page')<CR>
nnoremap <Leader>m <Cmd>call stack#push_stack('man', 'shell#man_page')<CR>
nnoremap <Leader>N <Cmd>call shell#fzf_help()<CR>
nnoremap <Leader>M <Cmd>call shell#fzf_man()<CR>

" General and popup/preview window scrolling
" Note: Karabiner remaps <S-Left|Right> to <PageUp|PageDown> and <C-Left|Right> to
" <Home|End>. Also note <S-Up|PageDown> and <PageUp|PageDown> scroll pages by default,
" and <Home|End> jump to first/last character of line by default. Here apply option
" arrow navigation by word/WORD to match .inputrc shell navigation settings. Note that
" iterm captures <PageUp|PageDown> but not needed since we have separate vim scrolling.
for s:mode in ['', 'i', 'c']  " note i/c mode shift/control arrows are identical in vim
  exe s:mode . 'noremap <C-Left> <C-Left>'
  exe s:mode . 'noremap <C-Right> <C-Right>'
  exe s:mode . 'noremap <M-Left> <S-Left>'
  exe s:mode . 'noremap <M-Right> <S-Right>'
endfor
noremap <expr> <C-u> iter#scroll_infer(-0.33, 0)
noremap <expr> <C-d> iter#scroll_infer(0.33, 0)
noremap <expr> <C-b> iter#scroll_infer(-0.66, 0)
noremap <expr> <C-f> iter#scroll_infer(0.66, 0)
inoremap <expr> <C-u> iter#scroll_infer(-0.33, 0)
inoremap <expr> <C-d> iter#scroll_infer(0.33, 0)
inoremap <expr> <C-b> iter#scroll_infer(-0.66, 0)
inoremap <expr> <C-f> iter#scroll_infer(0.66, 0)
inoremap <expr> <Up> iter#scroll_infer(-1)
inoremap <expr> <Down> iter#scroll_infer(1)
inoremap <expr> <C-k> iter#scroll_infer(-1)
inoremap <expr> <C-j> iter#scroll_infer(1)

" Insert mode popup window completion
" Todo: Consider using Shuougo pum.vim but hard to implement <CR>/<Tab> features.
" Note: Enter is 'accept' only if we scrolled down while tab always means 'accept'
augroup popup_setup
  au!
  au InsertEnter * set noignorecase | let b:scroll_state = 0
  au InsertLeave * set ignorecase | let b:scroll_state = 0
augroup END
inoremap <silent> <expr> <C-q> iter#complete_popup('<Cmd>pclose<CR>')
inoremap <silent> <expr> <C-w> iter#complete_popup('<Cmd>pclose<CR>')
inoremap <silent> <expr> <Tab> iter#complete_popup('<C-]><Tab>', 2, 1)
inoremap <silent> <expr> <S-Tab> iter#complete_popup(edit#forward_delete(0), 0, 1)
inoremap <silent> <expr> <F2> iter#complete_popup(ddc#map#manual_complete(), 2, 1)
inoremap <silent> <expr> <F1> iter#complete_popup(edit#forward_delete(0), 0, 1)
inoremap <silent> <expr> <Delete> iter#complete_popup(edit#forward_delete(1), 1)
inoremap <silent> <expr> <C-g><CR> iter#complete_popup('<CR>')
inoremap <silent> <expr> <C-g><Space> iter#complete_popup('<Space>')
inoremap <silent> <expr> <C-g><BackSpace> iter#complete_popup('<BackSpace>')
inoremap <silent> <expr> <CR> iter#complete_popup('<C-]><C-r>=edit#delimit_mate("r")<CR>', 1, 1)
inoremap <silent> <expr> <Space> iter#complete_popup('<C-]><C-r>=edit#delimit_mate("s")<CR>', 1)
inoremap <silent> <expr> <Backspace> iter#complete_popup('<C-r>=edit#delimit_mate("b")<CR>', 1)

" Command mode wild menu completion
" Note: This prevents annoyance where multiple old completion options can be shown
" on top of each other if triggered more than once, and permits workflow where hitting
" e.g. <Right> after scrolling will descend into subfolder and show further options.
" Note: This enforces paradigm where <F1>/<F2> is tab-like (horizontally scroll options)
" and <Up>/<Down> is scroll-like (vertically scroll history after clearing options).
augroup complete_setup
  au!
  au CmdlineLeave * let b:show_message = 1
  au CmdlineEnter,CmdlineLeave * let b:complete_state = 0
augroup END
cnoremap <silent> <expr> <Tab> iter#complete_cmdline("\<Tab>", 1)
cnoremap <silent> <expr> <S-Tab> iter#complete_cmdline("\<S-Tab>", 1)
cnoremap <silent> <expr> <F2> iter#complete_cmdline("\<Tab>", 1)
cnoremap <silent> <expr> <F1> iter#complete_cmdline("\<S-Tab>", 1)
cnoremap <silent> <expr> <C-k> iter#complete_cmdline("\<C-p>")
cnoremap <silent> <expr> <C-j> iter#complete_cmdline("\<C-n>")
cnoremap <silent> <expr> <Up> iter#complete_cmdline("\<C-p>")
cnoremap <silent> <expr> <Down> iter#complete_cmdline("\<C-n>")
cnoremap <silent> <expr> <C-h> iter#complete_cmdline("\<Left>")
cnoremap <silent> <expr> <C-l> iter#complete_cmdline("\<Right>")
cnoremap <silent> <expr> <Right> iter#complete_cmdline("\<Right>")
cnoremap <silent> <expr> <Left> iter#complete_cmdline("\<Left>")
cnoremap <silent> <expr> <Delete> iter#complete_cmdline("\<Delete>")
cnoremap <silent> <expr> <BS> iter#complete_cmdline("\<BS>")


"-----------------------------------------------------------------------------"
" Navigation and searching shortcuts
"-----------------------------------------------------------------------------"
" Toggle and navigate visual mode
" Note: Throughout vimrc marks y and z are reserved for internal map utilities. Here
" use 'y' for mouse click location and 'z' for visual mode entrance location, then
" start new visual selection between 'y' and 'z'. Generally 'y' should be temporary
for s:char in ['v', 'V']
  exe 'noremap ' . s:char . ' <Esc>mz' . s:char
endfor
noremap <C-v> <Esc><Cmd>WrapToggle 0<CR>mz<C-v>
nnoremap gn gE/<C-r>/<CR><Cmd>noh<CR>mzgn
nnoremap gN W?<C-r>/<CR><Cmd>noh<CR>mzgN
vnoremap <LeftMouse> <LeftMouse>my<Cmd>exe 'keepjumps normal! `z' . visualmode() . '`y' \| delmark y<CR>
nnoremap <Esc> <Cmd>call map(popup_list(), 'popup_close(v:val)')<CR>
vnoremap <Esc> <Cmd>call map(popup_list(), 'popup_close(v:val)')<CR><C-c>
vnoremap <CR> <Cmd>call map(popup_list(), 'popup_close(v:val)')<CR><C-c>

" Navigate recent tabs and wildmenu options with <C-,>/<C-.>
" Warning: The g:tab_stack variable is used by tags#buffer_sort() to put recently
" used tabs in stack at higher priority than others. Critical to keep variables.
augroup recents_setup
  au!
  au TabLeave * call stack#reset_tabs()  " reset scroll variables before leaving tab
  au CursorHold * call stack#update_tabs()
  au BufWinLeave * call stack#pop_stack('tab', bufnr(expand('<afile>')))
  au VimEnter * silent call stack#clear_stack('tab') | call stack#update_tabs()
augroup END
command! -nargs=0 ClearTabs call stack#clear_stack('tab') | call stack#update_tabs()
command! -nargs=0 ShowTabs call stack#update_tabs() | call stack#show_stack('tab')
command! -nargs=? PopTabs call stack#pop_stack('tab', <f-args>)
silent! exe 'cunmap <Up>' | silent! exe 'cunmap <Down>'
noremap <Tab><CR> <Cmd>call stack#reset_tabs()<CR><Cmd>call stack#update_tabs(2)<CR>
noremap <F1> <Cmd>call stack#scroll_tabs(-v:count1)<CR>
noremap <F2> <Cmd>call stack#scroll_tabs(v:count1)<CR>

" Navigate window jumplist with left/right arrows
" Note: This accounts for iterm function-key maps and karabiner arrow-key maps
" See: https://stackoverflow.com/a/27194972/4970632
augroup jumplist_setup
  au!
  au CursorHold,TextChanged,InsertLeave * if mode() !~# '^no' | call mark#update_jumps() | endif
augroup END
command! -bang -nargs=0 Jumps call mark#fzf_jumps(<bang>0)
noremap z' <Cmd>BLines<CR>
noremap g' <Cmd>call mark#fzf_jumps()<CR>
noremap <C-j> <Cmd>call mark#next_jump(-v:count1)<CR>
noremap <C-k> <Cmd>call mark#next_jump(v:count1)<CR>
noremap <Down> <Cmd>call mark#next_jump(-v:count1)<CR>
noremap <Up> <Cmd>call mark#next_jump(v:count1)<CR>

" Navigate buffer changelist with up/down arrows
" Note: This accounts for iterm function-key maps and karabiner arrow-key maps
" change entries removed. Here <F5>/<F6> are <Ctrl-/>/<Ctrl-\> in iterm
command! -bang -nargs=0 Changes call mark#fzf_changes(<bang>0)
noremap z" <Cmd>Lines<CR>
noremap g" <Cmd>call mark#fzf_changes()<CR>
noremap <C-h> <Cmd>call mark#next_change(-v:count1)<CR>
noremap <C-l> <Cmd>call mark#next_change(v:count1)<CR>
noremap <Left> <Cmd>call mark#next_change(-v:count1)<CR>
noremap <Right> <Cmd>call mark#next_change(v:count1)<CR>

" Navigate matches/sentences/paragraphs without adding to jumplist
" Note: Core vim idea is that these commands take us far away from cursor but
" typically use scrolling to go far away. So use CursorHold approach. Note sentence
" jumping mapped with textobj#sentence#move_[np] for most filetypes.
for s:key in ['(', ')'] | exe 'silent! unmap ' . s:key | endfor
noremap ; <Cmd>call switch#hlsearch(1 - v:hlsearch, 1)<CR>
noremap N <Cmd>call iter#next_match(-v:count1)<CR>
noremap n <Cmd>call iter#next_match(v:count1)<CR>
noremap { <Cmd>exe 'keepjumps normal! ' . v:count1 . '{'<CR>
noremap } <Cmd>exe 'keepjumps normal! ' . v:count1 . '}'<CR>

" Search for non-ascii or non-printable characters
" Note: \x7F-\x9F are actually displayable but not part of ISO standard so not shown
" by vim (also used as dummy no-match in comment.vim). See https://www.ascii-code.com
noremap gr /[^\x00-\x7F]<CR>
noremap gR /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Go to start or end without opening folds
" Useful for e.g. python files with docstring at top and function at bottom
" Note: Mapped jumping commands do not open folds by default, hence the expr below
" Note: Could use e.g. :1<CR> or :$<CR> but that would exclude them from jumplist
noremap G G
noremap <expr> gg 'gg' . (v:count ? 'zv' : '')

" Go to the next or previous unconcealed character
" This respect &concealcursor values
noremap <expr> h syntax#next_char(-v:count1)
noremap <expr> l syntax#next_char(v:count1)

" Go to the previous end-of-word or end-of-WORD
" This makes ge/gE a single-keystroke motion alongside with e/E, w/W, and b/B
noremap m ge
noremap M gE

" Move between alphanumeric groups of characters (i.e. excluding dots, dashes,
" underscores). This is consistent with tmux vim selection navigation
exe 'silent! runtime autoload/utils.vim'
noremap gw <Cmd>call iter#next_motion('w', 0)<CR>
noremap gb <Cmd>call iter#next_motion('b', 0)<CR>
noremap ge <Cmd>call iter#next_motion('e', 0)<CR>
noremap gm <Cmd>call iter#next_motion('ge', 0)<CR>
call utils#repeat_map('o', 'gw', 'AlphaNextStart', "<Cmd>call iter#next_motion('w', 0, v:operator)<CR>")
call utils#repeat_map('o', 'gb', 'AlphaPrevStart', "<Cmd>call iter#next_motion('b', 0, v:operator)<CR>")
call utils#repeat_map('o', 'ge', 'AlphaNextEnd',   "<Cmd>call iter#next_motion('e', 0, v:operator)<CR>")
call utils#repeat_map('o', 'gm', 'AlphaPrevEnd',   "<Cmd>call iter#next_motion('ge, 0, v:operator)<CR>")

" Move between groups of characters with the same case
" This is helpful when refactoring or renaming variables
noremap zw <Cmd>call iter#next_motion('w', 1)<CR>
noremap zb <Cmd>call iter#next_motion('b', 1)<CR>
noremap ze <Cmd>call iter#next_motion('e', 1)<CR>
noremap zm <Cmd>call iter#next_motion('ge', 1)<CR>
call utils#repeat_map('o', 'zw', 'CaseNextStart', "<Cmd>call iter#next_motion('w', 1, v:operator)<CR>")
call utils#repeat_map('o', 'zb', 'CasePrevStart', "<Cmd>call iter#next_motion('b', 1, v:operator)<CR>")
call utils#repeat_map('o', 'ze', 'CaseNextEnd',   "<Cmd>call iter#next_motion('e', 1, v:operator)<CR>")
call utils#repeat_map('o', 'zm', 'CasePrevEnd',   "<Cmd>call iter#next_motion('ge, 1, v:operator)<CR>")

" Screen motion mappings
" Note: This is consistent with 'zl', 'zL', 'zh', 'zH' horizontal scrolling
" and lets us use 'zt' for title case 'zb' for boolean toggle.
for s:key in ['m', 'r', 'R'] | exe 'noremap z' . s:key . ' <Nop>' | endfor
noremap z<Space> zz
noremap z\ zzze
noremap z9 ze
noremap z0 zs
noremap z( zt
noremap z) zb

" Reset manually open-closed folds accounting for custom overrides
" Note: Here 'zV' opens all folds from the most recent search
" Note: Here fold#update_folds() re-enforces special expr fold settings for markdown
" and python files then applies default toggle status that differs from buffer-wide
" &foldlevel for fortran python and tex files (e.g. always open \begin{document}).
for s:key in ['z', 'f', 'F', 'n', 'N'] | silent! exe 'unmap! z' . s:key | endfor
noremap gz <Cmd>Folds<CR>
noremap zg <Cmd>call fold#update_folds(1)<CR><Cmd>echom 'Updated folds'<CR>
noremap zx <Cmd>call fold#update_folds()<CR>zx<Cmd>call fold#regex_levels()<CR>zv
noremap zX <Cmd>call fold#update_folds()<CR>zX<Cmd>call fold#regex_levels()<CR>

" Toggle folds under cursor non-recursively after updating
" Note: Here fold#toggle_range_expr() calls fold#update_folds() before toggling.
" Note: These will overwrite 'fastfold_fold_command_suffixes' generated fold-updating
" maps. However now use even faster / more conservative fold#update_folds() method.
noremap <expr> zz '<Cmd>call fold#update_folds()<CR>' . (foldclosed('.') > 0 ? 'zo' : 'zc')
nnoremap zcc <Cmd>call fold#update_folds()<CR>zc
nnoremap zoo <Cmd>call fold#update_folds()<CR>zo
vnoremap <nowait> zc <Cmd>call fold#update_folds()<CR>zc
vnoremap <nowait> zo <Cmd>call fold#update_folds()<CR>zo
nnoremap <expr> za fold#toggle_range_expr(0)
nnoremap <expr> zc fold#toggle_range_expr(0, 1)
nnoremap <expr> zo fold#toggle_range_expr(0, 0)

" Toggle folds under cursor recursively (fold#update_folds() called internally)
" Note: Here 'zi' will close or open all nested folds under cursor up to level
" parent (use :echom fold#get_current() for debugging). Previously toggled with
" recursive-open then non-recursive close but annoying e.g. for huge classes.
" Note: Here 'zC' will close fold only up to current level or for definitions
" inside class (special case for python). For recursive motion mapping similar
" to 'zc' and 'zo' could use e.g. noremap <expr> zC fold#toggle_range_expr(1, 1)
noremap zi <Cmd>call fold#toggle_nested()<CR>
noremap zC <Cmd>call fold#toggle_current(1)<CR>
noremap zO <Cmd>call fold#toggle_current(0)<CR>
noremap z/ <Cmd>call switch#opensearch(1)<CR>
noremap z? <Cmd>call switch#opensearch(0)<CR>
noremap zN zN<Cmd>call fold#update_folds()<CR>

" Change fold level
" Note: Here fold#update_level() without arguments calls fold#update_folds()
" if the level was changed and prints the level change.
noremap z[ <Cmd>call fold#update_level('m')<CR>
noremap z] <Cmd>call fold#update_level('r')<CR>
noremap z{ <Cmd>call fold#update_level('M')<CR>
noremap z} <Cmd>call fold#update_level('R')<CR>

" Jump to next or previous fold or inside fold
" Note: The bracket maps fail without silent! when inside first fold in file
" Note: Recursive map required for [Z or ]Z or else way more complicated
call utils#repeat_map('', '[Z', 'FoldBackward', '<Cmd>keepjumps normal! zkza<CR>')
call utils#repeat_map('', ']Z', 'FoldForward', '<Cmd>keepjumps normal! zjza<CR>')
noremap [z <Cmd>keepjumps normal! zk<CR><Cmd>keepjumps normal! [z<CR>
noremap ]z <Cmd>keepjumps normal! zj<CR><Cmd>keepjumps normal! [z<CR>
noremap zk <Cmd>keepjumps normal! [z<CR>
noremap zj <Cmd>keepjumps normal! ]z<CR>

" Jump to marks and declare alphabetic marks using counts (navigate with ]` and [`)
" Note: :Marks does not handle file switching and :Jumps has an fzf error so override.
" Note: Uppercase marks unlike lowercase marks work between files and are saved in
" viminfo, so use them. Also numbered marks are mostly internal, can be configured
" to restore cursor position after restarting, also used in viminfo.
command! -bang -nargs=0 Marks call mark#fzf_marks(<bang>0)
command! -nargs=* SetMarks call mark#set_marks(<f-args>)
command! -nargs=* DelMarks call mark#del_marks(<f-args>)
noremap <expr> g_ v:count ? '`' . utils#translate_name('`') : '<Cmd>call mark#fzf_marks()<CR>'
noremap <Leader>- <Cmd>call mark#init_marks()<CR><Cmd>call mark#del_marks(get(g:, 'mark_name', 'A'))<CR>
noremap <Leader>_ <Cmd>call mark#init_marks()<CR><Cmd>call mark#del_marks(utils#translate_name('`'))<CR>
noremap _ <Cmd>call mark#init_marks()<CR><Cmd>call mark#set_marks(utils#translate_name('m'))<CR>
noremap z_ <Cmd>call mark#init_marks()<CR><Cmd>call mark#del_marks()<CR>
noremap <C-n> <Cmd>call mark#init_marks()<CR><Cmd>call mark#next_mark(-v:count1)<CR>
noremap <F12> <Cmd>call mark#init_marks()<CR><Cmd>call mark#next_mark(v:count1)<CR>

" Interactive file jumping with grep commands
" Note: Maps use default search pattern '@/'. Commands can be called with arguments
" to explicitly specify path (without arguments each name has different default).
" Note: These redefinitions add flexibility to native fzf.vim commands, mnemonic
" for alternatives is 'local directory' or 'current file'. Also note Rg is faster and
" has nicer output so use by default: https://unix.stackexchange.com/a/524094/112647
command! -range=0 -bang -nargs=* -complete=file Grep call call('grep#call_rg', [<bang>0, <count>, tags#get_match()expand('<cWORD>'), <f-args>])
command! -range=0 -bang -nargs=* -complete=file Find call call('grep#call_rg', [<bang>0, <count>, '\<' . expand('<cword>') . '\>', <f-args>])
command! -range=0 -bang -nargs=+ -complete=file Ag call grep#call_ag(<bang>0, <count>, <f-args>)
command! -range=0 -bang -nargs=+ -complete=file Rg call grep#call_rg(<bang>0, <count>, <f-args>)
nnoremap g; <Cmd>call grep#call_grep('rg', 1, 0)<CR>
nnoremap g: <Cmd>call grep#call_grep('rg', 1, 1)<CR>
nnoremap z; <Cmd>call grep#call_grep('rg', 0, 2)<CR>
nnoremap z: <Cmd>call grep#call_grep('rg', 1, 2)<CR>

" Convenience grep maps and commands
" Note: Search open files for print statements and project files for others
" Note: Currently do not use :Fixme :Error or :Xxx but these are also highlighted
let s:conflicts = '^' . repeat('[<>=|]', 7) . '\($\|\s\)'
command! -bang -nargs=* -complete=file Debugs call grep#call_rg(<bang>0, 2, '^\s*ic(', <f-args>)
command! -bang -nargs=* -complete=file Prints call grep#call_rg(<bang>0, 2, '^\s*print(', <f-args>)
command! -bang -nargs=* -complete=file Notes call grep#call_rg(<bang>0, 2, '\<\(Note\|NOTE\):', <f-args>)
command! -bang -nargs=* -complete=file Todos call grep#call_rg(<bang>0, 2, '\<\(Todo\|TODO\|Fixme\|FIXME\):', <f-args>)
command! -bang -nargs=* -complete=file Errors call grep#call_rg(<bang>0, 2, '\<\(Warning\|WARNING\|Error\|ERROR\):', <f-args>)
command! -bang -nargs=* -complete=file Conflicts call grep#call_rg(<bang>0, 2, s:conflicts, <f-args>)
noremap g<CR> <Cmd>Debugs!<CR>
noremap gG <Cmd>Conflicts<CR>
noremap gM <Cmd>Prints<CR>
noremap gB <Cmd>Todos<CR>
noremap gW <Cmd>Notes<CR>
noremap gE <Cmd>Errors<CR>
noremap zM <Cmd>Prints!<CR>
noremap zB <Cmd>Todos<CR>
noremap zW <Cmd>Notes<CR>
noremap zE <Cmd>Errors<CR>

" Navigate docstrings and methods
" Capital uses only non-variable-assignment zero-level or first-level docstrings
noremap [d <Cmd>call python#next_docstring(-v:count1, 0)<CR>
noremap ]d <Cmd>call python#next_docstring(v:count1, 0)<CR>
noremap [D <Cmd>call python#next_docstring(-v:count1, 1)<CR>
noremap ]D <Cmd>call python#next_docstring(v:count1, 1)<CR>

" Navigate contiguous comment blocks and headers
" Capital uses only top-level zero-indent comment blocks
noremap [c <Cmd>call comment#next_comment(-v:count1, 0)<CR>
noremap ]c <Cmd>call comment#next_comment(v:count1, 0)<CR>
noremap [C <Cmd>call comment#next_comment(-v:count1, 1)<CR>
noremap ]C <Cmd>call comment#next_comment(v:count1, 1)<CR>
noremap [b <Cmd>call comment#next_header(-v:count1, 0)<CR>
noremap ]b <Cmd>call comment#next_header(v:count1, 0)<CR>
noremap [B <Cmd>call comment#next_header(-v:count1, 1)<CR>
noremap ]B <Cmd>call comment#next_header(v:count1, 1)<CR>

" Navigate notes and todos
" Capital uses only top-level zero-indent headers
noremap [q <Cmd>call comment#next_label(-v:count1, 0, 'todo', 'fixme')<CR>
noremap ]q <Cmd>call comment#next_label(v:count1, 0, 'todo', 'fixme')<CR>
noremap [Q <Cmd>call comment#next_label(-v:count1, 1, 'todo', 'fixme')<CR>
noremap ]Q <Cmd>call comment#next_label(v:count1, 1, 'todo', 'fixme')<CR>
noremap [a <Cmd>call comment#next_label(-v:count1, 0, 'note', 'warning', 'error')<CR>
noremap ]a <Cmd>call comment#next_label(v:count1, 0, 'note', 'warning', 'error')<CR>
noremap [A <Cmd>call comment#next_label(-v:count1, 1, 'note', 'warning', 'error')<CR>
noremap ]A <Cmd>call comment#next_label(v:count1, 1, 'note', 'warning', 'error')<CR>

" Run replacement on this line alone
" Note: Critical to have separate visual and normal maps
" Note: This works recursively with the below maps.
function! s:regex_line() abort
  let char = getcharstr()
  let rmap = '\' . char
  if !empty(maparg(rmap))  " replacement exists
    let motion = mode() !~? '^n' ? '' : char =~? '^[ar]' ? 'ip' : 'al'
    call feedkeys(rmap . motion, 'm')
  endif
endfunction
noremap \\ <Cmd>call <sid>regex_line()<CR>

" Sort selected or motion lines
" See: https://superuser.com/a/189956/506762
vnoremap <expr> \a edit#sort_lines_expr()
nnoremap <expr> \a edit#sort_lines_expr()

" Reverse selected or motion lines
" See: https://vim.fandom.com/wiki/Reverse_order_of_lines
vnoremap <expr> \r edit#reverse_lines_expr()
nnoremap <expr> \r edit#reverse_lines_expr()

" Retab lines and remove trailing whitespace
" Note: Here define g:regex variables analogous to 'g:surround' and 'g:snippet'
" Note: Undo goes to first changed line: https://stackoverflow.com/a/52308371/4970632
for s:mode in ['n', 'v'] | exe s:mode . 'map \w \t' | endfor  " ambiguous maps
let g:sub_trail = ['Removed trailing spaces', '\s\+\ze$', '']  " analogous to surround
let g:sub_tabs = ['Translated tabs', '\t', {-> repeat(' ', &l:tabstop)}]
nnoremap <expr> \t call('edit#sub_replace_expr', g:sub_trail)
vnoremap <expr> \t call('edit#sub_replace_expr', g:sub_trail)
nnoremap <expr> \<Tab> call('edit#sub_replace_expr', g:sub_tabs)
vnoremap <expr> \<Tab> call('edit#sub_replace_expr', g:sub_tabs)

" Replace consecutive spaces on current line with
" one space only if they're not part of indentation
let g:sub_ssqueeze = ['Squeezed consecutive spaces', '\S\@<=\(^ \+\)\@<! \{2,}', '']
let g:sub_sstrip = ['Stripped spaces', '\S\@<=\(^ \+\)\@<! \+', '']
nnoremap <expr> \s call('edit#sub_replace_expr', g:sub_ssqueeze)
nnoremap <expr> \S call('edit#sub_replace_expr', g:sub_sstrip)
vnoremap <expr> \s call('edit#sub_replace_expr', g:sub_ssqueeze)
vnoremap <expr> \S call('edit#sub_replace_expr', g:sub_sstrip)

" Remove empty lines
" Replace consecutive newlines with single newline
let g:sub_esqueeze = ['Squeezed consecutive empty lines', '\(\n\s*\n\)\(\s*\n\)\+', '\1']
let g:sub_estrip = ['Stripped empty lines', '^\s*$\n', '']
nnoremap <expr> \e call('edit#sub_replace_expr', g:sub_esqueeze)
vnoremap <expr> \e call('edit#sub_replace_expr', g:sub_esqueeze)
nnoremap <expr> \E call('edit#sub_replace_expr', g:sub_estrip)
vnoremap <expr> \E call('edit#sub_replace_expr', g:sub_estrip)

" Delete first-level and second-level commented text
" Critical to put in same group since these change the line count
let g:sub_comments = [
  \ 'Removed comments', {->
    \ '\(^\s*' . comment#get_regex() . '.\+$\n\|\s\+' . comment#get_regex() . '.\+$\)'
  \ }, '']
let g:sub_dcomments = [
  \ 'Removed second-level comments', {->
    \ '\(^\s*' . comment#get_regex() . '\s*' . comment#get_regex()
    \ . '.\+$\n\|\s\+' . comment#get_regex() . '\s*' . comment#get_regex() . '.\+$\)'
  \ }, '']
nnoremap <expr> \c call('edit#sub_replace_expr', g:sub_comments)
vnoremap <expr> \c call('edit#sub_replace_expr', g:sub_comments)
nnoremap <expr> \C call('edit#sub_replace_expr', g:sub_dcomments)
vnoremap <expr> \C call('edit#sub_replace_expr', g:sub_dcomments)

" Replace useless bibtex entries
" Previously localized to bibtex ftplugin but no major reason not to include here
let g:sub_bibtex = [
  \ 'Removed unused bibtex entries', '^\s*'
  \ . '\(abstract\|annotate\|copyright\|file\|keywords\|note\|shorttitle\|url\|urldate\)'
  \ . '\s*=\s*{\_.\{-}},\?\n', '']
let g:sub_dbibtex = [
  \ 'Removed doi/unused bibtex entries', '^\s*'
  \ . '\(abstract\|annotate\|copyright\|doi\|file\|language\|keywords\|note\|shorttitle\|url\|urldate\)'
  \ . '\s*=\s*{\_.\{-}},\?\n', '']
nnoremap <expr> \x call('edit#sub_replace_expr', g:sub_bibtex)
vnoremap <expr> \x call('edit#sub_replace_expr', g:sub_bibtex)
nnoremap <expr> \X call('edit#sub_replace_expr', g:sub_dbibtex)
vnoremap <expr> \X call('edit#sub_replace_expr', g:sub_dbibtex)

" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
let g:sub_breaks = ['Converted dashed word breaks', '\(\w\)[-–]\s\+', '\1']
let g:sub_dashes = ['Converted unicode em dashes', '–', '--']
let g:sub_dsingle = ['Converted unicode single quotes', '‘', '`', '’', "'"]
let g:sub_ddouble = ['Converted unicode double quotes', '“', '``', '”', "''"]
nnoremap <expr> \_ call('edit#sub_replace_expr', g:sub_breaks)
vnoremap <expr> \_ call('edit#sub_replace_expr', g:sub_breaks)
nnoremap <expr> \- call('edit#sub_replace_expr', g:sub_dashes)
vnoremap <expr> \- call('edit#sub_replace_expr', g:sub_dashes)
nnoremap <expr> \' call('edit#sub_replace_expr', g:sub_dsingle)
vnoremap <expr> \' call('edit#sub_replace_expr', g:sub_dsingle)
nnoremap <expr> \" call('edit#sub_replace_expr', g:sub_ddouble)
vnoremap <expr> \" call('edit#sub_replace_expr', g:sub_ddouble)


"-----------------------------------------------------------------------------"
" Normal and insert-mode editing
"-----------------------------------------------------------------------------"
" Undo behavior and mappings
" Note: Here edit#insert_undo() returns undo-resetting <C-g>u and resets b:insert_mode
" based on cursor position. Also run this on InsertEnter e.g. after 'ciw' operator map
augroup undo_setup
  au!
  au InsertEnter * call edit#insert_undo()
augroup END
inoremap <expr> <F11> '<Cmd>undo<CR><Esc>' . edit#insert_mode()
inoremap <expr> <F12> edit#insert_undo()
nmap u <Cmd>call repeat#wrap('u', v:count)<CR>
nmap U <Cmd>call repeat#wrap("\<C-r>", v:count)<CR>

" Operator register and display utilities
" Note: For some reason cannot set g:peekaboo_ins_prefix = '' and simply have <C-r>
" trigger the mapping. See https://vi.stackexchange.com/q/5803/8084
imap <expr> <F10> peekaboo#peek(1, "\<C-r>", 0)
nmap <expr> <F10> peekaboo#peek(1, '"', 0)
vmap <expr> <F10> peekaboo#peek(1, '"', 0)

" Record macro by pressing Q (we use lowercase for quitting popup windows)
" and execute macro using ,. Also disable multi-window recordings.
" Note: Visual counts are ignored when followed by operations or recording
" Warning: Critical to use 'nmap' and 'vmap' since do not want operator-mode
nnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_name('q') : '')
nnoremap <expr> , '@' . utils#translate_name('@')
vnoremap <expr> Q 'q' . (empty(reg_recording()) ? utils#translate_name('q') : '')
vnoremap <expr> , '@' . utils#translate_name('@')

" Declare alphabetic registers with count (consistent with mark utilities)
" Note: Pressing ' or " followed by number uses numbered previous-deletion register,
" and pressing ' or " followed by normal-mode command uses black hole or clipboard.
" Note: Pressing double '' or \"\" triggers native or peekaboo register selection. The
" latter is handled inside utils by returning the corresponding <Plug> mapping.
nnoremap <expr> ' (v:count ? '<Esc>' : '') . utils#translate_name('', '_')
nnoremap <expr> " (v:count ? '<Esc>' : '') . utils#translate_name('q', '*')
vnoremap <expr> ' utils#translate_name('', '_')
vnoremap <expr> " utils#translate_name('q', '*')

" Change text, specify registers with counts.
" Note: Uppercase registers are same as lowercase but saved in viminfo.
nnoremap <expr> c (v:count ? '<Esc>' : '') . utils#translate_name('') . edit#insert_mode('c')
nnoremap <expr> C (v:count ? '<Esc>' : '') . utils#translate_name('') . edit#insert_mode('C')
vnoremap <expr> c utils#translate_name('') . edit#insert_mode('c')
vnoremap <expr> C utils#translate_name('') . edit#insert_mode('C')

" Delete text, specify registers with counts (no more dd mapping)
" Note: Visual counts are ignored, and cannot use <Esc> because that exits visual mode
nnoremap <expr> d (v:count ? '<Esc>' : '') . utils#translate_name('') . 'd'
nnoremap <expr> D (v:count ? '<Esc>' : '') . utils#translate_name('') . 'D'
vnoremap <expr> d utils#translate_name('') . 'd'
vnoremap <expr> D utils#translate_name('') . 'D'

" Yank text, specify registers with counts (no more yy mappings)
" Note: Here 'Y' yanks to end of line, matching 'C' and 'D' instead of 'yy' synonym
nnoremap <expr> y (v:count ? '<Esc>' : '') . utils#translate_name('') . 'y'
nnoremap <expr> Y (v:count ? '<Esc>' : '') . utils#translate_name('') . 'y$'
vnoremap <expr> y utils#translate_name('') . 'y'
vnoremap <expr> Y utils#translate_name('') . 'y'

" Paste from the nth previously deleted or changed text.
" Note: This was adapated from https://stackoverflow.com/a/31411902/4970632
nnoremap <expr> p utils#translate_name('') . 'p'
nnoremap <expr> P utils#translate_name('') . 'P'
vnoremap <expr> p utils#translate_name('') . 'p<Cmd>let @+=@0 \| let @"=@0<CR>'
vnoremap <expr> P utils#translate_name('') . 'P<Cmd>let @+=@0 \| let @"=@0<CR>'

" Join v:count lines with coinjoin.vim and keep cursor column
" Note: Here e.g. '2J' joins 'next two lines' instead of 'current plus one'
noremap <silent> J <Cmd>call edit#join_lines(0, 0)<CR>
noremap <silent> K <Cmd>call edit#join_lines(1, 0)<CR>
noremap <silent> gJ <Cmd>call edit#join_lines(0, 1)<CR>
noremap <silent> gK <Cmd>call edit#join_lines(1, 1)<CR>

" Swap characters or lines
" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
call utils#repeat_map('n', 'ch', 'SwapLeft', '<Cmd>call edit#swap_chars(1)<CR>')
call utils#repeat_map('n', 'cl', 'SwapRight', '<Cmd>call edit#swap_chars(0)<CR>')
call utils#repeat_map('n', 'ck', 'SwapAbove', '<Cmd>call edit#swap_lines(1)<CR>')
call utils#repeat_map('n', 'cj', 'SwapBelow', '<Cmd>call edit#swap_lines(0)<CR>')
call utils#repeat_map('n', 'cL', 'SliceLine', 'myi<CR><Esc><Cmd>keepjumps normal! `y<Cmd>delmark y<CR>')

" Spaces and tabs for particular filetypes.
" Note: For some reason must be manually enabled for vim and shell scripts. Not
" sure why but should explore other plugins.
augroup expandtab_setup
  au!
  au FileType vim,tex,sh call switch#expandtab(0, 1)
  au FileType xml,make,text,gitconfig call switch#expandtab(1, 1)
augroup END
command! -nargs=? TabToggle call switch#expandtab(<args>)
nnoremap <Leader><Tab> <Cmd>call switch#expandtab()<CR>

" Increase and decrease indent to level v:count
" Note: To avoid overwriting fugitive inline-diff mappings implement these as
" buffer-local .vim/autoload/common.vim maps. Also map brackets.
nnoremap <expr> > '<Esc>' . edit#indent_items_expr(0, v:count1)
nnoremap <expr> < '<Esc>' . edit#indent_items_expr(1, v:count1)

" Insert empty lines around cursor
" Note: See 'vim-unimpaired' for original. This is similar to vim-succinct 'e' object
call utils#repeat_map('n', '[e', 'BlankUp', '<Cmd>put!=repeat(nr2char(10), v:count1) \| '']+1<CR>')
call utils#repeat_map('n', ']e', 'BlankDown', '<Cmd>put=repeat(nr2char(10), v:count1) \| ''[-1<CR>')

" Stop cursor from moving after undo or leaving insert mode
" Note: Otherwise repeated i<Esc>i<Esc> will drift cursor to left. Also
" critical to keep jumplist or else populated after every single insertion.
augroup insert_repair
  au!
  au InsertLeave * exe 'silent! keepjumps normal! `^'
augroup END
nnoremap <expr> i edit#insert_mode('i')
nnoremap <expr> I edit#insert_mode('I')
nnoremap <expr> a edit#insert_mode('a')
nnoremap <expr> A edit#insert_mode('A')
nnoremap <expr> o edit#insert_mode('o')
nnoremap <expr> O edit#insert_mode('O')

" Enter insert mode from visual mode
" Note: Here 'I' goes to start of selection and 'A' end of selection
exe 'silent! vunmap o' | exe 'silent! vunmap O'
vnoremap <expr> gi '<Esc>' . edit#insert_mode('i')
vnoremap <expr> gI '<Esc>' . edit#insert_mode('I')
vnoremap <expr> ga '<Esc>' . edit#insert_mode('a')
vnoremap <expr> gA '<Esc>' . edit#insert_mode('A')
vnoremap <expr> go '<Esc>' . edit#insert_mode('o')
vnoremap <expr> gO '<Esc>' . edit#insert_mode('O')
vnoremap <expr> I mode() =~# '^[vV]'
  \ ? '<Esc><Cmd>keepjumps normal! `<<CR>' . edit#insert_mode('i') : edit#insert_mode('I')
vnoremap <expr> A mode() =~# '^[vV]'
  \ ? '<Esc><Cmd>keepjumps normal! `><CR>' . edit#insert_mode('a') : edit#insert_mode('A')

" Enter insert mode with paste toggle
" Note: Switched easy-align mapping from ga for consistency here
nnoremap <expr> ga switch#paste() . edit#insert_mode('a')
nnoremap <expr> gA switch#paste() . edit#insert_mode('A')
nnoremap <expr> gi switch#paste() . edit#insert_mode('i')
nnoremap <expr> gI switch#paste() . edit#insert_mode('I')
nnoremap <expr> go switch#paste() . edit#insert_mode('o')
nnoremap <expr> gO switch#paste() . edit#insert_mode('O')
nnoremap <expr> gc switch#paste() . utils#translate_name('') . edit#insert_mode('c')
nnoremap <expr> gC switch#paste() . utils#translate_name('') . edit#insert_mode('C')

" Toggle caps lock, copy mode, and conceal mode
" Turn on for filetypes containing raw possibly heavily wrapped data
augroup copy_setup
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
cnoremap <expr> <C-v> edit#lang_map()
inoremap <expr> <C-v> edit#lang_map()

" ReST section comment headers
" Note: <Plug> name cannot be subset of other name or results in delay
call utils#repeat_map('n', 'g-', 'DashSingle', '<Cmd>call comment#append_line("-", 0)<CR>')
call utils#repeat_map('n', 'z-', 'DashDouble', '<Cmd>call comment#append_line("-", 1)<CR>')
call utils#repeat_map('n', 'g=', 'EqualSingle', '<Cmd>call comment#append_line("=", 0)<CR>')
call utils#repeat_map('n', 'z=', 'EqualDouble', '<Cmd>call comment#append_line("=", 1)<CR>')
call utils#repeat_map('v', 'g-', 'VDashSingle', '<Cmd>call comment#append_line("-", 0, "''<", "''>")<CR>')
call utils#repeat_map('v', 'z-', 'VDashDouble', '<Cmd>call comment#append_line("-", 1, "''<", "''>")<CR>')
call utils#repeat_map('v', 'g=', 'VEqualSingle', '<Cmd>call comment#append_line("=", 0, "''<", "''>")<CR>')
call utils#repeat_map('v', 'z=', 'VEqualDouble', '<Cmd>call comment#append_line("=", 1, "''<", "''>")<CR>')

" Insert various comment blocks
" Note: This disables repitition of title insertions
let s:author = '"Author: Luke Davis (lukelbd@gmail.com)"'
let s:edited = '"Edited: " . strftime("%Y-%m-%d")'
for s:key in ';:/?''"' | silent! exe 'unmap gc' . s:key | endfor
call utils#repeat_map('n', 'z.;', 'HeadLine', '<Cmd>call comment#header_line("-", 77, 0)<CR>')
call utils#repeat_map('n', 'z./', 'HeadAuth', '<Cmd>call comment#append_note(' . s:author . ')<CR>')
call utils#repeat_map('n', 'z.?', 'HeadEdit', '<Cmd>call comment#append_note(' . s:edited . ')<CR>')
call utils#repeat_map('n', 'z.:', '', '<Cmd>call comment#header_line("-", 77, 1)<CR>')
call utils#repeat_map('n', "z.'", '', '<Cmd>call comment#header_inchar()<CR>')
call utils#repeat_map('n', 'z."', '', '<Cmd>call comment#header_inline(5)<CR>')

" Auto wrap the lines or items within motion
" Note: Previously tried to make this operator map but not necessary, should
" already work with 'g@<motion>' invocation of wrapping operator function.
command! -range -nargs=? WrapLines <line1>,<line2>call edit#wrap_lines(<args>)
command! -range -nargs=? WrapItems <line1>,<line2>call edit#wrap_items(<args>)
noremap <expr> gq edit#wrap_lines_expr(v:count)
noremap <expr> gQ edit#wrap_items_expr(v:count)

" Single character mappings
" Here prefer characterize since usually has more info
nnoremap <expr> cx '"_' . edit#insert_mode('s')
nnoremap <expr> gx edit#insert_mode('gi')
map ` <Plug>(characterize)
noremap ~ ga
noremap + <C-a>
noremap - <C-x>
noremap x "_x
noremap X "_X

" Change case for word or motion
" Note: Here 'zu' is analgogous to 'zb' used for boolean toggle
for s:key in ['u', 'U'] | silent! exe 'unmap g' . s:key | endfor
for s:key in ['u', 'U'] | silent! exe 'unmap z' . repeat(s:key, 2) | endfor
call utils#repeat_map('n', 'zu', 'CaseToggle', 'my~h`y<Cmd>delmark y<CR>')
call utils#repeat_map('n', 'zU', 'CaseTitle', 'myguiw~h`y<Cmd>delmark y<CR>')
nnoremap guu guiw
nnoremap gUU gUiw
vnoremap zu g~
vnoremap zU gu<Esc>`<~h

" Update binary spell file
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

" Toggle spell checking
" Turn on for filetypes containing text destined for users
augroup spell_setup
  au!
  let s:filetypes = join(s:lang_filetypes, ',')
  exe 'au FileType ' . s:filetypes . ' setlocal spell'
augroup END
command! SpellToggle call switch#spell(<args>)
command! LangToggle call switch#lang(<args>)
nnoremap <Leader>s <Cmd>call switch#spell()<CR>
nnoremap <Leader>S <Cmd>call switch#lang()<CR>

" Replace misspelled words or define or identify words
call utils#repeat_map('', '[S', 'SpellBackward', '<Cmd>call edit#spell_next(-v:count1)<CR>')
call utils#repeat_map('', ']S', 'SpellForward', '<Cmd>call edit#spell_next(v:count1)<CR>')
noremap [s <Cmd>keepjumps normal! [s<CR>
noremap ]s <Cmd>keepjumps normal! ]s<CR>
noremap gs <Cmd>call edit#spell_check()<CR>
noremap gS <Cmd>call edit#spell_check(v:count)<CR>
noremap zs zg
noremap zS zug


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

" Sessions and history. Use 'vim-session' bash function to restore from
" .vimsession or start new session with that file, or 'vim' then ':so .vimsession'.
" See: https://github.com/junegunn/vim-peekaboo/issues/84
" Note: Here mru can be used to replace current file in window with files from recent
" popup list. Useful e.g. if lsp or fugitive plugins accidentally replace buffer.
" call plug#('thaerkh/vim-workspace')
" call plug#('gioele/vim-autoswap')  " deals with swap files automatically; no longer use them so unnecessary
" call plug#('xolox/vim-reload')  " easier to write custom reload function
" call plug#('Asheq/close-buffers.vim')  " e.g. Bdelete hidden, Bdelete select
" call plug#('artnez/vim-wipeout')  " utility overwritten with custom one
call plug#('tpope/vim-repeat')  " repeat utility
call plug#('tpope/vim-obsession')  " sparse features on top of built-in session behavior
call plug#('junegunn/vim-peekaboo')  " register display
call plug#('mbbill/undotree')  " undo history display
call plug#('yegappan/mru')  " most recent file
let g:MRU_file = '~/.vim_mru_files'  " default (custom was ignored for some reason)
let g:peekaboo_window = 'vertical topleft 30new'
let g:peekaboo_prefix = "\1"  " disable mappings in lieu of 'nomap' option
let g:peekaboo_ins_prefix = "\1"  " disable mappings in lieu of 'nomap' option

" Navigation and searching
" Note: The vim-tags @#&*/?! mappings auto-integrate with vim-indexed-search. Also
" disable colors for increased speed.
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" call plug#('tpope/vim-unimpaired')  " bracket map navigation, no longer used
" call plug#('kshenoy/vim-signature')  " mark signs, unneeded and abandoned
" call plug#('vim-scripts/EnhancedJumps')  " jump list, unnecessary
" call plug#('easymotion/vim-easymotion')  " extremely slow and overkill
call plug#('henrik/vim-indexed-search')
call plug#('andymass/vim-matchup')
call plug#('justinmk/vim-sneak')  " simple and clean
silent! unlet g:loaded_sneak_plugin
let g:matchup_mappings_enabled = 1  " enable default mappings
let g:indexed_search_mappings = 0  " note this also disables <Plug>(mappings)

" Error checking utilities
" Note: Test plugin works for every filetype (simliar to ale).
" Note: ALE plugin looks for all checkers in $PATH
" call plut#('scrooloose/syntastic')  " out of date: https://github.com/vim-syntastic/syntastic/issues/2319
" call plug#('tweekmonster/impsort.vim') " conflicts with isort plugin, also had major issues
if has('python3') | call plug#('fisadev/vim-isort') | endif
call plug#('vim-test/vim-test')
call plug#('dense-analysis/ale')
call plug#('Chiel92/vim-autoformat')
call plug#('tell-k/vim-autopep8')
call plug#('psf/black')

" Git integration utilities
" Note: vim-flog and gv.vim are heavyweight and lightweight commit branch viewing
" plugins. Probably not necessary unless in giant project with tons of branches.
" See: https://github.com/rbong/vim-flog/issues/15
" See: https://vi.stackexchange.com/a/21801/8084
" call plug#('rbong/vim-flog')  " view commit graphs with :Flog, filetype 'Flog' (?)
" call plug#('junegunn/gv.vim')  " view commit graphs with :GV, filetype 'GV'
call plug#('rhysd/conflict-marker.vim')  " highlight conflicts
call plug#('airblade/vim-gitgutter')
call plug#('tpope/vim-fugitive')
let g:conflict_marker_enable_mappings = 0

" Tag integration utilities
" Note: This should work for both fzf ':Tags' (uses 'tags' since relies on tagfiles()
" for detection in autoload/vim.vim) and gutentags (uses only g:gutentags_ctags_tagfile
" for both detection and writing).
" call plug#('xolox/vim-misc')  " dependency for easytags
" call plug#('xolox/vim-easytags')  " kind of old and not that useful honestly
" call plug#('preservim/tagbar')  " unnecessarily complex interface
call plug#('yegappan/taglist')  " simpler interface plus mult-file support
call plug#('ludovicchabant/vim-gutentags')  " slows things down without config
let g:gutentags_enabled = 1
let g:Tlist_Compact_Format = 1
let g:Tlist_Enable_Fold_Column = 1
let g:Tlist_File_Fold_Auto_Close = 1
let g:Tlist_Use_Right_Window = 1
let g:Tlist_WinWidth = 40
" let g:gutentags_enabled = 0

" Fuzzy selection and searching
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
let g:fzf_action = {'ctrl-m': 'Drop', 'ctrl-t': 'Drop', 'ctrl-x': 'split', 'ctrl-v': 'vsplit' }  " have file search and grep open to existing window if possible
let g:fzf_layout = {'down': '~33%'}  " for some reason ignored (version 0.29.0)
let g:fzf_buffers_jump = 1  " have fzf jump to existing window if possible
let g:fzf_tags_command = 'ctags -R -f .vimtags ' . tag#parse_ignores(1)  " added just for safety

" Language server integration
" Note: Here vim-lsp-ale sends diagnostics generated by vim-lsp to ale, does nothing
" when g:lsp_diagnostics_enabled = 0 and can cause :ALEReset to fail, so skip for now.
" In future should use let g:lsp_ale_auto_enable_linter = 0 and then restrict
" integration to particular filetypes by adding 'vim-lsp' to g:ale_linters lists.
" Note: Seems vim-lsp can both detect servers installed separately in $PATH with
" e.g. mamba install python-lsp-server (needed for jupyterlab-lsp) or install
" individually in ~/.local/share/vim-lsp-settings/servers/<server> using the
" vim-lsp-settings plugin commands :LspInstallServer and :LspUninstallServer
" (servers written in python are installed with pip inside 'venv' virtual environment
" subfolders). Most likely harmless if duplicate installations but try to avoid.
" call plug#('natebosch/vim-lsc')  " alternative lsp client
" call plug#('rhysd/vim-lsp-ale')  " send vim-lsp diagnostics to ale, skip for now
if s:enable_lsp
  call plug#('prabirshrestha/vim-lsp')  " ddc-vim-lsp requirement
  call plug#('mattn/vim-lsp-settings')  " auto vim-lsp settings
  call plug#('rhysd/vim-healthcheck')  " plugin help
  let g:lsp_float_max_width = g:linelength  "  some reason results in wider windows
  let g:lsp_preview_max_width = g:linelength  "  some reason results in wider windows
  let g:lsp_preview_max_height = 2 * g:linelength
endif

" Insert completion engines
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
" call plug#('Shougo/ddc-source-omni')  " include &omnifunc results
if s:enable_ddc
  call plug#('tani/ddc-fuzzy')  " filter for fuzzy matching similar to fzf
  call plug#('matsui54/ddc-buffer')  " matching words from buffer (as in neocomplete)
  call plug#('shun/ddc-source-vim-lsp')  " language server protocol completion for vim 8+
  call plug#('Shougo/ddc-source-around')  " matching words near cursor
  call plug#('LumaKernel/ddc-source-file')  " matching file names
  call plug#('delphinus/ddc-ctags')  " current file ctags
endif

" Delimiters and snippets. Use vim-surround not vim-sandwich because mappings are
" better and API is nicer (note neither can delete surrounding delimiters). Should
" investigate snippet utils further but so far vim-succinct is fine.
" Todo: Investigate snippet further, but so far primitive vim-succinct snippets are fine
" See: https://github.com/wellle/targets.vim/issues/225
" See: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
" call plug#('wellle/targets.vim')
" call plug#('machakann/vim-sandwich')
" call plug#('honza/vim-snippets')  " reference snippet files supplied to e.g. ultisnips
" call plug#('LucHermitte/mu-template')  " file template and snippet engine mashup, not popular
" call plug#('Shougo/neosnippet.vim')  " snippets consistent with ddc
" call plug#('Shougo/neosnippet-snippets')  " standard snippet library
" call plug#('Shougo/deoppet.nvim')  " next generation snippets (does not work in vim8)
" call plug#('hrsh7th/vim-vsnip')  " snippets
" call plug#('hrsh7th/vim-vsnip-integ')  " integration with ddc.vim
" call plug#('SirVer/ultisnips')  " fancy snippet actions
call plug#('tpope/vim-surround')
call plug#('raimondi/delimitmate')

" Text object definitions
" Note: Also use vim-succinct to auto-convert every vim-surround delimiter
" definition to 'inner'/'outer' delimiter inclusive/exclusive objects.
" call plug#('bps/vim-textobj-python')  " use braceless 'm' instead
" call plug#('machakann/vim-textobj-functioncall')  " does not work
" call plug#('vim-scripts/argtextobj.vim')  " issues with this too
" call plug#('beloglazov/vim-textobj-quotes')  " multi-line string, but not docstrings
" call plug#('thalesmello/vim-textobj-multiline-str')  " multi-line string, adapted in python.vim
call plug#('kana/vim-textobj-user')  " base requirement
call plug#('kana/vim-textobj-line')  " entire line, object is 'l'
call plug#('kana/vim-textobj-entire')  " entire file, object is 'e'
call plug#('kana/vim-textobj-fold')  " select current fold, object is 'z'
call plug#('kana/vim-textobj-indent')  " indentation, object is 'i' or 'I' and 'a' includes empty lines
call plug#('sgur/vim-textobj-parameter')  " function parameter, object is '='
call plug#('glts/vim-textobj-comment')  " comment blocks, object is 'C' (see below)
call plug#('tkhren/vim-textobj-numeral')  " numerals, e.g. 1.1234e-10
call plug#('preservim/vim-textobj-sentence')  " sentence objects
let g:textobj_numeral_no_default_key_mappings = 1  " defined in vim-succinct block
let g:loaded_textobj_comment = 1  " avoid default mappings (see below)
let g:loaded_textobj_entire = 1  " avoid default mappings (see below)

" Alignment and calculations
" Note: tcomment_vim is nice minimal extension of vim-commentary, include explicit
" commenting and uncommenting and 'blockwise' commenting with g>b and g<b
" See: https://www.reddit.com/r/vim/comments/g71wyq/delete_continuation_characters_when_joining_lines/
" call plug#('scrooloose/nerdcommenter')  " too complex
" call plug#('tpope/vim-commentary')  " too simple
" call plug#('vim-scripts/Align')  " outdated align plugin
" call plug#('tommcdo/vim-lion')  " alternative to easy-align
" call plug#('godlygeek/tabular')  " difficult to use
" call plug#('terryma/vim-multiple-cursors')  " article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" call plug#('dkarter/bullets.vim')  " list numbering but completely fails
" call plug#('stormherz/tablify')  " fancy ++ style tables, for now use == instead
" call plug#('Rykka/riv.vim')  " fancy tables, let g:riv_python_rst_hl = 1
" call plug#('triglav/vim-visual-increment')  " superceded by vim-speeddating
" call plug#('vim-scripts/Toggle')  " toggling stuff on/off (forked instead)
call plug#('junegunn/vim-easy-align')  " align with motions, text objects, and ignores comments
call plug#('AndrewRadev/splitjoin.vim')  " single-line multi-line transition hardly every needed
call plug#('flwyd/vim-conjoin')  " join and remove line continuation characters
call plug#('tpope/vim-speeddating')  " dates and stuff
call plug#('sk1418/HowMuch')  " calcuations
call plug#('tomtom/tcomment_vim')  " comment motions
call plug#('tpope/vim-characterize')  " print character (nicer version of 'ga')
call plug#('metakirby5/codi.vim')  " calculators
silent! unlet g:loaded_tcomment
let g:HowMuch_no_mappings = 1
let g:speeddating_no_mappings = 1
let g:conjoin_map_J = "\1"  " disable mapping in lieu of 'nomap' option
let g:conjoin_map_gJ = "\1"  " disable mapping in lieu of 'nomap' option
let g:splitjoin_join_mapping  = 'cJ'
let g:splitjoin_split_mapping = 'cK'
let g:splitjoin_trailing_comma = 1
let g:splitjoin_normalize_whitespace = 1
let g:splitjoin_python_brackets_on_separate_lines = 1

" Folding and indentation
" Note: SimPylFold seems to have nice improvements, but while vim-tex-fold adds
" environment folding support, only native vim folds document header, which is
" sometimes useful. Will stick to default unless things change.
" Note: FastFold simply keeps &l:foldmethod = 'manual' most of time and updates on
" saves or fold commands instead of continuously-updating with the highlighting as
" vim tries to do. Works with both native vim syntax folding and expr overrides.
" Note: Indentline completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes. Instead use
" braceless.vim highlighting, appears only when cursor is there.
" call plug#('pseewald/vim-anyfold')  " better indent folding (instead of vim syntax)
" call plug#('matze/vim-tex-fold')  " folding tex environments (but no preamble)
" call plug#('yggdroot/indentline')  " vertical indent line
" call plug#('nathanaelkane/vim-indent-guides')  " alternative indent guide
call plug#('tweekmonster/braceless.vim')  " partial overlap with vim-textobj-indent, but these include header
call plug#('tmhedberg/SimpylFold')  " python folding
call plug#('Konfekt/FastFold')  " speedup folding
let g:braceless_block_key = 'm'  " captures if, for, def, etc.
let g:braceless_generate_scripts = 1  " see :help, required since we active in ftplugin
let g:tex_fold_override_foldtext = 0  " disable foldtext() override
let g:SimpylFold_docstring_preview = 0  " disable foldtext() override

" Syntax highlighting
" Note: Use :InlineEdit within blocks to open temporary buffer for editing. The buffer
" will have filetype-aware settings. See: https://github.com/AndrewRadev/inline_edit.vim
" Note: Here 'pythonic' vim-markdown folding prevents bug where folds auto-close after
" insert mode and ignores primary headers so entire document is not folded.
" See: https://vi.stackexchange.com/a/4892/8084
" See: https://github.com/preservim/vim-markdown/issues/516 and 489
" call plug#('numirias/semshi', {'do': ':UpdateRemotePlugins'})  " neovim required
" call plug#('vim-python/python-syntax')  " originally from hdima/python-syntax, manually copied version with match case
" call plug#('MortenStabenau/matlab-vim')  " requires tmux installed
" call plug#('daeyun/vim-matlab')  " alternative but project seems dead
" call plug#('neoclide/jsonc.vim')  " vscode-style expanded json syntax, but overkill
" call plug#('AndrewRadev/inline_edit.vim')  " inline syntax highlighting
call plug#('vim-scripts/applescript.vim')  " applescript syntax support
call plug#('andymass/vim-matlab')  " recently updated vim-matlab fork from matchup author
call plug#('preservim/vim-markdown')  " see .vim/after/syntax.vim for kludge fix
call plug#('tmux-plugins/vim-tmux')
call plug#('anntzer/vim-cython')
call plug#('tpope/vim-liquid')
call plug#('cespare/vim-toml')
call plug#('JuliaEditorSupport/julia-vim')
call plug#('flazz/vim-colorschemes')  " for macvim
call plug#('fcpg/vim-fahrenheit')  " for macvim
call plug#('KabbAmine/yowish.vim')  " for macvim
call plug#('lilydjwg/colorizer')  " only in macvim or when &t_Co == 256
let g:colorizer_nomap = 1  " use custom mapping
let g:colorizer_startup = 0  " too expensive to enable at startup
let g:filetype_m = 'matlab'  " see $VIMRUNTIME/autoload/dist/ft.vim
let g:latex_to_unicode_file_types = ['julia']  " julia-vim feature
let g:vim_markdown_conceal = 1  " conceal stuff
let g:vim_markdown_conceal_code_blocks = 0  " show code fences
let g:vim_markdown_fenced_languages = ['html', 'python']
let g:vim_markdown_folding_level = 0  " pythonic folding level
let g:vim_markdown_folding_style_pythonic = 1  " repair fold close issue
let g:vim_markdown_override_foldtext = 1  " also overwrite function (see common.vim)
let g:vim_markdown_math = 1 " turn on $$ math

" Filetype utilities
" Todo: Test vim-repl, seems to support all REPLs, but only :terminal is supported.
" Todo: Test vimcmdline, claims it can also run in tmux pane or 'terminal emulator'.
" Note: Now use https://github.com/msprev/fzf-bibtex with autoload/tex.vim integration
" Note: For better configuration see https://github.com/lervag/vimtex/issues/204
" call plug#('sillybun/vim-repl')  " run arbitrary code snippets
" call plug#('jalvesaq/vimcmdline')  " run arbitrary code snippets
" call plug#('vim-scripts/Pydiction')  " changes completeopt and dictionary and stuff
" call plug#('cjrh/vim-conda')  " for changing anconda VIRTUALENV but probably don't need it
" call plug#('klen/python-mode')  " incompatible with jedi-vim and outdated
" call plug#('ivanov/vim-ipython')  " replaced by jupyter-vim
" call plug#('davidhalter/jedi-vim')  " use vim-lsp with mamba install python-lsp-server
" call plug#('jeetsukumaran/vim-python-indent-black')  " black style indentexpr, but too buggy
" call plug#('lukelbd/jupyter-vim', {'branch': 'buffer-local-highlighting'})  " temporary
" call plug#('fs111/pydoc.vim')  " python docstring browser, now use custom utility
" call plug#('rafaqz/citation.vim')  " unite.vim citation source
" call plug#('twsh/unite-bibtex')  " unite.vim python 3 citation source
" call plug#('lervag/vimtex')  " giant tex plugin
" let g:pydiction_location = expand('~') . '/.vim/plugged/Pydiction/complete-dict'  " for pydiction
call plug#('heavenshell/vim-pydocstring')  " automatic docstring templates
call plug#('Vimjas/vim-python-pep8-indent')  " pep8 style indentexpr, actually seems to respect black style?
call plug#('goerz/jupytext.vim')  " edit ipython notebooks
call plug#('jupyter-vim/jupyter-vim')  " pair with jupyter consoles, support %% highlighting
let g:pydocstring_formatter = 'numpy'  " default is google so switch to numpy
let g:pydocstring_doq_path = '~/mambaforge/bin/doq'  " critical to mamba install
let g:jupyter_highlight_cells = 1  " required to prevent error in non-python vim
let g:jupyter_cell_separators = ['# %%', '# <codecell>']
let g:jupyter_mapkeys = 0
let g:jupytext_fmt = 'py:percent'
let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {'envs' : {'whitelist': ['enumerate', 'itemize', 'math']}}

" Shell utilities
" Note: For why to avoid these plugins see https://shapeshed.com/vim-netrw/
" various shortcuts to test whole file, current test, next test, etc.
" Note: Previously used ansi plugin to preserve colors in 'command --help' pages
" but now redirect colorized git help info to their corresponding man pages.
" call plug#('powerman/vim-plugin-AnsiEsc')  " colorize help pages
" call plug#('Shougo/vimshell.vim')  " first generation :terminal add-ons
" call plug#('Shougo/deol.nvim')  " second generation :terminal add-ons
" call plug#('jez/vim-superman')  " replaced with vim.vim and bashrc utilities
" call plug#('jistr/vim-nerdtree-tabs')  " unnecessary
" call plug#('scrooloose/nerdtree')  " unnecessary
" call plug#('vim-scripts/LargeFile')  " disable syntax highlighting for large files
call plug#('tpope/vim-eunuch')  " shell utils like chmod rename and move
let g:LargeFile = 1  " megabyte limit

" Custom plugins or forks and try to load locally if possible!
" Note: ^= prepends to list and += appends. Also previously added forks here but
" probably simpler/consistent to simply source files.
" Note: This needs to come after or else (1) vim-succinct will not be able to use
" textobj#user#plugin, (2) the initial statusline will possibly be incomplete, and
" (3) cannot wrap indexed-search plugin with tags file.
for s:plugin in s:vim_plugins
  let s:path = expand('~/software/' . s:plugin)
  let s:name = 'lukelbd/' . s:plugin
  if isdirectory(s:path) | call s:plug_local(s:path) | else | call plug#(s:name) | endif
endfor
for s:plugin in s:fork_plugins
  let s:path = expand('~/forks/' . s:plugin)
  let s:name = 'lukelbd/' . s:plugin
  if isdirectory(s:path) | call s:plug_local(s:path) | else | call plug#(s:name) | endif
endfor
let g:toggle_map = 'z<CR>'  " adjust toggle mapping (note this is repeatable)
let g:scrollwrapped_nomap = 1  " instead have advanced iter#scroll_infer maps
let g:scrollwrapped_wrap_filetypes = s:copy_filetypes + ['tex', 'text']
noremap <Leader>w <Cmd>WrapToggle<CR>

" End plugin manager. Also declares filetype plugin, syntax, and indent on
" Note every BufRead autocmd inside an ftdetect/filename.vim file is automatically
" made part of the 'filetypedetect' augroup (that's why it exists!).
call plug#end()
silent! delcommand SplitjoinJoin
silent! delcommand SplitjoinSplit


"-----------------------------------------------------------------------------"
" Plugin sttings
"-----------------------------------------------------------------------------"
" Sneak between two-character patterns
" Note: Tried easy motion but way too complicated / slows everything down
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
if s:plug_active('vim-sneak') || s:plug_active('vim-indexed-search')
  map f <Plug>Sneak_f
  map F <Plug>Sneak_F
  map t <Plug>Sneak_t
  map T <Plug>Sneak_T
  nmap s <Plug>Sneak_s
  nmap S <Plug>Sneak_S
  vmap s <Plug>Sneak_s
  vmap S <Plug>Sneak_S
  let g:sneak#label = 1  " show labels on matches for quicker jumping
  let g:sneak#s_next = 1  " press s/f/t repeatedly to jump matches until next motion
  let g:sneak#f_reset = 0  " keep f search separate from s
  let g:sneak#t_reset = 0  " keep t search separate from s
  let g:sneak#absolute_dir = 1  " same search direction no matter initial direction
  let g:sneak#use_ic_scs = 0  " search always case-sensitive, similar to '*' or popup
  let g:indexed_search_center = 0  " disable centered match jumping
  let g:indexed_search_colors = 0  " disable colors for speed
  let g:indexed_search_dont_move = 1  " irrelevant due to custom mappings
  let g:indexed_search_line_info = 1  " show first and last line indicators
  let g:indexed_search_max_lines = 100000  " increase from default of 3000 for log files
  let g:indexed_search_shortmess = 1  " shorter message
  let g:indexed_search_numbered_only = 1  " only show numbers
  let g:indexed_search_n_always_searches_forward = 1  " see also vim-sneak
endif

" Matching and searching settings
" Note: Here vim-tags searching integrates with indexed-search and vim-succinct
" surround delimiters integrate with matchup '%' keys.
" Note: Most custom delimiters defined in succinct.vim and ftplugin files. Also use
" custom names for several mappings and define textobj mappings.
if s:plug_active('vim-succinct') || s:plug_active('vim-matchup')
  " imap <S-Tab> <Plug>delimitMateS-Tab
  " imap <S-Tab> <Plug>delimitMateJumpMany
  let g:delimitMate_expand_cr = 2  " expand even if non empty
  let g:delimitMate_expand_space = 1
  let g:delimitMate_jump_expansion = 1
  let g:delimitMate_excluded_regions = 'String'  " disabled inside by default
  let g:succinct_surround_map = '<C-s>'
  let g:succinct_snippet_map = '<C-e>'
  let g:succinct_prevdelim_map = '<F3>'  " set manually above
  let g:succinct_nextdelim_map = '<F4>'  " set manually above
  let g:matchup_delim_nomids = 1  " skip e.g. 'else' during % jumps and text objects
  let g:matchup_delim_noskips = 1  " skip e.g. 'if' 'endif' in comments
  let g:matchup_matchparen_enabled = 1  " enable matchupt matching on startup
  let g:matchup_motion_keepjumps = 1  " preserve jumps when navigating
  let g:matchup_surround_enabled = 1  " enable 'ds%' 'cs%' mappings
  let g:matchup_transmute_enabled = 0  " issues with tex, use vim-succinct instead
  let g:matchup_text_obj_linewise_operators = ['y', 'd', 'c', 'v', 'V', "\<C-v>"]
endif

" Text object settings
" Note: Here use mnemonic 'v' for 'value' and 'C' for comment. The first avoids
" conflicts with ftplugin/tex.vim and the second with 'c' curly braces.
if s:plug_active('vim-textobj-user')
  augroup textobj_setup
    au!
    au VimEnter * call textobj#sentence#init()
  augroup END
  map ]v <Plug>(textobj-numeral-n)
  map [v <Plug>(textobj-numeral-p)
  map ]V <Plug>(textobj-numeral-N)
  map ]V <Plug>(textobj-numeral-P)
  omap av <Plug>(textobj-numeral-a)
  vmap av <Plug>(textobj-numeral-a)
  omap iv <Plug>(textobj-numeral-i)
  vmap iv <Plug>(textobj-numeral-i)
  let g:textobj#sentence#select = 's'  " smarter sentence selection
  let g:textobj#sentence#move_p = '('  " smarter sentence navigation
  let g:textobj#sentence#move_n = ')'  " smarter sentence navigation
  let g:vim_textobj_parameter_mapping = 'k'  " i.e. 'keyword' or 'keyword argument'
  let s:textobj_alpha = {
    \ 'g': '\(\<\|[^0-9A-Za-z]\)\r\(\>\|[^0-9A-Za-z]\)',
    \ 'h': '\(\<\|[^0-9a-z]\)\r[0-9a-z]\(\>\|[^0-9a-z]\)\@=',
  \ }
  let s:textobj_comment = {
    \ 'select-i': 'iC', 'select-i-function': 'textobj#comment#select_i',
    \ 'select-a': 'aC', 'select-a-function': 'textobj#comment#select_a',
  \ }
  let s:textobj_entire = {
    \ 'select-a': 'aE',  'select-a-function': 'textobj#entire#select_a',
    \ 'select-i': 'iE',  'select-i-function': 'textobj#entire#select_i'
  \ }
  call succinct#add_objects('alpha', s:textobj_alpha, 0, 1, 1)
  call textobj#user#plugin('comment', {'-': s:textobj_comment})  " do not add <Plug> suffix
  call textobj#user#plugin('entire', {'-': s:textobj_entire})  " do not add <Plug> suffix
endif

" Toggle comments and whatnot
" Note: This disable several maps but keeps many others. Remove unmap commands
" after restarting existing vim sessions.
if s:plug_active('tcomment_vim')
  for s:key in ['.', '"', "'", ':', '?', '/', ';']
    silent! exe 'unmap g.' . s:key
  endfor
  for s:key1 in ['>', '<'] | for s:key2 in ['b', 'c', '>', '<>']
    silent! exe 'unmap g' . s:key1 . s:key2
  endfor | endfor
  for s:key1 in add(range(1, 9), '') | for s:key2 in ['', 'b', 'c']
    if !empty(s:key1 . s:key2) | silent! exe 'unmap g.' . s:key1 . s:key2 | endif
  endfor | endfor
  nnoremap z.. <Cmd>call comment#toggle_comment()<CR>
  nnoremap z>> <Cmd>call comment#toggle_comment(1)<CR>
  nnoremap z<< <Cmd>call comment#toggle_comment(0)<CR>
  let g:tcomment_opleader1 = 'z.'  " default is 'gc'
  let g:tcomment_mapleader1 = ''  " disables <C-_> insert mode maps
  let g:tcomment_mapleader2 = ''  " disables <Leader><Space> normal mode maps
  let g:tcomment_textobject_inlinecomment = ''  " default of 'ic' disables text object
  let g:tcomment_mapleader_uncomment_anyway = 'z<'
  let g:tcomment_mapleader_comment_anyway = 'z>'
endif

" Tag integration settings
" Warning: Critical to mamba install 'universal-ctags' instead of outdated 'ctags'
" or else will get warnings for non-existing kinds.
" Note: Use .ctags config to ignore kinds or include below to filter bracket jumps. See
" :ShowTable for translations. Try to use 'minor' for all single-line constructs.
" Note: Custom plugin is similar to :Btags, but does not create or manage tag files,
" instead creating tags whenever buffer is loaded and tracking tags continuously. Also
" note / and ? update jumplist but cannot override without keeping interactivity.
" nnoremap <Leader>t <Cmd>CurrentTag<CR>
" nnoremap <Leader>T <Cmd>call switch#tags()<CR>
if s:plug_active('vim-tags')
  command! -nargs=? TagToggle call switch#tags(<args>)
  command! -bang -nargs=* ShowTable
    \ echo call('tags#table_kinds', <bang>0 ? ['all'] : [<f-args>])
    \ | echo call('tags#table_tags', <bang>0 ? ['all'] : [<f-args>])
  nnoremap gy <Cmd>BTags<CR>
  nnoremap gY <Cmd>Tags<CR>
  nnoremap <Leader>t <Cmd>ShowTable<CR>
  nnoremap <Leader>T <Cmd>ShowTable!<CR>
  let s:major = {'fortran': 'fsmp', 'python': 'fmc', 'vim': 'af', 'tex': 'csub'}
  let s:minor = {'fortran': 'ekltvEL', 'python': 'xviI', 'vim': 'vnC', 'tex': 'gioetBCN'}
  let g:tags_cursor_map = '<CR>'  " default is <Leader><CR>
  let g:tags_bselect_map = 'gt'  " default is <Leader><Leader>
  let g:tags_select_map = 'gT'  " default is <Leader><Tab>
  let g:tags_keep_jumps = 1  " default is 0
  let g:tags_major_kinds = s:major
  let g:tags_minor_kinds = s:minor
  let g:tags_prev_local_map = '[w'  " keyword jumping
  let g:tags_next_local_map = ']w'  " keyword jumping
  let g:tags_prev_global_map = '[W'
  let g:tags_next_global_map = ']W'
  silent! exe 'runtime plugin/tags.vim'
endif

" Gutentag tag generation
" Note: Use gutentags for fancy navigation in buffer / across project, alongside
" custom vim-tags utility for simple navigation in buffer.
" Todo: Update :Open and :Find so they also respect ignore files, consistent with
" bashrc grep/find utilities and with below grep/ctags utilities. For debugging
" parsing of ignore files use below :ShowIgnores command.
if s:plug_active('vim-gutentags')
  augroup tags_setup
    au!
    au User GutentagsUpdated call tag#update_paths()
    au BufCreate,BufReadPost * call tag#update_paths(expand('<afile>'))
  augroup END
  command! -complete=dir -nargs=* UpdatePaths call tag#update_paths(<f-args>)
  command! -nargs=? ShowIgnores echom 'Ignored patterns: ' . join(tag#parse_ignores(0, <q-args>), ' ')
  nnoremap zt <Cmd>UpdateTags \| GutentagsUpdate<CR><Cmd>echom 'Updated buffer tags'<CR>
  nnoremap zT <Cmd>UpdateTags! \| GutentagsUpdate!<CR><Cmd>echom 'Updated project tags'<CR>
  " let g:gutentags_cache_dir = '~/.vim_tags_cache'  " alternative cache specification
  " let g:gutentags_ctags_tagfile = 'tags'  " used with cache dir
  " let g:gutentags_file_list_command = 'git ls-files'  " alternative to exclude ignores
  let g:gutentags_background_update = 1  " disable for debugging, printing updates
  let g:gutentags_ctags_auto_set_tags = 0  " tag#update_paths() handles this instead
  let g:gutentags_ctags_executable = 'ctags'  " note this respects .ctags config
  let g:gutentags_ctags_exclude_wildignore = 1  " exclude &wildignore too
  let g:gutentags_ctags_exclude = tag#parse_ignores(0)  " exclude all by default
  let g:gutentags_ctags_tagfile = '.vimtags'
  let g:gutentags_define_advanced_commands = 1  " debugging command
  let g:gutentags_generate_on_new = 1  " do not update tags when opening project file
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
  " Fast fold settings
  augroup fastfold_setup
    au!
    au TextChanged,TextChangedI * let b:fastfold_queued = 1
  augroup END
  let g:fastfold_savehook = 0  " use custom instead
  let g:fastfold_fold_command_suffixes =  []  " use custom instead
  let g:fastfold_fold_movement_commands = []  " use custom instead
  " Native folding settings
  let g:baan_fold = 1
  let g:clojure_fold = 1
  let g:fortran_fold = 1
  let g:javaScript_fold = 1
  let g:html_syntax_folding = 1
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
" Note: LspDefinition accepts <mods> and stays in current buffer for local definitions,
" so below behavior is close to 'Drop': https://github.com/prabirshrestha/vim-lsp/pull/776
" Note: Highlighting under keywords required for reference jumping with [d and ]d but
" monitor for updates: https://github.com/prabirshrestha/vim-lsp/issues/655
" Note: Require kludge to get markdown syntax to work for some popups e.g. python dict()
" signature windows. See: https://github.com/prabirshrestha/vim-lsp/issues/1289
" Warning: Servers are 'pylsp', 'bash-language-server', 'vim-language-server'. Tried
" 'jedi-language-server' but had issues on linux, and tried 'texlab' but was slow. Note
" some cannot be installed with mamba and need vim-lsp-swettings :LspInstallServer.
" Warning: foldexpr=lsp#ui#vim#folding#foldexpr() foldtext=lsp#ui#vim#folding#foldtext()
" cause insert mode slowdowns even with g:lsp_fold_enabled = 0. Now use fast fold with
" native syntax foldmethod. Also tried tagfunc=lsp#tagfunc but now use LspDefinition
if s:plug_active('vim-lsp')
  " Autocommands and mappings
  " Note: The autocmd gives signature popups the same borders as hover popups, or else
  " they have double border. See: https://github.com/prabirshrestha/vim-lsp/issues/594
  augroup lsp_setup
    au!
    au User lsp_float_opened call window#setup_preview()
    au FileType markdown.lsp-hover let b:lsp_do_conceal = 1 | setlocal conceallevel=2
  augroup END
  command! -nargs=? LspToggle call switch#lsp(<args>)
  command! -nargs=? ClearDoc call stack#clear_stack('doc')
  command! -nargs=? ShowDoc call stack#show_stack('doc')
  command! -nargs=? PopDoc call stack#pop_stack('doc', <f-args>)
  command! -nargs=? Doc call stack#push_stack('doc', 'python#doc_page', <f-args>)
  noremap [r <Cmd>LspPreviousReference<CR>
  noremap ]r <Cmd>LspNextReference<CR>
  noremap gd <Cmd>call lsp#ui#vim#definition(0, "call feedkeys('zv', 'n') \| tab")<CR>
  noremap gD gdzv<Cmd>noh<CR>
  noremap zd <Cmd>LspReferences<CR>
  noremap zD <Cmd>LspRename<CR>
  noremap <Leader>d <Cmd>LspPeekDefinition<CR>
  noremap <Leader>f <Cmd>call stack#push_stack('doc', 'python#doc_page')<CR>
  noremap <Leader>F <Cmd>call python#doc_search()<cr>
  noremap <Leader>a <Cmd>LspHover --ui=float<CR>
  noremap <Leader>A <Cmd>LspSignatureHelp<CR>
  noremap <Leader>& <Cmd>call switch#lsp()<CR>
  noremap <Leader>% <Cmd>CheckHealth<CR>
  noremap <Leader>^ <Cmd>tabnew \| LspManage<CR><Cmd>file lspservers \| call window#setup_panel(0)<CR>
  " Lsp and server settings
  " See: https://github.com/python-lsp/python-lsp-server/issues/477
  " Note: See 'jupyterlab-lsp/plugin.jupyterlab-settings' for examples. Results are
  " shown in :CheckHelath. Try below when debugging (should disable :LspHover)
  " let s:pylsp_settings = {'plugins': {'jedi_hover': {'enabled': v:false}}}
  let s:pylsp_settings = {
    \ 'configurationSources': ['flake8'],
    \ 'plugins': {'jedi': {'auto_import_modules': ['numpy', 'pandas', 'matplotlib', 'proplot']}},
  \ }
  let s:texlab_settings = {}
  let s:julia_settings = {}
  let s:bash_settings = {}
  let g:lsp_settings = {
    \ 'pylsp': {'workspace_config': {'pylsp': s:pylsp_settings}},
    \ 'texlab': {'workspace_config': {'texlab': s:texlab_settings}},
    \ 'julia-language-server': {'workspace_config': {'julia-language-server': s:julia_settings}},
    \ 'bash-language-server': {'workspace_config': {'bash-language-server': s:bash_settings}},
  \ }
  let g:lsp_settings_servers_dir = '~/.vim_lsp_settings/servers'
  let g:lsp_settings_global_settings_dir = '~/.vim_lsp_settings'  " move here next?
  let g:lsp_ale_auto_enable_linter = v:false  " default is true
  let g:lsp_diagnostics_enabled = 0  " use ale instead
  let g:lsp_diagnostics_highlights_insert_mode_enabled = 0  " annoying
  let g:lsp_document_code_action_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_highlight_delay = 3000  " increased delay time
  let g:lsp_document_highlight_enabled = 0  " monitor, still really sucks
  let g:lsp_fold_enabled = 0  " not yet tested, requires 'foldlevel', 'foldlevelstart'
  let g:lsp_hover_ui = 'preview'  " either 'float' or 'preview'
  let g:lsp_hover_conceal = 1  " enable markdown conceale
  let g:lsp_inlay_hints_enabled = 0  " use inline hints
  let g:lsp_max_buffer_size = 2000000  " decrease from 5000000
  let g:lsp_preview_float = 1  " floating window
  let g:lsp_preview_fixup_conceal = -1  " fix window size in terminal vim
  let g:lsp_signature_help_enabled = 1  " sigature help
  let g:lsp_signature_help_delay = 100  " milliseconds
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
  let g:popup_preview_config = {
    \ 'border': v:true,
    \ 'maxWidth': g:linelength,
    \ 'maxHeight': 2 * g:linelength
  \ }
  let g:denops_disable_version_check = 0  " skip check for recent versions
  let g:denops#deno = 'deno'  " deno executable should be on $PATH
  let g:denops#server#deno_args = [
    \ '--allow-env', '--allow-net', '--allow-read', '--allow-write', '--allow-run',
    \ '--v8-flags=--max-heap-size=100,--max-old-space-size=100',
  \ ]
  let g:ddc_sources = ['around', 'buffer', 'ctags', 'file', 'vim-lsp']
  let g:ddc_options = {
    \ 'sourceParams': {'around': {'maxSize': 500}},
    \ 'filterParams': {'matcher_fuzzy': {'splitMode': 'word'}},
    \ 'sourceOptions': {
    \   '_': {
    \     'matchers': ['matcher_fuzzy'],
    \     'sorters': ['sorter_fuzzy'],
    \     'converters': ['converter_fuzzy'],
    \     'minAutoCompleteLength': 1,
    \   },
    \   'around': {
    \     'mark': 'A',
    \     'maxItems': 5,
    \   },
    \   'buffer': {
    \     'mark': 'B',
    \     'maxItems': 5,
    \   },
    \   'ctags': {
    \     'mark': 'T',
    \     'isVolatile': v:true,
    \     'maxItems': 5,
    \   },
    \   'file': {
    \     'mark': 'F',
    \     'isVolatile': v:true,
    \     'forceCompletionPattern': '\S/\S*',
    \     'maxItems': 5,
    \   },
    \   'vim-lsp': {
    \     'mark': 'L',
    \     'maxItems': 15,
    \     'isVolatile': v:true,
    \     'forceCompletionPattern': '\\.|:|->',
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
" map ]x <Plug>(ale_next_wrap)  " use universal circular scrolling
" map [x <Plug>(ale_previous_wrap)  " use universal circular scrolling
" 'python': ['python', 'flake8', 'mypy'],  " need to improve config
if s:plug_active('ale')
  augroup ale_setup
    au!
    au BufRead ipython_*config.py,jupyter_*config.py let b:ale_enabled = 0
  augroup END
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

" Formatting plugins related to ale
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
    \ 'line_length': g:linelength,
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
" Todo: Figure out how to get highlighting closer to marks without clearing background.
" May need to define custom :syn matches that are not regions. Ask stack exchange.
" Note: Need to remove syntax regions here because they are added on per-filetype
" basis and they wipe out syntax highlighting between the conflict markers.
" See: https://vi.stackexchange.com/q/31623/8084
" See: https://github.com/rhysd/conflict-marker.vim
if s:plug_active('conflict-marker.vim')
  augroup conflict_marker_setup
    au!
    au BufWinEnter * if conflict_marker#detect#markers()
      \ | syntax clear ConflictMarkerOurs ConflictMarkerTheirs | endif
  augroup END
  command! -count=1 Cprev call iter#next_conflict(<count>, 1)
  command! -count=1 Cnext call iter#next_conflict(<count>, 0)
  call utils#repeat_map('', '[F', 'ConflictBackward', '<Cmd>exe v:count1 . "Cprev" \| ConflictMarkerThemselves<CR>')
  call utils#repeat_map('', ']F', 'ConflictForward', '<Cmd>exe v:count1 . "Cnext" \| ConflictMarkerThemselves<CR>')
  noremap [f <Cmd>exe v:count1 . 'Cprev'<CR>
  noremap ]f <Cmd>exe v:count1 . 'Cnext'<CR>
  noremap gf <Cmd>ConflictMarkerOurselves<CR>
  noremap gF <Cmd>ConflictMarkerThemselves<CR>
  noremap zf <Cmd>ConflictMarkerBoth<CR>
  noremap zF <Cmd>ConflictMarkerNone<CR>
  let g:conflict_marker_enable_detect = 1
  let g:conflict_marker_enable_highlight = 1
  let g:conflict_marker_enable_matchit = 1
  let g:conflict_marker_highlight_group = 'ConflictMarker'
  let g:conflict_marker_begin = '^<<<<<<< .*$'
  let g:conflict_marker_end = '^>>>>>>> .*$'
  let g:conflict_marker_separator = '^=======$'
  let g:conflict_marker_common_ancestors = '^||||||| .*$'
  highlight ConflictMarker cterm=inverse gui=inverse
endif

" Fugitive settings
" Note: Fugitive overwrites commands for some reason so re-declare them
" whenever entering buffers and make them buffer-local (see git.vim).
" Note: All of the file-opening commands throughout fugitive funnel them through
" commands like Gedit, Gtabedit, etc. So can prevent duplicate tabs by simply
" overwriting this with custom tab-jumping :Drop command (see also git.vim).
if s:plug_active('vim-fugitive')
  augroup fugitive_setup
    au!
    au BufEnter * call git#command_setup()
  augroup END
  noremap zl <Cmd>BCommits<CR>
  noremap zL <Cmd>Commits<CR>
  noremap <expr> gl git#run_map_expr(2, 0, '', 'blame ')
  noremap gll <Cmd>call git#run_map(2, 0, '', 'blame ')<CR>
  noremap gL <Cmd>call git#run_map(0, 0, '', 'blame')<CR>
  noremap <Leader>' <Cmd>call git#run_map(0, 0, '', '')<CR>
  noremap <Leader>" <Cmd>call git#run_map(0, 0, '', 'status')<CR>
  noremap <Leader>y <Cmd>call git#run_map(0, 0, '', 'tree')<CR>
  noremap <Leader>Y <Cmd>call git#run_map(0, 0, '', 'log')<CR>
  noremap <Leader>u <Cmd>call git#run_map(0, 0, '', 'push origin')<CR>
  noremap <Leader>U <Cmd>call git#run_map(0, 0, '', 'pull origin')<CR>
  noremap <Leader>i <Cmd>call git#safe_commit(0, 'oops')<CR>
  noremap <Leader>I <Cmd>call git#safe_commit(1, 'oops')<CR>
  noremap <Leader>o <Cmd>call git#safe_commit(0, 'commit')<CR>
  noremap <Leader>O <Cmd>call git#safe_commit(1, 'commit')<CR>
  noremap <Leader>p <Cmd>call git#safe_commit(0, 'stash push --include-untracked')<CR>
  noremap <Leader>P <Cmd>call git#safe_commit(1, 'stash push --include-untracked')<CR>
  noremap <Leader>h <Cmd>call git#run_map(0, 0, '', 'diff -- :/')<CR>
  noremap <Leader>H <Cmd>call git#run_map(0, 0, '', 'stage -- :/')<CR>
  noremap <Leader>j <Cmd>call git#run_map(0, 0, '', 'diff -- %')<CR>
  noremap <Leader>J <Cmd>call git#run_map(0, 0, '', 'stage -- %')<CR>
  noremap <Leader>k <Cmd>call git#run_map(0, 0, '', 'diff --staged -- %')<CR>
  noremap <Leader>K <Cmd>call git#run_map(0, 0, '', 'reset --quiet -- %')<CR>
  noremap <Leader>l <Cmd>call git#run_map(0, 0, '', 'diff --staged -- :/')<CR>
  noremap <Leader>L <Cmd>call git#run_map(0, 0, '', 'reset --quiet -- :/')<CR>
  noremap <Leader>b <Cmd>call git#run_map(0, 0, '', 'branches')<CR>
  noremap <Leader>B <Cmd>call git#run_map(0, 0, '', 'switch -')<CR>
  let g:fugitive_legacy_commands = 1  " include deprecated :Git status to go with :Git
  let g:fugitive_dynamic_colors = 1  " fugitive has no HighlightRecent option
endif

" Git gutter settings
" Note: Use custom command for toggling on/off. Older vim versions always show
" signcolumn if signs present, so GitGutterDisable will remove signcolumn.
" Note: Previously used text change autocomamnds to manually-refresh gitgutter since
" plugin only defines CursorHold but under-the-hood the invoked function actually
" *does* only fire when text is different. So leave default configuration alone.
" Note: Staging maps below were inspired by tcomment maps 'gc', 'gcc', 'etc.', and
" navigation maps ]g, ]G (navigate to hunks, or navigate and stage hunks) were inspired
" by spell maps ]s, ]S (navigate to spell error, or navigate and fix error).
if s:plug_active('vim-gitgutter')
  command! -nargs=? GitGutterToggle call switch#gitgutter(<args>)
  let g:gitgutter_async = 1  " ensure enabled
  let g:gitgutter_map_keys = 0  " disable all maps yo
  let g:gitgutter_max_signs = -1  " maximum number of signs
  let g:gitgutter_preview_win_floating = 1  " enable preview window
  let g:gitgutter_use_location_list = 0  " use for errors instead
  call utils#repeat_map('', '[G', 'HunkBackward', '<Cmd>call git#hunk_jump(-v:count1, 1)<CR>')
  call utils#repeat_map('', ']G', 'HunkForward', '<Cmd>call git#hunk_jump(v:count1, 1)<CR>')
  noremap [g <Cmd>call git#hunk_jump(-v:count1, 0)<CR>
  noremap ]g <Cmd>call git#hunk_jump(v:count1, 0)<CR>
  noremap <Leader>g <Cmd>call git#hunk_show()<CR>
  noremap <Leader>G <Cmd>call switch#gitgutter()<CR>
  noremap <expr> gh git#hunk_action_expr(1)
  noremap <expr> gH git#hunk_action_expr(0)
  nnoremap <nowait> ghh <Cmd>call git#hunk_action(1)<CR>
  nnoremap <nowait> gHH <Cmd>call git#hunk_action(0)<CR>
  noremap zh <Cmd>GitGutter \| echom 'Updated buffer hunks'<CR>
  noremap zH <Cmd>GitGutterAll \| echom 'Updated global hunks'<CR>
endif

" Easy-align with delimiters for case/esac block parentheses and seimcolons, chained
" && and || symbols, or trailing comments. See file empty.txt for easy-align tests.
" Note: Use <Left> to stick delimiter to left instead of right and use * to align
" by all delimiters instead of the default of 1 delimiter.
" Note: Use :EasyAlign<Delim>is, id, or in for shallowest, deepest, or no indentation
" and use <Tab> in interactive mode to cycle through these.
if s:plug_active('vim-easy-align')
  augroup easy_align_setup
    au!
    au BufEnter * let g:easy_align_delimiters['c']['pattern'] = '\s' . comment#get_regex()
  augroup END
  map z, <Plug>(EasyAlign)
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
" Note: Recent codi versions use lua-vim which is not provided by conda-forge version.
" However seems to run fine even without lua lines. So ignore error with silent!
if s:plug_active('codi.vim')
  augroup codi_setup
    au!
    au User CodiEnterPre call calc#setup_codi(1)
    au User CodiLeavePost call calc#setup_codi(0)
  augroup END
  command! -nargs=* CodiNew call calc#start_codi(<f-args>)
  noremap <Leader>+ <Cmd>CodiNew<CR>
  noremap <Leader>= <Cmd>silent! Codi!!<CR>
  let g:codi#autocmd = 'None'
  let g:codi#rightalign = 0
  let g:codi#rightsplit = 0
  let g:codi#width = 30  " overridden by user
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

" Undo tree mapping and settings
" Note: Undotree normally triggers on BufEnter but may contribute to slowdowns. Use
" below to override built-in augroup before enabling buffer.
" Todo: Currently can only clear history with 'C' in active pane not externally. Need
" to submit PR for better command. See: https://github.com/mbbill/undotree/issues/158
if s:plug_active('undotree')
  function! Undotree_Augroup() abort  " autoload/undotree.vim s:undotree.Toggle()
    if undotree#UndotreeIsVisible()
      augroup Undotree
        au! | au InsertLeave,TextChanged * call undotree#UndotreeUpdate()
      augroup END
    endif
  endfunction
  function! Undotree_CustomMap() abort  " autoload/undotree.vim s:undotree.BindKey()
    exe 'vertical resize ' . window#default_width(1)
    nmap <buffer> U <Plug>UndotreeRedo
    noremap <buffer> <nowait> u <C-u>
    noremap <buffer> <nowait> d <C-d>
  endfunc
  noremap g\ <Cmd>UndotreeToggle<CR><Cmd>call Undotree_Augroup()<CR>
  let g:undotree_DiffAutoOpen = 0
  let g:undotree_RelativeTimestamp = 0
  let g:undotree_SetFocusWhenToggle = 1
  let g:undotree_ShortIndicators = 1
  let g:undotree_SplitWidth = 30  " overridden above
  let g:undotree_WindowLayout = 1  " see :help undotree_WindowLayout
endif

" Vim test settings
" Run tests near cursor or throughout file
if s:plug_active('vim-test')
  let test#strategy = 'iterm'
  let g:test#python#pytest#options = '--mpl --verbose'
  noremap <Leader>\ <Cmd>call utils#catch_errors('TestVisit')<CR>
  noremap <Leader>, <Cmd>call utils#catch_errors('TestLast')<CR>
  noremap <Leader>. <Cmd>call utils#catch_errors('TestNearest')<CR>
  noremap <Leader>< <Cmd>call utils#catch_errors('TestLast --mpl-generate')<CR>
  noremap <Leader>> <Cmd>call utils#catch_errors('TestNearest --mpl-generate')<CR>
  noremap <Leader>[ <Cmd>call utils#catch_errors('TestFile')<CR>
  noremap <Leader>] <Cmd>call utils#catch_errors('TestSuite')<CR>
  noremap <Leader>{ <Cmd>call utils#catch_errors('TestFile --mpl-generate')<CR>
  noremap <Leader>} <Cmd>call utils#catch_errors('TestSuite --mpl-generate')<CR>
endif

" The howmuch.vim plugin. Mnemonic for equation solving is just that parentheses
" show up in equations. Mnemonic for sums is the straight line at bottom of table.
" Note: Usage is HowMuch#HowMuch(isAppend, withEq, sum, engineType) where isAppend
" says whether to replace or append, withEq says whether to include equals sign, sum
" says whether to sum the numbers, and engine is one of 'py', 'bc', 'vim', 'auto'.
if s:plug_active('HowMuch')
  nnoremap g++ :call HowMuch#HowMuch(0, 0, 1, 'py')<CR>
  nnoremap z++ :call HowMuch#HowMuch(1, 1, 1, 'py')<CR>
  noremap <expr> g+ edit#how_much(0, 0, 1, 'py')
  noremap <expr> z+ edit#how_much(1, 1, 1, 'py')
endif

" Speed dating for incrementing or generating lists of numbers and dates
" Note: This overwrites default increment/decrement plugins declared above. Works
" by incrementing selected item(s), and if selection includes empty lines then extends
" them using the step size from preceding lines or using a default step size.
if s:plug_active('vim-speeddating')
  map + <Plug>SpeedDatingUp
  map - <Plug>SpeedDatingDown
  noremap <Plug>SpeedDatingFallbackUp <C-a>
  noremap <Plug>SpeedDatingFallbackDown <C-x>
endif

" Session saving and updating (the $ matches marker used in statusline)
" Obsession .vimsession activates vim-obsession BufEnter and VimLeavePre
" autocommands and saved session files call let v:this_session=expand("<sfile>:p")
" (so that v:this_session is always set when initializing with vim -S .vimsession)
if s:plug_active('vim-obsession')  " must manually preserve cursor position
  augroup session_setup
    au!
    au VimEnter * if !empty(v:this_session) | exe 'Obsession ' . v:this_session | endif
    au BufReadPost * if line('''"') > 0 && line('''"') <= line('$') | exe 'keepjumps normal! g`"' | endif
  augroup END
  command! -nargs=* -complete=customlist,vim#session_list Session call vim#init_session(<q-args>)
  noremap <Leader>$ <Cmd>Session<CR>
endif


"-----------------------------------------------------------------------------"
" Final tasks
"-----------------------------------------------------------------------------"
" Show syntax under cursor and syntax types
" Note: The first map prints information, the second two maps open windows, the
" other maps open tabs.
command! -nargs=? ShowStack call syntax#show_stack(<f-args>)
command! -nargs=0 ShowPlugin call syntax#show_runtime('ftplugin')
command! -nargs=0 ShowSyntax call syntax#show_runtime('syntax')
command! -nargs=0 ShowGroups exe 'help highlight-groups' | exe 'normal! zt'
command! -nargs=0 ShowBases exe 'help group-name' | exe 'normal! zt'
command! -nargs=0 ShowColors call syntax#show_colors()
noremap <Leader>` <Cmd>ShowStack<CR>
noremap <Leader>1 <Cmd>ShowGroups<CR>
noremap <Leader>2 <Cmd>ShowBases<CR>
noremap <Leader>3 <Cmd>ShowColors<CR>
noremap <Leader>4 <Cmd>ShowSyntax<CR>
noremap <Leader>5 <Cmd>ShowPlugin<CR>

" Repair syntax highlighting
" Note: :Colorize is from hex-colorizer plugin. Expensive so disable at start
" Note: Here :set background triggers colorscheme autocmd so must avoid infinite loop
augroup color_setup
  au!
  au VimEnter * exe 'runtime after/common.vim' | call mark#init_marks()
augroup END
command! -bang -range -count=0 Syntax
  \ call syntax#update_lines(<range> == 2 ? abs(<line2> - <line1>) : <count>, <bang>0)
call utils#repeat_map('', 'zy', 'SyncSmart', ':Syntax<CR>')
call utils#repeat_map('', 'zY', 'SyncStart', '<Cmd>Syntax!<CR>')
noremap <Leader>8 <Cmd>Colorize<CR>

" Scroll color schemes and toggle colorize
" Note: Here :Colorize is from colorizer.vim and :Colors from fzf.vim. Note coloring
" hex strings can cause massive slowdowns so disable by default.
command! -nargs=? -complete=color Scheme call syntax#next_scheme(<f-args>)
command! -count=1 Sprev call syntax#next_scheme(-<count>)
command! -count=1 Snext call syntax#next_scheme(<count>)
call utils#repeat_map('n', 'g(', 'Sprev', ':<C-u>Sprev<CR>')
call utils#repeat_map('n', 'g)', 'Snext', ':<C-u>Snext<CR>')
noremap <Leader>9 <Cmd>Colors<CR>
noremap <Leader>0 <Cmd>exe 'Scheme ' . g:colors_default<CR>

" Apply color scheme from flazz/vim-colorschemes
" Note: This has to come after color schemes are loaded.
" https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/
let g:colors_best = [
  \ 'adventurous',
  \ 'badwolf',
  \ 'fahrenheit',
  \ 'falcoln',
  \ 'gruvbox',
  \ 'manuscript',
  \ 'molokai',
  \ 'oceanicnext',
  \ 'sierra',
  \ 'sourcerer',
  \ 'slatedark',
  \ 'spacegray',
  \ 'tender',
  \ 'ubaryd',
  \ 'vimbrant',
  \ 'manuscript',
\ ]
if has('gui_running') && empty(get(g:, 'colors_name', ''))
  noautocmd colorscheme manuscript
endif
if !exists('g:colors_default')
  let g:colors_default = get(g:, 'colors_name', 'default')
endif

" General highlight defaults
" Use main colors instead of light and dark colors instead of main
" Note: The bulk operations are in autoload/syntax.vim
augroup colorscheme_setup
  au!
  exe 'au ColorScheme ' . g:colors_default . ' so ~/.vimrc'
augroup END
if !has('gui_running') && get(g:, 'colors_name', 'default') ==? 'default'
  noautocmd set background=dark  " standardize colors
  highlight Todo ctermbg=Red ctermfg=NONE
  highlight MatchParen ctermbg=Blue ctermfg=NONE
  highlight Sneak ctermbg=DarkMagenta ctermfg=NONE
  highlight Search ctermbg=Magenta ctermfg=NONE
  highlight PmenuSel ctermbg=Magenta ctermfg=NONE cterm=NONE
  highlight PmenuSbar ctermbg=DarkGray ctermfg=NONE cterm=NONE
  highlight Type ctermbg=NONE ctermfg=DarkGreen
  highlight Constant ctermbg=NONE ctermfg=Red
  highlight Special ctermbg=NONE ctermfg=DarkRed
  highlight PreProc ctermbg=NONE ctermfg=DarkCyan
  highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold
endif

" Clear jumps for new tabs and to ignore stuff from vimrc and plugin files. Note
" that feedkeys required or else this fails for e.g.
" See: https://stackoverflow.com/a/2419692/4970632
" See: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup clear_jumps
  au!
  au VimEnter,BufWinEnter * if get(w:, 'clear_jumps', 1) | silent clearjumps | let w:clear_jumps = 0 | endif
  au VimEnter,BufWinEnter * exe 'normal! zvzz'
augroup END
exe 'runtime autoload/repeat.vim'
call syntax#update_highlights()
nohlsearch  " turn off highlighting at startup
redraw!  " prevent statusline error
