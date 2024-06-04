# upload_to_server
```vim
" Define the connection credentials
let g:user_UtS = 'username'
let g:password_UtS = 'password'
" or leave it empty like this - let g:password_UtS = ''

let g:host_UtS = '10.11.11.11'
let g:algorithm_UtS = ''

" Define the local and remote repo paths
let g:local_repo_path_UtS = expand('~/Documents/exampleRepo/')
let g:remote_repo_path_UtS = '/WORK/USER/myProjects/test'

" Define directories which you don't want to trasfer
" Like this - ['unit/', 'examples/'] (Append the '/' character!). Or leave it empty
let g:exclude_dirs_UtS = []

" Add your excluded extensions here. Like this - ['.log', '.tmp', '.bak']
" Or leave it empty
let g:exclude_exts_UtS = []
```
