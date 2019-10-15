"-----------------------------------------------------------------------------"
" Massive script that configures various vim-plug loaded plugs
" It requires some global functions loaded in the vimrc
"-----------------------------------------------------------------------------"
" Helper funcs
if !exists('g:plugs')
  finish
endif
function! PlugActive(key)
  return has_key(g:plugs, a:key) " change if (e.g.) switch plugin managers
endfunction

" Custom plugins
" Mappings for vim-idetools command
if PlugActive('vim-idetools') || &rtp =~ 'vim-idetools'
  nnoremap <silent> <Leader>C :DisplayTags<CR>:redraw!<CR>
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

" Vim surround
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

" Text objects
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

" Fugitive command aliases
" Just want to eliminate that annoying fucking capital G
if PlugActive('vim-fugitive')
  for gcommand in ['Gcd', 'Glcd', 'Gstatus', 'Gcommit', 'Gmerge', 'Gpull',
   \ 'Grebase', 'Gpush', 'Gfetch', 'Grename', 'Gdelete', 'Gremove', 'Gblame', 'Gbrowse',
   \ 'Ggrep', 'Glgrep', 'Glog', 'Gllog', 'Gedit', 'Gsplit', 'Gvsplit', 'Gtabedit', 'Gpedit',
   \ 'Gread', 'Gwrite', 'Gwq', 'Gdiff', 'Gsdiff', 'Gvdiff', 'Gmove']
    exe 'cnoreabbrev g'.gcommand[1:].' '.gcommand
  endfor
endif

" Git gutter
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

" Codi (mathematical notepad)
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

" Neocomplete
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

" NERDCommenter
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

" Syntastic
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

" Tabular
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

" Refresh file
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

" Session management
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
