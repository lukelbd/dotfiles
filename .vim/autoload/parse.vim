"-----------------------------------------------------------------------------"
" Utilities for parsing input
"-----------------------------------------------------------------------------"
" Get the project 'root' from input directory
" Note: Root detectors are copied from g:gutentags_add_default_root_markers.
" Note: Previously tried just '__init__.py' for e.g. conda-managed packages and
" placing '.tagproject' in vim-plug folder but this caused tons of nested .vimtags
" file creations including *duplicate* tags when invoking :Tags function.
function! s:proj_root(head, globs, ...) abort
  let roots = []  " general projects
  let root = fnamemodify(a:head, ':p')
  while !empty(root) && root !=# '/'
    let root = fnamemodify(root, ':h')
    call add(roots, root)
  endwhile
  for root in a:0 && a:1 ? reverse(roots) : roots
    for glob in a:globs  " input names or patterns
      if !empty(globpath(root, glob, 0, 1)) | return root | endif
    endfor
  endfor | return ''
endfunction
function! s:dist_root(head, tails, ...) abort
  let head = a:head  " general distributions
  let tail = fnamemodify(head, ':t')
  let idx = index(a:tails, tail)
  if idx >= 0  " avoid e.g. ~/software/.vimtags
    let default = expand('~/dotfiles')
    let tail = get(a:000, idx, '')
    return empty(tail) ? default : head . '/' . tail
  endif
  while v:true  " see also tags#tag_files()
    let ihead = fnamemodify(head, ':h')
    if empty(ihead) || ihead ==# head | let head = '' | break | endif
    let idx = index(a:tails, fnamemodify(ihead, ':t'))
    if idx >= 0 | break | endif  " preceding head e.g. share/vim
    let head = ihead  " tag file candidate
  endwhile
  let tail = fnamemodify(head, ':t')  " e.g. /.../share/vim -> vim
  let suff = strpart(a:head, len(head))  " e.g. /.../share/vim/vim91 -> vim91
  let suff = matchstr(suff, '^[\/]\+' . tail . '[0-9]*[\/]\@=')
  return head . suff  " optional version subfolder
endfunction
function! parse#find_root(...) abort
  let path = resolve(expand(a:0 ? a:1 : '%'))
  let head = fnamemodify(path, ':p:h')  " no trailing slash
  let tails = ['servers', 'user-settings']  " e.g. @jupyterlab, .vim_lsp_settings
  let root = s:dist_root(head, tails)
  if !empty(root) | return root | endif
  let globs = ['.git', '.hg', '.svn', '.bzr', '_darcs', '_darcs', '_FOSSIL_', '.fslckout']
  let root = s:proj_root(head, globs, 0)  " highest-level control system indicator
  if !empty(root) | return root | endif
  let globs = ['__init__.py', 'setup.py', 'setup.cfg']
  let root = s:proj_root(head, globs, 1)  " lowest-level python distribution indicator
  if !empty(root) | return root | endif
  let projs = ['builds', 'local', 'share', 'bin']
  let homes = ['com~apple~CloudDocs', 'icloud', 'software', 'research', '']
  let defaults = ['Mackup', 'Mackup', '', 'dotfiles']
  let root = s:dist_root(head, homes + projs, defaults)
  if !empty(root) | return root | endif
  return head
endfunction

" Get paths from the open files and projects
" Note: If input directory is getcwd() then fnamemodify(getcwd(), ':~:.') returns only
" home directory shortened path (not dot or empty string). Convert to empty string
function! parse#get_paths(mode, global, level, ...)
  let args = filter(copy(a:000), '!empty(v:val)')  " ignore e.g. command entry
  if !empty(args)  " manual input
    let paths = map(args, 'resolve(v:val)')
  elseif a:global  " global buffers
    let paths = map(reverse(tags#get_paths()), 'resolve(v:val)')
  else  " current buffer
    let paths = [resolve(expand('%:p'))]
  endif
  if empty(args) && a:level >= 2  " path projects
    let paths = map(paths, 'parse#find_root(v:val)')
  elseif empty(args) && a:level >= 1  " path folders
    let paths = map(paths, "empty(v:val) || isdirectory(v:val) ? v:val : fnamemodify(v:val, ':h')")
  else  " general paths and folders
    let paths = filter(paths, 'isdirectory(v:val) || filereadable(v:val)')
  endif
  let result = []
  let unique = 'index(paths, v:val, v:key + 1) == -1'
  let outer = 'len(v:val) < len(path) && strpart(path, 0, len(v:val)) ==# v:val'
  for path in filter(copy(paths), unique)  " unique
    let inner = !empty(filter(copy(paths), outer))
    if inner && a:level > 2 | continue | endif  " e.g. ignore 'plugged' when in dotfiles
    let path = RelativePath(path)
    if path =~# '^icloud\>'
      let path = RelativePath(expand('~/' . path))
    elseif empty(path) && (a:mode > 0 || len(paths) > 1)
      let path = './'  " trailing slash as with other folders
    endif
    if !empty(path)  " otherwise return empty list
      call add(result, path)
    endif
  endfor
  return result
endfunction

" Get .ignore excludes for find and ctags (compare to bash ignores())
" Note: Critical to remove trailing slash for ctags recursive searching.
" Note: For some reason parsing '--exclude-exception' rules for g:fzf_tags_command
" does not work, ignores all other exclude flags, and vim-gutentags can only
" handle excludes anyway, so just bypass all patterns starting with '!'.
function! parse#get_ignores(level, skip, mode, ...) abort
  let nofiles = a:skip == 2
  let nodirs = a:skip == 1
  let paths = []  " search level
  if a:level <= 0
    call add(paths, '~/.gitignore')
  endif
  if a:level <= 1
    call add(paths, '~/.ignore')
  endif
  if a:level <= 2  " slowest so put last
    call add(paths, '~/.wildignore')
  endif
  let result = []
  call extend(paths, a:000)
  for path in paths
    let path = resolve(expand(path))
    if !filereadable(path) | continue | endif
    for line in readfile(path)
      if line =~# '^\s*\(#.*\)\?$' | continue | endif
      if nodirs && line =~# '/' | continue | endif
      if nofiles && line !~# '/' | continue | endif
      let item = substitute(trim(line), '\/$', '', '')
      if a:mode <= 0
        call add(result, item)
      elseif a:mode == 1  " ctags exclude
        if item =~# '/' | continue | endif  " not implemented
        if item[0] ==# '!'  " exclusion prepended with !
          call add(result, '--exclude-exception=' . item[1:])
        else  " standard exclusion
          call add(result, '--exclude=' . item)
        endif
      else  " find prune
        let flag = item =~# '/' ? '-path' : '-name'  " e.g. foo/bar
        let item = item =~# '/' ? '*/' . item . '/*' : item
        if item[0] ==# '!' | continue | endif  " not implemented
        if empty(result)
          call extend(result, [flag, shellescape(item)])
        else  " additional match
          call extend(result, ['-o', flag, shellescape(item)])
        endif
      endif
    endfor
  endfor
  if a:mode > 1 && !empty(result)
    let result = ['\('] + result + ['\)']  " prune groups
    let result = result + ['-prune', '-o']  " follow with e.g. -print
    if nofiles
      let result = ['-type', 'd'] + result
    elseif nodirs
      let result = ['-type', 'f'] + result
    endif
  endif
  return result
endfunction

" Get the register or name from count
" Note: Here default mark is top of stack (plus one if recording), default macro
" recording register is zero (move to one if non-empty), default macro execution
" register is one (recent successful recording), and default register is unnamed.
" Note: This translates counts passed to yanks/change/delete/paste to first
" 20 letters of alphabet, counts passed to macro records/plays to next 6 letters of
" alphabet, and counts passed to mark sets/jumps to first 24 letters of alphabet.
function! s:get_mark(mode) abort
  let offset = a:mode ==# 'm' ? 1 : 0  " offset
  let stack = get(g:, 'mark_stack', [])  " recent mark stack
  let base = char2nr('A')  " default mark
  let init = nr2char(base - offset)  " initial value
  let cnum = char2nr(get(stack, -1, init))
  return nr2char(cnum + offset)
endfunction
function! s:get_label(name) abort
  let label = ''  " default label
  if a:name ==# '_'
    let label = 'blackhole'
  elseif a:name =~# '[+*]'
    let label = 'clipboard'
  elseif a:name =~# '\d'  " use character to pick number register
    let label = getreg(a:name)
  elseif v:count
    let label = v:count ? 'count ' . v:count : ''
  endif
  return label
endfunction
function! s:get_props(mode, count) abort
  if a:mode =~# '[m`]'  " marks: uppercase a-z (64+1-64+26)
    let [default, name1, name2] = [s:get_mark(a:mode), 'A', 'Z']
  elseif a:mode =~# '[q@]'  " macros: lowercase q-z (96+17-96+26)
    let [default, name1, name2] = [a:mode ==# 'q' ? '0' : '1', '1', '9']
  else  " registers: lowercase a-p (96+1-96+16)
    let [default, name1, name2] = ['"', 'a', 'z']
  endif
  let cmax = char2nr(name2) - char2nr(name1) + 1  " register range
  let cnum = char2nr(name1) + min([a:count, cmax]) - 1
  let name = a:count > 0 ? nr2char(cnum) : default
  return [name, name1, name2, cmax]
endfunction

" Get the register or name translated from input arguments
" Note: This supports e.g. pasting macro keys with e.g. 1"p then quickly editing them
" and copying back into macro register with e.g. 1"dil. Also rotates yanks, changes,
" and deletions across a-z registers and macros across 1-9 registers (see above)
function! s:get_input(mode, default) abort
  let char = utils#input_default('Register', '', '', 1)
  if char =~? '^[dcyp]$'  " default register
    call feedkeys(char, 'm') | return a:default
  endif
  if char =~# '^[''"]$\|^\s$'
    return '"'  " unnamed register
  elseif char ==# "\<C-g>"
    return fugitive#Object(@%)  " replace native y<C-g> <C-r><C-g> maps
  elseif len(char) != 1 || char !~? '^\p$\|^\t$'
    call feedkeys(char, 'm') | return ''
  elseif char =~# '^\d$'  " select macro number register
    return s:get_props(a:mode, str2nr(char))[0]
  else
    return char
  endif
endfunction
function! parse#get_register(mode, ...) abort
  if v:register !=# '"' | return '' | endif  " avoid recursion
  let [name, _, _, cmax] = s:get_props(a:mode, v:count)
  if a:mode =~# '[ic]'
    let name = s:get_input(a:mode, '"')
  elseif a:0 && !v:count  " default value
    let name = s:get_input(a:mode, a:1)
  endif
  if empty(name)  " clear message
    redraw | echo '' | return ''
  elseif !v:count && a:mode !~# '[icq@m`]'
    call parse#setup_registers()  " queue register changes
  endif
  let warn = '' | if v:count > cmax  " emit warning
    let warn .= ' Truncating count ' . v:count . ' to ' . string(name) . ' (count ' . cmax . ')'
  endif
  if a:mode ==# 'm' && index(map(getmarklist(), 'v:val.mark'), "'" . name) != -1
    let warn .= ' Overwriting mark ' . string(name) . ' (count ' . v:count . ')'
  endif
  let label = s:get_label(name)
  let group = a:mode =~# '[m`]' ? 'Mark' : name =~# '^\d$' ? 'Macro' : 'Register'
  if !empty(warn)
    redraw | echohl WarningMsg | echom 'Warning: ' . trim(warn) | echohl None
  elseif name !=# '"'  " show register
    redraw | echom group . ': ' . name[0] . (empty(label) ? '' : ' (' . label . ')')
  endif
  if a:mode =~# '[ic]'  " insert or cmdline mode
    let name = "\<C-r>" . name
  elseif !a:0 && a:mode =~# '[q@]'
    let name = a:mode . name  " e.g. 1Q -> q1, 1@ -> @1
  elseif a:0 || a:mode !~# '[q@m`]'
    let name = '"' . name  " e.g. 1' -> \"a, 1y -> \"ay
  endif
  return v:count && mode() ==# 'n' ? "\<Esc>" . name : name
endfunction

" Set the register and rotate other entries forward
" Note: This auto-cycles previous register contents if input count was empty, either
" immediately for macros or delaying until TextYankPost i.e. delete or yank finished.
" Note: This radically overrides native register system by using numbered registers
" 1 through 9 for macros (0 while recording, assigned conditionally if non-empty) and
" letter registers for deletes and yanks. Also tried using -/+ for most recent v/V
" deletions but + is locked to * on mac and - cannot be assigned regtype V so ignore.
function! parse#set_register(info, dest, ...) abort
  let dest1 = type(a:dest) ? a:dest : nr2char(a:dest)
  let dest2 = a:0 ? type(a:1) ? a:1 : nr2char(a:1) : dest1
  for char in range(char2nr(dest2), char2nr(dest1) + 1, -1)
    let prev = getreginfo(nr2char(char - 1))
    let prev.isunnamed = v:false
    call setreg(nr2char(char), prev)
  endfor | call setreg(dest1, a:info)  " changes unnamed if isunnamed=v:true
endfunction
function! parse#set_translate(name, mode) abort
  let [_, name1, name2, _] = s:get_props(a:mode, 0)
  let info = getreginfo(a:name)  " information
  let info.isunnamed = a:mode =~# '[q@m`]' ? v:false : v:true
  if has_key(info, 'points_to') | call remove(info, 'points_to') | endif
  if a:name ==# '"' || a:name ==# '0'
    if a:name ==# '0' && a:mode ==# 'q' && getreg(a:name) !~# '\p\|\t'
      echom 'Cancelled macro' | return a:name
    elseif a:name !=# '0' || a:mode ==# 'q'  " push 0 for recordings only
      call parse#set_register(info, name1, name2)
    endif
  endif
  if a:mode ==# 'q' | echom 'Finished macro' | endif | return name1
endfunction
function! parse#setup_registers() abort
  let b:registers = {}
  let regs = map(range(0, 9), 'string(v:val)')
  for name in regs  " restore macros
    let info = getreginfo(name)
    let info.isunnamed = v:false
    let b:registers[name] = info
  endfor
  let restore = "call map(get(b:, 'registers', {}), 'setreg(v:key, v:val)')"
  let rotate = 'call parse#set_translate(v:event.regname, v:event.operator)'
  let reset = 'unlet! b:registers | autocmd! registers_' . bufnr()
  exe 'augroup registers_' . bufnr() | exe 'au!'
  exe 'au TextYankPost <buffer> ' . rotate . ' | ' restore . ' | ' . reset
  exe 'au CursorHold <buffer> if utils#none_pending() | ' . restore . ' | ' . reset . ' | endif'
  exe 'augroup END'
endfunction
