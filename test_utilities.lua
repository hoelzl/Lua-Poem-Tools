-- Tests of the basic plexer
--

module('test_utilities', package.seeall)

local utils = require 'utilities'
local test = require 'lunatest'

local assert_table_equal = utils.assert_table_equal
local set_equality_metatable = utils.set_equality_metatable
local equality_metatable = utils.equality_metatable

function test_set_equality_metatable_01 ()
   local expected = {}
   local value = {}
   assert_not_equal(expected, value)
   set_equality_metatable(expected)
   set_equality_metatable(value)
   assert_equal(equality_metatable, getmetatable(expected))
   assert_equal(equality_metatable, getmetatable(value))
   assert_equal(expected, value)
end

function test_set_equality_metatable_02 ()
   local expected = {1, 2, 3}
   local value = {1, 2, 3}
   assert_not_equal(expected, value)
   set_equality_metatable(expected)
   set_equality_metatable(value)
   assert_equal(equality_metatable, getmetatable(expected))
   assert_equal(equality_metatable, getmetatable(value))
   assert_equal(expected, value)
end

function test_set_equality_metatable_03 ()
   local expected = {}
   local value = {}
   local mt = {}
   assert_not_equal(equality_metatable, mt)
   setmetatable(expected, mt)
   setmetatable(value, mt)
   assert_not_equal(expected, value)
   assert_equal(mt, getmetatable(expected))
   assert_equal(mt, getmetatable(value))

   set_equality_metatable(expected)
   set_equality_metatable(value)

   local expected_mt = getmetatable(expected)
   local value_mt = getmetatable(value)
   assert_not_equal(equality_metatable, mt)
   assert_equal(mt, expected_mt)
   assert_equal(mt, value_mt)
   assert_equal(expected, value)
end

function test_assert_table_equal ()
   assert_table_equal({}, {})
   assert_table_equal({1,2,3}, {1,2,3})
   assert_error(function ()
		   assert_table_equal({1,2}, {1,2,3})
		end)
   assert_error(function ()
		   assert_table_equal({}, {1,2,3})
		end)
   assert_error(function ()
		   assert_table_equal({1,2}, {})
		end)
end

local function add1 (value)
   return value + 1
end

function test_map ()
   assert_table_equal({}, utils.map(add1, {}))
   assert_table_equal({2,3,4}, utils.map(add1, {1,2,3}))
end

function test_similar ()
   -- TODO: Write tests
end