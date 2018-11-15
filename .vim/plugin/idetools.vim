"------------------------------------------------------------------------------"
" Author: Luke Davis (lukelbd@gmail.com)
" Date: 2018-09-09
"Copy of unimpaired.vim from Tim Pope, and many custom features including
"ctags integration, scope-searching, and refactoring tools.
"------------------------------------------------------------------------------"
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
let g:tags_top = {
  \ '.vimrc'  : 'a',
  \ 'vim'     : 'afc',
  \ 'tex'     : 'bs',
  \ 'python'  : 'fcm',
  \ 'fortran' : 'smfp',
  \ 'default' : 'f',
  \ }
"List of files for which we only want not just the 'top level' tags (i.e. tags
"that do not belong to another block, e.g. a program or subroutine)
"Note: In future, may want to only filter tags belonging to specific
"group (e.g. if tag belongs to a 'program', ignore it).
let g:fts_all = ['fortran']

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
  return "ctags ".flags." ".shellescape(expand('%:p'))." 2>/dev/null | cut -d '\t' -f1,3-5 "
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
  elseif has_key(g:tags_top, &ft)
    let cats=g:tags_top[&ft]
  else
    let cats=g:tags_top['default']
  endif
  let b:ctags_top=filter(deepcopy(b:ctags_line),
    \ 'v:val[2]=~"['.cats.']" && ('.index(g:fts_all,&ft).'!=-1 || len(v:val)==3)')
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
nnoremap <silent> <Space><Space> :call fzf#run({'source': <sid>ctagmenu(b:ctags_alph), 'sink': function('<sid>ctagjump'), 'down': '~20%'})<CR>

"------------------------------------------------------------------------------"
"Next tools for using ctags to approximate variable scope
"------------------------------------------------------------------------------"
"Define simple function for jumping between these boundaries
function! s:ctagbracket(foreward, n)
  if !exists("b:ctags_top") || len(b:ctags_top)==0
    echohl WarningMsg | echom "Warning: ctags unavailable." | echohl None
    return line('.') "stay on current line if failed
  endif
  let ctaglines=map(deepcopy(b:ctags_top),'v:val[1]')
  let njumps=(a:n==0 ? 1 : a:n)
  for i in range(njumps)
    let lnum=line('.')
    "Edge cases; at bottom or top of document
    if lnum<b:ctags_top[0][1] || lnum>b:ctags_top[-1][1]
      let idx=(a:foreward ? 0 : -1)
    "Extra case not handled in main loop
    elseif lnum==b:ctags_top[-1][1]
      let idx=(a:foreward ? 0 : -2)
    "Main loop
    else
      for i in range(len(b:ctags_top)-1)
        if lnum==b:ctags_top[i][1]
          let idx=(a:foreward ? i+1 : i-1) | break
        elseif lnum>b:ctags_top[i][1] && lnum<b:ctags_top[i+1][1]
          let idx=(a:foreward ? i+1 : i) | break
        endif
        if i==len(b:ctags_top)-1
          echohl WarningMsg | "Error: Bracket jump failed." | echohl None | return line('.')
        endif
      endfor
    endif
  endfor
  echo 'Tag: '.b:ctags_top[idx][0]
  return b:ctags_top[idx][1]
endfunction

"Now define the maps
"Declare another useful map to jump to definition of key under cursor
nnoremap <CR> gd
function! s:ctagbracketmaps()
  if exists('g:tags_ignore') && index(g:tags_ignore, &ft)!=-1
    return
  endif
  noremap <expr> <buffer> <silent> [t <sid>ctagbracket(0,'.v:count.').'gg'
  noremap <expr> <buffer> <silent> [[ <sid>ctagbracket(0,'.v:count.').'gg'
  noremap <expr> <buffer> <silent> ]t <sid>ctagbracket(1,'.v:count.').'gg'
  noremap <expr> <buffer> <silent> ]] <sid>ctagbracket(1,'.v:count.').'gg'
  " if exists('g:has_nowait') && g:has_nowait
  " noremap <nowait> <expr> <buffer> <silent> [ <sid>ctagbracket(0,'.v:count.').'gg'
  " noremap <nowait> <expr> <buffer> <silent> ] <sid>ctagbracket(1,'.v:count.').'gg'
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
"Note the @/ sets the 'last search' register to this string value
nnoremap <silent> # :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>lB:set hlsearch<CR>
nnoremap <silent> @ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>lB:set hlsearch<CR>
"Remap g/ for function-wide searching; similar convention to other commands
"Note the <silent> will prevent beginning the search until another key is pressed
nnoremap <silent> g/ /<C-r>=<sid>scopesearch(0)<CR>
nnoremap <silent> g? ?<C-r>=<sid>scopesearch(0)<CR>
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
" * Note don't need 'c?', since if you want a function local string replacement, just
"   run 'g/' to select your text, then c/, d/, ca/, da/, et cetera. Same exact result.
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
