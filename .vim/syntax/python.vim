"------------------------------------------------------------------------------"
" Python syntax. Adapted from python-syntax and $VIMRUNTIME/syntax/python.vim {{{1
"------------------------------------------------------------------------------"
if exists('b:current_syntax')
  finish
endif

"-----------------------------------------------------------------------------"
" Helper functions {{{2
"-----------------------------------------------------------------------------"
function! s:define(name)
  if !exists(a:name) | let {a:name} = 1 | endif
endfunction
function! s:enabled(name)
  return exists(a:name) && {a:name}
endfunction
function! s:python2()
  return getline(1) =~# '^#!.*\<python2\>'
endfunction
command! -buffer Python2Syntax let b:python_version_2 = 1 | let &syntax = &syntax
command! -buffer Python3Syntax let b:python_version_2 = 0 | let &syntax = &syntax

"-----------------------------------------------------------------------------"
" Default settings  {{{2
"-----------------------------------------------------------------------------"
call s:define('g:python_slow_sync')
call s:define('g:python_highlight_builtin_funcs_kwarg')

if s:enabled('g:python_highlight_builtins')
  call s:define('g:python_highlight_builtin_objs')
  call s:define('g:python_highlight_builtin_types')
  call s:define('g:python_highlight_builtin_funcs')
endif

if s:enabled('g:python_highlight_all')
  call s:define('g:python_highlight_builtins')
  call s:define('g:python_highlight_exceptions')
  call s:define('g:python_highlight_string_formatting')
  call s:define('g:python_highlight_string_format')
  call s:define('g:python_highlight_string_templates')
  call s:define('g:python_highlight_indent_errors')
  call s:define('g:python_highlight_space_errors')
  call s:define('g:python_highlight_doctests')
  call s:define('g:python_print_as_function')
  call s:define('g:python_highlight_func_calls')
  call s:define('g:python_highlight_class_vars')
  call s:define('g:python_highlight_operators')
endif

"------------------------------------------------------------------------------"
" General syntax  {{{2
"------------------------------------------------------------------------------"
" Keywords
" The standard pyrex.vim unconditionally removes the pythonInclude
" group, so we provide a dummy group here to avoid crashing pyrex.vim.
syn keyword pythonInclude import
syn keyword pythonImport import
syn keyword pythonStatement break continue del return pass yield global assert lambda with
syn keyword pythonStatement raise nextgroup=pythonExClass skipwhite
syn keyword pythonStatement def nextgroup=pythonFunction skipwhite
syn keyword pythonStatement class nextgroup=pythonClass skipwhite
syn keyword pythonRepeat for while
syn keyword pythonConditional if elif else
syn keyword pythonException try except finally
syn match pythonMatch "^\s*\zscase\%(\s\+.*:.*$\)\@="
syn match pythonMatch "^\s*\zsmatch\%(\s\+.*:\s*\%(#.*\)\=$\)\@="
syn match pythonRaiseFromStatement '\<from\>'
syn match pythonImport '^\s*\zsfrom\>'

" Functions
if s:enabled('g:python_highlight_class_vars')
  syn keyword pythonClassVar self cls mcs
endif
if s:enabled('g:python_highlight_func_calls')
  syn match pythonFunctionCall '\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\ze\%(\s*(\)'
endif
if s:python2() && !s:enabled('g:python_print_as_function')
  syn keyword pythonStatement print
endif
if s:python2()
  syn keyword pythonStatement exec
  syn keyword pythonImport as
  syn match pythonFunction '[a-zA-Z_][a-zA-Z0-9_]*' display contained
else
  syn keyword pythonStatement as nonlocal
  syn match pythonStatement '\v\.@<!<await>'
  syn match pythonFunction '\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*' display contained
  syn match pythonClass '\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*' display contained
  syn match pythonStatement '\<async\s\+def\>' nextgroup=pythonFunction skipwhite
  syn match pythonStatement '\<async\s\+with\>'
  syn match pythonStatement '\<async\s\+for\>'
  syn cluster pythonExpression contains=pythonStatement,pythonRepeat,pythonConditional,pythonMatch,pythonOperator,pythonNumber,pythonHexNumber,pythonOctNumber,pythonBinNumber,pythonFloat,pythonString,pythonFString,pythonRawString,pythonRawFString,pythonBytes,pythonBoolean,pythonNone,pythonSingleton,pythonBuiltinObj,pythonBuiltinFunc,pythonBuiltinType,pythonClassVar
endif

" Decorators (python 2.4+)
syn match pythonDecorator '^\s*\zs@\S\@=' display nextgroup=pythonDottedName skipwhite
if s:python2()
  syn match pythonDottedName
    \ '[a-zA-Z_][a-zA-Z0-9_]*\%(\.[a-zA-Z_][a-zA-Z0-9_]*\)*' display contained
else
  syn match pythonDottedName
    \ '\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\%(\.\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\)*' display contained
endif
syn match pythonDot '\.' display containedin=pythonDottedName

" Operators
syn keyword pythonOperator
  \ and in is not or
if s:enabled('g:python_highlight_operators')
  syn match pythonOperator '\V=\|-\|+\|*\|@\%(\s\@=\|$\)\|/\|%\|&\||\|^\|~\|<\|>\|!=\|:='
endif
syn match pythonError
  \ '[$?]\|\([-+@%&|^~]\)\1\{1,}\|\([=*/<>]\)\2\{2,}\|\([+@/%&|^~<>]\)\3\@![-+*@/%&|^~<>]\|\*\*[*@/%&|^<>]\|=[*@/%&|^<>]\|-[+*@/%&|^~<]\|[<!>]\+=\{2,}\|!\{2,}=\+' display

" Comments
syn match pythonComment '#.*$' display contains=pythonTodo,@Spell
if !s:enabled('g:python_highlight_file_headers_as_comments')
  syn match pythonRun '\%^#!.*$'
  syn match pythonCoding '\%^.*\%(\n.*\)\?#.*coding[:=]\s*[0-9A-Za-z-_.]\+.*$'
endif
syn keyword pythonTodo TODO FIXME XXX contained

" Errors
syn match pythonError '\<\d\+[^0-9[:space:]]\+\>' display
if s:enabled('g:python_highlight_indent_errors')  " allow mixed spaces/tabs for formatting multilines
  syn match pythonIndentError '^\s*\%( \t\|\t \)\s*\S'me=e-1 display
endif
if s:enabled('g:python_highlight_space_errors')  " disallow trailing spaces
  syn match pythonSpaceError '\s\+$' display
endif

"------------------------------------------------------------------------------"
" Builtins and numbers {{{2
"------------------------------------------------------------------------------"
" Type builtins
if s:enabled('g:python_highlight_builtin_types')
  syn match pythonBuiltinType '\v\.@<!<%(object|bool|int|float|tuple|str|list|dict|set|frozenset|bytearray|bytes)>'
endif

" Object builtins
if s:enabled('g:python_highlight_builtin_objs')
  syn keyword pythonNone None
  syn keyword pythonBoolean True False
  syn keyword pythonSingleton Ellipsis NotImplemented
  syn keyword pythonBuiltinObj __debug__ __doc__ __file__ __name__ __package__
  syn keyword pythonBuiltinObj __loader__ __spec__ __path__ __cached__
endif

" Exception builtins
if s:enabled('g:python_highlight_exceptions')
  let s:exs_re = 'BaseException|Exception|ArithmeticError|LookupError|EnvironmentError|AssertionError|AttributeError|BufferError|EOFError|FloatingPointError|GeneratorExit|IOError|ImportError|IndexError|KeyError|KeyboardInterrupt|MemoryError|NameError|NotImplementedError|OSError|OverflowError|ReferenceError|RuntimeError|StopIteration|SyntaxError|IndentationError|TabError|SystemError|SystemExit|TypeError|UnboundLocalError|UnicodeError|UnicodeEncodeError|UnicodeDecodeError|UnicodeTranslateError|ValueError|VMSError|WindowsError|ZeroDivisionError|Warning|UserWarning|BytesWarning|DeprecationWarning|PendingDeprecationWarning|SyntaxWarning|RuntimeWarning|FutureWarning|ImportWarning|UnicodeWarning'
  if s:python2()
    let s:exs_re .= '|StandardError'
  else
    let s:exs_re .= '|BlockingIOError|ChildProcessError|ConnectionError|BrokenPipeError|ConnectionAbortedError|ConnectionRefusedError|ConnectionResetError|FileExistsError|FileNotFoundError|InterruptedError|IsADirectoryError|NotADirectoryError|PermissionError|ProcessLookupError|TimeoutError|StopAsyncIteration|ResourceWarning'
  endif
  execute 'syn match pythonExClass ''\v\.@<!\zs<%(' . s:exs_re . ')>'''
  unlet s:exs_re
endif

" Function builtins
if s:enabled('g:python_highlight_builtin_funcs')
  let s:funcs_re = '__import__|abs|all|any|bin|callable|chr|classmethod|compile|complex|delattr|dir|divmod|enumerate|eval|filter|format|getattr|globals|hasattr|hash|help|hex|id|input|isinstance|issubclass|iter|len|locals|map|max|memoryview|min|next|oct|open|ord|pow|property|range|repr|reversed|round|setattr|slice|sorted|staticmethod|sum|super|type|vars|zip'
  if s:python2()
    let s:funcs_re .= '|apply|basestring|buffer|cmp|coerce|execfile|file|intern|long|raw_input|reduce|reload|unichr|unicode|xrange'
    if s:enabled('g:python_print_as_function')
      let s:funcs_re .= '|print'
    endif
  else
    let s:funcs_re .= '|ascii|breakpoint|exec|print'
  endif
  let s:funcs_re = 'syn match pythonBuiltinFunc ''\v\.@<!\zs<%(' . s:funcs_re . ')>'
  if !s:enabled('g:python_highlight_builtin_funcs_kwarg')
    let s:funcs_re .= '\=@!'
  endif
  execute s:funcs_re . ''''
  unlet s:funcs_re
endif

" Ints floats longs bools
if s:python2()
  syn match pythonHexError '\<0[xX]\x*[g-zG-Z]\+\x*[lL]\=\>' display
  syn match pythonOctError '\<0[oO]\=\o*\D\+\d*[lL]\=\>' display
  syn match pythonBinError '\<0[bB][01]*\D\+\d*[lL]\=\>' display
  syn match pythonHexNumber '\<0[xX]\x\+[lL]\=\>' display
  syn match pythonOctNumber '\<0[oO]\o\+[lL]\=\>' display
  syn match pythonBinNumber '\<0[bB][01]\+[lL]\=\>' display
  syn match pythonNumberError '\<\d\+\D[lL]\=\>' display
  syn match pythonNumber '\<\d[lL]\=\>' display
  syn match pythonNumber '\<[0-9]\d\+[lL]\=\>' display
  syn match pythonNumber '\<\d\+[lLjJ]\>' display
  syn match pythonOctError '\<0[oO]\=\o*[8-9]\d*[lL]\=\>' display
  syn match pythonBinError '\<0[bB][01]*[2-9]\d*[lL]\=\>' display
  syn match pythonFloat '\.\d\+\%([eE][+-]\=\d\+\)\=[jJ]\=\>' display
  syn match pythonFloat '\<\d\+[eE][+-]\=\d\+[jJ]\=\>' display
  syn match pythonFloat '\<\d\+\.\d*\%([eE][+-]\=\d\+\)\=[jJ]\=' display
else  " pythonHexError comes after pythonOctError so that 0xffffl is pythonHexError
  syn match pythonOctError '\<0[oO]\=\o*\D\+\d*\>' display
  syn match pythonHexError '\<0[xX]\x*[g-zG-Z]\x*\>' display
  syn match pythonBinError '\<0[bB][01]*\D\+\d*\>' display
  syn match pythonHexNumber '\<0[xX][_0-9a-fA-F]*\x\>' display
  syn match pythonOctNumber '\<0[oO][_0-7]*\o\>' display
  syn match pythonBinNumber '\<0[bB][_01]*[01]\>' display
  syn match pythonNumberError '\<\d[_0-9]*\D\>' display
  syn match pythonNumberError '\<0[_0-9]\+\>' display
  syn match pythonNumberError '\<0_x\S*\>' display
  syn match pythonNumberError '\<0[bBxXoO][_0-9a-fA-F]*_\>' display
  syn match pythonNumberError '\<\d[_0-9]*_\>' display
  syn match pythonNumber '\<\d\>' display
  syn match pythonNumber '\<[1-9][_0-9]*\d\>' display
  syn match pythonNumber '\<\d[jJ]\>' display
  syn match pythonNumber '\<[1-9][_0-9]*\d[jJ]\>' display
  syn match pythonOctError '\<0[oO]\=\o*[8-9]\d*\>' display
  syn match pythonBinError '\<0[bB][01]*[2-9]\d*\>' display
  syn match pythonFloat '\.\d\%([_0-9]*\d\)\=\%([eE][+-]\=\d\%([_0-9]*\d\)\=\)\=[jJ]\=\>' display
  syn match pythonFloat '\<\d\%([_0-9]*\d\)\=[eE][+-]\=\d\%([_0-9]*\d\)\=[jJ]\=\>' display
  syn match pythonFloat '\<\d\%([_0-9]*\d\)\=\.\d\=\%([_0-9]*\d\)\=\%([eE][+-]\=\d\%([_0-9]*\d\)\=\)\=[jJ]\=' display
endif

"------------------------------------------------------------------------------"
" Strings and formatting  {{{2
"------------------------------------------------------------------------------"
" Byte strings
if s:python2()  " python 2 strings
  syn region pythonString start=+[bB]\='+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonString start=+[bB]\="+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonString start=+[bB]\="""+ skip=+\\"+ end=+"""+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest2,pythonSpaceError,@Spell
  syn region pythonString start=+[bB]\='''+ skip=+\\'+ end=+'''+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest,pythonSpaceError,@Spell
else  " python 3 byte strings
  syn region pythonBytes start=+[bB]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesError,pythonBytesContent,@Spell
  syn region pythonBytes start=+[bB]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesError,pythonBytesContent,@Spell
  syn region pythonBytes start=+[bB]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonBytesError,pythonBytesContent,pythonDocTest,pythonSpaceError,@Spell
  syn region pythonBytes start=+[bB]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonBytesError,pythonBytesContent,pythonDocTest2,pythonSpaceError,@Spell
  syn match pythonBytesError '.\+' display contained
  syn match pythonBytesContent '[\u0000-\u00ff]\+' display contained contains=pythonBytesEscape,pythonBytesEscapeError
endif

" Unicode strings
if s:python2()  " python 2 unicode strings
  syn region pythonUniString start=+[uU]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonUniString start=+[uU]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonUniString start=+[uU]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest,pythonSpaceError,@Spell
  syn region pythonUniString start=+[uU]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest2,pythonSpaceError,@Spell
else  " python 3 strings
  syn region pythonString start=+'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonString start=+"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonString start=+'''+ skip=+\\'+ end=+'''+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest,pythonSpaceError,@Spell
  syn region pythonString start=+"""+ skip=+\\"+ end=+"""+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest2,pythonSpaceError,@Spell
  syn region pythonFString start=+[fF]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonFString start=+[fF]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,@Spell
  syn region pythonFString start=+[fF]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest,pythonSpaceError,@Spell
  syn region pythonFString start=+[fF]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonBytesEscape,pythonBytesEscapeError,pythonUniEscape,pythonUniEscapeError,pythonDocTest2,pythonSpaceError,@Spell
endif

" Raw strings
if s:python2()  " python 2 unicode raw strings
  syn region pythonUniRawString start=+[uU][rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,pythonUniRawEscape,pythonUniRawEscapeError,@Spell
  syn region pythonUniRawString start=+[uU][rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,pythonUniRawEscape,pythonUniRawEscapeError,@Spell
  syn region pythonUniRawString start=+[uU][rR]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonUniRawEscape,pythonUniRawEscapeError,pythonDocTest,pythonSpaceError,@Spell
  syn region pythonUniRawString start=+[uU][rR]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonUniRawEscape,pythonUniRawEscapeError,pythonDocTest2,pythonSpaceError,@Spell
  syn match pythonUniRawEscape '\%([^\\]\%(\\\\\)*\)\@<=\\u\x\{4}' display contained
  syn match pythonUniRawEscapeError '\%([^\\]\%(\\\\\)*\)\@<=\\u\x\{,3}\X' display contained
endif
if s:python2()  " python 2 raw strings
  syn region pythonRawString start=+[bB]\=[rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawString start=+[bB]\=[rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawString start=+[bB]\=[rR]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonDocTest,pythonSpaceError,@Spell
  syn region pythonRawString start=+[bB]\=[rR]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonDocTest2,pythonSpaceError,@Spell
else  " python 3 raw strings
  syn region pythonRawString start=+[rR]'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawString start=+[rR]"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawString start=+[rR]'''+ skip=+\\'+ end=+'''+ keepend contains=pythonDocTest,pythonSpaceError,@Spell
  syn region pythonRawString start=+[rR]"""+ skip=+\\"+ end=+"""+ keepend contains=pythonDocTest2,pythonSpaceError,@Spell
  syn region pythonRawFString start=+\%([fF][rR]\|[rR][fF]\)'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawFString start=+\%([fF][rR]\|[rR][fF]\)"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawFString start=+\%([fF][rR]\|[rR][fF]\)'''+ skip=+\\'+ end=+'''+ keepend contains=pythonDocTest,pythonSpaceError,@Spell
  syn region pythonRawFString start=+\%([fF][rR]\|[rR][fF]\)"""+ skip=+\\"+ end=+"""+ keepend contains=pythonDocTest,pythonSpaceError,@Spell
  syn region pythonRawBytes start=+\%([bB][rR]\|[rR][bB]\)'+ skip=+\\\\\|\\'\|\\$+ excludenl end=+'+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawBytes start=+\%([bB][rR]\|[rR][bB]\)"+ skip=+\\\\\|\\"\|\\$+ excludenl end=+"+ end=+$+ keepend contains=pythonRawEscape,@Spell
  syn region pythonRawBytes start=+\%([bB][rR]\|[rR][bB]\)'''+ skip=+\\'+ end=+'''+ keepend contains=pythonDocTest,pythonSpaceError,@Spell
  syn region pythonRawBytes start=+\%([bB][rR]\|[rR][bB]\)"""+ skip=+\\"+ end=+"""+ keepend contains=pythonDocTest2,pythonSpaceError,@Spell
endif

" Escaped strings
syn match pythonRawEscape +\\['"]+ display contained
syn match pythonBytesEscape +\\[abfnrtv'"\\]+ display contained
syn match pythonBytesEscape '\\\o\o\=\o\=' display contained
syn match pythonBytesEscapeError '\\\o\{,2}[89]' display contained
syn match pythonBytesEscape '\\x\x\{2}' display contained
syn match pythonBytesEscapeError '\\x\x\=\X' display contained
syn match pythonBytesEscape '\\$'
syn match pythonUniEscape '\\u\x\{4}' display contained
syn match pythonUniEscapeError '\\u\x\{,3}\X' display contained
syn match pythonUniEscape '\\U\x\{8}' display contained
syn match pythonUniEscapeError '\\U\x\{,7}\X' display contained
syn match pythonUniEscape '\\N{[A-Z ]\+}' display contained
syn match pythonUniEscapeError '\\N{[^A-Z ]\+}' display contained

" doctest string formatting
if s:enabled('g:python_highlight_doctests')
  syn region pythonDocTest start='^\s*>>>' skip=+\\'+ end=+'''+he=s-1 end='^\s*$' contained
  syn region pythonDocTest2 start='^\s*>>>' skip=+\\"+ end=+"""+he=s-1 end='^\s*$' contained
endif

" % operator string formatting
if s:enabled('g:python_highlight_string_formatting')
  if s:python2()
    syn match pythonStrFormatting '%\%(([^)]\+)\)\=[-#0 +]*\d*\%(\.\d\+\)\=[hlL]\=[diouxXeEfFgGcrs%]' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString,pythonBytesContent
    syn match pythonStrFormatting '%[-#0 +]*\%(\*\|\d\+\)\=\%(\.\%(\*\|\d\+\)\)\=[hlL]\=[diouxXeEfFgGcrs%]' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString,pythonBytesContent
  else
    syn match pythonStrFormatting '%\%(([^)]\+)\)\=[-#0 +]*\d*\%(\.\d\+\)\=[hlL]\=[diouxXeEfFgGcrs%]' contained containedin=pythonString,pythonRawString,pythonBytesContent
    syn match pythonStrFormatting '%[-#0 +]*\%(\*\|\d\+\)\=\%(\.\%(\*\|\d\+\)\)\=[hlL]\=[diouxXeEfFgGcrs%]' contained containedin=pythonString,pythonRawString,pythonBytesContent
  endif
endif

" str.format syntax
if s:enabled('g:python_highlight_string_format')
  if s:python2()
    syn match pythonStrFormat '{{\|}}' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString
    syn match pythonStrFormat '{\%(\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\d\+\)\=\%(\.\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\[\%(\d\+\|[^!:\}]\+\)\]\)*\%(![rsa]\)\=\%(:\%({\%(\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\d\+\)}\|\%([^}]\=[<>=^]\)\=[ +-]\=#\=0\=\d*,\=\%(\.\d\+\)\=[bcdeEfFgGnosxX%]\=\)\=\)\=}' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString
  else
    syn match pythonStrFormat "{\%(\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\d\+\)\=\%(\.\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\[\%(\d\+\|[^!:\}]\+\)\]\)*\%(![rsa]\)\=\%(:\%({\%(\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\d\+\)}\|\%([^}]\=[<>=^]\)\=[ +-]\=#\=0\=\d*,\=\%(\.\d\+\)\=[bcdeEfFgGnosxX%]\=\)\=\)\=}" contained containedin=pythonString,pythonRawString
    syn region pythonStrInterpRegion matchgroup=pythonStrFormat start="{" end="\%(![rsa]\)\=\%(:\%({\%(\%([^[:cntrl:][:space:][:punct:][:digit:]]\|_\)\%([^[:cntrl:][:punct:][:space:]]\|_\)*\|\d\+\)}\|\%([^}]\=[<>=^]\)\=[ +-]\=#\=0\=\d*,\=\%(\.\d\+\)\=[bcdeEfFgGnosxX%]\=\)\=\)\=}" extend contained containedin=pythonFString,pythonRawFString contains=pythonStrInterpRegion,@pythonExpression
    syn match pythonStrFormat "{{\|}}" contained containedin=pythonFString,pythonRawFString
  endif
endif

" string.Template format
if s:enabled('g:python_highlight_string_templates')
  if s:python2()
    syn match pythonStrTemplate '\$\$' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString
    syn match pythonStrTemplate '\${[a-zA-Z_][a-zA-Z0-9_]*}' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString
    syn match pythonStrTemplate '\$[a-zA-Z_][a-zA-Z0-9_]*' contained containedin=pythonString,pythonUniString,pythonUniRawString,pythonRawString
  else
    syn match pythonStrTemplate '\$\$' contained containedin=pythonString,pythonRawString
    syn match pythonStrTemplate '\${[a-zA-Z_][a-zA-Z0-9_]*}' contained containedin=pythonString,pythonRawString
    syn match pythonStrTemplate '\$[a-zA-Z_][a-zA-Z0-9_]*' contained containedin=pythonString,pythonRawString
  endif
endif

"------------------------------------------------------------------------------"
" Default highlighting  {{{2
"------------------------------------------------------------------------------"
" This is fast but code inside triple quoted strings screws it up. It
" is impossible to fix because the only way to know if you are inside a
" triple quoted string is to start from the beginning of the file.
if s:enabled('g:python_slow_sync')
  syn sync minlines=2000
else
  syn sync match pythonSync grouphere NONE '):$'
  syn sync maxlines=200
endif

" General highlighting
hi def link pythonStatement Statement
hi def link pythonRaiseFromStatement Statement
hi def link pythonImport Include
hi def link pythonFunction Function
hi def link pythonFunctionCall Function
hi def link pythonConditional Conditional
hi def link pythonMatch Conditional
hi def link pythonRepeat Repeat
hi def link pythonException Exception
hi def link pythonOperator Operator
hi def link pythonDecorator Define
hi def link pythonDottedName Function
hi def link pythonBuiltinObj Identifier
hi def link pythonBuiltinFunc Function
hi def link pythonBuiltinType Structure
hi def link pythonExClass Structure
hi def link pythonClass Structure
hi def link pythonClassVar Identifier
hi def link pythonComment Comment
hi def link pythonTodo Todo
hi def link pythonError Error
hi def link pythonIndentError Error
hi def link pythonSpaceError Error
hi def link pythonString String
hi def link pythonRawString String
hi def link pythonRawEscape Special
hi def link pythonUniEscape Special
hi def link pythonUniEscapeError Error
if !s:enabled('g:python_highlight_file_headers_as_comments')
  hi def link pythonCoding Special
  hi def link pythonRun Special
endif

" Literal highlighting
hi def link pythonStrFormatting Special
hi def link pythonStrFormat Special
hi def link pythonStrTemplate Special
hi def link pythonDocTest Special
hi def link pythonDocTest2 Special
hi def link pythonNumber Number
hi def link pythonHexNumber Number
hi def link pythonOctNumber Number
hi def link pythonBinNumber Number
hi def link pythonFloat Float
hi def link pythonNumberError Error
hi def link pythonOctError Error
hi def link pythonHexError Error
hi def link pythonBinError Error
hi def link pythonBoolean Boolean
hi def link pythonNone Constant
hi def link pythonSingleton Constant
if s:python2()
  hi def link pythonUniString String
  hi def link pythonUniRawString String
  hi def link pythonUniRawEscape Special
  hi def link pythonUniRawEscapeError Error
else
  hi def link pythonBytes String
  hi def link pythonRawBytes String
  hi def link pythonBytesContent String
  hi def link pythonBytesError Error
  hi def link pythonBytesEscape Special
  hi def link pythonBytesEscapeError Error
  hi def link pythonFString String
  hi def link pythonRawFString String
endif
let b:current_syntax = 'python'
