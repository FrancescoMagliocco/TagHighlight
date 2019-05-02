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

if !exists('g:loaded_TagHighlight')
      \ || (exists('g:loaded_TagHLBufferEntry')
      \ && (g:plugin_development_mode != 1))
  finish
endif

let g:loaded_TagHLBufferEntry = 1

function! TagHighlight#BufferEntry#AutoSource()
  let l:searchresult = TagHighlight#Find#LocateFile('AUTOSOURCE', '')
  " COMBAK If the '== 1' just means true and it doesn't mean anything else like
  " the amount, the '== 1' can be taken out.
  if l:searchresult['Found'] == 1 && l:searchresult['Exists'] == 1
    exe 'source' l:searchresult['FullPath']
  endif
endfunction

" XXX Is a:filename not being used?...
function! TagHighlight#BufferEntry#BufEnter(filename)
  if !exists('b:TagHighlightPrivate')
    let b:TagHighlightPrivate = {}
  endif

  if !has_key(b:TagHighlightPrivate, 'ReadTypesCompleted')
    " In case it hasn't already been run, run the extension
    " checker.
    call TagHighlight#ReadTypes#ReadTypesByExtension()
  endif

  " No point in using the extra cpu cyles to check for the optoin if it's not
  " supported.
  if has('cscope')
    if TagHighlight#Option#GetOption('EnableCscope')
      call TagHighlight#Cscope#BufEnter()
    endif
  endif

  if TagHighlight#Option#GetOption('AutoSource')
    call TagHighlight#BufferEntry#AutoSource()
  endif

  call TagHighlight#BufferEntry#SetupVars()

  let b:TagHighlightPrivate['BufEnterInitialised'] = 1
endfunction

" XXX Is a:filename not being used?...
function! TagHighlight#BufferEntry#BufLeave(filename)
  if !exists('b:TagHighlightPrivate')
    let b:TagHighlightPrivate = {}
  endif

  if has('cscope')
    if TagHighlight#Option#GetOption('EnableCscope')
      call TagHighlight#Cscope#BufLeave()
    endif
  endif

  call TagHighlight#BufferEntry#ResetVars()

  let b:TagHighlightPrivate['BufLeaveInitialised'] = 1
endfunction

function! TagHighlight#BufferEntry#SetupVars()
  let l:custom_globals  = TagHighlight#Option#GetOption('CustomGlobals')
  let l:custom_settings = TagHighlight#Option#GetOption('CustomSettings')

  let l:custom_vars = {}
  for l:var in keys(l:custom_globals)
    let l:custom_vars['g:' . l:var] = l:custom_globals[l:var]
  endfor

  for l:var in keys(l:custom_settings)
    let l:custom_vars['&' . l:var] = l:custom_settings[l:var]
  endfor

  let s:saved_state = {}
  for l:var in keys(l:custom_vars)
    let s:saved_state[l:var] = exists(l:var) ? eval(l:var) : 'DOES NOT EXISTS'
    exe 'let' l:var '= custom_vars[var]'
  endfor
endfunction

function! TagHighlight#BufferEntry#ResetVars()
  if !exists('s:saved_state')
    return
  endif

  for l:var in keys(s:saved_state)
    " The '==?' means case doesn't matter
    execute s:saved_state[l:var] ==? 'DOES NOT EXIST'
          \ ? 'unlet ' . l:var
          \ : 'let ' . l:var . ' = s:saved_state[var]'
  endfor
endfunction
