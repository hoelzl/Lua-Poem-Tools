local runtime = require 'poem-runtime'
local unification = require 'poem-unification'
local test = require 'lunatest'

local make_variable = unification.make_variable
local unbound_value = unification.unbound_value
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
end

package.loaded['test-poem-unification'] = {}