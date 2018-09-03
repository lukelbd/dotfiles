"------------------------------------------------------------------------------"
"Plugin by Luke Davis <lukelbd@gmail.com> 
"Tries to wrap a few related features into one plugin file,
"including super cool and useful ***refactoring*** tools based on ctags:
" * Ctags integration -- jumping between successive tags, jumping to a particular
"   tag based on its regex, searching/replacing text blocks delimited by the
"   lines on which tags appear (roughly results in function-local search).
"   Each element of the b:ctags list (and similar lists) is as follows:
"     Index 0: Tag name.
"     Index 1: Tag line number.
"     Index 2: Tag type.
" * Made my own implementation instead of using easytags or gutentags, because
"   (1) find that :tag and :pop are not that useful outside of help menus --
"   generally only want to edit one file at a time, and the <C-]> is about as
"   reliable as gd or gD, and (2) now I can filter the most important tags
"   and make them searchable, without losing the completion popup you'd get
"   from :tagjump /<Tab>.
" * General searching/replacing utilities, useful for refactoring. A convervative
"   approach is taken for the most part -- global searches are not automatic. But
"   could expand functionality by adding s*, s# maps to go along with c*, c# maps,
"   which replace every choice without user confirmation. Or C*, C# would work.
" * Re-define a few of the shift-number row keys to make them a bit more useful:
"     '*' is the current word, global
"     '&' is the current WORD, global
"     '#' is the current word, global
"     '@' is the current WORD, global
"   This made sense for my workflow because I never really want the backward
"   search from '#', access my macros with the comma key instead of @, and the
"   & key goes pretty much untouched.
" * For c* and c# map origin, see:
"   https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
"   https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
" * For repeat.vim usage see: http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
"Todo: Make sure python2 and python3 shebangs work
"Maybe re-implement: if getline(1)=~"#!.*python[23]" | let force="--language=python"
"------------------------------------------------------------------------------"
call system("type ctags &>/dev/null")
if v:shell_error "exit code
  finish
endif
augroup ctags
  au!
  au BufRead,BufWritePost * call <sid>ctagsread()
  au BufEnter * call <sid>ctagbracketmaps()
augroup END
set tags=./.vimtags "if ever go back to using files, want these settings
set cpoptions+=d

"------------------------------------------------------------------------------"
"Options
"Files that we wish to ignore
let g:tags_ignore=['help', 'rst', 'qf', 'diff', 'man', 'nerdtree', 'tagbar']
"List of per-file/per-filetype tag categories that we define as 'scope-delimiters',
"i.e. tags approximately denoting boundaries for variable scope of code block underneath cursor
let g:tags_top={
  \ '.vimrc'  : 'a',
  \ 'vim'     : 'afc',
  \ 'tex'     : 'bs',
  \ 'python'  : 'fcm',
  \ 'fortran' : 'smfp',
  \ 'default' : 'f',
  \ }

"------------------------------------------------------------------------------"
"The below contains super cool ctags functions that are way better than
"any existing plugin; they power many of the features below
"------------------------------------------------------------------------------"
"Handy autocommands to update and dislay tags
nnoremap <silent> <Leader>c :DisplayTags<CR>:redraw!<CR>
nnoremap <silent> <Leader>C :ReadTags<CR>

"Function for generating command-line exe that prints taglist to stdout
"We call ctags in number mode (i.e. return line number instead of search pattern)
"To add global options, modify ~/.ctags
function! s:ctagcmd(...)
  let flags=(a:0 ? a:1 : '') "extra flags
  return "ctags ".flags." ".shellescape(expand('%:p'))." 2>/dev/null | cut -d '\t' -f1,3-4 "
  " \." | command grep '^[^\t]*\t".expand('%:p')."' "this filters to only tags from 'this file'
endfunction

"Miscellaneous tool; just provides a nice display of tags
"Used to show the regexes instead of -n mode; the below sed was used to parse them nicely
" | tr -s ' ' | sed '".'s$/\(.\{0,60\}\).*/;"$/\1.../$'."' "
function! s:ctagsdisplay()
  exe "!clear; ".s:ctagcmd()." "
  \." | tr -s '\t' | column -t -s '\t' | less"
endfunction
command! DisplayTags call <sid>ctagsdisplay()

"Next a function that generates ctags and parses them into list of lists
"Note multiple tags on same line is *very* common; try the below in a model src folder:
"for f in <pattern>; do echo $f:; ctags -f - -n $f | cut -d $'\t' -f3 | cut -d\; -f1 | sort -n | uniq -c | cut -d' ' -f4 | uniq; done
function! s:linesort(tag1, tag2) "default sorting is always alphabetical, with type coercion; must use this!
  let num1=a:tag1[1]
  let num2=a:tag2[1]
  return num1 - num2 "fits requirements
endfunc
function! s:alphsort(tag1, tag2) "from this page: https://vi.stackexchange.com/a/11237/8084
  let str1=a:tag1[0]
  let str2=a:tag2[0]
  return (str1<str2 ? -1 : str1==str2 ? 0 : 1) "equality, lesser, and greater
endfunction
function! s:ctagsread()
  "First get simple list of lists; tag properties sorted alphabetically by
  "identifier, and numerically by line number
  "* To filter by category, use: filter(b:ctags, 'v:val[2]=="<category>"')
  "* First bail out if filetype is bad
  if exists('g:tags_ignore') && index(g:tags_ignore, &ft)!=-1
    return
  endif
  let flags=(getline(1)=~'#!.*python[23]' ? '--language-force=python' : '')
  "Call system command
  "Warning: In MacVim, instead what gets called is:
  "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ctags"
  "and then for some reason ctags can't accept -n flag or --excmd=number flag.
  "Warning: To test if ctags worked, want exit status of *first* command in pipeline (i.e. ctags)
  "but instead we get cut/sed statuses. If ctags returns error
  let ctags=map(split(system(s:ctagcmd(flags)." | sed 's/;\"\t/\t/g'"), '\n'), "split(v:val,'\t')")
  if len(ctags)==0 || len(ctags[0])==0 "don't want warning message for files without tags!
    return
    "echohl WarningMsg | echom "Warning: ctags unavailable." | echohl None
  endif
  let b:ctags_alph=sort(deepcopy(ctags), 's:alphsort') "sort numerically by *position 1* in the sub-arrays
  let b:ctags_line=sort(deepcopy(ctags), 's:linesort') "sort alphabetically by *position 0* in the sub-arrays
  "Next filter the tags sorted by line to include only a few limited categories
  "Will also filter to pick only ***top-level*** items (i.e. tags with global scope)
  if has_key(g:tags_top, expand('%:t'))
    let cats=g:tags_top[expand('%:t')]
  elseif has_key(g:tags_top,&ft)
    let cats=g:tags_top[&ft]
  else
    let cats=g:tags_top['default']
  endif
  let b:ctags_top=filter(deepcopy(b:ctags_line), 'len(v:val)==3 && v:val[2]=~"['.cats.']"')
endfunction
command! ReadTags call <sid>ctagsread()

"------------------------------------------------------------------------------"
"Selecting tags by regex
"------------------------------------------------------------------------------"
"Check out fzf examples page for how we designed the below function:
"https://github.com/junegunn/fzf/wiki/Examples-(vim)
"First generate list of strings that will be used for fzf menu; will be of either of these formats:
"<line number>: name (type)
"<line number>: name (type, scope)
function! s:ctagmenu(ctaglist) "returns nicely formatted string
  return map(deepcopy(a:ctaglist), 'printf("%4d", v:val[1]).": ".v:val[0]." (".join(v:val[2:],", ").")"')
endfunction
"Next function to parse user's menu selection/get the line number, and jump to it
function! s:ctagjump(ctag) "split by multiple whitespace, get the line number (comes after the colon)
  exe split(a:ctag, '\s\+')[0][:-2]
endfunction
noremap <silent> <Leader><Space> :call fzf#run({'source': <sid>ctagmenu(b:ctags_alph), 'sink': function('<sid>ctagjump'), 'down': '~20%'})<CR>

"------------------------------------------------------------------------------"
"Next tools for using ctags to approximate variable scope
"------------------------------------------------------------------------------"
"Define simple function for jumping between these boundaries
function! s:ctagbracket(foreward, n)
  if !exists("b:ctags_top") || len(b:ctags_top)==0
    echohl WarningMsg | echom "Warning: ctags unavailable." | echohl None
    return
  endif
  let ctaglines=map(deepcopy(b:ctags_top),'v:val[-2]')
  let njumps=(a:n==0 ? 1 : a:n)
  for i in range(njumps)
    let lnum=line('.')
    "Edge cases; at bottom or top of document
    if lnum<ctaglines[0] || lnum>ctaglines[-1]
      let i=(a:foreward ? 0 : -1)
    "Extra case not handled in main loop
    elseif lnum==ctaglines[-1]
      let i=(a:foreward ? 0 : -2)
    "Main loop
    else
      for i in range(len(ctaglines)-1)
        if lnum==ctaglines[i]
          let i=(a:foreward ? i+1 : i-1) | break
        elseif lnum>ctaglines[i] && lnum<ctaglines[i+1]
          let i=(a:foreward ? i+1 : i) | break
        endif
        if i==len(ctaglines)-1
          echohl WarningMsg | "Error: Bracket jump failed." | echohl None
        endif
      endfor
    endif
    return ctaglines[i] "just return the line number
  endfor
endfunction

"Now define the maps, and declare another useful map to jump to definition of key under cursor
nnoremap <CR> gd
function! s:ctagbracketmaps()
  if exists('g:tags_ignore') && index(g:tags_ignore, &ft)!=-1
    return
  endif
  noremap <expr> <buffer> <silent> [t <sid>ctagbracket(0,'.v:count.').'gg'
  noremap <expr> <buffer> <silent> ]t <sid>ctagbracket(1,'.v:count.').'gg'
  " if exists('g:has_nowait') && g:has_nowait
  "   noremap <nowait> <expr> <buffer> <silent> [ <sid>ctagbracket(0,'.v:count.').'gg'
  "   noremap <nowait> <expr> <buffer> <silent> ] <sid>ctagbracket(1,'.v:count.').'gg'
endfunction

"------------------------------------------------------------------------------"
"Searching/replacing/changing in-between tags
"------------------------------------------------------------------------------"
"Searching within scope of current function or environment
" * Search func idea came from: http://vim.wikia.com/wiki/Search_in_current_function
" * Below is copied from: https://stackoverflow.com/a/597932/4970632
" * Note jedi-vim 'variable rename' is sketchy and fails; should do my own
"   renaming, and do it by confirming every single instance
function! s:scopesearch(command)
  "Test out scopesearch
  let ntext=10 "text length
  if !exists("b:ctags_top") || len(b:ctags_top)==0
    echohl WarningMsg | echo "Warning: Tags unavailable, so cannot limit search scope." | echohl None
    return ""
  endif
  let start=line('.')
  let ctaglines=map(deepcopy(b:ctags_top), 'v:val[1]') "just pick out the line number
  let ctaglines=ctaglines+[line('$')]
  "Return values
  "%% is literal % character
  "Check out %l atom documentation; note it last atom selects *above* that line (so increment by one)
  "and first atom selects *below* that line (so decrement by 1)
  for i in range(0,len(ctaglines)-2)
    if ctaglines[i]<=start && ctaglines[i+1]>start "must be line above start of next function
      let text=b:ctags_top[i][0]
      if len(text)>=ntext
        let text=text[:ntext-1].'...'
      endif
      " echom 'Scopesearch selected lines '.ctaglines[i].' to '.(ctaglines[i+1]-1).'.'
      echom 'Scopesearch selected line '.ctaglines[i].' ('.text.') to '.(ctaglines[i+1]-1).'.'
      if a:command | return printf('%d,%ds', ctaglines[i]-1, ctaglines[i+1]) "range for :line1,line2s command
      else | return printf('\%%>%dl\%%<%dl', ctaglines[i]-1, ctaglines[i+1])
      endif
    endif
  endfor
  echohl WarningMsg | echom "Warning: Scopesearch failed to limit search scope." | echohl None
  return "" "empty string; will not limit scope anymore
endfunction

"------------------------------------------------------------------------------"
"Magical refactoring tools
"------------------------------------------------------------------------------"
"Display number of occurrences of word under cursor
nnoremap <silent> <Leader>* :echo 'Number of occurences: '.system('grep -c "\b'.expand('<cword>').'\b" '.expand('%').' \| xargs')<CR>

"Make */# search global/function-local <cword>, and &/@ the same for <cWORD>s
"Note by default '&' repeats last :s command
" * Also give cWORDs their own 'boundaries' -- do this by using \_s
"   which matches an EOL (from preceding line or this line) *or* whitespace
" * Use ':let @/=STUFF<CR>' instead of '/<C-r>=STUFF<CR><CR>' because this prevents
"   cursor from jumping around right away, which is more betterer
nnoremap <silent> * :let @/='\<'.expand('<cword>').'\>\C'<CR>lb:set hlsearch<CR>
nnoremap <silent> & :let @/='\_s\@<='.expand('<cWORD>').'\ze\_s\C'<CR>lB:set hlsearch<CR>
"Equivalent of * and # (each one key to left), but limited to function scope
nnoremap <silent> # :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>lB:set hlsearch<CR>
nnoremap <silent> @ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>lB:set hlsearch<CR>
  "note the @/ sets the 'last search' register to this string value

"Remap ? for function-wide searching; follows convention of */# and &/@
"Also note the <silent> will prevent beginning the search until another key is pressed
nnoremap <silent> ? /<C-r>=<sid>scopesearch(0)<CR>
"Map to search by character; never use default ! map so why not!
"by default ! waits for a motion, then starts :<range> command
nnoremap <silent> ! ylh/<C-r>=escape(@",'/\')<CR><CR>

"------------------------------------------------------------------------------"
"Next a magical function; performs n<dot>n<dot>n style replacement in one keystroke
"Script found here: https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
"Script referenced here: https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
augroup refactor_tool
  au!
  au InsertLeave * call <sid>move_to_next() "magical c* searching function
augroup END

"First a function for jumping to next occurence automatically
let g:inject_replace_occurences=0
let g:iterate_occurences=0
function! s:move_to_next()
  if g:iterate_occurences
    let winview=winsaveview()
    while search(@/, 'n') "while result is non-zero, i.e. matches exist
      exe 'normal .'
    endwhile
    echo "Replaced all occurences."
    let g:iterate_occurences=0
    call winrestview(winview)
  elseif g:inject_replace_occurences
    " silent! call feedkeys("n")
    keepjumps silent! normal n
    call repeat#set("\<Plug>ReplaceOccurences")
    "n is not a 'dot' command, so the default last operation was the changing
    "inner word action. calling repeat#set says this plug map will be run when
    "the <dot> key is pressed next -- but, the insert stuff will also be run
    "see the source code for more information
  endif
  let g:inject_replace_occurences=0
endfunction

"Check if we are on top of an occurence
"'[ and '] are first/last characters of previously yanked or changed text
"Ctrl-a in insert mode types the same text as when you were last in insert mode; see :help i_
function! s:replace_occurence()
  let winview = winsaveview()
  let save_reg = getreg('"')
  let save_regmode = getregtype('"')
  let [lnum_cur, col_cur] = getpos(".")[1:2] 
  keepjumps normal! ygn
  let [lnum1, col1] = getpos("'[")[1:2]
  let [lnum2, col2] = getpos("']")[1:2]
  call setreg('"', save_reg, save_regmode)
  call winrestview(winview)
  "If we are on top of an occurence, replace it
  if lnum_cur>=lnum1 && lnum_cur<=lnum2 && col_cur>=col1 && col_cur<=col2
    exe "silent! keepjumps normal! cgn\<C-a>\<Esc>"
  endif
  " silent! call feedkeys("n")
  silent! normal n
  call repeat#set("\<Plug>ReplaceOccurences")
endfunction

"Remaps using black magic
" * First one just uses last search, the other ones use word under cursor
" * Note gn and gN move to next hlsearch, then *visually selects it*, so cgn says to change in this selection
nnoremap <silent> c/ :set hlsearch<CR>
      \:let g:inject_replace_occurences=1<CR>cgn
nnoremap <silent> c* :let @/='\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
      \:let g:inject_replace_occurences=1<CR>cgn
nnoremap <silent> c& :let @/='\_s\@<='.expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
      \:let g:inject_replace_occurences=1<CR>cgn
nnoremap <silent> c# :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
      \:let g:inject_replace_occurences=1<CR>cgn
nnoremap <silent> c@ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
      \:let g:inject_replace_occurences=1<CR>cgn
nnoremap <silent> <Plug>ReplaceOccurences :call <sid>replace_occurence()<CR>

"Remap as above, but this time replace ***all*** occurrences
"These ones I made all by myself! Added a block to move_to_next function
nmap ca/ :let g:iterate_occurences=1<CR>c/
nmap ca* :let g:iterate_occurences=1<CR>c*
nmap ca& :let g:iterate_occurences=1<CR>c&
nmap ca# :let g:iterate_occurences=1<CR>c#
nmap ca@ :let g:iterate_occurences=1<CR>c@

"------------------------------------------------------------------------------"
"Next, similar to above, but use these for *deleting* text
"Doesn't require the fancy wrapper
"------------------------------------------------------------------------------"
" * Note that omitting the g means only *first* occurence is replaced
"   if use %, would replace first occurence on every line
" * Options for accessing register in vimscript, where we can't immitate user <C-r> keystroke combination:
"     exe 's/'.@/.'//' OR exe 's/'.getreg('/').'//'
" * Use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on empty lines
" function! s:plugfactory(plugname, )
" endfunction
" command! -nargs=1 PlugFactory call <sid>plugfactory('<args>')
"Todo: Fix annoying issue where stuff still gets deleted after no more variables are left
function! s:delete_next()
  try "note the silent! feature fucks up try catch statements
    keepjumps normal! dgnn
    let b:delete_done=0
  catch
    echo "Replaced all occurences."
  endtry
endfunction
nnoremap <silent> <Plug>search1 :set hlsearch<CR>:call <sid>delete_next()<CR>:call repeat#set("\<Plug>search1",v:count)<CR>
nnoremap <silent> <Plug>search2 /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``:call <sid>delete_next()<CR>:call repeat#set("\<Plug>search2",v:count)<CR>
nnoremap <silent> <Plug>search3 /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``:call <sid>delete_next()<CR>:call repeat#set("\<Plug>search3",v:count)<CR>
nnoremap <silent> <Plug>search4 /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``:call <sid>delete_next()<CR>:call repeat#set("\<Plug>search4",v:count)<CR>
nnoremap <silent> <Plug>search5 /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``:call <sid>delete_next()<CR>:call repeat#set("\<Plug>search5",v:count)<CR>
nmap d/ <Plug>search1
nmap d* <Plug>search2
nmap d& <Plug>search3
nmap d# <Plug>search4
nmap d@ <Plug>search5

"Finally, remap as above, but for deleting everything
"Make sure to use existing mappings (i.e. no 'normal!')
function! s:delete_all(command)
  let winview=winsaveview()
  exe 'normal '.a:command
  while search(@/, 'n') "while result is non-zero, i.e. matches exist
    exe 'normal .'
  endwhile
  echo "Deleted all occurences."
  call winrestview(winview)
endfunction
nmap da/ :call <sid>delete_all('d/')<CR>
nmap da* :call <sid>delete_all('d*')<CR>
nmap da& :call <sid>delete_all('d&')<CR>
nmap da# :call <sid>delete_all('d#')<CR>

"------------------------------------------------------------------------------"
" Unimpaired.vim below
"------------------------------------------------------------------------------"
" unimpaired.vim - Pairs of handy bracket mappings
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      2.0
" GetLatestVimScripts: 1590 1 :AutoInstall: unimpaired.vim
" Copied: Luke Davis (lukelbd@gmail.com)
" Copied this just to disable a few default mappings.
" Also overwrite the tag mapping [t and ]t with my own

if exists("g:loaded_unimpaired") || &cp || v:version < 700
  finish
endif
let g:loaded_unimpaired = 1

let s:maps = []
function! s:map(...) abort
  call add(s:maps, copy(a:000))
endfunction

function! s:maps() abort
  for [mode, head, rhs; rest] in s:maps
    let flags = get(rest, 0, '') . (rhs =~# '^<Plug>' ? '' : '<script>')
    let tail = ''
    let keys = get(g:, mode.'remap', {})
    if type(keys) != type({})
      continue
    endif
    while !empty(head)
      if has_key(keys, head)
        let head = keys[head]
        if empty(head)
          let head = '<skip>'
        endif
        break
      endif
      let tail = matchstr(head, '<[^<>]*>$\|.$') . tail
      let head = substitute(head, '<[^<>]*>$\|.$', '', '')
    endwhile
    if head !=# '<skip>' && (flags !~? '<unique>' || empty(maparg(head.tail, mode)))
      exe mode.'map' flags head.tail rhs
    endif
  endfor
endfunction

" Section: Next and previous
function! s:MapNextFamily(map,cmd) abort
  let map = '<Plug>unimpaired'.toupper(a:map)
  let cmd = '".(v:count ? v:count : "")."'.a:cmd
  let end = '"<CR>'.(a:cmd ==# 'l' || a:cmd ==# 'c' ? 'zv' : '')
  execute 'nnoremap <silent> '.map.'Previous :<C-U>exe "'.cmd.'previous'.end
  execute 'nnoremap <silent> '.map.'Next     :<C-U>exe "'.cmd.'next'.end
  execute 'nnoremap <silent> '.map.'First    :<C-U>exe "'.cmd.'first'.end
  execute 'nnoremap <silent> '.map.'Last     :<C-U>exe "'.cmd.'last'.end
  call s:map('n', '['.        a:map , map.'Previous')
  call s:map('n', ']'.        a:map , map.'Next')
  call s:map('n', '['.toupper(a:map), map.'First')
  call s:map('n', ']'.toupper(a:map), map.'Last')
  if exists(':'.a:cmd.'nfile')
    execute 'nnoremap <silent> '.map.'PFile :<C-U>exe "'.cmd.'pfile'.end
    execute 'nnoremap <silent> '.map.'NFile :<C-U>exe "'.cmd.'nfile'.end
    call s:map('n', '[<C-'.toupper(a:map).'>', map.'PFile')
    call s:map('n', ']<C-'.toupper(a:map).'>', map.'NFile')
  elseif exists(':p'.a:cmd.'next')
    execute 'nnoremap <silent> '.map.'PPrevious :<C-U>exe "p'.cmd.'previous'.end
    execute 'nnoremap <silent> '.map.'PNext :<C-U>exe "p'.cmd.'next'.end
    call s:map('n', '[<C-'.toupper(a:map).'>', map.'PPrevious')
    call s:map('n', ']<C-'.toupper(a:map).'>', map.'PNext')
  endif
endfunction

call s:MapNextFamily('a','')
call s:MapNextFamily('b','b')
call s:MapNextFamily('l','l')
call s:MapNextFamily('q','c')
" call s:MapNextFamily('t','t') "use my own tags plugin

function! s:entries(path) abort
  let path = substitute(a:path,'[\\/]$','','')
  let files = split(glob(path."/.*"),"\n")
  let files += split(glob(path."/*"),"\n")
  call map(files,'substitute(v:val,"[\\/]$","","")')
  call filter(files,'v:val !~# "[\\\\/]\\.\\.\\=$"')

  let filter_suffixes = substitute(escape(&suffixes, '~.*$^'), ',', '$\\|', 'g') .'$'
  call filter(files, 'v:val !~# filter_suffixes')

  return files
endfunction

function! s:FileByOffset(num) abort
  let file = expand('%:p')
  if empty(file)
    let file = getcwd() . '/'
  endif
  let num = a:num
  while num
    let files = s:entries(fnamemodify(file,':h'))
    if a:num < 0
      call reverse(sort(filter(files,'v:val <# file')))
    else
      call sort(filter(files,'v:val ># file'))
    endif
    let temp = get(files,0,'')
    if empty(temp)
      let file = fnamemodify(file,':h')
    else
      let file = temp
      let found = 1
      while isdirectory(file)
        let files = s:entries(file)
        if empty(files)
          let found = 0
          break
        endif
        let file = files[num > 0 ? 0 : -1]
      endwhile
      let num += (num > 0 ? -1 : 1) * found
    endif
  endwhile
  return file
endfunction

function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

nnoremap <silent> <Plug>unimpairedDirectoryNext     :<C-U>edit <C-R>=<SID>fnameescape(fnamemodify(<SID>FileByOffset(v:count1), ':.'))<CR><CR>
nnoremap <silent> <Plug>unimpairedDirectoryPrevious :<C-U>edit <C-R>=<SID>fnameescape(fnamemodify(<SID>FileByOffset(-v:count1), ':.'))<CR><CR>
call s:map('n', ']f', '<Plug>unimpairedDirectoryNext')
call s:map('n', '[f', '<Plug>unimpairedDirectoryPrevious')

" Section: Diff
call s:map('n', '[n', '<Plug>unimpairedContextPrevious')
call s:map('n', ']n', '<Plug>unimpairedContextNext')
call s:map('o', '[n', '<Plug>unimpairedContextPrevious')
call s:map('o', ']n', '<Plug>unimpairedContextNext')

nnoremap <silent> <Plug>unimpairedContextPrevious :call <SID>Context(1)<CR>
nnoremap <silent> <Plug>unimpairedContextNext     :call <SID>Context(0)<CR>
onoremap <silent> <Plug>unimpairedContextPrevious :call <SID>ContextMotion(1)<CR>
onoremap <silent> <Plug>unimpairedContextNext     :call <SID>ContextMotion(0)<CR>

function! s:Context(reverse) abort
  call search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', a:reverse ? 'bW' : 'W')
endfunction

function! s:ContextMotion(reverse) abort
  if a:reverse
    -
  endif
  call search('^@@ .* @@\|^diff \|^[<=>|]\{7}[<=>|]\@!', 'bWc')
  if getline('.') =~# '^diff '
    let end = search('^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^@@ '
    let end = search('^@@ .* @@\|^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^=\{7\}'
    +
    let end = search('^>\{7}>\@!', 'Wnc')
  elseif getline('.') =~# '^[<=>|]\{7\}'
    let end = search('^[<=>|]\{7}[<=>|]\@!', 'Wn') - 1
  else
    return
  endif
  if end > line('.')
    execute 'normal! V'.(end - line('.')).'j'
  elseif end == line('.')
    normal! V
  endif
endfunction

" Section: Line operations
function! s:BlankUp(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>unimpairedBlankUp", a:count)
endfunction

function! s:BlankDown(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>unimpairedBlankDown", a:count)
endfunction

nnoremap <silent> <Plug>unimpairedBlankUp   :<C-U>call <SID>BlankUp(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedBlankDown :<C-U>call <SID>BlankDown(v:count1)<CR>

call s:map('n', '[<Space>', '<Plug>unimpairedBlankUp')
call s:map('n', ']<Space>', '<Plug>unimpairedBlankDown')

function! s:ExecMove(cmd) abort
  let old_fdm = &foldmethod
  if old_fdm !=# 'manual'
    let &foldmethod = 'manual'
  endif
  normal! m`
  silent! exe a:cmd
  norm! ``
  if old_fdm !=# 'manual'
    let &foldmethod = old_fdm
  endif
endfunction

function! s:Move(cmd, count, map) abort
  call s:ExecMove('move'.a:cmd.a:count)
  silent! call repeat#set("\<Plug>unimpairedMove".a:map, a:count)
endfunction

function! s:MoveSelectionUp(count) abort
  call s:ExecMove("'<,'>move'<--".a:count)
  silent! call repeat#set("\<Plug>unimpairedMoveSelectionUp", a:count)
endfunction

function! s:MoveSelectionDown(count) abort
  call s:ExecMove("'<,'>move'>+".a:count)
  silent! call repeat#set("\<Plug>unimpairedMoveSelectionDown", a:count)
endfunction

nnoremap <silent> <Plug>unimpairedMoveUp            :<C-U>call <SID>Move('--',v:count1,'Up')<CR>
nnoremap <silent> <Plug>unimpairedMoveDown          :<C-U>call <SID>Move('+',v:count1,'Down')<CR>
noremap  <silent> <Plug>unimpairedMoveSelectionUp   :<C-U>call <SID>MoveSelectionUp(v:count1)<CR>
noremap  <silent> <Plug>unimpairedMoveSelectionDown :<C-U>call <SID>MoveSelectionDown(v:count1)<CR>

call s:map('n', '[e', '<Plug>unimpairedMoveUp')
call s:map('n', ']e', '<Plug>unimpairedMoveDown')
call s:map('x', '[e', '<Plug>unimpairedMoveSelectionUp')
call s:map('x', ']e', '<Plug>unimpairedMoveSelectionDown')

" Section: Option toggling
function! s:statusbump() abort
  let &l:readonly = &l:readonly
  return ''
endfunction

function! s:toggle(op) abort
  call s:statusbump()
  return eval('&'.a:op) ? 'no'.a:op : a:op
endfunction

function! s:cursor_options() abort
  return &cursorline && &cursorcolumn ? 'nocursorline nocursorcolumn' : 'cursorline cursorcolumn'
endfunction

function! s:option_map(letter, option, mode) abort
  call s:map('n', '[o'.a:letter, ':'.a:mode.' '.a:option.'<C-R>=<SID>statusbump()<CR><CR>')
  call s:map('n', ']o'.a:letter, ':'.a:mode.' no'.a:option.'<C-R>=<SID>statusbump()<CR><CR>')
  call s:map('n', 'yo'.a:letter, ':'.a:mode.' <C-R>=<SID>toggle("'.a:option.'")<CR><CR>')
endfunction

call s:map('n', '[ob', ':set background=light<CR>')
call s:map('n', ']ob', ':set background=dark<CR>')
call s:map('n', 'yob', ':set background=<C-R>=&background == "dark" ? "light" : "dark"<CR><CR>')
call s:option_map('c', 'cursorline', 'setlocal')
call s:option_map('-', 'cursorline', 'setlocal')
call s:option_map('_', 'cursorline', 'setlocal')
call s:option_map('u', 'cursorcolumn', 'setlocal')
call s:option_map('<Bar>', 'cursorcolumn', 'setlocal')
call s:map('n', '[od', ':diffthis<CR>')
call s:map('n', ']od', ':diffoff<CR>')
call s:map('n', 'yod', ':<C-R>=&diff ? "diffoff" : "diffthis"<CR><CR>')
call s:option_map('h', 'hlsearch', 'set')
call s:option_map('i', 'ignorecase', 'set')
call s:option_map('l', 'list', 'setlocal')
call s:option_map('n', 'number', 'setlocal')
call s:option_map('r', 'relativenumber', 'setlocal')
call s:option_map('s', 'spell', 'setlocal')
call s:option_map('w', 'wrap', 'setlocal')
call s:map('n', '[ov', ':set virtualedit+=all<CR>')
call s:map('n', ']ov', ':set virtualedit-=all<CR>')
call s:map('n', 'yov', ':set <C-R>=(&virtualedit =~# "all") ? "virtualedit-=all" : "virtualedit+=all"<CR><CR>')
call s:map('n', '[ox', ':set cursorline cursorcolumn<CR>')
call s:map('n', ']ox', ':set nocursorline nocursorcolumn<CR>')
call s:map('n', 'yox', ':set <C-R>=<SID>cursor_options()<CR><CR>')
call s:map('n', '[o+', ':set cursorline cursorcolumn<CR>')
call s:map('n', ']o+', ':set nocursorline nocursorcolumn<CR>')
call s:map('n', 'yo+', ':set <C-R>=<SID>cursor_options()<CR><CR>')

function! s:legacy_option_map(letter) abort
  let y = get(get(g:, 'nremap', {}), 'y', 'y')
  return y . 'o' . a:letter . ':echo "Use ' . y . 'o' . a:letter . ' instead"' . "\<CR>"
endfunction

if empty(maparg('co', 'n'))
  nmap <silent><expr> co <SID>legacy_option_map(nr2char(getchar()))
  nnoremap cop <Nop>
endif
" if empty(maparg('=o', 'n'))
"   nmap <silent><expr> =o <SID>legacy_option_map(nr2char(getchar()))
"   nnoremap =op <Nop>
" endif

function! s:setup_paste() abort
  let s:paste = &paste
  let s:mouse = &mouse
  set paste
  set mouse=
  augroup unimpaired_paste
    autocmd!
    autocmd InsertLeave *
          \ if exists('s:paste') |
          \   let &paste = s:paste |
          \   let &mouse = s:mouse |
          \   unlet s:paste |
          \   unlet s:mouse |
          \ endif |
          \ autocmd! unimpaired_paste
  augroup END
endfunction

nnoremap <silent> <Plug>unimpairedPaste :call <SID>setup_paste()<CR>

call s:map('n', '[op', ':call <SID>setup_paste()<CR>O', '<silent>')
call s:map('n', ']op', ':call <SID>setup_paste()<CR>o', '<silent>')
call s:map('n', 'yop', ':call <SID>setup_paste()<CR>0C', '<silent>')

" Section: Put
function! s:putline(how, map) abort
  let [body, type] = [getreg(v:register), getregtype(v:register)]
  if type ==# 'V'
    exe 'normal! "'.v:register.a:how
  else
    call setreg(v:register, body, 'l')
    exe 'normal! "'.v:register.a:how
    call setreg(v:register, body, type)
    silent! call repeat#set("\<Plug>unimpairedPut".a:map)
  endif
endfunction

nnoremap <silent> <Plug>unimpairedPutAbove :call <SID>putline('[p', 'Above')<CR>
nnoremap <silent> <Plug>unimpairedPutBelow :call <SID>putline(']p', 'Below')<CR>

call s:map('n', '[p', '<Plug>unimpairedPutAbove', '<unique>')
call s:map('n', ']p', '<Plug>unimpairedPutBelow', '<unique>')
call s:map('n', '[P', '<Plug>unimpairedPutAbove')
call s:map('n', ']P', '<Plug>unimpairedPutBelow')
" call s:map('n', '>P', ":call <SID>putline('[p', 'Above')<CR>>']", '<silent>')
" call s:map('n', '>p', ":call <SID>putline(']p', 'Below')<CR>>']", '<silent>')
" call s:map('n', '<P', ":call <SID>putline('[p', 'Above')<CR><']", '<silent>')
" call s:map('n', '<p', ":call <SID>putline(']p', 'Below')<CR><']", '<silent>')
" call s:map('n', '=P', ":call <SID>putline('[p', 'Above')<CR>=']", '<silent>')
" call s:map('n', '=p', ":call <SID>putline(']p', 'Below')<CR>=']", '<silent>')

" Section: Encoding and decoding
function! s:string_encode(str) abort
  let map = {"\n": 'n', "\r": 'r', "\t": 't', "\b": 'b', "\f": '\f', '"': '"', '\': '\'}
  return substitute(a:str,"[\001-\033\\\\\"]",'\="\\".get(map,submatch(0),printf("%03o",char2nr(submatch(0))))','g')
endfunction

function! s:string_decode(str) abort
  let map = {'n': "\n", 'r': "\r", 't': "\t", 'b': "\b", 'f': "\f", 'e': "\e", 'a': "\001", 'v': "\013", "\n": ''}
  let str = a:str
  if str =~# '^\s*".\{-\}\\\@<!\%(\\\\\)*"\s*\n\=$'
    let str = substitute(substitute(str,'^\s*\zs"','',''),'"\ze\s*\n\=$','','')
  endif
  return substitute(str,'\\\(\o\{1,3\}\|x\x\{1,2\}\|u\x\{1,4\}\|.\)','\=get(map,submatch(1),submatch(1) =~? "^[0-9xu]" ? nr2char("0".substitute(submatch(1),"^[Uu]","x","")) : submatch(1))','g')
endfunction

function! s:url_encode(str) abort
  return substitute(a:str,'[^A-Za-z0-9_.~-]','\="%".printf("%02X",char2nr(submatch(0)))','g')
endfunction

function! s:url_decode(str) abort
  let str = substitute(substitute(substitute(a:str,'%0[Aa]\n$','%0A',''),'%0[Aa]','\n','g'),'+',' ','g')
  return substitute(str,'%\(\x\x\)','\=nr2char("0x".submatch(1))','g')
endfunction

" HTML entities
let g:unimpaired_html_entities = {
      \ 'nbsp':     160, 'iexcl':    161, 'cent':     162, 'pound':    163,
      \ 'curren':   164, 'yen':      165, 'brvbar':   166, 'sect':     167,
      \ 'uml':      168, 'copy':     169, 'ordf':     170, 'laquo':    171,
      \ 'not':      172, 'shy':      173, 'reg':      174, 'macr':     175,
      \ 'deg':      176, 'plusmn':   177, 'sup2':     178, 'sup3':     179,
      \ 'acute':    180, 'micro':    181, 'para':     182, 'middot':   183,
      \ 'cedil':    184, 'sup1':     185, 'ordm':     186, 'raquo':    187,
      \ 'frac14':   188, 'frac12':   189, 'frac34':   190, 'iquest':   191,
      \ 'Agrave':   192, 'Aacute':   193, 'Acirc':    194, 'Atilde':   195,
      \ 'Auml':     196, 'Aring':    197, 'AElig':    198, 'Ccedil':   199,
      \ 'Egrave':   200, 'Eacute':   201, 'Ecirc':    202, 'Euml':     203,
      \ 'Igrave':   204, 'Iacute':   205, 'Icirc':    206, 'Iuml':     207,
      \ 'ETH':      208, 'Ntilde':   209, 'Ograve':   210, 'Oacute':   211,
      \ 'Ocirc':    212, 'Otilde':   213, 'Ouml':     214, 'times':    215,
      \ 'Oslash':   216, 'Ugrave':   217, 'Uacute':   218, 'Ucirc':    219,
      \ 'Uuml':     220, 'Yacute':   221, 'THORN':    222, 'szlig':    223,
      \ 'agrave':   224, 'aacute':   225, 'acirc':    226, 'atilde':   227,
      \ 'auml':     228, 'aring':    229, 'aelig':    230, 'ccedil':   231,
      \ 'egrave':   232, 'eacute':   233, 'ecirc':    234, 'euml':     235,
      \ 'igrave':   236, 'iacute':   237, 'icirc':    238, 'iuml':     239,
      \ 'eth':      240, 'ntilde':   241, 'ograve':   242, 'oacute':   243,
      \ 'ocirc':    244, 'otilde':   245, 'ouml':     246, 'divide':   247,
      \ 'oslash':   248, 'ugrave':   249, 'uacute':   250, 'ucirc':    251,
      \ 'uuml':     252, 'yacute':   253, 'thorn':    254, 'yuml':     255,
      \ 'OElig':    338, 'oelig':    339, 'Scaron':   352, 'scaron':   353,
      \ 'Yuml':     376, 'circ':     710, 'tilde':    732, 'ensp':    8194,
      \ 'emsp':    8195, 'thinsp':  8201, 'zwnj':    8204, 'zwj':     8205,
      \ 'lrm':     8206, 'rlm':     8207, 'ndash':   8211, 'mdash':   8212,
      \ 'lsquo':   8216, 'rsquo':   8217, 'sbquo':   8218, 'ldquo':   8220,
      \ 'rdquo':   8221, 'bdquo':   8222, 'dagger':  8224, 'Dagger':  8225,
      \ 'permil':  8240, 'lsaquo':  8249, 'rsaquo':  8250, 'euro':    8364,
      \ 'fnof':     402, 'Alpha':    913, 'Beta':     914, 'Gamma':    915,
      \ 'Delta':    916, 'Epsilon':  917, 'Zeta':     918, 'Eta':      919,
      \ 'Theta':    920, 'Iota':     921, 'Kappa':    922, 'Lambda':   923,
      \ 'Mu':       924, 'Nu':       925, 'Xi':       926, 'Omicron':  927,
      \ 'Pi':       928, 'Rho':      929, 'Sigma':    931, 'Tau':      932,
      \ 'Upsilon':  933, 'Phi':      934, 'Chi':      935, 'Psi':      936,
      \ 'Omega':    937, 'alpha':    945, 'beta':     946, 'gamma':    947,
      \ 'delta':    948, 'epsilon':  949, 'zeta':     950, 'eta':      951,
      \ 'theta':    952, 'iota':     953, 'kappa':    954, 'lambda':   955,
      \ 'mu':       956, 'nu':       957, 'xi':       958, 'omicron':  959,
      \ 'pi':       960, 'rho':      961, 'sigmaf':   962, 'sigma':    963,
      \ 'tau':      964, 'upsilon':  965, 'phi':      966, 'chi':      967,
      \ 'psi':      968, 'omega':    969, 'thetasym': 977, 'upsih':    978,
      \ 'piv':      982, 'bull':    8226, 'hellip':  8230, 'prime':   8242,
      \ 'Prime':   8243, 'oline':   8254, 'frasl':   8260, 'weierp':  8472,
      \ 'image':   8465, 'real':    8476, 'trade':   8482, 'alefsym': 8501,
      \ 'larr':    8592, 'uarr':    8593, 'rarr':    8594, 'darr':    8595,
      \ 'harr':    8596, 'crarr':   8629, 'lArr':    8656, 'uArr':    8657,
      \ 'rArr':    8658, 'dArr':    8659, 'hArr':    8660, 'forall':  8704,
      \ 'part':    8706, 'exist':   8707, 'empty':   8709, 'nabla':   8711,
      \ 'isin':    8712, 'notin':   8713, 'ni':      8715, 'prod':    8719,
      \ 'sum':     8721, 'minus':   8722, 'lowast':  8727, 'radic':   8730,
      \ 'prop':    8733, 'infin':   8734, 'ang':     8736, 'and':     8743,
      \ 'or':      8744, 'cap':     8745, 'cup':     8746, 'int':     8747,
      \ 'there4':  8756, 'sim':     8764, 'cong':    8773, 'asymp':   8776,
      \ 'ne':      8800, 'equiv':   8801, 'le':      8804, 'ge':      8805,
      \ 'sub':     8834, 'sup':     8835, 'nsub':    8836, 'sube':    8838,
      \ 'supe':    8839, 'oplus':   8853, 'otimes':  8855, 'perp':    8869,
      \ 'sdot':    8901, 'lceil':   8968, 'rceil':   8969, 'lfloor':  8970,
      \ 'rfloor':  8971, 'lang':    9001, 'rang':    9002, 'loz':     9674,
      \ 'spades':  9824, 'clubs':   9827, 'hearts':  9829, 'diams':   9830,
      \ 'apos':      39}

function! s:xml_encode(str) abort
  let str = a:str
  let str = substitute(str,'&','\&amp;','g')
  let str = substitute(str,'<','\&lt;','g')
  let str = substitute(str,'>','\&gt;','g')
  let str = substitute(str,'"','\&quot;','g')
  return str
endfunction

function! s:xml_entity_decode(str) abort
  let str = substitute(a:str,'\c&#\%(0*38\|x0*26\);','&amp;','g')
  let str = substitute(str,'\c&#\(\d\+\);','\=nr2char(submatch(1))','g')
  let str = substitute(str,'\c&#\(x\x\+\);','\=nr2char("0".submatch(1))','g')
  let str = substitute(str,'\c&apos;',"'",'g')
  let str = substitute(str,'\c&quot;','"','g')
  let str = substitute(str,'\c&gt;','>','g')
  let str = substitute(str,'\c&lt;','<','g')
  let str = substitute(str,'\C&\(\%(amp;\)\@!\w*\);','\=nr2char(get(g:unimpaired_html_entities,submatch(1),63))','g')
  return substitute(str,'\c&amp;','\&','g')
endfunction

function! s:xml_decode(str) abort
  let str = substitute(a:str,'<\%([[:alnum:]-]\+=\%("[^"]*"\|''[^'']*''\)\|.\)\{-\}>','','g')
  return s:xml_entity_decode(str)
endfunction

function! s:Transform(algorithm,type) abort
  let sel_save = &selection
  let cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  let reg_save = @@
  if a:type ==# 'line'
    silent exe "normal! '[V']y"
  elseif a:type ==# 'block'
    silent exe "normal! `[\<C-V>`]y"
  else
    silent exe "normal! `[v`]y"
  endif
  if a:algorithm =~# '^\u\|#'
    let @@ = {a:algorithm}(@@)
  else
    let @@ = s:{a:algorithm}(@@)
  endif
  norm! gvp
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! s:TransformOpfunc(type) abort
  return s:Transform(s:encode_algorithm, a:type)
endfunction

function! s:TransformSetup(algorithm) abort
  let s:encode_algorithm = a:algorithm
  let &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_').'TransformOpfunc'
  return 'g@'
endfunction

function! UnimpairedMapTransform(algorithm, key) abort
  exe 'nnoremap <expr> <Plug>unimpaired_'    .a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")'
  exe 'xnoremap <expr> <Plug>unimpaired_'    .a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")'
  exe 'nnoremap <expr> <Plug>unimpaired_line_'.a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")."_"'
  call s:map('n', a:key, '<Plug>unimpaired_'.a:algorithm)
  call s:map('x', a:key, '<Plug>unimpaired_'.a:algorithm)
  call s:map('n', a:key.a:key[strlen(a:key)-1], '<Plug>unimpaired_line_'.a:algorithm)
endfunction

call UnimpairedMapTransform('string_encode','[y')
call UnimpairedMapTransform('string_decode',']y')
call UnimpairedMapTransform('url_encode','[u')
call UnimpairedMapTransform('url_decode',']u')
call UnimpairedMapTransform('xml_encode','[x')
call UnimpairedMapTransform('xml_decode',']x')

" Section: Activation
call s:maps()
