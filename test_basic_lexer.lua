-- Tests of the basic lexer
--
module('test_basic_lexer', package.seeall)

local utils = require 'utilities'
local lex = require 'basic_lexer'
local test = require 'lunatest'

local assert_node = utils.assert_node

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

function test_term_list_lexer ()
   local lexer = lex.lexer
   assert_node(lexer, "a + b",
	       {{type = "atom", pos = 1, name = "a"},
		{type = "atom", pos = 3, name = "+"},
		{type = "atom", pos = 5, name = "b"}})
   assert_node(lexer, "1 + (3 * 7)",
	       {{type = "number", pos = 1, name = "1"},
		{type = "atom", pos = 3, name = "+"},
		{type = "atom", pos = 5, name = "("},
		{type = "number", pos = 6, name = "3"},
		{type = "atom", pos = 8, name = "*"},
		{type = "number", pos = 10, name = "7"},
		{type = "atom", pos = 11, name = ")"}})
   assert_node(lexer, 'map(x, [1, a, A, _, "Foo"])',
	       {{type = "atom", pos = 1, name = "map"},
		{type = "atom", pos = 4, name = "("},
		{type = "atom", pos = 5, name = "x"},
		{type = "atom", pos = 6, name = ","},
		{type = "atom", pos = 8, name = "["},
		{type = "number", pos = 9, name = "1"},
		{type = "atom", pos = 10, name = ","},
		{type = "atom", pos = 12, name = "a"},
		{type = "atom", pos = 13, name = ","},
		{type = "variable", pos = 15, name = "A"},
		{type = "atom", pos = 16, name = ","},
		{type = "anonymous_variable", pos = 18, name = "_"},
		{type = "atom", pos = 19, name = ","},
		{type = "string", pos = 21, name = "Foo"},
		{type = "atom", pos = 26, name = "]"},
		{type = "atom", pos = 27, name = ")"}})
   assert_node(lexer, 'map(x, [1, a, A, _, | "Foo"])',
	       {{type = "atom", pos = 1, name = "map"},
		{type = "atom", pos = 4, name = "("},
		{type = "atom", pos = 5, name = "x"},
		{type = "atom", pos = 6, name = ","},
		{type = "atom", pos = 8, name = "["},
		{type = "number", pos = 9, name = "1"},
		{type = "atom", pos = 10, name = ","},
		{type = "atom", pos = 12, name = "a"},
		{type = "atom", pos = 13, name = ","},
		{type = "variable", pos = 15, name = "A"},
		{type = "atom", pos = 16, name = ","},
		{type = "anonymous_variable", pos = 18, name = "_"},
		{type = "atom", pos = 19, name = ","},
		{type = "atom", pos = 21, name = "|"},
		{type = "string", pos = 23, name = "Foo"},
		{type = "atom", pos = 28, name = "]"},
		{type = "atom", pos = 29, name = ")"}})
end