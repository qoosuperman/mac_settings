inoremap jk <ESC>
let mapleader = "'"

set softtabstop=2
set shiftwidth=2
set backspace=indent,eol,start
set hlsearch
set ignorecase
set incsearch
let g:snipMate = { 'snippet_version' : 1 }
set clipboard=unnamed

call plug#begin('~/.vim/plugged')
Plug 'vim-ruby/vim-ruby'
Plug 'vim-airline/vim-airline'
Plug 'preservim/nerdtree'
Plug 'kien/ctrlp.vim'
Plug 'tomtom/tcomment_vim'
Plug 'tpope/vim-rails'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tomtom/tlib_vim'
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'
Plug 'preservim/tagbar'
Plug 'mileszs/ack.vim'
Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown', 'do': 'yarn install'}
call plug#end()
