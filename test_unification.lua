-- Tests of the unification algorithm

module('test_poem_unification', package.seeall)

local runtime = require 'poem_runtime'
local unification = require 'poem_unification'
local test = require 'lunatest'

local trail, clear_trail = runtime.trail, runtime.clear_trail

local make_variable = unification.make_variable
local unbound_value = unification.unbound_value
local set_binding, undo_bindings = 
   unification.set_binding, unification.undo_bindings
local is_variable, is_bound = unification.is_variable, unification.is_bound
local deref, unify = unification.deref, unification.unify

function test_make_variable ()
   local var = make_variable()
   assert_true(is_variable(var))
   assert_equal(var.binding, unbound_value())
   assert_number(var.name)
end 

function test_is_variable ()
   local var = make_variable()
   assert_true(is_variable(var))
   assert_false(is_variable(nil))
   assert_false(is_variable({}))
   assert_false(is_variable("foo"))
end

function test_set_binding_1 ()
   clear_trail()
   assert_true(0, #trail)
   local x = make_variable()
   -- Test that we cannot bind a variable to itself
   set_binding(x, x)
   assert_false(is_bound(x))
   assert_true(0, #trail)
   clear_trail()
end

function test_set_binding_2 ()
   clear_trail()
   assert_true(0, #trail)
   local x = make_variable()
   local y = make_variable()
   set_binding(x, y)
   assert_true(is_bound(x))
   assert_false(is_bound(y))
   assert_equal(x.binding, y)
   assert_true(1, #trail)
   clear_trail()
end

function test_variable_binding_1 ()
   clear_trail()
   assert_true(0, #trail)
   local x = make_variable()
   local y = { "unique" }
   set_binding(x, y)
   assert_true(is_bound(x))
   assert_equal(x.binding, y)
   assert_true(1, #trail)
   clear_trail()
end

function test_undo_bindings ()
   clear_trail()
   local vars = {}
   for i = 1,100 do
      local var = make_variable()
      vars[#vars + 1] = var
      set_binding(var, i)
   end
   assert_equal(#trail, 100)
   for k, v in pairs(trail) do
      assert_equal(v, vars[k], 
		   "Trail variable not equal to generated variable?")
      assert_true(is_bound(v),
		  "Trail variable is not bound?")
   end
   undo_bindings(80)
   assert_equal(#trail, 80)
   for k, v in pairs(trail) do
      assert_equal(v, vars[k])
      assert_true(is_bound(v))
   end
   for i = 81, 100 do
      assert_false(is_bound(vars[i]))
   end
   clear_trail()
end

function test_deref_1 ()
   local mv = make_variable
   local u, v, w, x, y, z = mv(), mv(), mv(), mv(), mv(), mv()
   set_binding(u, v)
   set_binding(v, w)
   set_binding(w, x)
   set_binding(x, y)
   set_binding(y, z)
   assert_equal(u.binding, v)
   assert_equal(v.binding, w)
   assert_false(is_bound(z))
   clear_trail()
end

function test_deref_2 ()
   local mv = make_variable
   local u, v, w, x, y, z = mv(), mv(), mv(), mv(), mv(), mv()
   set_binding(u, v)
   set_binding(v, w)
   set_binding(w, x)
   set_binding(x, y)
   set_binding(y, z)
   assert_equal(u.binding, v)
   assert_equal(v.binding, w)
   assert_false(is_bound(z))
   assert_equal(deref(u), z)
   assert_equal(u.binding, z)
   assert_equal(v.binding, w)
   assert_false(is_bound(z))
   clear_trail()
end

function test_deref_3 ()
   local mv = make_variable
   local u, v, w, x, y, z = mv(), mv(), mv(), mv(), mv(), mv()
   set_binding(u, v)
   set_binding(v, w)
   set_binding(w, x)
   set_binding(x, y)
   set_binding(y, z)
   assert_equal(u.binding, v)
   assert_equal(v.binding, w)
   assert_false(is_bound(z))
   assert_equal(deref(u), z)
   assert_equal(u.binding, z)
   assert_equal(v.binding, w)
   assert_false(is_bound(z))
   set_binding(z, 1)
   assert_true(is_bound(z))
   assert_equal(u.binding, z)
   assert_equal(deref(u), 1)
   assert_equal(u.binding, 1)
   clear_trail()
end

function test_unify_string ()
   assert_true(unify("", ""))
   assert_true(unify("asdf", "asdf"))
   assert_false(unify("asdf", "abcd"))
end

function test_unify_numbers ()
   assert_true(unify(1, 1))
   assert_false(unify(1, 2))
end

function test_unify_booleans ()
   assert_true(unify(true, true))   
   assert_true(unify(false, false))   
   assert_false(unify(true, false))   
   assert_false(unify(false, true))
end

function test_unify_vars_1 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()

   assert_true(unify(x, x))
   assert_true(unify(x, y))
   assert_true(unify(x, z))
   assert_true(unify(y, z))
end

function test_unify_vars_2 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()

   assert_true(unify(x, y))
   assert_true(unify(y, z))
   assert_true(unify(x, z))
end

function test_unify_vars_3 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()

   assert_true(unify(x, y))
   assert_true(unify(y, 1))
   assert_true(unify(z, 1))
   assert_true(unify(x, z))
   assert_true(unify(z, x))
   assert_true(unify(y, z))
end

function test_unify_vars_4 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()

   assert_true(unify(x, y))
   assert_true(unify(y, 1))
   assert_true(unify(z, 2))
   assert_true(unify(x, 1))
   assert_false(unify(x, z))
   assert_false(unify(z, x))
   assert_false(unify(y, z))
end

function test_unify_tables_1 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()
   
   local t1 = {x, y, z}
   local t2 = {1, 2}

   assert_true(unify(t1, t2))
   assert_equal(deref(x), 1)
   assert_equal(deref(y), 2)
   assert_equal(deref(z), nil)
end

function test_unify_tables_2 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()
   
   local t1 = {x, 2, z}
   local t2 = {1, y, 3}

   assert_true(unify(t1, t2))
   assert_equal(deref(x), 1)
   assert_equal(deref(y), 2)
   assert_equal(deref(z), 3)
end

function test_unify_tables_3 ()
   local x = make_variable()
   local y = make_variable()
   local z = make_variable()
   
   local t1 = {x, 2, z, 4}
   local t2 = {1, y, 3}

   assert_false(unify(t1, t2))
end
