"------------------------------------------------------------------------------"
" Override the default tagbar updating behavior. Prevents dependence on
" cursorhold events. Otherwise have to use e.g. 100ms which can cause lags.
"------------------------------------------------------------------------------"
" Note: This is placed here for consistency with gitgutter.vim... not actually
" overwritting the native TagbarAutoCmds group instead use g:tagbar_no_autocmds.
" This helps tagbar window highlighting and statusline message keep up.
" Note: Native tagbar populates s:delayed_update_files with written files and relies
" on CursorHold which triggers do_delayed_update() to subsequently update the tags.
" Instead much simpler to just update right away after writing and not use Cursorhold.
if exists('g:tagbar_no_autocmds') && g:tagbar_no_autocmds
  augroup tagbar  " native is TagbarAutoCmds
    au!
    au BufRead,BufWritePost * call tagbar#Update()  " same events as vim-tags plugin
    au CursorMoved,CursorMovedI * call tagbar#Update() | tagbar#highlighttag()
  augroup END
endif
