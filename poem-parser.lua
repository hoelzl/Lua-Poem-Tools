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
local word_char = word_start_char + R'AZ' + digit + special_char
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
      node("atom", (word_start_char * word_char^0) - V'keywords') *
      V'ws';
   atom_operator = V'ws' *
      node("atom",
	   ((operator_start_char^1 * operator_char^0) + 
	    (reserved_char^1 * operator_char^0))) *
      V'ws';
   quoted_atom = V'ws' *
      node("atom", 
	   P'\'' * (P'\\' * P(1) + (1 - P'\''))^0 * P'\'',
	  make_quoted_atom_node) *
      V'ws';
   atom = V'atom_word' + V'atom_operator' + V'quoted_atom';
   constant = V'number' + V'atom' + V'string';

   command = V'ws' *
      node("command", word_start_char * word_char^0 * P('!')) *
      V'ws';
   sensing_action = V'ws' *
      node("sensing_action", word_start_char * word_char^0 * P('?')) *
      V'ws';

   named_variable = V'ws' *
      node("variable", 
	   R'AZ' * V'word_char'^0 + 
	      P'_' * R('az', 'AZ', '09')^1 * V'word_char'^0) *
      V'ws';
   anonymous_variable = V'ws' *
      node("anonymous_variable", P'_') *
      V'ws';
   variable = V'named_variable' + V'anonymous_variable';

   functor = V'command' + V'sensing_action' + V'atom';
}

local term_table = {
   variable_list = V'ws' *
      V'variable' * (V'ws' * P',' * V'ws' * V'variable')^0 *
      V'ws';

   simple_term =  V'variable' + V'constant';

   term_list = V'ws' *
      V'term' * (V'ws' * P',' * V'ws' * V'term')^0 *
      V'ws';
   term_list_no_vbar = V'ws' *
      V'term_no_vbar' * (V'ws' * P',' * V'ws' * V'term_no_vbar')^0 *
      V'ws';
   term_list_no_comma = V'ws' *
      V'term_no_comma' * (V'ws' * P',' * V'ws' * V'term_no_comma')^0 *
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
		       (V'single_term' - (P'|' + P','))^2,
		       make_sequence_node) +
                  (V'single_term' - (P'|' + P','));
   term_no_dot = node("sequence_term",
		      (V'single_term' - P'.')^2,
		      make_sequence_node) +
                 (V'single_term' - P'.');
}

local program_table = {
   fact = node("fact", 
	       V'compound_term' *  P'.', 
	       make_fact_node)
      * V'ws';
   rule = node("rule", 
	       V'compound_term' * P':-' * V'term_no_dot' * P'.', 
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
   [";"]     = { precedence = 1100, associativity = "xfy" },
   ["->"]    = { precedence = 1050, associativity = "xfy" },
   [","]     = { precedence = 1000, associativity = "xfy" },
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

local function is_unary_operator (op, unops)
   unops = unops or unary_operators
   return unops[op] and true
end
poem_parser.is_unary_operator = is_unary_operator

local function unop_precedence (op, unops)
   unops = unops or unary_operators
   local opspec = unops[op]
   if opspec then 
      return opspec.precedence or 0
   else
      return 0
   end
end
poem_parser.unop_precedence = unop_precedence

local function is_binary_operator (op, binops)
   binops = binops or binary_operators
   return binops[op] and true
end
poem_parser.is_binary_operator = is_binary_operator

local function binop_precedence (op, binops)
   binops = binops or binary_operators
   local opspec = binops[op]
   local result = 0
   if opspec then
      -- print("binop_precedence: found op ", op)
      result = opspec.precedence or 0
   else
      -- print("binop_precedence: didn't find op ", op)
   end
   -- print("binop_precedence: result = ", result)
   return result
end
poem_parser.binop_precedence = binop_precedence

local build_syntax_tree

-- This function takes a list of operators and build a syntax tree
-- according to the precedence and associativity specification.  The
-- algorithm is essentially a Top-Down Operator-Precedence Parser, see
-- the original paper by Vaughan Pratt or the Web site
-- http://eli.thegreenplace.net/2010/01/02/top-down-operator-precedence-parsing/
-- for a description.
local function build_operator_tree (pts, operators)
   -- pts are the parse trees in the sequence term
   -- operators is the table of operators
   
   local unops, binops = operators.unops, operators.binops
   local current_index = 1
   local token = pts[current_index]

   local lbp, expression

   local function next ()
      current_index = current_index + 1
      local result = pts[current_index]
      -- print("next: result")
      -- table.print(result)
      return result
   end
   
   local function nud (t)
      -- nud stands for "null denotation"
      -- t is a token
      local prec = 1500 - unop_precedence(t, unops)
      local argument = expression(prec)
      local result = { type = "unop",
		       operator = t.value,
		       argument = argument }
      -- print("nud: result")
      -- table.print(result)
      return result
   end

   local function led (left, t)
      -- led stands for "left denotation"
      -- left is the left parse tree
      -- t is a token
      if t then
	 local rhs = expression(lbp(t))
	 local result = { type = "binop",
			  operator = t.value,
			  lhs = left,
			  rhs = rhs }
	 -- print("led: result")
	 -- table.print(result)
	 return result
      else
	 return left
      end
   end

   function lbp (t)
      -- lbp stands for "left binding power"
      -- t is a token
      return 1500 - binop_precedence(t.value, binops)
   end

   function expression (rbp)
      -- rbp is the right binding power
      -- print("expression: rbp = ", rbp)
      local t = token
      -- print("expression: token")
      -- table.print(t)
      token = next()
      if (token) then
	 -- print("expression: lbp(token) = ", lbp(token))
      end
      local left = build_syntax_tree(t, operators)
      -- print("expression: built syntax tree")
      while token and rbp < lbp(token) do
	 t = token
	 token = next()
	 left = led(left, t)
      end
      return left
   end

   return expression(0)
end

function build_syntax_tree (pt, operators)
   -- pt is the parse_tree
   local node_type = pt.type
   local function bst (node)
      return build_syntax_tree(node, operators)
   end
   if node_type == "number" then
      return { type = "number",
	       value = tonumber(pt.value) }
   elseif node_type == "string" or node_type == "atom"
      or node_type == "command" or node_type == "sensing_action" then
      return pt
   elseif node_type == "variable" then
      return { type = "variable", name = pt.value }
   elseif node_type == "anonymous_variable" then
      return { type = "anonymous_variable" }
   elseif node_type == "compound_term" then
      return { type = "compound_term",
	       functor = pt.functor,
	       arguments = map(bst, pt.arguments) }
   -- We might expands list here, but maybe we can use list notation
   -- in the sitcalc axioms, so it's probably safer to let them be for
   -- the time being.
   elseif node_type == "improper_list" then
      return { type = "improper_list",
	       elements = map(bst, pt.elements),
	       tail = bst(pt.tail) }
   elseif node_type == "list" then
      return { type = "list",
		elements = map(bst, pt.elements) }
   elseif node_type == "paren_term" then
      local value = pt.value
      if not value then
	 error("Parenthesized term without value.")
      elseif not value.type then
	 error("Parenthesized term without value type.")
      else
	 return bst(value)
      end	  
   elseif node_type == "sequence_term" then
      return build_operator_tree(pt.elements, operators)
   elseif node_type == "fact" then
      local fact = pt.fact
      if not fact then
	 error("Empty fact?")
      elseif not fact.type then
	 error("Fact without type?")
      else
	 return { type = "fact",
		  fact = bst(fact) }
      end
   elseif node_type == "rule" then
      return { type = "rule",
	       conclusion = bst(pt.conclusion),
	       premises = map(bst, pt.premises) }
   elseif node_type == "program" then
      return { type = "program",
	       elements = map(bst, pt.elements) }
   end
   print("Failed to match node type " .. node_type)
   table.print(pt)
   error("Aborting.")
end
poem_parser.build_syntax_tree = build_syntax_tree

package.loaded['poem-parser'] = poem_parser
