local BB = require("breadboard")
local log = require("log")
log.info("`breadboard` required, game started")

BB.screenSize(120)

local btn = BB.button

local Level = require("level")

local level = Level()

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
end
