"-----------------------------------------------------------------------------"
" General utilities
"-----------------------------------------------------------------------------"
" Grep commands
" Todo: Only use search pattern? https://github.com/junegunn/fzf.vim/issues/346
" Ag ripgrep flags: https://github.com/junegunn/fzf.vim/issues/921#issuecomment-1577879849
" Ag ignore file: https://github.com/ggreer/the_silver_searcher/issues/1097
function! grep#ag(bang, level, depth, ...) abort
  let flags = '--path-to-ignore ~/.ignore --skip-vcs-ignores --hidden'
  let extra = a:depth ? ' --depth ' . (a:depth - 1) : ''
  let args = call('grep#parse', [a:level] + a:000)
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  call fzf#vim#ag_raw(flags . ' -- ' . args, opts, a:bang)  " bang uses fullscreen
endfunction
function! grep#rg(bang, level, depth, ...) abort
  let flags = '--no-ignore-vcs --hidden'
  let extra = a:depth ? ' --max-depth ' . a:depth : ''
  let args = call('grep#parse', [a:level] + a:000)
  " let opts = a:level > 0 ? {'dir': expand('%:h')} : {}
  " let opts = fzf#vim#with_preview(opts)
  let opts = fzf#vim#with_preview()
  let cmd = 'rg --column --line-number --no-heading --color=always --smart-case '
  call fzf#vim#grep(cmd . ' ' . flags . extra . ' -- ' . args, opts, a:bang)  " bang uses fullscreen
endfunction

" Parse grep args and translate regex indicators
" Warning: Strange bug seems to cause :Ag and :Rg to only work on individual files
" if more than one file is passed. Otherwise preview window shows 'file is not found'
" error and selecting from menu fails. So always pass extra dummy name.
function! grep#parse(level, search, ...) abort
  let cmd = fzf#shellescape(a:search)  " similar to native but handles other shells
  let cmd = substitute(cmd, '\\[<>]', '\\b', 'g')  " translate word borders
  let cmd = substitute(cmd, '\\[cCvV]', '', 'g')  " smartcase imposed by flag
  let cmd = substitute(cmd, '\\S', "[^ \t]", 'g')  " non-whitespace characters
  let cmd = substitute(cmd, '\\s', "[ \t]",  'g')  " whitespace characters
  let cmd = substitute(cmd, '\\[ikf]', '\\w', 'g')  " keyword, identifier, filename
  let cmd = substitute(cmd, '\\[IKF]', '[a-zA-Z_]', 'g')  " same but no numbers
  let cmd = substitute(cmd, '\\\([(|)]\)', '\2', 'g')  " un-escape grouping indicators
  let cmd = substitute(cmd, '\([(|)]\)', '\\\1', 'g')  " escape literal parentheses
  let paths = a:000  " list of paths
  if empty(paths)  " default path or directory
    let paths = [a:level > 1 ? @% : a:level > 0 ? expand('%:h') : getcwd()]
  endif
  for path in paths  " iterate over all
    let path = substitute(path, '^\~', expand('~'), '')  " see also file.vim
    let path = substitute(path, '^' . getcwd(), '.', '')
    let path = substitute(path, '^' . expand('~'), '~', '')
    let cmd = cmd . ' ' . path  " do not escape paths to permit e.g. glob patterns
  endfor
  return cmd . ' dummy.fzf'  " fix bug described above
endfunction

" Call Rg or Ag grep commands (see also file.vim)
" Note: This lets user both pick default with <CR> or cancel with <C-c>
function! grep#list(lead, list, cursor)
  let opts = execute('history search')
  let opts = substitute(opts, '\n\@<=>\?\s*[0-9]*\s*\([^\n]*\)\(\n\|$\)\@=', '\1', 'g')
  let opts = split(opts, '\n')
  let opts = filter(opts, 'v:val[:len(a:lead) - 1] ==# a:lead')
  return reverse(opts[1:])
endfunction
function! grep#pattern(grep, level, depth) abort
  let prompt = a:level > 1 ? 'File' : a:level > 0 ? 'Local' : 'Global'
  let prompt = prompt . ' ' . toupper(a:grep[0]) . a:grep[1:] . ' pattern'
  let search = utils#complete_input(prompt, @/, 'grep#list')
  if empty(search) | return | endif
  let func = 'grep#' . tolower(a:grep)
  call call(func, [0, a:level, a:depth, search])
endfunction

" Parse .ignore files for ctags generation
" Note: This is actually only used to handle 'gutentags' ignore list but
" should be ported to bash and also used for 'qf()' and 'ff()' commands?
" Note: For some reason parsing '--exclude-exception' rules for g:fzf_tags_command
" does not work, ignores all other excludes, and vim-gutentags can only
" handle excludes anyway, so just bypass all patterns starting with '!'.
function! grep#ignores(join) abort
  let project = split(system('git rev-parse --show-toplevel'), "\n")
  let suffix = empty(project) ? [] : [project . '/.gitignore']
  let paths = ['~/.ignore', '~/.gitignore'] + suffix
  let ignores = []
  for path in paths
    let path = resolve(expand(path))
    if filereadable(path)
      for line in readfile(path)
        if line =~# '^\s*\(#.*\)\?$'
          continue
        elseif line[:0] ==# '!'
          continue
        elseif a:join
          let ignore = "--exclude='" . line . "'"
        else
          let ignore = line
        endif
        call add(ignores, ignore)
      endfor
    endif
  endfor
  let ignores = uniq(ignores)
  let ignores = a:join ? join(ignores, ' ') : ignores
  return ignores
endfunction
