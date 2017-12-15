"PLACED THIS IN ITS OWN FUNCTION BECAUSE MAKES MORE LOGICAL SENSE
"REALLY THIS IS A SEPARATE PLUGIN
"SCROLLING
function! s:scroll(num,mode,toggle)
if (line('.')!=1 && a:mode==1) || (line('.')!=line('$') && a:mode==0)
  "First stuff
  let a:oldscrolloff=&scrolloff
  let a:oldwinline=winline()
  setlocal scrolloff=0
  "Go to top/bottom of file, and coerce window movement with scrolling
  "(have to coerce in this way because <c-y>/<c-e> doesn't work in functions)
  let a:count=a:num
  if a:mode == 1
    execute 'normal! ' . eval(winline()-1) . 'gk'
      "must enclose :execute and <expr> numbers in eval()
    while line('.') != 1 && a:count
      execute 'normal!  gk'
      let a:count-=1
    endwhile
  else
    execute 'normal! ' . eval(winheight(0)-winline()). 'gj'
    while line('.') != line('$') && a:count
      execute 'normal!  gj'
      let a:count-=1
    endwhile
  endif
  "Fix position
  if a:oldwinline > winline()
    execute 'normal! ' . eval(a:oldwinline-winline()) . 'gj'
  elseif winline() > a:oldwinline
    execute 'normal! ' . eval(winline()-a:oldwinline) . 'gk'
  endif
  "If at top/bottom, keep scrolling by some amount; assuming the
  "toggle option is turned on
  if a:count>0 && a:toggle==1
    while line('.') != line('0') && line('.') != line('$') && a:count
      if a:mode == 1
        execute 'normal! gk'
      else
        execute 'normal! gj'
      endif
      let a:count-=1
    endwhile
  endif
  "Restore scrolloff
  execute 'setlocal scrolloff='.a:oldscrolloff
endif
endfunction
"Create normal mode maps
noremap <silent> <C-h> :call <sid>scroll(winheight(0)/4,0,1)<CR>
noremap <silent> <C-j> :call <sid>scroll(winheight(0)/2,0,1)<CR>
noremap <silent> <C-l> :call <sid>scroll(winheight(0)/4,1,1)<CR>
noremap <silent> <C-k> :call <sid>scroll(winheight(0)/2,1,1)<CR>
noremap <C-f> [[
noremap <C-g> ]]
"noremap <silent> <C-b> :call <sid>scroll(winheight(0),1,1)<CR>
"noremap <silent> <C-f> :call <sid>scroll(winheight(0),0,1)<CR>
" nnoremap <silent> <ScrollWheelUp> :call <sid>scroll(winheight(0)/12+1,1)<CR>
" nnoremap <silent> <ScrollWheelDown> :call <sid>scroll(winheight(0)/12+1,0)<CR>
noremap <silent> <ScrollWheelUp> :call <sid>scroll(1,1,0)<CR>
noremap <silent> <ScrollWheelDown> :call <sid>scroll(1,0,0)<CR>
"And visual mode scrolling; never really use with wrapping toggled, so
"will use standard <C-e> <C-y> scrolling here
vnoremap <expr> <C-h> eval(winheight(0)/4).'<C-e>'.eval(winheight(0)/4).'gj'
vnoremap <expr> <C-j> eval(winheight(0)/2).'<C-e>'.eval(winheight(0)/2).'gj'
vnoremap <expr> <C-l> eval(winheight(0)/4).'<C-y>'.eval(winheight(0)/4).'gk'
vnoremap <expr> <C-k> eval(winheight(0)/2).'<C-y>'.eval(winheight(0)/2).'gk'
vnoremap <C-f> [[
vnoremap <C-g> ]]
"vnoremap <expr> <C-f> eval(winheight(0)).'<C-e>'.eval(winheight(0)).'gj'
"vnoremap <expr> <C-b> eval(winheight(0)).'<C-y>'.eval(winheight(0)).'gk'
vnoremap <ScrollWheelDown> <C-e>gj
vnoremap <ScrollWheelUp> <C-y>gk
"So don't confuse myself, make sure <C-d> and <C-u> then don't work
noremap <C-d> <Nop>
noremap <C-u> <Nop>
vnoremap <C-d> <Nop>
vnoremap <C-u> <Nop>
