"------------------------------------------------------------------------------
" TABLINE MODIFICATION
"------------------------------------------------------------------------------
"Change highlghting groups; Tabline formats tab names better
set showtabline=1
  "always show, even if 1 file
hi TabLine      ctermfg=White  ctermbg=Black     cterm=bold
hi TabLineFill  ctermfg=White  ctermbg=Black     cterm=bold
hi TabLineSel   ctermfg=Black  ctermbg=White     cterm=bold
"Hijacked from Tabline function, and modified
let g:bufignore = ['nerdtree', 'tagbar', 'codi', 'help'] "filetypes considered 'helpers'
function! Tabline()
  let s = '' "the tab title
  for i in range(tabpagenr('$')) "iterate through each tab
    let tab = i + 1 "the tab number
    let buflist = tabpagebuflist(tab)
    for b in buflist "get the 'primary' panel in a tab, ignore 'helper' panels even if they are in focus
      let buftype = getbufvar(b, "&filetype")
      if index(g:bufignore, buftype)==-1 "index returns -1 if the item is not contained in the list
        let bufnr = b "we choose this as our 'primary' file for tab title
        break
      elseif b==buflist[-1] "occurs if e.g. entire tab is a help window; EXCEPTION, and use it for tab title
        let bufnr = b
      endif
    endfor
    let bufname = bufname(bufnr) "actual name
    let bufmodified = getbufvar(bufnr, "&mod")
    let s .= '%' . tab . 'T' "start 'tab' here; denotes edges of highlight groups and clickable area
    let s .= (tab == tabpagenr() ? '%#TabLineSel#' : '%#TabLine#') "the # encodes string with either highlight group
    let s .= ' ' . tab .':' "prefer zero-indexing
    let fname = fnamemodify(bufname, ':t')
    let fname = (len(fname) > 12 ? fname[:12].'·' : fname) "first 16 letters
    " let fname = (len(fname) > 12 ? fname[:12].'…' : fname) "first 16 letters
    " let fname = (len(fname) > 16 ? fname[:16].'⋯' : fname) "first 16 letters
    let s .= (bufname != '' ? '['. fname . '] ' : '[?] ')
    if bufmodified
      let s .= '[+] '
    endif
  endfor
  let s .= '%#TabLineFill#'
  return s
endfunction
set tabline=%!Tabline()

