".vimrc
"###############################################################################
" A fancy vimrc that does all sorts of magical things.
" When to use after: https://vi.stackexchange.com/questions/12731/when-to-use-the-after-directory
" Note: So far don't organize stuff into *after* files (only distinction
" is that they should test b:did_ftplugin, b:current_syntax, et. cetera or
" g:loaded_<name>, et. cetera). Just smash indent/ftplugin files together
" and only some of the files in .vim/ftplugin have those lines.
" Note: use :vimgrep <pattern> % to quickfix list, then can browse them
" separately from the normal n/N searching. Also note location lists are
" window-local quickfix lists -- use lvimgrep, lgrep, etc.
" Note: vim should be brew install'd *without* your anaconda tools in the path,
" there should be an alias for 'brew' that fixes this.
" Note: vim install with Homebrew can only work with *python* installed with
" Homebrew -- currently default vim is compiled with python2 support, so you
" brew install python2, then use pip2 install <x> to make modules accessible
" to python vim backend.
" Note: Have iTerm map some ctrl+key combinations that would otherwise
" be impossible to the F1, F2 keys. Currently they are:
"     F1: 1b 4f 50 (Ctrl-,)
"     F2: 1b 4f 51 (Ctrl-.)
"     F3: 1b 4f 52 (Ctrl-i)
"     F4: 1b 4f 53 (Ctrl-m)
"     F5: 1b 5b 31 35 7e (shift-forward delete/shift-caps lock on macbook)
" Note: Currently use Karabiner 'map Ctrl-j/k/h/l to arrow keys' turned on
" so be aware that if you map those keys in Vim, should also map arrows.
" Note: Currently have Karabiner swap underscore and backslash (so that
" camelcase is way, way easier to type, and having to press shift for backslash
" is no big deal because only ever need it for regexes mostly)
"###############################################################################
"IMPORTANT STUFF and SETTINGS
"Says to always use the vim default where vi and vim differ; for example, if you
"put this too late, whichwrap will be reset
set nocompatible
set tabpagemax=100 "allow opening shit load of tabs at once
set redrawtime=5000 "sometimes takes a long time, let it happen
set shortmess=a "snappy messages, frmo the avoid press enter doc
set shiftround "round to multiple of shiftwidth
let mapleader="\<Space>"
set viminfo='100,:100,<100,@100,s10,f0 "commands, marks (e.g. jump history), exclude registers >10kB of text
set history=100 "search history
"See solution: https://unix.stackexchange.com/a/414395/112647
set slm= "disable 'select mode' slm, allow only visual mode for that stuff
set background=dark "standardize colors -- need to make sure background set to dark, and should be good to go
"Repeat previous command
set updatetime=1000 "used for CursorHold autocmds
set nobackup noswapfile noundofile "no more swap files; constantly hitting C-s so it's safe
set list listchars=nbsp:¬,tab:▸\ ,eol:↘,trail:·
"other characters: ▸, ·, ¬, ↳, ⤷, ⬎, ↘, ➝, ↦,⬊
"Older versions can't combine number with relativenumber
set number numberwidth=4
set relativenumber
"Default tabs
set tabstop=2
set shiftwidth=2
set softtabstop=2
"Detect features; variables are used to decide which plugins can be loaded
exe 'runtime autoload/repeat.vim'
let g:has_signs  = has("signs") "for git gutter and syntastic maybe
let g:has_ctags  = str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))
let g:has_nowait = (v:version>=704 || v:version==703 && has("patch1261"))
let g:has_repeat = exists("*repeat#set") "start checks for function existence
if !g:has_repeat
  echom "Warning: vim-repeat unavailable, some features will be unavailable."
  sleep 1
endif
"Tools for plugins
"This sets buffer filetypes to ignore when assigning 'tab titles' based on windows in that tab
let g:bufignore=['nerdtree', 'tagbar', 'codi', 'help'] "filetypes considered 'helpers'
"Format options; see :help fo-table to see what they mean -- want to continue comment lines
"and numbered lists
let g:formatoptions="lro"
exe 'setlocal formatoptions='.g:formatoptions
augroup formatopts
  au!
  au BufRead * exe 'setlocal formatoptions='.g:formatoptions
augroup END
"Escape repair, necessary when we allow h/l to change line number
"Note for whichwrap, <> = left/right insert, [] = left/right normal mode
"After escaping, always return to place where last exited
"Todo: This breaks delimitmate option to create newlines (along with insert
"mode map of enter below); figure out why and how to fix
set whichwrap=[,],<,>,h,l
augroup escapefix
  au!
  au InsertLeave * normal! `^
augroup END
"Always navigate by \w word, never have '*' look up keyword words
"See: https://superuser.com/a/1150645/506762
" augroup keywordfix
"   au!
"   au BufEnter * set iskeyword=45,65-90,95,97-122,48-57 "the same: -,a-z,_,A-Z,0-9
" augroup END
" set iskeyword=45,65-90,95,97-122,48-57

"###############################################################################
"CHANGE/ADD PROPERTIES/SHORTCUTS OF VERY COMMON ACTIONS
"Undo cheyenne maps -- not sure how to isolate/disable /etc/vimrc without
"disabling other stuff we want, e.g. syntax highlighting
let s:check=mapcheck("\<Esc>", 'n')
if s:check != '' "non-empty
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
"Misc stuff
noremap <CR>    <Nop>
noremap <Space> <Nop>
"The above 2 enter weird modes I don't understand...
noremap Q     <Nop>
noremap K     <Nop>
"Disable c-z and Z for exiting vim
noremap <C-z> <Nop>
noremap Z     <Nop>
"Disable tab changing with gt
noremap gt    <Nop>
noremap gT    <Nop>
"Disabling dumb extra scroll commands
noremap <C-p> <Nop>
noremap <C-n> <Nop>
"Turn off common things in normal mode
"also prevent Ctrl+c ringing the bell
nnoremap <C-c>       <Nop>
nnoremap <Delete>    <Nop>
nnoremap <Aackspace> <Nop>
"Disable arrow keys because you're better than that
"Cancelled because now my Mac remaps C-h/j/k/l to motion commands, yay
" for s:map in ['noremap', 'inoremap', 'cnoremap'] "disable typical navigation keys
"   for s:motion in ['<Up>', '<Down>', '<Home>', '<End>', '<Left>', '<Right>']
"     exe s:map.' '.s:motion.' <Nop>'
"   endfor
" endfor
"Navigate changelist with c-j/c-k; navigate jumplist with <C-h>/<C-l>
"Arrow keys are for macbook mapping
noremap <C-l>   <C-i>
noremap <C-h>   <C-o>
noremap <Right> <C-i>
noremap <Left>  <C-o>
"Forward <C-m> (mapped to F4 in iTerm) and backwards
noremap <C-n> g;
noremap <F4> g,
"Enable shortcut so that recordings are taken by just toggling 'q' on-off
"the escapes prevent a weird error where sometimes q triggers command-history window
noremap <silent> <expr> q b:recording ?
  \ 'q<Esc>:let b:recording=0<CR>' : 'qa<Esc>:let b:recording=1<CR>'
"Easy mark usage -- use '"' or '[1-8]"' to set some mark, use '9"' to delete it,
"and use ' or [1-8]' to jump to a mark.
noremap <expr> " (v:count==9 ? '<Esc>:RemoveHighlights<CR>' :
  \ 'm'.nr2char(97+v:count).':HighlightMark '.nr2char(97+v:count).'<CR>')
noremap <expr> ' "`".nr2char(97+v:count)
"New macro useage; almost always just use one at a time
"also easy to remembers; dot is 'repeat last command', comma is 'repeat last macro'
map @ <Nop>
noremap , @a
"Redo map to capital U; means we cannot 'undo line', but who cares
nnoremap U <C-r>
"Use - for throwaway register, pipeline for clipboard register
"Don't try anything fancy here, it's not worth it!
noremap <silent> - "_
noremap <silent> \| "*
"These keys aren't used currently, and are in a really good spot,
"so why not? Fits mnemonically that insert above is Shift+<key for insert below>
nnoremap <silent> ` :call append(line('.'),'')<CR>
nnoremap <silent> ~ :call append(line('.')-1,'')<CR>
"Now use sneak plugin; use cc for replace character, cC for whole line
nnoremap cc s
nnoremap cC cc
"Replace the currently highlighted text
"Note s/cc have identical outcomes in visual mode
vnoremap cc s
vnoremap cC s
"Swap with row above, and swap with row below; awesome mnemonic, right?
"use same syntax for c/s because almost *never* want to change up/down
"The command-based approach make sthe cursor much less jumpy
" noremap <silent> ck mzkddp`z
" noremap <silent> cj jmzkddp`zj
nnoremap <silent> ck k:let g:view=winsaveview() \| d \| call append(line('.'), getreg('"')[:-2]) 
      \ \| call winrestview(g:view)<CR>
nnoremap <silent> cj :let g:view=winsaveview() \| d \| call append(line('.'), getreg('"')[:-2]) 
      \ \| call winrestview(g:view)<CR>j
"Useful for typos
nnoremap <silent> cl xph
nnoremap <silent> ch Xp
"Mnemonic is 'cut line' at cursor; character under cursor (e.g. a space) will be deleted
"use ss/substitute instead of cl if you want to enter insert mode
nnoremap <silent> cL mzi<CR><Esc>`z
"Delete entire line, leave behind an empty line
"Has to be *normal* mode remaps, or will affect operator pending mode; for
"example if you type 'dd', there will be delay.
nnoremap dL 0d$
"Pressing enter on empty line preserves leading whitespace (HACKY)
"works because Vim doesn't remove spaces when text has been inserted
nnoremap o ox<BS>
nnoremap O Ox<BS>
"Don't save single-character deletions to any register
nnoremap x "_x
nnoremap X "_X
"Paste from the nth previously deleted or changed (c/C) text
"The initial escape cancels your count operator, otherwise multiple lines pasted
"Can't map 0p because then every time hit 0 to go to first line, get delay, so instead
"Use 9 for last yanked (unchanged) text, because why not
nnoremap <expr> p v:count==0 ? 'p' : ( v:count==9 ? '<Esc>"0p' : '<Esc>"'.v:count.'p' )
nnoremap <expr> P v:count==0 ? 'P' : ( v:count==9 ? '<Esc>"0P' : '<Esc>"'.v:count.'P' )
"Visual mode p/P to replace selected text with contents of register
vnoremap p "_dP
vnoremap P "_dP
"Yank, substitute, delete until end of current line
nnoremap Y y$
nnoremap D D
"Put last search into unnamed register
nnoremap <silent> y/ :let @"=@/<CR>
nnoremap <silent> y? :let @"=@/<CR>
"Better join behavior -- before 2J joined this line and next, now it
"means 'join the two lines below'; more intuitive
nnoremap <expr> J v:count>1  ? 'JJ' : 'J'
nnoremap <expr> K v:count==0 ? 'Jx' : repeat('Jx',v:count)
"Toggle highlighting
nnoremap <silent> <Leader>i :set hlsearch<CR>
nnoremap <silent> <Leader>o :noh<CR>
"Enable left mouse click in visual mode to extend selection; normally this is impossible
"Note we can't use `< and `> because those refer to start and end of last visual selection,
"while we actually want the place where we *last exited* visual mode, like '^ for insert mode
"TODO: Modify enter-visual mode maps! See: https://stackoverflow.com/a/15587011/4970632
"Want to be able to ***temporarily turn scrolloff to infinity*** when enter visual
"mode, to do that need to stop explicitly mapping vi/va stuff, and to do that need
"to work on text objects.
nnoremap v myv
nnoremap <silent> v/ hn:noh<CR>gn
nnoremap V myV
nnoremap <C-v> my<C-v>
vnoremap <CR> <C-c>
vnoremap <silent> <LeftMouse> <LeftMouse>mx`y:exe "normal! ".visualmode()<CR>`x

"###############################################################################
"INSERT MODE MAPS, IN CONTEXT OF POPUP MENU AND FOR 'ESCAPING' DELIMITER
"First add an autocmd for saving where last *entered* insert mode
augroup insertenter
  au!
  au InsertEnter * let b:insertenter=winsaveview()
augroup END
"Next popup manager; will count number of tabs in popup menu so our position is always known
augroup popuphelper
  au!
  au InsertLeave,BufEnter * let b:menupos=0
augroup END
function! s:tab_increase() "use this inside <expr> remaps
  let b:menupos+=1 | return ''
endfunction
function! s:tab_decrease()
  let b:menupos-=1 | return ''
endfunction
function! s:tab_reset()
  let b:menupos=0 | return ''
endfunction
"Commands that when pressed expand to the default complete menu options:
"Keystrokes that close popup menu (note that insertleave triggers tabreset)
"WARNING: The space remap and tab remap break insert mode abbreviations!
"Need to trigger them manually with <C-]> (see :help i_Ctrl-])
inoremap <expr> <BS>    !pumvisible() ? "\<BS>"          : <sid>tab_reset()."\<C-e>\<BS>"
inoremap <expr> <Space> !pumvisible() ? "\<C-]>\<Space>" : <sid>tab_reset()."\<C-]>\<Space>"
"Incrementing items in menu
inoremap <expr> <C-k>             !pumvisible() ? "\<Up>"   : <sid>tab_decrease()."\<C-p>"
inoremap <expr> <C-j>             !pumvisible() ? "\<Down>" : <sid>tab_increase()."\<C-n>"
inoremap <expr> <Up>              !pumvisible() ? "\<Up>"   : <sid>tab_decrease()."\<C-p>"
inoremap <expr> <Down>            !pumvisible() ? "\<Down>" : <sid>tab_increase()."\<C-n>"
inoremap <expr> <ScrollWheelDown> !pumvisible() ? "" : <sid>tab_increase()."\<C-n>"
inoremap <expr> <ScrollWheelUp>   !pumvisible() ? "" : <sid>tab_decrease()."\<C-p>"
"Tab always means 'accept', and choose default menu item if necessary
inoremap <expr> <Tab> !pumvisible() ? "\<C-]>\<Tab>" : b:menupos==0 ? "\<C-n>\<C-y>".<sid>tab_reset() : "\<C-y>".<sid>tab_reset()
"Enter means 'accept' only when we have explicitly scrolled down to something
"Also prevent annoying delay where otherwise, have to press enter twice when popup menu open
inoremap <expr> <CR>  !pumvisible() ? "\<C-]>\<CR>" : b:menupos==0 ? "\<C-e>\<C-]>\<CR>" : "\<C-y>".<sid>tab_reset()
"Miscelaneous map, undoes last change
inoremap <C-u> <Esc>u:call winrestview(b:insertenter)<CR>a
"Map to backspace by *beginning* of *WORDs*
"Use a function because don't want to trigger those annoying
"InsertLeave/InsertEnter autocommands, it's more flexible, and
"it preserves everything as a single 'undo' command
"Warning: Older versions of vim don't allow indexing strings or
"lists with variable integers -- have to use an eval.
function! s:word_back(key)
  let prefix = ''
  let cursor = col('.')-1 "index along text string
  exe 'let text = (cursor>0 ? getline(".")[:'.cursor.'-1] : "")'
  if match(text,'^\s*$')!=-1
    let prefix = repeat(a:key, 1+len(text)) "moves us to previous line; also note cursor can be on eol char
    let text   = getline(line('.')-1)
  endif
  let pos = match(text,'\S\+\s*$')
  if pos>=0
    return prefix.(repeat(a:key, len(text)-pos))
  else
    return prefix.''
  endif
endfunction
function! s:word_forward(key)
  let prefix = ''
  let cursor = col('.')-1 "index along text string
  let text = getline('.') "note below evaluates to empty e.g. if cursor on e.o.l.
  exe 'let text = getline(".")['.cursor.':]'
  if match(text,'^\S*\s*$')!=-1 "no more word beginnings
    let prefix = repeat(a:key, len(text)) "moves us to next line
    let text   = ' '.getline(line('.')+1) "the space lets us move to word starts on first column
  endif
  let pos  = match(text,'^\S*\s\+\zs')
  if pos>=0
    return prefix.(repeat(a:key, pos))
  else
    return prefix.''
  endif
endfunction
"New map for 'execute one normal mode command, then return to insert mode'
inoremap <F1> <C-o>
"Apply maps, and simply use row of keys above j/k et cetera
"Note pressing Ctrl-i in iTerm sends F3; see first few lines of vimrc
inoremap <expr> <F3>  <sid>word_back("\<Left>")
inoremap <expr> <C-o> <sid>word_forward("\<Right>")
inoremap <expr> <C-u> <sid>word_back("\<BS>")
inoremap <expr> <C-p> <sid>word_forward("\<Delete>")
"**Neat idea for insert mode remap**; put closing braces on next line
"adapted from: https://blog.nickpierson.name/colemak-vim/
" inoremap (<CR> (<CR>)<Esc>ko
" inoremap {<CR> {<CR>}<Esc>ko
" inoremap ({<CR> ({<CR>});<Esc>ko

"###############################################################################
"GLOBAL FUNCTIONS, FOR VIM SCRIPTING
"Test plugin status
function! PlugActive(key)
  return has_key(g:plugs, a:key) "change if (e.g.) switch plugin managers
  " echo filter(split(&rtp), ','), 'v:val =~? "tex")
endfunction
"Misc fuctions
function! In(list,item)
  return index(a:list,a:item)!=-1
endfunction
function! Reverse(text) "want this to be accessible!
  return join(reverse(split(a:text, '.\zs')), '')
endfunction
function! Strip(text)
  return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction
"Misc commands
command! Reverse g/^/m0
" command! CommaReverse s/\v([^, ]+)(\s*,\s*)([^, ]+)/\3\2\1/ "just works for two items
"Better grep, with limited regex translation
function! Grep(regex) "returns list of matches
  let regex=a:regex
  let regex=substitute(regex, '\(\\<\|\\>\)', '\\b', 'g') "not sure why double backslash needed
  let regex=substitute(regex, '\\s', "[ \t]",  'g')
  let regex=substitute(regex, '\\S', "[^ \t]", 'g')
  let result=split(system("grep '".regex."' ".@%.' 2>/dev/null'), "\n")
  echo result
  return result
endfunction
command! -nargs=1 Grep call Grep(<q-args>)
"Builtin comment string decoding
"Alternatively, b:NERDCommenterDelims['left']
function! Comment(...)
  "By default, return character that will never be matched?
  " let placeholder = (a:0 ? ' ' : '')
  let placeholder = (a:0 ? '|' : '')
  "Get comment char
  if &ft == '' || &commentstring == '' "the
    return placeholder
  elseif &commentstring =~ '%s'
    return Strip(split(&commentstring, '%s')[0])
  else
    return placeholder
  endif
endfunction
"Misc
augroup death
  au!
  au VimLeave * if v:dying | echo "\nAAAAaaaarrrggghhhh!!!\n" | endif "see v:dying info
augroup END

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
endif

"###############################################################################
"CHANGE COMMAND-LINE WINDOW SETTINGS i.e. q: q/ and q? mode
function! s:commandline_check()
  nnoremap <buffer> <silent> q :q<CR>
  silent! unmap <CR>
  silent! unmap <C-c>
  nnoremap  <buffer> <C-z> <C-c><CR>
  inoremap <buffer> <C-z> <C-c><CR>
  setlocal nonumber norelativenumber nolist laststatus=0
endfunction
augroup cmdwin
  au!
  au CmdwinEnter * call s:commandline_check()
  au CmdwinLeave * setlocal laststatus=2
augroup END
nnoremap <Leader>; :<Up><CR>
nnoremap <Leader>: q:
nnoremap <Leader>/ q/
nnoremap <Leader>? q?

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
"VIM-PLUG PLUGINS
"Don't load some plugins if not compatible
augroup plug
augroup END
let g:compatible_tagbar      = (g:has_ctags && (v:version>=704 || v:version==703 && has("patch1058")))
let g:compatible_codi        = (v:version>=704 && has('job') && has('channel'))
let g:compatible_workspace   = (v:version>=800) "needs Git 8.0, so not too useful
let g:compatible_neocomplete = has("lua") "try alternative completion library
if expand('$HOSTNAME') =~ 'cheyenne\?' | let g:compatible_neocomplete = 0 | endif "had annoying bugs with refactoring tools
call plug#begin('~/.vim/plugged')
"------------------------------------------------------------------------------"
"Indent line
"Warning: Right now *totally* fucks up search mode, and cursorline overlaps. So not good.
"Requires changing Conceal group color, but doing that also messes up latex conceal
"backslashes (which we need to stay transparent); so forget it probably
" Plug 'yggdroot/indentline'
"------------------------------------------------------------------------------"
"Color schemes
Plug 'flazz/vim-colorschemes'
Plug 'fcpg/vim-fahrenheit'
Plug 'KabbAmine/yowish.vim'
"------------------------------------------------------------------------------"
"Custom text objects (inner/outer selections)
"a,b, asdfas, adsfashh
Plug 'kana/vim-textobj-user'      "base
Plug 'kana/vim-textobj-indent'    "match indentation, object is 'i'
Plug 'kana/vim-textobj-entire'    "entire file, object is 'e'
Plug 'sgur/vim-textobj-parameter' "warning: this can hang
" Plug 'bps/vim-textobj-python' "not really ever used, just use indent objects
" Plug 'vim-scripts/argtextobj.vim' "arguments
" Plug 'machakann/vim-textobj-functioncall' "fucking sucks/doesn't work, fuck you
"------------------------------------------------------------------------------"
"Colors (don't need colors)
" Plug 'altercation/vim-colors-solarized'
"------------------------------------------------------------------------------"
"Superman man pages (not really used currently)
" Plug 'jez/vim-superman'
"------------------------------------------------------------------------------"
"Thesaurus; appears broken
" Plug 'beloglazov/vim-online-thesaurus'
"------------------------------------------------------------------------------"
"Make mappings repeatable; critical
"Now we edit our own version in .vim/plugin/autoload
" Plug 'tpope/vim-repeat'
"------------------------------------------------------------------------------"
"Automatic list numbering; actually it mysteriously fails so fuck that shit
" let g:bullets_enabled_file_types = ['vim', 'markdown', 'text', 'gitcommit', 'scratch']
" Plug 'dkarter/bullets.vim'
"------------------------------------------------------------------------------"
"Proper syntax highlighting for a few different things
"Note impsort sorts import statements, and highlights modules with an after/syntax script
Plug 'tmux-plugins/vim-tmux'
Plug 'plasticboy/vim-markdown'
Plug 'vim-scripts/applescript.vim'
Plug 'anntzer/vim-cython'
Plug 'tpope/vim-liquid'
" Plug 'tweekmonster/impsort.vim' "this fucking thing has an awful regex, breaks if you use comments, fuck that shit
" Plug 'hdima/python-syntax' "this failed for me; had to manually add syntax file; f-strings not highlighted, and other stuff!
"------------------------------------------------------------------------------"
"Easy tags, for easy integration
" Plug 'xolox/vim-misc' "depdency for easytags
" Plug 'xolox/vim-easytags' "kinda old and not that useful honestly
" Plug 'ludovicchabant/vim-gutentags' "slows shit down like crazy
"------------------------------------------------------------------------------"
"Colorize Hex strings
"Note this option is ***incompatible*** with iTerm minimum contrast above 0
"Actually tried with minimum contrast zero and colors *still* messed up; forget it
" Plug 'lilydjwg/colorizer'
"------------------------------------------------------------------------------"
"TeX utilities; better syntax highlighting, better indentation,
"and some useful remaps. Also zotero integration.
Plug 'Shougo/unite.vim'
Plug 'rafaqz/citation.vim'
" Plug 'twsh/unite-bibtex' "python 3 version
" Plug 'msprev/unite-bibtex' "python 2 version
" Plug 'lervag/vimtex'
" Plug 'chrisbra/vim-tex-indent'
"------------------------------------------------------------------------------"
"Julia support and syntax highlighting
Plug 'JuliaEditorSupport/julia-vim'
"------------------------------------------------------------------------------"
"Python wrappers
Plug 'vim-scripts/Pydiction' "just changes completeopt and dictionary and stuff
" Plug 'davidhalter/jedi-vim' "mostly autocomplete stuff
" Plug 'cjrh/vim-conda' "for changing anconda VIRTUALENV; probably don't need it
" Plug 'klen/python-mode' "incompatible with jedi-vim; also must make vim compiled with anaconda for this to work
" Plug 'ivanov/vim-ipython' "same problem as python-mode
"------------------------------------------------------------------------------"
"Folding and matching
if g:has_nowait | Plug 'tmhedberg/SimpylFold' | endif
let g:loaded_matchparen = 1
Plug 'Konfekt/FastFold'
Plug 'andymass/vim-matchup'
" let g:loaded_matchparen = 0 "alternative (previously required matchaddpos, no longer)
" Plug 'vim-scripts/matchit.zip'
"------------------------------------------------------------------------------"
"Files and directories
Plug 'scrooloose/nerdtree'
Plug '~/.fzf' "fzf installation location; will add helptags and runtimepath
Plug 'junegunn/fzf.vim' "this one depends on the main repo above; includes many other tools
" Plug 'vim-ctrlspace/vim-ctrlspace' "for navigating buffers and tabs and whatnot
" Plug 'ctrlpvim/ctrlp.vim' "forget that shit, fzf is way better yo
if g:compatible_tagbar | Plug 'majutsushi/tagbar' | endif
" Plug 'jistr/vim-nerdtree-tabs' "unnecessary
" Plug 'vim-scripts/EnhancedJumps'
"------------------------------------------------------------------------------"
"Commenting and syntax checking
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
"------------------------------------------------------------------------------"
"Sessions and swap files and reloading
"Mapped in my .bashrc vims to vim -S .vimsession and exiting vim saves the session there
"Also vim-obsession more compatible with older versions
"NOTE: Apparently obsession causes all folds to be closed
Plug 'tpope/vim-obsession'
" if g:compatible_workspace | Plug 'thaerkh/vim-workspace' | endif
" Plug 'gioele/vim-autoswap' "deals with swap files automatically; no longer use them so unnecessary
" Plug 'xolox/vim-reload' "better to write my own simple plugin
"------------------------------------------------------------------------------"
"Git wrappers and differencing tools
Plug 'tpope/vim-fugitive'
if g:has_signs | Plug 'airblade/vim-gitgutter' | endif
"------------------------------------------------------------------------------"
"Shell utilities, including Chmod and stuff
Plug 'tpope/vim-eunuch'
"------------------------------------------------------------------------------"
"Completion engines
" Plug 'Valloric/YouCompleteMe' "broken
" Plug 'ajh17/VimCompletesMe' "no auto-popup feature
" Plug 'lifepillar/vim-mucomplete' "broken, seriously, cannot get it to work, don't bother! is slow anyway.
" if g:compatible_neocomplete | Plug 'ervandew/supertab' | endif "haven't tried it
if g:compatible_neocomplete | Plug 'shougo/neocomplete.vim' | endif
"------------------------------------------------------------------------------"
"Simple stuff for enhancing delimiter management
Plug 'tpope/vim-surround'
Plug 'raimondi/delimitmate'
"------------------------------------------------------------------------------"
"Aligning things and stuff
"Alternative to tabular is: https://github.com/tommcdo/vim-lion
"But in defense tabular is *super* flexible
Plug 'godlygeek/tabular'
"------------------------------------------------------------------------------"
"Calculators and number stuff
"No longer use codi, because had endless problems with it, and this cool 'Numi'
"desktop calculator will suffice
Plug 'triglav/vim-visual-increment' "visual incrementing/decrementing
" Plug 'vim-scripts/Toggle' "toggling stuff on/off; modified this myself
" Plug 'sk1418/HowMuch' "adds stuff together in tables; took this over so i can override mappings
" if g:compatible_codi | Plug 'metakirby5/codi.vim' | endif
"------------------------------------------------------------------------------"
"Single line/multiline transition; make sure comes after surround
"Hardly ever need this
" Plug 'AndrewRadev/splitjoin.vim'
" let g:splitjoin_split_mapping = 'cS' | let g:splitjoin_join_mapping  = 'cJ'
"------------------------------------------------------------------------------"
"Multiple cursors is awesome
"Article against this idea: https://medium.com/@schtoeffel/you-don-t-need-more-than-one-cursor-in-vim-2c44117d51db
" Plug 'terryma/vim-multiple-cursors'
"------------------------------------------------------------------------------"
"Better motions
"Sneak plugin; see the link for helpful discussion:
"https://www.reddit.com/r/vim/comments/2ydw6t/large_plugins_vs_small_easymotion_vs_sneak/
Plug 'justinmk/vim-sneak'
"------------------------------------------------------------------------------"
"End of plugins
"The plug#end also declares filetype plugin, syntax, and indent on
"Note apparently every BufRead autocmd inside an ftdetect/filename.vim file
"is automatically made part of the 'filetypedetect' augroup; that's why it exists!
call plug#end()

"###############################################################################
"SESSION MANAGEMENT
"First, simple Obsession session management
"Also manually preserve last cursor location:
" Jump to mark '"' without changing the jumplist (:help g`)
" Mark '"' is the cursor position when last exiting the current buffer
augroup session
  au!
  if PlugActive("vim-obsession") "must manually preserve cursor position
    au BufReadPost * if line("'\"")>0 && line("'\"")<=line("$") | exe "normal! g`\"" | endif
    au VimEnter * Obsession .vimsession
  endif
  "Autosave
  let s:autosave="InsertLeave" | if exists("##TextChanged") | let s:autosave.=",TextChanged" | endif
  " exe "au ".s:autosave." * w"
augroup END
"Function to toggle autosave on and off
"Consider disabling
function! s:autosave_toggle(on)
  if a:on "in future consider using this to disable autosave for large files
    if exists('b:autosave_on') && b:autosave_on=1
      return "already on
    endif
    let b:autosave_on=1
    echom 'Enabling autosave.'
    augroup autosave
      au! * <buffer>
      let g:autosave="InsertLeave"
      if exists("##TextChanged") | let g:autosave.=",TextChanged" | endif
      exe "au ".g:autosave." <buffer> * w"
    augroup END
  else
    if !exists('b:autosave_on') || b:autosave_on=0
      return "already off
    endif
    let b:autosave_on=0
    echom 'Disabling autosave.'
    augroup autosave
      au! * <buffer>
    augroup END
  endif
endfunction
"Vim workspace settings
"Had some issues with this plugin
if PlugActive("thaerkh/vim-workspace") "cursor positions automatically saved
  let g:workspace_session_name = '.vimsession'
  let g:workspace_session_disable_on_args = 1 "enter vim (without args) to load previous sessions
  let g:workspace_persist_undo_history = 0    "don't need to save undo history
  let g:workspace_autosave_untrailspaces = 0  "sometimes we WANT trailing spaces!
  let g:workspace_autosave_ignore = ['help', 'rst', 'qf', 'diff', 'man']
endif
"Function for refreshing custom filetype-specific files and .vimrc
"If you want to refresh some random global plugin in ~/.vim/autolaod or ~/.vim/plugin
"then just source it with the 'execute' shortcut Ctrl-z
function! s:refresh() "refresh sesssion; sometimes ~/.vimrc settings are overridden by ftplugin stuff
  " so ~/.vimrc "have issues with 'cannot refresh refresh(), it is currently in use'
  filetype detect "if started with empty file, but now shebang makes filetype clear
  filetype plugin indent on
  let loaded = []
  let files = ['~/.vim/ftplugin/'.&ft.'.vim',       '~/.vim/syntax/'.&ft.'.vim',
             \ '~/.vim/after/ftplugin/'.&ft.'.vim', '~/.vim/after/syntax/'.&ft.'.vim']
  for file in files
    if !empty(glob(file))
      exe 'so '.file
      let loaded+=[file]
    endif
  endfor
  echom "Loaded ".join(map(['~/.vimrc']+loaded, 'fnamemodify(v:val,":~")[2:]'), ', ').'.'
endfunction
command! Refresh so ~/.vimrc | call <sid>refresh()
nnoremap <silent> <Leader>S :call <sid>refresh()<CR>
"Redraw screen
nnoremap <silent> <Leader>r :redraw!<CR>

"##############################################################################"
"DICTIONARY COMPLETION
"Add dictionary search
set complete-=k complete+=k " Add dictionary search (as per dictionary option)
"Make vim look inside ~/.vim/words; currently just ncl is there
au BufRead,BufNewFile * execute 'setlocal dict+=~/.vim/words/'.&ft.'.dic'

"##############################################################################"
"TEMPLATES
"***NOTE*** BufNewFile events don't work inside ftplugin, because by the time
"vim has reached that file, the BufNewFiel event is no longer valid!
"Prompt user to choose from a list of templates (located in ~/latex folder)
"when creating a new LaTeX file.
"See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
augroup templates
  au!
  au BufNewFile *.tex call <sid>tex_pick() | redraw!
augroup END
function! s:tex_pick()
  " echo 'Current templates available: '.join(names, ', ').'.'
  while 1
    let template=input('Template (tab to reveal options): ', '', 'customlist,TeXTemplates')
    if template=='blank' || template==''
      break
    elseif filereadable(expand('~/latex/'.template.'.tex'))
      execute "0r ~/latex/".template.'.tex'
      break
    endif
    echom " (invalid name)"
  endwhile
endfunction
function! TeXTemplates(A,L,P)
  let templates=split(globpath('~/latex/', '*.tex'),"\n")
  let names=[]
  for template in templates
    let name=fnamemodify(template, ":t:r")
    if name =~? '^'.a:A "if what user typed so far matches name
      call add(names, fnamemodify(template, ":t:r"))
    endif
  endfor
  return ['blank']+names
endfunction

"##############################################################################"
"ZOTERO and BibTeX INTEGRATION
"Requires pybtex and bibtexparser python modules, and unite.vim plugin
"Simply cannot get bibtex to work, ***always*** throws error gathering
"candidates message, so annoying
"This also allows buffer-specific bibtex sources
augroup citations
  au!
  au BufRead  *.tex,*.bib let b:citation_vim_bibtex_file='' | call <sid>citation_maps()
  au BufEnter *.tex,*.bib let g:citation_vim_bibtex_file=(exists('b:citation_vim_bibtex_file') ? b:citation_vim_bibtex_file : '')
augroup END
if PlugActive('unite.vim')
  "Set up fuzzy matching
  call unite#filters#sorter_default#use(['sorter_rank'])
  " call unite#filters#matcher_default#use(['matcher_fuzzy'])
  if PlugActive('unite-bibtex')
    "Settings and stuff
    let g:unite_data_directory='~/.unite'
    let g:unite_bibtex_cache_dir='~/.unite'
    let g:unite_bibtex_prefix = '\citet{'
    let g:unite_bibtex_postfix = '}'
    let g:unite_bibtex_separator = ', '
    let g:unite_bibtex_bib_files=['./empty_convert.bib']
  endif
  if PlugActive('citation.vim')
    "Possible data sources:
    " abstract,       author, collection, combined,    date, doi,
    " duplicate_keys, file,   isbn,       publication, key,  key_inner, language,
    " issue,          notes,  pages,      publisher,   tags, title,     type,
    " url,            volume, zotero_key
    "Helper functions
    function! s:citations_zotero()
      "Set up for zotero searching
      if g:citation_vim_mode!='zotero'
        echom "Deleting cache."
        call delete(expand(g:citation_vim_cache_path.'/citation_vim_cache'))
      endif
      let g:citation_vim_mode='zotero'
    endfunction
    function! s:citations_bibtex()
      "Select bibliography file to use
      "Provide user option to pick from multiple files
      "To *reset* bib name, use :let g:ref=''
      if g:citation_vim_mode=='zotero'
        echom "Deleting cache."
        call delete(expand(g:citation_vim_cache_path.'/citation_vim_cache'))
      endif
      if b:citation_vim_bibtex_file==''
        let b:citation_vim_bibtex_file=s:bibfile()
        let g:citation_vim_bibtex_file=b:citation_vim_bibtex_file
      endif
      let g:citation_vim_mode='bibtex'
    endfunction
    function! s:bibfile()
      "Select bibliography files from user-given list
      let cwd=expand('%:h') "head component of path, can be relative
      let b:refs=split(glob(cwd.'/*.bib'),"\n")
      if len(b:refs)==0
        echom 'Warning: No .bib files found in file directory.'
        return ''
      elseif len(b:refs)==1
        let ref=b:refs[0]
      else
        while 1
          let ref=input('Select bibliography (tab to reveal options): ', '', 'customlist,BibFiles')
          if In(b:refs,ref)
            break
          endif
          echom ' (invalid name)'
        endwhile
      endif
      return ref
    endfunction
    function! BibFiles(A,L,P)
      "List bibfiles, simple function
      let names=[]
      for ref in b:refs
        if ref =~? '^'.a:A "if what user typed so far matches name
          call add(names, ref)
        endif
      endfor
      return names
    endfunction
    command! -nargs=* Zotero call <sid>citations_zotero() | Unite <args>
    command! -nargs=* BibTeX call <sid>citations_bibtex() | Unite <args>
    command! BibFile call <sid>bibfile()
    "Another simple functino to toggle prefix name
    function! s:cite(...)
      if a:0 && a:1!=''
        let suffix=(a:1=='c' ? '' : a:1)
        let g:citation_vim_outer_prefix='\cite'.suffix.'{'
        let g:citation_vim_suffix='}'
      else
        let g:citation_vim_outer_prefix=''
        let g:citation_vim_suffix=''
      endif
    endfunction
    command! -nargs=? Cite call <sid>cite(<q-args>)
    "Universal settings
    let g:citation_vim_mode="zotero" "will always default to zotero
    let g:unite_data_directory='~/.unite'
    let g:citation_vim_cache_path='~/.unite'
    let g:citation_vim_outer_prefix='\cite{'
    let g:citation_vim_inner_prefix=''
    let g:citation_vim_suffix='}'
    let g:citation_vim_et_al_limit=3 "show et al if more than 2 authors
    let g:citation_vim_zotero_path="~/Zotero" "location of .sqlite file
    let g:citation_vim_zotero_version=5
    " let g:citation_vim_zotero_attachment_path="~/Google Drive" "not needed cause symlinks are there maybe, didn't actually change 'data directory'
    " let g:citation_vim_bibtex_file="./empty_convert.bib" "by default, make this your filename
    "Mappings
    function! s:citation_maps()
      "Zotero
      inoremap <buffer> <silent> <C-g>k <Esc>:Cite<CR>:Zotero -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-g>c <Esc>:Cite c<CR>:Zotero -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-g>t <Esc>:Cite t<CR>:Zotero -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-g>p <Esc>:Cite p<CR>:Zotero -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-g>n <Esc>:Cite num<CR>:Zotero -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      "BibTex lookup (will look for .bib file automatically)
      inoremap <buffer> <silent> <C-f>k <Esc>:Cite<CR>:BibTeX -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-f>c <Esc>:Cite c<CR>:BibTeX -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-f>t <Esc>:Cite t<CR>:BibTeX -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-f>p <Esc>:Cite p<CR>:BibTeX -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
      inoremap <buffer> <silent> <C-f>n <Esc>:Cite num<CR>:BibTeX -buffer-name=citation -start-insert -ignorecase -default-action=append citation/key<CR>
    endfunction
    " "Insert citation, view citation info, append information
    " nnoremap <silent> <C-n>c :<C-u>Unite -buffer-name=citation-start-insert -default-action=append citation/key<CR>
    " nnoremap <silent> <C-n>I :<C-u>Unite -input=<C-R><C-W> -default-action=preview -force-immediately citation/combined<CR>
    " nnoremap <silent> <C-n>A :<C-u>Unite -default-action=yank citation/title<CR>
    " "Open pdf, open file directory, open url
    " nnoremap <silent> <C-n>f :<C-u>Unite -input=<C-R><C-W> -default-action=file -force-immediately citation/file<CR>
    " nnoremap <silent> <C-n>d :<C-u>Unite -input=<C-R><C-W> -default-action=start -force-immediately citation/file<CR>
    " nnoremap <silent> <C-n>u :<C-u>Unite -input=<C-R><C-W> -default-action=start -force-immediately citation/url<CR>
    " "Search for word under cursor; search for words, input prompt
    " nnoremap <silent> <C-n>s :<C-u>Unite  -default-action=yank  citation/key:<C-R><C-W><CR>
    " nnoremap <silent> <C-n>S :<C-u>exec "Unite  -default-action=start citation/key:" . escape(input('Search Key : '),' ')<CR>
  endif
endif

"##############################################################################"
"SNIPPETS
"TODO: Add these

"###############################################################################
"GIT GUTTER AND FUGITIVE
"TODO: Note we had to overwrite the gitgutter autocmds with a file in 'after'.
augroup git
augroup END
if PlugActive("vim-gitgutter")
  "Create command for toggling on/off; old VIM versions always show signcolumn
  "if signs present (i.e. no signcolumn option), so GitGutterDisable will remove signcolumn.
  " call gitgutter#disable() | silent! set signcolumn=no
  "In newer versions, have to *also* set the signcolumn option.
  silent! set signcolumn=no "silent ignores errors if not option
  let g:gitgutter_map_keys=0 "disable all maps yo
  let g:gitgutter_enabled=0 "whether enabled at *startup*
  function! s:gitguttertoggle(...)
    "Either listen to input, turn on if switch not declared, or do opposite
    if a:0
      let toggle=a:1
    else
      let toggle=(exists('b:gitgutter_enabled') ? 1-b:gitgutter_enabled : 1)
    endif
    if toggle
      GitGutterEnable
      silent! set signcolumn=yes
      let b:gitgutter_enabled=1
    else
      GitGutterDisable
      silent! set signcolumn=no
      let b:gitgutter_enabled=0
    endif
  endfunction
  "Maps for toggling gitgutter on and off
  nnoremap <silent> go :call <sid>gitguttertoggle(1)<CR>
  nnoremap <silent> gO :call <sid>gitguttertoggle(0)<CR>
  nnoremap <silent> g. :call <sid>gitguttertoggle()<CR>
  "Maps for showing/disabling changes under cursor
  nnoremap <silent> gs :GitGutterPreviewHunk<CR>:wincmd j<CR>
  nnoremap <silent> gS :GitGutterUndoHunk<CR>
  "Navigating between hunks
  nnoremap <silent> gN :GitGutterPrevHunk<CR>
  nnoremap <silent> gn :GitGutterNextHunk<CR>
endif
"Next some fugitive command aliases
"Just want to eliminate that annoying fucking capital G
if PlugActive("vim-fugitive")
  for gcommand in ['Git', 'Gcd', 'Glcd', 'Gstatus', 'Gcommit', 'Gmerge', 'Gpull',
  \ 'Grebase', 'Gpush', 'Gfetch', 'Grename', 'Gdelete', 'Gremove', 'Gblame', 'Gbrowse',
  \ 'Ggrep', 'Glgrep', 'Glog', 'Gllog', 'Gedit', 'Gsplit', 'Gvsplit', 'Gtabedit', 'Gpedit',
  \ 'Gread', 'Gwrite', 'Gwq', 'Gdiff', 'Gsdiff', 'Gvdiff', 'Gmove']
    exe 'cnoreabbrev g'.gcommand[1:].' '.gcommand
  endfor
endif

"##############################################################################"
"VIM SNEAK
"Just configure the maps here
"Also disable highlighting when doing sneak operations, because
"want to same the use highlight group
augroup sneak
augroup END
if PlugActive("vim-sneak")
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
"MATHUP
if PlugActive("vim-matchup") "better matching, see github
  let g:matchup_matchparen_enabled = 1
  let g:matchup_transmute_enabled = 0 "breaks latex!
endif

"###############################################################################
"DELIMITMATE (auto-generate closing delimiters)
"Note: If enter is mapped delimitmate will turn off its auto expand
"enter mapping.
"Warning: My InsertLeave mapping to stop moving the cursor left also fucks
"up the enter map; consider overwriting function.
if PlugActive("delimitmate")
  "First filetype settings
  "Enable carat matching for filetypes where need tags (or keycode symbols)
  "Vim needs to disable matching ", or everything is super slow
  "Tex need | for verbatim environments; note you *cannot* do set matchpairs=xyz; breaks plugin
  "Markdown need backticks for code, and can maybe do LaTeX math
  augroup delimitmate
    au!
    au FileType vim,html,markdown let b:delimitMate_matchpairs="(:),{:},[:],<:>"
    au FileType vim let b:delimitMate_quotes = "'"
    au FileType tex let b:delimitMate_quotes = "$ |" | let b:delimitMate_matchpairs = "(:),{:},[:],`:'"
    au FileType markdown let b:delimitMate_quotes = "\" ' $ `"
  augroup END
  "Todo: Apparently delimitmate has its own jump command, should start using it.
  "Set up delimiter paris; delimitMate uses these by default
  "Can set global defaults along with buffer-specific alternatives
  let g:delimitMate_expand_space=1
  let g:delimitMate_expand_cr=2 "expand even if it is not empty!
  let g:delimitMate_jump_expansion=0
  let g:delimitMate_quotes="\" '"
  let g:delimitMate_matchpairs="(:),{:},[:]"
  let g:delimitMate_excluded_regions="String" "by default is disabled inside, don't want that
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
nnoremap <silent> ;. :call <sid>spelltoggle()<CR>
nnoremap <silent> ;o :call <sid>spelltoggle(1)<CR>
nnoremap <silent> ;O :call <sid>spelltoggle(0)<CR>
"Also toggle UK/US languages
nnoremap <silent> ;K :call <sid>langtoggle(0)<CR>
nnoremap <silent> ;k :call <sid>langtoggle(1)<CR>
"Spell maps
nnoremap <Plug>backwardspell :call <sid>spellchange('[')<CR>:call repeat#set("\<Plug>backwardspell")<CR>
nnoremap <Plug>forwardspell  :call <sid>spellchange(']')<CR>:call repeat#set("\<Plug>forwardspell")<CR>
nmap ;D <Plug>backwardspell
nmap ;d <Plug>forwardspell
"Bring up menu
nnoremap ;m z=
"Add/remove from dictionary
nnoremap ;a zg
nnoremap ;r zug
"Functions
function! s:spellchange(direction)
  let nospell=0
  if !&l:spell
    let nospell=1
    setlocal spell
  endif
  let winview=winsaveview()
  exe 'normal! '.(a:direction==']' ? 'bh' : 'el')
  exe 'normal! '.a:direction.'s'
  normal! 1z=
  call winrestview(winview)
  if nospell
    setlocal nospell
  endif
endfunction
function! s:spelltoggle(...)
  if a:0
    let toggle=a:1
  else
    let toggle=1-&l:spell
  endif
  if toggle
    setlocal spell
    nnoremap <buffer> ;n ]S
    nnoremap <buffer> ;N [S
  else
    setlocal nospell
    nnoremap <buffer> ;n <Nop>
    nnoremap <buffer> ;N <Nop>
  endif
endfunction
function! s:langtoggle(...)
  if a:0
    let uk=a:1
  else
    let uk=(&l:spelllang == 'en_gb' ? 0 : 1)
  endif
  if uk
    setlocal spelllang=en_gb
    echo 'Current language: UK english'
  else
    setlocal spelllang=en_us
    echo 'Current language: US english'
  endif
endfunction
"Thesaurus stuff
"Plugin appears broken
"Use e key cause it's not used yet
" if PlugActive("vim-online-thesaurus")
"   let g:online_thesaurus_map_keys = 0
"   inoremap <C-e> <Esc>:OnlineThesaurusCurrentWord<CR>
"   " help
" endif

"###############################################################################
"HELP WINDOW SETTINGS, and special settings for mini popup windows where we don't
"want to see line numbers or special characters a la :set list.
"Also enable quitting these windows with single 'q' press
augroup simple
  "Note rst is 'restructured text' and qf is 'quickfix'
  au!
  au BufEnter * let b:recording=0
  au FileType rst,qf,help,diff,man SimpleSetup 1
  au FileType gitcommit SimpleSetup 0
augroup END
"Next set the help-menu remaps
"The defalt 'fart' search= assignments are to avoid passing empty strings
"Todo: If you're an insane person could also generate autocompletion for these ones, but nah
nnoremap <Leader>h :vert help 
if PlugActive('fzf.vim')
  nnoremap <Leader>H :Help<CR>
endif
"--help info; pipe output into less for better interaction
nnoremap <silent> <expr> <Leader>m ':!clear; search='.input('Get help info: ').'; '
  \.'if [ -n $search ] && builtin help $search &>/dev/null; then builtin help $search 2>&1 \| less; '
  \.'elif $search --help &>/dev/null; then $search --help 2>&1 \| less; fi<CR>:redraw!<CR>'
"man pages use capital m
nnoremap <silent> <expr> <Leader>M ':!clear; search='.input('Get man info: ').'; '
  \.'if [ -n $search ] && command man $search &>/dev/null; then command man $search; fi<CR>:redraw!<CR>'
"The doc pages appear in rst files, so turn off extra chars for them
"Also the syntastic shows up as qf files so want extra stuff turned off there too
function! s:simplesetup(...)
  if len(tabpagebuflist())==1
    q "exit if only one left
  endif
  if (a:0 ? a:1 : 1) "don't save
    nnoremap <buffer> <C-s> <Nop>
  endif
  if &ft=="help"
    wincmd L "moves current window to be at far-right (wincmd executes Ctrl+W maps)
    vertical resize 80 "always certain size
    nnoremap <buffer> <CR> <C-]>
    if g:has_nowait
      nnoremap <nowait> <buffer> <silent> [ :<C-u>pop<CR>
      nnoremap <nowait> <buffer> <silent> ] :<C-u>tag<CR>
    else
      nnoremap <nowait> <buffer> <silent> [[ :<C-u>pop<CR>
      nnoremap <nowait> <buffer> <silent> ]] :<C-u>tag<CR>
    endif
  endif
  nnoremap <silent> <buffer> q :q<CR>
  setlocal nolist nonumber norelativenumber nospell
endfunction
command! -nargs=? SimpleSetup call <sid>simplesetup(<args>)

"###############################################################################
"VIM VISUAL INCREMENT; creating columns of 1/2/3/4 etc.
"Disable all remaps
augroup increment
augroup END
"Disable old maps, create new ones
"Also change what vim considers to be 'numbers', want
"to avoid situation where integers with leading zeros
"are considered 'octal'
set nrformats=alpha
if PlugActive("vim-visual-increment")
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
if PlugActive("codi.vim")
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
"Compact alternative to neocomplete
"Just could not get it working, not many people so maybe just broken
augroup mucomplete
augroup END
if PlugActive("vim-mucomplete") "just check if activated
  " let g:mucomplete#enable_auto_at_startup = 1
  " let g:mucomplete#no_mappings = 1
  " let g:mucomplete#no_popup_mappings = 1
endif

"###############################################################################
"NEOCOMPLETE (RECOMMENDED SETTINGS)
if PlugActive("neocomplete.vim") "just check if activated
  "Enable omni completion for different filetypes; sooper cool bro
  "Not sure if this works yet
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

"##############################################################################"
"INDENTLINE
"Decided not worth it; need to make them black/pale, but often want conceal
"characters to have no coloring (i.e. use whatever color is underneath).
if PlugActive('indentline.vim')
  let g:indentLine_char='¦' "¦│┆
  let g:indentLine_setColors=0
  let g:indentLine_setConceal=0
  let g:indentLine_fileTypeExclude = ['rst', 'qf', 'diff', 'man', 'help', 'gitcommit', 'tex']
endif

"###############################################################################
"EVENTS MANAGEMENT
"Originally created for Ctrl-P plugin, but might consider using
"in future for other purposes
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

"##############################################################################"
"FZF COMPLETION
"TODO: Mimick command-line behavior with function -- can have FZF print
"available files/dirs, then call function that recursively calls the FZF
"activator if user selected a dir, opens the tab when they selected a file
"##############################################################################"
"Maybe not necessary anymore because Ctrl-P access got way better
"Vim documentation is incomplete; also see readme file: https://github.com/junegunn/fzf/blob/master/README-VIM.md
"The ctrl-i map below prevents tab from doing anything
"Also in iterm ctrl-i keypress translates to F3, so use that below
" Plug 'junegunn/fzf.vim'
" if PlugActive('fzf.vim')
augroup fzf
augroup END
if PlugActive('.fzf')
  "First some basic settings
  let g:fzf_layout = {'down': '~20%'} "make window smaller
  let g:fzf_action = {'ctrl-i': 'silent!',
    \ 'ctrl-m': 'tab split', 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split', 'ctrl-v': 'vsplit'}
endif
if PlugActive('fzf.vim')
  "Custom tools using fzf#run command
  "First a helper function (see below)
  let g:size='~35%'
  function! s:tabselect()
    let items=[]
    for i in range(tabpagenr('$')) "iterate through each tab
      let tabnr = i + 1 "the tab number
      let buflist = tabpagebuflist(tabnr)
      for b in buflist "get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
        if !In(g:bufignore, getbufvar(b, "&ft"))
          let bufnr = b "we choose this as our 'primary' file for tab title
          break
        elseif b==buflist[-1] "occurs if e.g. entire tab is a help window; exception, and indeed use it for tab title
          let bufnr = b
        endif
      endfor
      if tabnr==tabpagenr()
        continue
      endif
      let items+=[tabnr.': '.fnamemodify(bufname(bufnr),'%:t')] "actual name
    endfor
    return items
  endfunction
  function! s:tabjump(item)
    exe 'normal! '.split(a:item,':')[0].'gt'
  endfunction
  "Navigate to tabs, ignoring panels e.g. help windows and tagbar, better than :Windows
  " nnoremap <silent> <Tab><Tab> :Windows<CR>
  nnoremap <silent> <Tab><Tab> :call fzf#run({'source':<sid>tabselect(), 'options':'--no-sort', 'sink':function('<sid>tabjump'), 'down':g:size})<CR>
  "Open file in git repository, builtin version is fine
  nnoremap <silent> <C-p> :GFiles<CR>
  " nnoremap <silent> <C-p> :call fzf#run({'source':'git ls-files', 'sink':'tabe', 'down':g:size})<CR>
  "Open file through recursive search
  "Almost always need this from inside git repo, so don't bother
  " nnoremap <silent> <C-p> :Files<CR>
endif

"###############################################################################
"Ctrl-Space
"Massive plugin that I might stop using
"Probably just want to use Unite for some of these features, and
"use the vim-FZF plugin for fuzzy buffer searching.
if PlugActive('vim-ctrlspace')
  set hidden
  let g:CtrlSpaceUseTabline=0 "want to use my own!
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
if PlugActive("nerdtree")
  augroup nerdtree
    au!
    au BufEnter * if (winnr('$')==1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    au FileType nerdtree call s:nerdtreesetup()
  augroup END
  " f stands for files here
  " nnoremap <Leader>f :NERDTreeFind<CR>
  nnoremap <Leader>f :NERDTree %<CR>
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
    nnoremap <buffer> <Leader>f :NERDTreeClose<CR>
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
augroup nerdcomment
augroup END
if PlugActive("nerdcommenter")
  "----------------------------------------------------------------------------"
  "Basic settings and maps
  "----------------------------------------------------------------------------"
  "Custom delimiter overwrites (default python includes space for some reason)
  let g:NERDCustomDelimiters = {
    \ 'julia': {'left': '#', 'leftAlt': '#=', 'rightAlt': '=#'},
    \ 'python': {'left': '#'}, 'cython': {'left': '#'},
    \ 'pyrex': {'left': '#'}, 'ncl': {'left': ';'},
    \ 'smarty': {'left': '<!--', 'right': '-->'},
    \ }
  "Default settings
  let g:NERDCreateDefaultMappings = 0 " disable default mappings (make my own)
  let g:NERDSpaceDelims = 1           " comments led with spaces
  let g:NERDCompactSexyComs = 1       " use compact syntax for prettified multi-line comments
  let g:NERDTrimTrailingWhitespace=1  " trailing whitespace deletion
  let g:NERDCommentEmptyLines = 1     " allow commenting and inverting empty lines (useful when commenting a region)
  let g:NERDDefaultAlign = 'left'     " align line-wise comment delimiters flush left instead of following code indentation
  let g:NERDCommentWholeLinesInVMode = 1
  "Basic maps for toggling comments
  function! s:comment_insert()
    if exists('b:NERDCommenterDelims')
      let left=b:NERDCommenterDelims['left']
      let right=b:NERDCommenterDelims['right']
      let left_alt=b:NERDCommenterDelims['leftAlt']
      let right_alt=b:NERDCommenterDelims['rightAlt']
      if (left != '' && right != '')
        return (left . '  ' . right . repeat("\<Left>", len(right)+1))
      elseif left_alt != '' && right_alt != ''
        return (left_alt . '  ' . right_alt . repeat("\<Left>", len(right_alt)+1))
      else
        return (left . ' ')
      endif
    else
      return ''
    endif
  endfunction
  inoremap <expr> <C-c> <sid>comment_insert()
  " imap <expr> <C-c> b:NERDCommenterDelims['left'] . ' ' . b:NERDCommenterDelims['right']
  map c. <Plug>NERDCommenterToggle
  map co <Plug>NERDCommenterComment
  map cO <Plug>NERDCommenterUncomment

  "----------------------------------------------------------------------------"
  "Create functions that return fancy comment 'blocks' -- e.g. for denoting
  "section changes, for drawing a line across the screen, for writing information
  "Functions will preserve indentation level of the line where cursor is located
  "----------------------------------------------------------------------------"
  "First the helpers functions
  function! s:comment_filler()
    if &ft=="vim"
      return '#'
    else
      return Comment()
    endif
  endfunction
  function! s:comment_indent()
    let col=match(getline('.'), '^\s*\S\zs') "location of first non-whitespace char
    return (col==-1 ? 0 : col-1)
  endfunction
  "Next separators that extend out to 80th column
  function! s:bar(...) "inserts above by default; most common use
    if a:0 "if non-zero number of args
      let fill=a:1 "fill character
    else "chosoe fill based on filetype -- if comment char is 'skinny', pick another one
      let fill=s:comment_filler()
    endif
    let nspace=s:comment_indent()
    let nfill=(78-nspace)/len(fill) "divide by length of fill character
    let cchar=Comment()
    normal! k
    call append(line('.'), repeat(' ',nspace).cchar.repeat(fill,nfill).cchar)
    normal! jj
  endfunction
  "Sectioners (bars with text in-between)
  function! s:section(...) "to make insert above, replace 'o' with 'O', and '<Up>' with '<Down>'
    if a:0
      let fill=a:1 "fill character
    else "choose fill based on filetype -- if comment char is 'skinny', pick another one
      let fill=s:comment_filler()
    endif
    let nspace=s:comment_indent()
    let nfill=(78-nspace)/len(fill) "divide by length of fill character
    let cchar=Comment()
    let lines=[repeat(' ',nspace).cchar.repeat(fill,nfill).cchar,
             \ repeat(' ',nspace).cchar.' ',
             \ repeat(' ',nspace).cchar.repeat(fill,nfill).cchar]
    normal! k
    call append(line('.'), lines)
    normal! jj$
  endfunction
  "Arbtirary message above this line, matching indentation level
  function! s:message(...)
    if a:0
      let message=' '.a:1
    else
      let message=''
    endif
    let nspace=s:comment_indent()
    let cchar=Comment()
    normal! k
    call append(line('.'), repeat(' ',nspace).cchar.message)
    normal! jj
  endfunction
  "Inline style of format # ---- Hello world! ----
  function! s:inline(ndash)
    let nspace=s:comment_indent()
    let cchar=Comment()
    normal! k
    call append(line('.'), repeat(' ',nspace).cchar.repeat('-',a:ndash).'  '.repeat('-',a:ndash))
    normal! j^
    call search('- \zs', '', line('.')) "search, and stop on this line (should be same one); no flags
  endfunction
  "Inline style of format # ---- Hello world! ----
  function! s:double()
    let nspace=s:comment_indent()
    let cchar=Comment()
    normal! k
    call append(line('.'), repeat(' ',nspace).cchar.'  '.cchar)
    normal! j$h
  endfunction
  "Separator of dashes just matching current line length
  function! s:separator(...)
    if a:0
      let fill=a:1 "fill character
    else
      let fill=Comment() "comment character
    endif
    let nspace=s:comment_indent()
    let ndash=(match(getline('.'), '\s*$')-nspace) "location of last non-whitespace char
    let cchar=Comment()
    call append(line('.'), repeat(' ',nspace).repeat(fill,ndash))
  endfunction
  "Docstring
  function! s:docstring(char)
    let nspace=(s:comment_indent()+&l:tabstop)
    call append(line('.'), [repeat(' ',nspace).repeat(a:char,3), repeat(' ',nspace), repeat(' ',nspace).repeat(a:char,3)])
    normal! jj$
  endfunction

  "----------------------------------------------------------------------------"
  " Apply remaps using functions
  "----------------------------------------------------------------------------"
  "Section headers and dividers
  nnoremap <silent> <Plug>bar1 :call <sid>bar('-')<CR>:call repeat#set("\<Plug>bar1")<CR>
  nnoremap <silent> <Plug>bar2 :call <sid>bar()<CR>:call repeat#set("\<Plug>bar2")<CR>
  nmap c- <Plug>bar1
  nmap c_ <Plug>bar2
  nnoremap <silent> c\  :call <sid>section('-')<CR>A
  nnoremap <silent> c\| :call <sid>section()<CR>A
  "Author information comment
  nnoremap <silent> cA :call <sid>message('Author: Luke Davis (lukelbd@gmail.com)')<CR>
  "Current date comment; y is for year; note d is reserved for that kwarg-to-dictionary map
  nnoremap <silent> cY :call <sid>message('Date: '.strftime('%Y-%m-%d'))<CR>
  "Comment characters on either side fo line
  nnoremap <silent> c, :call <sid>double()<CR>i
  "Create an 'inline' comment header
  nnoremap <silent> cI :call <sid>inline(4)<CR>i
  "Create comment separator below current line
  nnoremap <silent> c; :call <sid>separator('-')<CR>
  nnoremap <silent> c: :call <sid>separator()<CR>
  "Python docstring
  nnoremap c' :call <sid>docstring("'")<CR>A
  nnoremap c" :call <sid>docstring('"')<CR>A
endif

"###############################################################################
"SYNTASTIC (syntax checking for code)
augroup syntastic
augroup END
if PlugActive("syntastic")
  "Commands for circular location-list (error) scrolling
  "Also remap the commands
  command! Lnext try | lnext | catch | lfirst | catch | endtry
  command! Lprev try | lprev | catch | llast  | catch | endtry
  nnoremap <silent> ;n :Lnext<CR>
  nnoremap <silent> ;N :Lprev<CR>
  "Determine checkers from annoying human-friendly output; version suitable
  "for scripting does not seem available. Weirdly need 'silent' to avoid
  "printint to vim menu. The *last* value in array will be checker.
  function! s:syntastic_checkers(...)
    redir => output
    silent SyntasticInfo
    redir END
    let result=split(output, "\n")
    let checkers=split(split(result[-2], ':')[-1], '\s\+')
    if checkers[0]=='-'
      let checkers=[]
    else
      call extend(checkers, split(split(result[-1], ':')[-1], '\s\+')[:1])
    endif
    if a:0 "just echo the result
      echo 'Checkers: '.join(checkers[:-2], ', ')
    else
      return checkers
    endif
  endfunction
  command! SyntasticCheckers call <sid>syntastic_checkers(1)
  "Helper function
  "Need to run Syntastic with noautocmd to prevent weird conflict with tabbar,
  "but that means have to change some settings manually
  function! s:syntastic_status()
    return (exists('b:syntastic_on') && b:syntastic_on)
  endfunction
  function! s:syntastic_enable()
    "Run checker
    let nbufs=len(tabpagebuflist())
    let checkers=s:syntastic_checkers()
    if len(checkers)==0
      echom 'No checkers available.'
    else "try running the checker, see if anything comes up
      noautocmd SyntasticCheck
      if (len(tabpagebuflist())>nbufs && !s:syntastic_status()) 
        \ || (len(tabpagebuflist())==nbufs && s:syntastic_status())
        wincmd j | set syntax=on | SimpleSetup
        wincmd k | let b:syntastic_on=1 | silent! set signcolumn=no
      else
        echom 'No errors found with checker '.checkers[-1].'.'
        let b:syntastic_on=0
      endif
    endif
  endfunction
  function! s:syntastic_disable()
    let b:syntastic_on=0
    SyntasticReset
  endfunction
  "Set up custom remaps
  nnoremap <silent> ;x :update<CR>:call <sid>syntastic_enable()<CR>
  nnoremap <silent> ;X :call <sid>syntastic_disable()<CR>
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
if PlugActive('vimtex')
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
"Note: Vim seems to run wraptoggle() *asynchronously* so if you test the
"filetype within function instead of right when you issue autocommand, can
"get the wrong files wrapped.
"Note: BufRead failed sometimes, maps got mysteriously reset even though
"wrapping was still on, happened when switching to non-wrapped tabs at start
"of session
augroup wrap_tabs
  au!
  au FileType * exe 'WrapToggle '.In(['bib','tex','markdown','liquid'],&ft)
  au FileType * exe 'TabToggle '.In(['text','gitconfig'],&ft)
augroup END
"Buffer amount on either side
"Can change this variable globally if want
let g:scrolloff=4 "but no scrolloff for wrapped documents
let g:colorcolumn=(has('gui_running') ? '0' : '80,120')
"Functions and command for toggling 'line wrapping' (with associated settings)
"and 'literal tabs' (so far just one option)
function! s:tabtoggle(...)
  if a:0
    let &l:expandtab=1-a:1 "toggle 'on' means literal tabs are 'on'
  else
    setlocal expandtab!
  endif
  let b:tab_mode=&l:expandtab
endfunction
command! -nargs=? TabToggle call <sid>tabtoggle(<args>)
function! s:wraptoggle(...)
  if a:0 "if non-zero number of args
    let toggle=a:1
  elseif !exists('b:wrap_mode')
    let toggle=1
  else
    let toggle=1-b:wrap_mode
  endif
  if toggle==1
    "Display options that make more sense with wrapped lines
    let b:wrap_mode=1
    let &l:scrolloff=0
    let &l:wrap=1
    let &l:colorcolumn=0
    "Basic wrap-mode navigation, always move visually
    "Still might occasionally want to navigate by lines though, so remap those to g
    "Use noremap instead of nnoremap, so works in *operator-pending mode*
    noremap  <buffer> k  gk
    noremap  <buffer> j  gj
    noremap  <buffer> ^  g^
    noremap  <buffer> $  g$
    noremap  <buffer> 0  g0
    noremap  <buffer> gj j
    noremap  <buffer> gk k
    noremap  <buffer> g^ ^
    noremap  <buffer> g$ $
    noremap  <buffer> g0 0
    nnoremap <buffer> A  g$a
    nnoremap <buffer> I  g^i
    nnoremap <buffer> gA A
    nnoremap <buffer> gI I
  else
    "Disable previous options
    let b:wrap_mode=0
    let &l:scrolloff=g:scrolloff
    let &l:wrap=0
    let &l:colorcolumn=g:colorcolumn
    "Disable previous maps
    silent! unmap  <buffer> k
    silent! unmap  <buffer> j
    silent! unmap  <buffer> ^
    silent! unmap  <buffer> $
    silent! unmap  <buffer> 0
    silent! unmap  <buffer> gj
    silent! unmap  <buffer> gk
    silent! unmap  <buffer> g^
    silent! unmap  <buffer> g$
    silent! unmap  <buffer> g0
    silent! nunmap <buffer> A
    silent! nunmap <buffer> I
    silent! nunmap <buffer> gA
    silent! nunmap <buffer> gI
  endif
endfunction
command! -nargs=? WrapToggle call <sid>wraptoggle(<args>)

"###############################################################################
"TABULAR - ALIGNING AROUND :,=,ETC.
"By default, :Tabularize command provided *without range* will select the
"contiguous lines that contain specified delimiter; so this function only makes
"sense when applied for a visual range! So we don't need to worry about using Tabularize's
"automatic range selection/implementing it in this special command
augroup tabular
augroup END
if PlugActive("tabular")
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
      echom 'Warning: No matches in selection.'
    else
      exe firstline.','.lastline.'Tabularize '.a:arg
    endif
    "Add back the lines that were deleted
    for pair in reverse(dlines) "insert line of text below where deletion occurred (line '0' adds to first line)
      call append(pair[0]-1, pair[1])
    endfor
  endfunction
  "Command
  "* Note odd concept (see :help args) that -nargs=1 will pass subsequent text, including
  "  whitespace, as single argument, but -nargs=*, et cetera, will aceept multiple arguments delimited by whitespace
  "* Be careful -- make sure to pass <args> in singly quoted string!
	command! -range -nargs=1 Table <line1>,<line2>call <sid>table(<q-args>)
  "NOTE: e.g. for aligning text after colons, input character :\zs; aligns first character after matching preceding regex
  "Align arbitrary character, and suppress error message if user Ctrl-c's out of input line
  nnoremap <silent> <expr> \<Space> ':silent! Tabularize /'.input('Alignment regex: ').'/l1c1<CR>'
  vnoremap <silent> <expr> \<Space> "<Esc>:silent! '<,'>Table /".input('Alignment regex: ').'/l1c1<CR>'
  "By commas; suitable for diag_table's in models; does not ignore comment characters
  nnoremap <expr> \, ':Tabularize /,\('.Comment(1).'.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \, ':Table      /,\('.Comment(1).'.*\)\@<!\zs/l0c1<CR>'
  "Dictionary, colon on right
  nnoremap <expr> \D ':Tabularize /\('.Comment(1).'.*\)\@<!\zs:/l0c1<CR>'
  vnoremap <expr> \D ':Table      /\('.Comment(1).'.*\)\@<!\zs:/l0c1<CR>'
  "Dictionary, colon on left
  nnoremap <expr> \d ':Tabularize /:\('.Comment(1).'.*\)\@<!\zs/l0c1<CR>'
  vnoremap <expr> \d ':Table      /:\('.Comment(1).'.*\)\@<!\zs/l0c1<CR>'
  "Right-align by spaces, considering comments as one 'field'; other words are
  "aligned by space; very hard to ignore comment-only lines here, because we specify text
  "before the first 'field' (i.e. the entirety of non-matching lines) will get right-aligned
  nnoremap <expr> \r ':Tabularize /^\s*[^\t '.Comment(1).']\+\zs\ /r0l0l0<CR>'
  vnoremap <expr> \r ':Table      /^\s*[^\t '.Comment(1).']\+\zs\ /r0l0l0<CR>'
  "As above, but let align
  "See :help non-greedy to see what braces do; it is like *, except instead of matching
  "as many as possible, can match as few as possible in some range;
  "with braces, a minus will mean non-greedy
  nnoremap <expr> \l ':Tabularize /^\s*\S\{-1,}\('.Comment(1).'.*\)\@<!\zs\s/l0<CR>'
  vnoremap <expr> \l ':Table      /^\s*\S\{-1,}\('.Comment(1).'.*\)\@<!\zs\s/l0<CR>'
  "Check out documentation on \@<! atom; difference between that and \@! is that \@<!
  "checks whether something doesn't match *anywhere before* what follows
  "Also the \S has to come before the \(\) atom instead of after for some reason
  nnoremap <expr> \\ ':Tabularize /\S\('.Comment(1).'.*\)\@<!\zs\ /l0<CR>'
  vnoremap <expr> \\ ':Table      /\S\('.Comment(1).'.*\)\@<!\zs\ /l0<CR>'
  "As above, but include comments
  " nnoremap <expr> \\| ':Tabularize /\S\zs\ /l0<CR>'
  " vnoremap <expr> \\| ':Table      /\S\zs\ /l0<CR>'
  "Tables
  nnoremap <expr> \\| ':Tabularize /\|/l1c1<CR>'
  vnoremap <expr> \\| ':Table      /\|/l1c1<CR>'
  "Case/esac blocks
  nnoremap <expr> \) ':Tabularize /\(\S\+)\zs\\|\zs;;\)/l1c0l1<CR>'
  vnoremap <expr> \) ':Table      /\(\S\+)\zs\\|\zs;;\)/l1c0l1<CR>'
  "By comment character; ^ is start of line, . is any char, .* is any number, \zs
  "is start match here (must escape backslash), then search for the comment
  " nnoremap <expr> \C ':Tabularize /^.*\zs'.Comment(1).'/l1<CR>'
  " vnoremap <expr> \C ':Table      /^.*\zs'.Comment(1).'/l1<CR>'
  "By comment character, but ignore comment-only lines
  nnoremap <expr> \C ':Tabularize /^\s*[^ \t'.Comment(1).'].*\zs'.Comment(1).'/l1<CR>'
  vnoremap <expr> \C ':Table      /^\s*[^ \t'.Comment(1).'].*\zs'.Comment(1).'/l1<CR>'
  "Align by the first equals sign either keeping it to the left or not
  "The eaiser to type one (-=) puts equals signs in one column
  "This selects the *first* uncommented equals sign that does not belong to
  "a logical operator or incrementer <=, >=, ==, %=, -=, +=, /=, *= (have to escape dash in square brackets)
  nnoremap <expr> \= ':Tabularize /^[^'.Comment(1).']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  vnoremap <expr> \= ':Table      /^[^'.Comment(1).']\{-}[=<>+\-%*]\@<!\zs==\@!/l1c1<CR>'
  nnoremap <expr> \+ ':Tabularize /^[^'.Comment(1).']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
  vnoremap <expr> \+ ':Table      /^[^'.Comment(1).']\{-}[=<>+\-%*]\@<!=\zs=\@!/l0c1<CR>'
  " nnoremap <expr> \= ':Tabularize /^[^=]*\zs=/l1c1<CR>'
  " vnoremap <expr> \= ':Table      /^[^=]*\zs=/l1c1<CR>'
  " nnoremap <expr> \+ ':Tabularize /^[^=]*=\zs/l0c1<CR>'
  " vnoremap <expr> \+ ':Table      /^[^=]*=\zs/l0c1<CR>'
endif

"###############################################################################
"TAGBAR (requires 'brew install ctags-exuberant')
" Note some mappings:
" p jumps to tag under cursor, in code window, but remain in tagbar
" C-n and C-p browses by top-level tags
" o toggles the fold under cursor, or current one
if PlugActive("tagbar")
  "Automatically open tagbar (with FileType did not work because maybe
  "some conflict with Obsession; BufReadPost works though)
  "Gets pretty annoying so nah
  augroup tagbar
    au!
    " au BufReadPost * call s:tagbarmanager()
  augroup END
  function! s:tagbarmanager()
    if ".py,.jl,.m,.vim,.tex"=~expand("%:e") && expand("%:e")!=""
      call s:tagbarsetup()
    endif
  endfunction
  "Setting up Tagbar with a custom configuration
  function! s:tagbarsetup()
    "Manage various panels, make sure nerdtree is flushed to right
    "if open; first close tagbar if open, open if closed
    if &ft=="nerdtree"
      wincmd h
      wincmd h "move two places in case e.g. have help menu + nerdtree already
    endif
    let tabfts=map(tabpagebuflist(),'getbufvar(v:val, "&ft")')
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
    "Make sure NERDTree is always flushed to the far right
    "Do this by moving TagBar one spot to the left if it is opened
    "while NERDTree already open. If TagBar was opened first, NERDTree will already be far to the right.
  endfunction
  nnoremap <silent> <Leader>t :call <sid>tagbarsetup()<CR>
  "Global settings
  " let g:tagbar_iconchars = ['▸', '▾'] "prettier
  " let g:tagbar_iconchars = ['+', '-'] "simple
  let g:tagbar_silent=1 "no information echoed
  let g:tagbar_previewwin_pos="bottomleft" "result of pressing 'P'
  let g:tagbar_left=0 "open on left; more natural this way
  let g:tagbar_indent=-1 "only one space indent
  let g:tagbar_show_linenumbers=0 "not needed
  let g:tagbar_autofocus=0 "don't autojump to window if opened
  let g:tagbar_sort=1 "sort alphabetically? actually much easier to navigate, so yes
  let g:tagbar_case_insensitive=1 "make sorting case insensitive
  let g:tagbar_compact=1 "no header information in panel
  let g:tagbar_width=15 "better default
  let g:tagbar_zoomwidth=15 "don't ever 'zoom' even if text doesn't fit
  let g:tagbar_expand=0
  " let g:tagbar_singleclick=1 "one click select, was annoying
  "Mappings
  let g:tagbar_map_openfold="="
  let g:tagbar_map_closefold="-"
  let g:tagbar_map_closeallfolds="_"
  let g:tagbar_map_openallfolds="+"
  "Fold levels
  let g:tagbar_autoshowtag=2 "never ever open tagbar folds automatically, even when opening for first time
  let g:tagbar_foldlevel=1 "setting to zero will override the 'kinds' fields in below dicts
  "Custom creations; note the kinds depend on some special language defs in ~/.ctags
  "For more info, see :help tagbar-extend
  "To list kinds, see :!ctags --list-kinds=<filetype>
  "The first number is whether to fold by default, second is whether to highlight location
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
endif

"###############################################################################
"###############################################################################
" GENERAL STUFF, BASIC REMAPS
"###############################################################################
"###############################################################################
"BUFFER WRITING/SAVING
"Just declare a couple maps here
"Note: Update only writes if file has been changed; see
"https://stackoverflow.com/a/22425359/4970632
augroup saving
augroup END
nnoremap <silent> <C-s> :update<CR>
" nnoremap <silent> <C-s> :w!<CR>
nnoremap <silent> <C-x> :echom "Ctrl-x reserved for tmux commands. Use Ctrl-z to compile instead."<CR>
nnoremap <silent> <C-r> :if &ft=="vim" \| so % \| echom "Sourced file." \| endif<CR>
"use force write, in case old version exists
nnoremap <silent> <C-a> :qa<CR> 
nnoremap <silent> <C-q> :let g:tabpagelast=(tabpagenr('$')==tabpagenr())<CR>:if tabpagenr('$')==1
  \ \| qa \| else \| tabclose \| if !g:tabpagelast \| silent! tabp \| endif \| endif<CR>
nnoremap <silent> <C-w> :let g:tabpagenr=tabpagenr('$')<CR>:let g:tabpagelast=(tabpagenr('$')==tabpagenr())<CR>
  \ :q<CR>:if g:tabpagenr!=tabpagenr('$') && !g:tabpagelast \| silent! tabp \| endif<CR>
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
let &breakat=" 	!*-+;:,./?" "break at single instances of several characters
set textwidth=0 "also disable it to start with dummy
set linebreak "breaks lines only in whitespace makes wrapping acceptable
if exists('&breakindent')
  set breakindent "map indentation when breaking
endif
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

"###############################################################################
"SPECIAL TAB NAVIGATION
"Remember previous tab
augroup tabs
  au!
  au TabLeave * let g:lasttab=tabpagenr()
augroup END
"Basic switching, and shortcut for 'last active tab'
nnoremap <Tab>1 1gt
nnoremap <Tab>2 2gt
nnoremap <Tab>3 3gt
nnoremap <Tab>4 4gt
nnoremap <Tab>5 5gt
nnoremap <Tab>6 6gt
nnoremap <Tab>7 7gt
nnoremap <Tab>8 8gt
nnoremap <Tab>9 9gt
nnoremap <Tab>, gT
nnoremap <Tab>. gt
let g:lasttab=1
nnoremap <silent> <Tab>' :execute "tabn ".g:lasttab<CR>
  "return to previous tab
"Moving screen around cursor
nnoremap <Tab>u zt
nnoremap <Tab>o zb
nnoremap <Tab>i mzz.`z
"Moving cursor around screen
nnoremap <Tab>q H
nnoremap <Tab>w M
nnoremap <Tab>e L
"Moving screen left/right
nnoremap <Tab>y zH
nnoremap <Tab>p zL
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
nnoremap <silent> <Tab>m :call <sid>tabmove(input('Move tab: '))<CR>
nnoremap <silent> <Tab>> :call <sid>tabmove(eval(tabpagenr()+1))<CR>
nnoremap <silent> <Tab>< :call <sid>tabmove(eval(tabpagenr()-1))<CR>
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
  let response=input('open ('.getcwd().'): ', '', 'customlist,AllFiles')
  if response!=''
    exe 'tabe '.response
  else
    echom "Cancelled."
  endif
endfunction
nnoremap <silent> <C-o> :call <sid>openwrapper()<CR>
"Splitting -- make :sp and :vsp split to right and bottom
"Beware if you switched underscore and backslash!
set splitright
set splitbelow
nnoremap <Tab>- :split 
nnoremap <Tab>\ :split 
nnoremap <Tab>_ :vsplit 
nnoremap <Tab>\| :vsplit 
"Window selection
nnoremap <Tab>j <C-w>j
nnoremap <Tab>k <C-w>k
nnoremap <Tab>h <C-w>h
nnoremap <Tab>l <C-w>l
"Switch to last window
nnoremap <Tab>; <C-w><C-p>
"Maps for resizing windows
nnoremap <expr> <silent> <Tab>9 '<Esc>:resize '.(winheight(0)-3*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>0 '<Esc>:resize '.(winheight(0)+3*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>( '<Esc>:resize '.(winheight(0)-5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>) '<Esc>:resize '.(winheight(0)+5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>[ '<Esc>:vertical resize '.(winwidth(0)-5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>] '<Esc>:vertical resize '.(winwidth(0)+5*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>{ '<Esc>:vertical resize '.(winwidth(0)-10*max([1,v:count])).'<CR>'
nnoremap <expr> <silent> <Tab>} '<Esc>:vertical resize '.(winwidth(0)+10*max([1,v:count])).'<CR>'
nnoremap <silent> <Tab>= :vertical resize 80<CR>

"###############################################################################
"COPY/PASTING CLIPBOARD
"Pastemode toggling; pretty complicated
"Really really really want to toggle with <C-v> since often hit Ctrl-V, Cmd-V, so
"makes way more sense, but that makes inserting 'literal chars' impossible
"Workaround is to map cv to enter insert mode with <C-v>
nnoremap <expr> <silent> <Leader>v ":if &eventignore=='' \| setlocal eventignore=InsertEnter \| echom 'Ctrl-V pasting disabled for next InsertEnter.' "
  \." \| else \| setlocal eventignore= \| echom '' \| endif<CR>"
augroup copypaste "also clear command line when leaving insert mode, always
  au!
  au InsertEnter * set pastetoggle=<C-v> "need to use this, because mappings don't work
  au InsertLeave * set nopaste | setlocal eventignore= pastetoggle= | echo
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
augroup search_replace
  au!
  au InsertEnter * set noignorecase "default ignore case
  au InsertLeave * set ignorecase
  au FileType bib,tex call <sid>tex_replace()
augroup END
set hlsearch incsearch "show match as typed so far, and highlight as you go
set noinfercase ignorecase smartcase "smartcase makes search case insensitive, unless has capital letter
"Will use the 'g' prefix for these, because why not
"see https://unix.stackexchange.com/a/12814/112647 for idea on multi-empty-line map
"Delete commented text; very useful when sharing manuscripts
noremap <silent> <expr> \c ':s/\(^\s*'.Comment().'.*$\n'
  \.'\\|^.*\S*\zs\s\+'.Comment().'.*$\)//g \| noh<CR>'
"Delete trailing whitespace; from https://stackoverflow.com/a/3474742/4970632
"Replace consecutive spaces on current line with one space, if they're not part of indentation
noremap <silent> \w :s/\s\+$//g \| noh<CR>:echom "Trimmed trailing whitespace."<CR>
noremap <silent> \W :s/\(\S\)\@<=\(^ \+\)\@<! \{2,}/ /g \| noh<CR>:echom "Squeezed consecutive spaces."<CR>
"Delete empty lines
"Replace consecutive newlines with single newline
noremap <silent> \e :s/^\s*$\n//g \| noh<CR>:echom "Removed empty lines."<CR>
noremap <silent> \E :s/\(\n\s*\n\)\(\s*\n\)\+/\1/g \| noh<CR>:echom "Squeezed consecutive newlines."<CR>
"Replace tabs with spaces
noremap <expr> <silent> \<Tab> ':s/\t/' .repeat(' ',&tabstop).'/g \| noh<CR>'
"Fix unicode quotes and dashes, trailing dashes due to a pdf copy
"Underscore is easiest one to switch if using that Karabiner map
nnoremap <silent> \' :silent! %s/‘/`/g<CR>:silent! %s/’/'/g<CR>:echom "Fixed single quotes."<CR>
nnoremap <silent> \" :silent! %s/“/``/g<CR>:silent! %s/”/''/g<CR>:echom "Fixed double quotes."<CR>
nnoremap <silent> \- :silent! %s/–/--/g<CR>:echom "Fixed long dashes."<CR>
nnoremap <silent> \_ :silent! %s/\(\w\)[-–] /\1/g<CR>:echom "Fixed trailing dashes."<CR>
"Special: replace useless BibTex entries
function! s:tex_replace()
  nnoremap <buffer> <silent> \x :%s/^\s*\(abstract\\|file\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>
  nnoremap <buffer> <silent> \X :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>
endfunction

"###############################################################################
"CAPS LOCK
"The autocmd is confusing, but better than an autocmd that lmaps and lunmaps;
"that would cancel command-line queries (or I'd have to scroll up to resume them)
"don't think any other mapping type has anything like lmap; iminsert is unique
"yay insert mode WITH CAPS LOCK how cool is that THAT THAT!
augroup capslock
  au!
  au InsertLeave,CmdWinLeave * set iminsert=0
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
"Use iTerm hex Code map to simulate an F5 press whenever you press some other
"easier to reach combo. Currently it is <C-/> -- like it a lot!
inoremap <F5> <C-^>
cnoremap <F5> <C-^>
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
"Delete all folds; delete fold at cursor is zd
nnoremap zD zE
"Never need the lower-case versions (which globally change fold levels), but
"often want to open/close everything; this mnemonically makes sense because
"folding is sort-of like indenting really
nnoremap z> zM
nnoremap z< zR
"Open and close all folds; to open/close under cursor, use zo/zc
nnoremap zO zR
nnoremap zC zM
"Change fold levels, and make sure return to same place
"Never really use this feature so forget it
" nnoremap <silent> zl :let b:position=winsaveview()<CR>zm:call winrestview(b:position)<CR>
" nnoremap <silent> zh :let b:position=winsaveview()<CR>zr:call winrestview(b:position)<CR>

"###############################################################################
"g CONFIGURATION
augroup gcommands
augroup END
"Free up m keys, so ge/gE command belongs as single-keystroke words along with e/E, w/W, and b/B
noremap m ge
noremap M gE
"Capitalization stuff with g, a bit refined
"not currently used in normal mode, and fits better mnemonically
"Mnemonic is l for letter, t for title case
nnoremap gu guiw
vnoremap gu gu
nnoremap gU gUiw
vnoremap gU gU
vnoremap gl ~
nnoremap <silent> <Plug>cap1 ~h:call repeat#set("\<Plug>cap1")<CR>
nnoremap <silent> <Plug>cap2 mzguiw~h`z:call repeat#set("\<Plug>cap2")<CR>
nmap gl <Plug>cap1
nmap gt <Plug>cap2
" nnoremap gl ~h
" nnoremap gt mzguiw~h`z
"Default 'open file under cursor' to open in new tab; change for normal and vidual
"Remember the 'gd' and 'gD' commands go to local declaration, or first instance.
nnoremap <expr> gf ":if len(glob('<cfile>'))>0 \| echom 'File(s) exist.' "
  \."\| else \| echom 'File \"'.expand('<cfile>').'\" does not exist.' \| endif<CR>"
nnoremap gF <c-w>gf
"Now remap indentation commands. Why is this here? Just go with it.
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
"SPECIAL SYNTAX HIGHLIGHTING OVERWRITES (all languages; must come after filetype stuff)
"* See this thread (https://vi.stackexchange.com/q/9433/8084) on modifying syntax
"  for every file; we add our own custom highlighting for vim comments
"* For adding keywords, see: https://vi.stackexchange.com/a/11547/8084
"* Will also enforce shebang always has the same color, because it's annoying otherwise
"* And generally only want 'conceal' characters invisible for latex; otherwise we
"  probably want them to look like comment characters
"* The url regex was copied from the one used for .tmux.conf
"------------------------------------------------------------------------------"
"First coloring for ***GUI Vim versions***
"See: https://www.reddit.com/r/vim/comments/4xd3yd/vimmers_what_are_your_favourite_colorschemes/ 
"------------------------------------------------------------------------------"
if has('gui_running')
  "Declare colorscheme
  " colorscheme gruvbox
  " colorscheme kolor
  " colorscheme dracula
  " colorscheme onedark
  " colorscheme molokai
  colorscheme oceanicnext "really nice
  " colorscheme yowish "yellow
  " colorscheme tomorrow-night
  " colorscheme atom "mimics Atom
  " colorscheme chlordane "hacker theme
  " colorscheme papercolor
  " colorscheme solarized
  " colorscheme fahrenheit
  " colorscheme slate "no longer controlled through terminal colors
  "Bugfixes
  hi! link vimCommand Statement
  hi! link vimNotFunc Statement
  hi! link vimFuncKey Statement
  hi! link vimMap     Statement
endif
"------------------------------------------------------------------------------"
"Next coloring for **Terminal VIM versions***
"Have to use cTerm colors, and control the ANSI colors from your terminal settings
"Warning: The containedin just tries to *guess* what particular comment and
"string group names are for given filetype syntax schemes. Verify that the
"regexes will match using :Group with cursor over a comment.
"Example: Had to change .*Comment to .*Comment.* since Julia has CommentL name
"------------------------------------------------------------------------------"
function! s:keywordsetup()
   syn match customURL =\v<(((https?|ftp|gopher)://|(mailto|file|news):)[^'  <>"]+|(www|web|w3)[a-z0-9_-]*\.[a-z0-9._-]+\.[^'  <>"]+)[a-zA-Z0-9/]= containedin=.*\(Comment\|String\).*
   hi link customURL Underlined
   if &ft!="vim"
     syn match Todo '\<\%(WARNING\|ERROR\|FIXME\|TODO\|NOTE\|XXX\)\ze:\=\>' containedin=.*Comment.* "comments
     syn match Special '^\%1l#!.*$' "shebangs
   else
     syn clear vimTodo "vim instead uses the Stuff: syntax
   endif
endfunction
augroup syntax
  au!
  "The below filetype-specific commands don't sucessfully overwrite existing highlighting;
  "need to use after/syntax/ft.vim instead
  " au Syntax *.tex syn match Ignore '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@=' conceal
  " au Syntax *.tex call matchadd('Conceal', '\(%.*\|\\[a-zA-Z@]\+\|\\\)\@<!\zs\\\([a-zA-Z@]\+\)\@=', 0, -1, {'conceal': ''})
  " au Syntax *.vim syn region htmlNoSpell start=+<!--+ end=+--\s*>+ contains=@NoSpell
  au Syntax  * call <sid>keywordsetup()
  au BufRead * set conceallevel=2 concealcursor=
  " au BufEnter * if &ft=="tex" | hi Conceal ctermbg=NONE ctermfg=NONE | else | hi Conceal ctermbg=NONE ctermfg=Black | endif
  au InsertEnter * highlight StatusLine ctermbg=Black ctermbg=White ctermfg=Black cterm=NONE
  au InsertLeave * highlight StatusLine ctermbg=White ctermbg=Black ctermfg=White cterm=NONE
augroup END
"Python syntax
highlight link pythonImportedObject Identifier
"HTML syntax
" highlight link htmlNoSpell
"Popup menu
highlight Pmenu     ctermbg=NONE    ctermfg=White cterm=NONE
highlight PmenuSel  ctermbg=Magenta ctermfg=Black cterm=NONE
highlight PmenuSbar ctermbg=NONE    ctermfg=Black cterm=NONE
"Status line
highlight StatusLine ctermbg=Black ctermfg=White cterm=NONE
"Create dummy group -- will be transparent, but use to add @Nospell
highlight Dummy ctermbg=NONE ctermfg=NONE
"Magenta is uncommon color, so change this
"Note if Sneak undefined, this won't raise error; vim thinkgs maybe we will define it later
highlight Sneak  ctermbg=DarkMagenta ctermfg=NONE
"And search/highlight stuff; by default foreground is black, make it transparent
highlight Search ctermbg=Magenta     ctermfg=NONE
"Fundamental changes, move control from LightColor to Color and DarkColor, because
"ANSI has no control over light ones it seems.
"Generally 'Light' is NormalColor and 'Normal' is DarkColor
highlight Type        ctermbg=NONE ctermfg=DarkGreen
highlight Constant    ctermbg=NONE ctermfg=Red
highlight Special     ctermbg=NONE ctermfg=DarkRed
highlight PreProc     ctermbg=NONE ctermfg=DarkCyan
highlight Indentifier ctermbg=NONE ctermfg=Cyan cterm=Bold
"Make Conceal highlighting group ***transparent***, so that when you
"set the conceallevel to 0, concealed elements revert to their original highlighting.
highlight Conceal    ctermbg=NONE  ctermfg=NONE ctermbg=NONE  ctermfg=NONE
"Special characters
highlight Comment    ctermfg=Black cterm=NONE
highlight NonText    ctermfg=Black cterm=NONE
highlight SpecialKey ctermfg=Black cterm=NONE
"Matching parentheses
highlight Todo       ctermfg=NONE  ctermbg=Red
highlight MatchParen ctermfg=NONE ctermbg=Blue
"Cursor line or column highlighting using color mapping set by CTerm (PuTTY lets me set
"background to darker gray, bold background to black, 'ANSI black' to a slightly lighter
"gray, and 'ANSI black bold' to black). Note 'lightgray' is just normal white
set cursorline
highlight LineNR       cterm=NONE ctermbg=NONE ctermfg=Black
highlight CursorLine   cterm=NONE ctermbg=Black
highlight CursorLineNR cterm=NONE ctermbg=Black ctermfg=White
"Column stuff; color 80th column, and after 120
highlight ColorColumn  cterm=NONE ctermbg=Gray
highlight SignColumn  guibg=NONE cterm=NONE ctermfg=Black ctermbg=NONE
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
command! -nargs=? Syntax call <sid>syntax(<q-args>)
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
  execute 'split $VIMRUNTIME/ftplugin/'.&ft.'.vim'
  silent SimpleSetup
endfunction
function! s:ftsyntax()
  execute 'split $VIMRUNTIME/syntax/'.&ft.'.vim'
  silent SimpleSetup
endfunction
command! PluginFile call <sid>ftplugin()
command! SyntaxFile call <sid>ftsyntax()
"Window displaying all colors
function! s:colors()
  source $VIMRUNTIME/syntax/colortest.vim
  silent SimpleSetup
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
"Warning: On cheyenne, get lalloc error when calling WipeReg, strange
" command! WipeReg let regs='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"' | let i=0 | while i<strlen(regs) | exec 'let @'.regs[i].'=""' | let i=i+1 | endwhile | unlet regs
if $HOSTNAME !~ 'cheyenne'
  command! WipeReg for i in range(34,122) | silent! call setreg(nr2char(i), '') | silent! call setreg(nr2char(i), []) | endfor
  WipeReg
endif
noh     "turn off highlighting at startup
redraw! "weird issue sometimes where statusbar disappears
