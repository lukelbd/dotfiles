"-----------------------------------------------------------------------------"
" LaTeX specific settings
"-----------------------------------------------------------------------------"
" Restrict concealmeant to just symbols and stuff
" a=accents/ligatures
" b=bold/italics
" d=delimiters (e.g. $$ math mode)
" m=math symbols
" g=Greek
" s=superscripts/subscripts
let g:tex_conceal = 'agm'

" Allow @ in makeatletter, allow texmathonly outside of math regions (i.e.
" don't highlight [_^] when you think they are outside math zone
let g:tex_stylish = 1

" Disable spell checking in verbatim mode and comments, disable errors
" let g:tex_fast = "" "fast highlighting, but pretty ugly
let g:tex_fold_enable = 1
let g:tex_comment_nospell = 1
let g:tex_verbspell = 0
let g:tex_no_error = 1

" Typesetting LaTeX and displaying PDF viewer
" Copied s:vim8 from autoreload/plug.vim file
let s:vim8 = has('patch-8.0.0039') && exists('*job_start')
function! s:latex_background(...)
  if !s:vim8
    echom "Error: Latex compilation requires vim >= 8.0"
    return 1
  endif
  " Jump to logfile if it is open, else open one
  let opts = (a:0 ? a:1 : '') " flags
  let texfile = expand('%')
  let logfile = expand('%:t:r') . '.log'
  let lognum = bufwinnr(logfile)
  if lognum == -1
    silent! exe string(winheight('.')/4) . 'split ' . logfile
    silent! exe winnr('#') . 'wincmd w'
  else
    silent! exe bufwinnr(logfile) . 'wincmd w'
    silent! 1,$d
    silent! exe winnr('#') . 'wincmd w'
  endif
  " Run job in realtime
  " WARNING: Trailing space will be escaped as a flag! So trim it.
  let num = bufnr(logfile)
  let g:tex_job = job_start('/Users/ldavis/bin/latexmk ' . texfile . trim(opts),
      \ { 'out_io': 'buffer', 'out_buf': num })
endfunction

" Latex compiling maps
noremap <silent> <buffer> <C-z> :call <sid>latex_background()<CR>
noremap <silent> <buffer> <Leader>z :call <sid>latex_background(' --diff')<CR>
noremap <silent> <buffer> <Leader>Z :call <sid>latex_background(' --word')<CR>

" Regex that filters out useless bibtex entries
nnoremap <buffer> <silent> \x :%s/^\s*\(abstract\\|file\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>
nnoremap <buffer> <silent> \X :%s/^\s*\(abstract\\|language\\|file\\|doi\\|url\\|urldate\\|copyright\\|keywords\\|annotate\\|note\\|shorttitle\)\s*=\s*{\_.\{-}},\?\n//gc<CR>

" Bibtex and Zotero INTEGRATION
" Requires pybtex and bibtexparser python modules, and unite.vim plugin
" Simply cannot get bibtex to work always throws error gathering candidates
" Possible data sources:
"  abstract,       author, collection, combined,    date, doi,
"  duplicate_keys, file,   isbn,       publication, key,  key_inner, language,
"  issue,          notes,  pages,      publisher,   tags, title,     type,
"  url,            volume, zotero_key
" NOTE: Set up with macports. By default the +python vim was compiled with
" is not on path; access with port select --set pip <pip36|python36>. To
" install module dependencies, use that pip. Can also install most packages
" with 'port install py36-module_name' but often get error 'no module
" named pkg_resources'; see this thread: https://stackoverflow.com/a/10538412/4970632
if &rtp =~ 'unite.vim' && &rtp =~ 'citation.vim'
  " Global and local settings
  let g:unite_data_directory = '~/.unite'
  let g:citation_vim_cache_path = '~/.unite'
  let g:citation_vim_outer_prefix = '\cite{'
  let g:citation_vim_inner_prefix = ''
  let g:citation_vim_suffix = '}'
  let g:citation_vim_et_al_limit = 3 " show et al if more than 2 authors
  let g:citation_vim_zotero_path = '~/Zotero' " location of .sqlite file
  let g:citation_vim_zotero_version = 5
  let g:citation_vim_bibtex_file = (exists('b:citation_vim_bibtex_file') ? b:citation_vim_bibtex_file : '')
  let g:citation_vim_opts = '-start-insert -buffer-name=citation -ignorecase -default-action=append citation/key'
  " Pseudo local settings that are applied as global variables before calling cite command
  let b:citation_vim_mode = 'bibtex'
  let b:citation_vim_bibtex_file = ''

  " Where to search for stuff
  " NOTE: This tries to allow buffer-local settings
  function! s:citation_vim_run(suffix, opts)
    if b:citation_vim_mode == 'bibtex' && b:citation_vim_bibtex_file == ''
      let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
    endif
    let g:citation_vim_mode = b:citation_vim_mode
    let g:citation_vim_outer_prefix = '\cite' . a:suffix . '{'
    let g:citation_vim_bibtex_file = b:citation_vim_bibtex_file
    call unite#helper#call_unite('Unite', a:opts, line('.'), line('.'))
    normal! a
    return ''
  endfunction

  " Ask user to select bibliography files from list
  " Requires special completion function for selecting bibfiles
  function! s:citation_vim_bibfile()
    let cwd = expand('%:h')
    let refs = split(glob(cwd . '/*.bib'), "\n")
    if len(refs) == 1
      let ref = refs[0]
    elseif len(refs)
      let items = fzf#run({'source':refs, 'options':'--no-sort', 'down':'~30%'})
      if len(items)
        let ref = items[0]
      else " user cancelled or entered invalid name
        let ref = refs[0]
      endif
    else
      echohl WarningMsg
      echom 'Warning: No .bib files found in file directory.'
      echohl None
      let ref = ''
    endif
    return ref
  endfunction

  " Toggle func
  function s:citation_vim_toggle(...)
    let mode_prev = b:citation_vim_mode
    let file_prev = b:citation_vim_bibtex_file
    if a:0
      let b:citation_vim_mode = (a:1 ? 'bibtex' : 'zotero')
    elseif b:citation_vim_mode == 'bibtex'
      let b:citation_vim_mode = 'zotero'
    else
      let b:citation_vim_mode = 'bibtex'
    endif
    " Toggle
    if b:citation_vim_mode == 'bibtex'
      if b:citation_vim_bibtex_file == ''
        let b:citation_vim_bibtex_file = s:citation_vim_bibfile()
      endif
      echom "Using BibTex file: " . expand(b:citation_vim_bibtex_file)
    else
      echom "Using Zotero database: " . expand(g:citation_vim_zotero_path)
    endif
    " Delete cache
    if mode_prev != b:citation_vim_mode || file_prev != b:citation_vim_bibtex_file
      call delete(expand(g:citation_vim_cache_path . '/citation_vim_cache'))
    endif
  endfunction
  command! BibtexToggle call <sid>bibtex_toggle()

  " Mappings
  " NOTE: For more default mappings, see zotero.vim documentation
  " NOTE: Do not use start-insert option, need map to declare special exit map
  " NOTE: Resume option starts with the previous input
  nnoremap <silent> <buffer> <Leader>B :BibtexToggle<CR>
  inoremap <silent> <buffer> <C-b>c <Esc>:call <sid>citation_vim_run('', g:citation_vim_opts)<CR>
  inoremap <silent> <buffer> <C-b>t <Esc>:call <sid>citation_vim_run('t', g:citation_vim_opts)<CR>
  inoremap <silent> <buffer> <C-b>p <Esc>:call <sid>citation_vim_run('p', g:citation_vim_opts)<CR>
  inoremap <silent> <buffer> <C-b>n <Esc>:call <sid>citation_vim_run('num', g:citation_vim_opts)<CR>
endif

