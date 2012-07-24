-- Tests of the Poem parser
--

module('test_poem_parser', package.seeall)

local pp = require 'poem_parser'
local lpeg = require 'lpeg'
local test = require 'lunatest'
