" Tag Highlighter:
"   Author:  A. S. Budden <abudden _at_ gmail _dot_ com>
" Copyright: Copyright (C) 2009-2013 A. S. Budden
"            Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            the TagHighlight plugin is provided *as is* and comes with no
"            warranty of any kind, either expressed or implied. By using
"            this plugin, you agree that in no event will the copyright
"            holder be liable for any damages resulting from the use
"            of this software.

" ---------------------------------------------------------------------

" To use the v:t_* variables
if v:version < 800
  finish
endif

if &cp || (exists('g:loaded_TagHighlight') && (g:plugin_development_mode != 1))
  finish
endif

let g:loaded_TagHighlight = 1

" Lets only do the TagHLDebug calls if Debug is on.
let g:TagHighlight_Debug = get(g:, 'TagHighlight_Debug', 0)

" Any len that is non-zero will make true
if len(globpath(&rtp, 'plugin/ctags_highlighting.vim'))
  echoerr 'Legacy ctags highlighter found.  This highlighter is'
        \ 'intended to replace ctags_highlighter.  See the'
        \ 'user documentation in doc/TagHighlight.txt for'
        \ 'more information.'
  finish
endif

if !exists('g:TagHighlightSettings')
  let g:TagHighlightSettings = {}
endif

let g:TagHighlightPrivate = {}

let s:plugin_paths = split(
      \ globpath(&rtp, 'plugin/TagHighlight/TagHighlight.py'), '\n')

if len(s:plugin_paths) == 1
  let g:TagHighlightPrivate['PluginPath'] =
        \ fnamemodify(s:plugin_paths[0], ':p:h')
elseif !len(s:plugin_paths)
  echoerr 'Cannot find TagHighlight.py'
else
  echoerr 'Multiple plugin installs found: something has gone wrong!'
endif

" Update types & tags
command! -bar UpdateTypesFile
      \ silent call TagHighlight#Generation#UpdateAndRead(0)

command! -bar UpdateTypesFileOnly
      \ silent call TagHighlight#Generation#UpdateAndRead(1)

if g:TagHighlight_Debug
  command! -nargs=1 -bang UpdateTypesFileDebug
        \ call TagHighlight#Debug#DebugUpdateTypesFile(<bang>0, <f-args>)
endif

function! s:LoadLanguages()
  " This loads the language data files.
  let g:TagHighlightPrivate['ExtensionLookup']        = {}
  let g:TagHighlightPrivate['FileTypeLookup']         = {}
  let g:TagHighlightPrivate['SyntaxLookup']           = {}
  let g:TagHighlightPrivate['SpecialSyntaxHandlers']  = {}
  " Hopefully the order doesn't matter and the split(glob(.. HAS to be done
  " before initializing some of the entries..
  for l:language_file in split(glob(
        \ g:TagHighlightPrivate['PluginPath'] . '/data/languages/*.txt'), '\n')
    let l:entries = TagHighlight#LoadDataFile#LoadFile(l:language_file)
    if has_key(l:entries, 'Suffix')
          \ && has_key(l:entries, 'VimExtensionMatcher') 
          \ && has_key(l:entries, 'VimFileTypes')
          \ && has_key(l:entries, 'VimSyntaxes')
      let l:Suffix = l:entries['Suffix']
      let g:TagHighlightPrivate['ExtensionLookup'][l:entries[
            \ 'VimExtensionMatcher']] = l:Suffix

      let l:VimFts = l:entries['VimFileTypes']
      let g:TagHighlightPrivate['FileTypeLookup'][type(l:VimFts) == v:t_list
            \ ? join(l:VimFts, ',')
            \ : l:VimFts] = l:Suffix

      let l:VimSyntaxes = l:entries['VimSyntaxes']
      let g:TagHighlightPrivate['SyntaxLookup'][type(l:VimSyntaxes) == v:t_list
            \ ? join(l:VimSyntaxes, ',')
            \ : l:VimSyntaxes] = l:Suffix
    else
      echoerr 'Could not load language from file' l:language_file
    endif

    if has_key(l:entries, 'SpecialSyntaxHandlers')
      let l:SpecialSyntaxHandlers = l:entries['SpecialSyntaxHandlers']
      let g:TagHighlightPrivate['SpecialSyntaxHandlers'][l:Suffix] =
            \ type(l:SpecialSyntaxHandlers) == v:t_list
            \   ? l:SpecialSyntaxHandlers
            \   : [l:SpecialSyntaxHandlers]
    endif
  endfor
endfunction

function! s:LoadKinds()
  " Load the list of kinds (ignoring ctags information) into
  " Vim.  This is used to make the default links
  let g:TagHighlightPrivate['Kinds'] =
        \ TagHighlight#LoadDataFile#LoadDataFile('kinds.txt')
  " Use a dictionary to get all unique entries
  let l:tag_names_dict = {}
  let l:Kinds = g:TagHighlightPrivate['Kinds']
  for l:entry in keys(l:Kinds)
    for l:key in keys(l:Kinds[l:entry])
      let l:tag_names_dict[l:Kinds[l:entry][l:key]] = ''
    endfor
  endfor

  let g:TagHighlightPrivate['AllTypes'] = sort(keys(l:tag_names_dict))
endfunction

function! TagHLDebug(str, level)
  if !g:TagHighlight_Debug | return | endif
  if TagHighlight#Debug#DebugLevelIncludes(a:level)
    try
      let l:debug_file = TagHighlight#Option#GetOption('DebugFile')
      let l:print_time = TagHighlight#Option#GetOption('DebugPrintTime')
    catch /Unrecognised option/
      " Probably haven't loaded the option definitions
      " yet, so assume no debug log file
      let l:debug_file = 0
    endtry

    if !l:debug_file
      echomsg a:str
    else
      exe 'redir >>' l:debug_file
      silent echo l:print_time && exists('*strftime')
            \ ? strftime('%H.%M.%S') . ': ' . a:str
            \ : a:str
      redir END
    endif
  endif
endfunction

function s:LoadTagHLConfig(filename, report_error)
  if filereadable(a:filename)
    let g:TagHighlightSettings = extend(
          \ g:TagHighlightSettings,
          \ TagHighlight#LoadDataFile#LoadFile(a:filename))
  elseif a:report_error
    echoerr 'Cannot read config file ' . a:filename
  endif
endfunction

call s:LoadLanguages()
call s:LoadKinds()

for s:f in split(globpath(&rtp, 'TagHLConfig.txt'), '\n')
  call s:LoadTagHLConfig(s:f, 0)
endfor

command! -nargs=1 -complete=file LoadTagHLConfig
      \ call s:LoadTagHLConfig(<q-args>, 1)

for s:tagname in g:TagHighlightPrivate['AllTypes']
  let s:simplename = substitute(s:tagname, '^CTags', '', '')
  exe 'hi default link' s:tagname s:simplename
  " Highlight everything as a keyword by default
  exe 'hi default link' s:simplename 'Keyword'
endfor

if !has_key(g:TagHighlightPrivate, 'AutoCommandsLoaded')
  let g:TagHighlightPrivate['AutoCommandsLoaded'] = 1
  augroup TagHighlight
    autocmd!
    autocmd BufRead,BufNewFile *
          \ call TagHighlight#ReadTypes#ReadTypesByExtension()
    autocmd Syntax * call TagHighlight#ReadTypes#ReadTypesBySyntax()
    autocmd FileType * call TagHighlight#ReadTypes#ReadTypesByFileType()
    autocmd BufEnter *
          \ call TagHighlight#BufferEntry#BufEnter(expand("<afile>:p"))
    autocmd BufLeave *
          \ call TagHighlight#BufferEntry#BufLeave(expand("<afile>:p"))
  augroup END
endif
command! ReadTypes call TagHighlight#ReadTypes#ReadTypesByOption()
