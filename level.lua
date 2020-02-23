local BB = require("breadboard")
local log = require("log")

local rnd = love.math.random

local _kindMap = {
  dirt = {0, 0},
  dirt1 = {1, 0},
  dirt2 = {2, 0},
  dirt3 = {3, 0},
  dirt4 = {4, 0},
  rock = {0, 1},
  gold1 = {1, 1},
  gold2 = {2, 1},
  gold3 = {3, 1},
  gold4 = {4, 1},
  bedRock = {0, 2},
  grass = {0, 3},
}

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
end

function Level:generateMap(width, height)
  local m = {}
  local brd = 5

  log.info("Starting level generation for a ("..width..", "..height..")")

  log.debug("Firstly setting initial random values for the map")
  for j=1, height do
    m[j] = {}
    for i=1, width do
      local v = nil
      if j > 6 or i <= width - 8 then
        if i == 1 or i == width or j == height then
          v = 'bedRock'
        elseif i > width - brd and 1 - (width - i) / brd > rnd() or
               i <= brd and (i-1) / brd < rnd() or
               j > height - brd and 1 - (height - j) / brd > rnd() then
          v = 'bedRock'
        elseif rnd() < 0.3 * j / height then
          v = 'rock'
        else
          local r = rnd()
          if r < 0.01 then
            v = 'dirt4'
          elseif r < 0.03 then
            v = 'dirt3'
          elseif r < 0.1 then
            v = 'dirt2'
          else
            v = rnd() < 0.3 and 'dirt1' or 'dirt'
          end
          r = rnd()
          if r < 0.003 then
            v = 'gold4'
          elseif r < 0.01 then
            v = 'gold3'
          elseif r < 0.03 then
            v = 'gold2'
          elseif r < 0.09 then
            v = 'gold1'
          end
        end
      end
      m[j][i] = {
        i = i,
        j = j,
        k = v,
      }
    end
  end
  local v = rnd(255)
  while v == self._lastV do v = rnd(255) end
  self._lastV = v
  m[6][width-8].k = 'dirt'

  log.debug("Initiating floodfill for path to every block")
  local accum = {{width-8, 6}}
  local index = 1
  local vv = function (i, j)
    if (not m[j][i]._v or m[j][i]._v ~= v) and m[j][i].k ~= 'bedRock' then
      accum[#accum+1] = {i, j}
      m[j][i]._v = v
    end
  end
  while index <= #accum do
    local i, j = unpack(accum[index])
    if i > 1 then vv(i-1, j) end
    if j > 1 then vv(i, j-1) end
    if i < width then vv(i+1, j) end
    if j < height then vv(i, j+1) end
    index = index + 1
  end

  log.debug("Generating grass...")
  local y = 1
  for i=2, width-8 do
    for j=1, y-1 do
      m[j][i].k = nil
    end
    m[y][i].k = 'grass'
    if rnd() < 0.5 then
      if rnd() < 1 / (1+y*1.2) then
        y = y + 1
      elseif y > 1 then
        y = y - 1
      end
    end
  end

  log.debug("Setting 'bedRock' for all untouched blocks")
  for j=1, height do
    for i=1, width do
      if m[j][i].k and m[j][i]._v == v then
        m[j][i]._v = nil
      elseif m[j][i].k then
        m[j][i].k = 'bedRock'
      end
    end
  end

  log.debug("Drawing tiles")
  for j=1, height do
    for i=1, width do
      local x, y = (i-1) * 2, (j-1) * 2
      local v = m[j][i]
      if v.k then
        v = _kindMap[v.k]
        BB.tile(self._img, v[1]*2, v[2]*2, x, y, 2, 2)
      else
        BB.tileClear(x, y, 2, 2, 0, 0, 1, {0, 0.25, 1})
      end
    end
  end

  log.info("Level generation completed.")

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
