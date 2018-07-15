"------------------------------------------------------------------------------
" STATUSLINE MODIFICATION
"------------------------------------------------------------------------------
"Alway show
let g:nostatus="tagbar,nerdtree"
set laststatus=2
"Command line below statusline
set showcmd
set noshowmode
" au BufEnter * let &stl='%{ShortenFilename()}%{FileInfo()}%{PrintMode()}%{Git()}%{PrintLanguage()}%{CapsLock()}%=%{Tag()}%{Location()}'
" au BufReadPost * let &stl='%{ShortenFilename()}%{FileInfo()}%{PrintMode()}%{Git()}%{PrintLanguage()}%{CapsLock()}%=%{Tag()}%{Location()}'
" au FileType tagbar,nerdtree let &stl=' ' "don't work
" au BufEnter *[Tt]agbar*,*[Nn][Ee][Rr][Dd]*[Tt]ree* let &l:stl=' ' "empty returns default; use non-empty
"Define all the different modes
"Show whether in pastemode
function! PrintMode()
  "Dictionary
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  let currentmode={
    \ 'n':  'Normal',  'no': 'N-Operator Pending',
    \ 'v':  'Visual',  'V' : 'V-Line',  '': 'V-Block',
    \ 's':  'Select',  'S' : 'S-Line',  '': 'S-Block',
    \ 'i':  'Insert',  'R' : 'Replace', 'Rv': 'V-Replace',
    \ 'c':  'Command', 'r' : 'Prompt',
    \ 'cv': 'Vim Ex',  'ce': 'Ex',
    \ 'rm': 'More',    'r?': 'Confirm', '!' : 'shell',
    \}
  " let print=toupper(currentmode[mode()])
  let l:string=currentmode[mode()]
  if &paste
    let l:string.=':Paste'
  endif
  return '  ['.l:string.']'
  " return ' ['.string.']'
endfunction
"Caps lock (are language maps enabled?)
function! CapsLock()
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  if &iminsert "iminsert is the option that enables/disables language remaps (lnoremap)
      "and if it is on, we turn on the caps-lock remaps
    return '  [CapsLock]'
  else
    return ''
  endif
endfunction
"Shorten a given filename by truncating path segments.
"https://github.com/blueyed/dotfiles/blob/master/vimrc#L396
function! ShortenFilename() "{{{
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  "Necessary args
  let bufname=@%
  let maxlen=20
  "Replace home directory
  if bufname=~$HOME
    let bufname='~'.split(bufname,$HOME)[-1]
  endif
  "Body
  let maxlen_of_parts = 7 " including slash/dot
  let maxlen_of_subparts = 5 " split at dot/hypen/underscore; including split
  let s:PS = exists('+shellslash') ? (&shellslash ? '/' : '\') : "/"
  let parts = split(bufname, '\ze['.escape(s:PS, '\').']')
  let i = 0
  let n = len(parts)
  let wholepath = '' " used for symlink check
  while i < n
    let wholepath .= parts[i]
    " Shorten part, if necessary:
    if i<n-1 && len(bufname) > maxlen && len(parts[i]) > maxlen_of_parts
    " Let's see if there are dots or hyphens to truncate at, e.g.
    " 'vim-pkg-debian' => 'v-p-d…'
    let w = split(parts[i], '\ze[._-]')
    if len(w) > 1
      let parts[i] = ''
      for j in w
      if len(j) > maxlen_of_subparts-1
        let parts[i] .= j[0:maxlen_of_subparts-2]."·"
      else
        let parts[i] .= j
      endif
      endfor
    else
      let parts[i] = parts[i][0:maxlen_of_parts-2]."·"
    endif
    endif
    " add indicator if this part of the filename is a symlink
    if getftype(wholepath) == 'link'
    if parts[i][0] == s:PS
      let parts[i] = parts[i][0] . '↪ ./' . parts[i][1:]
    else
      let parts[i] = '↪ ./' . parts[i]
    endif
    endif
    let i += 1
  endwhile
  let r = join(parts, '')
  return r
endfunction "}}}
"Find out current buffer's size and output it.
function! FileInfo() "{{{
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  if &ft=="" | let l:string="unknown:"
  else | let l:string=&ft.":"
  endif
  let bytes = getfsize(expand('%:p'))
  if (bytes >= 1024)
    let kbytes = bytes / 1024
  endif
  if (exists('kbytes') && kbytes >= 1000)
    let mbytes = kbytes / 1000
  endif
  if bytes <= 0
    let l:string.='null'
  endif
  if (exists('mbytes'))
    let l:string.=(mbytes.'MB')
  elseif (exists('kbytes'))
    let l:string.=(kbytes.'KB')
  else
    let l:string.=(bytes.'B')
  endif
  return '  ['.l:string.']'
endfunction "}}}
"Whether UK english (e.g. Nature), or U.S. english
function! PrintLanguage()
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  if &spell
    if &spelllang=='en_us'
      return '  [US]'
    elseif &spelllang=='en_gb'
      return '  [UK]'
    else
      return '  [??]'
    endif
  else
    return ''
  endif
endfunction
"Git stuff
function! Git()
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  if exists('*fugitive#head') && fugitive#head()!=''
    let status=fugitive#head() 
    return '  ['.toupper(status[0]).tolower(status[1:]).']'
  else
    return ''
  endif
endfunction
"Location
function! Location()
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  return '  ['.line('.').'/'.line('$').'] ('.(100*line('.')/line('$')).'%)' "current line and percentage
endfunction
"Tag
function! Tag()
  let maxlen=10 "can change this
  if &ft && g:nostatus=~?&ft
    return ''
  endif
  if !exists('*tagbar#currenttag') | return '' | endif
  let string=tagbar#currenttag('%s','')
  if string=='' | return '' | endif
  if len(string)>=maxlen | let string=string[:maxlen-1].'···' | endif
  return '  ['.string.']'
endfunction
"Current tag using my own function
"Consider modifying this
" function! CurrentTag()
"   let a:njumps=(a:n==0 ? 1 : a:n)
"   for i in range(a:njumps)
"     let lnum=line('.')
"     "Edge cases; at bottom or top of document
"     if lnum<b:ctaglines[0] || lnum>b:ctaglines[-1]
"       let i=(a:foreward ? 0 : -1)
"     "Extra case not handled in main loop
"     elseif lnum==b:ctaglines[-1]
"       let i=(a:foreward ? 0 : -2)
"     "Main loop
"     else
"       for i in range(len(b:ctaglines)-1)
"         if lnum==b:ctaglines[i]
"           let i=(a:foreward ? i+1 : i-1) | break
"         elseif lnum>b:ctaglines[i] && lnum<b:ctaglines[i+1]
"           let i=(a:foreward ? i+1 : i) | break
"         endif
"         if i==len(b:ctaglines)-1 | echom "Error: Bracket jump failed." | endif
"       endfor
"     endif
"     exe b:ctaglines[i]
"   endfor
" endfunction
let &stl=''                      " Clear statusline for when vimrc is loaded
let &stl.='%{ShortenFilename()}' " Current buffer's file name
let &stl.='%{FileInfo()}'        " Output buffer's file size
let &stl.='%{PrintMode()}'       " Normal/insert mode
let &stl.='%{Git()}'             " Fugitive branch
let &stl.='%{PrintLanguage()}'   " Show language setting: UK english or US enlish
let &stl.='%{CapsLock()}'        " Check if language maps enabled
let &stl.='%='                   " Right side of statusline, and perserve space between sides
let &stl.='%{Tag()}'
let &stl.='%{Location()}'        " Cursor's current line, total lines, and percentage
" let &stl.=' %{ObsessionStatus()}' "useless

