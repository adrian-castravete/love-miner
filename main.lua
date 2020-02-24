local BB = require("breadboard")
local log = require("log")
log.info("`breadboard` required, game started")

BB.screenSize(120)

local btn = BB.button

local Level = require("level")
local Player = require("player")

local level = Level()
local player = Player(57*16, 5*16)
level:on("create", function (w, h)
  player.x = (w-7)*16
  player.y = 5*16
  log.info("Ready player one")
end)

log.info("Starting animation; reached `BB.frame`")
function BB.frame(dt)
  BB.clearScreen()

  local dx, dy = 0, 0
  local s = 256 * dt
  if btn('l') then dx = dx - s end
  if btn('u') then dy = dy - s end
  if btn('r') then dx = dx + s end
  if btn('d') then dy = dy + s end
  level.cameraX = level.cameraX + dx
  level.cameraY = level.cameraY + dy

  level:update(dt)
  if level:ready() then
    player:update(dt)
  end
end
