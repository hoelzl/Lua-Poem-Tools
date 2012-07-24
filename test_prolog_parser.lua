-- Tests of the Prolog plexer
--

module('test_prolog_parser', package.seeall)

local pp = require 'prolog_parser'
local lpeg = require 'lpeg'
local test = require 'lunatest'
