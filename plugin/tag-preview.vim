" vars {{{1
if !exists('g:tag_preview_winpos')
  let g:tag_preview_winpos = 'right'
endif

if !exists('g:tag_preview_winsize')
  let g:tag_preview_winsize = 80
endif

" commands {{{1
command! -bang TagPreviewCWord call tagpreview#preview_tag(expand('<cword>'), <bang>0)
command! TagPreviewClose call tagpreview#close_window()

" keymaps {{{1
call tagpreview#register_hotkey(1, 1, '<LocalLeader>q', ':TagPreviewClose<CR>', 'Close window.')

if !get(g:, 'tagpreview#no_mappings', get(g:, 'no_plugin_maps', 0))
  noremap <silent> <M-;> :TagPreviewCWord<CR>
  noremap <silent> <M-:> :TagPreviewClose<CR>
endif

" register plugin {{{1
call xcc#plugin#register('tag-preview', { 'actions': ['autoclose']  })
