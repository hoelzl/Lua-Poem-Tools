local pp = require 'poem-parser'
local lpeg = require 'lpeg'

function print_parse_tree(parser, code)
   local result = parser:match(code);
   if result then
      print("Input: ", code)
      table.print(result)
      print()
   else
      error("Could not parse input " .. code)
   end
end

function test_atom_parser()
   local atom_parser_table = table.merge(pp.parser_table, { lpeg.V'atom' })
   -- table.print(atom_parser_table)
   local atom_parser = lpeg.P(atom_parser_table)
   print_parse_tree(atom_parser, "foo")
   print_parse_tree(atom_parser, "&*%$")
   print_parse_tree(atom_parser, "'foo bar baz'")
end

function test_binop_parser()
   local binop_parser_table = table.merge(pp.parser_table, { 
					     pp.node("binop", lpeg.V'binop') })
   -- table.print(binop_parser_table)
   local binop_parser = lpeg.P(binop_parser_table)
   print_parse_tree(binop_parser, "=")
   print_parse_tree(binop_parser, "@#$%")
   print_parse_tree(binop_parser, ",")
   print_parse_tree(binop_parser, "|")
   -- The followint two tests should fail
   --[[
   print_parse_tree(binop_parser, ":-")
   print_parse_tree(binop_parser, ".")
   ]]--
end


function test_strict_binop_parser()
   local binop_parser_table = table.merge(pp.parser_table, { 
					     pp.node("strict_binop", lpeg.V'strict_binop') })
   -- table.print(binop_parser_table)
   local binop_parser = lpeg.P(binop_parser_table)
   print_parse_tree(binop_parser, "=")
   print_parse_tree(binop_parser, "@#$%")
   print_parse_tree(binop_parser, "%")
   -- The following four tests should fail
   --[[
   print_parse_tree(binop_parser, ",")
   print_parse_tree(binop_parser, "|")
   print_parse_tree(binop_parser, ":-")
   print_parse_tree(binop_parser, ".")
   ]]--
end

function test_binop_term_list_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'binop_term_list' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, " + bar")
   print_parse_tree(term_parser, "* foo")
   print_parse_tree(term_parser, " + bar * foo")
   print_parse_tree(term_parser, ", bar, foo")
   -- This should fail
   --[[
   print_parse_tree(term_parser, ":- bar")
   ]]--
end

function test_strict_binop_term_list_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'strict_binop_term_list' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, " + bar")
   print_parse_tree(term_parser, "* foo")
   print_parse_tree(term_parser, " + bar * foo")
   -- This should fail
   --[[
   print_parse_tree(term_parser, "| foo")
   print_parse_tree(term_parser, ", bar, foo")
   print_parse_tree(term_parser, ":- bar")
   ]]--
end


function test_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "foo")
   print_parse_tree(term_parser, "foo()")
   print_parse_tree(term_parser, "foo(bar)")
   print_parse_tree(term_parser, "foo ( bar )")
   print_parse_tree(term_parser, "foo(bar, baz)")
   print_parse_tree(term_parser, "foo(bar, baz, 'and a complex atom', 1234)")
   print_parse_tree(term_parser, "'foo'()")
   print_parse_tree(term_parser, "'foo bar'()")
   print_parse_tree(term_parser, "'foo bar'(baz, $$$)")
   print_parse_tree(term_parser, "+(baz, $$$)")
end

function test_list_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "[]")
   print_parse_tree(term_parser, "[123]")
   print_parse_tree(term_parser, "[123, x, Y]")
   print_parse_tree(term_parser, "[X | Y]")
   print_parse_tree(term_parser, "[a, b, c | Y]")
end

function test_paren_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "(foo)")
   print_parse_tree(term_parser, "(foo(bar))")
   print_parse_tree(term_parser, "(17)")
   print_parse_tree(term_parser, "(17 + 4)")
   print_parse_tree(term_parser, "(foo(bar) + 17)")
   print_parse_tree(term_parser, "(foo(bar) + (a * +(2, 3)))")
end

function test_binop_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "foo + bar")
   print_parse_tree(term_parser, "foo + bar * baz")
   print_parse_tree(term_parser, "(foo + bar) * baz")
   print_parse_tree(term_parser, "foo + (bar * baz)")
   print_parse_tree(term_parser, "foo % (16 - 3 * f(5)) + (bar * baz)")
end


function test_clause_parser()
   local parser = pp.parser
   print_parse_tree(parser, "foo(bar, 1, x, 'atom with space').")
   print_parse_tree(parser, "'this is a constant'(applied, to, \"some terms\").")
   print_parse_tree(parser, "f([a, list, 17]).")
   print_parse_tree(parser, "g([ this ( is   (a, nested), term  ), inalist | withrestandwhitespace ]).")
   print_parse_tree(parser, "f(x,y) :- g(y, x), h(x, x); foo(bar), z(y).")
   print_parse_tree(parser, "f(x,y) :- g(y, x) and h(x, x) or foo(bar) and z(y).")
   print_parse_tree(parser, "f(x,y) :- g(y, x) & h(x, x) | foo(bar) &&&||||**** z(y).")
   print_parse_tree(parser, [[
     f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
     f(X,Y) :- g(X, X), h(X, Y), bar(foo).
     g(X,Y) :- asdf(X, Y).
   ]])
end
