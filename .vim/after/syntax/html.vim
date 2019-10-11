" Disable spell check in comments by *overwriting* existing
" syntax group. Easy peasy.
syn region htmlComment start=+<!--+ end=+--\s*>+ contains=@NoSpell
