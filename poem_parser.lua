-- A parser for Poem.
--
module('poem_parser', package.seeall)

local lpeg = require 'lpeg'
local utils = require 'utilities'
local bp = require 'basic_parser'

local P, R, S, V = 
   lpeg.P, lpeg.R, lpeg.S, lpeg.V

local C, Cb, Cc, Cg, Cs, Ct =
   lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Ct

-- local poem_parser = {}

local bp_cst = basic_lexer.char_syntax_table
local digit = bp_cst.digit

-- TODO: Replace this rather random collection of symbols with some
-- Unicode character class.
local poem_letter = R('az', 'AZ') + S'äöüÄÖÜßøåÅçÇ'
local poem_special_word_char = 
   S'_+-–*/~^±%&@#<>≤≥‹›=≠≈∑√∫÷?!§~¡$£€¢∞¶•·ªº°™®†‡¥π…¬˚∆˙©Ωµ'
local poem_non_word_char = S'|:;,.'
-- TODO: We should really allow any letterlike char here.
local poem_word_char =
   poem_letter + poem_special_word_char + digit
local poem_operator_start_char =
   poem_special_word_char + poem_non_word_char
local operator_char = poem_operator_start_char + bp_cst.reserved_char

local poem_char_syntax_table = {
   digit = digit;
   letter = poem_letter;

   word_start_char = word_start_char;
   word_char = poem_word_char;

   operator_start_char = poem_operator_start_char;
   operator_char = poem_operator_char;
}
poem_parser.char_syntax_table = poem_char_syntax_table

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

local function set_prolog_syntax ()
   poem_parser.parser_table =
      set_character_syntax(prolog_char_syntax_table)
   poem_parser.parser = make_parser()
end

local function set_poem_syntax ()
   poem_parser.parser_table =
      set_character_syntax(poem_char_syntax_table)
   poem_parser.parser = make_parser()
end


-- package.loaded['poem-parser'] = poem_parser
