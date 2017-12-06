"------------------------------------------------------------------------------
" STATUSLINE MODIFICATION
"------------------------------------------------------------------------------
"Alway show
set laststatus=2
"Command line below statusline
set showcmd
set noshowmode
"Colors
highlight StatusLine ctermbg=White ctermfg=Black cterm=Bold
au InsertEnter * highlight StatusLine ctermbg=Black ctermfg=White cterm=Bold
au InsertLeave * highlight StatusLine ctermbg=White ctermfg=Black cterm=Bold
  "more visible insert mode
" Define all the different modes
" Show whether in pastemode
function! PrintMode()
  " Dictionary
  let a:currentmode={
    \ 'n'  : 'Normal', 'no' : 'N-Operator Pending',
    \ 'v'  : 'Visual', 'V'  : 'V-Line', '' : 'V-Block', 's'  : 'Select', 'S'  : 'S-Line', '' : 'S-Block',
    \ 'i'  : 'Insert', 'R'  : 'Replace', 'Rv' : 'V-Replace',
    \ 'c'  : 'Command', 'r'  : 'Prompt',
    \ 'cv' : 'Vim Ex', 'ce' : 'Ex',
    \ 'rm' : 'More', 'r?' : 'Confirm', '!'  : 'Shell',
    \}
  let a:print=a:currentmode[mode()]
  if &paste
    let a:print.=':Paste'
  endif
  return a:print
endfunction
"Caps lock (are language maps enabled?)
function! CapsLock()
  if &iminsert
      "iminsert is the option that enables/disables language remaps (lnoremap)
      "and if it is on, we turn on the caps-lock remaps
    return '[CAPSLOCK] '
  else
    return ''
  endif
endfunction
" Shorten a given filename by truncating path segments.
" https://github.com/blueyed/dotfiles/blob/master/vimrc#L396
function! ShortenFilename() "{{{
  "Necessary args
  let a:bufname=@%
  let a:maxlen=20
  "Body
  let maxlen_of_parts = 7 " including slash/dot
  let maxlen_of_subparts = 5 " split at dot/hypen/underscore; including split
  let s:PS = exists('+shellslash') ? (&shellslash ? '/' : '\') : "/"
  let parts = split(a:bufname, '\ze['.escape(s:PS, '\').']')
  let i = 0
  let n = len(parts)
  let wholepath = '' " used for symlink check
  while i < n
    let wholepath .= parts[i]
    " Shorten part, if necessary:
    if i<n-1 && len(a:bufname) > a:maxlen && len(parts[i]) > maxlen_of_parts
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
" Find out current buffer's size and output it.
function! FileSize() "{{{
  let bytes = getfsize(expand('%:p'))
  if (bytes >= 1024)
    let kbytes = bytes / 1024
  endif
  if (exists('kbytes') && kbytes >= 1000)
    let mbytes = kbytes / 1000
  endif
  if bytes <= 0
    return 'null'
  endif
  if (exists('mbytes'))
    return mbytes . 'MB'
  elseif (exists('kbytes'))
    return kbytes . 'KB'
  else
    return bytes . 'B'
  endif
endfunction "}}}
"Whether UK english (e.g. Nature), or U.S. english
function! PrintLanguage()
  if &spell
    if &spelllang=='en_us'
      return '[US]'
    elseif &spelllang=='en_gb'
      return '[UK]'
    else
      return '[??]'
    endif
  else
    return ''
  endif
endfunction
"Set statusline
let &stl=''        " Clear statusline for when vimrc is loaded
" let &stl.='%{ShortenFilename()}'.     " Current buffer's file name
"       \ ' [%{&ft!=""?&ft.":":"unknown:"}%{FileSize()}]'. " Output buffer's file size
let &stl.='%{ShortenFilename()}'     " Current buffer's file name
let &stl.=' [%{&ft!=""?&ft.":":"unknown:"}%{FileSize()}]' " Output buffer's file size
let &stl.=' [%{PrintMode()}]' " Normal/insert mode
let &stl.=' %{ObsessionStatus()}' " Whether obsession if functioning
let &stl.=' %m'     " Show modified status of buffer
let &stl.='%{PrintLanguage()}' " Show language setting: UK english or US enlish
let &stl.='%= '     " Right side of statusline, and perserve space between sides
let &stl.='%{CapsLock()}'    " check if language maps enabled
let &stl.=' [%l/%L]'   " Cursor's current line, total lines
let &stl.=' (%p%%)' " Percentage through file in lines, as in <c-g>

