-- The basic parsing lexer.
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


local node_metatable = {
   __tostring = function (t)
      return utils.table_tostring(t, 15)
   end,
   __eq = utils.equal
}

local function set_node_metatable (node)
   if (type(node) == "table") then
      setmetatable(node, node_metatable)
   else
      error(tostring(node) .. " is not a table.")
   end
   return node
end
basic_lexer.set_node_metatable = set_node_metatable

local function set_node_metatable_recursively (node)
   if (type(node) == "table") then
      setmetatable(node, node_metatable)
      for _, n in pairs(node) do
	 set_node_metatable_recursively(n)
      end
   end
   return node
end
basic_lexer.set_node_metatable_recursively = set_node_metatable_recursively

local function make_simple_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.name = t[3]
   return result
end

local function make_sequence_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.elements = utils.slice(t, 4)
   return result
end

local function make_modified_term_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.value = t[4]
   return result
end

local function make_simple_atom_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.name = t[3]
   return result
end

local function make_quoted_atom_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   -- FIXME: We need to process control characters in the value
   result.name = string.sub(t[3], 2, -2)
   return result
end

local function make_compound_term_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.functor = t[4]
   result.arguments = utils.slice(t, 5)
   return result
end

local function make_improper_list_node (t)
   local result = { type = "improper_list" }
   result.pos = t[2]
   local n = #t
   result.elements = utils.slice(t, 4, n-1)
   result.tail = t[n]
   return result
end

local function make_fact_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.conclusion = t[4]
   result.premises = {}
   return result
end

local function make_rule_node (t)
   local result = {}
   result.type = t[1]
   result.pos = t[2]
   result.conclusion = t[4]
   result.premises = utils.slice(t, 5)
   return result
end

local function node (id, pattern, fun)
   fun = fun or make_simple_node
   local function fun_with_mt (t)
      local result = fun(t)
      return set_node_metatable(result)
   end
   return (Ct(Cc(id) * Cp() * C(pattern))) / fun_with_mt
end
basic_lexer.node = node

local lexer_table = {
   any_char_but_newline = P(1) - P'\n';
   newline_or_eof = P'\n' + -P(1);
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
 
   string = V'ws' *
      node("string",
	   P'"' * (P'\\' * P(1) + (1 - P'"'))^0 * P'\"') *
      V'ws';

   atom_word = V'ws' *
      node("atom",
	   V'word_start_char' * V'word_char'^0,
	  make_simple_atom_node) *
      V'ws';
   atom_operator = V'ws' *
      node("atom",
	   V'operator_start_char'^1 * V'operator_char'^0,
	  make_simple_atom_node) *
      V'ws';
   quoted_atom = V'ws' *
      node("atom", 
	   P'\'' * (P'\\' * P(1) + (1 - P'\''))^0 * P'\'',
	  make_quoted_atom_node) *
      V'ws';
   -- escaped_atom = V'atom_word' + 
   --    P'\\' * V'atom_operator' + 
   --    P'(' * V'atom_operator' * P')' + 
   --    V'quoted_atom';
   -- atom = V'escaped_atom' + V'atom_operator';
   atom = V'atom_word' + 
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

   -- functor = V'escaped_atom';
   functor = V'atom';
}

local term_table = {
   variable_list = V'ws' *
      V'variable' * (V'ws' * P',' * V'ws' * V'variable')^0 *
      V'ws';

   simple_term =  V'variable' + V'constant';

   -- term_list = V'ws' *
   --    node("term_list",
   -- 	   V'term' * (V'ws' * V'term')^0,
   -- 	   make_sequence_node) *
   --    V'ws';
   term_list_no_comma = V'ws' *
      V'term_no_comma' * (V'ws' * P',' * V'ws' * V'term_no_comma')^0 *
      V'ws';
   term_list_no_vbar = V'ws' *
      V'term_no_vbar' * (V'ws' * P',' * V'ws' * V'term_no_vbar')^0 *
      V'ws';

   compound_term = node("compound_term",
			V'functor' * P'(' * V'ws' *
			   V'term_list_no_comma'^-1 *
			   V'ws' * P')',
		       make_compound_term_node) *
                   V'ws';

   improper_list_term = V'ws' * P'[' * 
      node("improper_list", 
	   V'term_list_no_vbar'^-1 * 
	      V'ws' * P'|' * V'ws' * V'term',
	   make_improper_list_node) *
	      V'ws' * P']' * V'ws';
   proper_list_term = V'ws' * P'[' * 
      node("list", V'term_list_no_vbar'^-1, make_sequence_node) *
      P']'* V'ws';
   list_term = V'improper_list_term' + V'proper_list_term';

   paren_term = V'ws' * P'(' * V'ws' *
      node("paren_term", V'term', make_modified_term_node) *
      P')' * V'ws';

   complex_term = V'compound_term' + V'list_term' + V'paren_term';
   single_term =  V'complex_term' + V'simple_term';
   term = node("sequence_term",
	       V'single_term'^2,
	       make_sequence_node) +
           V'single_term';
   term_no_comma = node("sequence_term",
			(V'single_term' - P',')^2,
			make_sequence_node) +
                   (V'single_term' - P',');
   term_no_vbar = node("sequence_term",
		       (V'single_term' - S'|,')^2,
		       make_sequence_node) +
                  (V'single_term' - S'|,');
   term_no_dot = node("sequence_term",
		      (V'single_term' - P'.')^2,
		      make_sequence_node) +
                 (V'single_term' - P'.');
}

local program_table = {
   fact = node("clause", 
	       V'compound_term' *  P'.', 
	       make_fact_node)
      * V'ws';
   rule = node("clause", 
	       V'compound_term' * P':-' * V'term_no_dot' * P'.', 
	       make_rule_node) *
               V'ws';
   clause = V'rule' + V'fact';
   
   program = node("program", (V'clause')^1, make_sequence_node);
}

local lexer_table = utils.merge(basic_char_syntax_table,
				 lexer_table,
				 term_table,
				 -- program_table,
				 {V'term'})
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
      lexer_table[0] = V(initial_rule)
   end
   return P(lexer_table)
end
basic_lexer.make_lexer = make_lexer

basic_lexer.lexer = make_lexer()
