if exists( 'g:loaded_vim_projectdir' )
	finish
endif
let g:loaded_vim_projectdir = 1

" 未定義なら初期化
if !exists( 'g:filename_projectdir_file' ) || empty( g:filename_projectdir_file )
	let g:filename_projectdir_file = expand( '$HOME/.vim/projectdir.conf' )
endif

" 文字列の長さの長い方からのソート
function! s:compareLength( a, b )
	return strlen( a:b ) - strlen( a:a )
endfunction

" プロジェクトディレクトリの検索
function! s:searchProjectDir( Directory )
	for l:inst in s:directoryList
		if 0 <= stridx( a:Directory, l:inst )
			return l:inst
		endif
	endfor
	return ''
endfunction

" ディレクトリの移動
function! s:moveProjectDir()
	if !exists( 'b:projectDir' )
		" まだ検索していない。.
		let l:nowDir = expand("%:p:h")
		let l:result = s:searchProjectDir( nowDir )
		if !empty( l:result )
			let b:projectDir = l:result
		else
			let b:projectDir = getcwd()
		endif
	endif
	"echo 'move:' . b:projectDir
	execute 'cd ' . b:projectDir
endfunction

" バッファ移動時に動作
augroup plugin-projectdir
	autocmd!
	autocmd BufReadPost,BufWritePost,BufEnter * call s:moveProjectDir()
augroup END

" プロジェクトディレクトリリストの初期化
function! projectdir#reload()
	" 設定ファイルを読み込む
	let l:filename = fnamemodify( expand( g:filename_projectdir_file ), ':p' )
	let s:directoryList = filereadable( l:filename ) ? readfile( l:filename ) : []

	for l:i in range( len( s:directoryList ) )
		let s:directoryList[ l:i ] = expand( s:directoryList[ l:i ] )
	endfor

	" 文字長でソート == 一番下位ディレクトリ優先
	let s:directoryList = sort( s:directoryList, 's:compareLength' )
	"echo s:directoryList

	" 今いるバッファのディレクトリ更新.
	if exists( 'b:projectDir' )
		unlet b:projectDir
	endif
	call s:moveProjectDir()
endfunction
call projectdir#reload() " とりあえず読み込む

