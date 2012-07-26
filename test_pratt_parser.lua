-- Tests of the Pratt parser.
--
local utils = require 'utilities'
local lex = require 'basic_lexer'
local pratt = require 'pratt_parser'
local test = require 'lunatest'

local operator, default_environment = 
   pratt.operator, pratt.default_environment
local null_context, left_context =
   pratt.null_context, pratt.left_context
local default_null_denotation, default_left_denotation =
   pratt.default_null_denotation, pratt.default_left_denotation
local null_denotation = pratt.null_denotation
local prefix_op, postfix_op = pratt.prefix_op, pratt.postfix_op
local infix_left, infix_no, infix_right =
   pratt.infix_left, pratt.infix_no, pratt.infix_right
local open_delimiter, list_delimiter =
   pratt.open_delimiter, pratt.list_delimiter
local operator_specification = pratt.operator_specification
local delete_op = pratt.delete_op
local is_arg_cons, flatten_arg_cons = 
   pratt.is_arg_cons, pratt.flatten_arg_cons
local parse = pratt.parse

local assert_node = utils.assert_node
local set_node_metatable, set_node_metatable_recursively =
   utils.set_node_metatable, utils.set_node_metatable_recursively
local print_table = utils.print_table

module('test_pratt_parser', package.seeall)

local function assert_pratt_parse (expected, tokens, rbp, env, override)
   rbp = rbp or 0
   env = env or pratt.default_environment
   override = override or {}
   expected = set_node_metatable_recursively(expected)
   local result = parse(rbp, tokens, 1, env, override)
   set_node_metatable_recursively(result)
   assert_equal(getmetatable(expected), getmetatable(result),
	       "Metatables do not match for " .. 
		  utils.table_tostring(result) ..
		  ", " .. 
		  utils.table_tostring(expected) .. 
		  ".")
   assert_equal(expected, result);
end

local function assert_lex_parse (code, expected, lexer, rbp, env, override)
   lexer = lexer or lex.lexer
   rbp = rbp or 0
   env = env or pratt.default_environment
   override = override or {}
   expected = set_node_metatable_recursively(expected)
   local lex_result = lexer:match(code)
   -- print_table(lex_result)
   local result = parse(rbp, lex_result, 1, env, override)
   set_node_metatable_recursively(result)
   assert_equal(getmetatable(expected), getmetatable(result),
	       "Metatables do not match for " .. code .. ".")
   assert_equal(expected, result);
end

local function assert_lex_parse_error (code, lexer, rbp, env, override)
   lexer = lexer or lex.lexer
   rbp = rbp or 0
   env = env or pratt.default_environment
   override = override or {}
   local lex_result = lexer:match(code)
   assert_error(function () parse(rbp, lex_result, 1, env, override) end)
end

function test_operator ()
   assert_equal('foo', operator { name = 'foo'})
   assert_not_equal('foo', operator { name = 'bar' })
   local token = {}
   assert_equal(token, operator(token))
   assert_error(function () return operator(token, true) end)
end

function test_null_context ()
   assert_table(null_context(default_environment))
   assert_error(function () return null_context({}) end)
end

function test_null_denotation_1 ()
   local den, op, rbp = null_denotation('+', default_environment)
   assert_equal(default_null_denotation, den)
   assert_equal('+', op)
   assert_equal(0, rbp)
end

function test_null_denotation_2 ()
   local token = { name = '+' }
   local den, op, rbp = null_denotation(token, default_environment)
   assert_equal(default_null_denotation, den)
   assert_equal('+', op)
   assert_equal(0, rbp)
end

function test_null_denotation_3 ()
   local token = { name = ':-' }
   local den, op, rbp = null_denotation(token, default_environment)
   assert_equal(prefix_op, den)
   assert_equal(':-', op)
   assert_equal(100, rbp)
end

function test_left_context ()
   assert_table(left_context(default_environment))
   assert_error(function () return left_context({}) end)
end

function test_op_spec_1 ()
   local token = nil
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, {})
   assert_equal(default_left_denotation, den)
   assert_nil(op)
   assert_nil(opspec)
   assert_equal(0, lbp)
end

function test_op_spec_2 ()
   local token = {}
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, {})
   assert_equal(default_left_denotation, den)
   assert_equal(token, op)
   assert_nil(opspec)
   assert_equal(0, lbp)
end

function test_op_spec_3 ()
   local token = { name = '<' }
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, {})
   assert_equal(infix_no, den)
   assert_equal('<', op)
   assert_table(opspec)
   assert_equal(500, lbp)
end

function test_op_spec_4 ()
   local token = { name = ',' }
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, {})
   assert_equal(infix_right, den)
   assert_equal('and', op)
   assert_table(opspec)
   assert_equal(300, lbp)
end

function test_op_spec_5 ()
   local token = { name = '<' }
   local override = { ['<'] = { left_binding_power = 1234,
				denotation = infix_left }}
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, override)
   assert_equal(infix_left, den)
   assert_equal('<', op)
   assert_table(opspec)
   assert_equal(1234, lbp)
end

function test_op_spec_6 ()
   local token = { name = '<' }
   local override = { ['<'] = delete_op }
   local den, op, opspec, lbp = 
      operator_specification(token, default_environment, override)
   assert_equal(default_left_denotation, den)
   assert_equal('<', op)
   assert_nil(opspec)
   assert_equal(0, lbp)
end

function test_parse_1 ()
   local tokens = {{ name = 'foo' }}
   local expected = tokens[1]
   assert_pratt_parse(expected, tokens)
end

function test_parse_2 ()
   local tokens = {{ '1' }}
   local expected = tokens[1]
   assert_pratt_parse(expected, tokens)
end

function test_parse_3 ()
   local tokens = {{ '1' }, { name = '+' }, { '2' }}
   local expected = { op = '+',
		      lhs = tokens[1],
		      rhs = tokens[3] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_4 ()
   local tokens = {{ '1' }, { name = '+' }, { '2' }, { name = '+' }, { '3' }}
   local expected = { op = '+',
		      lhs = { op = '+', lhs = tokens[1], rhs = tokens[3] },
		      rhs = tokens[5] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_5 ()
   local tokens = {{ '1' }, { name = '+' },
		   { '2' }, { name = '+' }, 
		   { '3' }, { name = '+' }, 
		   { '4' }}
   local expected = { op = '+',
		      lhs = { op = '+',
			      lhs = { op = '+', lhs = tokens[1], rhs = tokens[3] },
			      rhs = tokens[5] },
		      rhs = tokens[7] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_6 ()
   local tokens = {{ '1' }, { name = '+' },
		   { '2' }, { name = '-' }, 
		   { '3' }, { name = '+' }, 
		   { '4' }}
   local expected = { op = '+',
		      lhs = { op = '-',
			      lhs = { op = '+', lhs = tokens[1], rhs = tokens[3] },
			      rhs = tokens[5] },
		      rhs = tokens[7] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_7 ()
   local tokens = {{ '1' }, { name = '*' }, { '2' }}
   local expected = { op = '*',
		      lhs = tokens[1],
		      rhs = tokens[3] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_8 ()
   local tokens = {{ '1' }, { name = '*' }, { '2' }, { name = '+' }, { '3' }}
   local expected = { op = '+',
		      lhs = { op = '*', lhs = tokens[1], rhs = tokens[3] },
		      rhs = tokens[5] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_9 ()
   local tokens = {{ '1' }, { name = '+' }, { '2' }, { name = '*' }, { '3' }}
   local expected = { op = '+',
		      lhs = tokens[1],
		      rhs = { op = '*', lhs = tokens[3], rhs = tokens[5] }}
   assert_pratt_parse(expected, tokens)
end

function test_parse_10 ()
   local tokens = {{ '1' }, { name = '+' },
		   { '2' }, { name = '*' }, 
		   { '3' }, { name = '+' }, 
		   { '4' }}
   local expected = {op = '+', 
		     lhs = {op = '+',
			    lhs = tokens[1],
			    rhs = {op = '*', lhs = tokens[3], rhs = tokens[5]}},
		     rhs = tokens[7]}
   assert_pratt_parse(expected, tokens)
end

function test_parse_11 ()
   local tokens = {{ '1' }, { name = '^' }, { '2' }}
   local expected = { op = '^',
		      lhs = tokens[1],
		      rhs = tokens[3] }
   assert_pratt_parse(expected, tokens)
end

function test_parse_12 ()
   local tokens = {{ '1' }, { name = '^' }, { '2' }, { name = '^' }, { '3' }}
   local expected = { op = '^',
		      lhs = tokens[1],
		      rhs = { op = '^', lhs = tokens[3], rhs = tokens[5] }}
   assert_pratt_parse(expected, tokens)
end

function test_parse_13 ()
   local tokens = {{ '1' }, { name = '^' }, 
		   { '2' }, { name = '^' }, 
		   { '3' }, { name = '^' }, 
		   { '4' }}
   local expected = { op = '^',
		      lhs = tokens[1],
		      rhs = { op = '^', 
			      lhs = tokens[3], 
			      rhs = { op = '^',
				      lhs = tokens[5],
				      rhs = tokens[7] }}}
   assert_pratt_parse(expected, tokens)
end

function test_parse_14 ()
   local tokens = {{ '1' }, { name = '+' }, 
		   { '2' }, { name = '*' }, 
		   { '3' }, { name = '^' }, 
		   { '4' }}
   local expected = { op = '+',
		      lhs = tokens[1],
		      rhs = { op = '*', 
			      lhs = tokens[3], 
			      rhs = { op = '^',
				      lhs = tokens[5],
				      rhs = tokens[7] }}}
   assert_pratt_parse(expected, tokens)
end

function test_parse_15 ()
   local tokens = {{ '1' }, { name = '^' }, 
		   { '2' }, { name = '*' }, 
		   { '3' }, { name = '+' }, 
		   { '4' }}
   local expected = { op = '+',
		      lhs = { op = '*',
			      lhs = { op = '^',
				      lhs = tokens[1],
				      rhs = tokens[3] },
			      rhs = tokens[5] },
		      rhs = tokens[7] }
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_1 ()
   local tokens = {{ name = '(' }, { '1' }, { name = '+' }, { '2' }, { name = ')' }} 
   local expected = { op = '+',
		      delimited = true,
		      lhs = tokens[2],
		      rhs = tokens[4] }
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_2 ()
   local tokens = {{ name = '(' }, { '1' }, { name = '+' }, { '2' }, { name = ')' },
		   { name = '*' }, { '3' }} 
   local expected = { op = '*',
		      lhs = { op = '+',
			      delimited = true,
			      lhs = tokens[2],
			      rhs = tokens[4] },
		      rhs = tokens[7] }
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_3 ()
   local tokens = {{ name = '(' }, { '1' }, { name = '+' }, 
		   { '2', pos = 1234 }, { name = ')' },
		   { name = '*' }} 
   assert_error(function () pratt.parse(0, tokens, 1, default_environment, {}) end)
end

function test_paren_parse_4 ()
   local tokens = {{ name = '(' }, { '1' }, { name = '+' }, { name = ')' },
		   { '2', pos = 1234 }, { name = ')' },
		   { name = '*' }, { '3' }} 
   assert_error(function () pratt.parse(0, tokens, 1, default_environment, {}) end)
end

function test_paren_parse_5 ()
   local tokens = {{ name = '(' }, { name = '(' }, { name = '(' },
		   { '1' }, { name = ')' },
		   { name = '+' }, { '2' }, { name = ')' }, { name = ')' }}
   local expected = { op = '+',
		      delimited = true,
		      lhs = { '1',
			      delimited = true },
		      rhs = { '2' } }
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_6 ()
   local tokens = {{ name = '(' }, { name = '(' }, { name = '(' }, { name = '(' },
		   { '1' }, { name = ')' }, { name = '+' }, { '2' }, { name = ')' },
		   { name = ')' }, { name = ')' },
		   { name = '*' }, { '3' }}
   local expected = { op = '*',
		      lhs = { op = '+',
			      delimited = true,
			      lhs = { '1',
				      delimited = true },
			      rhs = { '2'} },
		      rhs = { '3' }}
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_7 ()
   local tokens = {{ '1' }, { name = '+' }, { name = '(' },  { '2' },
		   { name = '-' }, { '3' }, { name = ')' }} 
   local expected = { op = '+',
		      lhs = { '1' },
		      rhs = { op = '-',
			      delimited = true,
			      lhs = { '2' },
			      rhs = { '3' } }}
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_8 ()
   local tokens = {{ '1' }, { name = '*' }, { name = '(' },  { '2' },
		   { name = '-' }, { '3' }, { name = ')' }} 
   local expected = { op = '*',
		      lhs = { '1' },
		      rhs = { op = '-',
			      delimited = true,
			      lhs = { '2' },
			      rhs = { '3' } }}
   assert_pratt_parse(expected, tokens)
end

function test_is_arg_cons_1 ()
   assert_true(is_arg_cons{'cons-arg', 1, 2})
   assert_false(is_arg_cons{ name = 'foo' })
   assert_false(is_arg_cons{})
end

function test_flatten_arg_cons_1 ()
   local expected = set_node_metatable_recursively({{}})
   local arg_cons = {}
   local result = flatten_arg_cons(arg_cons)
   result = set_node_metatable_recursively(result)
   assert_equal(expected, result)
end

function test_flatten_arg_cons_2 ()
   local expected = set_node_metatable_recursively({1, 2, 3})
   local arg_cons = {'cons-arg', 1, {'cons-arg', 2, 3}}
   local result = flatten_arg_cons(arg_cons)
   result = set_node_metatable_recursively(result)
   assert_equal(expected, result)
end

function test_function_parse_1 ()
   local tokens = {{ name = 'f' }, { name = '(' }, { name = ')'}}
   local expected = { op = "compound-term", functor = tokens[1], args = {}}
   assert_pratt_parse(expected, tokens)
end

function test_function_parse_2 ()
   local tokens = {{ name = 'f' }, { name = '(' }, { '1' }, { name = ')'}}
   local expected = { op = "compound-term", functor = tokens[1], args = {{'1'}}}
   assert_pratt_parse(expected, tokens)
end

function test_function_parse_3 ()
   local tokens = {{ name = 'f' }, { name = '(' }, 
		   { '1' }, { name = ',' },
		   { '2' },
		   { name = ')'}}
   local expected = { op = "compound-term", functor = tokens[1],
		      args = {{'1'}, {'2'}}}
   assert_pratt_parse(expected, tokens)
end

function test_function_parse_4 ()
   local tokens = {{ name = 'f' }, { name = '(' }, 
		   { '1' }, { name = ',' },
		   { '2' }, { name = ',' },
		   { name = ')'}}
   local expected = { op = "compound-term", functor = tokens[1],
		      args = {{'1'}, {'2'}}}
   assert_error(function () pratt.parse(0, tokens, 1, default_environment, {}) end)
end

function test_function_parse_5 ()
   local tokens = {{ name = 'f' }, { name = '(' }, 
		   { '1' }, { name = ',' },
		   { name = 'g' }, { name = '(' },
		   { 'a' }, { name = ',' }, { 'b' },
		   { name = ')' }, { name = ',' },
		   { '2' }, { name = ',' }, { '3' },
		   { name = ')'}}
   local expected = {op = "compound-term",
		     functor = {name = "f"}, 
		     args = {{"1"},
			     {op = "compound-term", 
			      functor = {name = "g"},
			      args = {{"a"}, {"b"}}},
			     {"2"},
			     {"3"}}}
   assert_pratt_parse(expected, tokens)
end

function test_lexer_and_parser_1 ()
   local code = "1"
   local expected = {type = "number", pos = 1, name = "1"}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_2 ()
   local code = "1 + 2"
   local expected = {op = "+",
		     lhs = {type = "number", pos = 1, name = "1"},
		     rhs = {type = "number", pos = 5, name = "2"}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_3 ()
   local code = "1 + 2 * 3"
   local expected = {op = "+",
		     lhs = {type = "number", pos = 1, name = "1"},
		     rhs = {op = "*",
			    lhs = {type = "number", pos = 5, name = "2"},
			    rhs = {type = "number", pos = 9, name = "3"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_4 ()
   local code = "1 * (2 + 3 + 4)"
   local expected = {op = "*",
		     lhs = {type = "number", pos = 1, name = "1"},
		     rhs = {op = "+",
			    delimited = true,
			    lhs = {op = "+",
				   lhs = {type = "number", pos = 6, name = "2"},
				   rhs = {type = "number", pos = 10, name = "3"}},
			    rhs = {type = "number", pos = 14, name = "4"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_5 ()
   local code = "7 * (8 + 9)"
   local expected = {op = "*",
		     lhs = {type = "number", pos = 1, name = "7"},
		     rhs = {op = "+",
			    delimited = true,
			    lhs = {type = "number", pos = 6, name = "8"},
			    rhs = {type = "number", pos = 10, name = "9"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_6 ()
   local code = "7 ^ (8 + 9)"
   local expected = {op = "^",
		     lhs = {type = "number", pos = 1, name = "7"},
		     rhs = {op = "+",
			    delimited = true,
			    lhs = {type = "number", pos = 6, name = "8"},
			    rhs = {type = "number", pos = 10, name = "9"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_7 ()
   local code = "1 * (2 + 3 + 4) + 5 * 6 ^ 7 ^ (8 + 9)"
   local expected = {
      op = "+",
      lhs = {op = "*",
	     lhs = {type = "number", pos = 1, name = "1"},
	     rhs = {
		op = "+",
		delimited = true,
		lhs = {
		   op = "+",
		   lhs = {type = "number", pos = 6, name = "2"},
		   rhs = {type = "number", pos = 10, name = "3"}},
		rhs = {type = "number", pos = 14, name = "4"}}},
      rhs = {
	 op = "*",
	 lhs = {type = "number", pos = 19, name = "5"},
	 rhs = {
	    op = "^",
	    lhs = {type = "number", pos = 23, name = "6"}, 
	    rhs = {
	       op = "^",
	       lhs = {type = "number", pos = 27, name = "7"},
	       rhs = {
		  op = "+",
		  delimited = true,
		  lhs = {type = "number", pos = 32, name = "8"},
		  rhs = {type = "number", pos = 36, name = "9"}}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_8 ()
   local code = "[]"
   local expected = {op = "list", args = {}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_9 ()
   local code = "[1]"
   local expected = {op = "list",
		     args = {{type = "number", pos = 2, name = "1"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_10 ()
   local code = "[1, 2, 3]"
   local expected = {op = "list",
		     args = {{type = "number", pos = 2, name = "1"},
			     {type = "number", pos = 5, name = "2"},
			     {type = "number", pos = 8, name = "3"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_11 ()
   local code = "[x | Y]"
   local expected = {op = "list",
		     args = {{type = "atom", pos = 2, name = "x"}},
		     rest_arg = {type = "variable", pos = 6, name = "Y"}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_12 ()
   local code = "[x | [Y | Z]]"
   local expected = {
      op = "list",
      args = {{type = "atom", pos = 2, name = "x"}},
      rest_arg = {
	 op = "list",
	 args = {{type = "variable", pos = 7, name = "Y"}},
	 rest_arg = {
	    type = "variable", pos = 11, name = "Z"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_1 ()
   local code = "f()"
   local expected = {op = "compound-term", 
		     functor = {type = "atom", pos = 1, name = "f"},
		     args = {}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_2 ()
   local code = "f(1, x, X)"
   local expected = {op = "compound-term", 
		     functor = {type = "atom", pos = 1, name = "f"}, 
		     args = {{type = "number", pos = 3, name = "1"}, 
			     {type = "atom", pos = 6, name = "x"},
			     {type = "variable", pos = 9, name = "X"}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_3 ()
   local code = "f(g(x), h(Y, Z))"
   local expected = {op = "compound-term", 
		     functor = {type = "atom", pos = 1, name = "f"},
		     args = {{op = "compound-term", 
			      functor = {type = "atom", pos = 3, name = "g"},
			      args = {{type = "atom", pos = 5, name = "x"}}},
			     {op = "compound-term", 
			      functor = {type = "atom", pos = 9, name = "h"},
			      args = {{type = "variable", pos = 11, name = "Y"},
				      {type = "variable", pos = 14, name = "Z"}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_4 ()
   local code = "(f())"
   local expected = {op = "compound-term", 
		     delimited = true,
		     functor = {type = "atom", pos = 2, name = "f"},
		     args = {}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_5 ()
   local code = "f()()"
   local expected = {op = "compound-term",
		     functor = {op = "compound-term",
			    functor = {type = "atom", pos = 1, name = "f"}, 
			    args = {}}, 
		     args = {}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_6 ()
   local code = "f(g(X))(1 + 2 * 3)"
   local expected = {op = "compound-term", 
		     functor = {op = "compound-term", 
			    functor = {type = "atom", pos = 1, name = "f"},
			    args = {
			       {op = "compound-term", 
				functor = {type = "atom", 
				       pos = 3, name = "g"},
				args = {{type = "variable", pos = 5, name = "X"}}}}},
		     args = {{op = "+",
			      lhs = {type = "number", pos = 9, name = "1"},
			      rhs = {op = "*",
				     lhs = {type = "number", pos = 13, name = "2"},
				     rhs = {type = "number", pos = 17, name = "3"}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_7 ()
   local code = "f(g(X)) * (1 + 2 * 3)"
   local expected = {op = "*",
		     lhs = {op = "compound-term", 
			    functor = {type = "atom", pos = 1, name = "f"},
			    args = {
			       {op = "compound-term",
				functor = {type = "atom", pos = 3, name = "g"},
				args = {{type = "variable", pos = 5, name = "X"}}}}},
		     rhs = {op = "+",
			    delimited = true,
			    lhs = {type = "number", pos = 12, name = "1"},
			    rhs = {op = "*",
				   lhs = {type = "number", pos = 16, name = "2"},
				   rhs = {type = "number", pos = 20, name = "3"}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_8 ()
   local code = "f(g(X)) * -(1 + 2 * 3)"
   local expected = {op = "*",
		     lhs = {
			op = "compound-term", 
			functor = {type = "atom", pos = 1, name = "f"},
			args = {
			   {op = "compound-term", 
			    functor = {type = "atom", pos = 3, name = "g"},
			    args = {{type = "variable", pos = 5, name = "X"}}}}},
		     rhs = {
			op = "-", 
			rhs = {
			   op = "+",
			   delimited = true,
			   lhs = {type = "number", pos = 13, name = "1"},
			   rhs = {
			      op = "*",	  
			      lhs = {type = "number", pos = 17, name = "2"},
			      rhs = {type = "number", pos = 21, name = "3"}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_9 ()
   local code = "f(g(X)) * - - - -(1 + - 2)"
   local expected = {
      op = "*",
      lhs = {
	 op = "compound-term", 
	 functor = {type = "atom", pos = 1, name = "f"},
	 args = {
	    {op = "compound-term", 
	     functor = {type = "atom", pos = 3, name = "g"},
	     args = {{type = "variable", pos = 5, name = "X"}}}}}, 
      rhs = {
	 op = "-", 
	 rhs = {
	    op = "-", 
	    rhs = {
	       op = "-", 
	       rhs = {
		  op = "-", 
		  rhs = {
		     op = "+",	  
		     delimited = true,
		     lhs = {type = "number", pos = 19, name = "1"},
		     rhs = {type = "number", pos = 23, name = "- 2"}}}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_10 ()
   local code = "f(g(X)) - - - - -(1 + - 2)"
   local expected = {
      op = "-",
      lhs = {
	 op = "compound-term", 
	 functor = {type = "atom", pos = 1, name = "f"},
	 args = {
	    {op = "compound-term", 
	     functor = {type = "atom", pos = 3, name = "g"},
	     args = {{type = "variable", pos = 5, name = "X"}}}}}, 
      rhs = {
	 op = "-", 
	 rhs = {
	    op = "-", 
	    rhs = {
	       op = "-", 
	       rhs = {
		  op = "-",
		  rhs = {
		     op = "+",
		     delimited = true,
		     lhs = {type = "number", pos = 19, name = "1"},
		     rhs = {type = "number", pos = 23, name = "- 2"}}}}}}}
   assert_lex_parse(code, expected)
end

function test_lexer_and_parser_fun_11 ()
   local code = "f(g(X)) + - - - +(1 + - 2)"
   local expected = {
      op = "+", 
      rhs = {
	 op = "-", 
	 rhs = {
	    op = "-", 
	    rhs = {
	       op = "-", 
	       rhs = {
		  op = "compound-term", 
		  functor = {type = "atom", pos = 17, name = "+"},
		  args = {
		     {op = "+",
		      lhs = {type = "number", pos = 19, name = "1"},
		      rhs = {type = "number", pos = 23, name = "- 2"}}}}}}},
      lhs = {op = "compound-term", 
	     functor = {type = "atom", pos = 1, name = "f"},
	     args = {{op = "compound-term", 
		      functor = {type = "atom", pos = 3, name = "g"},
		      args = {{type = "variable", pos = 5, name = "X"}}}}}}
   assert_lex_parse(code, expected)
end

function test_clause_1 ()
   local code = "f(X, Y)."
   local expected = {op = "compound-term", 
		     functor = {type = "atom", pos = 1, name = "f"},
		     args = {{type = "variable", pos = 3, name = "X"},
			     {type = "variable", pos = 6, name = "Y"}}}
   assert_lex_parse(code, expected)
end

function test_clause_2 ()
   local code = "f(X, Y) :- g(X, Z), h(Z, Y)."
   local expected = {
      op = ":-",
      lhs = {op = "compound-term", 
	     functor = {type = "atom", pos = 1, name = "f"},
	     args = {{type = "variable", pos = 3, name = "X"},
		     {type = "variable", pos = 6, name = "Y"}}},
      rhs = {
	 op = "and",
	 lhs = {op = "compound-term",
		functor = {type = "atom", pos = 12, name = "g"},
		args = {{type = "variable", pos = 14, name = "X"}, 
			{type = "variable", pos = 17, name = "Z"}}},
	 rhs = {
	    op = "compound-term", 
	    functor = {type = "atom", pos = 21, name = "h"},
	    args = {{type = "variable", pos = 23, name = "Z"},
		    {type = "variable", pos = 26, name = "Y"}}}}}
   assert_lex_parse(code, expected)
end

function test_clause_3 ()
   local code = "f(X, Y) :- g(X, Z) :- h(Z, Y)."
   assert_lex_parse_error(code)
end

function test_clause_4 ()
   local code = "f(X, Y) :- (g(X, Z) :- h(Z, Y))."
   assert_lex_parse(code, {
		       op = ":-",
		       lhs = {
			  op = "compound-term",
			  functor = {type = "atom", pos = 1, name = "f"},
			  args = {{type = "variable", pos = 3, name = "X"},
				  {type = "variable", pos = 6, name = "Y"}}},
		       rhs = {
			  op = ":-",
			  delimited = true,
			  lhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 13, name = "g"},
			     args = {
				{type = "variable", pos = 15, name = "X"},
				{type = "variable", pos = 18, name = "Z"}}},
			  rhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 24, name = "h"},
			     args = {
				{type = "variable", pos = 26, name = "Z"},
				{type = "variable", pos = 29, name = "Y"}}}}})
end

function test_clause_5 ()
   local code = "f(X, Y) :- (g(X, Z) --> h(Z, Y))."
   assert_lex_parse(code, {
		       op = ":-",
		       lhs = {
			  op = "compound-term",
			  functor = {type = "atom", pos = 1, name = "f"},
			  args = {
			     {type = "variable", pos = 3, name = "X"},
			     {type = "variable", pos = 6, name = "Y"}}}, 
		       rhs = {
			  op = "-->", 
			  lhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 13, name = "g"},
			     args = {
				{type = "variable", pos = 15, name = "X"},
				{type = "variable", pos = 18, name = "Z"}}},
			  rhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 25, name = "h"},
			     args = {
				{type = "variable", pos = 27, name = "Z"},
				{type = "variable", pos = 30, name = "Y"}}},
			  delimited = true}})
end

function test_clause_6 ()
   local code = "f(X, Y) :- g(X, Z) --> h(Z, Y)."
   assert_lex_parse_error(code)
end

function test_clause_7 ()
   local code = "f(X, Y) :- (g(X, Z) --> -->(Z, Y))."
   assert_lex_parse(code, {
		       op = ":-",
		       lhs = {
			  op = "compound-term",
			  functor = {type = "atom", pos = 1, name = "f"},
			  args = {
			     {type = "variable", pos = 3, name = "X"},
			     {type = "variable", pos = 6, name = "Y"}}}, 
		       rhs = {
			  op = "-->",
			  delimited = true,
			  lhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 13, name = "g"},
			     args = {
				{type = "variable", pos = 15, name = "X"},
				{type = "variable", pos = 18, name = "Z"}}},
			  rhs = {
			     op = "compound-term",
			     functor = {type = "atom", pos = 25, name = "-->"},
			     args = {
				{type = "variable", pos = 29, name = "Z"},
				{type = "variable", pos = 32, name = "Y"}}}}})
end
