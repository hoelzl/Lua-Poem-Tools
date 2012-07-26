-- Tests of the Pratt parser.
--
module('test_pratt_parser', package.seeall)

local utils = require 'utilities'
local pratt = require 'pratt_parser'
local test = require 'lunatest'

local assert_node = utils.assert_node
