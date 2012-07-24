-- Tests of the basic lexer
--
module('test_basic_lexer', package.seeall)

local utils = require 'utilities'
local lex = require 'basic_lexer'
local test = require 'lunatest'

function assert_node(lexer, code, parse_tree)
   -- Recursively set all metatables to ensure the correct comparison
   local result = lex.set_node_metatable_recursively(lexer:match(code))
   parse_tree = lex.set_node_metatable_recursively(parse_tree)
   assert_equal(getmetatable(parse_tree), getmetatable(result),
	       "Metatables do not match for " .. code .. ".")
   assert_equal(parse_tree, result);
   return result
end

function test_atom_lexer()
   local atom_lexer = lex.make_lexer('atom')
   assert_node(atom_lexer, "foo",
	       {type = "atom", pos = 1, name = "foo"})
   assert_node(atom_lexer, "fooBarBaz", 
	       {type = "atom", pos = 1, name = "fooBarBaz"})
   assert_node(atom_lexer, "&*",
	       {type = "atom", pos = 1, name = "&*"})
   assert_node(atom_lexer, "&*%$",
	       {type = "atom", pos = 1, name = "&*%$"})
   assert_node(atom_lexer, "'foo Bar Baz'", 
	       {type = "atom", pos = 1, name = "foo Bar Baz"})
end
 
function test_atom_operator_lexer ()
   local operator_lexer = lex.make_lexer('atom_operator')
   assert_node(operator_lexer, "=", 
	       { type = "atom", pos = 1, name = "=" })
   assert_node(operator_lexer, "@#$%", 
	       { type = "atom", pos = 1, name = "@#$%" })
   assert_node(operator_lexer, "%",
	       { type = "atom", pos = 1, name = "%" })
   assert_node(operator_lexer, ",",
	       { type = "atom", pos = 1, name = "," })
   assert_node(operator_lexer, "|",
	       { type = "atom", pos = 1, name = "|" })
   assert_node(operator_lexer, ":-",
	       { type = "atom", pos = 1, name = ":-" })
   assert_node(operator_lexer, ".",
	       { type = "atom", pos = 1, name = "." })
end

function test_term_lexer_1 ()
   local term_lexer = lex.make_lexer('term')
   assert_node(term_lexer, "foo", {type = "atom", pos = 1, name = "foo"})
   assert_node(term_lexer, "foo()", 
	       {type = "compound_term",
		pos = 1, 
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {}})
   assert_node(term_lexer, "foo(bar)",
	       {type = "compound_term",
		pos = 1, 
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {{type = "atom", pos = 5, name = "bar"}}})
   assert_node(term_lexer, "foo ( bar )", 
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {{type = "atom", pos = 7, name = "bar"}}})
   assert_node(term_lexer, "foo(Bar, baz)",
	       {type = "compound_term", 
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {{type = "variable", pos = 5, name = "Bar"},
			     {type = "atom", pos = 10, name = "baz"}}})
   assert_node(term_lexer, "foo(bar, Baz, 'and a complex atom', 1234)",
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {{type = "atom", pos = 5, name = "bar"},
			     {type = "variable", pos = 10, name = "Baz"},
			     {type = "atom", pos = 15, name = "and a complex atom"},
			     {type = "number", pos = 37, name = "1234"}}})
   assert_node(term_lexer, "'foo'()",
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {}})
   assert_node(term_lexer, "'foo bar'()",
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo bar"},
		arguments = {}})
   assert_node(term_lexer, "'foo bar'(Baz, $$$)",
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo bar"},
		arguments = {{type = "variable", pos = 11, name = "Baz"},
			     {type = "atom", pos = 16, name = "$$$"}}})
   assert_node(term_lexer, "+(baz, $$$)",
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "+"},
		arguments = {{type = "atom", pos = 3, name = "baz"},
			     {type = "atom", pos = 8, name = "$$$"}}})
   assert_node(term_lexer, "\\+(baz, $$$)", 
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 2, name = "+"},
		arguments = {{type = "atom", pos = 4, name = "baz"},
			     {type = "atom", pos = 9, name = "$$$"}}})
   assert_node(term_lexer, "foo(g(X, h(y)))", 
	       {type = "compound_term",
		pos = 1,
		functor = {type = "atom", pos = 1, name = "foo"},
		arguments = {
		   {type = "compound_term",
		    pos = 5,
		    functor = {type = "atom", pos = 5, name = "g"},
		    arguments = {
		       {type = "variable", pos = 7, name = "X"},
		       {type = "compound_term",
			pos = 10,
			functor = {type = "atom", pos = 10, name = "h"},
			arguments = {{type = "atom", pos = 12, name = "y"}}}}}}})
end

function test_term_lexer_2 ()
   local term_lexer = lex.make_lexer('term')
   assert_node(term_lexer, " + - * / bar", 
	       {type = "sequence_term",
		pos = 1,
		elements = {{type = "atom", pos = 2, name = "+"},
			    {type = "atom", pos = 4, name = "-"},
			    {type = "atom", pos = 6, name = "*"},
			    {type = "atom", pos = 8, name = "/"},
			    {type = "atom", pos = 10, name = "bar"}}})
   assert_node(term_lexer, "* Foo ! ! !",
	       {type = "sequence_term",
		pos = 1, 
		elements = {{type = "atom", pos = 1, name = "*"},
			    {type = "variable", pos = 3, name = "Foo"},
			    {type = "atom", pos = 7, name = "!"},
			    {type = "atom", pos = 9, name = "!"},
			    {type = "atom", pos = 11, name = "!"}}})
   assert_node(term_lexer, "+ bar * -(-(-Foo))",
	       {type = "sequence_term",
		pos = 1,
		elements = {
		   {type = "atom", pos = 1, name = "+"},
		   {type = "atom", pos = 3, name = "bar"},
		   {type = "atom", pos = 7, name = "*"},
		   {type = "compound_term",
		    pos = 9,
		    functor = {type = "atom", pos = 9, name = "-"},
		    arguments = {
		       {type = "compound_term",
			pos = 11,
			functor = {type = "atom", pos = 11, name = "-"}, 
			arguments = {{type = "sequence_term",
				      pos = 13,
				      elements = {
					 {type = "atom", pos = 13, name = "-"},
					 {type = "variable", pos = 14,
					  name = "Foo"}}}}}}}}})
   assert_node(term_lexer, ", bar, Foo",
	       {type = "sequence_term",
		pos = 1,
		elements = {{type = "atom", pos = 1, name = ","},
			    {type = "atom", pos = 3, name = "bar"},
			    {type = "atom", pos = 6, name = ","},
			    {type = "variable", pos = 8, name = "Foo"}}})
end

function test_list_term_lexer()
   local term_lexer = lex.make_lexer('term')
   assert_node(term_lexer, "[]", {type = "list", pos = 2, elements = {}})
   assert_node(term_lexer, "[123]",
	       {type = "list", pos = 2,
		elements = {{type = "number", pos = 2, name = "123"}}})
   assert_node(term_lexer, "[x, y, Z]", 
	       {type = "list", pos = 2, 
		elements = {{type = "atom", pos = 2, name = "x"},
			    {type = "atom", pos = 5, name = "y"},
			    {type = "variable", pos = 8, name = "Z"}}})
   assert_node(term_lexer, "[123, y, Z]", 
	       {type = "list", pos = 2,
		elements = {{type = "number", pos = 2, name = "123"},
			    {type = "atom", pos = 7, name = "y"},
			    {type = "variable", pos = 10, name = "Z"}}})
   assert_node(term_lexer, "[X | Y]",
	       {type = "improper_list", pos = 2,
		elements = {{type = "variable", pos = 2, name = "X"}},
		tail = {type = "variable", pos = 6, name = "Y"}})
   assert_node(term_lexer, "[a, 123, b | Y]", 
	       {type = "improper_list", pos = 2,
		elements = {{type = "atom", pos = 2, name = "a"},
			    {type = "number", pos = 5, name = "123"},
			    {type = "atom", pos = 10, name = "b"}},
		tail = {type = "variable", pos = 14, name = "Y"}})
end

function test_paren_term_lexer()
   local term_lexer = lex.make_lexer('term')
   assert_node(term_lexer, "(foo)",
	       {type = "paren_term", pos = 2,
		value = {type = "atom", pos = 2, name = "foo"}})
   assert_node(term_lexer, "(foo(bar))",
	       {type = "paren_term", pos = 2,
		value = {type = "compound_term", pos = 2,
			 functor = {type = "atom", pos = 2, name = "foo"},
			 arguments = {{type = "atom", pos = 6, name = "bar"}}}})
   assert_node(term_lexer, "(17)", 
	       {type = "paren_term", pos = 2, 
		value = {type = "number", pos = 2, name = "17"}})
   assert_node(term_lexer, "(17 + 4)", 
	       {type = "paren_term", pos = 2,
		value = {type = "sequence_term", pos = 2,
			 elements = {{type = "number", pos = 2, name = "17"},
				     {type = "atom", pos = 5, name = "+"},
				     {type = "number", pos = 7, name = "4"}}}})
   assert_node(term_lexer, "(foo(bar) + 17)",
	       {type = "paren_term", pos = 2,
		value = {type = "sequence_term", pos = 2,
			 elements = {
			    {type = "compound_term", pos = 2,
			     functor = {type = "atom", pos = 2, name = "foo"},
			     arguments = {{type = "atom", pos = 6, name = "bar"}}},
			    {type = "atom", pos = 11, name = "+"},
			    {type = "number", pos = 13, name = "17"}}}})
   assert_node(term_lexer, "((2 + 3))", 
	       {type = "paren_term", pos = 2, 
		value = {type = "paren_term", pos = 3,
			 value = {type = "sequence_term", pos = 3,
				  elements = {{type = "number", pos = 3, name = "2"},
					      {type = "atom", pos = 5, name = "+"},
					      {type = "number", pos = 7, name = "3"}}}}})
   assert_node(term_lexer, "A * (2 + 3)", 
	       {type = "sequence_term", pos = 1,
		elements = {
		   {type = "variable", pos = 1, name = "A"},
		   {type = "compound_term",
		    pos = 3,
		    functor = {type = "atom", pos = 3, name = "*"},
		    arguments = {
		       {type = "sequence_term", 
			pos = 6,
			elements = {{type = "number", pos = 6, name = "2"},
				    {type = "atom", pos = 8, name = "+"},
				    {type = "number", pos = 10, name = "3"}}}}}}})
   assert_node(term_lexer, "(foo(bar) + (A * \\+(2, 3)))", {})
end

-- function test_operator_term_lexer()
--    local term_lexer_table = utils.merge(lex.lexer_table, { lpeg.V'term' })
--    -- utils.print(term_lexer_table)
--    local term_lexer = lpeg.P(term_lexer_table)
--    assert_node(term_lexer, "foo + bar",
-- 		     {type = "sequence_term",
-- 		      elements = {{type = "atom", value = "foo"}, 
-- 				  {type = "atom", value = "+"},
-- 				  {type = "atom", value = "bar"}}})
--    assert_node(term_lexer, "foo + bar * baz", {})
--    assert_node(term_lexer, "(foo + bar) * baz", {})
--    assert_node(term_lexer, "foo + (bar * baz)", {})
--    assert_node(term_lexer, "foo % (16 - 3 * f(5)) + (bar * baz)", {})
--    assert_node(term_lexer, "-bar", {})
--    assert_node(term_lexer, "foo + -bar", {})
--    assert_node(term_lexer, "+foo%", {})
--    assert_node(term_lexer, "+foo% @ + -bar", {})
-- end


function test_sequence_term_lexer()
   local term_lexer = lex.make_lexer('term')
   assert_node(term_lexer, "foo + bar, baz, Quux",
	       {type = "sequence_term",
		pos = 1,
		elements = {{type = "atom", pos = 1, name = "foo"}, 
			    {type = "atom", pos = 5, name = "+"},
			    {type = "atom", pos = 7, name = "bar"},
			    {type = "atom", pos = 10, name = ","},
			    {type = "atom", pos = 12, name = "baz"},
			    {type = "atom", pos = 15, name = ","},
			    {type = "variable", pos = 17, name = "Quux"}}})
   assert_node(term_lexer, "BAR * Foo",
	       {type = "sequence_term", 
		pos = 1,
		elements = {{type = "variable", pos = 1, name = "BAR"},
			    {type = "atom", pos = 5, name = "*"},
			    {type = "variable", pos = 7, name = "Foo"}}})
   assert_node(term_lexer, "-bar * Foo",
	       {type = "sequence_term", 
		pos = 1,
		elements = {{type = "atom", pos = 1, name = "-"},
			    {type = "atom", pos = 2, name = "bar"},
			    {type = "atom", pos = 6, name = "*"},
			    {type = "variable", pos = 8, name = "Foo"}}})
end
