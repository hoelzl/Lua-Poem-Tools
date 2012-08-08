-- Tests of clause simplification.
--
local utils = require 'utilities'
local pratt = require 'pratt_parser'
local test = require 'lunatest'
local simp = require 'simplification'

local assert_node, assert_parse_tree_equal =
   utils.assert_node, utils.assert_parse_tree_equal
local assert_parse_tree_similar =
   utils.assert_parse_tree_similar
local set_node_metatable, set_node_metatable_recursively =
   utils.set_node_metatable, utils.set_node_metatable_recursively
local print_table = utils.print_table

local parse_clauses_from_string = pratt.parse_clauses_from_string

local main_operator = simp.main_operator
local is_variable, is_clause = simp.is_variable, simp.is_clause
local make_variable, make_clause, make_unification = 
   simp.make_variable, simp.make_clause, simp.make_unification
local variable_equal = simp.variable_equal
local arglists, arglist_of_length = 
   simp.arglists, simp.arglist_of_length
local substitute_variable, substitute_variables 
   = simp.substitute_variable, simp.substitute_variables
local true_value, is_true_value = simp.true_value, simp.is_true_value
local conjoin, disjoin = simp.conjoin, simp.disjoin
local extract_head_and_body = simp.extract_head_and_body
local simplify_clause_head = simp.simplify_clause_head

module('test_simplification', package.seeall)

local function assert_head_simplification (input_code, expected_head_code,
					   expected_body_code)
   local input = parse_clauses_from_string(input_code)[1]
   assert_table(input)
   local head, body = simplify_clause_head(input)
   local expected_head = parse_clauses_from_string(expected_head_code)[1]
   assert_table(expected_head)
   local expected_body = parse_clauses_from_string(expected_body_code)[1]
   assert_table(expected_body)
   assert_parse_tree_similar(expected_head, head)
   assert_parse_tree_similar(expected_body, body)
end

function test_main_operator_1 ()
   local code = 'f(X, Y).'
   local clause = parse_clauses_from_string(code)[1]
   local op, type = main_operator(clause)
   assert_equal('f', op)
   assert_equal('functor', type)
end

function test_main_operator_2 ()
   local code = 'f(X, Y) :- g(Y, X).'
   local clause = parse_clauses_from_string(code)[1]
   local op, type = main_operator(clause)
   assert_equal(':-', op)
   assert_equal('operator', type)
end

function test_main_operator_3 ()
   local code = 'f(X, Y) + g(Y, X) * (foo --> bar).'
   local clause = parse_clauses_from_string(code)[1]
   local op, type = main_operator(clause)
   assert_equal('+', op)
   assert_equal('operator', type)
end

function test_is_variable ()
   local code = 'f(X, Y).'
   local clauses = parse_clauses_from_string(code)
   assert_true(is_variable(clauses[1].args[1]))
   assert_false(is_variable(clauses[1].functor))
end

function test_is_true_value ()
   assert_true(is_true_value(true_value()))
   assert_true(is_true_value(parse_clauses_from_string('true.')[1]))
   assert_false(is_true_value(parse_clauses_from_string('false.')[1]))
end

function test_is_clause_1 ()
   local code = 'f(X, Y).'
   local clauses = parse_clauses_from_string(code)
   assert_true(is_clause(clauses[1]))
end

function test_is_clause_2 ()
   local code = 'f(X, Y) :- foo(bar), g(Y, Y, Y).'
   local clauses = parse_clauses_from_string(code)
   assert_true(is_clause(clauses[1]))
end

function test_is_clause_3 ()
   local code = 'f(X, Y) :- foo(bar), g(Y, Y, Y); h(X, Y), baz(1 - X).'
   local clauses = parse_clauses_from_string(code)
   assert_table(clauses[1])
   assert(':-', main_operator(clauses[1]))
   assert_true(is_clause(clauses[1]))
end

function test_is_clause_4 ()
   local code = 'f(X, Y) --> foo(bar), g(Y, Y, Y); h(X, Y), baz(1 - X).'
   local clauses = parse_clauses_from_string(code)
   assert_table(clauses[1])
   assert(':-', main_operator(clauses[1]))
   assert_false(is_clause(clauses[1]))
end

function test_is_variable ()
   local var = make_variable()
   assert_equal('variable', var.type)
   assert_table(var.name)
end

function test_make_clause ()
   local lhs = parse_clauses_from_string('foo(X, Y).')[1]
   local rhs = parse_clauses_from_string('bar(X, Z), baz(Z, Y).')[1]
   local result = make_clause(lhs, rhs)
   assert_parse_tree_equal(
      { op = ":-",
	lhs = {
	   op = "compound-term",
	   functor = {type = "atom", pos = 1, name = "foo"},
	   args = {{type = "variable", pos = 5, name = "X"},
		   {type = "variable", pos = 8, name = "Y"}}}, 
	rhs = {
	   op = "and",
	   lhs = {
	      op = "compound-term", 
	      functor = {type = "atom", pos = 1, name = "bar"},
	      args = {{type = "variable", pos = 5, name = "X"},
		      {type = "variable", pos = 8, name = "Z"}}},
	   rhs = {
	      op = "compound-term", 
	      functor = {type = "atom", pos = 12, name = "baz"},
	      args = {{type = "variable", pos = 16, name = "Z"},
		      {type = "variable", pos = 19, name = "Y"}}}}},
      result)
   assert_table(lhs)
   assert_table(rhs)
   assert_parse_tree_equal({ op = ':-', lhs = lhs, rhs = rhs }, result)
end

function test_make_unification ()
   local lhs = parse_clauses_from_string('foo(X, Y).')[1]
   local rhs = parse_clauses_from_string('bar(X, Z), baz(Z, Y).')[1]
   assert_table(lhs)
   assert_table(rhs)
   local result = make_unification(lhs, rhs)
   assert_parse_tree_equal({ op = '=', lhs = lhs, rhs = rhs }, result)
end

function test_variable_equal ()
   local value1 = parse_clauses_from_string('foo(X, Y).')[1]
   local value2 = parse_clauses_from_string('bar(X, Z), baz(Z, Y).')[1]
   local var1 = { type = 'variable', name = 'X'}
   local var2 = { type = 'variable', name = 'X'} 
   local var3 = make_variable()
   assert_true(variable_equal(var1, var1))
   assert_true(variable_equal(var1, var2))
   assert_not_equal(var1, var2)
   assert_true(variable_equal(var3, var3))
   assert_false(variable_equal(var1, var3))
   assert_false(variable_equal(var1, value1))
   assert_false(variable_equal(value1, var1))
   assert_false(variable_equal(value1, value2))
end

function test_arglist_of_length_1 ()
   local result = arglist_of_length(0)
   assert_table(result)
   assert_equal(0, #result)
end

function test_arglist_of_length_2 ()
   local result = arglist_of_length(5)
   assert_table(result)
   assert_equal(5, #result)
   for _, v in ipairs(result) do
      assert_true(is_variable(v))
   end
   assert_equal(result, arglist_of_length(5))
end

function test_arglist_of_length_3 ()
   local result = arglist_of_length(500)
   assert_table(result)
   assert_equal(500, #result)
   for _, i in ipairs({1,5,100,500}) do
      assert_true(is_variable(result[i]))
   end
   assert_equal(result, arglist_of_length(500))
end

function test_substitute_variable_1 ()
   local old_var = make_variable()
   local new_var = make_variable()
   assert_equal(new_var, substitute_variable(new_var, old_var, old_var))
end

function test_substitute_variable_2 ()
   local old_var = make_variable()
   local new_var = make_variable()
   assert_equal(new_var, substitute_variable(new_var, old_var, new_var))
end

function test_substitute_variable_3 ()
   local old_var = make_variable()
   local new_var = make_variable()
   local term = make_variable()
   assert_parse_tree_equal(term,
			   substitute_variable(new_var, old_var, term))
end

function test_substitute_variable_4 ()
   local old_var = { type = 'variable', name = "Old" }
   local new_var = { type = 'variable', name = "New" }
   local term = { op = '+', lhs = old_var, rhs = old_var }
   local result = { op = '+', lhs = new_var, rhs = new_var }
   assert_parse_tree_equal(result, 
			   substitute_variable(new_var, old_var, term))
end

function test_substitute_variable_5 ()
   local old_var = { type = 'variable', name = "Old" }
   local new_var = { type = 'variable', name = "New" }
   local other = { type = 'variable', name = "Other" }
   local term = { op = '+', lhs = old_var, rhs = other }
   local result = { op = '+', lhs = new_var, rhs = other }
   assert_parse_tree_equal(result, 
			   substitute_variable(new_var, old_var, term))
end

function test_substitute_variable_6 ()
   local old_var = { type = 'variable', name = "Old" }
   local new_var = { type = 'variable', name = "New" }
   local term = { op = '+', 
		  lhs = { op = '*',
			  lhs = other,
			  rhs = old_var },
		  rhs = { op = '^',
			  lhs = old_var,
			  rhs = other }}
   local result = { op = '+', 
		  lhs = { op = '*',
			  lhs = other,
			  rhs = new_var },
		  rhs = { op = '^',
			  lhs = new_var,
			  rhs = other }}
   assert_parse_tree_equal(result, 
			   substitute_variable(new_var, old_var, term))
end

function test_substitute_variable_7 ()
   local old_var = { type = 'variable', name = "Old" }
   local new_var = { type = 'variable', name = "New" }
   local term = {op = "compound-term",
		 functor = {type = "atom", pos = 1, name = "f"},
		 args = {
		    old_var,
		    {type = "variable", pos = 6, name = "Y"},
		    old_var}}
   local result = {op = "compound-term",
		 functor = {type = "atom", pos = 1, name = "f"},
		 args = {
		    new_var,
		    {type = "variable", pos = 6, name = "Y"},
		    new_var}}
   assert_parse_tree_equal(result, 
			   substitute_variable(new_var, old_var, term))
end

function test_substitute_variables_1 ()
   local old_var_1 = { type = 'variable', name = "Old 1" }
   local new_var_1 = { type = 'variable', name = "New 1" }
   local old_var_2 = { type = 'variable', name = "Old 2" }
   local new_var_2 = { type = 'variable', name = "New 2" }
   local term = {op = "compound-term",
		 functor = {type = "atom", pos = 1, name = "f"},
		 args = {
		    old_var_1,
		    {type = "variable", pos = 6, name = "Y"},
		    old_var_2}}
   local result = {op = "compound-term",
		 functor = {type = "atom", pos = 1, name = "f"},
		 args = {
		    new_var_1,
		    {type = "variable", pos = 6, name = "Y"},
		    new_var_2}}
   assert_parse_tree_equal(
      result, 
      substitute_variables({{new_var_1, old_var_1}, {new_var_2, old_var_2}},
			   term))
end

function test_conjoin ()
   local lhs = parse_clauses_from_string('foo(X, Y).')[1]
   local rhs = parse_clauses_from_string('bar(X, Z), baz(Z, Y).')[1]
   assert_table(lhs)
   assert_table(rhs)
   local result = conjoin(lhs, rhs)
   assert_parse_tree_equal({ op = 'and', lhs = lhs, rhs = rhs }, result)
   assert_parse_tree_equal(lhs, conjoin(lhs, true_value()))
   assert_parse_tree_equal(rhs, conjoin(true_value(), rhs))
end

function test_disjoin ()
   local lhs = parse_clauses_from_string('foo(X, Y).')[1]
   local rhs = parse_clauses_from_string('bar(X, Z), baz(Z, Y).')[1]
   assert_table(lhs)
   assert_table(rhs)
   local result = disjoin(lhs, rhs)
   assert_parse_tree_equal({ op = 'or', lhs = lhs, rhs = rhs }, result)
end

function test_extract_head_and_body ()
   local code = 'f(X, Y, Z) :- X = Y; g(Z, Z, Z).'
   local clause = parse_clauses_from_string(code)[1]
   assert_table(clause)
   local head, body = extract_head_and_body(clause)
   assert_parse_tree_equal(clause,
			   make_clause(head, body),
			   code)
end

function test_simplify_clause_head_1 ()
   assert_head_simplification('g([X|Y]).', 'g(Z).', 'Z = [X|Y].')
end

function test_simplify_clause_head_2 ()
   assert_head_simplification('g(X, Y, Z).', 'g(X, Y, Z).', 'true.')
end

function test_simplify_clause_head_3 ()
   assert_head_simplification('g(a, Y, Z).',
			      'g(X, Y, Z).',
			      'X = a.')
end

function test_simplify_clause_head_4 ()
   assert_head_simplification('g(a, b, 1).',
			      'g(X, Y, Z).',
			      'Z = 1, Y = b, X = a.')
end

function test_simplify_clause_head_5 ()
   assert_head_simplification('g(X, Y, Z) :- f(X).',
			      'g(X, Y, Z).',
			      'f(X).')
end

function test_simplify_clause_head_6 ()
   assert_head_simplification('g(a, Y, Z) :- f(X).',
			      'g(X, Y, Z).',
			      'X = a and f(X).')
end

function test_simplify_clause_head_7 ()
   assert_head_simplification('g(a, [X, Z | Y], Z) :- f(X).',
			      'g(V, W, Z).',
			      'W = [X, Z | Y] and V = a and f(X).')
end
