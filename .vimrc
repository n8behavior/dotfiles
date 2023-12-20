syntax on
filetype plugin indent on
set number relativenumber
set nowrap
set linebreak
set softtabstop=4 shiftwidth=4 expandtab

autocmd FileType make set noexpandtab
autocmd FileType sh set noexpandtab tabstop=4
autocmd FileType automake set noexpandtab tabstop=4
autocmd BufRead,BufNewFile *.md setlocal textwidth=80

let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_working_path_mode = 'raw'

set listchars=tab:→\ ,space:·,nbsp:␣,trail:•,eol:¶,precedes:«,extends:»

set termguicolors
let g:gruvbox_italic=1
colorscheme gruvbox 
set background=dark

set laststatus=2

" rust-lang/rust.vim pluging Stuff
"let g:rustfmt_autosave = 1
"let g:rust_clip_command = 'xclip -selection clipboard'

set completeopt=menu,menuone,preview,noselect,noinsert
let g:ale_completion_enabled = 1
let g:ale_fix_on_save = 1
let g:ale_rust_rustfmt_options = '--edition 2018'
let g:ale_rust_cargo_use_clippy = 1
let g:ale_rust_cargo_check_tests = 1
let g:ale_rust_cargo_check_examples = 1
let g:ale_fixers = {'rust': ['rustfmt']}
let g:ale_linters = {
\  'rust': ['analyzer'],
\}
let g:ale_rust_analyzer_executable = '~/.cargo/bin/rust-analyzer'
