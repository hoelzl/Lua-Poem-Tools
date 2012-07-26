-- Tests of the Pratt parser.
--
local utils = require 'utilities'
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

local assert_node = utils.assert_node

module('test_pratt_parser', package.seeall)

local function assert_pratt_parse (expected, tokens, rbp, env, override)
   rbp = rbp or 0
   env = env or pratt.default_environment
   override = override or {}
   expected = utils.set_node_metatable_recursively(expected)
   local result = pratt.parse(rbp, tokens, 1, env, override)
   assert_equal(getmetatable(expected), getmetatable(result),
	       "Metatables do not match for " .. 
		  utils.table_tostring(result) ..
		  ", " .. 
		  utils.table_tostring(expected) .. 
		  ".")
   assert_equal(expected, result);
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
   assert_equal(200, lbp)
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
		      lhs = tokens[2],
		      rhs = tokens[4] }
   assert_pratt_parse(expected, tokens)
end

function test_paren_parse_2 ()
   local tokens = {{ name = '(' }, { '1' }, { name = '+' }, { '2' }, { name = ')' },
		   { name = '*' }, { '3' }} 
   local expected = { op = '*',
		      lhs = { op = '+',
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