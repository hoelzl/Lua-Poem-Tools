-- The runtime for the Poem system.
--

local utils = require 'poem-utilities'
local pp = require 'poem-parser'

local runtime = {}

-- The trail for undoing unifications
runtime.trail = {}

package.loaded['poem-runtime'] = runtime
