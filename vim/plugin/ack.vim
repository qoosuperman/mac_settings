if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif
nnoremap <C-a> :Ack!<Space>
