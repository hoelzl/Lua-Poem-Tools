-- Some generally useful utilities.
--

-- lunatest chokes on this
-- require 'strict'
lunatest = require 'lunatest'

module('utilities', package.seeall)


-- Recursively print the contents of a table.
local function print_rec(thing, skip_newline, level)
   level = level or 4
   if (type(thing) == "table") then
      if level <= 0 then
	 io.write('...')
      else
	 io.write('{')
	 local sep = ''
	 for _,v in ipairs(thing) do
	    io.write(sep);
	    print_rec(v, true, level - 1);
	    sep = ', '
	 end
	 for k,v in pairs(thing) do
	    if (type(k) ~= 'number') then
	       io.write(sep, k, ' = ');
	       print_rec(v, true, level - 1);
	       sep = ', '
	    end
	 end
	 io.write('}')
      end
   else
      io.write(tostring(thing))
   end
   if (not skip_newline) then
      print()
   end
end
utilities.print_rec = print_rec

-- Generate a string containing the contents of a table.
local function table_tostring (thing, level)
   level = (type(level) == "number" and level) or 4
   if level <= 0 then
      return "..."
   end

   local result = {}
   local function push (item)
      result[#result + 1] = item
   end 
   if (type(thing) == "table") then
      push('{')
      local sep = ''
      for _,v in ipairs(thing) do
	 push(sep); push(table_tostring(v, level - 1));
	 sep = ', '
      end
      for k,v in pairs(thing) do
	 if (type(k) ~= 'number') then
	    push(sep); push(k); push(' = ');
	    push(table_tostring(v, level - 1));
	    sep = ', '
	 end
      end
      push('}')
      return table.concat(result)
   elseif type(thing) == "string" then
      return '"' .. thing .. '"'
   else
      return tostring(thing)
   end
end
utilities.table_tostring = table_tostring

-- Print a table in tabular form; print nestet tables with
-- print_rec
local function print_table(tab)
   if (type(tab) == 'table') then
      for k,v in pairs(tab) do
	 io.write(k, '\t -> ')
	 print_rec(v, true)
	 -- io.write('\ttype: ', type(v))
	 print()
      end
   else
      print(tab)
   end
end
utilities.print_table = print_table

-- Destructively merge several tables.  If elements are contained in
-- multiple tables, the rightmost one takes precedence.
local function merge_destructively (tab, ...)
   for _,t in ipairs{...} do
      for k,v in pairs(t) do
	 tab[k] = v
      end
   end
   return tab
end
utilities.merge_destructively = merge_destructively

-- Merge serveral tables into a new table. If elements are contained
-- in multiple tables, the rightmost one takes precedence.
local function merge (...)
   return merge_destructively({}, ...)
end
utilities.merge = merge

-- Cloning a table is the same as merging it non-destructively.
local clone = merge
utilities.clone = merge

-- Returns a slice of the table.  If 'end_index' is not present it
-- defaults to the length of the table.
local function slice (tab, start_index, end_index)
   local result = {}
   local n = #tab
   start_index = start_index or 1
   end_index = end_index or n

   if end_index < 0 then
      end_index = n + end_index + 1
   elseif end_index > n then
      end_index = n
   end

   -- FIXME: should deal with negative start indices
   if start_index < 1 or start_index > n then
      return {}
   end
   local k = 1
   for i = start_index, end_index do
      result[k] = tab[i]
      k = k + 1
   end
   return result
end
utilities.slice = slice

local function map (f, tab) 
   local result = {}
   for k, v in pairs(tab) do
      result[k] = f(v)
   end
   return result
end
utilities.map = map

-- Check whether the contents of two tables are equal.
local function equal (t1, t2)
   for k,v in pairs(t1) do
      if t2[k] ~= v then
	 -- print("table 1: ", k, v, "table 2:", k, t2[k])
	 return false
      end
   end
   for k,v in pairs(t2) do
      if t1[k] ~= v then
	 -- print("table 1: ", k, v, "table 2:", k, t2[k])
	 return false
      end
   end
   return true
end
utilities.equal = equal

-- A metatable that compares tables by element
local equality_metatable = {
   __eq = equal
}
utilities.equality_metatable = equality_metatable

-- Sets the metatable of 'tab' to one that has an __eq attribute which
-- compares by element.  Tries to disturb existing metatables as
-- little as possible.
local function set_equality_metatable (tab, error_if_present)
   if (type(tab) == "table") then
      local mt = getmetatable(tab)
      if mt then
	 if not mt.__eq then
	    mt.__eq = equal
	 elseif error_if_present then
	    error("Metatable for " ..
		  table_tostring(tab) ..
		  "already has an __eq field.")
	 end
      else
	 -- print("Setting metatable.")
	 setmetatable(tab, equality_metatable)
      end
   else
      error(tostring(tab) .. " is not a table.")
   end
   return tab
end
utilities.set_equality_metatable = set_equality_metatable

-- Utilities for the lexer/parser
--
local node_metatable = {
   __tostring = function (t)
      return utilities.table_tostring(t, 15)
   end,
   __eq = utilities.equal
}

-- Check whether the contents of two tables are similar.  We ignore
-- 'pos' fields and match variables with anything.  We don't try to
-- keep track of variable unifications, so this is a rather crude
-- test.
local function similar (t1, t2)
   for k,v in pairs(t1) do
      if k ~= 'pos' and t2[k] ~= v then
	 if type(t2[k]) ~= 'table' or t2[k].type ~= 'variable' then
	    -- print("table 1: ", k, v, "table 2:", k, t2[k])
	    return false
	 end
      end
   end
   for k,v in pairs(t2) do
      if k ~= 'pos' and t1[k] ~= v then
	 if type(t1[k]) ~= 'table' or t1[k].type ~= 'variable' then
	    -- print("table 1: ", k, v, "table 2:", k, t2[k])
	    return false
	 end
      end
   end
   return true
end
utilities.similar = similar

local similar_metatable = {
   __tostring = function (t)
      return utilities.table_tostring(t, 15)
   end,
   __eq = utilities.similar
}

local function set_node_metatable (node)
   if (type(node) == 'table') then
      setmetatable(node, node_metatable)
   else
      error(tostring(node) .. " is not a table.")
   end
   return node
end
utilities.set_node_metatable = set_node_metatable

local function set_node_metatable_recursively (node, mt)
   mt = mt or node_metatable
   if (type(node) == 'table') then
      setmetatable(node, mt)
      for _, n in pairs(node) do
	 set_node_metatable_recursively(n, mt)
      end
   end
   return node
end
utilities.set_node_metatable_recursively = set_node_metatable_recursively

local function make_node (tab)
   tab = tab or {}   
   return set_node_metatable(tab)
end
utilities.make_node = make_node

-- Utilities for testing
--
local function assert_table_equal (tab1, tab2, message)
   assert_true(equal(tab1, tab2), message)
end
utilities.assert_table_equal = assert_table_equal

local function assert_node (lexer, code, expected)
   -- Recursively set all metatables to ensure the correct comparison
   -- and to obtain a helpful printout if the test fails.
   local result = set_node_metatable_recursively(lexer:match(code))
   expected = set_node_metatable_recursively(expected)
   assert_equal(getmetatable(expected), getmetatable(result),
	       "Metatables do not match for " .. code .. ".")
   assert_equal(expected, result);
end
utilities.assert_node = assert_node

local function assert_parse_tree_equal (expected, result, code)
   code = code or expected
   set_node_metatable_recursively(expected)
   set_node_metatable_recursively(result)
   assert_equal(getmetatable(expected), getmetatable(result),
		"Metatables do not match for " .. table_tostring(code) .. ".")
   assert_equal(expected, result);
end
utilities.assert_parse_tree_equal = assert_parse_tree_equal

local function assert_parse_tree_similar (expected, result, code)
   code = code or expected
   set_node_metatable_recursively(expected, similar_metatable)
   set_node_metatable_recursively(result, similar_metatable)
   assert_equal(getmetatable(expected), getmetatable(result),
		"Metatables do not match for " .. table_tostring(code) .. ".")
   assert_equal(expected, result);
end
utilities.assert_parse_tree_similar = assert_parse_tree_similar