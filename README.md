# Upload to Server
This Vim plugin connects your local repository with your remote repository and transfers files from the local repo to the remote server.<br>

Under the hood, the plugin uses **SCP** for file transferring.<br>
So you need to have **SSH** and **SSHPASS** installed on your machine and you should configure your SSH connection credentials correctly in your vimrc file.<be>

The plugin was initially created for transferring files to the **OpenVMS** operating system (and was tested on it), but it should also work for other systems.<br>

## Prepare
**First step:** Copy the ```upload_to_server.vim``` file to your ```~/.vim/plugin/``` folder.

**Second step:** Add the below code to your vimrc file and config them:

```vim
" Define the connection credentials
let g:user_UtS = 'username'
let g:password_UtS = 'password'
" or leave it empty like this - let g:password_UtS = ''

let g:host_UtS = '10.11.11.11'
let g:algorithm_UtS = ''

" Define the local and remote repo paths
let g:local_repo_path_UtS = expand('~/Documents/exampleRepo')
let g:remote_repo_path_UtS = '/WORK/USER/myProjects/test'

" Define directories which you don't want to trasfer
" Like this - ['unit/', 'examples/'] (Append the '/' character!). Or leave it empty
let g:exclude_dirs_UtS = []

" Add your excluded extensions here. Like this - ['.log', '.tmp', '.bak']
" Or leave it empty
let g:exclude_exts_UtS = []
```

## Usage
There are **4** commands that you can use:
- ```:PutInit```  (CTRL+I) - creates plugin internal file (called _repoTimeFile.txt_) for saving repositories' files' last modification date. This is needed for Quick upload. You need to run this command only once, after preparation.
- ```:PutFile```  (CTRL+P) - transfer the current file to the remote server and update repoTimeFile.txt.
- ```:PutAll```   (CTRL+A) - transfer all the repo files to the remote server and update repoTimeFile.txt.
- ```:PutQuick``` (CTRL+Q) - transfer all repo files that were updated compared to their time in the repoTimeFile and update it.

Hotkeys work in **Normal mode** only.
