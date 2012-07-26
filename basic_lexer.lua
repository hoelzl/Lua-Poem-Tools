-- The basic lexer.
--
module('basic_lexer', package.seeall)

local lpeg = require 'lpeg'
local utils = require 'utilities'

local P, R, S, V = 
   lpeg.P, lpeg.R, lpeg.S, lpeg.V

local C, Cb, Cc, Cg, Cp, Cs, Ct =
   lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cp, lpeg.Cs, lpeg.Ct

local digit = R'09'
local word_start_char = R('az')
local reserved_char = S'\\\''

local basic_letter = R('az', 'AZ')
local basic_special_word_char = S'_'
local basic_non_word_char = 
   S'+-*/\\~^<>:;,.?@#$&=%!|'
local basic_word_char = 
   basic_letter + basic_special_word_char + digit
local basic_operator_start_char =
   basic_special_word_char + basic_non_word_char
local basic_operator_char =
   basic_operator_start_char + reserved_char

local basic_char_syntax_table = {
   digit = digit;
   letter = basic_letter;
   reserved_char = reserved_char;

   word_start_char = word_start_char;
   word_char = basic_word_char;

   operator_start_char = basic_operator_start_char;
   operator_char = basic_operator_char;
}
basic_lexer.char_syntax_table = basic_char_syntax_table

local function make_simple_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.name = t[3]
   return result
end

local function make_string_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2] - 1
   result.name = t[3]
   return result
end

local function make_quoted_atom_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2] - 1
   -- FIXME: We need to process control characters in the value
   result.name = t[3]
   return result
end

local function make_result_list (t)
   return utils.slice(t, 4)
end

local function node (id, pattern, fun)
   fun = fun or make_simple_node
   local function fun_with_mt (t)
      local result = fun(t)
      return utils.set_node_metatable(result)
   end
   return (Ct(Cc(id) * Cp() * C(pattern))) / fun_with_mt
end
basic_lexer.node = node

local lexer_table = {
   any_char_but_newline = P(1) - P'\n';
   newline_or_eof = P'\n' + -P(1);
   -- TODO: Keep a line count for error messages
   comment = P'--' * V'any_char_but_newline'^0 * V'newline_or_eof';
   ws = (S('\r\n\f\t ') + V'comment')^0;
   
   number = V'ws' * 
      node("number",
	   (P'-')^-1 * V'ws' * digit^1 * (P'.' * digit^1)^-1 *
	      (S'eE' * (P'-')^-1 * digit^1)^-1) *
      V'ws' +
      V'ws' *
      node("number",
	   (P'-')^-1 * V'ws' * P'.' * digit^1 *
	      (S'eE' * (P'-')^-1 * digit^1)^-1) *
      V'ws';
 
   string = V'ws' * P'"' *
      node("string",
	   (P'\\' * P(1) + (1 - P'"'))^0,
	  make_string_node) *
      P'\"' * V'ws';

   atom_word = V'ws' *
      node("atom",
	   V'word_start_char' * V'word_char'^0,
	  make_simple_node) *
      V'ws';
   atom_operator = V'ws' *
      node("atom",
	   V'operator_start_char' * V'operator_char'^0,
	  make_simple_node) *
      V'ws';
   atom_paren = V'ws' * 
      node("atom", S'()[]{}', make_simple_node) * 
      V'ws';
   quoted_atom = V'ws' * P'\'' *
      node("atom", 
	   (P'\\' * P(1) + (1 - P'\''))^0,
	  make_quoted_atom_node) *
      P'\'' * V'ws';
   atom = V'atom_word' + 
      V'atom_paren' +
      P'\\' * V'atom_operator' + 
      P'(' * V'atom_operator' * P')' + 
      V'atom_operator' +
      V'quoted_atom';

   constant = V'number' + V'atom' + V'string';

   named_variable = V'ws' *
      node("variable", 
	   R'AZ' * V'word_char'^0 + 
	      P'_' * R('az', 'AZ', '09')^1 * V'word_char'^0) *
      V'ws';
   anonymous_variable = V'ws' *
      node("anonymous_variable", P'_') *
      V'ws';
   variable = V'named_variable' + V'anonymous_variable';

   term =  V'variable' + V'constant';

   term_list = node('term-list',
		    (V'ws' * V'term' * V'ws')^0,
		   make_result_list)
}

local lexer_table = utils.merge(basic_char_syntax_table,
				 lexer_table,
				 {V'term_list'})
basic_lexer.lexer_table = lexer_table

local function merge_character_syntax (char_syntax_table, lexer_table)
   lexer_table = lexer_table or basic_lexer.lexer_table
   return char_syntax_table and utils.merge(lexer_table, char_syntax_table) or
      lexer_table
end
basic_lexer.merge_character_syntax = merge_character_syntax

local function make_lexer (initial_rule, char_syntax_table, lexer_table)
   lexer_table = lexer_table or basic_lexer.lexer_table
   lexer_table = merge_character_syntax(char_syntax_table, lexer_table)
   if initial_rule then
      lexer_table[1] = V(initial_rule)
   end
   return P(lexer_table)
end
basic_lexer.make_lexer = make_lexer

basic_lexer.lexer = make_lexer()
