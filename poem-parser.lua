-- A parser for Poem.
--

local lpeg = require 'lpeg'
local utils = require 'poem-utilities'

local P, R, S, V = 
   lpeg.P, lpeg.R, lpeg.S, lpeg.V

local C, Cb, Cc, Cg, Cs, Ct =
   lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Ct

local poem_parser = {}

local digit = R'09'
local special_char = S'_+-%*/$&@#^<>='
local non_word_char = special_char + S'!?;:'
local reserved_char = S'|,.'
local word_start_char = R('az')
local word_char = word_start_char + digit + special_char
local operator_start_char = special_char + non_word_char
local operator_char = operator_start_char + reserved_char

local function K (k)
  return P(k) * -word_char;
end

local function remove_full_match (t) 
   table.remove(t, 2)
   return t
end

local function make_simple_node (t)
   local result = {}
   result.type = t[1]
   result.value = t[2]
   return result
end

local function make_sequence_node (t)
   local result = {}
   result.type = t[1]
   result.elements = table.slice(t, 3)
   return result
end

local function make_modified_term_node (t)
   local result = {}
   result.type = t[1]
   result.value = t[3]
   return result
end

local function make_quoted_atom_node (t)
   local result = {}
   result.type = t[1]
   result.value = string.sub(t[2], 2, -2)
   return result
end

local function make_compound_term_node (t)
   local result = { type = "compound_term" }
   result.functor = t[3]
   result.arguments = table.slice(t, 4)
   return result
end

local function make_improper_list_node (t)
   local result = { type = "improper_list" }
   local n = #t
   result.elements = table.slice(t, 3, n-1)
   result.tail = t[n]
   return result
end

local function make_fact_node (t)
   local result = {}
   result.type = t[1]
   result.fact = t[3]
   return result
end

local function make_rule_node (t)
   local result = {}
   result.type = t[1]
   result.conclusion = t[3]
   result.premises = table.slice(t, 4)
   return result
end


local function node (id, pattern, fun)
   if fun then
      return Ct(Cc(id) * C(pattern)) / fun
   else
      return Ct(Cc(id) * C(pattern)) / make_simple_node
   end
end
poem_parser.node = node

local lexer_table = {
   digit = digit;
   special_char = special_char;
   non_word_char = non_word_char;
   reserved_char = reserved_char;
   word_start_char = word_start_char;
   word_char = word_char;
   operator_start_char = operator_start_char;
   operator_char = operator_char;

   keywords = K('forall') + K('exists');

   comment = P'--' * (P(1) - P'\n')^0 * (P'\n' + -P(1));
   ws = (S('\r\n\f\t ') + V'comment')^0;
   
   number = V'ws' * 
      node("number",
	   (P'-')^-1 * V'ws' * digit^1 * (P'.' * digit^1)^-1 *
	      (S'eE' * (P'-')^-1 * digit^1)^-1 * -word_char) *
      V'ws' +
      V'ws' *
      node("number",
	   (P'-')^-1 * V'ws' * P'.' * digit^1 *
	      (S'eE' * (P'-')^-1 * digit^1)^-1 * -word_char) *
      V'ws';
 
   string = V'ws' *
      node("string",
	   P'"' * (P'\\' * P(1) + (1 - P'"'))^0 * P'\"') *
      V'ws';

   atom_word = V'ws' *
      node("word", (word_start_char * word_char^0) - V'keywords') *
      V'ws';
   atom_operator = V'ws' *
      node("operator",
	   ((operator_start_char^1 * operator_char^0) + 
	    (reserved_char^1 * operator_char^1))) *
      V'ws';
   quoted_atom = V'ws' *
      node("quoted_atom", 
	   P'\'' * (P'\\' * P(1) + (1 - P'\''))^0 * P'\'',
	  make_quoted_atom_node) *
      V'ws';
   atom = V'atom_word' + V'atom_operator' + V'quoted_atom';
   constant = V'atom' + V'number' + V'string';

   relaxed_atom_operator = V'ws' *
      node("operator",
	   ((operator_start_char^1 * operator_char^0) + 
	    (reserved_char^1 * operator_char^0))) *
      V'ws';
   relaxed_atom = V'atom_word' + V'relaxed_atom_operator' + V'quoted_atom';
   relaxed_constant = V'relaxed_atom' + V'number' + V'string';

   command = V'ws' *
      node("command", word_start_char * word_char^0 * P('!')) *
      V'ws';
   sensing_action = V'ws' *
      node("sensing_action", word_start_char * word_char^0 * P('?')) *
      V'ws';

   named_variable = V'ws' *
      node("variable", 
	   R'AZ' * word_char^0 + P'_' * word_char^0 * word_start_char * word_char^0) *
      V'ws';
   anonymous_variable = V'ws' *
      node("anonymous_variable", P'_') *
      V'ws';
   variable = V'named_variable' + V'anonymous_variable';

   -- Should we allow relaxed atoms as functors?
   functor = V'atom' + V'command' + V'sensing_action';
}

local term_table = {
   variable_list = V'ws' *
      V'variable' * (V'ws' * P',' * V'ws' * V'variable')^0 *
      V'ws';

   simple_term = V'constant' + V'variable';
   relaxed_simple_term = V'relaxed_constant' + V'variable';

   term_list = V'ws' *
      V'term' * (V'ws' * P',' * V'ws' * V'term')^0 *
      V'ws';
   term_list_no_vbar = V'ws' *
      (V'term' - P'|') * (V'ws' * P',' * V'ws' * (V'term' - P'|'))^0 *
      V'ws';

   compound_term = node("compound_term",
			V'functor' * P'(' * V'ws' *
			   V'term_list'^-1 *
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
      node("list", V'term_list'^-1, make_sequence_node) *
      P']'* V'ws';
   list_term = V'improper_list_term' + V'proper_list_term';

   paren_term = V'ws' * P'(' * V'ws' *
      node("paren_term", V'relaxed_term', make_modified_term_node) *
      P')' * V'ws';

   complex_term = V'compound_term' + V'list_term' + V'paren_term';
   single_term = V'complex_term' + V'simple_term';
   term = node("sequence_term",
	       V'single_term'^2,
	       make_sequence_node) +
           V'single_term';

   relaxed_single_term = V'complex_term' + V'relaxed_simple_term';
   relaxed_term = node("sequence_term",
		       V'relaxed_single_term'^2,
		       make_sequence_node) +
                  V'relaxed_single_term';
   relaxed_term_no_dot = node("sequence_term",
			      (V'relaxed_single_term' - P'.')^2,
			      make_sequence_node) +
                         (V'relaxed_single_term' - P'.');
}

local program_table = {
   fact = node("fact", 
	       V'compound_term' *  P'.', 
	       make_fact_node)
      * V'ws';
   rule = node("rule", 
	       V'compound_term' * P':-' * V'relaxed_term_no_dot' * P'.', 
	       make_rule_node) *
               V'ws';
   clause = V'rule' + V'fact';
   
   program = node("program", (V'clause')^1, make_sequence_node);
}

local parser_table = table.merge(lexer_table,
				 term_table,
				 program_table,
				 {V'program'})
poem_parser.parser_table = parser_table

local parser = P(parser_table)
poem_parser.parser = parser

package.loaded['poem-parser'] = poem_parser
