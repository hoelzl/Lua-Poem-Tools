-- An implementation of destructive unification
--

local utils = require 'poem-utilities'
local runtime = require 'poem-runtime'

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
   return x and x.type == 'variable'
end
unification.is_variable = is_variable

local function is_bound (x)
   return x and x.binding ~= unbound
end
unification.is_bound = is_bound

local function deref (x)
   while is_variable(x) and is_bound(x) do
      x = x.binding
   end
   return x
end
unification.deref = deref

local function unify (x, y)
   x = deref(x)
   y = deref(y)
   if x == y then
      return true
   elseif is_variable(x) then
      x.binding = y
   elseif is_variable(y) then
      y.binding = x
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
   else
      return false
   end
end
unification.unify = unify

package.loaded['poem-unification'] = unification