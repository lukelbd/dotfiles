"------------------------------------------------------------------------------"
"Plugin by Luke Davis <lukelbd@gmail.com> 
"Tries to wrap a few related features into one plugin file,
"including super cool and useful ***refactoring*** tools based on ctags:
" * Ctags integration -- jumping between successive tags, jumping to a particular
"   tag based on its regex, searching/replacing text blocks delimited by the
"   lines on which tags appear (roughly results in function-local search).
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
let g:has_ctags = str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))
if !g:has_ctags
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
let g:tags_scope={
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
function! s:ctagcmd(...)
  let flags=(a:0 ? a:1 : '') "extra flags
  return "ctags --langmap=vim:+.vimrc,sh:+.bashrc ".flags." "
    \."-f - ".expand('%:p')." | cut -d '\t' -f1,3-4 "
  " \." | command grep '^[^\t]*\t".expand('%:p')."' "this filters to only tags from 'this file'
endfunction

"Miscellaneous tool; just provides a nice display of tags with text
"from the actual line
function! s:ctagsdisplay()
  exe "!clear; ".s:ctagcmd()." "
  \." | tr -s ' ' | sed '".'s$/\(.\{0,60\}\).*/;"$/\1.../$'."' "
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
  "To filter by category, use: filter(b:ctags, 'v:val[-1]=="<category>"')
  if exists('g:tags_ignore') && index(g:tags_ignore, &ft)!=-1
    return "variable contining filetypes where we don't want to generate tags
  endif
  let flags=(getline(1)=~'#!.*python[23]' ? '--language=python' : '')
  let ctags=map(split(system(s:ctagcmd(flags.' -n')." | sed 's/;\"\t/\t/g'"), '\n'), "split(v:val,'\t')")
  let b:ctags_alph=sort(deepcopy(ctags), 's:alphsort')
  let b:ctags_line=sort(deepcopy(ctags), 's:linesort')
  "Next determine
  if has_key(g:tags_scope, expand('%:t'))
    let cats=g:tags_scope[expand('%:t')]
  elseif has_key(g:tags_scope,&ft)
    let cats=g:tags_scope[&ft]
  else
    let cats=g:tags_scope['default']
  endif
  let b:ctags_scope=filter(deepcopy(b:ctags_line), 'v:val[-1]=~"['.cats.']"')
endfunction
command! ReadTags call <sid>ctagsread()

"------------------------------------------------------------------------------"
"Selecting tags by regex
"------------------------------------------------------------------------------"
"Check out fzf examples page for how we designed the below function:
"https://github.com/junegunn/fzf/wiki/Examples-(vim)
function! s:ctagmenu(ctaglist) "returns nicely formatted string
  return map(deepcopy(a:ctaglist), 'printf("%4d", v:val[-2]).": ".v:val[0]." (".v:val[-1].")"')
endfunction
function! s:ctagjump(ctag) "split by multiple whitespace, get the line number (comes after the colon)
  exe split(a:ctag, '\s\+')[0][:-2]
endfunction
noremap <Leader><Space> :call fzf#run({'source': <sid>ctagmenu(b:ctags_alph), 'sink': funcref('<sid>ctagjump'), 'down': '~20%'})<CR>

"------------------------------------------------------------------------------"
"Next tools for using ctags to approximate variable scope
"------------------------------------------------------------------------------"
"Define simple function for jumping between these boundaries
function! s:ctagbracket(foreward, n)
  if !exists("b:ctags_scope") || len(b:ctags_scope)==0
    echohl WarningMsg | echom "Warning: ctags unavailable." | echohl None
    return
  endif
  let ctaglines=map(b:ctags_scope,'v:val[-2]')
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
    return "means this 
  endif
  if g:has_nowait
    noremap <nowait> <expr> <buffer> <silent> [ <sid>ctagbracket(0,'.v:count.').'gg'
    noremap <nowait> <expr> <buffer> <silent> ] <sid>ctagbracket(1,'.v:count.').'gg'
  else
    noremap <expr> <buffer> <silent> [[ <sid>ctagbracket(0,'.v:count.').'gg'
    noremap <expr> <buffer> <silent> ]] <sid>ctagbracket(1,'.v:count.').'gg'
  endif
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
  if !exists("b:ctaglines_file") || len(b:ctaglines_file)==0
    echohl WarningMsg | echo "Warning: Tags unavailable, so cannot limit search scope." | echohl None
    return ""
  endif
  let start=line('.')
  let ctaglines=b:ctaglines_file+[line('$')]
  "Return values
  "%% is literal % character
  "Check out %l atom documentation; note it last atom selects *above* that line (so increment by one)
  "and first atom selects *below* that line (so decrement by 1)
  for i in range(0,len(ctaglines)-2)
    if ctaglines[i]<=start && ctaglines[i+1]>start "must be line above start of next function
      echom "Scopesearch selected lines ".ctaglines[i]." to ".(ctaglines[i+1]-1)."."
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
"Try again with grep; way easier, but ugly
nnoremap <silent> <Leader>* :echo system('grep -c "\b'
  \.expand('<cword>').'\b" '.expand('%').' \| xargs')<CR>

"------------------------------------------------------------------------------"
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

"------------------------------------------------------------------------------"
"Remap ? for function-wide searching; follows convention of */# and &/@
"The \(\) makes text after the scope-atoms a bit more readable
"Also note the <silent> will prevent beginning the search until another key is pressed
nnoremap <silent> ? /<C-r>=<sid>scopesearch(0)<CR>\(\)\(\)\(\)
"Map to search by character; never use default ! map so why not!
"by default ! waits for a motion, then starts :<range> command
nnoremap <silent> ! ylh/<C-r>=escape(@",'/\')<CR><CR>

"------------------------------------------------------------------------------"
"Next a magical function; performs n<dot>n<dot>n style replacement in one keystroke
"Script found here: https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
"Script referenced here: https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
augroup refactor_tool
  au!
  au InsertLeave * call MoveToNext() "magical c* searching function
augroup END
let g:inject_replace_occurences=0
let g:iterate_occurences=0
function! MoveToNext()
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
nnoremap <silent> <Plug>ReplaceOccurences :call ReplaceOccurence()<CR>
function! ReplaceOccurence()
  "Check if we are on top of an occurence
  "'[ and '] are first/last characters of previously yanked or changed text
  "Ctrl-a in insert mode types the same text as when you were last in insert mode; see :help i_
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
"Remap as above, but for substituting stuff
"These ones I made all by myself! Added a block to MoveToNext function
nmap ca/ :let g:iterate_occurences=1<CR>c/
nmap ca* :let g:iterate_occurences=1<CR>c*
nmap ca& :let g:iterate_occurences=1<CR>c&
nmap ca# :let g:iterate_occurences=1<CR>c#
nmap ca@ :let g:iterate_occurences=1<CR>c@

"------------------------------------------------------------------------------"
"Next, similar to above, but use these for *deleting* text
"Don't require that annoying wrapper
" * Note that omitting the g means only *first* occurence is replaced
"   if use %, would replace first occurence on every line
" * Options for accessing register in vimscript, where we can't immitate user <C-r> keystroke combination:
"     exe 's/'.@/.'//' OR exe 's/'.getreg('/').'//'
" * Use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on empty lines
" function! s:plugfactory(plugname, )
" endfunction
" command! -nargs=1 PlugFactory call <sid>plugfactory('<args>')
"TODO: Fix annoying issue where stuff still gets deleted after no more variables are left
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

"------------------------------------------------------------------------------"
"Finally, remap as above, but for substituting stuff
"Want the interactivity of changing text inside the document (rather than
"command line at the bottom), but that would require weird integration with repeat#set
"if it weren't for this strange function
function! s:refactor_all(command)
  "Make sure to use existing mappings (i.e. no 'normal!')
  let winview=winsaveview()
  exe 'normal '.a:command
  while search(@/, 'n') "while result is non-zero, i.e. matches exist
    exe 'normal .'
  endwhile
  echo "Deleted all occurences."
  call winrestview(winview)
endfunction
"Explicit is better than implicit
nmap da/ :call <sid>refactor_all('d/')<CR>
nmap da* :call <sid>refactor_all('d*')<CR>
nmap da& :call <sid>refactor_all('d&')<CR>
nmap da# :call <sid>refactor_all('d#')<CR>
nmap da@ :call <sid>refactor_all('d@')<CR>

