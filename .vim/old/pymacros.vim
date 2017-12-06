function! PyInteract() "executes whole file, interactively (use silent)
"1) Initial stuff
"2) Make temporary file
"3) Run
"4) Remove temporary file
execute "silent !clear; "
      \."cp ".shellescape(@%).' tmp.py; '
      \."ipython --no-banner --no-confirm-exit -i -c '\\%run tmp'; "
      \."rm tmp.py"
"Post) Redraw
redraw!
endfunction
function! PyPart(linefirst, linelast) "execute between lines, interactively (silent necessary)
  "Pre) Get arguments for shell 'head' and 'tail' commands
  let a:head = a:linelast
  let a:tail = a:linelast-a:linefirst+1
  "1) Initial stuff
  "2) Get file head
  "3) Get file tail
  "4) Filter certain commands out, and save temporary file
  "5) Run
  "6) Remove temporary file
  execute "silent !clear; set -x; "
        \."head -n ".a:head." ".shellescape(@%)
        \." | tail -n ".a:tail
        \." | gsed '/mpl.use/d' | gsed '/plt.show/d' | gsed '/fig.show/d' > tmp.py; "
        \."ipython --no-banner --no-confirm-exit -i tmp.py; "
        \. "rm tmp.py"
  "Post) Redraw
  redraw!
endfunction
function! PyHelp(content) "interactive help() from command-line interface
  " ...note, piping sliced-up .py file doesn't work, prints out non-interactive
  " ...help info; must call from python to show help page in less editor
  "Pre) Insert help(content) line and write
  execute "normal ohelp(".a:content.")"
  write
  "1) Trim up to help(content) line
  "2) Filter stuff, and save temporary file
  "2) Run file
  "3) Remove tempory file and old lines
  execute "silent !clear; set -x; "
        \."head -n ".line('.')." ".shellescape(@%)
        \." | gsed '/mpl.use/d' | gsed '/print(/d' > tmp.py; "
        \."python tmp.py; "
        \."rm tmp.py"
  "Post) Remove help(content) line, write, and redraw
  execute "normal dd"
  write
  redraw!
endfunction
"I HAVE MODIFIED THIS SIGNIFICANTLY; SOME FEATURES MIGHT BE BAD WORKFLOW
"Basic remap; run code
"x is for 'execute' and i is for 'interactive'
noremap <silent> <buffer> <C-x> :w<CR>:call PyFull()<CR>
noremap <silent> <buffer> <C-z> :w<CR>:call PyInteract()<CR>
"   "don't use C-i (this is Tab)
"Get simple pydoc string
"o is for 'doc'
nnoremap <buffer> <C-o> yiw:call PyDoc(@")<CR>
vnoremap <buffer> <C-o> y:call PyDoc(@")<CR>
noremap <buffer> <expr> <Leader>d ":call PyDoc('".input('Python documentation: ')."')<CR>"
"Interactive mode partial execution (these should be silent, because you want to just
"quit the ipython shell, and immediately return to vim withour press Enter)
"t is for 'until'
nnoremap <silent> <buffer> <C-t> :w<CR>:call PyPart(line('0'),line('.'))<CR>
vnoremap <silent> <buffer> <C-t> <Esc>:w<CR>:call PyPart(line("'<"),line("'>"))<CR>
  "trim with head and tail cmdline tools
"Get python help on specific OBJECT (more complicated than pydoc lookup)
nnoremap <buffer> <C-h> yiw:call PyHelp(@")<CR>
vnoremap <buffer> <C-h> y:call PyHelp(@")<CR>
noremap <buffer> <expr> yh ":call PyHelp('".input('Python help: ')."')<CR>"
  "first one want just normal mode, next one visual, last one should be
  "available in everything
