" **************************************************************************** "
"                                                                              "
"                                                         :::      ::::::::    "
"    upload_to_server.vim                               :+:      :+:    :+:    "
"                                                     +:+ +:+         +:+      "
"    By: vismaily <nenie_iri@mail.ru>               +#+  +:+       +#+         "
"                                                 +#+#+#+#+#+   +#+            "
"    Created: 2024/06/04 18:12:58 by vismaily          #+#    #+#              "
"    Updated: 2024/08/20 11:22:49 by vismaily         ###   ########.fr        "
"                                                                              "
" **************************************************************************** "

let g:repo_time_file = expand('~/.vim/plugin/repoTimeFile.txt')

let g:exclude_dirs_UtS = map(g:exclude_dirs_UtS, {idx, val -> g:local_repo_path_UtS . '/' . val})

" defining the commands
command! PutFile :call PutCurrentFile(g:user_UtS, g:password_UtS, g:host_UtS, g:algorithm_UtS, g:local_repo_path_UtS, g:remote_repo_path_UtS, g:repo_time_file)
command! PutAll :call PutAllFiles(g:user_UtS, g:password_UtS, g:host_UtS, g:algorithm_UtS, g:local_repo_path_UtS, g:remote_repo_path_UtS, g:repo_time_file)
command! PutQuick :call PutQuickAllFiles(g:user_UtS, g:password_UtS, g:host_UtS, g:algorithm_UtS, g:local_repo_path_UtS, g:remote_repo_path_UtS, g:repo_time_file)
command! PutInit :call PutInit(g:local_repo_path_UtS, g:repo_time_file)

" defining the hotkeys for commands
nnoremap <C-P> :PutFile<CR>
nnoremap <C-A> :PutAll<CR>
nnoremap <C-Q> :PutQuick<CR> 
nnoremap <C-I> :PutInit<CR> 

" Function to get the last modification date of a file
function! GetFileModificationDate(file)
	try
		let l:mtime = system('stat -c %Y ' . shellescape(a:file))
		" Remove null characters from the modification time
		let l:mtime = substitute(l:mtime, '\%x00', '', 'g')
		return l:mtime
	catch
        echohl ErrorMsg
        echo "ERROR: Failed to get modification date for " . a:file
        echohl NONE
        return -1
    endtry
endfunction

" Function to trasfer the current file
function! PutCurrentFile(user, password, host, algorithm, local_base_path, remote_base_path, repo_time_file)
	let l:current_file = expand('%:p')
	call SCPFile(a:user, a:password, a:host, a:algorithm, a:local_base_path, a:remote_base_path, l:current_file, a:repo_time_file)
endfunction

" Recursive function to traverse directories and append in repoTimeFile.txt the
" file name and its last modification time
function! CreateRepoTimeFile(local_path, repo_time_file)
	try
		let l:files = systemlist('ls -A ' . a:local_path)

		for file in l:files
			let l:full_path = a:local_path . '/' . file

			if file[0] != '.' && isdirectory(l:full_path)
				call CreateRepoTimeFile(l:full_path, a:repo_time_file)
			elseif file[0] != '.'
				let l:mod_time = GetFileModificationDate(l:full_path)
				if l:mod_time == -1
                    return -1
                endif
				" Append the file path and modification time to repoTimeFile.txt
				call writefile([l:full_path . '|' . l:mod_time], a:repo_time_file, 'a')
			endif
		endfor
		return 0
	catch
	    echohl ErrorMsg
        echo "ERROR: Failed to process " . l:full_path
        echohl NONE
        return -1
	endtry
endfunction

" Function to parse the repoTimeFile.txt and
" return a dictionary of file paths and modification dates
function! ParseRepoTimeFile(repo_time_file)
    let l:repo_times = {}
    try
        let l:lines = readfile(a:repo_time_file)
        for line in l:lines
            let [file_path, mod_time] = split(line, '|')
            let l:repo_times[file_path] = mod_time
        endfor
    catch
        echohl ErrorMsg
        echo "ERROR: Unable to read or parse repo time file."
        echohl NONE
        return -1
    endtry
    return l:repo_times
endfunction

" Function to clear the repoTimeFile.txt before writing new data
function! PutInit(local_repo_path, repo_time_file)

    " Display loading message
	echohl WarningMsg
	echo "Creating repoTimeFile with modification times of files."
	echo "Please wait..."
	echohl NONE

    call writefile([], a:repo_time_file)
    let l:res = CreateRepoTimeFile(a:local_repo_path, a:repo_time_file)

	redraw!

	if l:res == -1
        echohl ErrorMsg
        echom "ERROR: Initialization failed."
        echohl NONE
    else
        echohl MoreMsg
		echom "Files' modification times were initialized and saved."
        echohl NONE
    endif
endfunction

" Recursive function to traverse directories and get needed files
function! Get_files_recursive(local_path, remote_path)
    let l:files = systemlist('ls -A ' . a:local_path)
	let l:result_local = []
    let l:result_remote = []

    for file in l:files
		let l:full_path = a:local_path . '/' . file
		let l:remote_dir = a:remote_path . '/' . file

        if file[0] != '.' && isdirectory(full_path)
			" Exclude specified directories from exclude list
			if index(g:exclude_dirs_UtS, l:full_path . '/') == -1
				let [l:local, l:remote] = Get_files_recursive(l:full_path, l:remote_dir)
				call extend(l:result_local, l:local)
                call extend(l:result_remote, l:remote)
			endif
        elseif file[0] != '.'
			" Check if the file extension is not in the excluded list
			let l:ext = fnamemodify(file, ':e')  " Get the file extension
            if index(g:exclude_exts_UtS, '.' . l:ext) == -1
				call add(l:result_local, l:full_path)
				call add(l:result_remote, l:remote_dir)
			endif
        endif
    endfor

	return [l:result_local, l:result_remote]
endfunction

" Function to transfer all files listed in arguments
function! PutFiles(command, user, host, remote_base_path, res_local, res_remote)
    " Display loading message
	echohl WarningMsg
    echo "Uploading files to the remote server."
	echo "Please wait..."
	echohl NONE

	let l:all_files_copied = 1  " Assume all files are copied successfully
	let l:failed_files = []     " List to store paths of files that failed to copy

	set nomore

	for i in range(len(a:res_local))
		let l:local_path = shellescape(a:res_local[i], 1)
		let l:remote_path = shellescape(a:res_remote[i], 1)

		" construct scp command
		let l:scp_command = a:command . ' ' . l:local_path
		let l:scp_command .= ' ' . a:user . '@' . a:host . ':' . l:remote_path

		try
			let [l:status, l:output] = systemlist(l:scp_command)
			let l:status = 0
		catch
			let l:status = 1
		endtry

		if l:status == 0
			echohl MoreMsg
			echo "SUCCESS: " . l:local_path
			echohl NONE
		else
			echohl ErrorMsg
			echo "FAIL: " . l:local_path
			echohl NONE
			let l:all_files_copied = 0  " Set to 0 if any file fails to copy
			call add(l:failed_files, l:local_path)  " Store failed file path
		endif
	endfor

	if l:all_files_copied == 1
		echohl MoreMsg
		echo "All files copied successfully."
		echo " "
		let c = getchar()
		echohl NONE
		set more
		return 0
	else
		echohl WarningMsg
		echo "Failed to copy all files."
		echo "This is a list of files which were not copied to the server:"
		echohl ErrorMsg
		for file in l:failed_files
            echo file
        endfor
		echohl NONE
		set more
		return -1
	endif
endfunction

" Function to filter out files that have not been updated
function! FilterUpdatedFiles(local_files, remote_files, repo_times)
    let l:filtered_local = []
    let l:filtered_remote = []

    for i in range(len(a:local_files))
        let local_file = a:local_files[i]
        let remote_file = a:remote_files[i]
        let local_mod_time = GetFileModificationDate(local_file)

        " Check if the file exists in the repo_times dictionary
        if has_key(a:repo_times, local_file)
            let repo_mod_time = a:repo_times[local_file]

            " Compare the modification times
            if local_mod_time != repo_mod_time
                call add(l:filtered_local, local_file)
                call add(l:filtered_remote, remote_file)
            endif
        else
            " If the file is not in the repo_times, add it to the filtered list
            call add(l:filtered_local, local_file)
            call add(l:filtered_remote, remote_file)
        endif
    endfor

    return [l:filtered_local, l:filtered_remote]
endfunction

" Function to update the repo time file with the transferred files' modification dates
function! UpdateRepoTimeFile(repo_time_file, transferred_files, repo_times)
    try
		let l:repo_times_local = a:repo_times

        " Update the modification dates of the transferred files
        for file in a:transferred_files
            let l:mod_time = GetFileModificationDate(file)
            let l:repo_times_local[file] = l:mod_time
        endfor

        " Write the updated dictionary back to the repo time file
        let l:lines = []
        for [file_path, mod_time] in items(l:repo_times_local)
            call add(l:lines, file_path . '|' . mod_time)
        endfor

        call writefile(l:lines, a:repo_time_file, 'w')

    catch
        echohl ErrorMsg
        echo "ERROR: Failed to update repo time file."
        echo " "
        echohl NONE
        return -1
    endtry

    return 0
endfunction

" Function to transfer all files from the local repo to the remote repo
function! PutAllFiles(user, password, host, algorithm, local_base_path, remote_base_path, repo_time_file)
    let l:password = a:password

	" Prompt for password if not provided
    if l:password == ''
        let l:password = inputsecret("Enter password: ")
		echo "\n"
    endif

	" Initial connection check
	let l:check_command = 'sshpass -p ' . l:password . ' ssh ' . a:algorithm
	let l:check_command .= 	' ' . a:user . '@' . a:host . ' exit'

    try
        silent! let l:check_status = system(l:check_command)
        if v:shell_error != 0
            throw 'Connection check failed.'
        endif
    catch
        echohl ErrorMsg
        echo "ERROR: Unable to establish connection to the remote server."
        echohl NONE
        echo "Executed command:\n" . l:check_command
        return -1
    endtry

	let l:command = '! sshpass -p ' . l:password . ' scp -s ' . a:algorithm

	" Recursively get the list of files
	let [l:res_local, l:res_remote] = Get_files_recursive(a:local_base_path, a:remote_base_path)

	echo l:res_local

	let l:status =  PutFiles(l:command, a:user, a:host, a:remote_base_path, l:res_local, l:res_remote)
	if l:status == -1
		return -1
	endif

	" Parse the existing repo time file
	let l:repo_times = ParseRepoTimeFile(a:repo_time_file)
	if l:repo_times == -1
		return -1
	endif

	" Update the repo time file with the transferred files' modification dates
    let l:update_status = UpdateRepoTimeFile(a:repo_time_file, l:res_local, l:repo_times)
    if l:update_status == -1
        return -1
    endif
	return 0
endfunction

" Function to transfer all UPDATED files from the local repo to the remote repo
function! PutQuickAllFiles(user, password, host, algorithm, local_base_path, remote_base_path, repo_time_file)
    let l:password = a:password

	" Prompt for password if not provided
    if l:password == ''
        let l:password = inputsecret("Enter password: ")
		echo "\n"
    endif

	" Initial connection check
	let l:check_command = 'sshpass -p ' . l:password . ' ssh ' . a:algorithm
	let l:check_command .= 	' ' . a:user . '@' . a:host . ' exit'

    try
        silent! let l:check_status = system(l:check_command)
        if v:shell_error != 0
            throw 'Connection check failed.'
        endif
    catch
        echohl ErrorMsg
        echo "ERROR: Unable to establish connection to the remote server."
        echohl NONE
        echo "Executed command:\n" . l:check_command
        return -1
    endtry

	let l:command = '! sshpass -p ' . l:password . ' scp -s ' . a:algorithm

	" Recursively get the list of files
	let [l:res_local, l:res_remote] = Get_files_recursive(a:local_base_path, a:remote_base_path)

	" Parse the repo time file
    let l:repo_times = ParseRepoTimeFile(a:repo_time_file)
	if type(l:repo_times) != type({})
        return -1
    endif

    " Filter out files that have not been updated
    let [l:filtered_local, l:filtered_remote] = FilterUpdatedFiles(l:res_local, l:res_remote, l:repo_times)
	if len(l:filtered_local) == 0
		echohl MoreMsg
		echo "There are no updated files"
		echohl NONE
		return 0
	endif

	let l:status = PutFiles(l:command, a:user, a:host, a:remote_base_path, l:filtered_local, l:filtered_remote)
 	if l:status == -1
 		return -1
 	endif

   " Update the repo time file with the transferred files' modification dates
    let l:update_status = UpdateRepoTimeFile(a:repo_time_file, l:filtered_local, l:repo_times)
    if l:update_status == -1
        return -1
    endif

    echohl MoreMsg
    echo "Files were transferred and repo_time_file was updated."
    echo " "
    echohl NONE
	return 0
endfunction

" Function to perform SCP based on given user, password, host, and directory
function! SCPFile(user, password, host, algorithm, local_base_path, remote_base_path, file, repo_time_file)
    let l:password = a:password
    let l:file = shellescape(a:file, 1)

	" Prompt for password if not provided
    if l:password == ''
        let l:password = inputsecret("Enter password: ")
		echo "\n"
    endif

    " Replace the local base path with the remote base path
    let l:relative_path = substitute(a:file, '^' . a:local_base_path, '', '')
	let l:remote_path = a:remote_base_path . l:relative_path
	let l:remote_path = shellescape(l:remote_path, 1)
    let l:full_remote_path = a:user . '@' . a:host . ':' . l:remote_path

    " Constructing the command
	let l:command = '! sshpass -p ' . l:password . ' scp -s ' . a:algorithm
	let l:command .= ' ' . l:file . ' ' . l:full_remote_path

	" echo l:command

	try
		let [l:status, l:output] = systemlist(l:command)
		let l:status = 0
	catch
		let l:status = 1
	endtry

	redraw!

 	if l:status == 0
 		" File copied successfully
 		echohl MoreMsg
 		echo "SUCCESS"
 		echo " "
 		echo "file:"
 		echo l:file
 		echo "copied to:"
 		echo l:remote_path
 		echo " "
 		echo "File copied successfully."
 		echohl NONE

        " Parse the existing repo time file
        let l:repo_times = ParseRepoTimeFile(a:repo_time_file)
		if type(l:repo_times) != type({})
			return -1
		endif

		" Update the repo time file
		let l:repo_times[a:file] = GetFileModificationDate(a:file)
        let l:lines = []
        for [file_path, mod_time] in items(l:repo_times)
            call add(l:lines, file_path . '|' . mod_time)
        endfor

        let l:update_status = writefile(l:lines, a:repo_time_file, 'w')

		if l:update_status == -1
			echohl ErrorMsg
			echo "ERROR: Failed to update repo time file."
			echo " "
			echohl NONE
			return -1
		else
			echohl MoreMsg
			echo " "
			echo "repo_time_file was updated."
			echo " "
			echohl NONE
		endif
		return 0
 	else
 		" File copy failed
 		echohl ErrorMsg
 		echo "FAIL"
 		echo l:command
 		echo " "
 		echo "file:" 
 		echo l:file
         echo "not copied to:"
 		echo l:full_remote_path
 		echo " "
 		echo "File copy failed."
 		echohl NONE
		return -1
 	endif
endfunction
