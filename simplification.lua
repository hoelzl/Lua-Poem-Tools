-- Simplification of clauses
--
local utils = require 'utilities'

local assert, ipairs, error, print, pairs, tostring, type = 
   assert, ipairs, error, print, pairs, tostring, type
local _G, io, table, string = _G, io, table, string

local table_tostring, print_table = 
   utils.table_tostring, utils.print_table

module('simplification')

local simp = _G.simplification

-- Returns the outermost operator or functor of a term.
local function main_operator (term)
   if term.op == 'compound-term' then 
      return term.functor.name, 'functor'
   else 
      return term.op, 'operator'
   end
end
simp.main_operator = main_operator

-- Returns true if 'term' is a variable
local function is_variable (term)
   return term.type == 'variable'
end
simp.is_variable = is_variable

-- Returns true if 'term' is a clause.  Currently only a very rough
-- approximation.
local function is_clause (term)
   local op, kind = main_operator(term)
   return kind == 'functor' or op == ':-'
end
simp.is_clause = is_clause

local function true_value ()
   return {type = 'atom', pos = 1, name = 'true'}
end
simp.true_value = true_value

local function is_true_value (term)
   return type(term) == 'table' and 
      term.type == 'atom' and 
      term.name == 'true'
end
simp.is_true_value = is_true_value

local variable_counter = 0
local function make_variable ()
   variable_counter = variable_counter + 1
   return { type = 'variable',
	    -- Ensure that the name is unique
	    name = { "_Var_" .. variable_counter }}
end
simp.make_variable = make_variable

local function make_clause (head, body)
   return { op = ':-',
	    lhs = head,
	    rhs = body }
end
simp.make_clause = make_clause

local function make_unification (var, term)
   return { op = '=',
	    lhs = var,
	    rhs = term }
end
simp.make_unification = make_unification

local function variable_equal (var1, var2)
   return var1 == var2 or
      (var1.type == 'variable' and var2.type == 'variable' and
       var1.name == var2.name)
end
simp.variable_equal = variable_equal

local function conjoin (lhs, rhs)
   -- We pick off the easy simplification that might be useful when
   -- modifying a term that was artificially split.
   if is_true_value(lhs) then
      return rhs
   elseif is_true_value(rhs) then
      return lhs
   else
      return { op = 'and',
	       lhs = lhs,
	       rhs = rhs }
   end
end
simp.conjoin = conjoin

local function disjoin (lhs, rhs)
   return { op = 'or',
	    lhs = lhs,
	    rhs = rhs }
end
simp.disjoin = disjoin

-- Split a clause into head and body; create a body if the clause is a
-- fact.
local function extract_head_and_body (clause)
   local op, kind = main_operator(clause)
   if kind == 'functor' then
      assert(clause.op == 'compound-term',
	     "Clause kind is functor, but its operator is not a compound term.")
      return clause, true_value()
   else
      assert(clause.op == ':-')
      local head, body = assert(clause.lhs), assert(clause.rhs)
      assert(head.op == 'compound-term')
      return head, body
   end
end
simp.extract_head_and_body = extract_head_and_body

local function simplify_clause_head (clause)
   local head, body = extract_head_and_body(clause)
   local args = head.args
   for i,arg in ipairs(args) do
      if not is_variable(arg) then
	 local var = make_variable()
	 args[i] = var
	 body = conjoin(make_unification(var, arg), body)
      end
   end
   return head, body
end
simp.simplify_clause_head = simplify_clause_head
