function! vimsession#session_root() abort
  let l:root = fnamemodify(expand(get(g:, 'vimsession_directory', '~/.vim_sessions')), ':p')
  return substitute(l:root, '/\+$', '', '')
endfunction

function! vimsession#session_file(...) abort
  let l:dir = a:0 ? a:1 : getcwd()
  let l:normalized_dir = fnamemodify(empty(l:dir) ? getcwd() : l:dir, ':p')
  let l:key = substitute(l:normalized_dir, '[\/\\:]', '%', 'g')
  let l:key = substitute(l:key, '\s\+', '_', 'g')
  let l:key = substitute(l:key, '[^A-Za-z0-9._%-]', '_', 'g')
  let l:key = substitute(l:key, '^%\\+', '', '')
  let l:key = substitute(l:key, '%\\+$', '', '')
  let l:key = substitute(l:key, '%\+', '%', 'g')

  if empty(l:key)
    let l:key = 'root'
  endif

  if exists('*sha256')
    let l:key .= '-' . sha256(l:normalized_dir)[0:7]
  endif

  return vimsession#session_root() . '/' . l:key . '.vim'
endfunction

function! vimsession#ensure_session_root() abort
  let l:root = vimsession#session_root()
  if !isdirectory(l:root)
    call mkdir(l:root, 'p')
  endif

  return l:root
endfunction

function! vimsession#repair_nerdtree_session() abort
  if !exists('g:NERDTreeCreator')
    return
  endif

  let l:current_win = win_getid()

  for l:tab in range(1, tabpagenr('$'))
    for l:winnr in reverse(range(1, tabpagewinnr(l:tab, '$')))
      let l:winid = win_getid(l:winnr, l:tab)
      let l:bufnr = winbufnr(l:winid)
      let l:bufname = bufname(l:bufnr)

      if l:bufname =~# '^NERD_tree_tab_\d\+$' && empty(getbufvar(l:bufnr, 'NERDTree'))
        call win_gotoid(l:winid)
        let t:NERDTreeBufName = l:bufname
        execute 'file TRASH_' . l:bufname
        bwipeout!
        call g:NERDTreeCreator.CreateTabTree(getcwd())
      endif
    endfor
  endfor

  call win_gotoid(l:current_win)
endfunction

function! vimsession#close_stale_nerdtree_windows() abort
  let l:current_tab = tabpagenr()
  let l:current_win = win_getid()

  for l:tab in range(1, tabpagenr('$'))
    for l:winnr in reverse(range(1, tabpagewinnr(l:tab, '$')))
      let l:winid = win_getid(l:winnr, l:tab)
      let l:bufnr = winbufnr(l:winid)

      if bufname(l:bufnr) =~# '^NERD_tree_tab_\d\+$'
            \ && empty(getbufvar(l:bufnr, 'NERDTree'))
            \ && tabpagewinnr(l:tab, '$') > 1
        call win_gotoid(l:winid)
        close
      endif
    endfor
  endfor

  if win_gotoid(l:current_win) == 0
    execute 'tabnext ' . l:current_tab
  endif
endfunction

function! vimsession#save_current(...) abort
  let l:silent = a:0 ? a:1 : 0
  let l:session = vimsession#session_file()

  call vimsession#ensure_session_root()

  let g:vimsession_active_file = l:session
  execute 'mksession! ' . fnameescape(l:session)

  if !l:silent
    echomsg 'Session saved: ' . l:session
  endif

  return l:session
endfunction

function! vimsession#load_current(...) abort
  let l:silent = a:0 ? a:1 : 0
  let l:session = vimsession#session_file()

  let g:vimsession_active_file = l:session
  if !filereadable(l:session)
    if !l:silent
      echohl WarningMsg
      echomsg 'Session not found: ' . l:session
      echohl None
    endif
    return ''
  endif

  let g:vimsession_is_loading = 1
  try
    execute 'source ' . fnameescape(l:session)
  finally
    let g:vimsession_is_loading = 0
  endtry

  if !l:silent
    echomsg 'Session loaded: ' . l:session
  endif

  return l:session
endfunction

function! vimsession#delete_current() abort
  let l:session = vimsession#session_file()

  if !filereadable(l:session)
    echohl WarningMsg
    echomsg 'Session not found: ' . l:session
    echohl None
    return 0
  endif

  call delete(l:session)
  let g:vimsession_skip_auto_save_once = 1
  echomsg 'Session deleted: ' . l:session
  return 1
endfunction

function! vimsession#maybe_auto_start() abort
  if !get(g:, 'vimsession_auto_load', 1)
    return
  endif

  if get(g:, 'vimsession_did_auto_start', 0)
    return
  endif
  let g:vimsession_did_auto_start = 1

  let l:session = vimsession#session_file()
  let g:vimsession_active_file = l:session

  if filereadable(l:session)
    call vimsession#load_current(1)
  elseif get(g:, 'vimsession_create_on_start', 1)
    call vimsession#save_current(1)
  endif
endfunction

function! vimsession#maybe_auto_save() abort
  if !get(g:, 'vimsession_auto_save', 1)
    return
  endif

  if get(g:, 'vimsession_is_loading', 0)
    return
  endif

  if get(g:, 'vimsession_skip_auto_save_once', 0)
    let g:vimsession_skip_auto_save_once = 0
    return
  endif

  call vimsession#save_current(1)
endfunction
