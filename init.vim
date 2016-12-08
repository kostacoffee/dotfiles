" Enable Truecolor support
if (has("termguicolors"))
	set termguicolors
endif

" Plug
function! DoRemote(arg)
	UpdateRemotePlugins
endfunction

call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'scrooloose/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'easymotion/vim-easymotion'
Plug 'https://github.com/tpope/vim-surround.git'
Plug 'https://github.com/digitaltoad/vim-pug'
Plug 'Shougo/deoplete.nvim', {'do' : function('DoRemote')}
Plug 'airblade/vim-gitgutter'
Plug 'kostacoffee/seti.vim'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'posva/vim-vue'
call plug#end()

" actually ruining my life
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
nnoremap j gj
nnoremap k gk
inoremap {<cr> {<cr>}<c-o>O<tab>
"settings
set showcmd             " Show (partial) command in status line.
set noshowmode          " Show current mode.
set number              " Show the line numbers on the left side.
set formatoptions+=o    " Continue comment marker in new lines.
set textwidth=0         " Hard-wrap long lines as you type them.
set shiftwidth=4        " Indentation amount for < and > commands.
set noerrorbells        " No beeps.
set modeline            " Enable modeline.
set esckeys             " Cursor keys in insert mode.
set linespace=0         " Set line-spacing to minimum.
set nojoinspaces        " Prevents inserting two spaces after punctuation on a join (J)
set clipboard=unnamedplus	" Allows vim to use system clipboard
set tabstop=4
set noexpandtab
set list
filetype plugin indent off
syntax on
set background=dark
colorscheme seti
 
" air-line
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='deep_space'

" deoplete
let g:deoplete#enable_at_startup = 1

