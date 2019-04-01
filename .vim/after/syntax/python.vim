"------------------------------------------------------------------------------"
" ReST highlighting of docstrings
" From: http://www.slabbe.org/blogue/2011/06/rest-syntax-highlighting-for-sage-docstrings-in-vim/
"------------------------------------------------------------------------------"
" This thing fails!
finish
" Some new highlight groups
hi Prompt guifg=#80a0ff
hi PyDocString guifg=DarkGray
hi SageDocStringKeywords guifg=LightGray gui=underline,bold

" Load the ReST syntax file; but first we clear the current syntax
" definition, as rst.vim does nothing if b:current_syntax is defined.
let s:current_syntax=b:current_syntax
unlet b:current_syntax
" Load the ReST syntax file
syntax include @ReST $VIMRUNTIME/syntax/rst.vim
let b:current_syntax=s:current_syntax
unlet s:current_syntax

" clear the rstLiteralBlock
" TODO: improve this; this should apply to all
" pythonDocString regions but the sageDoctest regions
syntax clear rstLiteralBlock

" By using the nextgroup argument below, we are giving priority to
" pythonDocString over all other groups. This means that a pythonDocString
" can only begin a :
syntax match beginPythonBlock ":$" nextgroup=pythonDocString skipempty skipwhite
hi link beginPythonBlock None

syntax region pythonDocString
    \ start=+[uUr]\='+
    \ end=+'+
    \ contains=sageDoctest,pythonEscape,@Spell,@ReST,SageDocStringKeywords
    \ contained
    \ fold
syntax region pythonDocString
    \ start=+[uUr]\="+
    \ end=+"+ 
    \ contains=sageDoctest,pythonEscape,@Spell,@ReST,SageDocStringKeywords
    \ contained
    \ fold
syntax region pythonDocString
    \ matchgroup=PyDocString
    \ start=+[uUr]\="""+
    \ end=+"""+
    \ contains=sageDoctest,pythonEscape,@Spell,@ReST,SageDocStringKeywords,sageInputs
    \ contained
    \ skipempty
    \ skipwhite
    \ keepend
    \ fold
syntax region pythonDocString
    \ matchgroup=PyDocString
    \ start=+[uUr]\='''+
    \ end=+'''+
    \ contains=sageDoctest,pythonEscape,@Spell,@ReST,SageDocStringKeywords
    \ contained
    \ skipempty
    \ skipwhite
    \ keepend
    \ fold
hi link pythonDocString	PyDocString

" clear the pythonDoctest and pythonDoctestValue syntax groups
syntax clear pythonDoctest
syntax clear pythonDoctestValue

syntax region sageDoctest
    \ start=+^\s*sage:\s+
    \ end=+\%(^\s*$\|^\s*"""$\)+
    \ contains=ALLBUT,sageDoctest,@ReST,@Spell
    \ contained 
    \ nextgroup=sageDoctestValue
hi link sageDoctest	SpecialComment

syntax region sageDoctestValue
    \ start=+^\s*\%(sage:\s\|>>>\s\|\.\.\.\)\@!\S\++
    \ end="$"
    \ contains=NONE
    \ contained 
hi link sageDoctestValue Define

syntax match sagePrompt "sage:" containedin=sageDoctest contained
hi link sagePrompt Prompt

syntax case match
syntax keyword sageDocStringKeywords INPUT OUTPUT AUTHORS EXAMPLES TESTS
hi link sageDocStringKeywords SageDocStringKeywords

" Look back at least 200 lines to compute the syntax highlighting
syntax sync minlines=200
