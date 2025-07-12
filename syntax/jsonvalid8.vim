" Vim syntax file for jsonvalid8.nvim schema definitions

if exists("b:current_syntax")
  finish
endif

syntax keyword jsonvalid8Type string integer number boolean object array enum
syntax match   jsonvalid8Constraint /\w\+=[^,)]\+/
syntax match   jsonvalid8Enum /enum\[[^\]]*\]/
syntax match   jsonvalid8Comment /^\s*#.*$/

highlight def link jsonvalid8Type Type
highlight def link jsonvalid8Constraint Identifier
highlight def link jsonvalid8Enum Constant
highlight def link jsonvalid8Comment Comment

let b:current_syntax = "jsonvalid8"
