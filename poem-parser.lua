-- A parser for Poem.
--

local lpeg = require 'lpeg'
local utils = require 'poem-utilities'

local P, R, S, V = 
   lpeg.P, lpeg.R, lpeg.S, lpeg.V

local C, Cb, Cc, Cg, Cs, Ct =
   lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Ct

local poem_parser = {}

local function node (id, pattern, fun)
   if fun then
      return Ct(Cc(id) * C(pattern)) / fun
   else
      return Ct(Cc(id) * C(pattern))
   end
end
poem_parser.node = node

local digit = R'09'
local special_char = S'_+-%*/$&@#^<>=|'
local operator_char = special_char + S'!?,;.:'
local word_char = R('AZ', 'az') + digit + special_char

local function K (k)
  return P(k) * -word_char;
end

local function remove_full_match (t) 
   table.remove(t, 2)
   return t
end

local function make_compound_term (t)
   local result = { type = "compound_term" }
   result.functor = t[3]
   result.arguments = table.slice(t, 4)
   return result
end

local function make_proper_list_term (t)
   local result = { type = "list" }
   result.elements = table.slice(t, 3)
   return result
end

local function make_improper_list_term (t)
   local result = { type = "improper_list" }
   local n = #t
   result.elements = table.slice(t, 3, n-1)
   result.tail = t[n]
   return result
end

local lexer_table = {
   digit = digit;
   special_char = special_char;
   operator_char = operator_char;
   word_char = word_char;
   
   keywords = K('not') + K('and') + K('or') + K('forall') + K('exists');

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
      node("atom", (R'az' * word_char^0 * -S'!?') - V'keywords') *
      V'ws';
   atom_sign = V'ws' *
      node("atom", operator_char^1) *
      V'ws';
   quoted_atom = V'ws' *
      node("atom", P'\'' * (P'\\' * P(1) + (1 - P'\''))^0 * P'\'') *
      V'ws';
   atom = V'atom_word' + V'atom_sign' + V'quoted_atom';
   constant = V'atom' + V'number' + V'string';

   command = V'ws' *
      node("command", R'az' * word_char^0 * P('!')) *
      V'ws';
   sensing_action = V'ws' *
      node("sensing_action", R'az' * word_char^0 * P('?')) *
      V'ws';

   named_variable = V'ws' *
      node("variable", R'AZ' * word_char^0 + P'_' * word_char^1) *
      V'ws';
   anonymous_variable = V'ws' *
      node("anonymous_variable", P'_') *
      V'ws';
   variable = V'named_variable' + V'anonymous_variable';

   functor = V'atom' + V'command' + V'sensing_action';
}

local term_table = {
   variable_list = V'ws' *
      V'variable' * (V'ws' * P',' * V'ws' * V'variable')^0 *
      V'ws';

   simple_term = V'constant' + V'variable';

   term_list = V'ws' *
      V'term' * (V'ws' * P',' * V'ws' * V'term')^0 *
      V'ws';
   strict_term_list = V'ws' *
      V'strict_term' * (V'ws' * P',' * V'ws' * V'strict_term')^0 *
      V'ws';

   non_binop = V'ws' * (P'.' + P':-') * V'ws';
   binop = V'ws' * 
      (((V'operator_char' + V'special_char')^1 - V'non_binop') + K'and' + K'or') *
      V'ws';
   binop_term_rest = V'ws' *
      (node("binop", V'binop') * V'ws' * V'start_term' *V'ws') *
      V'ws';
   binop_term_list = V'binop_term_rest'^1 * -V'binop_term_rest';

   strict_non_binop = V'ws' * (P'.' + P':-' + P'|' + P',') * V'ws';
   strict_binop = V'ws' * 
      (((V'operator_char' + V'special_char')^1 - V'strict_non_binop') + K'and' + K'or') *
      V'ws';
   strict_binop_term_rest = V'ws' *
      (node("binop", V'strict_binop') * V'ws' * V'start_term' *V'ws') *
      V'ws';
   strict_binop_term_list = V'strict_binop_term_rest'^1 * -V'strict_binop_term_rest';

   compound_term = node("compound_term",
			V'functor' * P'(' * V'ws' *
			   V'term_list'^-1 *
			   V'ws' * P')',
		       make_compound_term) *
                   V'ws';
   compound_term_list = V'compound_term' *
      (V'ws' * node("binop", V'binop') * V'ws' * V'compound_term')^0 *
      V'ws';

   improper_list_term = V'ws' * P'[' * 
      node("improper_list_term", 
	   V'strict_term_list'^-1 * 
	      V'ws' * P'|' * V'ws' * V'term',
	   make_improper_list_term) *
	      V'ws' * P']' * V'ws';
   proper_list_term = V'ws' * P'[' * 
      node("proper_list_term", V'strict_term_list'^-1, make_proper_list_term) *
      P']'* V'ws';
   list_term = V'improper_list_term' + V'proper_list_term';
   paren_term = V'ws' * P'(' * V'ws' *
      node("paren_term", V'term', remove_full_match) *
      P')' * V'ws';

   start_term = V'compound_term' + V'list_term' + V'paren_term' + V'simple_term';
   term = node("binop_sequence", V'start_term' * V'binop_term_list', remove_full_match) +
      V'start_term';
   strict_term = node("binop_sequence", V'start_term' * V'strict_binop_term_list', remove_full_match) +
      V'start_term';
}

local program_table = {

   fact = node("fact", 
	       V'compound_term' *  P'.', 
	       function (t) table.remove(t, 2); return t end)
      * V'ws';
   rule = node("rule", 
	       V'compound_term' * P':-' * V'compound_term_list' * P'.', 
	       remove_full_match) *
               V'ws';
   clause = V'rule' + V'fact';
   
   program = node("program", (V'clause')^1, remove_full_match);
}

local parser_table = table.merge(lexer_table,
				 term_table,
				 program_table,
				 {V'program'})
poem_parser.parser_table = parser_table

local function simplify_parse_tree(tab) 
   if type(tab) ~= "table" or not next(tab) then
      return tab
   else
      local kind = tab[1]
      -- print("kind = ", kind)
      if kind == "compound_term" then
	 table.remove(tab, 2)
	 table.remove(tab, 3)
      elseif  kind == "improper_list_term" or kind == "proper_list_term" then
	 table.remove(tab, 2)
      elseif kind == "paren_term" then
	 table.remove(tab, 2)
      end
      for _,v in ipairs(tab) do
	 simplify_parse_tree(v)
      end
   end
   return tab
end
poem_parser.simplify_parse_tree = simplify_parse_tree

local parser = P(parser_table)
poem_parser.parser = parser

package.loaded['poem-parser'] = poem_parser
