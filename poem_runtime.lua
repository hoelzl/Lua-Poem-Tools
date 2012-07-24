-- The runtime for the Poem system.
--
module('poem_runtime', package.seeall)

local utils = require 'utilities'
local pp = require 'poem_parser'

-- The trail for undoing unifications
local trail = {}
poem_runtime.trail = trail

local function clear_trail ()
   for k, _ in pairs(trail) do
      trail[k] = nil
   end
end
poem_runtime.clear_trail = clear_trail

local function push_to_trail (value)
   trail[#trail + 1] = value
end
poem_runtime.push_to_trail = push_to_trail
