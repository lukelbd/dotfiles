"INSANELY BETTER SCROLLING AMONGST WRAPPED LINES
"ALSO ISSUES SOME NEW REMAPS FOR SCROLLING
"Placed this in its own function because makes more logical sense
"really this is a separate plugin
function! s:scroll(num,mode,toggle)
if (line('.')!=1 && a:mode==1) || (line('.')!=line('$') && a:mode==0)
  "First stuff
  let oldscrolloff=&scrolloff
  let oldwinline=winline()
  setlocal scrolloff=0
  "Go to top/bottom of file, and coerce window movement with scrolling
  "(have to coerce in this way because <c-y>/<c-e> doesn't work in functions)
  let l:count=a:num "count is read-only variable; need to explicitly declare scope
  if a:mode == 1
    execute 'keepjumps normal! ' . eval(winline()-1) . 'gk'
      "must enclose :execute and <expr> numbers in eval()
    while line('.') != 1 && l:count
      execute 'keepjumps normal!  gk'
      let l:count-=1
    endwhile
  else
    execute 'keepjumps normal! ' . eval(winheight(0)-winline()). 'gj'
    while line('.') != line('$') && l:count
      execute 'keepjumps normal!  gj'
      let l:count-=1
    endwhile
  endif
  "Fix position
  if oldwinline > winline()
    execute 'keepjumps normal! ' . eval(oldwinline-winline()) . 'gj'
  elseif winline() > oldwinline
    execute 'keepjumps normal! ' . eval(winline()-oldwinline) . 'gk'
  endif
  "If at top/bottom, keep scrolling by some amount; assuming the
  "toggle option is turned on
  if l:count>0 && a:toggle==1
    while line('.') != line('0') && line('.') != line('$') && l:count
      if a:mode == 1
        execute 'keepjumps normal! gk'
      else
        execute 'keepjumps normal! gj'
      endif
      let l:count-=1
    endwhile
  endif
  "Restore scrolloff
  execute 'setlocal scrolloff='.oldscrolloff
endif
endfunction
"-------------------------------------------------------------------------------
"Create normal mode maps
nnoremap <silent> <C-d> :call <sid>scroll(winheight(0)/3,0,1)<CR>
nnoremap <silent> <C-u> :call <sid>scroll(winheight(0)/3,1,1)<CR>
nnoremap <silent> <C-f> :call <sid>scroll(winheight(0)/5,0,1)<CR>
nnoremap <silent> <C-y> :call <sid>scroll(winheight(0)/5,1,1)<CR>
"-------------------------------------------------------------------------------
"Visual mode scrolling
vnoremap <silent> <expr> <C-d> eval(winheight(0)/3).'<C-e>'.eval(winheight(0)/3).'gj'
vnoremap <silent> <expr> <C-u> eval(winheight(0)/3).'<C-y>'.eval(winheight(0)/3).'gk'
vnoremap <silent> <expr> <C-f> eval(winheight(0)/5).'<C-e>'.eval(winheight(0)/5).'gj'
vnoremap <silent> <expr> <C-y> eval(winheight(0)/5).'<C-y>'.eval(winheight(0)/5).'gk'
"-------------------------------------------------------------------------------
"Mouse remaps; they break things and default scrolling is fine so forget it
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(winheight(0)/12+1,1)<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(winheight(0)/12+1,0)<CR>
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(1,1,0)<CR>:redraw<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(1,0,0)<CR>:redraw<CR>
" vnoremap <silent> <ScrollWheelDown> <C-e>gj
" vnoremap <silent> <ScrollWheelUp> <C-y>gk
