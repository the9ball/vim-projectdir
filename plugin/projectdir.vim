if exists( 'g:loaded_vim_projectdir' )
	finish
endif
let g:loaded_vim_projectdir = 1

" 初期書き込みファイル
let s:initialize = [
	\ '# vim-projectdir settingfile',
	\ '$HOME/.vim',
	\ ]

" Windows判定用
let s:is_win = has("win16") || has("win32") || has("win64")

" 未定義なら初期化
if !exists( 'g:filename_projectdir_file' ) || empty( g:filename_projectdir_file )
	let g:filename_projectdir_file = expand( '$HOME/.vim/projectdir.conf' )
endif

" 文字列の長さの長い方からのソート
function! s:compareLength( a, b )
	return strlen( a:b ) - strlen( a:a )
endfunction

" 重複チェック
function! s:unique_array( a )
	for l:index in range( 0, len( a:a )-2 )
		if 0 <= index( a:a, a:a[l:index], l:index+1 )
			" TODO:もっといい感じに
			call remove( a:a, l:index )
			return s:unique_array( a:a )
		endif
	endfor
	return a:a
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

function! s:setProjectDir( dir )
	let b:projectDir = substitute( a:dir, ' ', '\\ ', 'g' )
endfunction

" 現在のディレクトリを b:projectDir に設定
function! s:setProjectDirPwd()
	call s:setProjectDir( getcwd() )
endfunction

" ディレクトリの移動
function! s:moveProjectDir()
	if !exists( 'b:projectDir' )
		" まだ検索していない。.
		let l:nowDir = expand("%:p:h")
		if s:is_win
			let l:nowDir = tolower( l:nowDir )
		endif
		let l:result = s:searchProjectDir( nowDir )
		if !empty( l:result )
			call s:setProjectDir( l:result )
		else
			call s:setProjectDirPwd()
		endif
	endif
	"echo 'move:' . b:projectDir
	execute 'lcd ' . b:projectDir
endfunction

" バッファ移動時に動作
augroup plugin-projectdir
	autocmd!
	autocmd BufReadPost,BufWritePost,BufEnter * call s:moveProjectDir()
	autocmd BufLeave * call s:setProjectDirPwd()
augroup END

" プロジェクトディレクトリリストの初期化
function! projectdir#reload()
	" 設定ファイルを読み込む
	let l:filename = fnamemodify( expand( g:filename_projectdir_file ), ':p' )
	if !filereadable( l:filename )
		call writefile( s:initialize, l:filename )
	endif
	let s:directoryList = filereadable( l:filename ) ? readfile( l:filename ) : []

	" 設定を精査
	let l:temp = []
	for l:inst in s:directoryList " コメントや空行を省く
		if '' != l:inst && '#' != l:inst[0]
			call add( l:temp, l:inst )
		endif
	endfor
	let s:directoryList = copy( l:temp )
	unlet l:temp
	for l:i in range( len( s:directoryList ) )
		let s:directoryList[ l:i ] = expand( s:directoryList[ l:i ] )
		if s:is_win
			let s:directoryList[ l:i ] = tolower( s:directoryList[ l:i ] )
		endif
	endfor

	" 文字長でソート == 一番下位ディレクトリ優先
	let s:directoryList = sort( s:directoryList, 's:compareLength' )

	" 今いるバッファのディレクトリ更新.
	if exists( 'b:projectDir' )
		unlet b:projectDir
	endif
	call s:moveProjectDir()
endfunction
call projectdir#reload() " とりあえず読み込む

" 現在のカレントディレクトリを設定に追加する
function! projectdir#addcwd()
	" 設定ファイルを読み込む
	let l:filename = fnamemodify( expand( g:filename_projectdir_file ), ':p' )
	if !filereadable( l:filename )
		echo 'filereadable( "' . l:filename . '" ) == false'
		return
	endif
	let s:directoryList = filereadable( l:filename ) ? readfile( l:filename ) : []

	call add( s:directoryList, getcwd() ) " カレントを追加
	let s:directoryList = s:unique_array( s:directoryList ) " 重複チェック

	" 書き込む
	if !filewritable( l:filename )
		echo 'filewritable( "' . l:filename . '" ) == false'
		return
	endif
	call writefile( s:directoryList, l:filename )

	call projectdir#reload()
endfunction

" 設定のリストを表示する
function! projectdir#showlist()
	for l:inst in s:directoryList
		echo l:inst
	endfor
endfunction

" tyruさんから
function! s:has_plugin(name)
    let nosuffix = a:name =~? '\.vim$' ? a:name[:-5] : a:name
    let suffix   = a:name =~? '\.vim$' ? a:name      : a:name . '.vim'
    return &rtp =~# '\c\<' . nosuffix . '\>'
    \   || globpath(&rtp, suffix, 1) != ''
    \   || globpath(&rtp, nosuffix, 1) != ''
    \   || globpath(&rtp, 'autoload/' . suffix, 1) != ''
    \   || globpath(&rtp, 'autoload/' . tolower(suffix), 1) != ''
endfunction

" CtrlP対応
if s:has_plugin( 'CtrlP' )
	function! projectdir#init_ctrlp()
		cal ctrlp#init( ctrlp#projectdir#id() )
	endfunction
endif

