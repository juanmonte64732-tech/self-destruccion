local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local os = require("os")
local unicode = require("unicode")

local ARM_CODE = "10"
local CANCEL_CODE = "99"
local TOTAL_TIME = 20
local WARNING_THRESHOLD = 10

local gpu = component.gpu
local speech = nil
local redstones = {}

local function initializeComponents()
  if component.isAvailable("speech_box") then
    speech = component.speech_box
    print("[SYSTEM] Speech module detected")
  else
    print("[SYSTEM] Speech module not found")
  end
  
  for addr in component.list("redstone") do
    table.insert(redstones, component.proxy(addr))
    print("[SYSTEM] Redstone I/O initialized: " .. addr:sub(1, 8))
  end
  
  if #redstones == 0 then
    print("[WARNING] No redstone components detected")
  end
  
  os.sleep(1)
end

local function setAllRedstone(value)
  if #redstones == 0 then
    print("[ERROR] No redstone components available")
    return false
  end
  
  for _, rs in pairs(redstones) do
    for side = 0, 5 do
      pcall(function()
        rs.setOutput(side, value)
      end)
    end
  end
  
  return true
end

local function safeSpeak(text)
  if speech then
    local success, err = pcall(function()
      speech.say(text)
    end)
    if not success then
      print("[WARNING] Speech error: " .. tostring(err))
    end
    return success
  end
  return false
end

local function displayHeader()
  term.clear()
  print("=====================================")
  print("   SELF-DESTRUCT CONTROL SYSTEM")
  print("   UNAUTHORIZED ACCESS PROHIBITED")
  print("=====================================")
  print("")
end

local function authenticateUser()
  displayHeader()
  io.write("ENTER AUTHORIZATION CODE: ")
  local input = io.read()
  
  if not input then
    print("\n[ERROR] Input failed")
    os.sleep(1)
    return false
  end
  
  input = input:gsub("%s+", "")
  
  if input == ARM_CODE then
    print("\n[SUCCESS] Authorization accepted")
    print("[SYSTEM] Initializing self-destruct sequence...")
    os.sleep(1)
    return true
  else
    print("\n[DENIED] Invalid authorization code")
    print("[SYSTEM] Access denied - Returning to shell")
    os.sleep(2)
    return false
  end
end

local function displayCountdown(remaining, buffer, blink)
  local w, h = gpu.getResolution()
  local centerX = math.floor(w / 2)
  local centerY = math.floor(h / 2)
  
  gpu.setBackground(blink and 0xFF0000 or 0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  
  local title = "SELF-DESTRUCTION ACTIVATED"
  gpu.set(centerX - math.floor(#title / 2), centerY - 4, title)
  
  local warning = "!!! WARNING !!!"
  gpu.set(centerX - math.floor(#warning / 2), centerY - 3, warning)
  
  local timeText = "TIME REMAINING: " .. string.format("%02d", remaining) .. " SECONDS"
  gpu.set(centerX - math.floor(#timeText / 2), centerY - 1, timeText)
  
  if remaining <= WARNING_THRESHOLD then
    gpu.setForeground(0xFFFF00)
    local urgentText = "EVACUATE IMMEDIATELY"
    gpu.set(centerX - math.floor(#urgentText / 2), centerY + 1, urgentText)
    gpu.setForeground(0xFFFFFF)
  end
  
  local cancelPrompt = "ENTER CANCEL CODE TO ABORT:"
  gpu.set(centerX - math.floor(#cancelPrompt / 2), centerY + 3, cancelPrompt)
  
  local bufferDisplay = string.rep("*", #buffer)
  if #bufferDisplay > 0 then
    gpu.set(centerX - math.floor(#bufferDisplay / 2), centerY + 4, bufferDisplay)
  end
  
  local footer = "NO ABORT AFTER ZERO"
  gpu.setForeground(0xFF0000)
  gpu.set(centerX - math.floor(#footer / 2), centerY + 6, footer)
end

local function handleVoiceAnnouncements(remaining, spokenNumbers)
  if not speech then
    return
  end
  
  if remaining == TOTAL_TIME then
    safeSpeak("self destruct sequence activated. proceed to nearest shelter immediately.")
  elseif remaining == WARNING_THRESHOLD then
    safeSpeak("ten seconds remaining. evacuate now.")
  elseif remaining < WARNING_THRESHOLD and remaining > 0 and not spokenNumbers[remaining] then
    safeSpeak(tostring(remaining))
    spokenNumbers[remaining] = true
  elseif remaining == 0 then
    safeSpeak("detonation imminent")
  end
end

local function processInput(buffer, char)
  if char and char >= 48 and char <= 57 then
    buffer = buffer .. string.char(char)
    if #buffer > #CANCEL_CODE then
      buffer = buffer:sub(-#CANCEL_CODE)
    end
  end
  return buffer
end

local function cancelDestruction()
  local w, h = gpu.getResolution()
  local centerX = math.floor(w / 2)
  local centerY = math.floor(h / 2)
  
  gpu.setBackground(0x000000)
  gpu.setForeground(0x00FF00)
  gpu.fill(1, 1, w, h, " ")
  
  local msg1 = "SELF-DESTRUCT SEQUENCE ABORTED"
  local msg2 = "ALL SYSTEMS SAFE"
  local msg3 = "RETURNING TO NORMAL OPERATIONS"
  
  gpu.set(centerX - math.floor(#msg1 / 2), centerY - 1, msg1)
  gpu.set(centerX - math.floor(#msg2 / 2), centerY, msg2)
  gpu.set(centerX - math.floor(#msg3 / 2), centerY + 1, msg3)
  
  safeSpeak("self destruct sequence aborted. all systems safe.")
  
  os.sleep(3)
  setAllRedstone(0)
end

local function executeDetonation()
  local w, h = gpu.getResolution()
  local centerX = math.floor(w / 2)
  local centerY = math.floor(h / 2)
  
  gpu.setBackground(0xFF0000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  
  local boom = "DETONATION"
  gpu.set(centerX - math.floor(#boom / 2), centerY - 1, boom)
  
  local boom2 = "* * * KA-BOOM * * *"
  gpu.set(centerX - math.floor(#boom2 / 2), centerY + 1, boom2)
  
  safeSpeak("detonation")
  
  setAllRedstone(15)
  
  for i = 1, 5 do
    os.sleep(0.3)
    gpu.setBackground(i % 2 == 0 and 0xFF0000 or 0xFFFFFF)
    gpu.fill(1, 1, w, h, " ")
    gpu.setForeground(i % 2 == 0 and 0xFFFFFF or 0xFF0000)
    gpu.set(centerX - math.floor(#boom / 2), centerY, boom)
  end
  
  os.sleep(2)
end

local function runSelfDestructSequence()
  local w, h = gpu.getResolution()
  local startTime = computer.uptime()
  local lastRemaining = TOTAL_TIME
  local blink = true
  local inputBuffer = ""
  local spokenNumbers = {}
  
  handleVoiceAnnouncements(TOTAL_TIME, spokenNumbers)
  
  while true do
    local currentTime = computer.uptime()
    local elapsed = math.floor(currentTime - startTime)
    local remaining = TOTAL_TIME - elapsed
    
    if remaining < 0 then
      remaining = 0
      break
    end
    
    if remaining ~= lastRemaining then
      blink = not blink
      handleVoiceAnnouncements(remaining, spokenNumbers)
      lastRemaining = remaining
    end
    
    displayCountdown(remaining, inputBuffer, blink)
    
    local eventData = {event.pull(0.05)}
    
    if eventData[1] == "key_down" then
      local keyChar = eventData[3]
      inputBuffer = processInput(inputBuffer, keyChar)
      
      if inputBuffer == CANCEL_CODE then
        cancelDestruction()
        return
      end
    elseif eventData[1] == "interrupted" then
      print("\n[SYSTEM] Sequence interrupted by user")
      setAllRedstone(0)
      return
    end
  end
  
  executeDetonation()
end

local function main()
  print("[SYSTEM] Initializing self-destruct control system...")
  os.sleep(0.5)
  
  initializeComponents()
  
  if not authenticateUser() then
    return
  end
  
  term.clear()
  print("[ALERT] ARMING SELF-DESTRUCT SEQUENCE")
  print("[ALERT] THIS ACTION CANNOT BE UNDONE")
  print("")
  print("Press ENTER to continue or CTRL+C to abort...")
  
  local confirm = io.read()
  
  local success, err = pcall(runSelfDestructSequence)
  
  if not success then
    term.clear()
    print("[ERROR] System error occurred:")
    print(tostring(err))
    print("\n[SAFETY] Disabling all outputs...")
    setAllRedstone(0)
    os.sleep(3)
  end
  
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  term.clear()
  print("[SYSTEM] Self-destruct control system terminated")
end

main()
