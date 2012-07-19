require 'poem-parser'

local function print_simple_parse_tree(string)
   table.print(simplify_parse_tree(string))
   print()
end

function poem_parser.test_atom_parser()
   local atom_parser_table = table.merge(parser_table, { V'atom' })
   -- table.print(atom_parser_table)
   local atom_parser = P(atom_parser_table)
   print_simple_parse_tree(atom_parser:match("foo"))
   print_simple_parse_tree(atom_parser:match("&*%$"))
   print_simple_parse_tree(atom_parser:match("'foo bar baz'"))
end

function poem_parser.test_term_parser()
   local term_parser_table = table.merge(parser_table, { V'term' })
   -- table.print(term_parser_table)
   local term_parser = P(term_parser_table)
   print_simple_parse_tree(term_parser:match("foo"))
   print_simple_parse_tree(term_parser:match("foo()"))
   print_simple_parse_tree(term_parser:match("foo(bar)"))
   print_simple_parse_tree(term_parser:match("foo ( Bar )"))
   print_simple_parse_tree(term_parser:match("foo(bar, Baz)"))
   print_simple_parse_tree(term_parser:match("foo(bar, Baz, 'and a complex atom', 1234)"))
   print_simple_parse_tree(term_parser:match("'foo'()"))
   print_simple_parse_tree(term_parser:match("'foo bar'()"))
   print_simple_parse_tree(term_parser:match("'foo bar'(baz, $$$)"))
   print_simple_parse_tree(term_parser:match("+(baz, $$$)"))
end

function poem_parser.test_paren_term_parser()
   local term_parser_table = table.merge(parser_table, { V'term' })
   -- table.print(term_parser_table)
   local term_parser = P(term_parser_table)
   print_simple_parse_tree(term_parser:match("(foo)"))
   print_simple_parse_tree(term_parser:match("(foo(bar))"))
   print_simple_parse_tree(term_parser:match("(17)"))
   print_simple_parse_tree(term_parser:match("(17 + 4)"))
   print_simple_parse_tree(term_parser:match("(foo(bar) + 17)"))
   print_simple_parse_tree(term_parser:match("(foo(bar) + (a * +(2, 3)))"))
end

function poem_parser.test_binop_term_list_parser()
   local term_parser_table = table.merge(parser_table, { V'binop_term_list' })
   -- table.print(term_parser_table)
   local term_parser = P(term_parser_table)
   print_simple_parse_tree(term_parser:match(" + bar"))
   print_simple_parse_tree(term_parser:match(" * foo"))
   print_simple_parse_tree(term_parser:match(" + bar * foo"))
end

function poem_parser.test_binop_term_parser()
   local term_parser_table = table.merge(parser_table, { V'term' })
   -- table.print(term_parser_table)
   local term_parser = P(term_parser_table)
   print_simple_parse_tree(term_parser:match("foo + bar"))
   print_simple_parse_tree(term_parser:match("foo + bar * Baz"))
   print_simple_parse_tree(term_parser:match("(foo + bar) * Baz"))
   print_simple_parse_tree(term_parser:match("foo + (bar * Baz)"))
   print_simple_parse_tree(term_parser:match("foo % (16 - 3 * f(5)) + (bar * Baz)"))
end


function poem_parser.test_clause_parser()
   print_simple_parse_tree(parser:match("foo(bar, 1, X, 'atom with space')."))
   print_simple_parse_tree(parser:match("'this is a constant'(Applied, to, \"Some Terms\")."))
   print_simple_parse_tree(parser:match("f([a, List, 17])."))
   print_simple_parse_tree(parser:match("g([ this ( is   (a, nested), Term  ), InAList | WithRestAndWhitespace ])."))
   print_simple_parse_tree(parser:match("f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y)."))
   print_simple_parse_tree(parser:match("f(X,Y) :- g(Y, X) and h(X, X) or foo(bar) and z(Y)."))
   print_simple_parse_tree(parser:match("f(X,Y) :- g(Y, X) & h(X, X) | foo(bar) &&&||||**** z(Y)."))
   print_simple_parse_tree(parser:match([[
     f(X,Y) :- g(Y, X), h(X, X); foo(bar), z(Y).
     f(X,Y) :- g(X, X), h(X, Y), bar(foo).
     g(X,Y) :- asdf(X, Y).
   ]]))
end
