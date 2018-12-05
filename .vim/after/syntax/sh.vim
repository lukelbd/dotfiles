"------------------------------------------------------------------------------"
" Vim syntax file for completion for Slurm and embedded Awk highlighting
"------------------------------------------------------------------------------"
" Awk: copied from https://stackoverflow.com/a/13925238/4970632
" Currently just highlights stuff white; needs work.
"------------------------------------------------------------------------------"
" syn include @AWKScript syntax/awk.vim
" syn region AWKScriptCode matchgroup=AWKCommand
"     \ start=+[=\\]\@<!'+ skip=+\\'+ end=+'+ contains=@AWKScript contained
" " syn region AWKScriptEmbedded matchgroup=AWKCommand
" "     \ start=+\<g\?awk\>+ skip=+\\$+ end=+[=\\]\@<!'+me=e-1
" "     \ contains=@shIdList,@shExprList2 nextgroup=AWKScriptCode
" " syn region AWKScriptEmbedded matchgroup=AWKCommand
" "     \ start=+\$AWK\>+ skip=+\\$+ end=+[=\\]\@<!'+me=e-1
" "     \ contains=@shIdList,@shExprList2 containedin=shDerefSimple nextgroup=AWKScriptCode
" syn region AWKScriptEmbedded matchgroup=AWKCommand
"     \ start=+\<\(g\?awk\|\$AWK\)\>+ skip=+\\$+ end=+[=\\]\@<!'+me=e-1
"     \ contains=@shIdList,@shExprList2 nextgroup=AWKScriptCode
" syn cluster shCommandSubList add=AWKScriptEmbedded
" hi def link AWKCommand Type
"------------------------------------------------------------------------------"
"Manage shell type
if !exists("b:is_kornshell") && !exists("b:is_bash")
  if exists("g:is_posix") && !exists("g:is_kornshell")
   let g:is_kornshell= g:is_posix
  endif
  if exists("g:is_kornshell")
    let b:is_kornshell= 1
    if exists("b:is_sh")
      unlet b:is_sh
    endif
  elseif exists("g:is_bash")
    let b:is_bash= 1
    if exists("b:is_sh")
      unlet b:is_sh
    endif
  else
    let b:is_sh= 1
  endif
endif

"PBS system, less precise highlighting
"Simply copied from Slurm example below
"See also discussion here: https://unix.stackexchange.com/q/452461/112647
syn match shPBSKeyword contained '#\(PBS\)\s*'
syn region shPBSComment start='^#\(PBS\)' end="\n" oneline contains=shPBSKeyword,shPBSOption,shPBSValue
syn match shPBSOption contained '\-[^=]*'
hi def link shPBSKeyword PreProc
hi def link shPBSComment Error
syn region shPBSValue start="=" end="$" contains=shPBSString,shPBSMailType,shPBSIdentifier,shPBSEnv,shPBSHint,shPBSMode,shPBSPropag,shPBSInterval,shPBSDist,shPBSEmail
syn match shPBSNumber   contained '\d\d*'
syn match shPBSDuration contained '\d\d*\(:\d\d\)\{,2}'
syn match shPBSNodeInfo contained '\d\d*\(:\d\d*\)\{,2}'
syn match shPBSDuration contained '\d\d*-\d\=\d\(:\d\d\)\{,2}'
syn match shPBSInterval contained '\d\d*\(-\d*\)\='
syn match shPBSString   contained '.*'
syn match shPBSEnv      contained '\d*L\=S\='
syn keyword shPBSHint   contained compute_bound memory_bound nomultithread multithread
syn keyword shPBSMode   contained append truncate
syn keyword shPBSPropag contained ALL AS CORE CPU DATA FSIZE MEMLOCK NOFILE CPROC RSS STACK
syn keyword shPBSDist   contained block cyclic arbitrary
syn match shPBSDist  contained  'plane\(=.*\)\='
syn match shPBSEmail contained  '[-a-zA-Z0-9.+]*@[-a-zA-Z0-9.+]*'
hi def link shPBSComment  Error
hi def link shPBSKeyword  PreProc
hi def link shPBSOption   PreProc
hi def link shPBSDuration Special
hi def link shPBSString   Special
hi def link shPBSMailType Special
hi def link shPBSNumber   Special
hi def link shPBSSep      Special
hi def link shPBSNodeInfo Special
hi def link shPBSEnv      Special
hi def link shPBSHint     Special
hi def link shPBSMode     Special
hi def link shPBSPropag   Special
hi def link shPBSInterval Special
hi def link shPBSDist     Special
hi def link shPBSEmail    Special

"SLURM/SBATCH supercomputer system; see https://github.com/SchedMD/slurm/blob/master/contribs/slurm_completion_help/slurm.vim
"All shSlurmString are suspect; they probably could be narrowed down to more
"specific regular expressions. Typical example is --mail-type or --begin
syn region shSlurmComment start='^#\(SBATCH\)' end="\n" oneline contains=shSlurmKeyword,shSlurmOption,shSlurmValue
syn match shSlurmKeyword contained '#\(SBATCH\)\s*'
syn match shSlurmOption contained '--account='           nextgroup=shSlurmString
syn match shSlurmOption contained '--acctg-freq='        nextgroup=shSlurmNumber
syn match shSlurmOption contained '--extra-node-info='   nextgroup=shSlurmNodeInfo
syn match shSlurmOption contained '--socket-per-node='   nextgroup=shSlurmNumber
syn match shSlurmOption contained '--cores-per-socket='  nextgroup=shSlurmNumber
syn match shSlurmOption contained '--threads-per-core='  nextgroup=shSlurmNumber
syn match shSlurmOption contained '--begin='             nextgroup=shSlurmString
syn match shSlurmOption contained '--checkpoint='        nextgroup=shSlurmString
syn match shSlurmOption contained '--checkpoint-dir='    nextgroup=shSlurmString
syn match shSlurmOption contained '--comment='           nextgroup=shSlurmIdentifier
syn match shSlurmOption contained '--constraint='        nextgroup=shSlurmString
syn match shSlurmOption contained '--contiguous'
syn match shSlurmOption contained '--cpu-bind=='         nextgroup=shSlurmString
syn match shSlurmOption contained '--cpus-per-task='     nextgroup=shSlurmNumber
syn match shSlurmOption contained '--dependency='        nextgroup=shSlurmString
syn match shSlurmOption contained '--workdir='           nextgroup=shSlurmString
syn match shSlurmOption contained '--error='             nextgroup=shSlurmString
syn match shSlurmOption contained '--exclusive'
syn match shSlurmOption contained '--nodefile='          nextgroup=shSlurmString
syn match shSlurmOption contained '--get-user-env'
syn match shSlurmOption contained '--get-user-env='      nextgroup=shSlurmEnv
syn match shSlurmOption contained '--gid='               nextgroup=shSlurmString
syn match shSlurmOption contained '--hint='              nextgroup=shSlurmHint
syn match shSlurmOption contained '--immediate'          nextgroup=shSlurmNumber
syn match shSlurmOption contained '--input='             nextgroup=shSlurmString
syn match shSlurmOption contained '--job-name='          nextgroup=shSlurmString
syn match shSlurmOption contained '--job-id='            nextgroup=shSlurmNumber
syn match shSlurmOption contained '--no-kill'
syn match shSlurmOption contained '--licences='          nextgroup=shSlurmString
syn match shSlurmOption contained '--distribution='      nextgroup=shSlurmDist
syn match shSlurmOption contained '--mail-user='         nextgroup=shSlurmEmail
syn match shSlurmOption contained '--mail-type='         nextgroup=shSlurmString
syn match shSlurmOption contained '--mem='               nextgroup=shSlurmNumber
syn match shSlurmOption contained '--mem-per-cpu='       nextgroup=shSlurmNumber
syn match shSlurmOption contained '--mem-bind='          nextgroup=shSlurmNumber
syn match shSlurmOption contained '--mincores='          nextgroup=shSlurmNumber
syn match shSlurmOption contained '--mincpus='           nextgroup=shSlurmNumber
syn match shSlurmOption contained '--minsockets='        nextgroup=shSlurmNumber
syn match shSlurmOption contained '--minthreads='        nextgroup=shSlurmNumber
syn match shSlurmOption contained '--nodes='             nextgroup=shSlurmInterval
syn match shSlurmOption contained '--ntasks='            nextgroup=shSlurmNumber
syn match shSlurmOption contained '--network='           nextgroup=shSlurmString
syn match shSlurmOption contained '--nice'
syn match shSlurmOption contained '--nice='              nextgroup=shSlurmNumber
syn match shSlurmOption contained '--no-requeue'
syn match shSlurmOption contained '--ntasks-per-core='   nextgroup=shSlurmNumber
syn match shSlurmOption contained '--ntasks-per-socket=' nextgroup=shSlurmNumber
syn match shSlurmOption contained '--ntasks-per-node='   nextgroup=shSlurmNumber
syn match shSlurmOption contained '--overcommit'
syn match shSlurmOption contained '--output='            nextgroup=shSlurmString
syn match shSlurmOption contained '--open-mode='         nextgroup=shSlurmMode
syn match shSlurmOption contained '--partition='         nextgroup=shSlurmString
syn match shSlurmOption contained '--propagate'
syn match shSlurmOption contained '--propagate='         nextgroup=shSlurmPropag
syn match shSlurmOption contained '--quiet'
syn match shSlurmOption contained '--requeue'
syn match shSlurmOption contained '--reservation='       nextgroup=shSlurmString
syn match shSlurmOption contained '--share'
syn match shSlurmOption contained '--signal='            nextgroup=shSlurmString
syn match shSlurmOption contained '--time='              nextgroup=shSlurmDuration
syn match shSlurmOption contained '--tasks-per-node='    nextgroup=shSlurmNumber
syn match shSlurmOption contained '--tmp='               nextgroup=shSlurmString
syn match shSlurmOption contained '--uid='               nextgroup=shSlurmString
syn match shSlurmOption contained '--nodelist='          nextgroup=shSlurmString
syn match shSlurmOption contained '--wckey='             nextgroup=shSlurmString
syn match shSlurmOption contained '--wrap='              nextgroup=shSlurmString
syn match shSlurmOption contained '--exclude='           nextgroup=shSlurmString
syn region shSlurmValue start="=" end="$" contains=shSlurmString,shSlurmMailType,shSlurmIdentifier,shSlurmEnv,shSlurmHint,shSlurmMode,shSlurmPropag,shSlurmInterval,shSlurmDist,shSlurmEmail
syn match shSlurmNumber   contained '\d\d*'
syn match shSlurmDuration contained '\d\d*\(:\d\d\)\{,2}'
syn match shSlurmNodeInfo contained '\d\d*\(:\d\d*\)\{,2}'
syn match shSlurmDuration contained '\d\d*-\d\=\d\(:\d\d\)\{,2}'
syn match shSlurmInterval contained '\d\d*\(-\d*\)\='
syn match shSlurmString   contained '.*'
syn match shSlurmEnv      contained '\d*L\=S\='
syn keyword shSlurmHint   contained compute_bound memory_bound nomultithread multithread
syn keyword shSlurmMode   contained append truncate
syn keyword shSlurmPropag contained ALL AS CORE CPU DATA FSIZE MEMLOCK NOFILE CPROC RSS STACK
syn keyword shSlurmDist   contained block cyclic arbitrary
syn match shSlurmDist  contained  'plane\(=.*\)\='
syn match shSlurmEmail contained  '[-a-zA-Z0-9.+]*@[-a-zA-Z0-9.+]*'
hi def link shSlurmComment  Error
hi def link shSlurmKeyword  PreProc
hi def link shSlurmOption   PreProc
" hi def link shSlurmDuration Special
hi def link shSlurmString   Special
hi def link shSlurmMailType Special
hi def link shSlurmNumber   Special
hi def link shSlurmSep      Special
hi def link shSlurmNodeInfo Special
hi def link shSlurmEnv      Special
hi def link shSlurmHint     Special
hi def link shSlurmMode     Special
hi def link shSlurmPropag   Special
hi def link shSlurmInterval Special
hi def link shSlurmDist     Special
hi def link shSlurmEmail    Special
