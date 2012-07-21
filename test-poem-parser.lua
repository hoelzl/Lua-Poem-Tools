-- Tests of the Poem parser
--

module('test-poem-parser', package.seeall)

local pp = require 'poem-parser'
local lpeg = require 'lpeg'
local test = require 'lunatest'

function assert_parse_tree(parser, code, parse_tree)
   -- Recursively set all metatables to ensure the correct comparison
   local result = pp.set_node_metatable_recursively(parser:match(code))
   parse_tree = pp.set_node_metatable_recursively(parse_tree)
   assert_equal(getmetatable(parse_tree), getmetatable(result),
	       "Metatables do not match.")
   assert_equal(parse_tree, result);
   return result
end

function assert_syntax_tree(parser, operators, code, syntax_tree)
   local parse_tree = parser:match(code);
   if parse_tree then
      local st = pp.build_syntax_tree(parse_tree, operators)
      if st then
	 -- Recursively set all metatables to ensure the correct comparison
	 pp.set_node_metatable_recursively(st)
	 assert_equal(pp.set_node_metatable_recursively(syntax_tree), st)
      else
	 assert_true(false, "Could not create syntax tree.")
      end
   else
      assert_true(false, "Could not parse input.")
   end
end

function test_atom_parser()
   local atom_parser_table = table.merge(pp.parser_table, { lpeg.V'atom' })
   -- table.print(atom_parser_table)
   local atom_parser = lpeg.P(atom_parser_table)
   assert_parse_tree(atom_parser, "foo",
		     {type = "atom", value = "foo"})
   assert_parse_tree(atom_parser, "fooBarBaz", 
		     {type = "atom", value = "fooBarBaz"})
   assert_parse_tree(atom_parser, "&*%$", 
		     {type = "atom", value = "&*%$"})
   assert_parse_tree(atom_parser, "'foo Bar Baz'", 
		     {type = "atom", value = "foo Bar Baz"})
end

function test_operator_parser()
   local operator_parser_table = table.merge(pp.parser_table, { 
					     pp.node("operator", lpeg.V'atom_operator') })
   -- table.print(operator_parser_table)
   local operator_parser = lpeg.P(operator_parser_table)
   assert_parse_tree(operator_parser, "=", 
		     { type = "operator", value = "=" })
   assert_parse_tree(operator_parser, "@#$%", 
		     { type = "operator", value = "@#$%" })
   assert_parse_tree(operator_parser, "%",
		     { type = "operator", value = "%" })
   assert_parse_tree(operator_parser, ",",
		     { type = "operator", value = "," })
   assert_parse_tree(operator_parser, "|",
		     { type = "operator", value = "|" })
   assert_parse_tree(operator_parser, ":-",
		     { type = "operator", value = ":-" })
   assert_parse_tree(operator_parser, ".",
		     { type = "operator", value = "." })
end

function test_term_list_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term_list' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   assert_parse_tree(term_parser, "foo + bar, baz, Quux",
		     {type = "sequence_term", 
		      elements = {{type = "atom", value = "foo"},
				  {type = "atom", value = "+"},
				  {type = "atom", value = "bar"},
				  {type = "atom", value = ","},
				  {type = "atom", value = "baz"},
				  {type = "atom", value = ","},
				  {type = "variable", value = "Quux"}}})
   assert_parse_tree(term_parser, "BAR * Foo", {})
   assert_parse_tree(term_parser, "-bar * Foo", {})
end


function test_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   assert_parse_tree(term_parser, "foo", {})
   assert_parse_tree(term_parser, "foo()", {})
   assert_parse_tree(term_parser, "foo(bar)", {})
   assert_parse_tree(term_parser, "foo ( bar )", {})
   assert_parse_tree(term_parser, "foo(Bar, baz)", {})
   assert_parse_tree(term_parser, "foo(bar, Baz, 'and a complex atom', 1234)", {})
   assert_parse_tree(term_parser, "'foo'()", {})
   assert_parse_tree(term_parser, "'foo bar'()", {})
   assert_parse_tree(term_parser, "'foo bar'(Baz, $$$)", {})
   assert_parse_tree(term_parser, "+(baz, $$$)", {})
   assert_parse_tree(term_parser, "\\+(baz, $$$)", {})
   assert_parse_tree(term_parser, "foo(g(X, h(y)))", {})
end

-- function test_relaxed_term_parser()
--    local term_parser_table = table.merge(pp.parser_table, { lpeg.V'relaxed_term' })
--    -- table.print(term_parser_table)
--    local term_parser = lpeg.P(term_parser_table)
--    assert_parse_tree(term_parser, " + - * / bar", {})
--    assert_parse_tree(term_parser, "* Foo ! ! !", {})
--    assert_parse_tree(term_parser, " + bar * -(-(-Foo))", {})
--    assert_parse_tree(term_parser, ", bar, Foo", {})
--    -- This should fail
--    --[[
--    assert_parse_tree(term_parser, ":- bar", {})
--    ]]--
-- end

function test_list_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   assert_parse_tree(term_parser, "[]", {})
   assert_parse_tree(term_parser, "[123]", {})
   assert_parse_tree(term_parser, "[x, y, Z]", {})
   -- FIXME: This fails
   -- assert_parse_tree(term_parser, "[123, y, Z]", {})
   assert_parse_tree(term_parser, "[X | Y]", {})
   assert_parse_tree(term_parser, "[a, b, c | Y]", {})
end

function test_paren_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   assert_parse_tree(term_parser, "(foo)", {})
   assert_parse_tree(term_parser, "(foo(bar))", {})
   assert_parse_tree(term_parser, "(17)", {})
   assert_parse_tree(term_parser, "(17 + 4)", {})
   assert_parse_tree(term_parser, "(foo(bar) + 17)", {})
   assert_parse_tree(term_parser, "\\+(2, 3)", {})
   assert_parse_tree(term_parser, "(\\+(2, 3))", {})
   assert_parse_tree(term_parser, "((A * \\+(2, 3)))", {})
   assert_parse_tree(term_parser, "(foo(bar) + (A * \\+(2, 3)))", {})
end

function test_operator_term_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   -- table.print(term_parser_table)
   local term_parser = lpeg.P(term_parser_table)
   assert_parse_tree(term_parser, "foo + bar",
		     {type = "sequence_term",
		      elements = {{type = "atom", value = "foo"}, 
				  {type = "atom", value = "+"},
				  {type = "atom", value = "bar"}}})
   assert_parse_tree(term_parser, "foo + bar * baz", {})
   assert_parse_tree(term_parser, "(foo + bar) * baz", {})
   assert_parse_tree(term_parser, "foo + (bar * baz)", {})
   assert_parse_tree(term_parser, "foo % (16 - 3 * f(5)) + (bar * baz)", {})
   assert_parse_tree(term_parser, "-bar", {})
   assert_parse_tree(term_parser, "foo + -bar", {})
   assert_parse_tree(term_parser, "+foo%", {})
   assert_parse_tree(term_parser, "+foo% @ + -bar", {})
end


function test_fact_parser()
   local term_parser_table = table.merge(pp.parser_table, { lpeg.V'fact' })
   local parser = lpeg.P(term_parser_table)
   assert_parse_tree(parser, "foo(bar, 1, x, 'atom with space').", {})
   assert_parse_tree(parser, "'this is a constant'(applied, to, \"some terms\").", {})
   assert_parse_tree(parser, "f([a, list, 17]).", {})
   assert_parse_tree(parser, "g([ this ( is   (a, nested), term  ), in-a-list | with-rest-and-whitespace ]).", {})
end


function test_clause_parser()
   local parser = pp.parser
   assert_parse_tree(parser, "foo(bar, 1, x, 'atom with space').", {})
   assert_parse_tree(parser, "'this is a constant'(applied, to, \"some terms\").", {})
   assert_parse_tree(parser, "f([a, list, 17]).", {})
   assert_parse_tree(parser, "g([ this ( is   (a, nested), term  ), inalist | withrestandwhitespace ]).", {})
   assert_parse_tree(parser, "f(x,y) :- g(y, x), h(x, x); foo(bar), z(y).", {})

   assert_parse_tree(parser, "f(x,y) :- g(y, x) and h(x, x) or foo(bar) and z(y).", {})
   assert_parse_tree(parser, "f(x,y) :- g(y, x) & h(x, x) | foo(bar) &&&||||**** z(y).", {})
   print_parse_tree(parser, [[
     f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
     f(X,Y) :- g(X, X), h(X, Y), bar(foo).
     g(X,Y) :- asdf(X, Y).
   ]])
   assert_parse_tree(parser, "f(X) :- g(Y) =\\= g(Z) -> h(Z) xor h(true).", {})
end

function test_term_syntax()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   assert_syntax_tree(parser, {}, "foo", {})
   assert_syntax_tree(parser, {}, "fooBarBaz", {})
   assert_syntax_tree(parser, {}, "%", {})
   assert_syntax_tree(parser, {}, "''", {})
   assert_syntax_tree(parser, {}, "'quoted atom'", {})
   assert_syntax_tree(parser, {}, "123", {})
   assert_syntax_tree(parser, {}, "123.456", {})
   assert_syntax_tree(parser, {}, "-123.456", {})
   assert_syntax_tree(parser, {}, "\"\"", {})
   assert_syntax_tree(parser, {}, "\"This is a string!\"", {})
   -- Commands and sensing actions are currently not terms...
   -- assert_syntax_tree(parser, {}, "foo!", {})
   -- assert_syntax_tree(parser, {}, "foo?", {})
   assert_syntax_tree(parser, {}, "Foo", {})
   assert_syntax_tree(parser, {}, "FOO", {})
   assert_syntax_tree(parser, {}, "_foo", {})
   assert_syntax_tree(parser, {}, "_", {})
   assert_syntax_tree(parser, {}, "foo()", {})
   assert_syntax_tree(parser, {}, "foo(123, X, _y, _, z)", {})
   assert_syntax_tree(parser, {}, "foo(g(X, h(y)))", {})
   assert_syntax_tree(parser, {}, "[]", {})
   assert_syntax_tree(parser, {}, "[Foo, 123]", {})
   assert_syntax_tree(parser, {}, "[Foo, 123 | bar(X, Foo)]", {})
   assert_syntax_tree(parser, {}, "[Foo, 123 | Bar]", {})
end

function test_parenthesized_term_syntax()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   assert_syntax_tree(parser, {}, "(foo)", {})
   assert_syntax_tree(parser, {}, "(fooBarBaz)", {})
   assert_syntax_tree(parser, {}, "(%)", {})
   assert_syntax_tree(parser, {}, "('')", {})
   assert_syntax_tree(parser, {}, "('quoted atom')", {})
   assert_syntax_tree(parser, {}, "(123)", {})
   assert_syntax_tree(parser, {}, "(123.456)", {})
   assert_syntax_tree(parser, {}, "(-123.456)", {})
   assert_syntax_tree(parser, {}, "(\"\")", {})
   assert_syntax_tree(parser, {}, "(\"This is a string!\")", {})
   -- Commands and sensing actions are currently not terms...
   -- assert_syntax_tree(parser, {}, "foo!", {})
   -- assert_syntax_tree(parser, {}, "foo?", {})
   assert_syntax_tree(parser, {}, "(Foo)", {})
   assert_syntax_tree(parser, {}, "(FOO)", {})
   assert_syntax_tree(parser, {}, "(_foo)", {})
   assert_syntax_tree(parser, {}, "(_)", {})
   assert_syntax_tree(parser, {}, "(foo())", {})
   assert_syntax_tree(parser, {}, "(foo(123, X, _y, _, z))", {})
   assert_syntax_tree(parser, {}, "(foo(g(X, h(y))))", {})
   assert_syntax_tree(parser, {}, "([])", {})
   assert_syntax_tree(parser, {}, "([Foo, 123])", {})
   assert_syntax_tree(parser, {}, "([Foo, 123 | bar(X, Foo)])", {})
   assert_syntax_tree(parser, {}, "([Foo, 123 | Bar])", {})
   assert_syntax_tree(parser, {}, "(((((foo())))))", {})
end

function test_build_operator_tree ()
   local parser_table = table.merge(pp.parser_table, { lpeg.V'term' })
   local parser = lpeg.P(parser_table)
   assert_syntax_tree(parser, pp.operators, "A + B", {})
   assert_syntax_tree(parser, pp.operators, "A + B * C + D", {})
   assert_syntax_tree(parser, pp.operators, "A + B * C * D - E", {})
end

function test_program_syntax () 
   local parser = pp.parser
   assert_syntax_tree(parser, pp.operators, "f(x).", {})
   assert_syntax_tree(parser, pp.operators, "f(1 + 1, [a,b,c]).", {})
   assert_syntax_tree(parser, 
		      pp.operators,
		      [[
			  f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
			  f(X,Y) :- g(X, X), h(X, Y), bar(foo).
			  g(X,Y) :- asdf(X, Y).
		       ]],
		      {})
   assert_syntax_tree(parser, pp.operators,
		     "f(X) :- g(Y), g(Z) :- h(Y); h(Z).",
		     {})
   assert_syntax_tree(parser, pp.operators,
		      "f(X) :- g(Y) =\\= g(Z) -> h(Z) xor h(true).",
		      {})
end