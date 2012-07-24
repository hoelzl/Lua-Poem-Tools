-- Tests of the basic parser
--

module('test_basic_parser', package.seeall)

local lpeg = require 'lpeg'
local utils = require 'utilities'
local lex = require 'basic_lexer'
local bp = require 'basic_parser'
local test = require 'lunatest'

function assert_syntax_tree(lexer, operators, code, syntax_tree)
   local parse_tree = lexer:match(code);
   if parse_tree then
      local st = lex.build_syntax_tree(parse_tree, operators)
      if st then
	 -- Recursively set all metatables to ensure the correct comparison
	 lex.set_node_metatable_recursively(st)
	 assert_equal(lex.set_node_metatable_recursively(syntax_tree), st)
      else
	 assert_true(false, "Could not create syntax tree.")
      end
   else
      assert_true(false, "Could not parse input.")
   end
end

function test_term_syntax()
   local lexer_table = utils.merge(lex.lexer_table, { lpeg.V'term' })
   local lexer = lpeg.P(lexer_table)
   assert_syntax_tree(lexer, {}, "foo", {})
   assert_syntax_tree(lexer, {}, "fooBarBaz", {})
   assert_syntax_tree(lexer, {}, "%", {})
   assert_syntax_tree(lexer, {}, "''", {})
   assert_syntax_tree(lexer, {}, "'quoted atom'", {})
   assert_syntax_tree(lexer, {}, "123", {})
   assert_syntax_tree(lexer, {}, "123.456", {})
   assert_syntax_tree(lexer, {}, "-123.456", {})
   assert_syntax_tree(lexer, {}, "\"\"", {})
   assert_syntax_tree(lexer, {}, "\"This is a string!\"", {})
   -- Commands and sensing actions are currently not terms...
   -- assert_syntax_tree(lexer, {}, "foo!", {})
   -- assert_syntax_tree(lexer, {}, "foo?", {})
   assert_syntax_tree(lexer, {}, "Foo", {})
   assert_syntax_tree(lexer, {}, "FOO", {})
   assert_syntax_tree(lexer, {}, "_foo", {})
   assert_syntax_tree(lexer, {}, "_", {})
   assert_syntax_tree(lexer, {}, "foo()", {})
   assert_syntax_tree(lexer, {}, "foo(123, X, _y, _, z)", {})
   assert_syntax_tree(lexer, {}, "foo(g(X, h(y)))", {})
   assert_syntax_tree(lexer, {}, "[]", {})
   assert_syntax_tree(lexer, {}, "[Foo, 123]", {})
   assert_syntax_tree(lexer, {}, "[Foo, 123 | bar(X, Foo)]", {})
   assert_syntax_tree(lexer, {}, "[Foo, 123 | Bar]", {})
end

function test_parenthesized_term_syntax()
   local lexer_table = utils.merge(lex.lexer_table, { lpeg.V'term' })
   local lexer = lpeg.P(lexer_table)
   assert_syntax_tree(lexer, {}, "(foo)", {})
   assert_syntax_tree(lexer, {}, "(fooBarBaz)", {})
   assert_syntax_tree(lexer, {}, "(%)", {})
   assert_syntax_tree(lexer, {}, "('')", {})
   assert_syntax_tree(lexer, {}, "('quoted atom')", {})
   assert_syntax_tree(lexer, {}, "(123)", {})
   assert_syntax_tree(lexer, {}, "(123.456)", {})
   assert_syntax_tree(lexer, {}, "(-123.456)", {})
   assert_syntax_tree(lexer, {}, "(\"\")", {})
   assert_syntax_tree(lexer, {}, "(\"This is a string!\")", {})
   -- Commands and sensing actions are currently not terms...
   -- assert_syntax_tree(lexer, {}, "foo!", {})
   -- assert_syntax_tree(lexer, {}, "foo?", {})
   assert_syntax_tree(lexer, {}, "(Foo)", {})
   assert_syntax_tree(lexer, {}, "(FOO)", {})
   assert_syntax_tree(lexer, {}, "(_foo)", {})
   assert_syntax_tree(lexer, {}, "(_)", {})
   assert_syntax_tree(lexer, {}, "(foo())", {})
   assert_syntax_tree(lexer, {}, "(foo(123, X, _y, _, z))", {})
   assert_syntax_tree(lexer, {}, "(foo(g(X, h(y))))", {})
   assert_syntax_tree(lexer, {}, "([])", {})
   assert_syntax_tree(lexer, {}, "([Foo, 123])", {})
   assert_syntax_tree(lexer, {}, "([Foo, 123 | bar(X, Foo)])", {})
   assert_syntax_tree(lexer, {}, "([Foo, 123 | Bar])", {})
   assert_syntax_tree(lexer, {}, "(((((foo())))))", {})
end

function test_build_operator_tree ()
   local lexer_table = utils.merge(lex.lexer_table, { lpeg.V'term' })
   local lexer = lpeg.P(lexer_table)
   assert_syntax_tree(lexer, lex.operators, "A + B", {})
   assert_syntax_tree(lexer, lex.operators, "A + B * C + D", {})
   assert_syntax_tree(lexer, lex.operators, "A + B * C * D - E", {})
end

function test_program_syntax () 
   local lexer = lex.lexer
   assert_syntax_tree(lexer, lex.operators, "f(x).", {})
   assert_syntax_tree(lexer, lex.operators, "f(1 + 1, [a,b,c]).", {})
   assert_syntax_tree(lexer, 
		      lex.operators,
		      [[
			  f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
			  f(X,Y) :- g(X, X), h(X, Y), bar(foo).
			  g(X,Y) :- asdf(X, Y).
		       ]],
		      {})
   assert_syntax_tree(lexer, lex.operators,
		     "f(X) :- g(Y), g(Z) :- h(Y); h(Z).",
		     {})
   assert_syntax_tree(lexer, lex.operators,
		      "f(X) :- g(Y) =\\= g(Z) -> h(Z) xor h(true).",
		      {})
end