local BB = require("breadboard")
local log = require("log")

local Entity = require("entity")

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

local Level = BB.class(Entity)

function Level:init(width, height)
  local w = width or 64
  local h = height or 64

  self.cameraX = w * 16
  self.cameraY = 0

  self._maxLightLevel = 15
  self._levelWidth = w
  self._levelHeight = h
  self._img = BB.makeTileset("blocks.png")
  self._state = 'initial'
  self._map = nil
  self._co = nil
end

function Level:generateMap(width, height)
  local m = {}
  local brd = 5
  local mll = self._maxLightLevel

  self._state = 'creating'
  log.info("Starting level generation for a ("..width..", "..height..")")

  coroutine.yield('generation', 0)

  log.debug("Firstly setting initial random values for the map")
  for j=1, height do
    m[j] = {}
    for i=1, width do
      m[j][i] = {
        i = i,
        j = j,
        k = nil,
        ll = 0,
        d = 1,
        u = true,
      }
      local v, d = nil, 1
      if j > 6 or i <= width - 8 then
        if i == 1 or i == width or j == height then
          v = 'bedRock'
          d = 1048576000
        elseif i > width - brd and 1 - (width - i) / brd > rnd() or
               i <= brd and (i-1) / brd < rnd() or
               j > height - brd and 1 - (height - j) / brd > rnd() then
          v = 'bedRock'
          d = 1048576000
        elseif rnd() < 0.3 * j / height then
          v = 'rock'
          d = 20
        else
          local r = rnd()
          if r < 0.01 then
            v = 'dirt4'
            d = 7
          elseif r < 0.03 then
            v = 'dirt3'
            d = 6
          elseif r < 0.1 then
            v = 'dirt2'
            d = 5
          else
            v = rnd() < 0.3 and 'dirt1' or 'dirt'
            d = 3 + (v == 'dirt1' and 1 or 0)
          end
          r = rnd()
          if r < 0.003 then
            v = 'gold4'
            d = 7
          elseif r < 0.01 then
            v = 'gold3'
            d = 6
          elseif r < 0.03 then
            v = 'gold2'
            d = 5
          elseif r < 0.09 then
            v = 'gold1'
            d = 4
          end
        end
      end
      m[j][i].k = v
      m[j][i].d = d
    end
    coroutine.yield('generation', j / height)
  end
  local v = self:_uniqueV()
  m[6][width-8].k = 'dirt'
  coroutine.yield('generation', 1)

  log.debug("Generating grass...")
  local y = 1
  for i=2, width-8 do
    for j=1, y-1 do
      m[j][i].k = nil
      m[j][i].ll = mll
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

  log.debug("Setting initial light levels for top")
  for i=1, width do
    for j=1, 7 do
      if j == 1 or m[j-1][i].k == nil or
         i > 1 and m[j][i-1].k == nil or
         i < width and m[j][i+1].k == nil then
        m[j][i].ll = mll
      end
    end
    coroutine.yield('lighting', i / width)
  end
  coroutine.yield('lighting', 1)

  --log.debug("Drawing tiles")
  --for j=1, height do
  --  for i=1, width do
  --    self:_redrawTile(i, j)
  --  end
  --  coroutine.yield('drawing', j / height)
  --end
  --coroutine.yield('drawing', 1)

  self.cameraX = width * 16
  self.cameraY = 0

  log.info("Level generation completed.")

  self._state = 'playing'
  self._map = m
  self:fire("create", width, height)

  return 'done'
end

function Level:ready()
  return self._state == 'playing'
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
      log.error("WTF? "..tostring(st))
      love.event.quit()
    else
      if st ~= 'done' then
        BB.printXY(0, 0, "Creating level ...")
        BB.printXY(0, 12, st..": "..tostring(math.floor(prog*100)).."%")
      end
    end
  elseif self._state == 'playing' then
    self:_cameraBounds()
    self:_redrawUncleanTiles()
    BB.draw(0, 0, w*2, h*2, -self.cameraX, -self.cameraY)
  end
end

function Level:warpCamera(newX, newY)
  self.cameraX, self.cameraY = newX, newY
  self:_cameraBounds()
end

function Level:dig(cx, cy, v)
  if not self:ready() then
    log.warn("Level not ready. Ignoring dig...")
    return
  end
  local m = self._map
  local c = m[cy][cx]
  if c.k then
    c.k = 'air'
  end
  if cy == 1 then
    m[1][cx].k = nil
  end
  local j = 2
  while m[j][cx].k == 'air' or m[j][cx].k == nil do
    if m[j][cx].k == 'air' and m[j-1][cx].k == nil then
      m[j][cx].k = nil
      self:_refresh(cx, j)
    end
    j = j + 1
  end
  self:_refresh(cx, cy)
end

function Level:placeTorch(cx, cy)
  if not self:ready() then
    log.warn("Level not ready. Ignoring dig...")
    return
  end
  local c = self._map[cy][cx]
  c.ll = self._maxLightLevel
  self:_refresh(cx, cy)
end

function Level:_cameraBounds()
  local cx, cy = self.cameraX, self.cameraY
  cx = math.min(self._levelWidth * 16 - 119, math.max(0, cx))
  cy = math.min(self._levelHeight * 16 - 119, math.max(0, cy))
  self.cameraX, self.cameraY = cx, cy
end

function Level:_redrawUncleanTiles()
  local vi = BB.viewport()
  local zr = 16 * vi.zoom
  local sxb = math.floor(self.cameraX / 16 - vi.offsetX / zr)
  local syb = math.floor(self.cameraY / 16 - vi.offsetY / zr)
  local sxe = sxb + math.floor(vi.width / zr) + 2
  local sye = syb + math.floor(vi.height / zr) + 2

  for j=syb, sye do
    for i=sxb, sxe do
      if i > 0 and j > 0 and i <= self._levelWidth and j <= self._levelHeight then
        local c = self._map[j][i]
        if c.u then
          self:_redrawTile(i, j)
          c.u = false
        end
      end
    end
  end
end

function Level:_refresh(i, j)
  if not (i > 0 and j > 0 and i <= self._levelWidth and j <= self._levelHeight) then
    return
  end

  local m = self._map
  local accum = {{i, j}}
  local top = 1
  local v = self:_uniqueV()
  while top <= #accum do
    local x, y = unpack(accum[top])
    top = top + 1
    self:_refreshLightLevel(x, y)
    local check = function (cx, cy)
      if m[cy][cx].k == 'air' and m[cy][cx]._v ~= v and math.abs(cx-i) + math.abs(cy-j) < 8 then
        m[cy][cx]._v = v
        accum[#accum+1] = {cx, cy}
      end
      self:_refreshLightLevel(cx, cy)
    end
    if x > 1 then check(x-1, y) end
    if y > 1 then check(x, y-1) end
    if x < self._levelWidth then check(x+1, y) end
    if y < self._levelHeight then check(x, y+1) end
  end
end

function Level:_refreshLightLevel(i, j)
  local m = self._map
  local c = m[j][i]
  local lightLevel = c.ll

  local check = function(v)
    if not v.k then
      lightLevel = self._maxLightLevel
    end
    if v.k == 'air' and lightLevel < v.ll - 1 then
      lightLevel = v.ll - 1
    end
  end
  if i > 1 then check(m[j][i-1]) end
  if j > 1 then check(m[j-1][i]) end
  if i < self._levelWidth then check(m[j][i+1]) end
  if j < self._levelHeight then check(m[j+1][i]) end
  c.ll = lightLevel
  c.u = true
end

function Level:_redrawTile(i, j)
  local x, y = (i-1) * 2, (j-1) * 2
  local v = self._map[j][i]

  if v.ll == 0 then return end
  local l = v.ll / self._maxLightLevel
  BB.tileClear(x, y, 2, 2)
  if v.k then
    if v.k == 'air' then
      BB.tile(self._img, 0, 0, x, y, 2, 2, l, {0.4, 0.3, 0})
    else
      local c = _kindMap[v.k]
      BB.tile(self._img, c[1]*2, c[2]*2, x, y, 2, 2, l)
    end
  else
    BB.tileClear(x, y, 2, 2, 1, {0, 0.25, 1})
  end
end

function Level:_uniqueV()
  local v = rnd(255)
  while v == self._lastV do v = rnd(255) end
  self._lastV = v
  return v
end

return Level
