" variables {{{1
let s:title = '-TagPreview-'

let s:keymap = {}

let s:tagname = ''
let s:taglist = []
let s:tagidx = 0

" functions {{{1
" tagpreview#bind_mappings {{{2
function! tagpreview#bind_mappings() abort
  call xcc#keymap#bind(s:keymap)
endfunction

" tagpreview#register_hotkey {{{2
function! tagpreview#register_hotkey(priority, local, key, action, desc) abort
  call xcc#keymap#register(s:keymap, a:priority, a:local, a:key, a:action, a:desc)
endfunction

" tagpreview#open_window {{{2
function! s:get_preview_winnr() abort
  for i in range(winnr('$'))
    if getwinvar(i + 1, '&previewwindow', 0)
      return i + 1
    endif
  endfor
  return -1
endfunction

function! s:on_close() abort
  " go back to edit buffer
  call xcc#window#goto_edit_window()
  call xcc#hl#clear_target()
endfunction

function! tagpreview#init_buffer() abort
  set previewwindow
  call setbufvar('%', g:xcc#plugin#plugin_key, 'tag-preview')
  call tagpreview#bind_mappings()

  augroup tagpreview
    au! BufWinLeave <buffer> call <SID>on_close()
  augroup END
endfunction

function! tagpreview#open_window() abort
  let l:winnr = winnr()
  if xcc#window#check_if_autoclose(l:winnr)
    call xcc#window#close(l:winnr)
  endif
  call xcc#window#goto_edit_window()

  let l:winnr = s:get_preview_winnr()
  if l:winnr == -1
    call xcc#window#open(
          \ s:title,
          \ g:tag_preview_winsize,
          \ g:tag_preview_winpos,
          \ 1,
          \ 1,
          \ function('tagpreview#init_buffer'),
          \ )
  else
    execute l:winnr . 'wincmd w'
  endif
endfunction

" tagpreview#close_window {{{2
function! tagpreview#close_window() abort
  silent pclose
endfunction

" tagpreview#preview_tag {{{2
function! s:find_taglist(pattern) abort
  let l:ftags = []
  try
    let l:ftags = taglist(a:pattern)
  catch /^Vim\%((\a\+)\)\=:E/
    let l:bak = &tagbsearch
    set notagbsearch
    let l:ftags = taglist(a:pattern)
    let &tagbsearch = l:bak
  endtry
  return l:ftags
endfunc

function! s:tagfind(tagname) abort
  let l:pattern = escape(a:tagname, '[\*~^')
  let l:result = s:find_taglist('^' . pattern . '$')
  if type(l:result) == 0 || (type(l:result) == 3 && empty(l:result))
    return []
  endif
  return l:result
endfunction

function! tagpreview#preview_tag(tagname, focus) abort
  if &previewwindow
    return 0
  endif

  let l:reuse = 0
  if s:tagname ==# a:tagname
    let l:reuse = 1
  endif

  if l:reuse == 0
    let s:tagname = a:tagname
    let s:taglist = s:tagfind(a:tagname)
    let s:tagidx = 0
  else
    let s:tagidx += 1
    if s:tagidx >= len(s:taglist)
      let s:tagidx = 0
    endif
  endif

  if len(s:taglist) == 0
    call xcc#msg#err('E257: tag-preview: tag not find "' . a:tagname . '"')
    return 1
  endif

  if s:tagidx >= len(s:taglist)
    call xcc#msg#err('E257: tag-preview: index error')
    return 2
  endif

  let l:taginfo = s:taglist[s:tagidx]
  let l:filename = l:taginfo.filename
  if !filereadable(l:filename)
    call xcc#msg#err('E484: tag-preview: can not open file ' . l:filename)
    return 3
  endif

  " open the global tag preview window
  call tagpreview#open_window()

  " open file and highlight tagname
  silent execute 'e! ' . fnameescape(l:filename)

  call tagpreview#init_buffer()
  normal! gg
  if has_key(l:taginfo, 'line')
    silent! execute '' . l:taginfo.line
  else
    silent! execute '1'
    silent! execute l:taginfo.cmd
  endif
  normal! zvzz
  call xcc#hl#confirm_line(line('.'))

  let l:text = taginfo.name
  let l:text .= ' (' . (s:tagidx + 1) . '/' . len(s:taglist) . ') '
  let l:text .= l:filename
  call xcc#msg#notice(l:text)

  if a:focus == 0
    call xcc#window#goto_edit_window()
  endif
endfunction
