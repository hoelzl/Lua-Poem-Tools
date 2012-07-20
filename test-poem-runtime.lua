-- Tests of the Poem runtime
--

module('test-poem-runtime', package.seeall)

local runtime = require 'poem-runtime'
local test = require 'lunatest'

local trail, clear_trail, push_to_trail = 
   runtime.trail, runtime.clear_trail, runtime.push_to_trail

function test_push_to_trail ()
   local length = #trail
   push_to_trail(1234)
   assert_equal(#trail, length + 1)
   assert_equal(trail[#trail], 1234)
end

function test_clear_trail ()
   for i = 1,100 do
      push_to_trail(i)
   end
   assert_gte(#trail, 100)
   clear_trail()
   assert_equal(#trail, 0)
end
