-- A parser for prolog

module('prolog_parser', package.seeall)

local lpeg = require 'lpeg'
local utils = require 'utilities'
local bpl = require 'basic_plexer'

local P, R, S, V = 
   lpeg.P, lpeg.R, lpeg.S, lpeg.V

local C, Cb, Cc, Cg, Cs, Ct =
   lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Ct

local prolog_char_syntax_table = table.merge(bpl.char_syntax_table)
prolog_parser.char_syntax_table = prolog_char_syntax_table


-- These tables are taken from the SWI-Prolog web site.
-- Need to check with the standard that they are correct.
local unary_operators = {
   [":-"]             = { precedence = 1200, associativity = "fx" },
   ["?-"]             = { precedence = 1200, associativity = "fx" },
   dynamic            = { precedence = 1150, associativity = "fx" },
   multifile          = { precedence = 1150, associativity = "fx" },
   module_transparent = { precedence = 1150, associativity = "fx" },
   discontiguous      = { precedence = 1150, associativity = "fx" },
   volatile           = { precedence = 1150, associativity = "fx" },
   initialization     = { precedence = 1150, associativity = "fx" },
   ["\\+"]            = { precedence =  900, associativity = "fx" },
   ["~"]              = { precedence =  900, associativity = "fx" },
   ["+"]              = { precedence =  500, associativity = "fx" },
   ["-"]              = { precedence =  500, associativity = "fx" },
   ["?"]              = { precedence =  500, associativity = "fx" },
   ["\\"]             = { precedence =  500, associativity = "fx" },
}

local binary_operators = {
   ["-->"]   = { precedence = 1200, associativity = "xfx" },
   [":-"]    = { precedence = 1200, associativity = "xfx" },
   [";"]     = { precedence = 1100, associativity = "xfy", replacement = "or" },
   ["or"]    = { precedence = 1100, associativity = "xfy" },   
   ["->"]    = { precedence = 1050, associativity = "xfy" },
   [","]     = { precedence = 1000, associativity = "xfy", replacement = "and" },
   ["and"]   = { precedence = 1000, associativity = "xfy" },
   ["\\"]    = { precedence =  954, associativity = "xfy" },
   ["<"]     = { precedence =  700, associativity = "xfx" },
   ["="]     = { precedence =  700, associativity = "xfx" },
   ["=.."]   = { precedence =  700, associativity = "xfx" },
   ["=@="]   = { precedence =  700, associativity = "xfx" },
   ["=:="]   = { precedence =  700, associativity = "xfx" },
   ["=<"]    = { precedence =  700, associativity = "xfx" },
   ["=="]    = { precedence =  700, associativity = "xfx" },
   ["=\\="]  = { precedence =  700, associativity = "xfx" },
   [">"]     = { precedence =  700, associativity = "xfx" },
   [">="]    = { precedence =  700, associativity = "xfx" },
   ["@<"]    = { precedence =  700, associativity = "xfx" },
   ["@=<"]   = { precedence =  700, associativity = "xfx" },
   ["@>"]    = { precedence =  700, associativity = "xfx" },
   ["@>="]   = { precedence =  700, associativity = "xfx" },
   ["\\="]   = { precedence =  700, associativity = "xfx" },
   ["\\=="]  = { precedence =  700, associativity = "xfx" },
   ["is"]    = { precedence =  700, associativity = "xfx" },
   [":"]     = { precedence =  600, associativity = "xfy" },
   ["+"]     = { precedence =  500, associativity = "yfx" },
   ["-"]     = { precedence =  500, associativity = "yfx" },
   ["/\\"]   = { precedence =  500, associativity = "yfx" },
   ["\\/"]   = { precedence =  500, associativity = "yfx" },
   ["xor"]   = { precedence =  500, associativity = "yfx" },
   ["*"]     = { precedence =  400, associativity = "yfx" },
   ["/"]     = { precedence =  400, associativity = "yfx" },
   ["//"]    = { precedence =  400, associativity = "yfx" },
   ["<<"]    = { precedence =  400, associativity = "yfx" },
   [">>"]    = { precedence =  400, associativity = "yfx" },
   ["mod"]   = { precedence =  400, associativity = "yfx" },
   ["rem"]   = { precedence =  400, associativity = "yfx" },
   ["**"]    = { precedence =  200, associativity = "xfx" },
   ["^"]     = { precedence =  200, associativity = "xfy" },
}

local operators = { unops = unary_operators,
		    binops = binary_operators }
poem_parser.operators = operators

