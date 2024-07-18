"-----------------------------------------------------------------------------"
" Utilities for grepping
"-----------------------------------------------------------------------------"
" Helper functions for parsing grep input
" NOTE: Grep, ag, and rg use standard PCRE regex syntax distinct from vim. Use 'man
"  pcre2pattern' for info: https://github.com/ggreer/the_silver_searcher/issues/850
" WARNING: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! grep#parse(global, level, regex, ...) abort
  let @/ = a:regex  " highlight matches
  if a:regex =~? '\\c'  " apply case manually
    let case = a:regex =~# '\\C' ? '--case-sensitive' : '--ignore-case'
  else  " infer case from options
    let case = &smartcase ? '--smart-case' : &ignorecase ? '--ignore-case' : '--case-sensitive'
  endif
  let paths = call('parse#get_paths', [0, a:global, a:level] + a:000)
  let paths = empty(paths) ? paths : add(paths, 'dummy.fzf')  " fix bug (see above)
  return [grep#regex(a:regex), join(paths, ' '), case]
endfunction
function! grep#regex(regex) abort  " convert to pcre syntax
  let regex = substitute(a:regex, '\\%\([$^]\)', '\1', 'g')  " convert file borders
  let regex = substitute(regex, '\\%\([#V]\|[<>]\?''m\)', '', 'g')  " ignore mark ranges
  let regex = substitute(regex, '\\%[<>]\?\(\.\|[0-9]\+\)[lcv]', '', 'g')  " ignore pos ranges
  let regex = substitute(regex, '\\[<>]', '\\b', 'g')  " convert boundaries to pcre
  let regex = substitute(regex, '\\[cvCV]', '', 'g')  " ignore indicators (see below)
  let regex = substitute(regex, '\C\\S', "[^ \t]", 'g')  " non-whitespace indicator
  let regex = substitute(regex, '\C\\s', "[ \t]",  'g')  " whitespace indicator
  let regex = substitute(regex, '\C\\_S', "[^ \t\n]", 'g')  " including newlines
  let regex = substitute(regex, '\C\\_s', "[ \t\n]",  'g')  " including newlines
  let regex = substitute(regex, '\C\\[IKF]', '[a-zA-Z_]', 'g')  " convert to alphabetic
  let regex = substitute(regex, '\C\\[ikf]', '\\w', 'g')  " convert to alphanumeric
  let regex = substitute(regex, '\%(\\%\?\)\@<!\([(|)+?{]\)', '\\\\\1', 'g')  " double escape magics
  let regex = substitute(regex, '\\%\?\([(|)+?{]\)', '\1', 'g')  " unescape magics
  return fzf#shellescape(regex)  " similar to native method but supports other shells
endfunction

" Call Blines or Lines from command
" NOTE: This supports :Lines navigation across existing open windows and tabs (native
" version handles buffer switching separately from s:action_for() invocation).
" NOTE: This integrates with grep-command-style regex-filtering (e.g. use '/' map to
" search natively then 'g/' to use fzf). Pass whitespace to disable regex filtering
" Fzf matches paths: https://github.com/junegunn/fzf.vim/issues/346
function! s:goto_lines(result) abort
  if empty(a:result) | return | endif
  let item = get(a:result, 0, '')
  let items = split(item, "\t", 0)
  if empty(items) | return | endif  " empty string yields []
  silent call file#drop_file(str2nr(items[0]))
  exe items[2] | exe 'normal! ^zvzz'
endfunction
function! grep#call_lines(global, level, regex, ...) abort
  let cmd = a:global ? 'lines' : 'blines'
  let opts = a:global ? {'sink*': function('s:goto_lines')} : {}
  let regex = a:regex =~# '^\s\+$' ? '' : a:regex
  let [show, source] = fzf#vim#_lines(a:global ? 0 : 1)
  let opts = '-d "\t" --tabstop 1 --nth ' . (2 + show) . '..'
  let opts .= ' --with-nth ' . (a:global ? 1 + show : 2 + show) . '..'
  let opts .= ' --layout reverse-list --tiebreak chunk,index --ansi --extended'
  let opts .= ' --query ' . string(succinct#regex(a:regex, 'omns'))
  let [_, _, case] = grep#parse(a:global, a:level, a:regex)
  let prompt = toupper(cmd[0]) . tolower(cmd[1:]) . '> '
  let regex1 = a:global ? '' : '^\e\?[^\e]*\D' . bufnr('') . '\t'
  let regex2 = empty(regex) ? '' : '\t[^\e]\+' . regex . '[^\e]*$'
  let options = {
    \ 'source': filter(source, 'v:val =~ regex1 && v:val =~ regex2'),
    \ 'sink*': function('s:goto_lines'),
    \ 'options': opts . ' --prompt ' . string(prompt),
  \ }
  return fzf#run(fzf#wrap(cmd, options, a:0 ? a:1 : 0))
endfunction

" Call Ag Rg Blines or Lines from command
" NOTE: If called manually then always enable recursive search and disable
" custom '~/.ignore' file (e.g. in case searching .vim/plugged folder).
" NOTE: Rg and Ag read '.gitignore' and '.ignore' from search directories. Disable
" first with -skip-vcs-ignores (ag) and -no-ignore-vcs (rg) or all with below flags.
" NOTE: Unlike Rg --no-ignore --ignore-file, Ag -unrestricted --ignore-file disables
" unrestricted flag and may load .ignore. Workaround is to use -t text-file-only filter
" NOTE: Native commands include final !a:bang argument toggling fullscreen but we
" use a:bang to indicate whether to search current buffer or global open buffers.
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! grep#call_ag(global, level, regex, ...) abort
  let flags = a:level > 1 ? '--hidden' : '--hidden --depth 0'
  let flags .= a:0 || a:level > 2 ? ' --unrestricted' : ' --path-to-ignore ~/.ignore'
  let flags .= a:0 || a:level > 2 ? ' -t' : ' --path-to-ignore ~/.wildignore'  " compare to rg
  let args = [a:global, a:level, a:regex] + a:000
  let [regex, paths, case] = call('grep#parse', args)
  let opts = fzf#vim#with_preview()
  let source = join([flags, case, '--', regex, paths], ' ')
  let filter = ' | sed "s@$HOME@~@"'  " post-process
  call fzf#vim#ag_raw(source . filter, opts, 0)  " 0 is no fullscreen
  redraw | echom 'Ag ' . regex . ' (level ' . a:level . ')'
endfunction
function! grep#call_rg(global, level, regex, ...) abort
  let flags = a:level > 1 ? '--hidden' : '--hidden --max-depth 1'
  let flags .= a:0 || a:level > 2 ? ' --no-ignore' : ' --ignore-file ~/.ignore'
  let flags .= ' --ignore-file ~/.wildignore'  " compare to ag
  let flags .= a:regex =~# '\\c' ? ' --ignore-case' : a:regex =~# '\\C' ? '--case-sensitive' : &l:smartcase
  let args = [a:global, a:level, a:regex] + a:000
  let [regex, paths, case] = call('grep#parse', args)
  let opts = fzf#vim#with_preview()
  let head = 'rg --column --line-number --no-heading --color=always'
  let source = join([head, flags, case, '--', regex, paths], ' ')
  let filter = ' | sed "s@$HOME@~@"'  " post-process
  call fzf#vim#grep(source . filter, opts, 0)  " 0 is no fullscreen
  redraw | echom 'Rg ' . regex . ' (level ' . a:level . ')'
endfunction

" Call Ag Rg BLines or Lines from mapping (see also file.vim)
" NOTE: Using <expr> instead of this tiny helper function causes <C-c> to
" display annoying 'Press :qa' helper message and <Esc> to enter fuzzy mode.
function! grep#complete_search(lead, line, cursor)
  let regex = '\n\@<=>\?\s*[0-9]*\s*\([^\n]*\)\(\n\|$\)\@='
  let match = 'empty(a:lead) || v:val[:len(a:lead) - 1] ==# a:lead'
  let opts = execute('history search')
  let opts = substitute(opts, regex, '\1', 'g')  " remove number prompt
  let opts = filter(split(opts, '\n'), match)
  return reverse([@/] + opts[1:])  " match to user input
endfunction
function! grep#call_grep(cmd, global, level) abort
  let paths = parse#get_paths(1, a:global, a:level)
  let head = a:cmd ==# 'lines' ? 'Search' : toupper(a:cmd[0]) . a:cmd[1:]
  let name = a:level > 2 ? 'directory' : a:level > 1 ? 'project' : a:level ? 'folder' : 'buffer'
  let name = len(paths) > 1 ? a:level > 2 ? 'directories' : name . 's' : name
  if a:global && len(paths) > 1  " open files or folders across session
    let label = len(paths) . ' ' . name
  elseif a:cmd ==# 'lines'
    let label = 'current buffer'
  else  " specific paths
    let label = name . ' ' . join(paths, ' ')
  endi
  let prompt = head . ' ' . label
  let regex = utils#input_default(prompt, @/, 'grep#complete_search')
  if empty(regex) | return | endif
  let args = [a:global, a:level, regex]
  call call('grep#call_' . tolower(a:cmd), args)
endfunction
