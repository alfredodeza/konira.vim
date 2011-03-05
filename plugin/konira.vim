" File:        konira.vim
" Description: Runs the current test configure/it/file with
"              konira
" Maintainer:  Alfredo Deza <alfredodeza AT gmail.com>
" License:     MIT
"============================================================================


if exists("g:loaded_konira") || &cp 
  finish
endif


" Global variables for registering next/previous error
let g:konira_session_errors    = {}
let g:konira_session_error     = 0
let g:konira_last_session      = ""


function! s:KoniraSyntax() abort
    let b:current_syntax = 'konira'
    syn match KoniraIt                   '\v^\s+it\s+'
    syn match KoniraDescribe             '\v^describe\s+'
    syn match KoniraRaises               '\v^\s+raises\s+'
    syn match KoniraBeforeAll            '\v^\s+before\s+all'
    syn match KoniraBeforeEach           '\v^\s+before\s+each'
    syn match KoniraAfterEach            '\v^\s+after\s+each'
    syn match KoniraAfterAll             '\v^\s+after\s+all'

    hi def link KoniraIt                 Statement
    hi def link KoniraDescribe           Statement
    hi def link KoniraRaises             Identifier
    hi def link KoniraBeforeAll          Statement
    hi def link KoniraBeforeEach         Statement
    hi def link KoniraAfterAll           Statement
    hi def link KoniraAfterEach          Statement
endfunction


function! s:KoniraFailsSyntax() abort
  let b:current_syntax = 'koniraFails'
  syn match KoniraQDelimiter            "\v\s+(\=\=\>\>)\s+"
  syn match KoniraQLine                 "Line:"
  syn match KoniraQPath                 "\v\s+(Path:)\s+"
  syn match KoniraQEnds                 "\v\s+(Ends On:)\s+"

  hi def link KoniraQDelimiter          Comment
  hi def link KoniraQLine               String
  hi def link KoniraQPath               String
  hi def link KoniraQEnds               String
endfunction


function! s:GoToError(direction)
    "   0 goes to first
    "   1 goes forward
    "  -1 goes backwards
    "   2 goes to last
    "   3 goes to the end of current error
    call s:ClearAll()
    let going = "First"
    if (len(g:konira_session_errors) > 0)
        if (a:direction == -1)
            let going = "Previous"
            if (g:konira_session_error == 0 || g:konira_session_error == 1)
                let g:konira_session_error = 1
            else
                let g:konira_session_error = g:konira_session_error - 1
            endif
        elseif (a:direction == 1)
            let going = "Next"
            if (g:konira_session_error != len(g:konira_session_errors))
                let g:konira_session_error = g:konira_session_error + 1
            endif
        elseif (a:direction == 0)
            let g:konira_session_error = 1
        elseif (a:direction == 2)
            let going = "Last"
            let g:konira_session_error = len(g:konira_session_errors)
        elseif (a:direction == 3)
            if (g:konira_session_error == 0 || g:konira_session_error == 1)
                let g:konira_session_error = 1
            endif
            let select_error = g:konira_session_errors[g:konira_session_error]
            let line_number = select_error['file_line']
            let error_path = select_error['file_path']
            let exception = select_error['exception']
            let file_name = expand("%:t")
            if error_path =~ file_name
                execute line_number
            else
                call s:OpenError(error_path)
                execute line_number
            endif
            let message = "End of Failed test: " . g:konira_session_error . "\t ==>> " . exception
            call s:Echo(message, 1)
            return
        endif

        if (a:direction != 3)
            let select_error = g:konira_session_errors[g:konira_session_error]
            let line_number = select_error['line']
            let error_path = select_error['path']
            let exception = select_error['exception']
            let file_name = expand("%:t")
            if error_path =~ file_name
                execute line_number
            else
                call s:OpenError(error_path)
                execute line_number
            endif
            let message = going . " Failed test: " . g:konira_session_error . "\t ==>> " . exception
            call s:Echo(message, 1)
            return
        endif
    else
        call s:Echo("Failed test list is empty")
    endif
endfunction


function! s:Echo(msg, ...)
    redraw!
    let x=&ruler | let y=&showcmd
    set noruler noshowcmd
    if (a:0 == 1)
        echo a:msg
    else
        echohl WarningMsg | echo a:msg | echohl None
    endif

    let &ruler=x | let &showcmd=y
endfun


" Always goes back to the first instance
" and returns that if found
function! s:FindPythonObject(obj)
    let orig_line = line('.')
    let orig_col  = col('.')

    if (a:obj == "describe")
        let objregexp  = '\v^describe\s+'
    elseif (a:obj == "it")
        let objregexp = '\v^\s+it\s+'
    endif

    let flag   = "Wb"
    let result = search(objregexp, flag)

    if result 
        return result
    endif

endfunction


function! s:NameOfCurrentDescribe()
    let save_cursor = getpos(".")
    normal $<cr>
    let find_object = s:FindPythonObject('describe')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *describe \(.*\):')
        let new_match =  matchlist(match_result[1], '"\(.*\)"')
        if (len(new_match) == 0)
            let new_match = matchlist(match_result[1], "'\\(.*\\)\\'")
        endif
        return new_match[1]
    endif
endfunction


function! s:NameOfCurrentIt()
    let save_cursor = getpos(".")
    normal $<cr>
    let find_object = s:FindPythonObject('it')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *it \(.*\):')
        if (len(match_result))
            let no_quotes = matchlist(match_result[1], '"\(.*\)"')
            if (len(no_quotes) == 0)
                let no_quotes = matchlist(match_result[1], "'\\(.*\\)\\'")
            endif
        endif
        return no_quotes[1]
    endif
endfunction


function! s:CurrentPath()
    let cwd = expand("%:p")
    return cwd
endfunction


function! s:RunInSplitWindow(path)
    let cmd = "konira --tb " . a:path
	let command = join(map(split(cmd), 'expand(v:val)'))
	let winnr = bufwinnr('koniraVerbose.konira')
	silent! execute  winnr < 0 ? 'botright new ' . 'koniraVerbose.konira' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=konira
	silent! execute 'silent %!'. command
	silent! execute 'resize ' . line('$')
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    call s:KoniraSyntax()
endfunction


function! s:OpenError(path)
	let winnr = bufwinnr('GoToError.konira')
	silent! execute  winnr < 0 ? 'botright new ' . ' GoToError.konira' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number 
    silent! execute ":e " . a:path
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
endfunction


function! s:ShowError()
    if (len(g:konira_session_errors) == 0)
        call s:Echo("No Failed test case from a previous run")
        return
    endif
    if (g:konira_session_error == 0)
        let error_n = 1
    else
        let error_n = g:konira_session_error
    endif
    let error_dict = g:konira_session_errors[error_n]
    if (error_dict['error'] == "")
        call s:Echo("No failed test case saved from last run.")
        return
    endif

	let winnr = bufwinnr('ShowError.konira')
	silent! execute  winnr < 0 ? 'botright new ' . ' ShowError.konira' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile number filetype=python
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    let line_number = error_dict['file_line']
    let error = error_dict['error']
    let message = "Test Error: " . error
    call append(0, error)
    exe '0'
    exe '0|'
    silent! execute 'resize ' . line('$')
    exe 'wincmd p'
endfunction


function! s:ShowFails(...)
    au BufLeave *.konira echo "" | redraw
    if a:0 > 0
        let gain_focus = a:0
    else
        let gain_focus = 0
    endif
    if (len(g:konira_session_errors) == 0)
        call s:Echo("No failed cases from a previous run")
        return
    endif
	let winnr = bufwinnr('Fails.konira')
	silent! execute  winnr < 0 ? 'botright new ' . 'Fails.konira' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=konira
    let blank_line = repeat(" ",&columns - 1)
    exe "normal i" . blank_line 
    hi RedBar ctermfg=white ctermbg=red guibg=red
    match RedBar /\%1l/
    for err in keys(g:konira_session_errors)
        let err_dict    = g:konira_session_errors[err]
        let line_number = err_dict['line']
        let exception   = err_dict['exception']
        let path_error  = err_dict['path']
        let ends        = err_dict['file_path']
        if (path_error == ends)
            let message = printf('Line: %-*u ==>> %-*s ==>> %s', 6, line_number, 24, exception, path_error)
        else
            let message = printf('Line: %-*u ==>> %-*s ==>> %s', 6, line_number, 24, exception, ends)
        endif
        let error_number = err + 1
        call setline(error_number, message)    
    endfor
	silent! execute 'resize ' . line('$')
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    silent! execute 'nnoremap <silent> <buffer> <Enter> :q! <CR>'
    call s:KoniraFailsSyntax()
    exe "normal 0|h"
    if (! gain_focus)
        exe 'wincmd p'
    else
        call s:Echo("Hit Return or q to exit", 1)
    endif
endfunction


function! s:LastSession()
    if (len(g:konira_last_session) == 0)
        call s:Echo("There is currently no saved last session to display")
        return
    endif
	let winnr = bufwinnr('LastSession.konira')
	silent! execute  winnr < 0 ? 'botright new ' . 'LastSession.konira' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=konira
    let session = split(g:konira_last_session, '\n')
    call append(0, session)
	silent! execute 'resize ' . line('$')
    silent! execute 'normal gg'
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    call s:KoniraSyntax()
    exe 'wincmd p'
endfunction


function! s:ToggleFailWindow()
	let winnr = bufwinnr('Fails.konira')
    if (winnr == -1)
        call s:ShowFails()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
    endif
endfunction


function! s:ToggleLastSession()
	let winnr = bufwinnr('LastSession.konira')
    if (winnr == -1)
        call s:LastSession()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
    endif
endfunction


function! s:ToggleShowError()
	let winnr = bufwinnr('ShowError.konira')
    if (winnr == -1)
        call s:ShowError()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
    endif
endfunction


function! s:ClearAll()
    let bufferL = [ 'Fails.konira', 'LastSession.konira', 'ShowError.konira', 'koniraVerbose.konira' ]
    for b in bufferL
        let winnr = bufwinnr(b)
        if (winnr != -1)
            silent! execute winnr . 'wincmd p'
            silent! execute 'q'
        endif
    endfor
endfunction


function! s:Runkonira(path)
    let g:konira_last_session = ""
    let cmd = "konira --tb " . a:path
    let out = system(cmd)
    
    " Pointers and default variables
    let g:konira_session_errors = {}
    let g:konira_session_error = 0
    let g:konira_last_session = out

    " Loop through the output and build the error dict
    for w in split(out, '\n')
        if w =~ '\v^Failures\s*'
            call s:ParseFailures(out)
            return
        elseif w =~ '\v^Errors\s*'
            call s:ParseErrors(out)
            return
        endif
    endfor
    call s:GreenBar()
endfunction


function! s:ParseFailures(stdout)
    " Pointers and default variables
    let failed = 0
    let errors = {}
    let error = {}
    let error_number = 0
    let konira_error = ""
    let current_file = expand("%:t")
    let file_regex =  '\v(^' . current_file . '|/' . current_file . ')'
    let error['line'] = ""
    let error['path'] = ""
    let error['exception'] = ""
    " Loop through the output and build the error dict
    for w in split(a:stdout, '\n')
        if ((error.line != "") && (error.path != "") && (error.exception != ""))
            try
                let end_file_path = error['file_path']
            catch /^Vim\%((\a\+)\)\=:E/
                let error.file_path = error.path
                let error.file_line = error.line
            endtry
            let error_number = error_number + 1
            let errors[error_number] = error
            let error = {}
            let error['line'] = ""
            let error['path'] = ""
            let error['exception'] = ""
        endif

        if w =~ '\v\s+(FAILURES)\s+'
            let failed = 1
        elseif w =~ '\v^(.*)\.py:(\d+):'
            if w =~ file_regex
                let match_result = matchlist(w, '\v:(\d+):')
                let error.line = match_result[1]
                let file_path = matchlist(w, '\v(.*.py):')
                let error.path = file_path[1]
            elseif w !~ file_regex
                let match_result = matchlist(w, '\v:(\d+):')
                let error.file_line = match_result[1]
                let file_path = matchlist(w, '\v(.*.py):')
                let error.file_path = file_path[1]
            endif
        elseif w =~  '\v^E\s+(.*)\s+'
            let split_error = split(w, "E ")
            let actual_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g") 
            let match_error = matchlist(actual_error, '\v(\w+):\s+(.*)')
            if (len(match_error))
                let error.exception = match_error[1]
                let error.error = match_error[2]
            else
                let error.exception = "UnmatchedException"
                let error.error = actual_error
            endif
        elseif w =~ '\v^(.*)\s*ERROR:\s+'
            let konira_error = w
        endif
    endfor

    " Display the result Bars
    if (failed == 1)
        let g:konira_session_errors = errors
        call s:ShowFails(1)
    elseif (failed == 0 && konira_error == "")
        call s:GreenBar()
    elseif (konira_error != "")
        call s:RedBar()
        echo "py.test " . konira_error
    endif
endfunction


function! s:ParseErrors(stdout)
    " Pointers and default variables
    let failed = 0
    let errors = {}
    let error = {}
    " Loop through the output and build the error dict

    for w in split(a:stdout, '\n')
        if w =~ '\v^(Errors)\s*'
            let failed = 1
        elseif w =~ '\v^File:'
            let match_line_no = matchlist(w, '\v:(\d+):')
            let error['line'] = match_line_no[1]
            let error['file_line'] = match_line_no[1]
            let split_file = split(w, "E ")
            let match_file = matchlist(split_file[0], '\v\s+(.*.py):')
            let error['file_path'] = match_file[1]
            let error['path'] = match_file[1]
        endif
        if w =~ '\v\s+(\=\=\>)\s+'
            let split_error = split(w, ': ')
            let match_exc = matchlist(split_error[0], '\v\s+(\w+)')
            let error['exception'] = match_exc[1]
            let error.error = split_error[1]
            echo split_error
        endif
    endfor
    try
        let end_file_path = error['file_path']
    catch /^Vim\%((\a\+)\)\=:E/
        let error.file_path = error.path
        let error.file_line = error.line
    endtry
    let errors[1] = error

    " Display the result Bars
    if (failed == 1)
        let g:konira_session_errors = errors
        call s:ShowFails(1)
    elseif (failed == 0)
        call s:GreenBar()
    endif
endfunction


function! s:RedBar()
    redraw
    hi RedBar ctermfg=white ctermbg=red guibg=red
    echohl RedBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:GreenBar()
    redraw
    hi GreenBar ctermfg=white ctermbg=green guibg=green
    echohl GreenBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:ThisIt(verbose)
    let m_name  = s:NameOfCurrentIt()
    let c_name  = s:NameOfCurrentDescribe()
    let abspath = s:CurrentPath()
    if (strlen(m_name) == 1)
        call s:Echo("Unable to find a matching it for testing")
        return
    elseif (strlen(c_name) == 1)
        call s:Echo("Unable to find a matching describe for testing")
        return
    endif

    let path =  "'" . abspath . "::" . c_name . "::" . m_name . "'"
    let message = "konira ==> Running case for it " . m_name 
    call s:Echo(message, 1)

    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:Runkonira(path)
    endif
endfunction


function! s:ThisDescribe(verbose)
    let c_name      = s:NameOfCurrentDescribe()
    let abspath     = s:CurrentPath()
    if (strlen(c_name) == 1)
        call s:Echo("Unable to find a matching describe for testing")
        return
    endif
    let message  = "konira ==> Running cases for describe " . c_name 
    call s:Echo(message, 1)

    let path = "'" . abspath . "::" . c_name . "'"
    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:Runkonira(path)
    endif
endfunction


function! s:ThisFile(verbose)
    call s:Echo("konira ==> Running cases for entire file ", 1)
    let abspath     = s:CurrentPath()
    if (a:verbose == 1)
        call s:RunInSplitWindow(abspath)
    else
        call s:Runkonira(abspath)
    endif
endfunction
    

function! s:Version()
    call s:Echo("konira.vim version 0.0.1dev", 1)
endfunction


function! s:Completion(ArgLead, CmdLine, CursorPos)
    let result_order = "first\nlast\nnext\nprevious\n"
    let test_objects = "class\nmethod\nfile\n"
    let optional     = "verbose\n"
    let reports      = "fails\nerror\nsession\nend\n"
    let pyversion    = "version\n"
    return test_objects . result_order . reports . optional . pyversion
endfunction


" Check if we have a konira file
fun! s:SelectPy()
let n = 1
while n < 10 && n < line("$")
  " check for konira
  let encoding = '\v^#\s+coding:\s+konira'
  if getline(n) =~ encoding
      call s:KoniraSyntax()
    return
  endif
  let n = n + 1
  endwhile
endfun


function! s:Proxy(action, ...)
    if (a:0 == 1)
        let verbose = 1
    else
        let verbose = 0
    endif
    if (a:action == "describe")
        call s:ClearAll()
        call s:ThisDescribe(verbose)
    elseif (a:action == "it")
        call s:ClearAll()
        call s:ThisIt(verbose)
    elseif (a:action == "file")
        call s:ClearAll()
        call s:ThisFile(verbose)
    elseif (a:action == "fails")
        call s:ToggleFailWindow()
    elseif (a:action == "next")
        call s:GoToError(1)
    elseif (a:action == "previous")
        call s:GoToError(-1)
    elseif (a:action == "first")
        call s:GoToError(0)
    elseif (a:action == "last")
        call s:GoToError(2)
    elseif (a:action == "end")
        call s:GoToError(3)
    elseif (a:action == "session")
        call s:ToggleLastSession()
    elseif (a:action == "error")
        call s:ToggleShowError()
    elseif (a:action == "version")
        call s:Version()
    endif
endfunction


command! -nargs=+ -complete=custom,s:Completion Konira call s:Proxy(<f-args>)

" Detect konira test files and apply according syntax
autocmd BufNewFile,BufRead,BufEnter *.py call s:SelectPy()

