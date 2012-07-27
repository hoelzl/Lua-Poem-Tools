#! /usr/bin/env luajit

require 'lunatest'

lunatest.suite('test_utilities')
lunatest.suite('test_basic_lexer')
lunatest.suite('test_pratt_parser')
-- lunatest.suite('test_prolog_parser')
-- lunatest.suite('test_poem_parser')
lunatest.suite('test_poem_runtime')
lunatest.suite('test_unification')
lunatest.suite('test_simplification')

lunatest.run()
