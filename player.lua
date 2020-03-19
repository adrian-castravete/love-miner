local BB = require("breadboard")
local log = require("log")

local Entity = require("entity")

local Player = BB.class(Entity)

BB.tileClear(240, 0, 16, 2, 1, {0.5, 1, 0})

function Player:init(level, cx, cy)
  self.cx = 1
  self.cy = 1
  self.x = 0
  self.y = 0
  self.level = level
  if cx and cy then
    self:warp(cx, cy)
  end
end

function Player:update(dt)
  self.level:warpCamera(self.x - 52, self.y - 52)
  BB.draw(240, 0, 2, 2, self.x - self.level.cameraX, self.y - self.level.cameraY)
end

function Player:warp(cx, cy)
  self.cx = cx
  self.cy = cy
  self.x = (cx-1) * 16
  self.y = (cy-1) * 16
  self.level:dig(cx, cy)
end

function Player:warpRelative(dx, dy)
  self:warp(self.cx+dx, self.cy+dy)
end

function Player:reactRelative(dx, dy)
end

function Player:placeTorch()
  self.level:placeTorch(self.cx, self.cy)
end

return Player
