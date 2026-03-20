if exists('g:loaded_vimsession_plugin')
  finish
endif
let g:loaded_vimsession_plugin = 1

let g:vimsession_directory = get(g:, 'vimsession_directory', '~/.vim_sessions')
let g:vimsession_auto_load = get(g:, 'vimsession_auto_load', 1)
let g:vimsession_auto_save = get(g:, 'vimsession_auto_save', 1)
let g:vimsession_create_on_start = get(g:, 'vimsession_create_on_start', 1)

command! -bar SessionLoad call vimsession#load_current()
command! -bar SessionSave call vimsession#save_current()
command! -bar SessionDelete call vimsession#delete_current()
command! -bar SessionPath echomsg vimsession#session_file()

augroup vimsession_plugin
  autocmd!
  autocmd VimEnter * call vimsession#maybe_auto_start()
  autocmd VimLeavePre * call vimsession#maybe_auto_save()
augroup END
