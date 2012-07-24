-- The basic parser.
--
-- This parser exects a stream of tokens and terms and turns it into a
-- syntax tree.
--
module('basic_parser', package.seeall)

-- These tables are taken from the SWI-Prolog web site.
-- Need to check with the standard that they are correct.
local unary_operators = {
   ["?-"]             = { precedence = 1200, associativity = "fx" },
   ["~"]              = { precedence =  900, associativity = "fx" },
   ["+"]              = { precedence =  500, associativity = "fx" },
   ["-"]              = { precedence =  500, associativity = "fx" },
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
   ["=<"]    = { precedence =  700, associativity = "xfx" },
   [">"]     = { precedence =  700, associativity = "xfx" },
   [">="]    = { precedence =  700, associativity = "xfx" },
   ["\\="]   = { precedence =  700, associativity = "xfx" },
   ["is"]    = { precedence =  700, associativity = "xfx" },
   [":"]     = { precedence =  600, associativity = "xfy" },
   ["+"]     = { precedence =  500, associativity = "yfx" },
   ["-"]     = { precedence =  500, associativity = "yfx" },
   ["xor"]   = { precedence =  500, associativity = "yfx" },
   ["*"]     = { precedence =  400, associativity = "yfx" },
   ["/"]     = { precedence =  400, associativity = "yfx" },
   ["mod"]   = { precedence =  400, associativity = "yfx" },
   ["rem"]   = { precedence =  400, associativity = "yfx" },
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

local function binop_replacement (op, binops)
   binops = binops or binary_operators
   local opspec = binops[op]
   local result = op
   if opspec then
      result = opspec.replacement or op
   end
   return result
end
poem_parser.binop_replacement = binop_replacement

-- Forward declaration
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
			  operator = binop_replacement(t.value, binops),
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
      -- print("expression: t")
      -- table.print(t)
      token = next()
      -- if (token) then
      -- 	 print("expression: token")
      -- 	 table.print(token)
      -- 	 print("expression: lbp(token) = ", lbp(token))
      -- end
      local left = build_syntax_tree(t, operators)
      -- print("expression: built syntax tree:")
      -- table.print(left)
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
   local function mt (node)
      return set_node_metatable(node)
   end
   if node_type == "number" then
      return mt { type = "number",
		  value = tonumber(pt.value) }
   elseif node_type == "string" or node_type == "atom" then
      return pt
   elseif node_type == "variable" then
      return mt { type = "variable", name = pt.value }
   elseif node_type == "anonymous_variable" then
      return mt { type = "anonymous_variable" }
   elseif node_type == "compound_term" then
      return mt { type = "compound_term",
		  functor = pt.functor,
		  arguments = map(bst, pt.arguments) }
   -- We might expands list here, but maybe we can use list notation
   -- in the sitcalc axioms, so it's probably safer to let them be for
   -- the time being.
   elseif node_type == "improper_list" then
      return mt { type = "improper_list",
		  elements = map(bst, pt.elements),
		  tail = bst(pt.tail) }
   elseif node_type == "list" then
      return mt { type = "list",
		  elements = map(bst, pt.elements) }
   elseif node_type == "paren_term" then
      local value = pt.value
      if not value then
	 error("Parenthesized term without value.")
      elseif not value.type then
	 error("Parenthesized term without value type.")
      else
	 return mt(bst(value))
      end	  
   elseif node_type == "sequence_term" then
      return mt(build_operator_tree(pt.elements, operators))
   elseif node_type == "clause" then
      return mt { type = "clause",
		  conclusion = bst(pt.conclusion),
		  premise = map(bst, pt.premises)[1] }
   elseif node_type == "program" then
      return mt { type = "program",
		  elements = map(bst, pt.elements) }
   end
   print("Failed to match node type " .. node_type)
   table.print(pt)
   error("Aborting.")
end
poem_parser.build_syntax_tree = build_syntax_tree

