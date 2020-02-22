function love.conf(t)
  t.identity = 'breadboard-miner'
  t.version = '11.1'
  t.accelerometerjoystick = false
  t.externalstorage = true
  t.gammacorrect = true

  local w = t.window
  w.title = "Miner - Breadboard"
  w.icon = nil
  w.width = 960
  w.height = 600
  w.minwidth = 240
  w.minheight = 240
  w.resizable = true
  w.fullscreentype = 'desktop'
  w.fullscreen = false
  w.usedpiscale = false
  w.hidpi = true
end
