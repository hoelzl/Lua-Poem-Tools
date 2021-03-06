-- Simplification of clauses
--
local utils = require 'utilities'

local assert, ipairs, error, print, pairs, tostring, type = 
   assert, ipairs, error, print, pairs, tostring, type
local _G, io, table, string = _G, io, table, string

local table_tostring, print_table = 
   utils.table_tostring, utils.print_table
local clone, merge, slice = utils.clone, utils.merge, utils.slice
local equal = utils.equal

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

local arglist_vars = {}

local function expand_arglist_vars (length)
   arglist_vars_length = #arglist_vars
   if arglist_vars_length >= length then 
      return
   else
      for i = arglist_vars_length + 1, length do
	 arglist_vars[i] = make_variable()
      end
   end
end
expand_arglist_vars(10)

local arglists = {}
simp.arglists = arglists

local function arglist_of_length (length)
   local arglist = arglists[length]
   if arglist then
      return arglist
   else
      expand_arglist_vars(length)
      arglist = slice(arglist_vars, 1, length)
      arglists[length] = arglist
      return arglist
   end
end
simp.arglist_of_length = arglist_of_length

local function substitute_variable (new_var, old_var, term)
   if (type(term) ~= 'table') then
      return term
   elseif variable_equal(old_var, term) then
      return new_var
   elseif variable_equal(new_var, term) then
      return new_var
   end
   local result = clone(term)
   for k, v in pairs(result) do
      result[k] = substitute_variable(new_var, old_var, v)
   end
   return result
end
simp.substitute_variable = substitute_variable

local function substitute_variables (var_pairs, term)
   for _, vars in pairs(var_pairs) do
      term = substitute_variable(vars[1], vars[2], term)
   end 
   return term
end
simp.substitute_variables = substitute_variables

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
   assert(head.op == 'compound-term',
	 "Can only normalize clauses whose head is a compound term.")
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

local function find_term_substitution (substitutions, term)
   for _, t in ipairs(substitutions) do
      -- TODO: We should really define a term_equal function that does
      -- the proper thing for terms.
      if equal(t[1], term) then
	 return t[2]
      end
   end
   return false
end

local function normalize_clause (clause)
   local head, body = extract_head_and_body(clause)
   assert(head.op == 'compound-term',
	 "Can only normalize clauses whose head is a compound term.")
   local arglist = head.args
   local num_args = #arglist
   local normal_arglist = arglist_of_length(num_args)
   local substitutions = {}
   local unifications = {}
   --[[
   for i = 1, num_args do
      local term = arglist[i]
      if not is_variable(arg) then 
	 unifications[#unifications + 1] = { normal_arglist[i], term }
      else
	 if contains_term(substitutions, term) then 
	    unifications[#unifications + 1] = { normal_arglist[i]
	 substitutions[#substitutions + 1] = 
	 end
    --]]
end
