-- A Pratt parser (aka top-down operator-precedence parser)
--
-- An implementation of an extended Pratt parser.
--
-- The original paper by Pratt is still one of the best descriptions
-- of the algorithm that I have found: 
--
-- Vaughan R. Pratt: Top down operator precedence, Proceedings of the
-- 1st annual ACM SIGACT-SIGPLAN symposium on Principles of
-- programming languages.  Available from the following URL:
-- http://dl.acm.org/citation.cfm?id=512931
--
-- The following implementation is written in a more functional style
-- than the algorithm in Pratt's paper so that it could easily be
-- extended to non-deterministic parsing tasks (without encoding the
-- non-determinism in the denotations).

-- The main entry point is the function 'parse'.  It expects an array
-- of tokens, a start index, the current right binding power, and a
-- table containing operator precedences, denotations and various
-- functions (which I call "environment").
--
-- I use the following abbreviations throughout the code:
--
-- env =    environment
-- op =     operator (this is the name of the token, not the full 
--          token returned by the lexer)
-- unop =   unary operator
-- binop =  binary operator
-- opspec = operator specification, a table containing all pertinent
--          information about an operator in a certain environment

-- lunatest chokes on this...
-- require 'strict'
local utils = require 'utilities'
local lex = require 'basic_lexer'

local assert, error, print, tostring, type = 
   assert, error, print, tostring, type
local _G, io, table, string = _G, io, table, string

local table_tostring = utils.table_tostring

module('pratt_parser')

local pratt = _G.pratt_parser

local function operator (token, check_for_errors)
   if type(token) ~= 'table' then
      if check_for_errors then
	 error("Token " .. tostring(token) .. " is not a table.")
      else
	 return token
      end
   end
   local op = token.name or token.op
   if not op then 
      if check_for_errors then
	 error("Can't determine operator of " .. 
	       utils.tostring(token) .. " at position " ..
	       (token.pos or "(unknown position)") .. ".")
      else
	 return token
      end
   end
   return op
end
pratt.operator = operator

local function null_context (environment)
   if not environment then
      error("Environment cannot be empty.")
   end
   context = environment.null_context
   if not context then 
      error('No null context in environment ' .. environment .. '.')
   end
   return context
end
pratt.null_context = null_context


-- The default null denotation for tokens that are not operators
local function default_null_denotation (rbp, op, token, tokens, index, env, override)
   if type(token) ~= "table" then
      error("Token " .. tostring(token) .. " is not a table.")
   end
   return env.make_node(token), index
end
pratt.default_null_denotation = default_null_denotation

-- The default left denotation for tokens that are not operators
local function default_left_denotation (rbp, op, lhs, token, tokens,
					index, env, override)
   if type(token) ~= "table" then
      error("Token " .. tostring(token) .. " is not a table.")
   end
   return env.make_node(token), index
end
pratt.default_left_denotation = default_left_denotation


-- Return the null denotation, the operator, and the right binding
-- power of 'token' in 'environment'.
local function null_denotation (token, env)
   local op = operator(token, false)
   if op then
      local context = null_context(env)
      local opspec = context[op]
      if opspec then
	 return opspec.denotation or env.default_null_denotation,
	        op,
	        opspec.right_binding_power or 0
      else
	 return env.default_null_denotation, op, 0
      end
   else
      return env.default_null_denotation, token, 0
   end
end
pratt.null_denotation = null_denotation

local function left_context (environment)
   context = environment.left_context
   if not context then 
      error('No left context in environment ' .. environment .. '.')
   end
   return context
end
pratt.left_context = left_context

-- Return a replacement operator for 'opspec'
local function replacement_for_op (op, opspec)
   return opspec.replacement or op
end
pratt.replacement_for_op = replacement_for_op

local delete_op = {}
pratt.delete_op = delete_op

-- Return the denotation , the (possibly replaced) operator, its
-- specification, and the left binding power for 'token' as multiple
-- values.
local function operator_specification (token, env, override)
   if not token then
      return env.default_left_denotation, nil, nil, 0
   end
   override = override or {}
   local op = operator(token)
   local opspec = override[op]
   if not opspec then
      local context = left_context(env)
      opspec = context[op]
   end
   if not opspec or opspec == delete_op then 
      return env.default_left_denotation, op, nil, 0
   else
      return opspec.denotation or env.default_left_denotation,
             replacement_for_op(op, opspec),
             opspec,
	     opspec.left_binding_power
   end
end
pratt.operator_specification = operator_specification

-- Return the left binding power of 'token' in 'environment'
local function left_binding_power (token, env, override)
   local den, op, opspec, lbp = 
      operator_specification(token, env, override)
   return lbp
end
pratt.left_binding_power = left_binding_power

local function get_token (tokens, index, check_for_errors)
   local token = tokens[index]
   if not token and check_for_errors then
      error("No token at position " .. index .. ".") 
   end
   return token
end
pratt.get_token = get_token

local last_token

local function error_position_string (index)
   if last_token and type(last_token) == 'table' and last_token.pos then
      return "position " .. tostring(last_token.pos)
   else
      return "index " .. tostring(index)
   end
end

-- Parse 'tokens' with 'right_binding_power', starting at position
-- 'index' in 'environment'.
local function parse (right_binding_power, tokens, index, env, override)
   local token = get_token(tokens, index)
   if token then
      last_token = token
      local nud, op, rbp = null_denotation(token, env)
      local lhs, new_index = nud(rbp, op, token, tokens, index + 1, env, override)
      token = get_token(tokens, new_index)
      local den, op, opspec, lbp = operator_specification(token, env, override)
      -- print("\nparse: ", new_index, op, lbp, right_binding_power)
      while (token and right_binding_power < lbp) do
	 if not den then
	    error("No denotation for " .. tostring(op) .. ".")
	 end
	 lhs, new_index = den(right_binding_power, op, lhs, token, 
			      tokens, new_index + 1, env, override)
	 token = get_token(tokens, new_index)
	 den, op, opspec, lbp = operator_specification(token, env, override)
      end
      return lhs, new_index
   else
      error("Cannot parse input starting at " .. 
	    error_position_string(index) .. ".", 2)
   end
end
pratt.parse = parse

local function parse_clauses_from_string (code, lexer, environment)
   lexer = lexer or lex.lexer
   environment = environment or pratt.default_environment
   local clauses = {}
   local tokens = lexer:match(code)
   local index = 1
   local result
   while tokens[index] do
      result, index = parse(0, tokens, index, environment, {})
      local next_token = get_token(tokens, index)
      if operator(next_token) == '.' then 
	 clauses[#clauses + 1] = result
	 index = index + 1
      elseif next_token then
	 error("Expected '.', received '" .. 
	       operator(next_token) ..
	       "' at position " .. tostring(next_token.pos) .. ".",
	      2)
      end
   end
   return clauses
end
pratt.parse_clauses_from_string = parse_clauses_from_string

local function parse_file (file_name, lexer, environment)
   local file = assert(io.open(file_name, 'r'),
		       "Cannot open file " .. file_name)
   local code = file:read("*all")
   return parse_clauses_from_string(code, lexer, environment)
end
pratt.parse_file = parse_file

--[[
utils = require 'utilities';
pratt = require 'pratt_parser';
print()
utils.print_table(pratt.parse_file('/Users/tc/Prog/Lua/Hacking/Poem/prolog_test.pl'))
--]]

local function prefix_op (rbp, op, token, tokens, index, env, override)
   local rhs, new_index = parse(rbp, tokens, index, env, override)
   return env.make_node{ op = op, rhs = rhs }, new_index
end
pratt.prefix_op = prefix_op

local function postfix_op (rbp, op, lhs, token, tokens, index, env, override)
   return env.make_node{ op = op, lhs = lhs }
end
pratt.postfix_op = postfix_op

local function infix_left (rbp, op, lhs, token, tokens, index, env, override)
   local den, op, opspec, lbp = operator_specification(token, env, override)
   local rhs, new_index = parse(lbp, tokens, index, env, override)
   return env.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_left = infix_left

local function infix_no (rbp, op, lhs, token, tokens, index, env, override)
   local den, op, opspec, lbp = operator_specification(token, env, override)
   local rhs, new_index = parse(lbp - 0.5, tokens, index, env, override)
   -- print("rhs: ", rhs.op, left_binding_power(rhs.op, env, override))
   -- print("op:  ", op, left_binding_power(op, env, override))
   if not rhs.delimited and 
      left_binding_power(rhs.op, env, override) == 
      left_binding_power(op, env, override) then
      error("Operator " .. tostring(op) .. " is not associative.")
   end
   return env.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_no = infix_no

local function infix_right (rbp, op, lhs, token, tokens, index, env, override)
   local den, op, opspec, lbp = operator_specification(token, env, override)
   local rhs, new_index = parse(lbp - 0.5, tokens, index, env, override)
   return env.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_right = infix_right

local function open_delimiter (end_delimiter)
   local function parse_delimiter_list (rbp, op, token, tokens, index, env, override)
      local arg, new_index = parse(0, tokens, index, env, {})
      local next_op = operator(get_token(tokens, new_index))
      if next_op ~= end_delimiter then
	 error("Expected " .. end_delimiter .. ", got " .. tostring(next_op))
      end
      arg.delimited = true
      return arg, new_index + 1
   end
   return parse_delimiter_list
end
pratt.open_delimiter = open_delimiter

local function is_arg_cons (cons)
   return cons and type(cons) == 'table' and cons[1] == 'cons-arg'
end
pratt.is_arg_cons = is_arg_cons

local function flatten_arg_cons (cons)
   local result = {}
   while is_arg_cons(cons) do
      result[#result + 1] = cons[2]
      cons = cons[3]
   end
   result[#result + 1] = cons
   return result
end
pratt.flatten_arg_cons = flatten_arg_cons

local function make_compound_term (functor, args, env)
   return env.make_node{ op = 'compound-term',
			 functor = functor,
			 args = args}
end
pratt.make_compound_term = make_compound_term

local function collect_arg (rbp, op, lhs, token, tokens, index, env, override)
   local next_op = operator(get_token(tokens, new_index))
   -- print("collect_arg: next_op = ", next_op)
   if next_op == ')' then
      return make_compound_term(lhs, {}, env), index
   end
   local arg, new_index = parse(0, tokens, index, env, override)
   -- print("collect_arg: arg = ", arg)
   return {'cons-arg', lhs, arg}, new_index
end
pratt.collect_arg = collect_arg

local function arglist (rbp, op, lhs, token, tokens, index, env, override)
   local new_override = { [','] = { left_binding_power = 100,
				    denotation = collect_arg }}
   local next_op = operator(get_token(tokens, index))
   if next_op == ')' then
      return make_compound_term(lhs, {}, env), index + 1
   end
   local args, new_index = parse(0, tokens, index, env, new_override)
   next_op = operator(get_token(tokens, new_index))
   if next_op ~= ')' then
      error("Expected ')', got " .. table_tostring(next_op) ..
	    " at " .. error_position_string(new_index))
   end
   args = flatten_arg_cons(args)
   return make_compound_term(lhs, args, env), new_index + 1
end
pratt.arglist = arglist

local function list_delimiter (rbp, op, token, tokens, index, env, override)
   local new_override = { [','] = { left_binding_power = 100,
				    denotation = collect_arg }}
   local next_op = operator(get_token(tokens, index))
   if next_op == ']' then
      return env.make_node{op = 'list', args = {}}
   end
   local args, new_index = parse(0, tokens, index, env, new_override)
   next_op = operator(get_token(tokens, new_index))
   local rest_arg = nil
   if next_op == '|' then
      rest_arg, new_index = parse(0, tokens, new_index + 1, env, {})
      next_op = operator(get_token(tokens, new_index))
   end 
   args = flatten_arg_cons(args)
   if next_op == ']' then
      return env.make_node{op = 'list', args = args, rest_arg = rest_arg},
      new_index + 1
   else
      error("Expected ]" .. ", got " .. tostring(next_op))
   end
end
pratt.list_delimiter = list_delimiter

-- These definitions should actually go into the Prolog parser.
local null_context = {
   null_context = null_context;
   ['(']        = { right_binding_power = 0,
		    denotation = open_delimiter(')') },
   ['[']        = { right_binding_power = 0,
		    denotation = list_delimiter }, 
   [':-']       = { right_binding_power = 100, 
		    denotation = prefix_op },
   ['?-']       = { right_binding_power = 100, 
		    denotation = prefix_op },
   ['-']        = { right_binding_power = 500,
		    denotation = prefix_op },
}

local left_context = {
   left_context = left_context;
   ['(']        = { left_binding_power = 10000,
		    denotation = arglist },
   [':-']       = { left_binding_power = 100,
		    denotation = infix_no },
   ['-->']      = { left_binding_power = 100,
		    denotation = infix_no },
   [';']        = { left_binding_power = 200,
		    denotation = infix_right,
		    replacement = 'or' },
   ['or']       = { left_binding_power = 200,
		    denotation = infix_right },
   ['->']       = { left_binding_power = 250,
		    denotation = infix_right,
		    replacement = 'implies' },
   ['implies']  = { left_binding_power = 250,
		    denotation = infix_right },
   [',']        = { left_binding_power = 300,
		    denotation = infix_right,
		    replacement = 'and'},
   ['and']      = { left_binding_power = 300,
		    denotation = infix_right },
   ['!']        =  { left_binding_power = 500,
		     denotation = postfix_op },
   ['<']        = { left_binding_power = 500,
		    denotation = infix_no },
   ['=<']       = { left_binding_power = 500,
		    denotation = infix_no },
   ['<']        = { left_binding_power = 500,
		    denotation = infix_no },
   ['<=']       = { left_binding_power = 500,
		    denotation = infix_no },
   ['is']       = { left_binding_power = 500,
		    denotation = infix_no },
   [':']        = { left_binding_power = 600,
		    denotation = infix_no },
   ['+']        = { left_binding_power = 700,
		    denotation = infix_left },
   ['-']        = { left_binding_power = 700,
		    denotation = infix_left },
   ['xor']      = { left_binding_power = 900,
		    denotation = infix_left },
   ['*']        = { left_binding_power = 900,
		    denotation = infix_left },
   ['/']        = { left_binding_power = 900,
		    denotation = infix_left },
   ['mod']      = { left_binding_power = 900,
		    denotation = infix_left },
   ['rem']      = { left_binding_power = 900,
		    denotation = infix_left },
   ['^']        = { left_binding_power = 1100,
		    denotation = infix_right },
}

local environment = { null_context = null_context,
		      left_context = left_context,
		      make_node = utils.make_node,
		      default_null_denotation = default_null_denotation,
		      default_left_denotation = default_left_denotation }
pratt.default_environment = environment
