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
  self.cameraX = w * 16
  self.cameraY = 0
  self._img = BB.makeTileset("blocks.png")
  self._state = 'initial'
  self._map = nil
  self._co = nil
end

function Level:generateMap(width, height)
  local m = {}
  local brd = 5

  self._state = 'creating'
  log.info("Starting level generation for a ("..width..", "..height..")")

  coroutine.yield('generation', 0)

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
    coroutine.yield('generation', j / height)
  end
  local v = rnd(255)
  while v == self._lastV do v = rnd(255) end
  self._lastV = v
  m[6][width-8].k = 'dirt'
  coroutine.yield('generation', 1)

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
  coroutine.yield('grass', 1)

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
    if index % 1000 == 1 then
      coroutine.yield('floodfill', index / (width * height))
    end
  end
  coroutine.yield('floodfill', 1)

  log.debug("Setting 'bedRock' for all untouched blocks")
  for j=1, height do
    for i=1, width do
      if m[j][i].k and m[j][i]._v == v then
        m[j][i]._v = nil
      elseif m[j][i].k then
        m[j][i].k = 'bedRock'
      end
    end
    coroutine.yield('bedrock', j / height)
  end
  coroutine.yield('bedrock', 1)

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
    coroutine.yield('drawing', j / height)
  end
  coroutine.yield('drawing', 1)

  self.cameraX = width * 16
  self.cameraY = 0

  log.info("Level generation completed.")

  self._state = 'playing'

  return 'done', m
end

function Level:update(dt)
  local w = self._levelWidth
  local h = self._levelHeight
  if self._state == 'initial' then
    self._co = coroutine.create(self.generateMap)
    local err, other = coroutine.resume(self._co, self, w, h)
  elseif self._state == 'creating' then
    local err, st, prog = coroutine.resume(self._co, self)
    if not err then
      self:setError(st)
    else
      if st == 'done' then
        self._map = prog
      else
        BB.printXY(0, 0, st..": "..tostring(math.floor(prog*100)).."%")
      end
    end
  elseif self._state == 'playing' then
    local cx, cy = self.cameraX, self.cameraY
    cx = math.min(w * 16 - 119, math.max(0, cx))
    cy = math.min(h * 16 - 119, math.max(0, cy))
    self.cameraX, self.cameraY = cx, cy

    BB.draw(0, 0, w*2, h*2, -cx, -cy)
  end
end

return Level
