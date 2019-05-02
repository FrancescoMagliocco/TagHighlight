" Tag Highlighter:
"   Author:  A. S. Budden <abudden _at_ gmail _dot_ com>
" Copyright: Copyright (C) 2013 A. S. Budden
"            Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            the TagHighlight plugin is provided *as is* and comes with no
"            warranty of any kind, either expressed or implied. By using
"            this plugin, you agree that in no event will the copyright
"            holder be liable for any damages resulting from the use
"            of this software.

" ---------------------------------------------------------------------

" If there is not support for 'cscope' or if it's not enabled, don't source
" this file.
if !exists('g:loaded_TagHighlight')
      \ || !has('cscope')
      \ || !TagHighlight#Option#GetOption('EnableCscope')
      \ || (exists('g:loaded_TagHLCscope') && (g:plugin_development_mode != 1))
  finish
endif

let g:loaded_TagHLCscope = 1

function TagHighlight#Cscope#GetConnections()
  let result = {}

  redir => connections
  silent cs show
  redir END

  let lines = split(connections, '\n')
  for entry in lines
    let matches = matchlist(entry, '^\s*\(\d\+\)\s\+\(\d\+\)\s\+\(\k\+\).*')
    if len(matches) >= 4
      " Just store the path (likely to be inconclusive due to lack of
      " explicit path in "cs show" output)
      let result[matches[1]] = matches[3]
    endif
  endfor

  return result
endfunction

function! TagHighlight#Cscope#RestoreConnections(connections)
  for index in keys(a:connections)
    exe 'silent cs add' a:connections[index]
  endfor
endfunction

let s:PausedConnections = {}
function! TagHighlight#Cscope#PauseCscope()
  " All of the checks for 'EnabledCscope' in this file are removed and are done
  " at the top of this file

  let s:PausedConnections = TagHighlight#Cscope#GetConnections()

  " Kill all cscope connections
  silent cs kill -1
endfunction

function! TagHighlight#Cscope#ResumeCscope()
  if has_key(
        \ b:TagHighlightPrivate, 'CscopeFileInfo')
        \ && b:TagHighlightPrivate['CscopeFileInfo']['Exists']
    exe 'silent cs add' b:TagHighlightPrivate['CscopeFileInfo']['FullPath']
  else
    let b:TagHighlightPrivate['CscopeFileInfo'] =
          \ TagHighlight#Find#LocateFile('CSCOPE', '')
    if b:TagHighlightPrivate['CscopeFileInfo']['Exists']
      exe 'silent cs add' b:TagHighlightPrivate['CscopeFileInfo']['FullPath']
    else
      call TagHighlight#Cscope#RestoreConnections(s:PausedConnections)
    endif
  endif
endfunction

function! TagHighlight#Cscope#BufEnter()
  let b:TagHighlightPrivate['StoredCscopeConnections'] =
        \ TagHighlight#Cscope#GetConnections()
  " Kill all connections
  silent cs kill -1

  if !has_key(b:TagHighlightPrivate, 'CscopeFileInfo')
    let b:TagHighlightPrivate['CscopeFileInfo'] =
          \ TagHighlight#Find#LocateFile('CSCOPE', '')
  endif

  if b:TagHighlightPrivate['CscopeFileInfo']['Exists']
    exe 'silent cs add' b:TagHighlightPrivate['CscopeFileInfo']['FullPath']
  endif
endfunction

function! TagHighlight#Cscope#BufLeave()
  silent cs kill -1
  if has_key(b:TagHighlightPrivate, 'StoredCscopeConnections')
    if len(b:TagHighlightPrivate['StoredCscopeConnections'])
      call TagHighlight#Cscope#RestoreConnections(
            \ b:TagHighlightPrivate['StoredCscopeConnections'])
    endif
  endif
endfunction

function! TagHighlight#Cscope#FindCscopeExe()
  " Find the cscope path
  let cscope_option = TagHighlight#Option#GetOption('CscopeExecutable')
  if cscope_option ==? 'None'
    let cscope_options = len(&cscopeprg) ? &cscopeprg : 'cscope'
  endif

  if cscope_option =~? '[\\/]'
    " Option set and includes '/' or '\': must be explicit
    " path to named executable: just pass to mktypes
    call TagHLDebug(
          \ 'CscopeExecutable set with path delimiter, using as explicit path',
          \ 'Information')
    let b:TagHighlightSettings['CscopeExeFull'] = cscope_option
  else
    " Option set but doesn't include path separator: search
    " in the path
    call TagHLDebug(
          \ 'CscopeExecutable set without path delimiter, searching in path',
          \ 'Information')
    let b:TagHighlightSettings['CscopeExeFull'] =
          \ TagHighlight#RunPythonScript#FindExeInPath(cscope_option)
  endif
endfunction
