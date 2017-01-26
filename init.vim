" Enable Truecolor support
if (has("termguicolors"))
	set termguicolors
	" something something background color tmux
	set t_ut =
endif

" Plug
function! DoRemote(arg)
	UpdateRemotePlugins
endfunction

call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/tpope/vim-fugitive.git'
Plug 'scrooloose/nerdtree'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'easymotion/vim-easymotion'
Plug 'https://github.com/tpope/vim-surround.git'
Plug 'Shougo/deoplete.nvim', {'do' : function('DoRemote')}
Plug 'airblade/vim-gitgutter'
Plug 'kostacoffee/seti.vim'

" language plugins
Plug 'posva/vim-vue'
Plug 'mitsuhiko/vim-python-combined'
Plug 'pangloss/vim-javascript'
Plug 'elzr/vim-json'
Plug 'othree/html5.vim'
Plug 'digitaltoad/vim-pug'
Plug 'vim-jp/vim-cpp'
Plug 'JulesWang/css.vim'
call plug#end()

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
set tabstop=4
set noexpandtab
set list
filetype plugin indent off
syntax on
set background=dark
colorscheme seti

let g:airline_powerline_fonts = 1
let g:airline_theme='jellybeans'
let g:airline#extensions#tabline#enabled = 1

" deoplete
let g:deoplete#enable_at_startup = 1
