local BB = require("breadboard")
local log = require("log")

local Entity = require("entity")

local Player = BB.class(Entity)

function Player:init(x, y)
  self.x = x
  self.y = y
end

function Player:update(dt)
end

return Player
