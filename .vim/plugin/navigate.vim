"------------------------------------------------------------------------------"
"Plugin by Luke Davis <lukelbd@gmail.com> 
"Tries to wrap a few related features into one plugin file:
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
let g:has_ctags=str2nr(system("type ctags &>/dev/null && echo 1 || echo 0"))
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
  au BufReadPost * call s:ctags(0)
  au BufWritePost * call s:ctags(0)
  au FileType * call s:ctagbracketmaps() "this is to *force* my special bracket maps to work
augroup END
"Map to search by character; never use default ! map so why not!
"by default ! waits for a motion, then starts :<range> command
nnoremap <silent> ! :let b:position=winsaveview()<CR>xhp/<C-R>-<CR>N:call winrestview(b:position)<CR>
"Function for declaring ctag lines and ctag regex strings, in line number order
function! s:compare(i1, i2) "default sorting is always alphabetical, with type coercion; must use this!
   return a:i1 - a:i2
endfunc
function! s:ctags(command)
  let b:ctags=[] "return these empty values upon error
  let b:ctaglines=[]
  let ignoretypes=["tagbar","nerdtree"]
  if index(ignoretypes, &ft)!=-1 | return | endif
  "Determine types of ctags we want to store
  if expand("%:t")==".vimrc"
    let type="a" "list only augroups
  elseif &ft=="vim"
    let type="[af]" "list only augroups
  elseif &ft=="tex"
    let type="[bs]" "b is for subsection, s is for section
  elseif &ft=="python"
    let type="[fcm]" "functions, classes, and modules
  else
    let type="f" "default just functions; note Vimscript makes c 'command!'
  endif
  "Ctags doesn't recognize python2/python3 shebangs by default
  if getline(1)=~"#!.*python[23]" | let force="--language=python"
  else | let force=""
  endif
  "Call ctags function
  "Add the sed line to include all items, not just top-level items
  "Currently is added
  " \."| sed 's/class:[^ ]*$//g' | sed 's/function:[^ ]*$//g' "
  if a:command "just return command
    "if table wasn't produced and this is just stderr text then don't tabulate (-s)
    return "ctags ".force." --langmap=vim:+.vimrc,sh:+.bashrc -f - ".expand("%")." "
      \."| sed 's/class:[^ ]*$//g' | sed 's/function:[^ ]*$//g' "
      \."| cut -s -d$'\t' -f1,3-" "ignore filename field, delimit by literal tabs
  else "save then sort
    let ctags=split(system("ctags ".force." --langmap=vim:+.vimrc,sh:+.bashrc -f - ".expand("%")." 2>/dev/null "
      \."| sed 's/class:[^ ]*$//g' | sed 's/function:[^ ]*$//g' "
      \."| grep -E $'\t".type."\t\?$' | cut -d$'\t' -f3 | cut -d'/' -f2"), '\n')
  endif
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
nnoremap <silent> <Leader>c :call <sid>ctags(0)<CR>:echom "Tags updated."<CR>
nnoremap <silent> <expr> <Leader>C ':!clear; '.<sid>ctags(1).' \| less<CR>:redraw!<CR>'
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
nnoremap <silent> <expr> <Leader><Space> ':call <sid>ctagjump("'.input('Enter ctag regex: ').'")<CR>'
" nmap <buffer> <expr> <Leader><Space> ":TagbarOpen<CR>:wincmd l<CR>/".input("Enter ctag regex: ")."<CR>:noh<CR><CR>"
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
if g:has_ctags
  "Searching within scope of current function or environment
  " * Search func idea came from: http://vim.wikia.com/wiki/Search_in_current_function
  " * Below is copied from: https://stackoverflow.com/a/597932/4970632
  " * Note jedi-vim 'variable rename' is sketchy and fails; should do my own
  "   renaming, and do it by confirming every single instance
  function! s:scopesearch(replace)
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
        if a:replace | return printf('%d,%ds', ctaglines[i]-1, ctaglines[i+1]) "range for :line1,line2s command
        else | return printf('\%%>%dl\%%<%dl', ctaglines[i]-1, ctaglines[i+1])
        endif
      endif
    endfor
    echom "Warning: Scopesearch failed to limit search scope."
    return "" "empty string; will not limit scope anymore
  endfunction
else
  "Much less reliable
  "Loop loop through possible jumping commands; the bracket commands
  "are generally declared with FileType regex searches, not ctags
  function! s:scopesearch(replace)
    let start=line('.')
    let saveview=winsaveview()
    for endjump in ['normal ]]k', 'call search("^\\S")']
      " echom 'Trying '.endjump
      keepjumps normal j[[
      let first=line('.')
      exe 'keepjumps '.endjump
      let last=line('.')
      " echom first.' to '.last | sleep 1
      if first<last | break | endif
      exe 'normal '.start.'g'
      "return to initial state at the end, important
    endfor
    call winrestview(saveview)
    if first<last
      echom "Scopesearch selected lines ".first." to ".last."."
      if !a:replace
        return printf('\%%>%dl\%%<%dl', first-1, last+1)
          "%% is literal % character, and backslashes do nothing in single quote; check out %l atom documentation
      else
        return printf('%d,%ds', first-1, last+1) "simply the range for a :search and replace command
      endif
    else
      echom "Warning: Scopesearch failed to find function range (first line ".first." >= second line ".last.")."
      return "" "empty string; will not limit scope anymore
    endif
  endfunction
endif

"###############################################################################
"Magical function; performs n.n.n. style replacement in one keystroke
"Requires the below augroup for some reason
"Inpsired from: https://www.reddit.com/r/vim/comments/8k4p6v/what_are_your_best_mappings/
"##############################################################################"
augroup refactor_tool
  au!
  au InsertLeave * noautocmd call MoveToNext() "magical c* searching function
augroup END
"Also we overhaul the &, @, and # keys
" * By default & repeats last :s command
" * Use <C-r>=expand('<cword>')<CR> instead of <C-r><C-w> to avoid errors on empty lines
" * gn and gN move to next hlsearch, then *visually selects it*, so cgn says to change in this selection
if has_key(g:plugs, "vim-repeat")
  let g:should_inject_replace_occurences=0
  function! MoveToNext()
    if g:should_inject_replace_occurences
      call feedkeys("n")
      call repeat#set("\<Plug>ReplaceOccurences")
    endif
    let g:should_inject_replace_occurences=0
  endfunction
  "Remaps using black magic
  "First one just uses last search, the other ones use word under cursor
  nmap <silent> c/ :set hlsearch<CR>
        \:let g:should_inject_replace_occurences=1<CR>cgn
  nmap <silent> c* :let @/='\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
        \:let g:should_inject_replace_occurences=1<CR>cgn
  nmap <silent> c& :let @/='\_s\@<='.expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
        \:let g:should_inject_replace_occurences=1<CR>cgn
  nmap <silent> c# :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>:set hlsearch<CR>
        \:let g:should_inject_replace_occurences=1<CR>cgn
  nmap <silent> c@ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>:set hlsearch<CR>
        \:let g:should_inject_replace_occurences=1<CR>cgn
  nmap <silent> <Plug>ReplaceOccurences :call ReplaceOccurence()<CR>
  "Original remaps, which don't move onto next highlight automatically
  " nnoremap c# /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgn
  " nnoremap c@ /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``cgn
  " nnoremap c* /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``cgn
  " nnoremap c& /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``cgn
  function! ReplaceOccurence()
    "Check if we are on top of an occurence
    "'[ and '] are first/last characters of previously yanked or changed text
    "Ctrl-a in insert mode types the same text as when you were last in insert mode; see :help i_
    let winview = winsaveview()
    let save_reg = getreg('"')
    let save_regmode = getregtype('"')
    let [lnum_cur, col_cur] = getpos(".")[1:2] 
    normal! ygn
    let [lnum1, col1] = getpos("'[")[1:2]
    let [lnum2, col2] = getpos("']")[1:2]
    call setreg('"', save_reg, save_regmode)
    call winrestview(winview)
    "If we are on top of an occurence, replace it
    if lnum_cur>=lnum1 && lnum_cur<=lnum2 && col_cur>=col1 && col_cur<=col2
      exe "normal! cgn\<C-a>\<Esc>"
    endif
    call feedkeys("n")
    call repeat#set("\<Plug>ReplaceOccurences")
  endfunction
endif

"###############################################################################
"Awesome refactoring stuff
"##############################################################################"
"Remap ? for function-wide searching; follows convention of */# and &/@
"The \(\) makes text after the scope-atoms a bit more readable
"Also note the <silent> will prevent beginning the search until another key is pressed
nnoremap <silent> ? /<C-r>=<sid>scopesearch(0)<CR>\(\)
"Keep */# case-sensitive while '/' and '?' are smartcase case-insensitive
nnoremap <silent> * :let @/='\<'.expand('<cword>').'\>\C'<CR>lb:set hlsearch<CR>
nnoremap <silent> & :let @/='\_s\@<='.expand('<cWORD>').'\ze\_s\C'<CR>lB:set hlsearch<CR>
"Equivalent of * and # (each one key to left), but limited to function scope
" nnoremap <silent> & /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``
" nnoremap <silent> @ /<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\C<CR>``
nnoremap <silent> # :let @/=<sid>scopesearch(0).'\<'.expand('<cword>').'\>\C'<CR>lB:set hlsearch<CR>
nnoremap <silent> @ :let @/='\_s\@<='.<sid>scopesearch(0).expand('<cWORD>').'\ze\_s\C'<CR>lB:set hlsearch<CR>
  "note the @/ sets the 'last search' register to this string value
" * Also expand functionality to <cWORD>s -- do this by using \_s
"   which matches an EOL (from preceding line or this line) *or* whitespace
" * Use ':let @/=STUFF<CR>' instead of '/<C-r>=STUFF<CR><CR>' because this prevents
"   cursor from jumping around right away, which is more betterer
"Next there are a few mnemonically similar maps
"1) Delete currently highlighted text
" * For repeat.vim useage with <Plug> named plugin syntax, see: http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
" * Note that omitting the g means only *first* occurence is replaced
"   if use %, would replace first occurence on every line
" * Options for accessing register in vimscript, where we can't immitate user <C-r> keystroke combination:
"     exe 's/'.@/.'//' OR exe 's/'.getreg('/').'//'
if 1 && has_key(g:plugs, "vim-repeat")
  nnoremap <Plug>search1 /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgnn:call repeat#set("\<Plug>search1",v:count)<CR>
  nnoremap <Plug>search2 /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgnn:call repeat#set("\<Plug>search2",v:count)<CR>
  nnoremap <Plug>search3 /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgnn:call repeat#set("\<Plug>search3",v:count)<CR>
  nnoremap <Plug>search4 /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgnn:call repeat#set("\<Plug>search4",v:count)<CR>
  nnoremap <Plug>search5 :set hlsearch<CR>dgnn:call repeat#set("\<Plug>search5",v:count)<CR>
  nmap d# <Plug>search1
  nmap d@ <Plug>search2
  nmap d* <Plug>search3
  nmap d& <Plug>search4
  nmap d/ <Plug>search5
else "with these ones, cursor will remain on word just replaced
  nnoremap d# /<C-r>=<sid>scopesearch(0)<CR>\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgn
  nnoremap d@ /\_s\@<=<C-r>=<sid>scopesearch(0)<CR><C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgn
  nnoremap d* /\<<C-r>=expand('<cword>')<CR>\>\C<CR>``dgn
  nnoremap d& /\_s\@<=<C-r>=expand('<cWORD>')<CR>\ze\_s\C<CR>``dgn
  nnoremap d/ :set hlsearch<CR>dng
endif
"Colon search replacements -- not as nice as the above ones, which stay in normal mode
"See that reddit thread for why normal-mode is better
" nnoremap <Leader>r :%s/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
" nnoremap <Leader>R :<C-r>=<sid>scopesearch(1)<CR>/\<<C-r><C-w>\>//gIc<Left><Left><Left><Left>
"   "the <C-r> means paste from the expression register i.e. result of following expr
" nnoremap <Leader>d :%s///gIc<Left><Left><Left><Left><Left>
" nnoremap <Leader>D :<C-r>=<sid>scopesearch(1)<CR>///gIc<Left><Left><Left><Left><Left>
"   "these ones delete stuff
