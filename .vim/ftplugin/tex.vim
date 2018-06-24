"------------------------------------------------------------------------------"
"LaTeX Templates
"Prompt user to choose from a list of templates (located in ~/latex folder)
"when creating a new LaTeX file
"See: http://learnvimscriptthehardway.stevelosh.com/chapters/35.html
"So far no other features here
"------------------------------------------------------------------------------"
augroup tex_templates
  au!
  au BufNewFile *.tex call s:textemplates()
  "no worries since ever TeX file should end in .tex; can't
  "think of situation where that's not true
augroup END
function! s:textemplates()
  let templates=split(globpath('~/latex/', '*.tex'),"\n")
  let names=[]
  for template in templates
    call add(names, '"'.fnamemodify(template, ":t:r").'"')
    "expand does not work, for some reason... because expand is used with one argument
    "with a globalfilename, e.g. % (current file)... fnamemodify is for strings
  endfor
  while 1
    echo "Current templates available: ".join(names, ", ")."."
    let template=expand("~")."/latex/".input("Enter choice: ").".tex"
    if filereadable(template)
      execute "0r ".template
      break
    endif
    echo "\nInvalid name."
  endwhile
endfunction

