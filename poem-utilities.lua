-- Some generally useful utilities.

-- Recursively print the contents of a table.
function table.print_rec(thing, skip_newline)
   if (type(thing) == "table") then
      io.write('{')
      local sep = ''
      for _,v in ipairs(thing) do
	 io.write(sep); table.print_rec(v, true);
	 sep = ', '
      end
      for k,v in pairs(thing) do
	 if (type(k) ~= 'number') then
	    io.write(sep, k, ' = '); table.print_rec(v, true);
	    sep = ', '
	 end
      end
      io.write('}')
   else
      io.write(tostring(thing))
   end
   if (not skip_newline) then
      print()
   end
end

-- Generate a string containing the contents of a table.
function table.tostring (thing)
   local result = {}
   local function push (item)
      result[#result + 1] = item
   end 
   if (type(thing) == "table") then
      push('{')
      local sep = ''
      for _,v in ipairs(thing) do
	 push(sep); push(table.tostring(v));
	 sep = ', '
      end
      for k,v in pairs(thing) do
	 if (type(k) ~= 'number') then
	    push(sep); push(k); push(' = '); push(table.tostring(v));
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


-- Print a table in tabular form; print nestet tables with
-- table.print_rec
function table.print(tab)
   if (type(tab) == 'table') then
      for k,v in pairs(tab) do
	 io.write(k, '\t -> ')
	 table.print_rec(v, true)
	 -- io.write('\ttype: ', type(v))
	 print()
      end
   else
      print(tab)
   end
end

-- Destructively merge several tables.  If elements are contained in
-- multiple tables, the rightmost one takes precedence.
function table.merge_destructively (tab, ...)
   for _,t in ipairs{...} do
      for k,v in pairs(t) do
	 tab[k] = v
      end
   end
   return tab
end

-- Merge serveral tables into a new table. If elements are contained
-- in multiple tables, the rightmost one takes precedence.
function table.merge (...)
   return table.merge_destructively({}, ...)
end

-- Check whether the contents of two tables are equal.
function table.equal (t1, t2)
   for k,v in pairs(t1) do
      if t2[k] ~= v then
	 print("table 1: ", k, v, "table 2:", k, t2[k])
	 return false
      end
   end
   for k,v in pairs(t2) do
      if t1[k] ~= v then
	 print("table 1: ", k, v, "table 2:", k, t2[k])
	 return false
      end
   end
   return true
end

function table.slice (tab, start_index, end_index)
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

function map (f, tab) 
   local result = {}
   for k, v in pairs(tab) do
      result[k] = f(v)
   end
   return result
end