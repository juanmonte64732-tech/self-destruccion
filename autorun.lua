local computer = require("computer")
local component = require("component")
local event = require("event")
local term = require("term")

local gpu = component.gpu

local redstones = {}
for addr in component.list("redstone") do
  redstones[addr] = component.proxy(addr)
end

local ARM_CODE = "10"
local CANCEL_CODE = "99"
local TOTAL_TIME = 200

local function setAllRedstone(v)
  for _, rs in pairs(redstones) do
    for s = 0, 5 do
      rs.setOutput(s, v)
    end
  end
end

term.clear()
io.write("Enter Password: ")
if io.read() ~= ARM_CODE then
  computer.beep(400, 0.3)
  return
end

local w, h = gpu.getResolution()
local start = computer.uptime()
local last = TOTAL_TIME
local blink = true
local buffer = ""

while true do
  local elapsed = math.floor(computer.uptime() - start)
  local remaining = TOTAL_TIME - elapsed
  if remaining <= 0 then break end

  if remaining ~= last then
    blink = not blink
    computer.beep(1000, 0.08)
    last = remaining
  end

  gpu.setBackground(blink and 0xFF0000 or 0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")

  gpu.set(w//2 - 13, h//2 - 2, "SELF-DESTRUCTION ACTIVATED")
  gpu.set(w//2 - 7,  h//2,     "TIME LEFT: "..remaining)
  gpu.set(w//2 - 6,  h//2 + 2, "CANCEL CODE:")
  gpu.set(w//2 - 3,  h//2 + 3, string.rep("*", #buffer))

  local ev = {event.pull(0.05)}
  if ev[1] == "char" then
    local ch = ev[2]
    if ch >= "0" and ch <= "9" then
      buffer = buffer .. ch
      if #buffer > #CANCEL_CODE then
        buffer = buffer:sub(-#CANCEL_CODE)
      end
      if buffer == CANCEL_CODE then
        gpu.setBackground(0x000000)
        gpu.setForeground(0x00FF00)
        gpu.fill(1, 1, w, h, " ")
        gpu.set(w//2 - 10, h//2, "DESTRUCTION CANCELED")
        computer.beep(800, 0.5)
        setAllRedstone(0)
        return
      end
    end
  end
end

gpu.setBackground(0xFF0000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
gpu.set(w//2 - 4, h//2, "KA-BOOM")
setAllRedstone(15)

