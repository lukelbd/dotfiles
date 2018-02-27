"------------------------------------------------------------------------------
" TABLINE MODIFICATION
"------------------------------------------------------------------------------
"Change highlghting groups; Tabline formats tab names better
set showtabline=1
  "always show, even if 1 file
hi TabLine     ctermfg=White ctermbg=Black cterm=None
hi TabLineFill ctermfg=White ctermbg=Black cterm=None
hi TabLineSel  ctermfg=Black ctermbg=White cterm=None
"Hijacked from Tabline function, and modified
"Only display name of a 'primary' file, not e.g. tagbar
let g:charmax=12 "maximum characters for filename
let g:bufignore = ['nerdtree', 'tagbar', 'codi', 'help'] "filetypes considered 'helpers'
function! Tabline()
  let tabstrings = [] "put strings in list
  let tabtexts = [] "actual text on screen
  for i in range(tabpagenr('$')) "iterate through each tab
    let tabstring = '' "initialize string
    let tabtext = ''
    let tab = i + 1 "the tab number
    let buflist = tabpagebuflist(tab) "call with arg to specify number, or without to specify current tab
    for b in buflist "get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
      if index(g:bufignore, getbufvar(b, "&ft"))==-1 "index returns -1 if the item is not contained in the list
        let bufnr = b "we choose this as our 'primary' file for tab title
        break
      elseif b==buflist[-1] "occurs if e.g. entire tab is a help window; EXCEPTION, and use it for tab title
        let bufnr = b
      endif
    endfor
    if tab==tabpagenr()
      let g:bufmain=bufnr
    endif
    let bufname = bufname(bufnr) "actual name
    let bufmodified = getbufvar(bufnr, "&mod")
    "Start the tab string
    let tabstring .= '%' . tab . 'T' "start 'tab' here; denotes edges of highlight groups and clickable area
    let tabstring .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#') "the # encodes string with either highlight group
    let tabtext .= ' ' . tab .'' "prefer zero-indexing
    "File name or placeholder if empty
    let fname = fnamemodify(bufname, ':t')
    if len(fname)-2 > g:charmax
      let offset = len(fname)-g:charmax
      if offset%2==1 | let offset+=1 | endif
      let fname = '·'.fname[offset/2:len(fname)-offset/2].'·' "… use this maybe
      " let fname = fname[:g:charmax].'·'
    endif
    let tabtext .= (bufname != '' ? '|'. fname . ' ' : '[?] ')
    "Modification marker
    if bufmodified
      let tabtext .= '[+] '
    endif
    "Add stuff to lists
    let tabstrings += [tabstring . tabtext]
    let tabtexts += [tabtext]
  endfor
  "Finally modify if too long
  "See :help non-greedy for explanation of the \{-} params; indicate trying
  "to match as few as possible; remember not to use double quotes here!
  let prefix = ''
  let suffix = ''
  let tabstart = 1 "will modify this as delete tabs
  let tabend = tabpagenr('$') "same
  let tabpage = tabpagenr() "continually test position relative to tabstart/tabend
  while len(join(tabtexts,'')) > &columns "replace leading/trailing tabs with dots in meantime
    if tabend-tabpage > tabpage-tabstart "VIM lists are zero-indexed, end-inclusive
      let tabstrings = tabstrings[:-2]
      let tabtexts = tabtexts[:-2]
      let suffix = '···'
      let tabend -= 1 "decrement; have blotted out one tab on right
    else
      let tabstrings = tabstrings[1:]
      let tabtexts = tabtexts[1:]
      let prefix = '···'
      let tabstart += 1 "increment; have blotted out one tab on left
    endif
  endwhile
  "Return final version
  return prefix . join(tabstrings,'') . suffix . '%#TabLineFill#'
endfunction
set tabline=%!Tabline()

