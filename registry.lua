-- A registry for Poem terms
--
local utils = require 'utilities'
local simp = require 'simplification'

local assert, ipairs, error, print, pairs, tostring, type = 
   assert, ipairs, error, print, pairs, tostring, type
local _G, io, table, string = _G, io, table, string

local table_tostring, print_table = 
   utils.table_tostring, utils.print_table

local extract_head_and_body = simp.extract_head_and_body

module('registry')

local reg = _G.registry

local predicate_table = {}
reg.predicate_table = predicate_table

local function clear_all_predicates ()
   predicate_table = {}
end
reg.clear_all_predicates = clear_all_predicates

local function clear_predicate (pred, arity)
   if arity then
      local pred_table = predicate_table[pred]
      if pred_table then
	 pred_table[arity] = nil
      end
   else
      pred_table[pred] = nil
   end
end
reg.clear_predicate = clear_predicate

local function register_predicate_head_and_body (functor, arity, head, body)
   assert(functor, "Cannot register empty predicate.")
   assert(arity, "Cannot register predicate with undetermined arity")
   assert(type(arity) == number,
	  "Cannot register predicate with non-numeric arity.")
   assert(head, "Cannot register empty head for predicate.")
   assert(body, "Cannot register empty body for predicate.")
   -- Maybe check that term has the given arity?
   local pred_table = predicate_table[functor]
   if not pred_table then
      pred_table = {}
      predicate_table[functor] = pred_table
   end
   local arity_table = pred_table[arity]
   if not arity_table then 
      arity_table = {}
      pred_table[arity] = arity_table
   end
   arity_table[#arity_table] = { head = head, body = body }
end
reg.register_predicate_head_and_body = register_predicate_head_and_body

local function simplify_and_register_clause (clause)
   local head, body = simplify_clause_head(clause)
   local functor = main_operator(head)
   local args = head.args
   local arity = #args
   register_predicate_head_and_body(functor, arity, head, body)
end
reg.simplify_and_register_clause = simplify_and_register_clause

local function get_clauses (functor, arity)
   local pred_table = predicate_table[functor] or {}
   return pred_table[arity]
end
reg.get_clauses = get_clauses
