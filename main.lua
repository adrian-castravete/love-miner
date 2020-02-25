local BB = require("breadboard")
local log = require("log")
log.info("`breadboard` required, game started")

BB.screenSize(120)

--local btn = BB.button
local btnp = BB.buttonPressed

local Level = require("level")
local Player = require("player")

local level = Level()
local player = Player(level)
level:on("create", function (w, h)
  player:warp(w-6, 6)
  log.info("Ready player one")
end)

log.info("Starting animation; reached `BB.frame`")
function BB.frame(dt)
  BB.clearScreen()

  if btnp('l') then player:warpRelative(-1, 0) end
  if btnp('u') then player:warpRelative(0, -1) end
  if btnp('r') then player:warpRelative(1, 0) end
  if btnp('d') then player:warpRelative(0, 1) end
  if btnp('a') then player:placeTorch() end

  level:update(dt)
  if level:ready() then
    player:update(dt)
  end
end
