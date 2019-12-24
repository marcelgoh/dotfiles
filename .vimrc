set nocompatible

filetype indent plugin on
syntax on

set title

set regexpengine=1

set ruler

set ignorecase
set smartcase

set splitbelow
set splitright

set termguicolors

colo monokai

set hidden
set wildmenu
set showcmd
set hlsearch
set number
set relativenumber

" Relative line numbering in normal mode
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

set tags=./.tags,.tags;$HOME

set autoindent
set shiftwidth=4
set expandtab
set nosmarttab

set backspace=indent,eol,start

" More forgiving if Shift-key is accidentally held too long
command! W w
command! Q q
map <S-up> <up>
map <S-down> <down>
imap <S-up> <up>
imap <S-down> <down>

" Press kj or KJ to enter normal mode
imap kj <Esc>
imap KJ <Esc>

" Syntax highlighting for a number of different filetypes
au BufReadPost *.p8 set syntax=lua
au BufReadPost *.bel set syntax=beluga
au BufReadPost *.tut set syntax=tutch
au BufReadPost *.pro set syntax=prolog
au BufReadPost *.opy set syntax=python
au BufReadPost *.ml,*mli compiler ocaml
au BufReadPost *.pde set syntax=processing

" Scheme comments use #| and |#
au! BufEnter *.scm syntax region schemeMultilineComment start=/#|/ end=/|#/ 
" au! BufEnter *.bel syn match Comment /%.*/

" Show trailing whitespace and spaces before a tab:
:highlight ExtraWhitespace ctermbg=grey guibg=grey
:autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\t/

" Timeout when matching parentheses
" let g:matchparen_timeout = 2
" let g:matchparen_insert_timeout = 2

" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line
