local computer = require("computer")
local component = require("component")
local event = require("event")
local term = require("term")

local ARM_CODE = "10"
local CANCEL_CODE = "99"
local TOTAL_TIME = 200

local gpu = component.gpu
local redstones = {}

for addr in component.list("redstone") do
  redstones[addr] = component.proxy(addr)
end

local function setAllRedstone(v)
  for _, rs in pairs(redstones) do
    for s = 0, 5 do
      rs.setOutput(s, v)
    end
  end
end

local function readPassword()
  term.clear()
  local w, h = gpu.getResolution()
  gpu.set(1, 1, "Enter Password: ")
  local buffer = ""
  
  while true do
    local ev = {event.pull()}
    if ev[1] == "char" then
      local ch = ev[2]
      if ch >= "0" and ch <= "9" then
        buffer = buffer .. ch
        gpu.set(17 + #buffer - 1, 1, "*")
      end
    elseif ev[1] == "key_down" then
      if ev[4] == 28 then
        return buffer
      end
    end
  end
end

local password = readPassword()
if password ~= ARM_CODE then
  computer.beep(400, 0.3)
  term.clear()
  print("Access Denied")
  os.sleep(1)
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
  
  if remaining <= 0 then 
    break 
  end
  
  if remaining ~= last then
    blink = not blink
    computer.beep(1000, 0.08)
    last = remaining
  end
  
  gpu.setBackground(blink and 0xFF0000 or 0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  
  local cx = math.floor(w / 2)
  local cy = math.floor(h / 2)
  
  gpu.set(cx - 13, cy - 2, "SELF-DESTRUCTION ACTIVATED")
  gpu.set(cx - 7,  cy,     "TIME LEFT: " .. remaining)
  gpu.set(cx - 6,  cy + 2, "CANCEL CODE:")
  gpu.set(cx - 3,  cy + 3, string.rep("*", #buffer))
  
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
        gpu.set(cx - 10, cy, "DESTRUCTION CANCELED")
        computer.beep(800, 0.5)
        os.sleep(2)
        setAllRedstone(0)
        return
      end
    end
  end
end

gpu.setBackground(0xFF0000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
local cx = math.floor(w / 2)
local cy = math.floor(h / 2)
gpu.set(cx - 4, cy, "KA-BOOM")
setAllRedstone(15)
os.sleep(5)
