"-----------------------------------------------------------------------------"
" Disable spell check in comments
" Accomplished by overwriting existing syntax group
"-----------------------------------------------------------------------------"
syn region htmlComment start=+<!--+ end=+--\s*>+ contains=@NoSpell
