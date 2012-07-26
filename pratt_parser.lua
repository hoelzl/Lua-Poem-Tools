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

-- require 'strict'
local utils = require 'utilities'
local assert, error, print, tostring, type = 
   assert, error, print, tostring, type
local _G, io, table, string = _G, io, table, string

module('pratt_parser')

local pratt = _G.pratt_parser

local function operator (token, check_for_errors)
   if (check_for_errors == null) then check_for_errors = true end
   if type(token) ~= 'table' then
      if check_for_errors then
	 error("Token " .. tostring(token) .. " is not a table.")
      else
	 return token
      end
   end
   local op = token.name
   if not op then 
      if check_for_errors then
	 error("Can't determine operator of " .. 
	       utils.tostring(token) .. " at position " ..
	       token.pos .. ".")
      else
	 return token
      end
   end
   return op
end
pratt.operator = operator

local function null_context (environment)
   context = environment.null_context
   if not context then 
      error('No null context in environment ' .. environment .. '.')
   end
   return context
end
pratt.null_context = null_context

-- The default null denotation for tokens that are not operators
local function default_null_denotation (op, rbp, tokens, index, env, override)
   return environment.make_node(op)
end
pratt.default_null_denotation = default_null_denotation

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

-- Return the denotation , the (possibly replaced) operator, its
-- specification, and the left binding power for 'token' as multiple
-- values.
local function operator_specification (token, env, override)
   if not token then return nil, nil, nil, 0 end
   override = override or {}
   local op = operator(token)
   local opspec = override[op]
   if not opspec then
      local context = left_context(environment)
      opspec = context[op]
   end
   if not opspec then 
      return nil, op, nil, 0
   else
      return opspec.denotation,
             replacement_for(op, opspec),
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

-- Parse 'tokens' with 'right_binding_power', starting at position
-- 'index' in 'environment'.
local function parse (right_binding_power, tokens, index, env, override)
   local token = get_token(tokens, index)
   local nud, op, rbp = null_denotation(token, env)
   local lhs, new_index = nud(op, rbp, tokens, index + 1, env, override)
   token = get_token(tokens, new_index)
   local den, op, opspec, lbp = operator_specification(token, env, override)
   while (token and right_binding_power < lbp) do
      lhs, new_index = den(op, lhs, rbp, tokens, new_index, env, override)
      token = get_token(tokens, new_index)
      den, op, opspec, lbp = operator_specification(token, env, override)
   end
   return lhs, new_index
end
pratt.parse = parse

local function prefix_op (op, rbp, tokens, index, env, override)
   local rhs, new_index = parse(rbp, tokens, index, env, override)
   return environment.make_node{ op = op, rhs = rhs }, new_index
end
pratt.prefix_op = prefix_op

local function postfix_op (op, lhs, rbp, tokens, index, env, override)
   return environment.make_node{ op = op, lhs = lhs }
end
pratt.postfix_op = postfix_op

local function infix_left (op, lhs, rbp, tokens, index, env, override)
   local rhs, new_index = parse(rbp, tokens, index, env, override)
   return environment.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_left = infix_left

local function infix_no (op, lhs, rbp, tokens, index, env, override)
   local next_token = get_token(tokens, index)
   if left_binding_power(token) == rbp then
      error("Operator " .. tostring(op) .. " is not associative.")
   end
   local rhs, new_index = parse(rbp, tokens, index, env, override)
   return environment.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_no = infix_no

local function infix_right (op, lhs, rbp, tokens, index, env, override)
   local rhs, new_index = parse(rbp - 0.5, tokens, index, env, override)
   return environment.make_node{ op = op, lhs = lhs, rhs = rhs }, 
          new_index
end
pratt.infix_right = infix_right

local function open_delimiter (separator, end_delimiter)
   local function parse_delimiter_list (op, rbp, tokens, index, env, override)
      override = { [separator] = {}}
      local rhs, new_index = parse(rbp, tokens, index, env, override)
      local token = get_token(tokens, new_index)
      local new_op = operator(token)
      if  new_op ~= end_delimiter then
	 error("Found " .. new_op .. " when expecting " ..
	       end_delimiter .. ".")
      end
      return rhs, new_index + 1
   end
   return parse_delimiter_list
end
pratt.open_delimiter = open_delimiter

local function list_delimiter (separator, end_delimiter)
   local function parse_delimiter_list (op, rbp, tokens, index, env, override)
      override = { [','] = {}, ['|'] = {}}
      -- TODO: same code as parse_delimiter_list in open_delimiter
      local rhs, new_index = parse(rbp, tokens, index, env, override)
      local token = get_token(tokens, new_index)
      local new_op = operator(token)
      if  new_op ~= end_delimiter then
	 error("Found " .. new_op .. " when expecting " ..
	       end_delimiter .. ".")
      end
      return rhs, new_index + 1
   end
   return parse_delimiter_list
end
pratt.list_delimiter = list_delimiter


-- These definitions should actually go into the Prolog parser.
local null_context = {
   null_context = null_context;
   [':-']       = { left_binding_power = 100, 
		    denotation = prefix_op },
   ['?-']       = { left_binding_power = 100, 
		    denotation = prefix_op },
   ['(']        = { left_binding_power = 0,
		    denotation = open_delimiter(',', ')'),
		    separators = {','},
		    closing_delimiters = {')'}},
   ['[']        = { left_binding_power = 0,
		    denotation = list_delimiter },   
}

local left_context = {
   left_context = left_context;
   [':-']       = { left_binding_power = 0,
		    denotation = infix_no },
   ['-->']      = { left_binding_power = 0,
		    denotation = infix_no },
   [';']        = { left_binding_power = 100,
		    denotation = infix_right,
		    replacement = 'or' },
   ['or']       = { left_binding_power = 100,
		    denotation = infix_right },
   ['->']       = { left_binding_power = 150,
		    denotation = infix_right,
		    replacement = 'implies' },
   ['implies']  = { left_binding_power = 150,
		    denotation = infix_right },
   [',']        = { left_binding_power = 200,
		    denotation = infix_right,
		    replacement = 'and'},
   ['and']      = { left_binding_power = 200,
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
   ['xor']      = { left_binding_power = 700,
		    denotation = infix_left },
   ['*']        = { left_binding_power = 700,
		    denotation = infix_left },
   ['/']        = { left_binding_power = 700,
		    denotation = infix_left },
   ['mod']      = { left_binding_power = 700,
		    denotation = infix_left },
   ['rem']      = { left_binding_power = 700,
		    denotation = infix_left },
   ['^']        = { left_binding_power = 700,
		    denotation = infix_right },
}

local environment = { null_context = null_context,
		      left_context = left_context,
		      make_node = utils.make_node }
pratt.default_environment = environment
