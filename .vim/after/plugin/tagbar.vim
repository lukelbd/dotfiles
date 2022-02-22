"------------------------------------------------------------------------------"
" Override the default tagbar updating behavior. Prevents dependence on
" cursorhold events. Otherwise have to use e.g. 100ms which can cause lags.
"------------------------------------------------------------------------------"
" Note: Use tagbar#Update() for BufRead,BufWrite to mimick s:AutoUpdate(..., 0)
" call by original group and use tagbar#ForceUpdate() for InsertLeave,TextChanged
" to mimick s:AutoUpdate(..., 1) call by original CursorHold,CursorHoldI group.
" Note: For some reason s:Init() in tagbar.vim is not called before custom commands
" which triggers error in tagbar#ForceUpdate(). No idea how tagbar always calls
" s:Init() before autocommands but we do so indirectly with tagbar#currenttag().
" Note: This is placed here for consistency with gitgutter.vim... not actually
" overwritting the native TagbarAutoCmds group instead use g:tagbar_no_autocmds.
" This helps tagbar window highlighting and statusline message keep up.
" Note: Native tagbar populates s:delayed_update_files with written files and relies
" on CursorHold which triggers do_delayed_update() to subsequently update the tags.
" Instead much simpler to just update right away after writing and not use Cursorhold.
function! s:highlight_tag() abort  " no abort to ensure setting is reset
  if !empty(filter(tabpagebuflist(), "bufname(v:val) =~# '__Tagbar__'"))  " note that tagbar#IsOpen fails
    let b = g:tagbar_no_autocmds
    let g:tagbar_no_autocmds = 0  " temporarily disable so s:HighlightTag() does not skip highlighting
    call tagbar#highlighttag(g:tagbar_autoshowtag != 2, 0)  " possibly open folds and force inactive
    let g:tagbar_no_autocmds = b
  endif
endfunction
if exists('g:tagbar_no_autocmds') && g:tagbar_no_autocmds
  augroup tagbar  " native is TagbarAutoCmds
    au!
    let cmds = exists('##TextChanged') ? 'InsertLeave,TextChanged' : 'InsertLeave'
    exe 'au ' . cmds . ' * call tagbar#ForceUpdate()'
    au BufEnter,BufReadPost,Filetype * call tagbar#currenttag('%s', '') | call tagbar#Update()
    au CursorMoved,CursorMovedI * noautocmd call s:highlight_tag()
  augroup END
endif
