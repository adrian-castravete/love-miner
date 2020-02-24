local BB = require("breadboard")
local log = require("log")

local Entity = BB.class()

function Entity:on(evtName, func)
  local ls = self:_getListeners(evtName)
  table.insert(ls, func)
end

function Entity:off(evtName, func)
  local ls = self:_getListeners(evtName)
  local a = {}
  for i, l in ipairs(ls) do
    if not func or l == func then
      a[#a+1] = i
    end
  end
  for i=#a, 1, -1 do
    table.remove(ls, i)
  end
end

function Entity:fire(evtName, ...)
  local ls = self:_getListeners(evtName)
  for i=1, #ls do
    ls[i](...)
  end
end

function Entity:_getListeners(evtName)
  local ls = self._listeners
  if not ls then
    ls = {}
    self._listeners = ls
  end
  l = ls[evtName]
  if not l then
    l = {}
    ls[evtName] = l
  end
  return l
end

return Entity
