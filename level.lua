local BB = require("breadboard")
local log = require("log")

local rnd = love.math.random

local Level = BB.class()

function Level:init(width, height)
  local w = width or 64
  local h = height or 64

  self._levelWidth = w
  self._levelHeight = h
  self.cameraX = 1024
  self.cameraY = 0
  self._img = BB.makeTileset("blocks.png")
  self._map = self:generateMap(w, h)

  log.info("Level generated with a size of ("..w..", "..h..")")
end

function Level:generateMap(width, height)
  local m = {}

  for j=1, height do
    m[j] = {}
    for i=1, width do
      local v = -1
      if j > 6 or i < 56 then
        if rnd() < 0.1 * i / 64 then
          v = 32
        else
          local r = rnd()
          if r < 0.01 then
            v = 4
          elseif r < 0.03 then
            v = 3
          elseif r < 0.1 then
            v = 2
          else
            v = rnd() < 0.3 and 1 or 0
          end
        end
      end
      local x, y = (i-1) * 2, (j-1) * 2
      if v >= 0 then
        BB.tile(self._img, v*2, x, y, 2, 2)
      else
        BB.tileClear(x, y, 2, 2, 0, 0, 1, {0, 0.25, 1})
      end
      m[j][i] = v
    end
  end

  return m
end

function Level:update(dt)
  local w = self._levelWidth
  local h = self._levelHeight
  local cx, cy = self.cameraX, self.cameraY
  cx = math.min(w * 16 - 119, math.max(0, cx))
  cy = math.min(h * 16 - 119, math.max(0, cy))
  self.cameraX, self.cameraY = cx, cy

  BB.draw(0, 0, w*2, h*2, -cx, -cy)
end

return Level
