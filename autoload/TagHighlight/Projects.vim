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
if !exists('g:loaded_TagHighlight') || (exists('g:loaded_TagHLProjects')
      \ && (g:plugin_development_mode != 1))
  finish
endif

let g:loaded_TagHLProjects = 1

function! TagHighlight#Projects#GetProjects()
  let projects = TagHighlight#Option#GetOption('Projects')
  call TagHLDebug('Projects option set to ' . string(projects), 'Information')
  for project in keys(projects)
    if type(projects[project]) == v:t_string
      let projects[project] = {'SourceDir': projects[project]}
      continue
"    elseif type(projects[project]) == v:t_dict
"          \ &&  has_key(projects[project], 'SourceDir')
      " Okay
"    else
    endif
    
    call TagHLDebug(
          \ "Invalid entry '" . project . "' in Projects list (no SourceDir)",
          \ 'Warning')
    call remove(projects, project)
"    endif
  endfor

  return projects
endfunction

function! TagHighlight#Projects#IsProject(name)
  return has_key(TagHighlight#Projects#GetProjects(), a:name)
endfunction

function! TagHighlight#Projects#GetProject(name)
  return TagHighlight#Projects#GetProjects()[a:name]
endfunction

function! TagHighlight#Projects#LoadProjectOptions(file)
  call TagHLDebug('Looking for project options for ' . a:file, 'Information')
  let full_path = fnamemodify(a:file, ':p')
  let projects = TagHighlight#Projects#GetProjects()
  if !exists('b:TagHighlightSettings')
    let b:TagHighlightSettings = {}
  endif

  if !exists('b:TagHighlightPrivate')
    let b:TagHighlightPrivate = {}
  endif

  let b:TagHighlightPrivate['InProject'] = 0
  for name in keys(projects)
    let project = projects[name]
    if !TagHighlight#Utilities#FileIsIn(full_path, project['SourceDir'])
      continue
    endif

    call TagHLDebug("Found project: '" . name . "'", 'Information')
    let b:TagHighlightSettings = extend(b:TagHighlightSettings, project)
    let b:TagHighlightPrivate['InProject']    = 1
    let b:TagHighlightPrivate['ProjectName']  = name
    break
  endfor

  if b:TagHighlightPrivate['InProject']
    return
  endif

  call TagHLDebug("Not in project: '" . a:file . "'", 'Information')
  let b:TagHighlightSettings = extend(
        \ b:TagHighlightSettings,
        \ TagHighlight#Option#GetOption('NonProjectOptions'))
endfunction
