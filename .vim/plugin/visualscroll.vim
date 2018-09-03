"------------------------------------------------------------------------------"
" Name:   wrapscroll.vim
" Author: Luke Davis (lukelbd@gmail.com)
" Date:   2018-09-03
"Approximately scroll by N virtual lines while line wrapping is toggled
"Note vim forces us to always start at beginning of wrapped line, but don't
"necessarily have to end on one. So, scrolling is ***always controlled***
"by the lines near the top of the screen!
"------------------------------------------------------------------------------"
augroup scroll
  au!
  au InsertEnter * let b:curswant=-1
augroup END

"------------------------------------------------------------------------------"
"Helper functions first
"------------------------------------------------------------------------------"
"Reverse a string
function! s:reverse(string)
  return join(reverse(split(a:string, '.\zs')), '')
endfunction
"This function has two purposes
" 1. Get the wrapped line height of given line.
" 2. Get a list of *actual* column numbers where *virtual* line breaks have
"    been placed by vim; numbers correspond to first char of each *virtual* col.
function! s:wrapped_line_props(mode,line)
  if 'lc'!~a:mode
    echom "Error: Mode string must be either [l]ine or [c]ol."
    return -1
  endif
  "First figure out indents
  let string=getline(a:line)
  let width=winwidth(0)-(&l:nu || &l:rnu)*&l:numberwidth "exclude region for numbers
  if &l:breakindent
    let n_indent=max([0,match(string,'^ \+\zs')])
  else
    let n_indent=0
  endif
  " echom 'nindent: '.n_indent
  "Iterate through pieces of string
  let offset=0
  let colnum=1
  let colstarts=[1]
  let lineheight=1
  while len(string)+1>=width "must include newline character
    "Determine offset due to 'linebreak' feature
    "Note this won't be perfect! Consecutive non-whitespace characters
    "in breakat seem to *prevent* breaking, for example. But close enough.
    if &l:linebreak
      let test=s:reverse(string[:width-1])
      let offset=match(test, '['.&l:breakat.']')
      " let offset=match(test, '['.&l:breakat.']\(\w\|\s\)') "breaks shit
      " echom 'offset: '.offset
    endif
    let colnum+=(width-offset-n_indent) "the *actual* column number at first position
    let colstarts+=[colnum] "add column to list
    let lineheight+=1 "increment line
    " echom 'substring: '.string[:width/2]
    " echom 'offset: '.offset
    "Note since vim uses 0-indexing, position <width> is 1 char after end
    "Also make sure we trim leading spaces
    let string=repeat(' ',n_indent).substitute(string[width-offset:],'^ \+','','')
  endwhile
  return (a:mode=='l' ? lineheight : colstarts)
  " echom 'lineheight: '.lineheight
endfunction
command! LineHeight echom <sid>wrapped_line_props('l','.')
command! ColBreaks echom join(<sid>wrapped_line_props('c','.'),', ')

"------------------------------------------------------------------------------"
"Next the driver function:
" * target is the number of lines
" * mode is whether to scroll down or up
" * move is whether to move cursor across lines when there is nothing
"   left to scroll, as with normal/builtin vim scrolling.
"------------------------------------------------------------------------------"
function! s:scroll(target,mode,move)
  "Initial stuff
  let verb=0
  if 'ud'!~a:mode
    echom "Error: Mode string must be either [u]p or [d]own."
    return -1
  endif
  let scrolloff=&l:scrolloff
  let &l:scrolloff=0
  if a:mode=='u'
    let stopline=1
    let motion=-1
  else
    let stopline=line('$')
    let motion=+1
  endif
  "----------------------------------------------------------------------------"
  "Figure out the new *top* line
  "Will set this with winrestview
  "----------------------------------------------------------------------------"
  if &l:wrap
    "Determine new line iteratively
    let scrolled=0
    let topline=(a:mode=='u' ? line('w0') : line('w0')-1) "initial
    while scrolled<=a:target && topline!=stopline
      let topline+=motion
      let lineheight=s:wrapped_line_props('l',topline)
      let scrolled+=lineheight
      if lineheight==-1 "indicates error
        return
      endif
    endwhile
    let topline=(a:mode=='u' ? topline : topline+1)
    " if a:mode=='u' && line('w0')==1
    if topline==stopline
      let scrolled=a:target
    endif
    if verb
      echom 'old topline: '.line('w0').' new topline: '.topline.' visual motion: '.scrolled.' target: '.a:target
    endif
    "Optionally *backtrack*, if using the previous topline option would
    "have been a bit closer to 'n' lines
    "Later should modify this to move by *at least* one line
    " let options=[-counter,counter+lineheight] "smaller number is the line *closer* to desired scroll number
    " let closest=index(options, min(options))
    " if closest==1
    "   let scrolled-=lineheight
    "   if a:mode=='u'
    "     let topline+=1
    "   else
    "     let topline-=1
    "   endif
    " endif
  else
    "If wrap not toggled, much simpler
    let topline=line('w0')
    let topline+=(motion*a:target)
    let scrolled=a:target "a:target is read-only variable, so re-assign
  endif
  "----------------------------------------------------------------------------"
  "Figure out how to correspondingly move *cursor* to match
  "the actual virtual lines scrolls, i.e. 'scrolled'
  "----------------------------------------------------------------------------"
  "Note numberwidth can be variable unless you set it manually to
  "something pretty big, possible bug there
  let curline=line('.')
  let wincol=wincol()-&numberwidth-1
  if &l:wrap
    "Determine which wrapped line we are on, and therefore,
    "the number of window columns we *have* to traverse
    let curcol=col('.')
    let colbreaks=s:wrapped_line_props('c',curline)
    let curline_offset=index(map(colbreaks, curcol.'>=v:val'), 0)-1
    let curline_height=len(colbreaks)
    if curline_offset==-1
      let curline_offset=curline_height-1 "offset from first virtual line of current line
    endif
    if verb
      echom 'current line: '.curline.' wrap number: '.curline_offset
    endif
    "--------------------------------------------------------------------------"
    "Determine the new cursorline, and offset down that line
    "Possible that the line at top of screen moves while the current much
    "bigger line does not, so account for that (if statement below)
    "The scroll_init will be the *required* visual lines scrolled if
    "we move the cursor line up or down
    if a:mode=='u'
      let scroll_init=curline_offset "virtual lines scrolled by moving one line
    else
      let scroll_init=curline_height-curline_offset-1
    endif
    if scroll_init>=scrolled
      "Case where we do not move lines
      if a:mode=='u'
        let curline_offset=curline_offset-scrolled
      else
        let curline_offset=curline_offset+scrolled
      endif
    else
      "Case where we do move lines
      "Idea is e.g. if we are on 2nd out of 4 visual lines, want to go to next one,
      "that represents a virtual scrolling of 2 lines at the start. Then scroll
      "by line heights until enough.
      let scroll=scroll_init
      let scrolled_cur=scroll_init "virtual lines scrolled if we move up/down for first time
      while scrolled_cur<scrolled
        if verb
          echom 'scroll: '.scroll.' cursor scrolled: '.scrolled_cur.' target: '.scrolled
        endif
        let curline+=motion "for now stop at line just *before* the destination
        let scroll=s:wrapped_line_props('l',curline) "virtual lines scrolled if we move *past* this current line
        let scrolled_cur+=scroll "number of lines scrolled if we move past *all virtual lines* of curline
      endwhile
      let scrolled_cur-=scroll "number of lines scrolled if we move up to first/last virtual line of curline
      let remainder=scrolled-scrolled_cur "remaining virtual lines to be scrolled
      "Have no idea why the below -1s work, but seem to work, maybe
      if a:mode=='u'
        let curline_offset=scroll-remainder
      else
        let curline_offset=max([0,remainder-1])
      endif
    endif
    if verb
      echom 'destination line: '.curline.' remainder: '.remainder.' wrap number: '.curline_offset
    endif
    "--------------------------------------------------------------------------"
    "Get the column number for winrestview
    let colstarts=s:wrapped_line_props('c',curline)
    let curcol=wincol+colstarts[curline_offset]-1
    if verb
      echom 'destination column num: '.curcol
    endif
  else
    "If wrap not toggled, much simpler
    if a:mode=='u'
      let curline-=a:target
    else
      let curline+=a:target
    endif
    let curcol=wincol
  endif
  "----------------------------------------------------------------------------"
  "Finally restore to the new column
  "----------------------------------------------------------------------------"
  "Playing with idea of persistent curswant, maybe delete
  if !exists('b:curswant') || b:curswant==-1
    let b:curswant=curcol "persistent column
  endif
  call winrestview({'topline':topline, 'lnum':curline,
                  \ 'leftcol':0, 'col':curcol, 'curswant':b:curswant})
  let &l:scrolloff=scrolloff
endfunction

"Create normal mode maps
"Arrow keys are for macbook Karabiner mapping
nnoremap <silent> <C-d>  :call <sid>scroll(winheight(0)/3,'d',1)<CR>
nnoremap <silent> <C-u>  :call <sid>scroll(winheight(0)/3,'u',1)<CR>
nnoremap <silent> <C-j>  :call <sid>scroll(winheight(0)/5,'d',1)<CR>
nnoremap <silent> <C-k>  :call <sid>scroll(winheight(0)/5,'u',1)<CR>
nnoremap <silent> <Down> :call <sid>scroll(winheight(0)/5,'d',1)<CR>
nnoremap <silent> <Up>   :call <sid>scroll(winheight(0)/5,'u',1)<CR>

"Visual mode scrolling with consistent mappings
"Arrow keys are for macbook Karabiner mapping
vnoremap <silent> <expr> <C-d>  eval(winheight(0)/3).'<C-e>'.eval(winheight(0)/3).'gj'
vnoremap <silent> <expr> <C-u>  eval(winheight(0)/3).'<C-y>'.eval(winheight(0)/3).'gk'
vnoremap <silent> <expr> <C-j>  eval(winheight(0)/5).'<C-e>'.eval(winheight(0)/5).'gj'
vnoremap <silent> <expr> <C-k>  eval(winheight(0)/5).'<C-y>'.eval(winheight(0)/5).'gk'
vnoremap <silent> <expr> <Down> eval(winheight(0)/5).'<C-e>'.eval(winheight(0)/5).'gj'
vnoremap <silent> <expr> <Up>   eval(winheight(0)/5).'<C-y>'.eval(winheight(0)/5).'gk'

"Mouse remaps; they break things and default scrolling is fine so forget it
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(winheight(0)/12+1,1)<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(winheight(0)/12+1,0)<CR>
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(1,1,0)<CR>:redraw<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(1,0,0)<CR>:redraw<CR>
" vnoremap <silent> <ScrollWheelDown> <C-e>gj
" vnoremap <silent> <ScrollWheelUp> <C-y>gk
