if exists('g:loaded_ctrlp_projectdir') && g:loaded_ctrlp_projectdir
  "finish
endif
let g:loaded_ctrlp_projectdir = 1

let s:mark_var = {
\  'init':   'ctrlp#projectdir#init()',
\  'exit':   'ctrlp#projectdir#exit()',
\  'accept': 'ctrlp#projectdir#accept',
\  'lname':  'mark',
\  'sname':  'mark',
\  'type':   'mark',
\  'sort':   0,
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:mark_var)
else
  let g:ctrlp_ext_vars = [s:mark_var]
endif

if exists( 's:list' )
  unlet s:list
endif
let s:list = []
function! ctrlp#projectdir#init()
  let l:list = ''
  redir => l:list
  call projectdir#showlist()
  redir END
  let s:list = split(l:list, "\n")
  return s:list
endfunc

function! ctrlp#projectdir#accept(mode, str)
  call ctrlp#exit()
  execute 'lcd ' . a:str
endfunction

function! ctrlp#projectdir#exit()
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#projectdir#id()
  return s:id
endfunction

