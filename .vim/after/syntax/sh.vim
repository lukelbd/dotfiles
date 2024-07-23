"------------------------------------------------------------------------------"
" Improve shell script syntax {{{1
"------------------------------------------------------------------------------"
" Figure out shell type {{{2
" TODO: Try heredoc highlighting from: .vim/after/syntax/perl/heredoc-perl.vim
" and awk highlighting from: https://stackoverflow.com/a/13925238/4970632
if !exists('b:is_kornshell') && !exists('b:is_bash')
  if exists('g:is_posix') && !exists('g:is_kornshell')
   let g:is_kornshell = g:is_posix
  endif
  if exists('g:is_kornshell')
    let b:is_kornshell = 1
    if exists('b:is_sh')
      unlet b:is_sh
    endif
  elseif exists('g:is_bash')
    let b:is_bash = 1
    if exists('b:is_sh')
      unlet b:is_sh
    endif
  else
    let b:is_sh = 1
  endif
endif

" PBS supercomputer system {{{2
" NOTE: This was adapated from sbatch block below
" See: https://unix.stackexchange.com/q/452461/112647
syn region shPBSComment start='^#\(PBS\)' end="\n" oneline contains=shPBSKeyword,shPBSOption,shPBSValue
syn region shPBSValue start="=" end="$" contains=shPBSString,shPBSMailType,shPBSIdentifier,shPBSEnv,shPBSHint,shPBSMode,shPBSPropag,shPBSInterval,shPBSDist,shPBSEmail
syn match shPBSKeyword contained '#\(PBS\)\s*'
syn match shPBSOption contained '\-[^=]*'
syn match shPBSNumber contained '\d\d*'
syn match shPBSDuration contained '\d\d*\(:\d\d\)\{,2}'
syn match shPBSNodeInfo contained '\d\d*\(:\d\d*\)\{,2}'
syn match shPBSDuration contained '\d\d*-\d\=\d\(:\d\d\)\{,2}'
syn match shPBSInterval contained '\d\d*\(-\d*\)\='
syn match shPBSString contained '.*'
syn match shPBSEnv contained '\d*L\=S\='
syn match shPBSDist contained 'plane\(=.*\)\='
syn match shPBSEmail contained '[-a-zA-Z0-9.+]*@[-a-zA-Z0-9.+]*'
syn keyword shPBSHint contained compute_bound memory_bound nomultithread multithread
syn keyword shPBSMode contained append truncate
syn keyword shPBSPropag contained ALL AS CORE CPU DATA FSIZE MEMLOCK NOFILE CPROC RSS STACK
syn keyword shPBSDist contained block cyclic arbitrary
hi def link shPBSComment Error
hi def link shPBSKeyword PreProc
hi def link shPBSOption PreProc
hi def link shPBSDuration Special
hi def link shPBSString Special
hi def link shPBSMailType Special
hi def link shPBSNumber Special
hi def link shPBSSep Special
hi def link shPBSNodeInfo Special
hi def link shPBSEnv Special
hi def link shPBSHint Special
hi def link shPBSMode Special
hi def link shPBSPropag Special
hi def link shPBSInterval Special
hi def link shPBSDist Special
hi def link shPBSEmail Special

" Slurm and sbatch supercomputer system {{{2
" NOTE: shSBATCHString are suspect.Shouldcould be narrowed down to more
" specific regular expressions. Typical example is --mail-type or --begin.
" See: https://github.com/SchedMD/slurm/blob/master/contribs/slurm_completion_help/slurm.vim
syn region shSBATCHComment start='^#\(SBATCH\)' end="\n" oneline contains=shSBATCHKeyword,shSBATCHOption,shSBATCHValue
syn region shSBATCHValue start="=" end="$" contains=shSBATCHString,shSBATCHMailType,shSBATCHIdentifier,shSBATCHEnv,shSBATCHHint,shSBATCHMode,shSBATCHPropag,shSBATCHInterval,shSBATCHDist,shSBATCHEmail
syn match shSBATCHKeyword contained '#\(SBATCH\)\s*'
syn match shSBATCHOption contained '--account=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--acctg-freq=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--extra-node-info=' nextgroup=shSBATCHNodeInfo
syn match shSBATCHOption contained '--socket-per-node=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--cores-per-socket=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--threads-per-core=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--begin=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--checkpoint=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--checkpoint-dir=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--comment=' nextgroup=shSBATCHIdentifier
syn match shSBATCHOption contained '--constraint=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--contiguous'
syn match shSBATCHOption contained '--cpu-bind==' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--cpus-per-task=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--dependency=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--workdir=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--error=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--exclusive'
syn match shSBATCHOption contained '--nodefile=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--get-user-env'
syn match shSBATCHOption contained '--get-user-env=' nextgroup=shSBATCHEnv
syn match shSBATCHOption contained '--gid=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--hint=' nextgroup=shSBATCHHint
syn match shSBATCHOption contained '--immediate' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--input=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--job-name=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--job-id=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--no-kill'
syn match shSBATCHOption contained '--licences=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--distribution=' nextgroup=shSBATCHDist
syn match shSBATCHOption contained '--mail-user=' nextgroup=shSBATCHEmail
syn match shSBATCHOption contained '--mail-type=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--mem=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--mem-per-cpu=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--mem-bind=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--mincores=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--mincpus=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--minsockets=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--minthreads=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--nodes=' nextgroup=shSBATCHInterval
syn match shSBATCHOption contained '--ntasks=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--network=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--nice'
syn match shSBATCHOption contained '--nice=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--no-requeue'
syn match shSBATCHOption contained '--ntasks-per-core=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--ntasks-per-socket=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--ntasks-per-node=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--overcommit'
syn match shSBATCHOption contained '--output=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--open-mode=' nextgroup=shSBATCHMode
syn match shSBATCHOption contained '--partition=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--propagate'
syn match shSBATCHOption contained '--propagate=' nextgroup=shSBATCHPropag
syn match shSBATCHOption contained '--quiet'
syn match shSBATCHOption contained '--requeue'
syn match shSBATCHOption contained '--reservation=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--share'
syn match shSBATCHOption contained '--signal=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--time=' nextgroup=shSBATCHDuration
syn match shSBATCHOption contained '--tasks-per-node=' nextgroup=shSBATCHNumber
syn match shSBATCHOption contained '--tmp=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--uid=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--nodelist=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--wckey=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--wrap=' nextgroup=shSBATCHString
syn match shSBATCHOption contained '--exclude=' nextgroup=shSBATCHString
syn match shSBATCHNumber contained '\d\d*'
syn match shSBATCHDuration contained '\d\d*\(:\d\d\)\{,2}'
syn match shSBATCHNodeInfo contained '\d\d*\(:\d\d*\)\{,2}'
syn match shSBATCHDuration contained '\d\d*-\d\=\d\(:\d\d\)\{,2}'
syn match shSBATCHInterval contained '\d\d*\(-\d*\)\='
syn match shSBATCHString contained '.*'
syn match shSBATCHEnv contained '\d*L\=S\='
syn match shSBATCHDist contained 'plane\(=.*\)\='
syn match shSBATCHEmail contained '[-a-zA-Z0-9.+]*@[-a-zA-Z0-9.+]*'
syn keyword shSBATCHHint contained compute_bound memory_bound nomultithread multithread
syn keyword shSBATCHMode contained append truncate
syn keyword shSBATCHPropag contained ALL AS CORE CPU DATA FSIZE MEMLOCK NOFILE CPROC RSS STACK
syn keyword shSBATCHDist contained block cyclic arbitrary
hi def link shSBATCHComment Error
hi def link shSBATCHKeyword PreProc
hi def link shSBATCHOption PreProc
hi def link shSBATCHString Special
hi def link shSBATCHMailType Special
hi def link shSBATCHNumber Special
hi def link shSBATCHSep Special
hi def link shSBATCHNodeInfo Special
hi def link shSBATCHEnv Special
hi def link shSBATCHHint Special
hi def link shSBATCHMode Special
hi def link shSBATCHPropag Special
hi def link shSBATCHInterval Special
hi def link shSBATCHDist Special
hi def link shSBATCHEmail Special
