"-----------------------------------------------------------------------------"
" A giant vim configuration that does all sorts of magical things. {{{1
"-----------------------------------------------------------------------------"
" Initial stuff {{{2
" WARNING: Vim may suppress messages even without :silent invocation (e.g. BufEnter
" fold updates, delayed :redraw). Always use :unsilent echom when debugging
" NOTE: The refresh variable used in .vim/autoload/vim.vim to autoload recently
" updated script and line length variable used in linting tools below.
" NOTE: Use karabiner to convert ctrl-j/k/h/l into arrow keys. So anything
" mapped to these control combinations below must also be assigned to arrow keys.
" NOTE: Use iterm to ensure alt-arrow presses always report as ^[[1;3A/B/C/D instead
" of ^[[1;9A/B/C/D (or disable profile..keys 'apps can change how keys are reported').
" NOTE: Use iterm to convert impossible ctrl+key combos to function keys using hex
" codes obtained from below links (also :help t_k1-9 and :help t_F1+9)
" NOTE: Here cursor shape requires either ptmux passthrough codes (see 'vitality.vim')
" or below terminal overrides. Previously used ':au FocusLost * stopinsert' workaround
" F1/F2: 0x1b 0x4f 0x50/0x51  (Ctrl-, Ctrl-.) (5-digit codes failed)
" F3/F4: 0x1b 0x4f 0x52/0x53 (Ctrl-[ Ctrl-])
" F5/F6: 0x1b 0x5b 0x31 0x35/0x37 0x7e (Ctrl-; Ctrl-') (3-digit codes failed)
" F7/F8: 0x1b 0x5b 0x31 0x38/0x39 0x7e (Ctrl-i Ctrl-m)
" F9/F10: 0x1b 0x5b 0x32 0x30/0x31 0x7e (currently unused) (forum codes required)
" F11/F12: 0x1b 0x5b 0x32 0x33/0x34 0x7e (currently unused)
" See: https://github.com/c-bata/go-prompt/blob/82a9122/input.go#L94-L125
" See: https://eevblog.com/forum/microcontrollers/mystery-of-vt100-keyboard-codes/
" See: https://stackoverflow.com/a/44473667/4970632 (terminal cursor overrides)

" vint: -ProhibitSetNoCompatible
set nocompatible
set encoding=utf-8
let g:linelength = 88
let g:mapleader = "\<Space>"
let g:refresh = get(g:, 'refresh', localtime())
let &t_vb = ''  " visual bell (disable completely)
let &t_ti = "\e7\e[r\e[?47h"  " termcap mode (keep scrollback)
let &t_te = "\e[?47l\e8"  " termcap end (keep scrollback)
let &t_SI = "\e[6 q"  " bar cursor (insert mode)
let &t_SR = "\e[4 q"  " underline cursor (replace mode)
let &t_EI = "\e[2 q"  " block cursor (normal mode)
let &t_ZH = "\e[3m"  " italics mode
let &t_ZR = "\e[23m"  " italics end
scriptencoding utf-8

" Global settings {{{2
" NOTE: Here plugins integrate with tags, location/quickfix lists, and jump/change
" lists while fzf.vim fully replaces native :grep and :find commands.
" NOTE: See .vim/after/common.vim and .vim/after/filetype.vim for overrides of
" buffer-local syntax and 'conceal-', 'format-', 'linebreak', and 'joinspaces'.
" WARNING: Setting default 'foldmethod' and 'foldexpr' can cause buffer-local
" expression folding e.g. simpylfold to disappear and not retrigger, while using
" setglobal didn't work for filetypes with folding not otherwise auto-triggered (vim)
let s:path = $HOME . '/mambaforge/bin'  " gui vim support
let $PATH = ($PATH !~# s:path ? s:path . ':' : '') . $PATH
set autoindent  " indents new lines
set backspace=indent,eol,start  " backspace by indent
set breakindent  " visually indent wrapped lines
set buflisted  " list all buffers by default
set cmdheight=1  " increase to avoid pressing enter to continue
set cmdwinheight=13  " i.e. show 12 previous commands (but changed by maps below)
set colorcolumn=89,121  " color column after recommended length of 88
set complete=.,w,b,u,t,i,k  " prevent slowdowns with ddc
set completeopt-=preview  " use custom denops-popup-preview plugin
set concealcursor=nc  " conceal in normal mode and during incsearch (see also common.vim)
set conceallevel=2  " hide conceal text completely (see also common.vim)
set formatoptions=rojclqn  " comment and wrapping (see fo-table and common.vim)
set linebreak  " see also common.vim
set confirm  " require confirmation if you try to quit
set cpoptions=aABceFs  " vim compatibility options
set cursorline  " highlight cursor line
set diffopt=filler,context:2,foldcolumn:0,vertical  " vim-difference display options
set display=lastline  " displays as much of wrapped lastline as possible;
set esckeys  " allow keycodes passed with escape
set fillchars=eob:~,vert:\|,lastline:@,fold:\ ,foldopen:\>,foldclose:<
set foldclose=  " use foldclose=all to auto-close folds when leaving
set foldcolumn=0  " do not show folds, since fastfold dynamically updates
set foldlevelstart=0  " hide folds when opening (then 'foldlevel' sets current status)
set foldnestmax=8  " allow only some folds
set foldopen=insert,jump,quickfix,tag,undo  " exclude: block, hor, mark, percent, search
set foldtext=fold#fold_text()  " default function for generating text shown on fold line
set guicursor+=a:blinkon0  " skip blinking cursor
set guifont=Menlo:h12  " match iterm settings
set guioptions=M  " skip $VIMRUNTIME/menu.vim https://vi.stackexchange.com/q/10348/8084
set history=500  " remember 500 previous searches / commands and save in .viminfo
set hlsearch  " highlight as you search forward
set ignorecase  " ignore case in search patterns
set incsearch  " show matches incrementally when using e.g. :sub
set lazyredraw  " skip redraws during macro and function calls
set listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·  " other options: ▸, ·, ¬, ↳, ⬎, ↘, ➝, ↦,⬊
set matchpairs=(:),{:},[:]  " exclude <> by default for use in comparison operators
set maxmempattern=50000  " from 1000 to 10000
set mouse=a  " mouse clicks and scroll allowed in insert mode via escape sequences
set modeline  " check for local settings e.g. fdm=marker
set modelines=5  " check last 5 lines of files (default)
set noautochdir  " disable auto changing
set noautowrite  " disable auto write for file jumping commands (ask user instead)
set noautowriteall  " disable autowrite for :exit, :quit, etc. (ask user instead)
set nobackup  " no backups when overwriting files, use tabline/statusline features
set noerrorbells  " disable error bells (see also visualbell and t_vb)
set nofileignorecase  " disable ignoring case (needed for color scheme iteration)
set nohidden  " unload buffers when not open in window
set noinfercase  " do not replace insert-completion with case inferred from typed text
set nojoinspaces  " do not add two spaces to join (see also common.vim)
set noshowmode  " hide e.g. 'insert' from bottom line (redundant with statusline)
set nostartofline  " do not move to column 1 when scrolling or changing buffers
set noswapfile " no more swap files, instead use session
set notimeout  " do not time out on multi-key mappings
set nowrap  " global wrap setting possibly overwritten by wraptoggle
set nrformats=alpha  " never interpret numbers as 'octal'
set path=.,,**  " cfile, cdir, glob (:find command, file_in_path command-complete)
set previewheight=20  " default preview window height
set pumheight=10  " maximum popup menu height
set pumwidth=10  " minimum popup menu width
set redrawtime=5000  " sometimes takes a long time, let it happen
set restorescreen  " restore screen after exiting vim
set selectmode=  " disable 'select mode' slm, allow only visual mode for that stuff
set sessionoptions=sesdir,tabpages,terminal,winsize  " restrict session options for speed
set shell=/usr/bin/env\ bash  " first bash found on $PATH
set shiftround  " round to multiple of shift width
set showcmd  " show operator pending command
set shortmess=atqcT  " snappy messages, 'a' does a bunch of common stuff
set showtabline=1  " default 2 spaces
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
set timeoutlen=1000  " mapping timeout length (ignored due to set notimeout)
set ttimeout  " time out on multi-byte key codes (needed for insert escape)
set ttimeoutlen=5  " multi-byte key code timeout length
set ttymouse=sgr  " different cursor shapes for different modes
set undodir=~/.vim_undo_hist  " ./setup enforces existence
set undofile  " save undo history
set undolevels=1000  " maximum undo level
set undoreload=10000  " save whole buffer in undo history before deleting
set updatetime=1500  " used for CursorHold autocmds and default is 4000ms
set verbose=0  " increment for debugging, e.g. verbose=2 prints sourced files, extremely useful
set viminfo='500,s50  " remember marks for 500 files (e.g. jumps), exclude registers >50kB of text
set virtualedit=block  " allow cursor to go past line endings in visual block mode
set visualbell  " prefer visual bell to beeps (see also 'noerrorbells')
set whichwrap=[,],<,>,h,l  " <> = left/right insert, [] = left/right normal mode
set wildmenu  " command line completion
set wildmode=longest:list,full  " command line completion
let &g:breakat = '  !*-+;:,./?'  " break lines following punctuation
let &g:cindent = 0  " disable c-style current line indentation
let &g:expandtab = 1  " global expand tab (respect tab toggling)
let &g:foldenable = 1  " global fold enable (respect 'zn' toggling)
let &g:foldmethod = 'syntax'  " global default fold method
let &g:formatlistpat = '^\s*\([*>+-]\|\d\+[)>:.]\)\s\+'  " filetype agnostic bullets
let &g:indentkeys = '0{,0},0),0],0#,!^F,o,O'  " default indentation triggers
let &g:iskeyword = '@,48-57,_,192-255'  " default keywords
let &g:iminsert = 0  " disable language maps (used for caps lock)
let &g:list = 1  " show characters by default
let &g:number = 1  " show line numbers
let &g:relativenumber = 1  " show relative line numbers
let &g:numberwidth = 4  " number column minimum width
let &g:scrolloff = 4  " screen lines above and below cursor
let &g:shortmess .= &buftype ==# 'nofile' ? 'I' : ''  " no intro when starting vim
let &g:shiftwidth = 2  " default 2 spaces
let &g:sidescrolloff = 4  " screen columns left and right of cursor
let &g:signcolumn = 'auto'  " show signs automatically number column
let &g:softtabstop = 2  " default 2 spaces
let &g:spell = 0  " global spell disable (only use text files)
let &g:tabstop = 2  " default 2 spaces
let &g:wildignore = join(parse#get_ignores(2, 1, 0), ',')

" Shared plugin settings {{{2
" Filetypes for several different settings
" NOTE: Here 'man' is for custom man page viewing utils, 'ale-preview' is used with
" :ALEDetail output, 'diff' is used with :GitGutterPreviewHunk output, 'git' is used
" with :Fugitive [show|diff] displays, 'fugitive' is used with other :Fugitive comamnds,
" and 'markdown.lsp_hover' is used with vim-lsp. The remaining filetypes are obvious.
let s:tab_filetypes = [
  \ 'xml', 'make', 'gitconfig', 'text',
\ ]  " use literal tabs
let s:info_filetypes = [
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
  \ 'help', 'netrw', 'job', '*lsp-hover', 'man', 'mru', 'panel', 'qf', 'undotree', 'stdout', 'taglist', 'vim-plug'
\ ]

" Flake8 ignore list (also apply to autopep8):
" NOTE: Keep this in sync with 'pep8' and 'black' file
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
" TODO: Add this to seperate linting configuration file?
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

" Disable normal mode maps {{{2
" * q and @ are for macros, instead reserve for quitting popup windows and tags map
" * Q and K are weird modes never used
" * Z is save and quit shortcut, use for executing
" * ][ and [] can get hit accidentally
" * Ctrl-r is undo, use u and U instead
" * Ctrl-p and Ctrl-n used for menu items, use <C-,> and <C-.> or scroll instead
" * Ctrl-a and Ctrl-x used for incrementing, use + and - instead
" * Backspace scrolls to left and Delete removes character to right
" * Enter and Underscore scrolls down on first non-blank character
" * Shift arrow keys are replaced by option arrow and page scroll commands
for s:key in [
  \ '@', 'q', 'Q', 'K', 'ZZ', 'ZQ', '][', '[]',
  \ '<C-p>', '<C-n>', '<C-a>', '<C-x>', '<C-t>', '<C-r>',
  \ '<S-Up>', '<S-Down>', '<S-Left>', '<S-Right>',
  \ '<Delete>', '<Backspace>', '<CR>', '_',
\ ]
  if empty(maparg(s:key, ''))
    exe 'noremap ' . s:key . ' <Nop>'
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
  \ '<F1>', '<F2>', '<F3>', '<F4>', '<F5>', '<F6>', '<F7>', '<F8>',
  \ '<C-d>', '<C-t>', '<C-h>', '<C-l>', '<C-b>', '<C-z>',
  \ '<C-x><C-n>', '<C-x><C-p>', '<C-x><C-e>', '<C-x><C-y>',
\ ]
  if empty(maparg(s:key, 'i'))
    exe 'inoremap ' . s:key . ' <Nop>'
  endif
endfor

" Remove clunky Cheyenne escape-sequence mappings, not sure how to isolate/disable
" /etc/vimrc without disabling other stuff we want e.g. synax highlighting
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
for s:pair in [['\', 'nv'], ['<Tab>', 'n'], ['<Leader>', 'nv']]
  let s:key = s:pair[0]
  for s:mode in split(s:pair[1], '\zs')  " construct list
    if empty(maparg(s:key, s:mode))
      let s:func = "<sid>gobble_map('" . s:key . "', '" . s:mode . "')"
      exe s:mode . 'map <expr> ' . s:key . ' ' . s:func
    endif
  endfor
endfor

"-----------------------------------------------------------------------------"
" Files and buffers {{{1
"-----------------------------------------------------------------------------"
" Handle buffers and windows {{{2
" NOTE: To avoid accidentally closing vim do not use mapped shortcuts. Instead
" require manual closure with :qall or :quitall.
command! -nargs=? Autosave call switch#autosave(<args>)
nnoremap q <Cmd>call window#close_panes()<CR>
nnoremap <Esc> <Cmd>call map(popup_list(), 'popup_close(v:val)') \| call switch#reveal(0)<CR>
vnoremap <Esc> <Cmd>call map(popup_list(), 'popup_close(v:val)')<CR><C-c>
vnoremap <CR> <Cmd>call map(popup_list(), 'popup_close(v:val)')<CR><C-c>
nnoremap <C-s> <Cmd>call file#update()<CR>
nnoremap <C-q> <Cmd>call window#close_tab()<CR>
nnoremap <C-w> <Cmd>call window#close_panes()<CR><Cmd>call window#close_pane()<CR>
nnoremap <Leader>W <Cmd>call switch#autosave()<CR>

" Refresh session or re-open previous files
" NOTE: Here :Mru shows tracked files during session, will replace current buffer.
command! -bang -nargs=? Refresh runtime autoload/vim.vim
  \ | call vim#config_refresh(<bang>0, <q-args>)
command! -nargs=? Scripts echom 'Scripts matching ' . string(<q-args>) . ':'
  \ | for s:path in utils#get_scripts(<q-args>) | echom s:path | endfor
nnoremap <leader>E <Cmd>call file#reload()<CR>
nnoremap <Leader>r <Cmd>redraw! \| echo ''<CR>
nnoremap <Leader>R <Cmd>Refresh<CR>
let g:MRU_Open_File_Relative = 1

" Buffer selection and management
" NOTE: Here :WipeBufs replaces :Wipeout plugin since has more sources
command! -bang -nargs=* History call file#fzf_history(<q-args>, <bang>0)
command! -bang -nargs=0 Recents call file#fzf_recent(<bang>0)
command! -nargs=0 ShowBufs call file#show_bufs()
command! -nargs=0 WipeBufs call file#wipe_bufs()
nnoremap <Leader>q <Cmd>ShowBufs<CR>
nnoremap <Leader>Q <Cmd>WipeBufs<CR>
nnoremap g, <Cmd>call file#fzf_history('')<CR>
nnoremap g< <Cmd>call file#fzf_recent()<CR>

" General file related utilities {{{2
" NOTE: Here :Drop is similar to :tab drop but handles popup windows
command! -nargs=* -complete=file Drop call file#drop_file(<f-args>)
command! -nargs=? Paths call file#show_paths(<f-args>)
command! -nargs=? Local call switch#localdir(<args>)
nnoremap zp <Cmd>Paths<CR>
nnoremap zP <Cmd>Local<CR>
nnoremap gp <Cmd>call file#show_cfile()<CR>
nnoremap gP <Cmd>call call('file#drop_file', file#expand_cfile())<CR>

" Open file in current directory or some input directory
" NOTE: Anything that is not :Files gets passed to :Drop command
" nnoremap <C-g> <Cmd>Locate<CR>  " uses giant database from Unix 'locate'
" command! -bang -nargs=* -complete=file Files call file#fzf_files(<bang>0, <f-args>)
command! -bang -nargs=* -complete=file Files call file#fzf_files(<bang>0, <f-args>)
command! -bang -nargs=* -complete=file Vsplit call file#fzf_init(<bang>0, 0, 0, 'botright vsplit', <f-args>)
command! -bang -nargs=* -complete=file Split call file#fzf_init(<bang>0, 0, 0, 'botright split', <f-args>)
command! -bang -nargs=* -complete=file Open call file#fzf_init(<bang>0, 0, 0, 'Drop', <f-args>)
nnoremap <C-e> <Cmd>call file#fzf_init(0, 0, 0, 'Split')<CR>
nnoremap <C-r> <Cmd>call file#fzf_init(0, 0, 0, 'Vsplit')<CR>
nnoremap <C-y> <Cmd>call file#fzf_init(0, 0, 1, 'Files')<CR>
nnoremap <F7> <Cmd>call file#fzf_init(0, 0, 0, 'Drop')<CR>
nnoremap <C-o> <Cmd>call file#fzf_init(0, 0, 1, 'Drop')<CR>
nnoremap <C-p> <Cmd>call file#fzf_init(0, 1, 1, 'Files')<CR>
nnoremap <C-g> <Cmd>exe fugitive#Command(0, 0, 0, 0, '', '') =~# '^echoerr' ? 'Git' : 'GFiles'<CR>

" Open file with optional user input
" NOTE: The <Leader> maps open up views of the current file directory
for s:key in ['q', 'w', 'e', 'r'] | silent! exe 'unmap <Tab>' . s:key | endfor
nnoremap <Tab>o <Cmd>call file#fzf_input('Open', parse#get_root())<CR>
nnoremap <Tab>i <Cmd>call file#fzf_input('Open', expand('%:p:h'))<CR>
nnoremap <Tab>p <Cmd>call file#fzf_input('Files', parse#get_root())<CR>
nnoremap <Tab>y <Cmd>call file#fzf_input('Files', expand('%:p:h'))<CR>
nnoremap <Tab>e <Cmd>call file#fzf_input('Split', expand('%:p:h'))<CR>
nnoremap <Tab>r <Cmd>call file#fzf_input('Vsplit', expand('%:p:h'))<CR>

" Mapping and command windows {{{2
" This uses iterm mapping of <F6> to <C-;> and works in all modes
" See: https://stackoverflow.com/a/41168966/4970632
omap <F5> <Plug>(fzf-maps-o)
xmap <F5> <Plug>(fzf-maps-x)
imap <F5> <Plug>(fzf-maps-i)
nnoremap <F5> <Cmd>Maps<CR>
cnoremap <F5> <Esc><Cmd>Commands<CR>
nnoremap <Leader><F5> <Cmd>Commands<CR>

" Vim help and history windows
" NOTE: For some reason even though :help :mes claims count N shows the N most recent
" message, for some reason using 1 shows empty line and 2 shows previous plus newline.
for s:key in ['[[', ']]'] | silent! exe 'unmap! g' . s:key | endfor
for s:key in [';;', '::'] | silent! exe 'unmap! g' . s:key | endfor
nnoremap <Leader>; <Cmd>let &cmdwinheight = window#get_height(0)<CR>q:
nnoremap <Leader>/ <Cmd>let &cmdwinheight = window#get_height(0)<CR>q/
nnoremap <Leader>: <Cmd>History:<CR>
nnoremap <Leader>? <Cmd>History/<CR>
nnoremap <Leader>v <Cmd>call vim#show_help()<CR>
nnoremap <Leader>V <Cmd>Helptags<CR>
nnoremap g; <Cmd>20message<CR>
nnoremap g: @:
vnoremap g: @:

" Shell commands and help windows {{{2
" add shortcut to search for all non-ASCII chars (previously used all escape chars).
" NOTE: Here 'Man' overrides buffer-local 'Man' command defined on man filetypes, so
" must use autoload function. Also see: https://stackoverflow.com/a/41168966/4970632
command! -nargs=? -complete=shellcmd Help call stack#push_stack('help', 'shell#help_page', <f-args>)
command! -nargs=? -complete=shellcmd Man call stack#push_stack('man', 'shell#man_page', <f-args>)
command! -nargs=0 ClearMan call stack#clear_stack('man')
command! -nargs=0 ListHelp call stack#print_stack('help')
command! -nargs=0 ListMan call stack#print_stack('man')
command! -nargs=? PopMan call stack#pop_stack('man', <q-args>, 1)
nnoremap <Leader>n <Cmd>call stack#push_stack('help', 'shell#help_page')<CR>
nnoremap <Leader>m <Cmd>call stack#push_stack('man', 'shell#man_page')<CR>
nnoremap <Leader>N <Cmd>call shell#fzf_help()<CR>
nnoremap <Leader>M <Cmd>call shell#fzf_man()<CR>

" 'Execute' script with different options
" NOTE: Current idea is to use 'ZZ' for running entire file and 'Z<motion>' for
" running chunks of code. Currently 'Z' only defined for python so use workaround.
" NOTE: Critical to label these maps so one is not a prefix of another
" or else we can get a delay. For example do not define <Plug>Execute
nmap Z <Plug>ExecuteMotion
vmap Z <Plug>ExecuteMotion
nmap ZZ <Plug>ExecuteFile0
nmap <Leader>z <Plug>ExecuteFile1
nmap <Leader>Z <Plug>ExecuteFile2
nnoremap <Plug>ExecuteFile0 <Nop>
nnoremap <Plug>ExecuteFile1 <Nop>
nnoremap <Plug>ExecuteFile2 <Nop>
nnoremap <expr> <Plug>ExecuteMotion utils#null_operator_expr()
vnoremap <expr> <Plug>ExecuteMotion utils#null_operator_expr()

" Toggle built-in terminal (mnemonic '!' is similar to ':!')
" NOTE: Map Ctrl-c to literal keypress so it does not close window and use environment
" variable with .bashrc setting to auto-enter to the current file directory.
" See: https://vi.stackexchange.com/q/14519/8084
" silent! tnoremap <silent> <Esc> <C-w>:q!<CR>  " disables all iTerm shortcuts
command! -complete=dir -nargs=? Terminal call shell#show_terminal(<f-args>)
silent! tnoremap <expr> <C-c> "\<C-c>"
nnoremap <Leader>! <Cmd>call shell#show_terminal()<CR>

"-----------------------------------------------------------------------------"
" Windows and folds {{{1
"-----------------------------------------------------------------------------"
" Window and tab management {{{2
" NOTE: Also tried 'FugitiveIndex' and 'FugitivePager' but kept getting confusing
" issues due to e.g. buffer not loaded before autocmds trigger. Instead use below.
let g:tags_skip_filetypes = s:panel_filetypes
let g:tabline_skip_filetypes = s:panel_filetypes
augroup panel_setup
  au!
  au CmdwinEnter * call vim#setup_cmdwin() | call window#setup_panel(1)
  au TerminalWinOpen * call window#setup_panel(1)
  au BufRead,BufEnter fugitive://* if &filetype !=# 'fugitive' | call window#setup_panel() | endif
  au FileType help call vim#setup_help()
  au FileType qf call jump#setup_loc()
  au FileType man call shell#setup_man()
  au FileType gitcommit call git#setup_commit()
  au FileType fugitiveblame call git#setup_blame() | call git#setup_panel()
  au FileType git,diff,fugitive call git#setup_panel()
  for s:type in s:panel_filetypes | let s:arg = s:type ==# 'gitcommit'
    exe 'au FileType ' . s:type . ' call window#setup_panel(' . s:arg . ')'
  endfor
augroup END

" Navigate recent tabs
" WARNING: The g:tab_stack variable is used by tags#get_recents() to put recently
" used tabs in stack at higher priority than others. Critical to keep variables.
silent! au! recents_setup
augroup tabs_setup
  au!
  au BufEnter,BufLeave * call window#update_stack(0)  " next update
  au BufWinLeave * call stack#pop_stack('tab', expand('<afile>'))
  au CursorHold * if localtime() - get(g:, 'tab_time', 0) > 10 | call window#update_stack(0) | endif
augroup END
command! -nargs=0 ClearTabs call stack#clear_stack('tab') | call window#update_stack(0)
command! -nargs=0 ListTabs call stack#print_stack('tab')
command! -nargs=? PopTabs call stack#pop_stack('tab', <q-args>, 1)
nnoremap <Tab><CR> <Cmd>call window#update_stack(0, -1, 2)<CR>
nnoremap <F1> <Cmd>call window#scroll_stack(-v:count1)<CR>
nnoremap <F2> <Cmd>call window#scroll_stack(v:count1)<CR>

" Tab selection and management
" WARNING: FZF cannot create terminals when called inside expr mappings.
" NOTE: Previously used e.g. '<tab>1' maps but not parse count on one keypress
" NOTE: Here :History includes v:oldfiles and open buffers
for s:key in range(1, 10) | exe 'silent! unmap <Tab>' . s:key | endfor
for s:key in ['.', ',', '>', '<'] | exe 'silent! xunmap z' . s:key | endfor
nnoremap g. <Cmd>exe v:count ? 'call window#goto_tab(v:count)' : 'call window#fzf_goto()'<CR>
nnoremap g> <Cmd>exe v:count ? 'call window#move_tab(v:count)' : 'call window#fzf_move()'<CR>
nnoremap g<Space> <Cmd>Windows<CR>
nnoremap z<Space> <Cmd>Buffers<CR>

" Tab and window jumping
nnoremap <Tab>, <Cmd>exe max([tabpagenr() - v:count1, 1]) . 'tabnext'<CR>
nnoremap <Tab>. <Cmd>exe min([tabpagenr() + v:count1, tabpagenr('$')]) . 'tabnext'<CR>
nnoremap <Tab>' <Cmd>silent! tabnext #<CR><Cmd>call file#echo_path('tab')<CR>
nnoremap <Tab>; <Cmd>silent! wincmd p<CR><Cmd>call file#echo_path('window')<CR>
nnoremap <Tab>j <Cmd>silent! wincmd j<CR>
nnoremap <Tab>k <Cmd>silent! wincmd k<CR>
nnoremap <Tab>h <Cmd>silent! wincmd h<CR>
nnoremap <Tab>l <Cmd>silent! wincmd l<CR>

" Tab and window resizing
nnoremap <Tab><Space> <Cmd>call window#default_width() \| call window#default_height()<CR>
nnoremap <Tab><Tab> <Cmd>call window#default_width() \| call window#default_height()<CR>
nnoremap <Tab>1 <Cmd>call window#default_width(1) \| call window#default_height(1)<CR>
nnoremap <Tab>2 <Cmd>call window#default_width(0.5) \| call window#default_height(0.5)<CR>
nnoremap <Tab>3 <Cmd>call window#default_width(0) \| call window#default_height(0)<CR>
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

" General motions and scrolling {{{2
" NOTE: Use parentheses since g0/g$ are navigation and z0/z9 used for color schemes
" NOTE: Mapped jumping commands do not open folds by default, hence the expr below
silent! exe 'runtime autoload/utils.vim'
for s:key in ['gg', 'G', 'H', 'L', 'J', 'K']
  let s:key1 = string(s:key =~? '^[jk]$' ? 'M' : s:key)
  let s:key2 = '(&l:foldopen =~# ''jump\\|all'' ? ''zv'' : '''')'
  exe 'noremap <expr> ' . s:key . ' ' . s:key1 . ' . ' . s:key2
endfor
for s:mode in ['n', 'v']
  exe s:mode . 'noremap _ zzze'
  exe s:mode . 'noremap z9 zb'
  exe s:mode . 'noremap z0 zt'
  exe s:mode . 'noremap z( ze'
  exe s:mode . 'noremap z) zs'
endfor

" Repair modifier-arrow key presses. Use iTerm to remap <BS> and <Del> to Shift-Arrow
" presses, then convert to no-op in normal mode and deletions for insert/command mode.
" NOTE: iTerm remaps Ctrl+Arrow presses to shell scrolling so cannot be used, and
" remaps Cmd+Left/Right to Home/End which are natively understood by vim.
for s:mode in ['', 'i', 'c']  " native motions by word
  exe s:mode . 'noremap <M-Left> <S-Left>'
  exe s:mode . 'noremap <M-Right> <S-Right>'
  exe s:mode . 'noremap <M-Up> <Home>'
  exe s:mode . 'noremap <M-Down> <End>'
endfor
for s:mode in ['i', 'c'] | exe s:mode . 'noremap <S-Up> <C-w>' | endfor
for s:mode in ['i', 'c'] |  exe s:mode . 'noremap <S-Left> <C-u>' | endfor
inoremap <expr> <S-Down> repeat('<Del>', matchend(getline('.')[col('.') - 1:], '\>'))
inoremap <expr> <S-Right> repeat('<Del>', len(getline('.')) - col('.') + 1)
cnoremap <expr> <S-Down> repeat('<Del>', matchend(getcmdline()[getcmdpos() - 1:], '\>'))
cnoremap <expr> <S-Right> repeat('<Del>', len(getcmdline()) - getcmdpos() + 1)

" General and popup/preview window scrolling
" NOTE: Karabiner remaps Ctrl-h/j/k/l keys to arrow key presses so here apply
" maps to both in case working from terminal without these maps. Also note iTerm
" maps mod-delete and mod-backspace keys to shift arrows which do normal mode scrolls.
for s:mode in ['n', 'v', 'i']
  exe s:mode . 'noremap <ScrollWheelLeft> <ScrollWheelRight>'
  exe s:mode . 'noremap <ScrollWheelRight> <ScrollWheelLeft>'
  exe s:mode . 'noremap <expr> <C-u> window#scroll_infer(-0.33, 0)'
  exe s:mode . 'noremap <expr> <C-d> window#scroll_infer(0.33, 0)'
  exe s:mode . 'noremap <expr> <C-b> window#scroll_infer(-0.66, 0)'
  exe s:mode . 'noremap <expr> <C-f> window#scroll_infer(0.66, 0)'
endfor
inoremap <expr> <Up> window#scroll_infer(-1)
inoremap <expr> <Down> window#scroll_infer(1)
inoremap <expr> <C-k> window#scroll_infer(-1)
inoremap <expr> <C-j> window#scroll_infer(1)

" Insert mode popup window completion
" TODO: Consider using Shuougo pum.vim but hard to implement <CR>/<Tab> features.
" NOTE: Enter is 'accept' only if we scrolled down while tab always means 'accept'
augroup popup_setup
  au!
  au InsertEnter * set noignorecase | let b:scroll_state = 0
  au InsertLeave * set ignorecase | let b:scroll_state = 0
augroup END
inoremap <silent> <expr> <C-q> window#close_popup('<Cmd>pclose<CR>')
inoremap <silent> <expr> <C-w> window#close_popup('<Cmd>pclose<CR>')
inoremap <silent> <expr> <Tab> window#close_popup('<C-]><Tab>', 2, 1)
inoremap <silent> <expr> <S-Tab> window#close_popup(edit#insert_delete(0), 0, 1)
inoremap <silent> <expr> <F2> window#close_popup(ddc#map#manual_complete(), 2, 1)
inoremap <silent> <expr> <F1> window#close_popup(edit#insert_delete(0), 0, 1)
inoremap <silent> <expr> <Delete> window#close_popup(edit#insert_delete(1), 1)
inoremap <silent> <expr> <C-g><CR> window#close_popup('<CR>')
inoremap <silent> <expr> <C-g><Space> window#close_popup('<Space>')
inoremap <silent> <expr> <C-g><BackSpace> window#close_popup('<BackSpace>')
inoremap <silent> <expr> <CR> window#close_popup('<C-]><C-r>=edit#insert_delims("r")<CR>', 1, 1)
inoremap <silent> <expr> <Space> window#close_popup('<C-]><C-r>=edit#insert_delims("s")<CR>', 1)
inoremap <silent> <expr> <Backspace> window#close_popup('<C-r>=edit#insert_delims("b")<CR>', 1)

" Command mode wild menu completion
" NOTE: This prevents annoyance where multiple old completion options can be shown
" on top of each other if triggered more than once, and permits workflow where hitting
" e.g. <Right> after scrolling will descend into subfolder and show further options.
" NOTE: This enforces paradigm where <F1>/<F2> is tab-like (horizontally scroll options)
" and <Up>/<Down> is scroll-like (vertically scroll history after clearing options).
augroup complete_setup
  au!
  au CmdlineEnter,CmdlineLeave * let b:complete_state = 0
augroup END
cnoremap <silent> <expr> <Tab> window#close_wild("\<Tab>", 1)
cnoremap <silent> <expr> <S-Tab> window#close_wild("\<S-Tab>", 1)
cnoremap <silent> <expr> <F2> window#close_wild("\<Tab>", 1)
cnoremap <silent> <expr> <F1> window#close_wild("\<S-Tab>", 1)
cnoremap <silent> <expr> <C-k> window#close_wild("\<C-p>")
cnoremap <silent> <expr> <C-j> window#close_wild("\<C-n>")
cnoremap <silent> <expr> <Up> window#close_wild("\<C-p>")
cnoremap <silent> <expr> <Down> window#close_wild("\<C-n>")
cnoremap <silent> <expr> <C-h> window#close_wild("\<Left>")
cnoremap <silent> <expr> <C-l> window#close_wild("\<Right>")
cnoremap <silent> <expr> <Right> window#close_wild("\<Right>")
cnoremap <silent> <expr> <Left> window#close_wild("\<Left>")
cnoremap <silent> <expr> <Delete> window#close_wild("\<Delete>")
cnoremap <silent> <expr> <BS> window#close_wild("\<BS>")
cnoremap <silent> <expr> / window#close_wild('/')

" Reset folds and levels {{{2
" NOTE: Also call fold#update_folds() in common.vim but with 0 to avoid resetting level
" when calling config_refresh(). So call again below whenever buffer enters window.
" NOTE: Here fold#update_folds() re-enforces special expr fold settings for markdown
" and python files then applies default toggle status that differs from buffer-wide
" &foldlevel for fortran python and tex files (e.g. always open \begin{document}).
for s:key in ['z', 'f', 'F', 'n', 'N'] | silent! exe 'unmap! z' . s:key | endfor
command! -bang -count -nargs=? UpdateFolds
  \ call fold#update_folds(<bang>0, <count>) | echom 'Updated folds'
nnoremap zv zvzzze
vnoremap zv zvzzze
nnoremap zV <Cmd>UpdateFolds!<CR>zvzzze
vnoremap zV <Cmd>UpdateFolds!<CR>zvzzze
nnoremap zx <Cmd>call fold#update_folds(0, 0)<CR>
vnoremap zx <Cmd>call fold#update_folds(0, 0)<CR>
nnoremap zX <Cmd>call fold#update_folds(0, 2)<CR>
vnoremap zX <Cmd>call fold#update_folds(0, 2)<CR>
nnoremap zZ <Cmd>UpdateFolds!<CR>
vnoremap zZ <Cmd>UpdateFolds!<CR>
nnoremap <expr> zz (foldclosed('.') > 0 ? 'zvzz' : foldlevel('.') > 0 ? 'zc' : 'zz') . 'ze'
vnoremap <expr> zz fold#toggle_folds_expr() . (foldclosed('.') > 0 ? 'zz' : '') . 'ze'

" Toggle folds over selection or under matches after updating
" NOTE: Here fold#toggle_folds_expr() calls fold#update_folds() before toggling.
" NOTE: These will overwrite 'fastfold_fold_command_suffixes' generated fold-updating
" maps. However now use even faster / more conservative fold#update_folds() method.
nnoremap zaa <Cmd>call fold#toggle_folds()<CR>
nnoremap zcc <Cmd>call fold#toggle_folds(1)<CR>
nnoremap zoo <Cmd>call fold#toggle_folds(0)<CR>
nnoremap <expr> za fold#toggle_folds_expr()
nnoremap <expr> zc fold#toggle_folds_expr(1)
nnoremap <expr> zo fold#toggle_folds_expr(0)
vnoremap <expr> za fold#toggle_folds_expr()
vnoremap <expr> zc fold#toggle_folds_expr(1)
vnoremap <expr> zo fold#toggle_folds_expr(0)

" Toggle nested or recursive folds after updating
" NOTE: Here 'zi' will close or open all nested folds under cursor up to level
" parent (use :echom fold#get_fold() for debugging). Previously toggled with
" recursive-open then non-recursive close but annoying e.g. for huge classes.
" NOTE: Here 'zC' will close fold only up to current level or for definitions
" inside class (special case for python). For recursive motion mapping similar
" to 'zc' and 'zo' could use e.g. noremap <expr> zC fold#toggle_folds_expr(1, 1)
exe 'silent! unmap zn'
nnoremap zN zN<Cmd>call fold#update_folds(0)<CR>
nnoremap zi <Cmd>call fold#toggle_children(0)<CR>
nnoremap zI <Cmd>call fold#toggle_children(1)<CR>
nnoremap zA <Cmd>call fold#toggle_parents()<CR>
nnoremap zC <Cmd>call fold#toggle_parents(1)<CR>
nnoremap zO <Cmd>call fold#toggle_parents(0)<CR>
vnoremap zN zN<Cmd>call fold#update_folds(0)<CR>
vnoremap <expr> zi fold#toggle_children_expr(0)
vnoremap <expr> zI fold#toggle_children_expr(1)
vnoremap <expr> zA fold#toggle_parents_expr()<CR>
vnoremap <expr> zC fold#toggle_parents_expr(1)
vnoremap <expr> zO fold#toggle_parents_expr(0)

" Change fold level and jump between or inside folds
" NOTE: The bracket maps fail without silent! when inside first fold in file
" NOTE: Recursive map required for [Z or ]Z or else way more complicated
" NOTE: Here fold#update_level() without arguments calls fold#update_folds()
" if the level was changed and prints the level change.
call utils#repeat_map('', '[Z', 'FoldBackward', '<Cmd>keepjumps normal! zkza<CR>')
call utils#repeat_map('', ']Z', 'FoldForward', '<Cmd>keepjumps normal! zjza<CR>')
noremap [z <Cmd>keepjumps normal! zk<CR><Cmd>keepjumps normal! [z<CR>
noremap ]z <Cmd>keepjumps normal! zj<CR><Cmd>keepjumps normal! ]z<CR>
noremap zk <Cmd>keepjumps normal! [z<CR>
noremap zj <Cmd>keepjumps normal! ]z<CR>
nnoremap gz <Cmd>call fold#fzf_folds()<CR>
nnoremap z[ <Cmd>call fold#update_level('m')<CR>
nnoremap z] <Cmd>call fold#update_level('r')<CR>
nnoremap z{ <Cmd>call fold#update_level('M')<CR>
nnoremap z} <Cmd>call fold#update_level('R')<CR>
vnoremap z[ <Cmd>call fold#update_level('m')<CR>
vnoremap z] <Cmd>call fold#update_level('r')<CR>
vnoremap z{ <Cmd>call fold#update_level('M')<CR>
vnoremap z} <Cmd>call fold#update_level('R')<CR>

"-----------------------------------------------------------------------------"
" Searching and jumping {{{1
"-----------------------------------------------------------------------------"
" Navigate jumplist {{{2
" NOTE: This accounts for iterm function-key maps and karabiner arrow-key maps
" See: https://stackoverflow.com/a/27194972/4970632
exe 'silent! unmap! gJ' | exe 'silent! unmap! gK'
silent! au! jumplist_setup
augroup jumps_setup
  au!
  au CursorHold,TextChanged,InsertLeave * if utils#none_pending() | call jump#push_jump() | endif
augroup END
command! -bang -nargs=0 Jumps call jump#fzf_jumps(<bang>0)
nnoremap g<Down> <Cmd>call jump#fzf_jumps()<CR>
nnoremap g<Up> <Cmd>call jump#fzf_jumps()<CR>
noremap <C-j> <Esc><Cmd>call jump#next_jump(-v:count1)<CR>
noremap <C-k> <Esc><Cmd>call jump#next_jump(v:count1)<CR>
noremap <Down> <Esc><Cmd>call jump#next_jump(-v:count1)<CR>
noremap <Up> <Esc><Cmd>call jump#next_jump(v:count1)<CR>

" Navigate buffer changelist with up/down arrows
" NOTE: This accounts for iterm function-key maps and karabiner arrow-key maps
" change entries removed. Here <F5>/<F6> are <Ctrl-/>/<Ctrl-\> in iterm
command! -bang -nargs=0 Changes call jump#fzf_changes(<bang>0)
nnoremap g<Left> <Cmd>call jump#fzf_changes()<CR>
nnoremap g<Right> <Cmd>call jump#fzf_changes()<CR>
noremap <C-h> <Esc><Cmd>call jump#next_change(-v:count1)<CR>
noremap <C-l> <Esc><Cmd>call jump#next_change(v:count1)<CR>
noremap <Left> <Esc><Cmd>call jump#next_change(-v:count1)<CR>
noremap <Right> <Esc><Cmd>call jump#next_change(v:count1)<CR>

" Navigate across recent tag jumps
" NOTE: Apply in vimrc to avoid overwriting. This works by overriding both fzf and
" internal tag jumping utils. Ignores tags resulting from direct :tag or <C-]>
command! -nargs=0 ClearTags call stack#clear_stack('tag')
command! -nargs=0 ListTags call stack#print_stack('tag')
command! -nargs=? PopTags call stack#pop_stack('tag', <q-args>, 1)
command! -nargs=* -complete=file ShowIgnores
  \ echom 'Tag ignores: ' . join(parse#get_ignores(0, 0, 0, <f-args>), ' ')
noremap <F3> <Esc>m'<Cmd>call tag#next_stack(-v:count1)<CR>
noremap <F4> <Esc>m'<Cmd>call tag#next_stack(v:count1)<CR>

" Jump to marks and declare alphabetic marks using counts (navigate with ]` and [`)
" NOTE: Marks does not handle file switching and :Jumps has an fzf error so override.
" NOTE: Uppercase marks unlike lowercase marks work between files and are saved in
" viminfo, so use them. Also numbered marks are mostly internal, can be configured
" to restore cursor position after restarting, also used in viminfo.
command! -bang -nargs=0 Marks call mark#fzf_marks(<bang>0)
command! -nargs=* SetMarks call mark#set_marks(<f-args>)
command! -nargs=* DelMarks call mark#del_marks(<f-args>)
nnoremap z_ <Cmd>call mark#set_marks(parse#get_register('m'))<CR>
nnoremap <expr> g_ v:count ? '`' . parse#get_register('`') : '<Cmd>call mark#fzf_marks()<CR>'
nnoremap <Leader>_ <Cmd>call mark#del_marks(get(g:, 'mark_name', 'A'))<CR>
nnoremap <Leader>- <Cmd>call mark#del_marks()<CR>
noremap <C-n> <Esc><Cmd>call mark#next_mark(-v:count1)<CR>
noremap <F8> <Esc><Cmd>call mark#next_mark(v:count1)<CR>

" Navigate tag stack, location list, and quickfix list
" NOTE: In general location list and quickfix list filled by ale, but quickfix also
" temporarily filled by lsp commands or fzf mappings, so add below generalized
" mapping for jumping between e.g. variables, grep matches, tag matches, etc.
command! -count=1 Lprev call jump#next_loc(<count>, 'loc', 1)
command! -count=1 Lnext call jump#next_loc(<count>, 'loc', 0)
command! -count=1 Qprev call jump#next_loc(<count>, 'qf', 1)
command! -count=1 Qnext call jump#next_loc(<count>, 'qf', 0)
nnoremap [{ <Cmd>exe v:count1 . 'Qprev'<CR><Cmd>call window#show_list(1)<CR><Cmd>wincmd p<CR>
nnoremap ]} <Cmd>exe v:count1 . 'Qnext'<CR><Cmd>call window#show_list(1)<CR><Cmd>wincmd p<CR>
nnoremap [X <Cmd>exe v:count1 . 'Qprev'<CR>
nnoremap ]X <Cmd>exe v:count1 . 'Qnext'<CR>
nnoremap [x <Cmd>exe v:count1 . 'Lprev'<CR>
nnoremap ]x <Cmd>exe v:count1 . 'Lnext'<CR>
nnoremap [Y <Cmd>exe v:count1 . 'tag!'<CR>
nnoremap ]Y <Cmd>exe v:count1 . 'pop!'<CR>
nnoremap [y <Cmd>exe v:count1 . 'tag'<CR>
nnoremap ]y <Cmd>exe v:count1 . 'pop'<CR>

" Line searching and grepping {{{2
" NOTE: This is only useful when 'search' excluded from &foldopen. Use to quickly
" jump over possibly-irrelevant matches without opening unrelated folds.
for s:map in ['//', '/?', '?/', '??'] | silent! exe 'unmap g' . s:map | endfor
command! -bang -nargs=* BLines call grep#call_lines(0, 0, <q-args>, <bang>0)
command! -bang -nargs=* Lines call grep#call_lines(1, 0, <q-args>, <bang>0)
nnoremap / <Cmd>let b:open_search = 0<CR>/
nnoremap ? <Cmd>let b:open_search = 0<CR>?
nnoremap g/ <Cmd>call grep#call_grep('lines', 0, 0)<CR>
nnoremap g? <Cmd>call grep#call_grep('lines', 1, 0)<CR>
nnoremap z; <Cmd>call switch#showmatches(1)<CR>
nnoremap z: <Cmd>call switch#showchanges(1)<CR>
vnoremap z; <Cmd>call switch#showmatches(1)<CR>
vnoremap z: <Cmd>call switch#showchanges(1)<CR>

" Search over current scope or selected line range
" NOTE: This overrides default vim-tags g/ and g? maps. Allows selecting range with
" input motion. Useful for debugging text objexts or when scope algorithm fails.
nnoremap z// <Cmd>call tags#set_search('', 1)<CR><Cmd>call feedkeys(empty(@/) ? '' : '/' . @/, 'n')<CR>
nnoremap z?? <Cmd>call tags#set_search('', 1)<CR><Cmd>call feedkeys(empty(@/) ? '' : '?' . @/, 'n')<CR>
vnoremap <expr> / edit#sel_lines_expr(0)
vnoremap <expr> ? edit#sel_lines_expr(1)
nnoremap <expr> z/ edit#sel_lines_expr(0)
nnoremap <expr> z? edit#sel_lines_expr(1)
vnoremap <expr> z/ edit#sel_lines_expr(0)
vnoremap <expr> z? edit#sel_lines_expr(1)

" Interactive file jumping with grep commands
" NOTE: Maps use default search pattern '@/'. Commands can be called with arguments
" to explicitly specify path (without arguments each name has different default).
" NOTE: Commands add flexibility to native fzf.vim commands. Note Rg is faster and
" has nicer output so use by default: https://unix.stackexchange.com/a/524094/112647
command! -range=0 -bang -nargs=* -complete=file Grep call call('grep#call_rg', [<bang>0, <count>, tags#get_search(2), <f-args>])
command! -range=0 -bang -nargs=* -complete=file Find call call('grep#call_rg', [<bang>0, <count>, tags#get_search(1), <f-args>])
command! -range=0 -bang -nargs=+ -complete=file Ag call grep#call_ag(<bang>0, <count>, <f-args>)
command! -range=0 -bang -nargs=+ -complete=file Rg call grep#call_rg(<bang>0, <count>, <f-args>)
nnoremap g' <Cmd>call grep#call_grep('rg', 1, 0)<CR>
nnoremap g" <Cmd>call grep#call_grep('rg', 0, 2)<CR>
nnoremap z' <Cmd>call grep#call_grep('rg', 1, 2)<CR>
nnoremap z" <Cmd>call grep#call_grep('rg', 1, 3)<CR>

" Grepping uncommented print statements
" NOTE: These searches all open projects by default
" NOTE: Regexes are assigned to @/ and translated with grep#regex()
let s:regex_code = '\%(^\s*\|[*;&|]\s\+\)'
let s:regex_bugs = s:regex_code . '\(ic(.*)\|echo\>.*2>&1\|unsilent\s\+echom\?\>\)'
let s:regex_echo = s:regex_code . '\(print(.*)\|echom\?\>\)'
let s:regex_diff = '^' . repeat('[<>=|]', 7) . '\($\|\s\)'
command! -bang -nargs=* -complete=file Debugs call grep#call_rg(<bang>0, 2, s:regex_bugs <f-args>)
command! -bang -nargs=* -complete=file Prints call grep#call_rg(<bang>0, 2, s:regex_echo, <f-args>)
command! -bang -nargs=* -complete=file Conflicts call grep#call_rg(<bang>0, 2, s:regex_diff, <f-args>)
nnoremap gB <Cmd>Debugs!<CR>
nnoremap zB <Cmd>Prints!<CR>
nnoremap gG <Cmd>Conflicts!<CR>

" Convenience grep maps and commands
" NOTE: This searches current open project by default
" NOTE: Regexes are assigned to @/ and translated with grep#regex()
let s:regex_note = '\<\(Note\|NOTE\):'
let s:regex_todo = '\<\(Todo\|TODO\|Fixme\|FIXME\):'
let s:regex_warn = '\<\(Warning\|WARNING\|Error\|ERROR\):'
let s:regex_code = '\(print(.*)\|echom\?\>\)'
command! -bang -nargs=* -complete=file Notes call grep#call_rg(<bang>0, 2, s:regex_note, <f-args>)
command! -bang -nargs=* -complete=file Todos call grep#call_rg(<bang>0, 2, s:regex_todo, <f-args>)
command! -bang -nargs=* -complete=file Warnings call grep#call_rg(<bang>0, 2, s:regex_warn, <f-args>)
nnoremap gE <Cmd>Todos<CR>
nnoremap gM <Cmd>Notes<CR>
nnoremap gW <Cmd>Warnings<CR>
nnoremap zE <Cmd>Todos!<CR>
nnoremap zM <Cmd>Notes!<CR>
nnoremap zW <Cmd>Warnings!<CR>

" Visual mode and general motions {{{2
" NOTE: Select mode (e.g. by typing 'gh') is same as visual but enters insert mode
" when you start typing, to emulate typing after click-and-drag. Never use it.
" NOTE: Throughout vimrc marks y and z are reserved for internal map utilities. Here
" use 'y' for mouse click location and 'z' for visual mode entrance location, then
" start new visual selection between 'y' and 'z'. Generally 'y' should be temporary
for s:key in ['v', 'V'] | exe 'nnoremap ' . s:key . ' <Esc>mz' . s:key | endfor
for s:key in ['v', 'V'] | exe 'vnoremap ' . s:key . ' <Esc>mz' . s:key | endfor
nnoremap gn mzgn
nnoremap gN mzgN
nnoremap <C-v> <Cmd>WrapToggle 0<CR>mz<C-v>
vnoremap <C-v> <Esc><Cmd>WrapToggle 0<CR>mz<C-v>
vnoremap <LeftMouse> <LeftMouse>my<Cmd>exe 'keepjumps normal! `z' . visualmode() . '`y' \| delmark y<CR>

" Navigate matches and regions without changing jumplist
" NOTE: Sentence jumping mapped with textobj#sentence#move_[np] for most filetypes.
" NOTE: Original vim idea is that these commands take us far away from cursor but
" typically use scrolling to go far away. So now use CursorHold approach.
for s:key in ['(', ')'] | exe 'silent! unmap ' . s:key | endfor
nnoremap ; <Cmd>call switch#hlsearch(1 - v:hlsearch, 1)<CR>
vnoremap ; <Cmd>call switch#hlsearch(1 - v:hlsearch, 1)<CR>
noremap N <Cmd>call jump#next_search(-v:count1)<CR>
noremap n <Cmd>call jump#next_search(v:count1)<CR>
noremap { <Cmd>exe 'keepjumps normal! ' . v:count1 . '{'<CR>
noremap } <Cmd>exe 'keepjumps normal! ' . v:count1 . '}'<CR>

" Navigate horizontally ignoring concealed regions
" NOTE: Here h/l skip concealed syntax regions and matchadd() matches (respecting
" &concealcursor values) and m/M is the missing previous end-of-word mapping.
noremap <expr> h (v:count ? '<Esc>' : '') . syntax#next_nonconceal(-v:count1)
noremap <expr> l (v:count ? '<Esc>' : '') . syntax#next_nonconceal(v:count1)
noremap w <Cmd>call jump#next_word('w')<CR>
noremap W <Cmd>call jump#next_word('W')<CR>
noremap b <Cmd>call jump#next_word('b')<CR>
noremap B <Cmd>call jump#next_word('B')<CR>
noremap e <Cmd>call jump#next_word('e')<CR>
noremap E <Cmd>call jump#next_word('E')<CR>
noremap m <Cmd>call jump#next_word('ge')<CR>
noremap M <Cmd>call jump#next_word('gE')<CR>

" Move between alphanumeric groups of characters (i.e. excluding dots, dashes,
" underscores). This is consistent with tmux vim selection navigation
noremap gw <Cmd>call jump#next_part('w', 0)<CR>
noremap gb <Cmd>call jump#next_part('b', 0)<CR>
noremap ge <Cmd>call jump#next_part('e', 0)<CR>
noremap gm <Cmd>call jump#next_part('m', 0)<CR>
call utils#repeat_map('o', 'gw', 'AlphaNextStart', "<Cmd>call jump#next_part('w', 0, v:operator)<CR>")
call utils#repeat_map('o', 'gb', 'AlphaPrevStart', "<Cmd>call jump#next_part('b', 0, v:operator)<CR>")
call utils#repeat_map('o', 'ge', 'AlphaNextEnd',   "<Cmd>call jump#next_part('e', 0, v:operator)<CR>")
call utils#repeat_map('o', 'gm', 'AlphaPrevEnd',   "<Cmd>call jump#next_part('m, 0, v:operator)<CR>")

" Move between groups of characters with the same case
" NOTE: This is helpful when refactoring and renaming variables
noremap zw <Cmd>call jump#next_part('w', 1)<CR>
noremap zb <Cmd>call jump#next_part('b', 1)<CR>
noremap ze <Cmd>call jump#next_part('e', 1)<CR>
noremap zm <Cmd>call jump#next_part('m', 1)<CR>
call utils#repeat_map('o', 'zw', 'CaseNextStart', "<Cmd>call jump#next_part('w', 1, v:operator)<CR>")
call utils#repeat_map('o', 'zb', 'CasePrevStart', "<Cmd>call jump#next_part('b', 1, v:operator)<CR>")
call utils#repeat_map('o', 'ze', 'CaseNextEnd',   "<Cmd>call jump#next_part('e', 1, v:operator)<CR>")
call utils#repeat_map('o', 'zm', 'CasePrevEnd',   "<Cmd>call jump#next_part('m, 1, v:operator)<CR>")

" Comments and header regions {{{2
" NOTE: <Plug> name cannot be subset of other name or results in delay
call utils#repeat_map('n', 'g-', 'DashSingle', '<Cmd>call comment#append_line("-", 0)<CR>')
call utils#repeat_map('n', 'z-', 'DashDouble', '<Cmd>call comment#append_line("-", 1)<CR>')
call utils#repeat_map('n', 'g=', 'EqualSingle', '<Cmd>call comment#append_line("=", 0)<CR>')
call utils#repeat_map('n', 'z=', 'EqualDouble', '<Cmd>call comment#append_line("=", 1)<CR>')
call utils#repeat_map('v', 'g-', 'VDashSingle', '<Cmd>call comment#append_line("-", 0, "''<", "''>")<CR>')
call utils#repeat_map('v', 'z-', 'VDashDouble', '<Cmd>call comment#append_line("-", 1, "''<", "''>")<CR>')
call utils#repeat_map('v', 'g=', 'VEqualSingle', '<Cmd>call comment#append_line("=", 0, "''<", "''>")<CR>')
call utils#repeat_map('v', 'z=', 'VEqualDouble', '<Cmd>call comment#append_line("=", 1, "''<", "''>")<CR>')

" Insert various comment blocks
" NOTE: This disables repitition of title insertions
for s:key in ';:/?''"' | silent! exe 'unmap gc' . s:key | endfor
let s:author = '"Author: Luke Davis (lukelbd@gmail.com)"'
let s:edited = '"Edited: " . strftime("%Y-%m-%d")'
call utils#repeat_map('n', 'z.;', 'HeadLine', '<Cmd>call comment#header_line("-", 77, 0)<CR>')
call utils#repeat_map('n', 'z./', 'HeadAuth', '<Cmd>call comment#append_note(' . s:author . ')<CR>')
call utils#repeat_map('n', 'z.?', 'HeadEdit', '<Cmd>call comment#append_note(' . s:edited . ')<CR>')
call utils#repeat_map('n', 'z.:', '', '<Cmd>call comment#header_line("-", 77, 1)<CR>')
call utils#repeat_map('n', "z.'", '', '<Cmd>call comment#header_inchar()<CR>')
call utils#repeat_map('n', 'z."', '', '<Cmd>call comment#header_inline(5)<CR>')

" Navigate docstrings comments and methods
" Capital uses only non-variable-assignment or zero-indent
noremap [d <Cmd>call python#next_docstring(-v:count1, 0)<CR>
noremap ]d <Cmd>call python#next_docstring(v:count1, 0)<CR>
noremap [D <Cmd>call python#next_docstring(-v:count1, 1)<CR>
noremap ]D <Cmd>call python#next_docstring(v:count1, 1)<CR>
noremap [c <Cmd>call comment#next_comment(-v:count1, 0)<CR>
noremap ]c <Cmd>call comment#next_comment(v:count1, 0)<CR>
noremap [C <Cmd>call comment#next_comment(-v:count1, 1)<CR>
noremap ]C <Cmd>call comment#next_comment(v:count1, 1)<CR>

" Navigate notes and todos
" Capital uses only top-level zero-indent headers
noremap [b <Cmd>call comment#next_header(-v:count1, 0)<CR>
noremap ]b <Cmd>call comment#next_header(v:count1, 0)<CR>
noremap [B <Cmd>call comment#next_header(-v:count1, 1)<CR>
noremap ]B <Cmd>call comment#next_header(v:count1, 1)<CR>
noremap [q <Cmd>call comment#next_label(-v:count1, 0, 'todo', 'fixme')<CR>
noremap ]q <Cmd>call comment#next_label(v:count1, 0, 'todo', 'fixme')<CR>
noremap [Q <Cmd>call comment#next_label(-v:count1, 1, 'todo', 'fixme')<CR>
noremap ]Q <Cmd>call comment#next_label(v:count1, 1, 'todo', 'fixme')<CR>
noremap [a <Cmd>call comment#next_label(-v:count1, 0, 'note', 'warning', 'error')<CR>
noremap ]a <Cmd>call comment#next_label(v:count1, 0, 'note', 'warning', 'error')<CR>
noremap [A <Cmd>call comment#next_label(-v:count1, 1, 'note', 'warning', 'error')<CR>
noremap ]A <Cmd>call comment#next_label(v:count1, 1, 'note', 'warning', 'error')<CR>

"-----------------------------------------------------------------------------"
" Normal and insert mode {{{1
"-----------------------------------------------------------------------------"
" Repeats and registers {{{2
" Override normal mode repititions
" NOTE: Here repeat_setup and repeat#undo() are copied from vim-repeat plugin to fix
" race condition and b:changedtick bugs (see autoload/repeat.vim for details).
silent! au! repeatPlugin
augroup repeat_setup
  au!
  au BufEnter,BufWritePost * if g:repeat_tick == 0 | let g:repeat_tick = b:changedtick | endif
  au BufLeave,BufWritePre,BufReadPre * let g:repeat_tick = (!g:repeat_tick || g:repeat_tick == b:changedtick) ? 0 : -1
augroup END
nnoremap u <Cmd>call repeat#undo(0, v:count1)<CR>
nnoremap U <Cmd>call repeat#undo(1, v:count1)<CR>
nnoremap . <Cmd>if !repeat#run(v:count) \| echoerr repeat#errmsg() \| endif<CR>

" Override insert mode undo and register selection
" NOTE: Here edit#insert_init() returns undo-resetting <C-g>u and resets b:insert_mode
" based on cursor position. Also run this on InsertEnter e.g. after 'ciw' operator map
silent! au! undo_setup
augroup insert_setup
  au!
  au InsertEnter * call edit#insert_undo()
augroup END
inoremap <expr> <F7> '<Cmd>undo<CR><Esc>' . edit#insert_init()
inoremap <expr> <F8> edit#insert_undo()
inoremap <expr> <C-r> parse#get_register('i')
cnoremap <expr> <C-r> parse#get_register('c')

" Record macro by pressing Q with optional count
" NOTE: This permits e.g. 1, or '1, for specific macros. Note cannot run 'q' from autoload
" NOTE: Vim inserts key code <80><fd>5 (corresponds to ASCII table number 53 which is
" KE_IGNORE) when pressing escape in insert mode if ttimeout is enabled so that when
" mapping is replayed the escape will be parsed literally. See: https://vi.stackexchange.com/a/35207/8084
nnoremap <expr> , v:register ==# '"' ? parse#get_register('@') : '@' . v:register
vnoremap <expr> , v:register ==# '"' ? parse#get_register('@') : '@' . v:register
nnoremap <expr> Q empty(reg_recording()) ? parse#get_register('q')
  \ : 'q<Cmd>call parse#set_translate(' . string(reg_recording()) . ', "q")<CR>'
nnoremap <expr> Q empty(reg_recording()) ? parse#get_register('q')
  \ : 'q<Cmd>call parse#set_translate(' . string(reg_recording()) . ', "q")<CR>'

" Declare alphabetic registers with count (consistent with mark utilities)
" WARNING: Critical to use 'nmap' and 'vmap' since do not want operator-mode
" NOTE: Pressing ' or " followed by number uses macro in registers 0 to 9 and
" pressing ' or " followed by normal-mode command uses black hole or clipboard.
nnoremap <expr> ' (v:count ? '<Esc>' : '') . parse#get_register('', '_')
nnoremap <expr> " (v:count ? '<Esc>' : '') . parse#get_register('@', '*')
vnoremap <expr> ' parse#get_register('', '_')
vnoremap <expr> " parse#get_register('@', '*')

" Override changes and deletions
" NOTE: Uppercase registers are same as lowercase but saved in viminfo.
nnoremap <expr> c (v:count ? '<Esc>' : '') . (&l:foldopen =~# 'insert\|all' ? 'zv' : '') . parse#get_register('') . edit#insert_init('c')
nnoremap <expr> C (v:count ? '<Esc>' : '') . (&l:foldopen =~# 'insert\|all' ? 'zv' : '') . parse#get_register('') . edit#insert_init('C')
vnoremap <expr> c parse#get_register('') . edit#insert_init('c')
vnoremap <expr> C parse#get_register('') . edit#insert_init('C')

" Delete text, specify registers with counts (no more dd mapping)
" NOTE: Visual counts are ignored, and cannot use <Esc> because that exits visual mode
nnoremap <expr> d (v:count ? '<Esc>' : '') . parse#get_register('') . 'd'
nnoremap <expr> D (v:count ? '<Esc>' : '') . parse#get_register('') . 'D'
vnoremap <expr> d parse#get_register('') . 'd'
vnoremap <expr> D parse#get_register('') . 'D'

" Yank text, specify registers with counts (no more yy mappings)
" NOTE: Here 'Y' yanks to end of line, matching 'C' and 'D' instead of 'yy' synonym
nnoremap <expr> y (v:count ? '<Esc>' : '') . parse#get_register('') . 'y'
nnoremap <expr> Y (v:count ? '<Esc>' : '') . parse#get_register('') . 'y$'
vnoremap <expr> y parse#get_register('') . 'y'
vnoremap <expr> Y parse#get_register('') . 'y'

" Paste from the nth previously deleted or changed text
" NOTE: v_P does not overwrite register: https://stackoverflow.com/a/74935585/4970632
nnoremap <expr> p parse#get_register('') . 'p'
nnoremap <expr> P parse#get_register('') . 'P'
vnoremap <expr> p parse#get_register('') . 'P'
vnoremap <expr> P parse#get_register('') . 'P'

" Remove single character
" NOTE: This omits single-character deletions from register by default
nnoremap <expr> gx edit#insert_init('gi')
nnoremap <expr> cx '"_' . edit#insert_init('c') . 'l'
nnoremap <expr> cX '"_' . edit#insert_init('c') . 'h'
nnoremap dx x
nnoremap dX X
nnoremap x "_x
nnoremap X "_X
vnoremap x "_x
vnoremap X "_X

" Indents wrapping and spaces {{{2
" NOTE: This enforces defaults without requiring 'set' during session refresh.
" NOTE: To avoid overwriting fugitive inline-diff maps also add these to common.vim
silent! au! expandtab_setup
augroup tab_setup
  au!
  au BufWinEnter * call switch#tabs(index(s:tab_filetypes, &l:filetype) >= 0, 1)
augroup END
command! -nargs=? TabToggle call switch#tabs(<args>)
nnoremap <Leader><Tab> <Cmd>call switch#tabs()<CR>
nnoremap <expr> > '<Esc>' . edit#indent_lines_expr(0, v:count1)
nnoremap <expr> < '<Esc>' . edit#indent_lines_expr(1, v:count1)
vnoremap <expr> > edit#indent_lines_expr(0, v:count1)
vnoremap <expr> < edit#indent_lines_expr(1, v:count1)

" Insert empty lines or swap lines
" Mnemonic is 'cut line' at cursor, character under cursor will be deleted
" NOTE: See 'vim-unimpaired' for original. This is similar to vim-succinct 'e' object
call utils#repeat_map('n', '[e', 'BlankUp', '<Cmd>put!=repeat(nr2char(10), v:count1) \| '']+1<CR>')
call utils#repeat_map('n', ']e', 'BlankDown', '<Cmd>put=repeat(nr2char(10), v:count1) \| ''[-1<CR>')
call utils#repeat_map('n', 'ch', 'ChangeLeft', '<Cmd>call edit#change_chars(1)<CR>')
call utils#repeat_map('n', 'cl', 'ChangeRight', '<Cmd>call edit#change_chars(0)<CR>')
call utils#repeat_map('n', 'ck', 'ChangeAbove', '<Cmd>call edit#change_lines(1)<CR>')
call utils#repeat_map('n', 'cj', 'ChangeBelow', '<Cmd>call edit#change_lines(0)<CR>')
call utils#repeat_map('n', 'cL', 'ChangeSplit', 'myi<CR><Esc><Cmd>keepjumps normal! `y<Cmd>delmark y<CR>')

" Join and wrap lines with user formatting
" Uses :Join command added by conjoin plugin
" NOTE: Here e.g. '2J' joins 'next two lines' instead of 'current plus one'
" NOTE: Use insert-mode <C-F> to format line if '!^F' present in &indentkeys
command! -range -nargs=? Format <line1>,<line2>call edit#format_lines(<args>)
nnoremap gqq <Cmd>call edit#format_lines(v:count)<CR>
nnoremap <expr> gq edit#format_lines_expr(v:count)
vnoremap <expr> gq edit#format_lines_expr(v:count)
nnoremap gJ <Cmd>call edit#join_lines(0, 0)<CR>
nnoremap gK <Cmd>call edit#join_lines(1, 0)<CR>
vnoremap <expr> gJ edit#join_lines_expr(0, 0)
vnoremap <expr> gK edit#join_lines_expr(1, 0)
nnoremap zJ <Cmd>call edit#join_lines(0, 1)<CR>
nnoremap zK <Cmd>call edit#join_lines(1, 1)<CR>
vnoremap <expr> zJ edit#join_lines_expr(0, 1)
vnoremap <expr> zK edit#join_lines_expr(1, 1)

" Copying caps and insert mode {{{2
" NOTE: This enforces defaults without requiring 'set' in vimrc or ftplugin that
" override session settings. Tried BufNewFile,BufReadPost but they can fail.
let s:copy_filetypes = s:data_filetypes + s:info_filetypes + s:panel_filetypes
augroup copy_setup
  au!
  au BufWinEnter * call switch#copy(0, index(s:copy_filetypes, &l:filetype) >= 0, 1)
augroup END
command! -nargs=? CopyToggle call switch#copy(1, <args>)
command! -nargs=? ConcealToggle call switch#conceal(<args>)  " mainly just for tex
cnoremap <expr> <C-v> switch#caps()
inoremap <expr> <C-v> switch#caps()
nnoremap <Leader>c <Cmd>call switch#copy(1)<CR>
nnoremap <Leader>C <Cmd>doautocmd BufWinEnter<CR>
nnoremap g[ <Cmd>call switch#reveal(0)<CR>
nnoremap g] <Cmd>call switch#reveal(1)<CR>
vnoremap g[ <Cmd>call switch#reveal(0)<CR>
vnoremap g] <Cmd>call switch#reveal(1)<CR>

" Stop cursor from moving after undo or leaving insert mode
" NOTE: Otherwise repeated i<Esc>i<Esc> will drift cursor to left. Also
" critical to keep jumplist or else populated after every single insertion.
augroup insert_repair
  au!
  au InsertLeave * exe 'silent! keepjumps normal! `^'
augroup END
nnoremap <expr> i edit#insert_init('i')
nnoremap <expr> I edit#insert_init('I')
nnoremap <expr> a edit#insert_init('a')
nnoremap <expr> A edit#insert_init('A')
nnoremap <expr> o edit#insert_init('o')
nnoremap <expr> O edit#insert_init('O')

" Enter insert mode from visual mode
" NOTE: Here 'I' goes to start of selection and 'A' end of selection
exe 'silent! vunmap o' | exe 'silent! vunmap O'
vnoremap <expr> gi '<Esc>' . edit#insert_init('i')
vnoremap <expr> gI '<Esc>' . edit#insert_init('I')
vnoremap <expr> ga '<Esc>' . edit#insert_init('a')
vnoremap <expr> gA '<Esc>' . edit#insert_init('A')
vnoremap <expr> go '<Esc>' . edit#insert_init('o')
vnoremap <expr> gO '<Esc>' . edit#insert_init('O')
vnoremap <expr> I mode() =~# '^[vV]'
  \ ? '<Esc><Cmd>keepjumps normal! `<<CR>' . edit#insert_init('i') : edit#insert_init('I')
vnoremap <expr> A mode() =~# '^[vV]'
  \ ? '<Esc><Cmd>keepjumps normal! `><CR>' . edit#insert_init('a') : edit#insert_init('A')

" Enter insert mode with paste toggle
" NOTE: Switched easy-align mapping from ga for consistency here
nnoremap <expr> ga switch#paste() . edit#insert_init('a')
nnoremap <expr> gA switch#paste() . edit#insert_init('A')
nnoremap <expr> gi switch#paste() . edit#insert_init('i')
nnoremap <expr> gI switch#paste() . edit#insert_init('I')
nnoremap <expr> go switch#paste() . edit#insert_init('o')
nnoremap <expr> gO switch#paste() . edit#insert_init('O')
nnoremap <expr> gc switch#paste() . parse#get_register('') . edit#insert_init('c')
nnoremap <expr> gC switch#paste() . parse#get_register('') . edit#insert_init('C')

" Characters and spelling {{{2
" NOTE: \x7F-\x9F are actually displayable but not part of ISO standard so not shown
" by vim (also used as dummy no-match in comment.vim). See https://www.ascii-code.com
nmap ` <Plug>(characterize)
vmap ` <Plug>(characterize)
nnoremap ~ ga
nnoremap g` /[^\x00-\x7F]<CR>
nnoremap g~ /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]<CR>

" Change case for word or motion
" NOTE: Here 'zu' is analgogous to 'zb' used for boolean toggle
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

" Toggle and navigate spell checking
" NOTE: This enforces defaults without requiring 'set' during session refresh.
augroup spell_setup
  au!
  au BufWinEnter * let &l:spell = index(s:lang_filetypes, &l:filetype) >= 0
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
nnoremap gs <Cmd>call edit#spell_check()<CR>
nnoremap gS <Cmd>call edit#spell_check(v:count)<CR>
vnoremap gs <Cmd>call edit#spell_check()<CR>
vnoremap gS <Cmd>call edit#spell_check(v:count)<CR>
nnoremap zs zg
nnoremap zS zug
vnoremap zs zg
vnoremap zS zug

" Preset substitutions {{{2
" NOTE: Critical to have separate visual and normal maps
" NOTE: This works recursively with the below maps.
function! s:feed_replace() abort
  let char = getcharstr()
  let rmap = '\' . char
  if empty(maparg(rmap)) | return | endif  " replacement exists
  let motion = mode() !~? '^n' ? '' : char =~? '^[arnu]' ? 'ip' : 'al'
  call feedkeys(rmap . motion, 'm')
endfunction
nnoremap \\ <Cmd>call <sid>feed_replace()<CR>

" Sort or reverse lines using variety of :sort arguments
" Here 'i' ignores case, 'n' is numeric, 'f' is by float
" See: https://superuser.com/a/189956/506762
vnoremap <expr> \a edit#sort_lines_expr()
nnoremap <expr> \a edit#sort_lines_expr()
vnoremap <expr> \A edit#sort_lines_expr('i')
nnoremap <expr> \A edit#sort_lines_expr('i')
vnoremap <expr> \n edit#sort_lines_expr('n')
nnoremap <expr> \n edit#sort_lines_expr('n')
vnoremap <expr> \N edit#sort_lines_expr('f')
nnoremap <expr> \N edit#sort_lines_expr('f')

" Reverse or filter to unique lines
" Here 'i' ignores case, 'u' is unique sort
" See: https://vim.fandom.com/wiki/Reverse_order_of_lines
vnoremap <expr> \r edit#reverse_lines_expr()
nnoremap <expr> \r edit#reverse_lines_expr()
vnoremap <expr> \u edit#sort_lines_expr('u')
nnoremap <expr> \u edit#sort_lines_expr('u')
vnoremap <expr> \U edit#sort_lines_expr('ui')
nnoremap <expr> \U edit#sort_lines_expr('ui')

" Retab lines and remove trailing whitespace
" NOTE: Here define g:regex variables analogous to 'g:surround' and 'g:snippet'
" NOTE: Undo goes to first changed line: https://stackoverflow.com/a/52308371/4970632
for s:mode in ['n', 'v'] | exe s:mode . 'map \w \t' | endfor  " ambiguous maps
let g:sub_trail = ['Removed trailing spaces', '\s\+\ze$', '']  " analogous to surround
let g:sub_tabs = ['Translated tabs', '\t', {-> repeat(' ', &l:tabstop)}]
nnoremap <expr> \t call('edit#search_replace_expr', g:sub_trail)
vnoremap <expr> \t call('edit#search_replace_expr', g:sub_trail)
nnoremap <expr> \<Tab> call('edit#search_replace_expr', g:sub_tabs)
vnoremap <expr> \<Tab> call('edit#search_replace_expr', g:sub_tabs)

" Replace consecutive spaces on current line with
" one space only if they're not part of indentation
let g:sub_ssqueeze = ['Squeezed consecutive spaces', '\S\@<=\(^ \+\)\@<! \{2,}', ' ']
let g:sub_sstrip = ['Stripped spaces', '\S\@<=\(^ \+\)\@<! \+', '']
nnoremap <expr> \s call('edit#search_replace_expr', g:sub_ssqueeze)
nnoremap <expr> \S call('edit#search_replace_expr', g:sub_sstrip)
vnoremap <expr> \s call('edit#search_replace_expr', g:sub_ssqueeze)
vnoremap <expr> \S call('edit#search_replace_expr', g:sub_sstrip)

" Remove empty lines
" Replace consecutive newlines with single newline
let g:sub_esqueeze = ['Squeezed consecutive empty lines', '\(\n\s*\n\)\(\s*\n\)\+', '\1']
let g:sub_estrip = ['Stripped empty lines', '^\s*$\n', '']
nnoremap <expr> \e call('edit#search_replace_expr', g:sub_esqueeze)
vnoremap <expr> \e call('edit#search_replace_expr', g:sub_esqueeze)
nnoremap <expr> \E call('edit#search_replace_expr', g:sub_estrip)
vnoremap <expr> \E call('edit#search_replace_expr', g:sub_estrip)

" Delete first-level and second-level commented text
" Critical to put in same group since these change the line count
let g:sub_comments = [
  \ 'Removed comments', 'Comment', {->
    \ '\(^\s*' . comment#get_regex() . '.\+$\n\|\s\+' . comment#get_regex() . '.\+$\)'
  \ }, '']
let g:sub_dcomments = [
  \ 'Removed second-level comments', 'Comment', {->
    \ '\(^\s*' . comment#get_regex() . '\s*' . comment#get_regex()
    \ . '.\+$\n\|\s\+' . comment#get_regex() . '\s*' . comment#get_regex() . '.\+$\)'
  \ }, '']
nnoremap <expr> \c call('edit#search_replace_expr', g:sub_comments)
vnoremap <expr> \c call('edit#search_replace_expr', g:sub_comments)
nnoremap <expr> \C call('edit#search_replace_expr', g:sub_dcomments)
vnoremap <expr> \C call('edit#search_replace_expr', g:sub_dcomments)

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
nnoremap <expr> \x call('edit#search_replace_expr', g:sub_bibtex)
vnoremap <expr> \x call('edit#search_replace_expr', g:sub_bibtex)
nnoremap <expr> \X call('edit#search_replace_expr', g:sub_dbibtex)
vnoremap <expr> \X call('edit#search_replace_expr', g:sub_dbibtex)

" Fix unicode quotes and dashes, trailing dashes due to a pdf copy
" Underscore is easiest one to switch if using that Karabiner map
let g:sub_breaks = ['Converted dashed word breaks', '\(\w\)[-–]\s\+', '\1']
let g:sub_dashes = ['Converted unicode em dashes', '–', '--']
let g:sub_dsingle = ['Converted unicode single quotes', '‘', '`', '’', "'"]
let g:sub_ddouble = ['Converted unicode double quotes', '“', '``', '”', "''"]
nnoremap <expr> \_ call('edit#search_replace_expr', g:sub_breaks)
vnoremap <expr> \_ call('edit#search_replace_expr', g:sub_breaks)
nnoremap <expr> \- call('edit#search_replace_expr', g:sub_dashes)
vnoremap <expr> \- call('edit#search_replace_expr', g:sub_dashes)
nnoremap <expr> \' call('edit#search_replace_expr', g:sub_dsingle)
vnoremap <expr> \' call('edit#search_replace_expr', g:sub_dsingle)
nnoremap <expr> \" call('edit#search_replace_expr', g:sub_ddouble)
vnoremap <expr> \" call('edit#search_replace_expr', g:sub_ddouble)

"-----------------------------------------------------------------------------"
" External plugins {{{1
"-----------------------------------------------------------------------------"
" Initialize plugin manager {{{2
" NOTE: Ad hoc enable LSP below for debugging. Can also use switch#lsp()
" NOTE: Auto skip installing added to s:forks below if possible.
" NOTE: See https://vi.stackexchange.com/q/388/8084 for a comparison of plugin managers.
" Currently use junegunn/vim-plug but could switch to Shougo/dein.vim which was derived
" from Shougo/neobundle.vim which was based on vundle. Just a bit faster.
call plug#begin('~/.vim/plugged')
let s:forks = ['vim-syntaxMarkerFold']  " previous attempt
let s:enable_ddc = 1  " popup completion
let s:enable_lsp = 1  " lsp integration
let g:filetype_m = 'matlab'  " default .m filetype
let g:filetype_f = 'fortran'  " default .f filetype
let g:filetype_inc = 'fortran'  " default .inc filetype
let g:filetype_cfg = 'dosini'  " default .cfg filetype
let g:filetype_cls = 'tex'  " default .cls filetype

" Helper function for downloaded plugins
" NOTE: This allows adding to s:forks above without changing anything else
function! s:get_plug(regex) abort
  return filter(split(&runtimepath, ','), "v:val =~# '" . a:regex . "'")
endfunction
function! s:plug(plug, ...) abort
  let name = split(a:plug, '/')[-1]
  let path = expand('~/forks/' . name)
  let idx = index(s:forks, name)
  if idx < 0  " fork not requested
    call call('plug#', [a:plug] + a:000)
  elseif isdirectory(path)
    call s:push(0, path)
  else
    redraw | echohl WarningMsg
    echom 'Warning: Fork ' . string(name) . ' not found.'
    echohl None
  endif
endfunction
command! -nargs=1 GetPlug echom 'Plugins: ' . join(s:get_plug(<q-args>), ', ')

" Helper function for pushing user-specific plugins
" See: https://github.com/junegunn/vim-plug/issues/32
function! s:has_plug(key) abort
  return &runtimepath =~# '/' . a:key . '\>'
endfunction
function! s:push(auto, arg) abort
  if a:arg =~# '/' || isdirectory(a:arg)
    let path = fnamemodify(a:arg, ':p')
  else  " default location
    let path = expand('~/software/' . a:arg)
  endif
  let name = fnamemodify(path, ':t')
  let plug = 'lukelbd/' . name
  let item = escape(path, ' ~')
  if !a:auto && !isdirectory(path)
    redraw | echohl WarningMsg
    echom 'Warning: Plugin ' . string(name) . ' not found.'
    echohl None
  elseif a:auto && !isdirectory(path)
    return s:plug(plug)
  elseif &runtimepath !~# item  " remaining tildes
    exe 'set runtimepath^=' . item | exe 'set runtimepath+=' . item . '/after'
  endif
endfunction
command! -nargs=* AddPlug call s:push(0, <f-args>)

" Core utilities and integration {{{2
" Use bash 'vim-session' to start form existing .vimsession or start new session with
" input file file, or use 'vim' then ':so .vimsession' or ':Session' command.
" NOTE: Here mru can be used to replace current file in window with files from recent
" popup list. Useful e.g. if lsp or fugitive plugins accidentally replace buffer.
" See: https://github.com/junegunn/vim-peekaboo/issues/84
" call s:plug('thaerkh/vim-workspace')
" call s:plug('gioele/vim-autoswap')  " deals with swap files automatically; no longer use them so unnecessary
" call s:plug('xolox/vim-reload')  " easier to write custom reload function
" call s:plug('Asheq/close-buffers.vim')  " e.g. Bdelete hidden, Bdelete select
" call s:plug('artnez/vim-wipeout')  " utility overwritten with custom one
" call s:plug('tpope/vim-repeat')  " repeat utility (copied instead)
call s:plug('tpope/vim-obsession')  " sparse features on top of built-in session behavior
call s:plug('junegunn/vim-peekaboo')  " register display
call s:plug('mbbill/undotree')  " undo history display
call s:plug('yegappan/mru')  " most recent file
let g:peekaboo_prefix = "\1"  " disable mappings in lieu of 'nomap' option
let g:peekaboo_ins_prefix = "\1"  " disable mappings in lieu of 'nomap' option
let g:MRU_file = '~/.vim_mru_files'  " default (custom was ignored for some reason)

" Shared plugin frameworks (e.g. fzf)
" TODO: Use ctrl-a then enter or e.g. ctrl-q to auto-populate quickfix list with lines
" in window. Figure out setqflist() filename and line using dedicated parsing funcs
" NOTE: Use fzf#wrap to apply global settings, and never use fzf#run return value to
" get results (will result in weird hard-to-debug issues due to async calling).
" NOTE: 'Drop' opens selection in existing window, similar to switchbuf=useopen,usetab.
" However :Buffers still opens duplicate tabs even with fzf_buffers_jump=1.
" NOTE: Specify ctags command below and set default 'tags' above accordingly, however
" in this is only used if gutentags files unavailable (see tag.vim s:get_files)
" See: https://github.com/junegunn/fzf.vim/issues/185
" See: https://github.com/junegunn/fzf/issues/1577#issuecomment-492107554
" See: https://www.reddit.com/r/vim/comments/9504rz/denite_the_best_vim_pluggin/e3pbab0/
" call setqflist(map(copy(a:lines), '{''filename'': v:val }')) | copen | cc
" call s:plug('Shougo/pum.vim')  " pum completion mappings, but mine are nicer
" call s:plug('Shougo/unite.vim')  " first generation
" call s:plug('Shougo/denite.vim')  " second generation
" call s:plug('Shougo/ddu.vim')  " third generation
" call s:plug('Shougo/ddu-ui-filer.vim')  " successor to Shougo/vimfiler and Shougo/defx.nvim
" call s:plug('ctrlpvim/ctrlp.vim')  " replaced with fzf
" call s:plug('roosta/fzf-folds.vim')  " replaced with custom utility
call s:plug('~/.fzf')  " fzf installation location, will add helptags and runtimepath
call s:plug('junegunn/fzf.vim')  " pin to version supporting :Drop
let g:fzf_action = {'ctrl-m': 'Drop', 'ctrl-e': 'split', 'ctrl-r': 'vsplit' }  " have file search and grep open to existing window if possible
let g:fzf_buffers_jump = 1  " jump to existing window if already open
let g:fzf_history_dir = expand('~/.fzf-hist')  " navigate searches with ctrl-n, ctrl-p
let g:fzf_layout = {'down': '~33%'}  " for some reason ignored (version 0.29.0)
let g:fzf_require_dir = 0  " see lukelbd/fzf.vim completion-edits branch
let g:fzf_tags_command = 'ctags -R -f .vimtags ' . join(parse#get_ignores(0, 0, 1), ' ')

" Navigation and searching
" NOTE: The vim-tags @#&*/?! mappings auto-integrate with vim-indexed-search. Also
" disable colors here for increased speed.
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
" call s:plug('tpope/vim-unimpaired')  " bracket map navigation, no longer used
" call s:plug('kshenoy/vim-signature')  " mark signs, unneeded and abandoned
" call s:plug('vim-scripts/EnhancedJumps')  " jump list, unnecessary
" call s:plug('easymotion/vim-easymotion')  " extremely slow and overkill
" call s:plug('mhinz/vim-grepper')  " for ag/rg but seems like easymotion, too much
call s:plug('henrik/vim-indexed-search')
call s:plug('andymass/vim-matchup')
call s:plug('justinmk/vim-sneak')  " simple and clean
silent! unlet g:loaded_sneak_plugin
let g:matchup_mappings_enabled = 1  " enable default mappings
let g:indexed_search_mappings = 0  " note this also disables <Plug>(mappings)

" Errors and lsp servers {{{2
" Asynchronous linting engine settings
" NOTE: Test plugin works for every filetype (simliar to ale).
" NOTE: ALE plugin looks for all checkers in $PATH
" call plut#('scrooloose/syntastic')  " out of date: https://github.com/vim-syntastic/syntastic/issues/2319
" call s:plug('tweekmonster/impsort.vim') " conflicts with isort plugin, also had major issues
if has('python3') | call s:plug('fisadev/vim-isort') | endif
call s:plug('vim-test/vim-test')
call s:plug('dense-analysis/ale')
call s:plug('Chiel92/vim-autoformat')
call s:plug('tell-k/vim-autopep8')
call s:plug('psf/black')
let g:autoformat_autoindent = 0
let g:autoformat_retab = 0
let g:autoformat_remove_trailing_spaces = 0

" Language server settings
" NOTE: Here vim-lsp-ale sends diagnostics generated by vim-lsp to ale, does nothing
" when g:lsp_diagnostics_enabled = 0 and can cause :ALEReset to fail, so skip for now.
" In future should use let g:lsp_ale_auto_enable_linter = 0 and then restrict
" integration to particular filetypes by adding 'vim-lsp' to g:ale_linters lists.
" NOTE: Seems vim-lsp can both detect servers installed separately in $PATH with
" e.g. mamba install python-lsp-server (needed for jupyterlab-lsp) or install
" individually in ~/.local/share/vim-lsp-settings/servers/<server> using the
" vim-lsp-settings plugin commands :LspInstallServer and :LspUninstallServer
" (servers written in python are installed with pip inside 'venv' virtual environment
" subfolders). Most likely harmless if duplicate installations but try to avoid.
" call s:plug('natebosch/vim-lsc')  " alternative lsp client
" call s:plug('rhysd/vim-lsp-ale')  " send vim-lsp diagnostics to ale, skip for now
if s:enable_lsp
  call s:plug('prabirshrestha/vim-lsp')  " ddc-vim-lsp requirement
  call s:plug('mattn/vim-lsp-settings')  " auto vim-lsp settings
  call s:plug('rhysd/vim-healthcheck')  " plugin help
  let g:lsp_float_max_width = g:linelength  "  some reason results in wider windows
  let g:lsp_preview_max_width = g:linelength  "  some reason results in wider windows
  let g:lsp_preview_max_height = 2 * g:linelength
endif

" Insert completion engines {{{2
" NOTE: Autocomplete requires deno (install with mamba). Older verison requires pynvim
" WARNING: denops.vim frequently upgrades requirements to most recent vim
" distribution but conda-forge version is slower to update. Workaround by pinning
" to older commits: https://github.com/vim-denops/denops.vim/commits/main
" call s:plug('neoclide/coc.nvim")  " vscode inspired
" call s:plug('ervandew/supertab')  " oldschool, don't bother!
" call s:plug('ajh17/VimCompletesMe')  " no auto-popup feature
" call s:plug('hrsh7th/nvim-cmp')  " lua version
" call s:plug('Valloric/YouCompleteMe')  " broken, don't bother!
" call s:plug('prabirshrestha/asyncomplete.vim')  " alternative engine
" call s:plug('Shougo/neocomplcache.vim')  " first generation (no requirements)
" call s:plug('Shougo/neocomplete.vim')  " second generation (requires lua)
" call s:plug('Shougo/deoplete.nvim')  " third generation (requires pynvim)
" call s:plug('Shougo/neco-vim')  " deoplete dependency
" call s:plug('roxma/nvim-yarp')  " deoplete dependency
" call s:plug('roxma/vim-hug-neovim-rpc')  " deoplete dependency
" let g:neocomplete#enable_at_startup = 1  " needed inside plug#begin block
" let g:deoplete#enable_at_startup = 1  " needed inside plug#begin block
" call s:plug('vim-denops/denops.vim', {'commit': 'e641727'})  " ddc dependency
" call s:plug('Shougo/ddc.vim', {'commit': 'db28c7d'})  " fourth generation (requires deno)
" call s:plug('Shougo/ddc-ui-native', {'commit': 'cc29db3'})  " matching words near cursor
if s:enable_ddc
  call s:plug('matsui54/denops-popup-preview.vim')  " show previews during pmenu selection
  call s:plug('vim-denops/denops.vim')  " ddc dependency
  call s:plug('Shougo/ddc.vim', {'commit': '74743f5'})  " fourth generation (requires deno)
  call s:plug('Shougo/ddc-ui-native')  " matching words near cursor
endif

" Omnifunc sources not provided by engines
" See: https://github.com/Shougo/deoplete.nvim/wiki/Completion-Sources
" call s:plug('neovim/nvim-lspconfig')  " nvim-cmp source
" call s:plug('hrsh7th/cmp-nvim-lsp')  " nvim-cmp source
" call s:plug('hrsh7th/cmp-buffer')  " nvim-cmp source
" call s:plug('hrsh7th/cmp-path')  " nvim-cmp source
" call s:plug('hrsh7th/cmp-cmdline')  " nvim-cmp source
" call s:plug('deoplete-plugins/deoplete-jedi')  " old language-specific completion
" call s:plug('Shougo/neco-syntax')  " old language-specific completion
" call s:plug('Shougo/echodoc.vim')  " old language-specific completion
" call s:plug('Shougo/ddc-nvim-lsp')  " language server protocoal completion for neovim only
" call s:plug('Shougo/ddc-matcher_head')  " filter for heading match
" call s:plug('Shougo/ddc-sorter_rank')  " filter for sorting rank
" call s:plug('Shougo/ddc-source-omni')  " include &omnifunc results
" call s:plug('delphinus/ddc-ctags')  " completion using 'ctags' command
" call s:plug('akemrir/ddc-tags-exec')  " completion using tagfiles() lines
if s:enable_ddc
  call s:plug('tani/ddc-fuzzy')  " filter for fuzzy matching similar to fzf
  call s:plug('matsui54/ddc-buffer')  " matching words from buffer (as in neocomplete)
  call s:plug('shun/ddc-source-vim-lsp')  " language server protocol completion for vim 8+
  call s:plug('Shougo/ddc-source-around')  " matching words near cursor
  call s:plug('LumaKernel/ddc-source-file', {'commit': '7233513'})  " matching file names
endif

" Delimiters and snippets {{{2
" Use vim-surround not vim-sandwich because mappings are better and API is nicer.
" Should investigate snippet utils further but so far vim-succinct is fine.
" TODO: Investigate snippet further, but so far primitive vim-succinct snippets are fine
" See: https://github.com/wellle/targets.vim/issues/225
" See: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
" call s:plug('wellle/targets.vim')
" call s:plug('machakann/vim-sandwich')
" call s:plug('honza/vim-snippets')  " reference snippet files supplied to e.g. ultisnips
" call s:plug('LucHermitte/mu-template')  " file template and snippet engine mashup, not popular
" call s:plug('Shougo/neosnippet.vim')  " snippets consistent with ddc
" call s:plug('Shougo/neosnippet-snippets')  " standard snippet library
" call s:plug('Shougo/deoppet.nvim')  " next generation snippets (does not work in vim8)
" call s:plug('hrsh7th/vim-vsnip')  " snippets
" call s:plug('hrsh7th/vim-vsnip-integ')  " integration with ddc.vim
" call s:plug('SirVer/ultisnips')  " fancy snippet actions
call s:plug('tpope/vim-surround')
call s:plug('raimondi/delimitmate')
let g:surround_no_mappings = 1  " use vim-succinct mappings
let g:surround_no_insert_mappings = 1  " use vim-succinct mappings

" Text object definitions
" NOTE: Also use vim-succinct to auto-convert every vim-surround delimiter
" definition to 'inner'/'outer' delimiter inclusive/exclusive objects.
" call s:plug('machakann/vim-textobj-functioncall')  " use custom object instead
" call s:plug('vim-scripts/argtextobj.vim')  " use parameter instead
" call s:plug('kana/vim-textobj-fold')  " use custom oject insead
" call s:plug('bps/vim-textobj-python')  " use braceless 'm' instead
" call s:plug('beloglazov/vim-textobj-quotes')  " multi-line string, but not docstrings
" call s:plug('thalesmello/vim-textobj-multiline-str')  " multi-line string, adapted in python.vim
call s:plug('kana/vim-textobj-user')  " general requirement
call s:plug('kana/vim-textobj-line')  " entire line, object is 'l'
call s:plug('kana/vim-textobj-entire')  " entire file, object is 'e'
call s:plug('kana/vim-textobj-indent')  " indentation, object is 'i' or 'I' and 'a' includes empty lines
call s:plug('sgur/vim-textobj-parameter')  " argument, object is '='
call s:plug('glts/vim-textobj-comment')  " comment blocks, object is 'C' (see below)
call s:plug('tkhren/vim-textobj-numeral')  " numerals, e.g. 1.1234e-10
call s:plug('preservim/vim-textobj-sentence')  " sentence objects
let g:textobj_numeral_no_default_key_mappings = 1  " defined in vim-succinct block
let g:loaded_textobj_comment = 1  " avoid default mappings (see below)
let g:loaded_textobj_entire = 1  " avoid default mappings (see below)

" Folds indents and alignment {{{2
" General plugins for aligning and formatting under text
" NOTE: tcomment_vim is nice minimal extension of vim-commentary, include explicit
" commenting and uncommenting and 'blockwise' commenting with g>b and g<b
" See: https://www.reddit.com/r/vim/comments/g71wyq/delete_continuation_characters_when_joining_lines/
" call s:plug('scrooloose/nerdcommenter')  " too complex
" call s:plug('tpope/vim-commentary')  " too simple
" call s:plug('vim-scripts/Align')  " outdated align plugin
" call s:plug('tommcdo/vim-lion')  " alternative to easy-align
" call s:plug('godlygeek/tabular')  " difficult to use
" call s:plug('terryma/vim-multiple-cursors')  " article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" call s:plug('dkarter/bullets.vim')  " list numbering but completely fails
" call s:plug('stormherz/tablify')  " fancy ++ style tables, for now use == instead
" call s:plug('triglav/vim-visual-increment')  " superceded by vim-speeddating
" call s:plug('vim-scripts/Toggle')  " toggling stuff on/off (forked instead)
call s:plug('junegunn/vim-easy-align')  " align with motions, text objects, and ignores comments
call s:plug('AndrewRadev/splitjoin.vim')  " single-line multi-line transition hardly every needed
call s:plug('flwyd/vim-conjoin')  " join and remove line continuation characters
call s:plug('tomtom/tcomment_vim')  " comment motions
call s:plug('tpope/vim-characterize')  " print character (nicer version of 'ga')
call s:plug('tpope/vim-speeddating')  " dates and stuff
call s:plug('sk1418/HowMuch')  " calcuations
call s:plug('metakirby5/codi.vim')  " calculators
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

" File type folds and indentation
" NOTE: SimPylFold seems to have nice improvements, but while vim-tex-fold adds
" environment folding support, only native vim folds document header, which is
" sometimes useful. Will stick to default unless things change.
" NOTE: FastFold simply keeps &l:foldmethod = 'manual' most of time and updates on
" saves or fold commands instead of continuously-updating with the highlighting as
" vim tries to do. Works with both native vim syntax folding and expr overrides.
" NOTE: Indentline completely messes up search mode. Also requires changing Conceal
" group color, but doing that also messes up latex conceal backslashes. Instead use
" braceless.vim highlighting, appears only when cursor is there.
" call s:plug('pseewald/vim-anyfold')  " better indent folding (instead of vim syntax)
" call s:plug('matze/vim-tex-fold')  " folding tex environments (but no preamble)
" call s:plug('yggdroot/indentline')  " vertical indent line
" call s:plug('nathanaelkane/vim-indent-guides')  " alternative indent guide
" call s:plug('Jorengarenar/vim-syntaxMarkerFold')  " markers in syntax (now use fastfold method)
call s:plug('tweekmonster/braceless.vim')  " partial overlap with vim-textobj-indent, but these include header
call s:plug('pedrohdz/vim-yaml-folds')  " yaml folds
call s:plug('tmhedberg/SimpylFold')  " python folding
call s:plug('Konfekt/FastFold')  " speedup folding
let g:braceless_block_key = 'm'  " captures if, for, def, etc.
let g:braceless_generate_scripts = 1  " see :help, required since we active in ftplugin
let g:tex_fold_override_foldtext = 0  " disable foldtext() override
let g:SimpylFold_docstring_preview = 0  " disable foldtext() override

" Syntax and filetypes {{{2
" NOTE: Use :InlineEdit within blocks to open temporary buffer for editing. The buffer
" will have filetype-aware settings. See: https://github.com/AndrewRadev/inline_edit.vim
" NOTE: Here 'pythonic' vim-markdown folding prevents bug where folds auto-close after
" insert mode and ignores primary headers so entire document is not folded.
" See: https://vi.stackexchange.com/a/4892/8084
" See: https://github.com/preservim/vim-markdown/issues/516 and 489
" call s:plug('numirias/semshi', {'do': ':UpdateRemotePlugins'})  " neovim required
" call s:plug('MortenStabenau/matlab-vim')  " requires tmux installed
" call s:plug('daeyun/vim-matlab')  " alternative but project seems dead
" call s:plug('neoclide/jsonc.vim')  " vscode-style expanded json syntax, but overkill
" call s:plug('AndrewRadev/inline_edit.vim')  " inline syntax highlighting
" call s:plug('vim-python/python-syntax')  " nicer python syntax (copied instead)
call s:plug('vim-scripts/applescript.vim')  " applescript syntax support
call s:plug('andymass/vim-matlab')  " recently updated vim-matlab fork from matchup author
call s:plug('preservim/vim-markdown')  " see .vim/after/syntax.vim for kludge fix
call s:plug('chrisbra/csv.vim')  " csv syntax highlighting
call s:plug('Rykka/riv.vim')  " restructured text, syntax folds
call s:plug('tmux-plugins/vim-tmux')  " tmux syntax highlighting
call s:plug('anntzer/vim-cython')  " cython syntax highlighting
call s:plug('tpope/vim-liquid')  " liquid syntax highlighting
call s:plug('cespare/vim-toml')  " toml syntax highlighting
call s:plug('JuliaEditorSupport/julia-vim')  " julia syntax highlighting
call s:plug('flazz/vim-colorschemes')  " macvim colorschemes
call s:plug('fcpg/vim-fahrenheit')  " macvim colorschemes
call s:plug('KabbAmine/yowish.vim')  " macvim colorschemes
call s:plug('lilydjwg/colorizer')  " requires macvim or &t_Co == 256
let g:no_csv_maps = 1  " use custom maps
let g:csv_disable_fdt = 1  " use custom foldtext
let g:colorizer_nomap = 1  " use custom mapping
let g:colorizer_startup = 0  " too expensive to enable at startup
let g:latex_to_unicode_file_types = ['julia']  " julia-vim feature
let g:riv_python_rst_hl = 0  " highlight rest in python docstrings
let g:vim_markdown_conceal = 1  " conceal stuff
let g:vim_markdown_conceal_code_blocks = 0  " show code fences
let g:vim_markdown_fenced_languages = ['html', 'python']
let g:vim_markdown_folding_disabled = 1  " apply manually instead of with autocommands
let g:vim_markdown_folding_level = 1  " pythonic folding level
let g:vim_markdown_folding_style_pythonic = 1  " repair fold close issue
let g:vim_markdown_override_foldtext = 0  " also overwrite function (see common.vim)
let g:vim_markdown_math = 1 " turn on $$ math

" Filetype utilities
" TODO: Test vim-repl, seems to support all REPLs, but only :terminal is supported.
" TODO: Test vimcmdline, claims it can also run in tmux pane or 'terminal emulator'.
" NOTE: Now use https://github.com/msprev/fzf-bibtex with autoload/tex.vim integration
" NOTE: For better configuration see https://github.com/lervag/vimtex/issues/204
" call s:plug('sillybun/vim-repl')  " run arbitrary code snippets
" call s:plug('jalvesaq/vimcmdline')  " run arbitrary code snippets
" call s:plug('vim-scripts/Pydiction')  " changes completeopt and dictionary and stuff
" call s:plug('cjrh/vim-conda')  " for changing anconda VIRTUALENV but probably don't need it
" call s:plug('klen/python-mode')  " incompatible with jedi-vim and outdated
" call s:plug('ivanov/vim-ipython')  " replaced by jupyter-vim
" call s:plug('davidhalter/jedi-vim')  " use vim-lsp with mamba install python-lsp-server
" call s:plug('lukelbd/jupyter-vim', {'branch': 'buffer-local-highlighting'})  " temporary
" call s:plug('fs111/pydoc.vim')  " python docstring browser, now use custom utility
" call s:plug('rafaqz/citation.vim')  " unite.vim citation source
" call s:plug('twsh/unite-bibtex')  " unite.vim python 3 citation source
" call s:plug('lervag/vimtex')  " giant tex plugin
" let g:pydiction_location = expand('~') . '/.vim/plugged/Pydiction/complete-dict'  " for pydiction
" call s:plug('Vimjas/vim-python-pep8-indent')  " pep8 style indentexpr, seems to respect black
" call s:plug('jeetsukumaran/vim-python-indent-black')  " black style indentexpr (copied instead)
call s:plug('heavenshell/vim-pydocstring')  " automatic docstring templates
call s:plug('goerz/jupytext.vim')  " edit ipython notebooks
call s:plug('jupyter-vim/jupyter-vim')  " pair with jupyter consoles, support %% highlighting
call s:plug('quick-lint/quick-lint-js', {'rtp': 'plugin/vim/quick-lint-js.vim'})  " quick linting
let g:pydocstring_formatter = 'numpy'  " default is google so switch to numpy
let g:pydocstring_doq_path = '~/mambaforge/bin/doq'  " critical to mamba install
let g:jupyter_highlight_cells = 1  " required to prevent error in non-python vim
let g:jupyter_cell_separators = ['# %%', '# <codecell>']
let g:jupyter_mapkeys = 0
let g:jupytext_fmt = 'py:percent'
let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {'envs' : {'whitelist': ['enumerate', 'itemize', 'math']}}

" Shell and other utilities {{{2
" NOTE: Previously used vitality.vim to support FocusLost in iterm+tmux and avoid
" insert-mode-cursor in other panes. Now use tmux integration and key codes above.
" NOTE: Previously used ansi plugin to preserve colors in 'command --help' pages
" but now redirect colorized git help info to their corresponding man pages.
" See: https://shapeshed.com/vim-netrw/ (why to avoid nerdtree-type plugins)
" See: https://vi.stackexchange.com/a/14203/8084 (outdated ptmux sequences)
" See: https://www.reddit.com/r/vim/comments/24g8r8/italics_in_terminal_vim_and_tmux/
" See: https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it
" call s:plug('powerman/vim-plugin-AnsiEsc')  " colorize help pages
" call s:plug('sjl/vitality.vim')  " outdated (tmux+iterm passthrough sequences)
" call s:plug('vim-scripts/LargeFile')  " disable syntax highlighting for large files
" call s:plug('Shougo/vimshell.vim')  " first generation :terminal add-ons
" call s:plug('Shougo/deol.nvim')  " second generation :terminal add-ons
" call s:plug('jez/vim-superman')  " replaced with vim.vim and bashrc utilities
" call s:plug('scrooloose/nerdtree')  " unnecessary
" call s:plug('jistr/vim-nerdtree-tabs')  " unnecessary
" let g:vitality_always_assume_iterm = 1  " outdated (tmux+iterm passthrough sequences)
call s:plug('tpope/vim-eunuch')  " shell utils like chmod rename and move
call s:plug('tpope/vim-vinegar')  " netrw enhancements (acts on filetype netrw)
let g:LargeFile = 1  " megabyte limit

" Git related utilities
" NOTE: vim-flog and gv.vim are heavyweight and lightweight commit branch viewing
" plugins. Probably not necessary unless in giant project with tons of branches.
" See: https://github.com/rbong/vim-flog/issues/15
" See: https://vi.stackexchange.com/a/21801/8084
" call s:plug('rbong/vim-flog')  " view commit graphs with :Flog, filetype 'Flog' (?)
" call s:plug('junegunn/gv.vim')  " view commit graphs with :GV, filetype 'GV'
call s:plug('rhysd/conflict-marker.vim')  " highlight conflicts
call s:plug('airblade/vim-gitgutter')
call s:plug('tpope/vim-fugitive')
let g:conflict_marker_enable_mappings = 0
let g:fugitive_no_maps = 1  " disable cmap <C-r><C-g> and nmap y<C-g>

" Tag navigation utilities
" NOTE: This should work for both fzf ':Tags' (uses 'tags' since relies on tagfiles()
" for detection in autoload/vim.vim) and gutentags (uses only g:gutentags_ctags_tagfile
" for both detection and writing).
" call s:plug('xolox/vim-misc')  " dependency for easytags
" call s:plug('xolox/vim-easytags')  " kind of old and not that useful honestly
" call s:plug('preservim/tagbar')  " unnecessarily complex interface
call s:plug('yegappan/taglist')  " simpler interface plus mult-file support
call s:plug('ludovicchabant/vim-gutentags')  " slows things down without config
let g:gutentags_enabled = 1
" let g:gutentags_enabled = 0

" Custom plugins or forks and try to load locally if possible
" NOTE: This needs to come after or else (1) vim-succinct will not be able to use
" textobj#user#plugin, (2) the initial statusline will possibly be incomplete, and
" (3) cannot wrap indexed-search plugin with tags file.
call s:push(1, 'ddc-source-tags')
call s:push(1, 'vim-succinct')
call s:push(1, 'vim-tags')
call s:push(1, 'vim-statusline')
call s:push(1, 'vim-tabline')
call s:push(1, 'vim-scrollwrapped')
call s:push(1, 'vim-toggle')
let g:toggle_map = '\|'  " adjust toggle mapping (note this is repeatable)
let g:scrollwrapped_nomap = 1  " instead have advanced window#scroll_infer maps
let g:scrollwrapped_wrap_filetypes = s:info_filetypes + ['tex', 'text']
exe 'nnoremap + <C-a>' | exe 'nnoremap - <C-x>'
exe 'vnoremap + <C-a>' | exe 'vnoremap - <C-x>'
nnoremap <Leader>w <Cmd>WrapToggle<CR>
vnoremap <Leader>w <Cmd>WrapToggle<CR>

" End plugin manager. Also declares filetype plugin, syntax, and indent on
" Note every BufRead autocmd inside an ftdetect/filename.vim file is automatically
" made part of the 'filetypedetect' augroup (that's why it exists!).
call plug#end()
silent! delcommand SplitjoinJoin
silent! delcommand SplitjoinSplit

"-----------------------------------------------------------------------------"
" Plugin settings {{{1
"-----------------------------------------------------------------------------"
" Matches and delimiters {{{2
" NOTE: Here vim-tags searching integrates with indexed-search and vim-succinct
" surround delimiters integrate with matchup '%' keys.
if s:has_plug('vim-matchup')  " {{{
  let g:matchup_delim_nomids = 1  " skip e.g. 'else' during % jumps and text objects
  let g:matchup_delim_noskips = 1  " skip e.g. 'if' 'endif' in comments
  let g:matchup_matchparen_enabled = 1  " enable matchupt matching on startup
  let g:matchup_motion_keepjumps = 1  " preserve jumps when navigating
  let g:matchup_surround_enabled = 1  " enable 'ds%' 'cs%' mappings
  let g:matchup_transmute_enabled = 0  " issues with tex, use vim-succinct instead
  let g:matchup_text_obj_linewise_operators = ['y', 'd', 'c', 'v', 'V', "\<C-v>"]
endif  " }}}
if s:has_plug('vim-indexed-search')  " {{{
  let g:indexed_search_center = 0  " disable centered match jumping
  let g:indexed_search_colors = 0  " disable colors for speed
  let g:indexed_search_dont_move = 1  " irrelevant due to custom mappings
  let g:indexed_search_line_info = 1  " show first and last line indicators
  let g:indexed_search_max_lines = 100000  " increase from default of 3000 for log files
  let g:indexed_search_shortmess = 1  " shorter message
  let g:indexed_search_numbered_only = 1  " only show numbers
  let g:indexed_search_n_always_searches_forward = 1  " see also vim-sneak
endif  " }}}

" Navigation and delimiters
" NOTE: Tried easy motion but way too complicated / slows everything down
" See: https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
if s:has_plug('vim-succinct')  " {{{
  let g:succinct_delims = {
    \ 'e': '\n\r\n',
    \ 'f': '\1function: \1(\r)',
    \ 'A': '\1array: \1[\r]'
  \ }
  inoremap <F3> <Plug>PrevDelim
  inoremap <F4> <Plug>NextDelim
  let g:succinct_snippet_map = '<C-e>'  " default mapping
  let g:succinct_surround_map = '<C-s>'  " default mapping
  let g:delimitMate_expand_cr = 2  " expand even if non empty
  let g:delimitMate_expand_space = 1
  let g:delimitMate_jump_expansion = 1
  let g:delimitMate_excluded_regions = 'String'  " disabled inside by default
endif  " }}}
if s:has_plug('vim-sneak')  " {{{
  for s:key in ['f', 'F', 't', 'T']
    exe 'map ' . s:key . ' <Plug>Sneak_' . s:key
  endfor
  for s:mode in ['n', 'v'] | for s:key in ['s', 'S']
    exe s:mode . 'map ' . s:key . ' <Plug>Sneak_' . s:key
  endfor | endfor
  let g:sneak#label = 1  " show labels on matches for quicker jumping
  let g:sneak#s_next = 1  " press s/f/t repeatedly to jump matches until next motion
  let g:sneak#f_reset = 0  " keep f search separate from s
  let g:sneak#t_reset = 0  " keep t search separate from s
  let g:sneak#absolute_dir = 1  " same search direction no matter initial direction
  let g:sneak#use_ic_scs = 0  " search always case-sensitive, similar to '*' or popup
endif  " }}}

" Text object settings
" NOTE: Here use mnemonic 'v' for 'value' and 'C' for comment. The first avoids
" conflicts with ftplugin/tex.vim and the second with 'c' curly braces.
if s:has_plug('vim-textobj-user')  " {{{
  augroup textobj_setup
    au!
    au VimEnter * call textobj#sentence#init()
  augroup END
  omap an <Plug>(textobj-numeral-a)
  vmap an <Plug>(textobj-numeral-a)
  omap in <Plug>(textobj-numeral-i)
  vmap in <Plug>(textobj-numeral-i)
  omap a. <Plug>(textobj-comment-a)
  vmap a. <Plug>(textobj-comment-a)
  omap i. <Plug>(textobj-comment-i)
  vmap i. <Plug>(textobj-comment-i)
  let g:textobj#sentence#select = 's'  " smarter sentence selection FooBarBaz
  let g:textobj#sentence#move_p = '('  " smarter sentence navigation
  let g:textobj#sentence#move_n = ')'  " smarter sentence navigation
  let g:vim_textobj_parameter_mapping = 'k'  " i.e. 'keyword' or 'keyword argument'
  let s:textobj_alpha = {
    \ 'g': '\(\<\|[^0-9A-Za-z]\@<=[0-9A-Za-z]\@=\)\r\(\>\|[^0-9A-Za-z]\@=\)',
    \ 'h': '\(\<\|[0-9a-z]\@<=[^0-9a-z]\@=\)\r\(\>\|[0-9a-z]\@<=[^0-9a-z]\@=\)',
    \ 'v': '\(\k\|[*:.-]\)\@<!\(\k\|[*:.-]\)\@=\r\(\k\|[*:.-]\)\@<=\(\k\|[*:.-]\)\@!\s*',
  \ }  " 'ag' includes e.g. trailing underscore similar to 'a word'
  let s:textobj_entire = {
    \ 'select-a': 'aE',  'select-a-function': 'textobj#entire#select_a',
    \ 'select-i': 'iE',  'select-i-function': 'textobj#entire#select_i'
  \ }
  let s:textobj_comment = {
    \ 'select-i': 'iC', 'select-i-function': 'textobj#comment#select_i',
    \ 'select-a': 'aC', 'select-a-function': 'textobj#comment#select_big_a',
  \ }
  let s:textobj_fold = {
    \ 'select-i': 'iz', 'select-i-function': 'fold#get_fold_i',
    \ 'select-a': 'az', 'select-a-function': 'fold#get_fold_a',
  \ }
  let s:textobj_parent = {
    \ 'select-i': 'iZ', 'select-i-function': 'fold#get_parent_i',
    \ 'select-a': 'aZ', 'select-a-function': 'fold#get_parent_a',
  \ }
  call succinct#add_objects('alpha', s:textobj_alpha, 0, 1)  " do not escape
  call textobj#user#plugin('comment', {'-': s:textobj_comment})  " no <Plug> suffix
  call textobj#user#plugin('entire', {'-': s:textobj_entire})  " no <Plug> suffix
  call textobj#user#plugin('fold', {'-': s:textobj_fold})  " no <Plug> suffix
  call textobj#user#plugin('parent', {'-': s:textobj_fold})  " no <Plug> suffix
endif  " }}}

" Easy-align settings. Support case/esac block parentheses and seimcolons, chained
" && and || symbols, trailing comments. See file empty.txt for easy-align tests.
" NOTE: Use <Left> to stick delimiter to left instead of right and use * to align
" by all delimiters instead of the default of 1 delimiter.
" NOTE: Use :EasyAlign<Delim>is, id, or in for shallowest, deepest, or no indentation
" and use <Tab> in interactive mode to cycle through these.
if s:has_plug('vim-easy-align')  " {{{
  augroup easy_align_setup
    au!
    au BufEnter * let g:easy_align_delimiters['c']['pattern'] = '\s' . comment#get_regex()
  augroup END
  map z, <Plug>(EasyAlign)
  let g:easy_align_delimiters = {
    \ ';': {'pattern': ';\+'},
    \ ')': {'pattern': ')', 'stick_to_left': 1, 'left_margin': 0},
    \ '&': {'pattern': '\(&&\|||\)'},
    \ 'c': {'pattern': '\s#'},
  \ }
  let g:easy_align_bypass_fold = 0  " avoid conflict with fastfold
  let g:easy_align_delimiter_align = 'r'  " align varied-length delimiters
  let g:easy_align_ignore_groups = ['Comment', 'String']
endif  " }}}

" Comment toggle settings
" NOTE: This disable several maps but keeps many others. Remove unmap commands
" after restarting existing vim sessions.
if s:has_plug('tcomment_vim')  " {{{
  augroup comment_setup
    au!
    au FileType csv,text call comment#setup_table()
  augroup END
  for s:key1 in ['>', '<'] | for s:key2 in ['b', 'c', '>', '<>']
    silent! exe 'unmap g' . s:key1 . s:key2
  endfor | endfor
  for s:key1 in add(range(1, 9), '') | for s:key2 in ['', 'b', 'c']
    if !empty(s:key1 . s:key2) | silent! exe 'unmap g.' . s:key1 . s:key2 | endif
  endfor | endfor
  nnoremap z.. <Cmd>call comment#toggle_comment()<CR>
  nnoremap z>> <Cmd>call comment#toggle_comment(1)<CR>
  nnoremap z<< <Cmd>call comment#toggle_comment(0)<CR>
  inoremap <C-g>c <Space><C-\><C-o>v:TCommentInline mode=#<CR><Delete>
  inoremap <C-g>C <Space><C-\><C-o>:TCommentBlock mode=#<CR><Delete>
  let g:tcomment_opleader1 = 'z.'  " default is 'gc'
  let g:tcomment_mapleader1 = ''  " disables <C-_> insert mode maps
  let g:tcomment_mapleader2 = ''  " disables <Leader><Space> normal mode maps
  let g:tcomment_textobject_inlinecomment = ''  " default of 'ic' disables text object
  let g:tcomment_mapleader_uncomment_anyway = 'z<'
  let g:tcomment_mapleader_comment_anyway = 'z>'
endif  " }}}

" Tags and folds {{{2
" Buffer specific tag management
" WARNING: Critical to mamba install 'universal-ctags' instead of outdated 'ctags'
" or else will get warnings for non-existing kinds.
" NOTE: Use .ctags config to ignore kinds or include below to filter bracket jumps. See
" :ShowTable for translations. Try to use 'minor' for all single-line constructs.
" NOTE: Custom plugin is similar to :Btags, but does not create or manage tag files,
" instead creating tags whenever buffer is loaded and tracking tags continuously. Also
" note / and ? update jumplist but cannot override without keeping interactivity.
if s:has_plug('taglist')  " {{{
  augroup taglist_setup
    au!
    au BufEnter *__Tag_List__* call tag#setup_taglist() | call window#setup_panel()
  augroup END
  let g:Tlist_Compact_Format = 1
  let g:Tlist_Enable_Fold_Column = 1
  let g:Tlist_File_Fold_Auto_Close = 1
  let g:Tlist_Use_Right_Window = 0
  let g:Tlist_WinWidth = 40
  nnoremap z\ <Cmd>TlistToggle<CR>
  vnoremap z\ <Cmd>TlistToggle<CR>
endif  " }}}
if s:has_plug('vim-tags')  " {{{
  exe 'silent! unmap gyy' | exe 'silent! unmap zyy'
  command! -count -nargs=? TagToggle
    \ call call('switch#tags', <range> ? [<count>] : [<args>])
  command! -bang -nargs=* ShowTable let s:args = <bang>0 ? ['all'] : [<f-args>]
    \ | echo call('tags#table_kinds', s:args) . "\n" . call('tags#table_tags', s:args)
  nnoremap <Leader>t <Cmd>ShowTable<CR>
  nnoremap <Leader>T <Cmd>ShowTable!<CR>
  nnoremap <C-t> <Cmd>call tag#fzf_stack()<CR>
  nnoremap gy <Cmd>call tags#select_tag(0)<CR>
  nnoremap gY <Cmd>call tags#select_tag(2)<CR>
  nnoremap zy <Cmd>call tags#select_tag(1)<CR>
  nnoremap zY <Cmd>UpdateFolds \| UpdateFiles \| UpdateTags \| GutentagsUpdate<CR><Cmd>echom 'Updated buffer tags'<CR>
  let s:major = {'fortran': 'fsmp', 'python': 'fmc', 'vim': 'af', 'tex': 'csub'}
  let s:minor = {'fortran': 'ekltvEL', 'python': 'xviI', 'vim': 'vnC', 'tex': 'gioetBCN'}
  let g:tags_keep_jumps = 1  " default is zero
  let g:tags_bselect_map = 'gy'  " default is <Leader><Leader>
  let g:tags_select_map = 'gY'  " default is <Leader><Tab>
  let g:tags_cursor_map = '<CR>'  " default is <Leader><CR>
  let g:tags_major_kinds = s:major
  let g:tags_minor_kinds = s:minor
  let g:tags_prev_local_map = '[w'  " keyword jumping
  let g:tags_next_local_map = ']w'  " keyword jumping
  let g:tags_prev_global_map = '[W'
  let g:tags_next_global_map = ']W'
endif  " }}}

" Project-wide ctags management
" NOTE: Adding directories with '--exclude' flags fails in gutentags since it manually
" feeds files to 'ctags' executable which bypasses recursive exclude folder-name
" checking. Instead exclude folders using manual file generation executable.
if s:has_plug('vim-gutentags')  " {{{
  augroup tags_setup
    au!
    au User GutentagsUpdated call tag#update_files()
    au BufCreate,BufReadPost * call tag#update_files(expand('<afile>'))
  augroup END
  command! -bang -nargs=* -complete=file Tags call tag#fzf_tags(0, <bang>0, <f-args>)
  command! -bang -nargs=* -complete=file FTags call tag#fzf_tags(1, <bang>0, <f-args>)
  command! -bang -nargs=* -complete=file BTags call tag#fzf_btags(<bang>0, <q-args>)
  command! -nargs=* -complete=dir UpdateFiles call tag#update_files(<f-args>)
  command! -nargs=0 ShowCache call tag#show_cache()
  nnoremap gt <Cmd>BTags<CR>
  nnoremap gT <Cmd>Tags<CR>
  nnoremap zt <Cmd>FTags<CR>
  nnoremap zT <Cmd>UpdateFolds \| UpdateFiles \| UpdateTags! \| GutentagsUpdate!<CR><Cmd>echom 'Updated project tags'<CR>
  let g:gutentags_trace = 0  " toggle debug mode (also try :ShowIgnores)
  let g:gutentags_background_update = 1  " disable for debugging, printing updates
  let g:gutentags_ctags_auto_set_tags = 0  " tag#update_files() handles this instead
  let g:gutentags_ctags_executable = 'ctags'  " note this respects .ctags config
  let g:gutentags_ctags_exclude_wildignore = 1  " exclude &wildignore too
  let g:gutentags_ctags_exclude = []  " instead manage manually (see below)
  let g:gutentags_ctags_extra_args = parse#get_ignores(0, 1, 1)  " exclude and exclude-exception flags
  let g:gutentags_file_list_command = {
    \ 'default': 'find . ' . join(parse#get_ignores(0, 2, 2), ' ') . ' -print',
    \ 'markers': {'.git': 'git ls-files', '.hg': 'hg files'},
  \ }
  let g:gutentags_ctags_tagfile = '.vimtags'  " similar to .vimsession
  let g:gutentags_define_advanced_commands = 1  " debugging command
  let g:gutentags_generate_on_new = 1  " do not update tags when opening project file
  let g:gutentags_generate_on_write = 1  " update tags when file updated
  let g:gutentags_generate_on_missing = 1  " update tags when no vimtags file found
  let g:gutentags_generate_on_empty_buffer = 0  " do not update tags when opening vim
  let g:gutentags_project_root_finder = 'parse#get_root'
  " let g:gutentags_cache_dir = '~/.vim_tags_cache'  " alternative cache specification
  " let g:gutentags_ctags_tagfile = 'tags'  " used with cache dir
  " let g:gutentags_file_list_command = 'git ls-files'  " alternative to exclude ignores
endif  " }}}

" Vim syntax folding and fastfold settings
" WARNING: Converting syntax and expr folds to manual is very slow, so FastFold plugin
" applies autocommands that reset manual folds on FileType and BufRead or BufWinEnter
" after VimEnter has completed. Must define foldmethod-updating and fastfold-upating
" autocommands before and after respective VimEnter-defined FastFold autocommands.
" NOTE: Use custom autocommands. Native fastfold only changes foldmethod after opening
" new window via BufWinEnter (or BufRead if b:fastfold_fdm_hook = 1). Thus after
" starting sessions with multiple tabs, folds in other tabs will be 'slow' until
" a mapping or savehook is triggered. Workaround is to trigger fold#updaetfolds(0)
" on BufRead that runs FastFoldUpdate if foldmethod has not been changed to 'manual'.
" NOTE: Use custom mappings. zr reduces fold level by 1, zm folds more by 1 level,
" zR is big reduction (opens everything), zM is big increase (closes everything),
" zj and zk jump to start/end of *this* fold, [z and ]z jump to next/previous fold,
" zv is open folds enough to view cursor (useful when jumping lines or searching), and
" zn and zN fold toggle between no folds/previous folds without affecting foldlevel.
" See: https://www.reddit.com/r/vim/comments/c5g6d4/why_is_folding_so_slow/
" See: https://github.com/Konfekt/FastFold and https://github.com/tmhedberg/SimpylFold
if s:has_plug('FastFold')  " {{{
  function! s:fold_setup() abort
    augroup fold_setup
      au!
      au FileType,BufEnter,VimEnter * call fold#update_method()
      au TextChanged,TextChangedI * let b:fastfold_queued = 2
    augroup END
  endfunction
  function! s:fold_update() abort
    augroup fold_update
      au!
      au BufEnter * call fold#update_folds(0)
      au FileType * let b:fastfold_queued = 1 | call fold#update_folds(0, 1)
    augroup END
  endfunction
  function! s:fold_init(...) abort
    if a:0 && a:1  " autocommands preceding fastfold
      augroup fastfold_setup
        au! | au VimEnter * call fold#update_method() | call s:fold_setup()
      augroup END
    else  " autocommands following fastfold
      augroup fastfold_update
        au! | au VimEnter * call fold#update_folds(0, 1) | call s:fold_update()
      augroup END
    endif
  endfunction
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
  let g:sh_fold_enabled = 3
  let g:tex_fold_enabled = 1
  let g:vimsyn_folding = 'aflpP'
  let g:xml_syntax_folding = 1
  let g:zsh_fold_enable = 1
  let g:fastfold_minlines = 0
  let g:fastfold_force = 0  " enable only for syntax and expr folds
  let g:fastfold_fdmhook = 0  " disable foldmethod OptionSet hook
  let g:fastfold_savehook = 0  " disable default BufWritePost hook
  let g:fastfold_skip_filetypes = s:panel_filetypes
  let g:fastfold_fold_command_suffixes =  []
  let g:fastfold_fold_movement_commands = []
  call s:fold_init(1) | runtime plugin/fastfold.vim | call s:fold_init(0)
endif  " }}}

" Lsp server settings {{{2
" NOTE: The autocmd gives signature popups the same borders as hover popups, or else
" they have double border. See: https://github.com/prabirshrestha/vim-lsp/issues/594
" NOTE: Require kludge to get markdown syntax to work for some popups e.g. python dict()
" signature windows. See: https://github.com/prabirshrestha/vim-lsp/issues/1289
" NOTE: See 'jupyterlab-lsp/plugin.jupyterlab-settings' for examples. Results are
" shown in :CheckHelath. Try below when debugging (should disable :LspHover)
" let s:python_settings = {'plugins': {'jedi_hover': {'enabled': v:false} } }
" WARNING: Servers are 'pylsp', 'bash-language-server', 'vim-language-server'. Tried
" 'jedi-language-server' but had issues on linux, and tried 'texlab' but was slow. Note
" some cannot be installed with mamba and need vim-lsp-swettings :LspInstallServer.
if s:has_plug('vim-lsp-settings')  " {{{
  augroup lsp_setup
    au!
    au User lsp_float_opened call window#setup_preview()
    au FileType markdown.lsp-hover let b:lsp_do_conceal = 1 | setlocal conceallevel=2
  augroup END
  let s:tex_settings = {}
  let s:bash_settings = {}
  let s:julia_settings = {}
  let s:python_settings = {
    \ 'configurationSources': ['flake8'],
    \ 'plugins': {'jedi': {'auto_import_modules': ['numpy', 'pandas', 'matplotlib', 'proplot']}},
  \ }
  let g:lsp_settings = {
    \ 'pylsp': {'workspace_config': {'pylsp': s:python_settings}},
    \ 'texlab': {'workspace_config': {'texlab': s:tex_settings}},
    \ 'julia-language-server': {'workspace_config': {'julia-language-server': s:julia_settings}},
    \ 'bash-language-server': {'workspace_config': {'bash-language-server': s:bash_settings}},
  \ }
  let g:lsp_ale_auto_enable_linter = v:false  " default is true
  let g:lsp_diagnostics_enabled = 0  " use ale instead
  let g:lsp_diagnostics_highlights_insert_mode_enabled = 0  " annoying
  let g:lsp_document_code_action_signs_enabled = 0  " disable annoying signs
  let g:lsp_document_highlight_delay = 3000  " increased delay time
  let g:lsp_document_highlight_enabled = 0  " monitor, still really sucks
  let g:lsp_fold_enabled = 0  " not yet tested, requires 'foldlevel', 'foldlevelstart'
  let g:lsp_hover_conceal = 1  " enable markdown conceale
  let g:lsp_hover_ui = 'preview'  " either 'float' or 'preview'
  let g:lsp_inlay_hints_enabled = 0  " use inline hints
  let g:lsp_max_buffer_size = 2000000  " decrease from 5000000
  let g:lsp_preview_fixup_conceal = -1  " fix window size in terminal vim
  let g:lsp_preview_float = 1  " floating window
  let g:lsp_settings_global_settings_dir = '~/.vim_lsp_settings'  " move here next?
  let g:lsp_settings_servers_dir = '~/.vim_lsp_settings/servers'
  let g:lsp_signature_help_delay = 100  " milliseconds
  let g:lsp_signature_help_enabled = 1  " signature help
  let g:lsp_use_native_client = 1  " improve speed, use c for communicaiton
endif  " }}}

" Lsp integration commands and mappings
" See: https://github.com/python-lsp/python-lsp-server/issues/477
" NOTE: LspDefinition accepts <mods> and stays in buffer for local definitions so g<CR>
" behavior is close to 'Drop': https://github.com/prabirshrestha/vim-lsp/pull/776
" NOTE: Highlighting under keywords required for reference jumping with [d and ]d but
" monitor for updates: https://github.com/prabirshrestha/vim-lsp/issues/655
" WARNING: foldexpr=lsp#ui#vim#folding#foldexpr() foldtext=lsp#ui#vim#folding#foldtext()
" cause insert mode slowdowns even with g:lsp_fold_enabled = 0. Now use fast fold with
" native syntax foldmethod. Also tried tagfunc=lsp#tagfunc but now use LspDefinition
if s:has_plug('vim-lsp')  " {{{
  let g:_foldopen = 'call feedkeys(&foldopen =~# ''quickfix\|all'' ? "zv" : "", "n")'
  command! -nargs=? LspToggle call switch#lsp(<args>)
  command! -nargs=? ClearDoc call stack#clear_stack('doc')
  command! -nargs=? ListDoc call stack#print_stack('doc')
  command! -nargs=? PopDoc call stack#pop_stack('doc', <q-args>, 1)
  command! -nargs=? Doc call stack#push_stack('doc', 'python#doc_page', <f-args>)
  noremap [r <Cmd>LspPreviousReference<CR>
  noremap ]r <Cmd>LspNextReference<CR>
  nnoremap gr <Cmd>LspReferences<CR>
  nnoremap gR <Cmd>LspRename<CR>
  nnoremap zr <Cmd>LspDocumentSymbol<CR>
  nnoremap zR <Cmd>LspDocumentSymbolSearch<CR>
  nnoremap gd <Cmd>LspHover --ui=float<CR>
  nnoremap gD <Cmd>LspSignatureHelp<CR>
  nnoremap zd <Cmd>LspPeekDefinition<CR>
  nnoremap zD <Cmd>LspPeekDeclaration<CR>
  vnoremap gd <Cmd>LspHover --ui=float<CR>
  vnoremap gD <Cmd>LspSignatureHelp<CR>
  vnoremap zd <Cmd>LspPeekDefinition<CR>
  vnoremap zD <Cmd>LspPeekDeclaration<CR>
  nnoremap g<CR> <Cmd>call lsp#ui#vim#definition(0, g:_foldopen . ' \| tab')<CR>
  nnoremap z<CR> gd<Cmd>exe g:_foldopen<CR><Cmd>noh<CR>
  nnoremap <Leader>a <Cmd>LspInstallServer<CR>
  nnoremap <Leader>A <Cmd>LspUninstallServer<CR>
  nnoremap <Leader>f <Cmd>call edit#auto_format(0)<CR>
  nnoremap <Leader>F <Cmd>call edit#auto_format(1)<CR>
  nnoremap <Leader>d <Cmd>call stack#push_stack('doc', 'python#doc_page')<CR>
  nnoremap <Leader>D <Cmd>call python#fzf_doc()<cr>
  nnoremap <Leader>& <Cmd>call switch#lsp()<CR>
  nnoremap <Leader>% <Cmd>call window#show_health()<CR>
  nnoremap <Leader>^ <Cmd>call window#show_manager()<CR>
endif  " }}}

" Lsp completion settings (see :help ddc-options).
" Note underscore seems to indicate all sources (used for global filter options)
" and filetype-specific options added with ddc#custom#patch_filetype(filetype, ...).
" NOTE: Previously had installation permissions issues so used various '--allow'
" flags to support. See: https://github.com/Shougo/ddc.vim/issues/120
" NOTE: Try to limit memory to 50M. Engine flags are passed to '--v8-flags' flag
" as of deno 1.17.0? See: https://stackoverflow.com/a/72499787/4970632
" NOTE: Use 'converters': [], 'matches': ['matcher_head'], 'sorters': ['sorter_rank']
" to speed up or disable fuzzy completion. See: https://github.com/Shougo/ddc-ui-native
" and https://github.com/Shougo/ddc.vim#configuration. Also for general config
" inspiration see https://www.reddit.com/r/neovim/comments/sm2epa/comment/hvv13pe/.
" {'border': v:false, 'maxWidth': 80, 'maxHeight': 30}
" ['around', 'buffer', 'file', 'ctags', 'vim-lsp', 'vsnip']
" 'vsnip': {'mark': 'S', 'maxItems': 5}}
" 'ctags': {'mark': 'T', 'isVolatile': v:true, 'maxItems': 5}}
if s:has_plug('ddc.vim')  " {{{
  augroup ddc_setup
    au!
    au InsertEnter * if &l:filetype ==# 'vim' | setlocal iskeyword+=: | endif
    au InsertLeave * if &l:filetype ==# 'vim' | setlocal iskeyword-=: | endif
  augroup END
  command! -nargs=? DdcToggle call switch#ddc(<args>)
  nnoremap <Leader>* <Cmd>call switch#ddc()<CR>
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
  let g:ddc_sources = ['around', 'buffer', 'file', 'tags', 'vim-lsp']
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
    \   'file': {
    \     'mark': 'F',
    \     'maxItems': 5,
    \     'forceCompletionPattern': '\S/\S*',
    \   },
    \ 'tags': {
    \     'mark': 'T',
    \     'maxItems': 15,
    \     'isVolatile': v:true,
    \     'forceCompletionPattern': '\\.|:|->',
    \  },
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
endif  " }}}

" Asynchronous linting {{{2
" NOTE: bashate is equivalent to pep8, similar to prettier and beautify
" for javascript and html, also tried shfmt but not available.
" NOTE: black is not a linter (try :ALEInfo) but it is a 'fixer' and can be used
" with :ALEFix black. Or can use the black plugin and use :Black of course.
" NOTE: chktex is awful (e.g. raises errors for any command not followed
" by curly braces) so lacheck is best you are going to get.
" NOTE: eslint is awful (requires crazy dependencies) and could not get deno
" to highlight lines so use 'npm install --global quick-lint-js' instead.
" 'python': ['python', 'flake8', 'mypy'],  " need to improve config
" https://quick-lint-js.com/install/vim/npm-posix/
" https://github.com/Kuniwak/vint  # vim linter and format checker (pip install vim-vint)
" https://github.com/PyCQA/flake8  # python linter and format checker
" https://pypi.org/project/doc8/  # python format checker
" https://github.com/koalaman/shellcheck  # shell linter
" https://github.com/mvdan/sh  # shell format checker
" https://github.com/openstack/bashate  # shell format checker
" https://mypy.readthedocs.io/en/stable/introduction.html  # type annotation checker
" https://github.com/creativenull/dotfiles/blob/1c23790/config/nvim/init.vim#L481-L487
if s:has_plug('ale')  " {{{
  augroup ale_setup
    au!
    au BufRead ipython_*config.py,jupyter_*config.py let b:ale_enabled = 0
  augroup END
  command! -nargs=? AleToggle call switch#ale(<args>)
  nnoremap <Leader>x <Cmd>call window#show_list(0)<CR>
  nnoremap <Leader>X <Cmd>call window#show_list(1)<CR>
  nnoremap <Leader>@ <Cmd>call switch#ale()<CR>
  nnoremap <Leader># <Cmd>ALEInfo<CR>
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
    \ 'javascript': ['quick-lint-js'],
    \ 'typescript': ['quick-lint-js'],
    \ 'vim': ['vint'],
  \ }
  let g:ale_change_sign_column_color = 0  " do not change entire column
  let g:ale_completion_enabled = 0
  let g:ale_completion_autoimport = 0
  let g:ale_cursor_detail = 0
  let g:ale_disable_lsp = 'auto'  " permit lsp-powered linters e.g. quick-lint-js
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
  let g:ale_set_quickfix = 0  " require manual population
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
endif  " }}}

" Testing and formatting plugin settings
" Isort: https://github.com/fisadev/vim-isort
" Black: https://black.readthedocs.io/en/stable/integrations/editors.html?highlight=vim#vim
" Autopep8: https://github.com/tell-k/vim-autopep8 (includes several global variables)
" Autoformat: https://github.com/vim-autoformat/vim-autoformat (expands native 'autoformat' utilities)
if s:has_plug('black')  " {{{
  let g:black_linelength = g:linelength
  let g:black_skip_string_normalization = 1
endif  " }}}
if s:has_plug('vim-autopep8')  " {{{
  let g:autopep8_disable_show_diff = 1
  let g:autopep8_ignore = s:flake8_ignore
  let g:autopep8_max_line_length = g:linelength
endif  " }}}
if s:has_plug('vim-isort')  " {{{
  let g:vim_isort_python_version = 'python3'
  let g:vim_isort_config_overrides = {
    \ 'include_trailing_comma': 'true',
    \ 'force_grid_wrap': 0,
    \ 'multi_line_output': 3,
    \ 'line_length': g:linelength,
  \ }
endif  " }}}
if s:has_plug('vim-autoformat')  " {{{
  let g:formatdef_isort_black = '"isort '
    \ . '--trailing-comma '
    \ . '--force-grid-wrap 0 '
    \ . '--multi-line 3 '
    \ . '--line-length ' . g:linelength
    \ . ' - | black '
    \ . '--skip-string-normalization '
    \ . '--line-length ' . g:linelength . ' - "'
  let g:formatters_python = ['isort_black']  " defined above
  let g:formatters_fortran = ['fprettify']  " install with mamba
endif  " }}}
if s:has_plug('vim-test')  " {{{
  let test#strategy = 'iterm'
  let g:test#python#pytest#options = '--mpl --verbose'
  nnoremap <Leader>\ <Cmd>call utils#catch_errors('TestVisit')<CR>
  nnoremap <Leader>, <Cmd>call utils#catch_errors('TestLast')<CR>
  nnoremap <Leader>. <Cmd>call utils#catch_errors('TestNearest')<CR>
  nnoremap <Leader>< <Cmd>call utils#catch_errors('TestLast --mpl-generate')<CR>
  nnoremap <Leader>> <Cmd>call utils#catch_errors('TestNearest --mpl-generate')<CR>
  nnoremap <Leader>[ <Cmd>call utils#catch_errors('TestFile')<CR>
  nnoremap <Leader>] <Cmd>call utils#catch_errors('TestSuite')<CR>
  nnoremap <Leader>{ <Cmd>call utils#catch_errors('TestFile --mpl-generate')<CR>
  nnoremap <Leader>} <Cmd>call utils#catch_errors('TestSuite --mpl-generate')<CR>
endif  " }}}

" Git plugin settings {{{2
" Conflict highlight settings (warning: change below to 'BufEnter?')
" Shortcuts mirror zf/zF/zd/zD used for manual fold deletion and creation
" TODO: Figure out how to get highlighting closer to marks without clearing background.
" May need to define custom :syn matches that are not regions. Ask stack exchange.
" NOTE: Need to remove syntax regions here because they are added on per-filetype
" basis and they wipe out syntax highlighting between the conflict markers.
" See: https://vi.stackexchange.com/q/31623/8084
" See: https://github.com/rhysd/conflict-marker.vim
if s:has_plug('conflict-marker.vim')  " {{{
  augroup conflict_marker_setup
    au!
    au BufWinEnter * if conflict_marker#detect#markers() | syntax clear
      \ ConflictMarkerOurs ConflictMarkerTheirs ConflictMarkerCommonAncestorsHunk | endif
  augroup END
  command! -count=1 Cprev call git#next_conflict(<count>, 1)
  command! -count=1 Cnext call git#next_conflict(<count>, 0)
  call utils#repeat_map('', '[F', 'ConflictBackward', '<Cmd>exe v:count1 . "Cprev" \| ConflictMarkerThemselves<CR>')
  call utils#repeat_map('', ']F', 'ConflictForward', '<Cmd>exe v:count1 . "Cnext" \| ConflictMarkerThemselves<CR>')
  noremap [f <Cmd>exe v:count1 . 'Cprev'<CR>
  noremap ]f <Cmd>exe v:count1 . 'Cnext'<CR>
  nnoremap gf <Cmd>ConflictMarkerOurselves<CR>
  nnoremap gF <Cmd>ConflictMarkerThemselves<CR>
  nnoremap zf <Cmd>ConflictMarkerBoth<CR>
  nnoremap zF <Cmd>ConflictMarkerNone<CR>
  let g:conflict_marker_enable_detect = 1
  let g:conflict_marker_enable_highlight = 1
  let g:conflict_marker_enable_matchit = 1
  let g:conflict_marker_highlight_group = 'ConflictMarker'
  let g:conflict_marker_begin = '^<<<<<<< .*$'
  let g:conflict_marker_end = '^>>>>>>> .*$'
  let g:conflict_marker_separator = '^=======$'
  let g:conflict_marker_common_ancestors = '^||||||| .*$'
  highlight ConflictMarker cterm=inverse gui=inverse
endif  " }}}

" Fugitive settings
" NOTE: Fugitive overwrites commands for some reason so re-declare them
" whenever entering buffers and make them buffer-local (see git.vim).
" NOTE: All of the file-opening commands throughout fugitive funnel them through
" commands like Gedit, Gtabedit, etc. So can prevent duplicate tabs by simply
" overwriting this with custom tab-jumping :Drop command (see also git.vim).
if s:has_plug('vim-fugitive')  " {{{
  augroup fugitive_setup
    au!
    au BufWinEnter * call git#setup_commands()
  augroup END
  nnoremap gl <Cmd>BCommits<CR>
  nnoremap gL <Cmd>Commits<CR>
  nnoremap zL <Cmd>call git#run_map(0, 0, '', 'blame')<CR>
  nnoremap zll <Cmd>call git#run_map(2, 0, '', 'blame ')<CR>
  nnoremap <expr> zl git#run_map_expr(2, 0, '', 'blame ')
  vnoremap <expr> zl git#run_map_expr(2, 0, '', 'blame ')
  nnoremap <Leader>' <Cmd>call git#run_map(0, 0, '', '')<CR>
  nnoremap <Leader>" <Cmd>call git#run_map(0, 0, '', 'status')<CR>
  nnoremap <Leader>y <Cmd>call git#run_map(0, 0, '', 'commits')<CR>
  nnoremap <Leader>Y <Cmd>call git#run_map(0, 0, '', 'tree')<CR>
  nnoremap <Leader>u <Cmd>call git#run_map(0, 0, '', 'push origin')<CR>
  nnoremap <Leader>U <Cmd>call git#run_map(0, 0, '', 'pull origin')<CR>
  nnoremap <Leader>i <Cmd>call git#run_commit(0, 'oops')<CR>
  nnoremap <Leader>I <Cmd>call git#run_commit(1, 'oops')<CR>
  nnoremap <Leader>o <Cmd>call git#run_commit(0, 'commit')<CR>
  nnoremap <Leader>O <Cmd>call git#run_commit(1, 'commit')<CR>
  nnoremap <Leader>p <Cmd>call git#run_commit(0, 'stash push --include-untracked')<CR>
  nnoremap <Leader>P <Cmd>call git#run_commit(1, 'stash push --include-untracked')<CR>
  nnoremap <Leader>h <Cmd>call git#run_map(0, 0, '', 'diff --staged -- :/')<CR>
  nnoremap <Leader>H <Cmd>call git#run_map(0, 0, '', 'reset --quiet -- :/')<CR>
  nnoremap <Leader>j <Cmd>call git#run_map(0, 0, '', 'diff -- %')<CR>
  nnoremap <Leader>J <Cmd>call git#run_map(0, 0, '', 'stage -- %')<CR>
  nnoremap <Leader>k <Cmd>call git#run_map(0, 0, '', 'diff --staged -- %')<CR>
  nnoremap <Leader>K <Cmd>call git#run_map(0, 0, '', 'reset --quiet -- %')<CR>
  nnoremap <Leader>l <Cmd>call git#run_map(0, 0, '', 'diff -- :/')<CR>
  nnoremap <Leader>L <Cmd>call git#run_map(0, 0, '', 'stage -- :/')<CR>
  nnoremap <Leader>b <Cmd>call git#run_map(0, 0, '', 'branches')<CR>
  nnoremap <Leader>B <Cmd>call git#run_map(0, 0, '', 'switch -')<CR>
  let g:fugitive_legacy_commands = 1  " include deprecated :Git status to go with :Git
  let g:fugitive_dynamic_colors = 1  " fugitive has no HighlightRecent option
endif  " }}}

" Git gutter settings
" NOTE: Use custom command for toggling on/off. Older vim versions always show
" signcolumn if signs present, so GitGutterDisable will remove signcolumn.
" NOTE: Previously used text change autocomamnds to manually-refresh gitgutter since
" plugin only defines CursorHold but under-the-hood the invoked function actually
" *does* only fire when text is different. So leave default configuration alone.
" NOTE: Staging maps below were inspired by tcomment maps 'gc', 'gcc', 'etc.', and
" navigation maps ]g, ]G (navigate to hunks, or navigate and stage hunks) were inspired
" by spell maps ]s, ]S (navigate to spell error, or navigate and fix error).
if s:has_plug('vim-gitgutter')  " {{{
  command! -nargs=? GitGutterToggle call switch#gitgutter(<args>)
  command! -bang -range Hunks call git#stat_hunks(<range> ? <line1> : 0, <range> ? <line2> : 0, <bang>0)
  exe 'silent! unmap zgg'
  let g:gitgutter_async = 1  " ensure enabled
  let g:gitgutter_map_keys = 0  " disable all maps yo
  let g:gitgutter_max_signs = -1  " maximum number of signs
  let g:gitgutter_preview_win_floating = 1  " toggle preview window
  let g:gitgutter_floating_window_options = {'minwidth': g:linelength}
  let g:gitgutter_use_location_list = 0  " use for errors instead
  call utils#repeat_map('', '[G', 'HunkBackward', '<Cmd>call git#next_hunk(-v:count1, 1)<CR>')
  call utils#repeat_map('', ']G', 'HunkForward', '<Cmd>call git#next_hunk(v:count1, 1)<CR>')
  noremap [g <Cmd>call git#next_hunk(-v:count1, 0)<CR>
  noremap ]g <Cmd>call git#next_hunk(v:count1, 0)<CR>
  nnoremap <Leader>g <Cmd>call git#show_hunk()<CR>
  nnoremap <Leader>G <Cmd>call switch#gitgutter()<CR>
  nnoremap <expr> zh git#stat_hunks_expr()
  nnoremap <expr> gh git#stage_hunks_expr(1)
  nnoremap <expr> gH git#stage_hunks_expr(0)
  vnoremap <expr> zh git#stat_hunks_expr()
  vnoremap <expr> gh git#stage_hunks_expr(1)
  vnoremap <expr> gH git#stage_hunks_expr(0)
  nnoremap <nowait> zhh <Cmd>call git#stat_hunks(0, 0)<CR>
  nnoremap <nowait> ghh <Cmd>call git#stage_hunks(1)<CR>
  nnoremap <nowait> gHH <Cmd>call git#stage_hunks(0)<CR>
  nnoremap zg <Cmd>GitGutter \| echom 'Updated buffer hunks'<CR>
  nnoremap zG <Cmd>GitGutterAll \| echom 'Updated global hunks'<CR>
endif  " }}}

" Utility plugin settings {{{2
" Calculations and increments
" Julia usage bug: https://github.com/meta Kirby/codi.vim/issues/120
" Python history bug: https://github.com/metakirby5/codi.vim/issues/85
" Syncing bug (kludge is workaround): https://github.com/metakirby5/codi.vim/issues/106
" NOTE: Recent codi versions use lua-vim which is not provided by conda-forge version.
" However seems to run fine even without lua lines. So ignore errors with silent!
" NOTE: Speeddating increments selected item(s), and if selection includes empty lines
" then extends using step size from preceding lines or using a default step size.
" NOTE: Usage is HowMuch#HowMuch(isAppend, withEq, sum, engineType) where isAppend says
" whether to replace or append, withEq says whether to include equals sign, sum says
" whether to sum the numbers, and engine is one of 'py', 'bc', 'vim', 'auto'.
if s:has_plug('HowMuch')  " {{{
  nnoremap g++ :call HowMuch#HowMuch(0, 0, 1, 'py')<CR>
  nnoremap z++ :call HowMuch#HowMuch(1, 1, 1, 'py')<CR>
  nnoremap <expr> g+ utils#motion_func('HowMuch#HowMuch', [0, 0, 1, 'py'])
  nnoremap <expr> z+ utils#motion_func('HowMuch#HowMuch', [1, 1, 1, 'py'])
  vnoremap <expr> g+ utils#motion_func('HowMuch#HowMuch', [0, 0, 1, 'py'])
  vnoremap <expr> z+ utils#motion_func('HowMuch#HowMuch', [1, 1, 1, 'py'])
endif  " }}}
if s:has_plug('vim-speeddating')  " {{{
  nmap <silent> + <Plug>SpeedDatingUp:call repeat#set("\<Plug>SpeedDatingUp")<CR>
  nmap <silent> - <Plug>SpeedDatingDown:call repeat#set("\<Plug>SpeedDatingDown")<CR>
  vmap <silent> + <Plug>SpeedDatingUp:call repeat#set("\<Plug>SpeedDatingUp")<CR>
  vmap <silent> - <Plug>SpeedDatingDown:call repeat#set("\<Plug>SpeedDatingDown")<CR>
  nnoremap <Plug>SpeedDatingFallbackUp <C-a>
  nnoremap <Plug>SpeedDatingFallbackDown <C-x>
  vnoremap <Plug>SpeedDatingFallbackUp <C-a>
  vnoremap <Plug>SpeedDatingFallbackDown <C-x>
endif  " }}}
if s:has_plug('codi.vim')  " {{{
  augroup codi_setup
    au!
    au User CodiEnterPre call calc#setup_codi(1)
    au User CodiLeavePost call calc#setup_codi(0)
  augroup END
  command! -nargs=* CodiNew call calc#init_codi(<f-args>)
  nnoremap <Leader>+ <Cmd>CodiNew<CR>
  nnoremap <Leader>= <Cmd>silent! Codi!!<CR>
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
endif  " }}}

" Session saving and undo/register history
" WARNING: Critical to load vinegar before sinse setup_netrw() manipulates vinegar
" mappings, and critical to load enuch first so rename is not overwritten.
" TODO: Currently can only clear history with 'C' in active pane not externally. Need
" to submit PR for better command. See: https://github.com/mbbill/undotree/issues/158
" NOTE: Here peekaboo#peek() returns <Plug>(peekaboo) which invokes peekaboo#aboo()
" with <C-\><C-o> which moves cursor when called from end-of-line. Use below instead
" NOTE: For some reason cannot set g:peekaboo_ins_prefix = '' and simply have <C-r>
" trigger the mapping. See https://vi.stackexchange.com/q/5803/8084
" NOTE: Undotree normally triggers on BufEnter but may contribute to slowdowns. Use
" below to override built-in augroup before enabling buffer.
" NOTE: :Obsession .vimsession activates vim-obsession BufEnter and VimLeavePre
" autocommands and saved session files call let v:this_session=expand("<sfile>:p")
" (so that v:this_session is always set when initializing with vim -S .vimsession)
if s:has_plug('vim-obsession')  " {{{
  augroup session_setup
    au!
    au VimEnter * exe !empty(v:this_session) ? 'Obsession ' . v:this_session : ''
  augroup END
  command! -nargs=* -complete=customlist,vim#complete_sessions Session call vim#init_session(<q-args>)
  nnoremap <Leader>$ <Cmd>Session<CR>
endif  " }}}
if s:has_plug('vim-eunuch') || s:has_plug('vim-obsession')  " {{{
  silent! exe 'runtime plugin/eunuch.vim plugin/vinegar.vim'
  augroup netrw_setup
    au!
    au FileType netrw call shell#setup_netrw()
  augroup END
  command! -nargs=* -complete=file -bang Rename call file#rename(<q-args>, '<bang>')
  nnoremap <Tab>\ <Cmd>call shell#show_netrw('topleft vsplit', 1)<CR>
  nnoremap <Tab>= <Cmd>call shell#show_netrw('topleft vsplit', 0)<CR>
  nnoremap <Tab>- <Cmd>call shell#show_netrw('botright split', 1)<CR>
endif  " }}}
if s:has_plug('vim-peekaboo')  " {{{
  augroup peekaboo_setup
    au!
    au BufEnter * let b:peekaboo_on = 1
  augroup END
  let g:peekaboo_delay = -1  " WARNING: critical or else insert mapping fails
  let g:peekaboo_window = 'vertical topleft 30new'
  imap <F6> <Cmd>call peekaboo#peek(1, "\<C-r>", 0)<CR><Cmd>call peekaboo#aboo()<CR>
  cmap <F6> <Cmd>call peekaboo#peek(1, "\<C-r>", 0)<CR><Cmd>call peekaboo#aboo()<CR>
  nmap <expr> <F6> peekaboo#peek(1, '"', 0)
  vmap <expr> <F6> peekaboo#peek(1, '"', 0)
endif  " }}}
if s:has_plug('undotree')  " {{{
  function! Undotree_Augroup() abort  " autoload/undotree.vim s:undotree.Toggle()
    if !undotree#UndotreeIsVisible() | return | endif
    augroup Undotree
      au! | au InsertLeave,TextChanged * call undotree#UndotreeUpdate()
    augroup END
  endfunction
  function! Undotree_CustomMap() abort  " autoload/undotree.vim s:undotree.BindKey()
    call window#default_width(0)
    nmap <buffer> U <Plug>UndotreeRedo
    noremap <buffer> <nowait> u <C-u>
    noremap <buffer> <nowait> d <C-d>
  endfunc
  nnoremap g\ <Cmd>UndotreeToggle<CR><Cmd>call Undotree_Augroup()<CR>
  let g:undotree_DiffAutoOpen = 0
  let g:undotree_RelativeTimestamp = 0
  let g:undotree_SetFocusWhenToggle = 1
  let g:undotree_ShortIndicators = 1
  let g:undotree_SplitWidth = 30  " overridden above
  let g:undotree_WindowLayout = 1  " see :help undotree_WindowLayout
endif  " }}}

"-----------------------------------------------------------------------------"
" Syntax settings {{{1
"-----------------------------------------------------------------------------"
" Highlighting and colors {{{2
" Apply and list schemes from flazz/vim-colorschemes
" NOTE: This has to come after color schemes are loaded.
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

" General default colors
" Use main colors instead of light and dark colors instead of main
" NOTE: The bulk operations are in autoload/syntax.vim
augroup scheme_setup
  au!
  exe 'au ColorScheme ' . g:colors_default . ' so ~/.vimrc'
augroup END
if !has('gui_running') && get(g:, 'colors_name', 'default') ==? 'default'  " {{{
  noautocmd set background=dark  " standardize colors
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
endif  " }}}

" Syntax utilities {{{2
" Apply defaults and add runtime popup mappings
" NOTE: Here common.vim fails to apply mark fold overrides if called right away,
" perhaps race condition with syntax fold definitions. Use feedkeys() instead
" NOTE: Here syntax autocommands triggered by 'set syntax=', always after scripts
" loaded by $VIMRUNTIME/syntax/synload.vim 'au Syntax * call s:SynSet()' (this works
" by unletting b:current_syntax variable then finding the syntax and after scripts).
" NOTE: Here fix 'riv' bug where changing g:riv_python_rst_hl after startup has no
" effect. Grepped vim runtime and plugged, riv is literally only place where 'syntax'
" file employs 'loaded' variables with finish block (typically only used for plugins).
augroup syntax_setup
  au!
  au Syntax * unlet! b:af_py_loaded | unlet! b:af_rst_loaded
  au Syntax * unlet! b:common_syntax | exe 'runtime after/common.vim'
augroup END
command! -nargs=? ShowGroups call syntax#show_stack(<f-args>)
command! -nargs=0 ShowNames exe 'help highlight-groups' | exe 'normal! zt'
command! -nargs=0 ShowBases exe 'help group-name' | exe 'normal! zt'
command! -nargs=0 ShowColors call vim#show_runtime('syntax', 'colortest')
command! -nargs=0 ShowSyntax call vim#show_runtime('syntax')
command! -nargs=0 ShowPlugin call vim#show_runtime('ftplugin')
nnoremap <Leader>` <Cmd>ShowGroups<CR>
nnoremap <Leader>1 <Cmd>ShowPlugin<CR>
nnoremap <Leader>2 <Cmd>ShowSyntax<CR>
nnoremap <Leader>3 <Cmd>ShowNames<CR>
nnoremap <Leader>4 <Cmd>ShowBases<CR>
nnoremap <Leader>5 <Cmd>ShowColors<CR>

" Repair syntax highlighting
" NOTE: :Colorize is from hex-colorizer plugin. Expensive so disable at start
" NOTE: Here :set background triggers colorscheme autocmd so must avoid infinite loop
augroup mark_setup
  au!
  au VimEnter * call mark#init_marks()
augroup END
command! -bang -count=0 Syntax
  \ call syntax#sync_lines(<range> == 2 ? abs(<line2> - <line1>) : <count>, <bang>0)
nnoremap <Leader>e <Cmd>Syntax<CR>
nnoremap <Leader>6 <Cmd>Syntax 100<CR>
nnoremap <Leader>7 <Cmd>Syntax!<CR>
nnoremap <Leader>8 <Cmd>Colorize<CR>

" Scroll color schemes and toggle colorize
" NOTE: Here :Colorize is from colorizer.vim and :Colors from fzf.vim. Note coloring
" hex strings can cause massive slowdowns so disable by default.
command! -nargs=? -complete=color Scheme call syntax#next_scheme(<f-args>)
command! -count=1 Sprev call syntax#next_scheme(-<count>)
command! -count=1 Snext call syntax#next_scheme(<count>)
call utils#repeat_map('n', 'g{', 'Sprev', ':<C-u>Sprev<CR>')
call utils#repeat_map('n', 'g}', 'Snext', ':<C-u>Snext<CR>')
nnoremap <Leader>9 <Cmd>Colors<CR>
nnoremap <Leader>0 <Cmd>exe 'Scheme ' . g:colors_default<CR>

" Clear jumps for new tabs and to ignore stuff from vimrc and plugin files.
" TODO: Fix issue where gitgutter interrupts vim-succinct getchar()
" silent! exe 'au! gitgutter CursorHoldI'
" See: https://stackoverflow.com/a/2419692/4970632
" See: http://vim.1045645.n5.nabble.com/Clearing-Jumplist-td1152727.html
augroup jump_setup
  au!
  au BufReadPost * exe line('''"') && line('''"') <= line('$') ? 'keepjumps normal! g`"' : ''
  au VimEnter,BufWinEnter * if get(w:, 'clear_jumps', 1) | silent clearjumps | let w:clear_jumps = 0 | endif
augroup END
silent! exe 'runtime autoload/repeat.vim'
if !v:vim_did_enter | nohlsearch | endif
call syntax#update_highlights() | redraw!
nnoremap <Leader><Leader> <Cmd>echo system('curl https://icanhazdadjoke.com/')<CR>
