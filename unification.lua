-- An implementation of destructive unification
--

module('unification', package.seeall)

local utils = require 'utilities'
local runtime = require 'poem_runtime'

local unification = {}
local trail = runtime.trail

local unbound = {'unbound'}

local variable_counter = 1

local function unbound_value ()
   return unbound
end
unification.unbound_value = unbound_value

local function make_variable (name)
   if not name then
      name = variable_counter
      variable_counter = variable_counter + 1
   end
   return { type = 'variable',
	    name = name,
	    binding = unbound }
end
unification.make_variable = make_variable

local function is_variable (x)
   return x and type(x) == 'table' and x.type == 'variable'
end
unification.is_variable = is_variable

local function is_bound (x)
   return x.binding ~= unbound
end
unification.is_bound = is_bound

local function deref (x)
   -- Shorten variable-variable bindings
   local result = x
   while is_variable(result) and is_bound(result) do
      result = result.binding
      x.binding = result
   end
   return result
end
unification.deref = deref

local function set_binding (var, value)
   if var ~= value then
      trail[#trail + 1] = var
      var.binding = value
   end
end
unification.set_binding = set_binding

local function undo_bindings (level)
   local trail_level = #trail
   while trail_level > level do
      local var = trail[trail_level]
      var.binding = unbound
      trail[trail_level] = nil
      trail_level = trail_level - 1
   end
end
unification.undo_bindings = undo_bindings

local function unify (x, y)
   x = deref(x)
   y = deref(y)
   if x == y then
      return true
   elseif is_variable(x) then
      set_binding(x, y)
      return true
   elseif is_variable(y) then
      set_binding(y, x)
      return true
   elseif type(x) == 'table' and type(y) == 'table' then
      for k, v in pairs(x) do
	 if not unify(v, y[k]) then
	    return false
	 end
      end
      for k, v in pairs(y) do
	 if not unify(v, x[k]) then
	    return false
	 end
      end
      return true
   else
      return false
   end
end
unification.unify = unify

package.loaded['poem-unification'] = unification