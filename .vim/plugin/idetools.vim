"------------------------------------------------------------------------------"
"Plugin by Luke Davis <lukelbd@gmail.com> 
"Tries to wrap a few related features into one plugin file,
"including super cool and useful ***refactoring*** tools:
" * For repeat.vim usage see: http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
" * CTAGS integration -- jumping between successive tags, jumping to a particular
"   tag based on its regex, searching/replacing text blocks delimited by the
"   lines on which tags appear (roughly results in function-local search)
" * General searching/replacing utilities, useful for refactoring. A convervative
"   approach is taken for the most part -- global searches are not automatic. But
"   could expand functionality by adding s*, s# maps to go along with c*, c# maps,
"   which replace every choice without user confirmation. Or C*, C# would work.
" * Re-define a few of the shift-number row keys to make them a bit more useful:
"   '*' is the current word, global
"   '&' is the current WORD, global
"   '#' is the current word, global
"   '@' is the current WORD, global
"   This made sense for my workflow because I never really want the backward
"   search from '#', access my macros with the comma key instead of @, and the
"   & key goes pretty much untouched.
" * For c* and c# map origin, see:
"   https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
"   https://www.reddit.com/r/vim/comments/2p6jqr/quick_replace_useful_refactoring_and_editing_tool/
"###############################################################################
"Check ctags is present first
"###############################################################################
let g:has_ctags  = str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))
if !g:has_ctags
  finish
endif

"###############################################################################
"Wrapper functions for useful CTAGS integration  (requires 'brew install ctags-exuberant')
"###############################################################################
" * Note that, unfortunately, tagbar doesn't have useful interface to access
"   the ctags file generated already, which is why the s:ctags function exists 
"   and this plugin doesn't simply wrap around tagbar. But ctags is very quick.
" * By default ctags are sorted alphabetically; below we put the line numbers
"   and regexes in separate lists, and sort by line number.
"Declare dem tags yo
augroup ctags
  au!
  au BufReadPost,BufWritePost * call s:ctags(0)
  au FileType * call s:ctagbracketmaps() "this is to *force* my special bracket maps to work
augroup END
"------------------------------------------------------------------------------"
"Function for declaring ctag lines and ctag regex strings, in line number order
function! s:compare(i1, i2) "default sorting is always alphabetical, with type coercion; must use this!
   return a:i1 - a:i2
endfunc
function! s:ctags(...)
  let dry_run=0
  if a:0
    let dry_run=a:1
  endif
  let b:ctags=[] "return these empty values upon error
  let b:ctaglines=[]
  let ignoretypes=["tagbar","nerdtree"]
  if index(ignoretypes, &ft)!=-1 | return | endif
  "Determine types of ctags we want to store
  if expand("%:t")==".vimrc"
    "list only augroups
    let type="a"
  elseif &ft=="vim"
    "augroups and functions
    let type="[af]"
  elseif &ft=="tex"
    "b is for subsection, s is for section
    let type="[bs]"
  elseif &ft=="python"
    "functions, classes, and modules
    let type="[fcm]"
  elseif &ft=="fortran"
    "s is for submodule, m for module, f for function, p for program
    "ignore variable declarations
    let type="[smfp]"
  else
    "default just functions; note Vimscript makes c 'command!'
    let type="f"
  endif
  "Ctags doesn't recognize python2/python3 shebangs by default
  if getline(1)=~"#!.*python[23]" | let force="--language=python"
  else | let force=""
  endif
  "Call ctags function
  "The cut ignores the filename field, and the trailing (optional) hieararchy field
  let cmd="ctags ".force." --langmap=vim:+.vimrc,sh:+.bashrc -f - ".expand("%")
      \." 2>/dev/null | cut -d '\t' -f1,3-4 "
  if dry_run | return cmd | endif
  let ctags=split(system(cmd." | grep '\t".type."$' | cut -d'/' -f2"), '\n')
  if len(ctags)==0 | return | endif
  "Get ctag lines and sort them by number
  " echom join(ctags,',')
  let ctaglines=map(deepcopy(ctags), 'search("^".escape(v:val[1:-2],"$/*[]"),"n")')
  " echom join(ctags,',')
  " echom join(ctaglines,',')
  let b:ctaglines=sort(deepcopy(ctaglines), "s:compare") "vim is object-oriented, like python
  " echom join(ctaglines,',')
  let b:ctags=map(range(len(b:ctaglines)), 'ctags[index(ctaglines, b:ctaglines[v:val])]')
endfunction "note if you use FileType below, it will fail to refresh when re-entering VIM
"Create mappings
"First one just updates tags
"Second one returns the ctags command, then does some other fancy stuff and displays
"it to the user in a temporary pager. The sed line limits the column width to 60 chars.
nnoremap <silent> <Leader>c :call <sid>ctags(0)<CR>:echom "Tags updated."<CR>
nnoremap <silent> <expr> <Leader>C ":!clear; ".<sid>ctags(1)." \| tr -s ' ' "
      \." \| sed '".'s$/\(.\{0,60\}\).*/;"$/\1.../$'."' "
      \." \| tr -s '\t' \| column -t -s '\t' "
      \." \| less<CR>:redraw!<CR>"
      " \." \| tr -s '".'\t'."' \| column -t -s '".'\t'."' \| less<CR>:redraw!<CR>"
" command! Ctags call <sid>ctags(1)
"------------------------------------------------------------------------------"
"Function for jumping between regexes in the ctag search strings
function! s:ctagjump(regex)
  if !exists("b:ctags") || len(b:ctags)==0
    echom "Warning: Ctags unavailable."
    return
  endif
  for i in range(len(b:ctags))
    let string=b:ctags[i][1:-2] "ignore leading ^ and trailing $
    if string =~? a:regex "ignores case
      ":<number><CR> travels to that line number
      exe b:ctaglines[i]
      return
    endif
  endfor
  echo "Warning: Ctag regex not found."
endfunction
function! s:ctaglist(A,B,C)
  let choices=[]
  for ctag in b:ctags
    if ctag[1:-2] =~# a:A "regex matching case
      call add(choices, substitute(ctag[1:-2], '^\s*\(.\{-}\)\s*$', '\1', '')) "ignore leading ^/$
    endif
  endfor
  return choices "super simple
endfunction
nnoremap <silent> <Leader><Space> :call <sid>ctags(0)<CR>:call <sid>ctagjump(input('Enter ctag (tab to reveal options): ', '', 'customlist,<sid>ctaglist'))<CR>
" nnmap <buffer> <Leader><Space> :TagbarOpen<CR>:wincmd l<CR>:call search(input('Enter ctag regex: '))<CR>:noh<CR>
"------------------------------------------------------------------------------"
"Next jump between subsequent ctags with [[ and ]]
function! s:ctagbracket(foreward, n)
  if &ft=="help" | return | endif
  if !exists("b:ctaglines") || len(b:ctaglines)==0 | echom "Warning: No ctags found." | return | endif
  let a:njumps=(a:n==0 ? 1 : a:n)
  for i in range(a:njumps)
    let lnum=line('.')
    "Edge cases; at bottom or top of document
    if lnum<b:ctaglines[0] || lnum>b:ctaglines[-1]
      let i=(a:foreward ? 0 : -1)
    "Extra case not handled in main loop
    elseif lnum==b:ctaglines[-1]
      let i=(a:foreward ? 0 : -2)
    "Main loop
    else
      for i in range(len(b:ctaglines)-1)
        if lnum==b:ctaglines[i]
          let i=(a:foreward ? i+1 : i-1) | break
        elseif lnum>b:ctaglines[i] && lnum<b:ctaglines[i+1]
          let i=(a:foreward ? i+1 : i) | break
        endif
        if i==len(b:ctaglines)-1 | echom "Error: Bracket jump failed." | endif
      endfor
    endif
    return b:ctaglines[i] "just return the line number
  endfor
endfunction
function! s:ctagbracketmaps()
  if &ft!="help" "use bracket for jumpint to last position here
    if g:has_nowait
      nnoremap <nowait> <expr> <buffer> <silent> [ '<Esc>:exe <sid>ctagbracket(0,'.v:count.')<CR>:echo "Jumped to previous tag."<CR>'
      nnoremap <nowait> <expr> <buffer> <silent> ] '<Esc>:exe <sid>ctagbracket(1,'.v:count.')<CR>:echo "Jumped to next tag."<CR>'
      vnoremap <nowait> <expr> <buffer> <silent> [ '<Esc>gv'.<sid>ctagbracket(0,'.v:count.').'ggk<CR>'
      vnoremap <nowait> <expr> <buffer> <silent> ] '<Esc>gv'.<sid>ctagbracket(1,'.v:count.').'ggk<CR>'
    else
      nnoremap <expr> <buffer> <silent> [[ '<Esc>:exe <sid>ctagbracket(0,'.v:count.')<CR>:echo "Jumped to previous tag."<CR>'
      nnoremap <expr> <buffer> <silent> ]] '<Esc>:exe <sid>ctagbracket(1,'.v:count.')<CR>:echo "Jumped to next tag."<CR>'
      vnoremap <expr> <buffer> <silent> [[ '<Esc>gv'.<sid>ctagbracket(0,'.v:count.').'ggk<CR>'
      vnoremap <expr> <buffer> <silent> ]] '<Esc>gv'.<sid>ctagbracket(1,'.v:count.').'ggk<CR>'
    endif
  endif
endfunction

"###############################################################################
"Searching/replacing/changing in-between tags
"##############################################################################"
"Searching within scope of current function or environment
" * Search func idea came from: http://vim.wikia.com/wiki/Search_in_current_function
" * Below is copied from: https://stackoverflow.com/a/597932/4970632
" * Note jedi-vim 'variable rename' is sketchy and fails; should do my own
"   renaming, and do it by confirming every single instance
function! s:scopesearch(command)
  "Test out scopesearch
  if !exists("b:ctaglines") || len(b:ctaglines)==0
    echo "Warning: Tags unavailable, so cannot limit search scope."
    return ""
  endif
  let start=line('.')
  let saveview=winsaveview()
  call winrestview(saveview)
  let ctaglines=extend(b:ctaglines,[line('$')])
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
  echom "Warning: Scopesearch failed to limit search scope."
  return "" "empty string; will not limit scope anymore
endfunction
" "Much less reliable
" "Loop loop through possible jumping commands; the bracket commands
" "are generally declared with FileType regex searches, not ctags
" function! s:scopesearch(command)
"   let start=line('.')
"   let saveview=winsaveview()
"   for endjump in ['normal ]]k', 'call search("^\\S")']
"     " echom 'Trying '.endjump
"     keepjumps normal j[[
"     let first=line('.')
"     exe 'keepjumps '.endjump
"     let last=line('.')
"     " echom first.' to '.last | sleep 1
"     if first<last | break | endif
"     exe 'normal '.start.'g'
"     "return to initial state at the end, important
"   endfor
"   call winrestview(saveview)
"   if first<last
"     echom "Scopesearch selected lines ".first." to ".last."."
"     if !a:command
"       return printf('\%%>%dl\%%<%dl', first-1, last+1)
"         "%% is literal % character, and backslashes do nothing in single quote; check out %l atom documentation
"     else
"       return printf('%d,%ds', first-1, last+1) "simply the range for a :search and replace command
"     endif
"   else
"     echom "Warning: Scopesearch failed to find function range (first line ".first." >= second line ".last.")."
"     return "" "empty string; will not limit scope anymore
"   endif
" endfunction

"###############################################################################
"Magical refactoring tools
"##############################################################################"
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
nnoremap <silent> ! :let b:position=winsaveview()<CR>xhp/<C-R>-<CR>N:call winrestview(b:position)<CR>
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

