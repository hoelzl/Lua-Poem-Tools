member(X, [X|Z]).
member(X, [Y|Z]) :- member(X, Z).

foo(X, Y) :- bar(X, Z), baz(Z, Y).

