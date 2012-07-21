#! /usr/bin/env luajit

require 'lunatest'

lunatest.suite('test-poem-parser')
lunatest.suite('test-poem-runtime')
lunatest.suite('test-poem-unification')

lunatest.run()
