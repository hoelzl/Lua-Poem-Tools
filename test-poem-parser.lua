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

function print_syntax_tree(parser, operators, code)
   local parse_tree = parser:match(code);
   if parse_tree then
      local syntax_tree = pp.build_syntax_tree(parse_tree, operators)
      if syntax_tree then
	 print("Input: ", code)
	 table.print(syntax_tree)
	 print()
      else
	 error("Could not obtain parse tree for " .. code)
      end
   else
      error("Could not parse input " .. code)
   end
end

function test_everything()
   test_atom_parser()
   test_operator_parser()
   test_term_list_parser()
   test_term_parser()
   test_list_term_parser()
   test_paren_term_parser()
   test_operator_term_parser()
   test_fact_parser()
   test_clause_parser()
   test_term_syntax()
   test_parenthesized_term_syntax()
   test_build_operator_tree()
   test_program_syntax()
end

function test_atom_parser()
   local atom_parser_table = table.merge(pp.parser_table, { lpeg.V'atom' })
   -- table.print(atom_parser_table)
   local atom_parser = lpeg.P(atom_parser_table)
   print_parse_tree(atom_parser, "foo")
   print_parse_tree(atom_parser, "fooBarBaz")
   print_parse_tree(atom_parser, "&*%$")
   print_parse_tree(atom_parser, "'foo Bar Baz'")
end

function test_operator_parser()
   local operator_parser_table = table.merge(pp.parser_table, { 
					     pp.node("operator", lpeg.V'atom_operator') })
   -- table.print(operator_parser_table)
   local operator_parser = lpeg.P(operator_parser_table)
   print_parse_tree(operator_parser, "=")
   print_parse_tree(operator_parser, "@#$%")
   print_parse_tree(operator_parser, "%")
   print_parse_tree(operator_parser, ",")
   print_parse_tree(operator_parser, "|")
   print_parse_tree(operator_parser, ":-")
   print_parse_tree(operator_parser, ".")
end

function test_term_list_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term_list' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "foo + bar, baz, Quux")
   print_parse_tree(term_parser, "BAR * Foo")
   print_parse_tree(term_parser, "-bar * Foo")
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
   print_parse_tree(term_parser, "foo(Bar, baz)")
   print_parse_tree(term_parser, "foo(bar, Baz, 'and a complex atom', 1234)")
   print_parse_tree(term_parser, "'foo'()")
   print_parse_tree(term_parser, "'foo bar'()")
   print_parse_tree(term_parser, "'foo bar'(Baz, $$$)")
   print_parse_tree(term_parser, "+(baz, $$$)")
end

function test_relaxed_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'relaxed_term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, " + - * / bar")
   print_parse_tree(term_parser, "* Foo ! ! !")
   print_parse_tree(term_parser, " + bar * -(-(-Foo))")
   print_parse_tree(term_parser, ", bar, Foo")
   -- This should fail
   --[[
   print_parse_tree(term_parser, ":- bar")
   ]]--
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
   print_parse_tree(term_parser, "(foo(bar) + (A * +(2, 3)))")
end

function test_operator_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   print_parse_tree(term_parser, "foo + bar")
   print_parse_tree(term_parser, "foo + bar * baz")
   print_parse_tree(term_parser, "(foo + bar) * baz")
   print_parse_tree(term_parser, "foo + (bar * baz)")
   print_parse_tree(term_parser, "foo % (16 - 3 * f(5)) + (bar * baz)")
   print_parse_tree(term_parser, "-bar")
   print_parse_tree(term_parser, "foo + -bar")
   print_parse_tree(term_parser, "+foo%")
   print_parse_tree(term_parser, "+foo% @ + -bar")
end


function test_fact_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'fact' })
   local parser = lpeg.P(term_parser_table)
   print_parse_tree(parser, "foo(bar, 1, x, 'atom with space').")
   print_parse_tree(parser, "'this is a constant'(applied, to, \"some terms\").")
   print_parse_tree(parser, "f([a, list, 17]).")
   print_parse_tree(parser, "g([ this ( is   (a, nested), term  ), in-a-list | with-rest-and-whitespace ]).")
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
   print_parse_tree(parser, "f(X) :- g(Y) =\\= g(Z) -> h(Z) xor h(true).")
end

function test_term_syntax()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   print_syntax_tree(parser, {}, "foo")
   print_syntax_tree(parser, {}, "fooBarBaz")
   print_syntax_tree(parser, {}, "%")
   print_syntax_tree(parser, {}, "''")
   print_syntax_tree(parser, {}, "'quoted atom'")
   print_syntax_tree(parser, {}, "123")
   print_syntax_tree(parser, {}, "123.456")
   print_syntax_tree(parser, {}, "-123.456")
   print_syntax_tree(parser, {}, "\"\"")
   print_syntax_tree(parser, {}, "\"This is a string!\"")
   -- Commands and sensing actions are currently not terms...
   -- print_syntax_tree(parser, {}, "foo!")
   -- print_syntax_tree(parser, {}, "foo?")
   print_syntax_tree(parser, {}, "Foo")
   print_syntax_tree(parser, {}, "FOO")
   print_syntax_tree(parser, {}, "_foo")
   print_syntax_tree(parser, {}, "_")
   print_syntax_tree(parser, {}, "foo()")
   print_syntax_tree(parser, {}, "foo(123, X, _y, _, z)")
   print_syntax_tree(parser, {}, "foo(g(X, h(y)))")
   print_syntax_tree(parser, {}, "[]")
   print_syntax_tree(parser, {}, "[Foo, 123]")
   print_syntax_tree(parser, {}, "[Foo, 123 | bar(X, Foo)]")
   print_syntax_tree(parser, {}, "[Foo, 123 | Bar]")
end

function test_parenthesized_term_syntax()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   print_syntax_tree(parser, {}, "(foo)")
   print_syntax_tree(parser, {}, "(fooBarBaz)")
   print_syntax_tree(parser, {}, "(%)")
   print_syntax_tree(parser, {}, "('')")
   print_syntax_tree(parser, {}, "('quoted atom')")
   print_syntax_tree(parser, {}, "(123)")
   print_syntax_tree(parser, {}, "(123.456)")
   print_syntax_tree(parser, {}, "(-123.456)")
   print_syntax_tree(parser, {}, "(\"\")")
   print_syntax_tree(parser, {}, "(\"This is a string!\")")
   -- Commands and sensing actions are currently not terms...
   -- print_syntax_tree(parser, {}, "foo!")
   -- print_syntax_tree(parser, {}, "foo?")
   print_syntax_tree(parser, {}, "(Foo)")
   print_syntax_tree(parser, {}, "(FOO)")
   print_syntax_tree(parser, {}, "(_foo)")
   print_syntax_tree(parser, {}, "(_)")
   print_syntax_tree(parser, {}, "(foo())")
   print_syntax_tree(parser, {}, "(foo(123, X, _y, _, z))")
   print_syntax_tree(parser, {}, "(foo(g(X, h(y))))")
   print_syntax_tree(parser, {}, "([])")
   print_syntax_tree(parser, {}, "([Foo, 123])")
   print_syntax_tree(parser, {}, "([Foo, 123 | bar(X, Foo)])")
   print_syntax_tree(parser, {}, "([Foo, 123 | Bar])")
   print_syntax_tree(parser, {}, "(((((foo())))))")
end

function test_build_operator_tree ()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   print_syntax_tree(parser, pp.operators, "A + B")
   print_syntax_tree(parser, pp.operators, "A + B * C + D")
   print_syntax_tree(parser, pp.operators, "A + B * C * D - E")
end

function test_program_syntax () 
   local parser = pp.parser
   print_syntax_tree(parser, pp.operators, "f(x).")
   print_syntax_tree(parser, pp.operators, "f(1 + 1, [a,b,c]).")
   print_syntax_tree(parser, pp.operators, [[
     f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
     f(X,Y) :- g(X, X), h(X, Y), bar(foo).
     g(X,Y) :- asdf(X, Y).
   ]])
   print_syntax_tree(parser, pp.operators,
		     "f(X) :- g(Y), g(Z) :- h(Y); h(Z).")
   print_syntax_tree(parser, pp.operators,
		     "f(X) :- g(Y) =\\= g(Z) -> h(Z) xor h(true).")
end