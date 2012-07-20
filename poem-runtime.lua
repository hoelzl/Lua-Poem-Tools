-- The runtime for the Poem system.
--

local utils = require 'poem-utilities'
local pp = require 'poem-parser'

local runtime = {}

-- The trail for undoing unifications
local trail = {}
runtime.trail = trail

local function clear_trail ()
   for k, _ in pairs(trail) do
      trail[k] = nil
   end
end
runtime.clear_trail = clear_trail

local function push_to_trail (value)
   trail[#trail + 1] = value
end
runtime.push_to_trail = push_to_trail

package.loaded['poem-runtime'] = runtime
