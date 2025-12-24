--------------------------------------------------
-- SELF DESTRUCT CONTROL SYSTEM
-- OpenComputers + speech_box
-- Minecraft 1.12.2
--------------------------------------------------

local component = require("component")
local computer  = require("computer")
local event     = require("event")
local term      = require("term")
local os        = require("os")

--------------------------------------------------
-- CONFIG
--------------------------------------------------

local ARM_CODE = "10"
local CANCEL_CODE = "99"
local TOTAL_TIME = 20
local WARNING_THRESHOLD = 10

--------------------------------------------------
-- COMPONENTS
--------------------------------------------------

local gpu = component.gpu
local speech = nil
local redstones = {}

--------------------------------------------------
-- NUMBER WORDS
--------------------------------------------------

local NUMBER_WORDS = {
  [10] = "ten",
  [9]  = "nine",
  [8]  = "eight",
  [7]  = "seven",
  [6]  = "six",
  [5]  = "five",
  [4]  = "four",
  [3]  = "three",
  [2]  = "two",
  [1]  = "one"
}

--------------------------------------------------
-- SCREEN UTILS
--------------------------------------------------

local function clearScreen(bg, fg)
  local w, h = gpu.getResolution()
  gpu.setBackground(bg)
  gpu.setForeground(fg)
  gpu.fill(1, 1, w, h, " ")
end

local function centerText(y, text)
  local w = gpu.getResolution()
  gpu.set(math.floor((w - #text) / 2) + 1, y, text)
end

--------------------------------------------------
-- INIT
--------------------------------------------------

local function initializeComponents()
  clearScreen(0x000000, 0xFFFFFF)

  if component.isAvailable("speech_box") then
    speech = component.speech_box
    speech.setVolume(1)
    speech.setPitch(1)
    speech.setSpeed(1)
    speech.speak("speech system online")
  end

  for addr in component.list("redstone") do
    table.insert(redstones, component.proxy(addr))
  end

  os.sleep(1)
end

--------------------------------------------------
-- REDSTONE
--------------------------------------------------

local function setAllRedstone(value)
  for _, rs in ipairs(redstones) do
    for side = 0, 5 do
      pcall(function()
        rs.setOutput(side, value)
      end)
    end
  end
end

--------------------------------------------------
-- SPEECH
--------------------------------------------------

local function speak(text)
  if speech then
    pcall(function()
      speech.speak(text)
    end)
  end
end

--------------------------------------------------
-- AUTH
--------------------------------------------------

local function authenticate()
  clearScreen(0x000000, 0xFFFFFF)
  centerText(6, "SELF DESTRUCT CONTROL SYSTEM")
  centerText(8, "ENTER AUTHORIZATION CODE")
  centerText(10, "> ")

  local input = io.read()

  if input == ARM_CODE then
    speak("authorization accepted")
    return true
  else
    speak("authorization denied")
    os.sleep(2)
    return false
  end
end

--------------------------------------------------
-- DISPLAY
--------------------------------------------------

local function displayCountdown(timeLeft, buffer)
  clearScreen(0x000000, 0xFFFFFF)

  centerText(4, "!!! SELF DESTRUCT ACTIVATED !!!")
  centerText(6, "TIME REMAINING")
  centerText(8, string.format("%02d SECONDS", timeLeft))

  if timeLeft <= WARNING_THRESHOLD then
    gpu.setForeground(0xFF0000)
    centerText(10, "EVACUATE IMMEDIATELY")
    gpu.setForeground(0xFFFFFF)
  end

  centerText(13, "CANCEL CODE")
  centerText(14, string.rep("*", #buffer))
end

--------------------------------------------------
-- VOICE LOGIC
--------------------------------------------------

local function handleVoice(timeLeft, spoken)
  if not speech then return end

  if timeLeft == TOTAL_TIME then
    speak("self destruct sequence activated")
  elseif timeLeft == WARNING_THRESHOLD then
    speak("ten seconds remaining")
  elseif timeLeft <= 9 and timeLeft >= 1 and not spoken[timeLeft] then
    speak(NUMBER_WORDS[timeLeft])
    spoken[timeLeft] = true
  elseif timeLeft == 0 then
    speak("detonation")
  end
end

--------------------------------------------------
-- SEQUENCE
--------------------------------------------------

local function runSequence()
  local startTime = computer.uptime()
  local spoken = {}
  local buffer = ""
  local lastTime = TOTAL_TIME

  while true do
    local elapsed = math.floor(computer.uptime() - startTime)
    local remaining = TOTAL_TIME - elapsed
    if remaining < 0 then break end

    if remaining ~= lastTime then
      handleVoice(remaining, spoken)
      lastTime = remaining
    end

    displayCountdown(remaining, buffer)

    local e = {event.pull(0.1)}
    if e[1] == "key_down" then
      local ch = e[3]
      if ch >= 48 and ch <= 57 then
        buffer = (buffer .. string.char(ch)):sub(-2)
      end

      if buffer == CANCEL_CODE then
        clearScreen(0x000000, 0x00FF00)
        centerText(10, "SELF DESTRUCT ABORTED")
        speak("self destruct aborted")
        setAllRedstone(0)
        os.sleep(3)
        return
      end
    end
  end

  ------------------------------------------------
  -- DETONATION
  ------------------------------------------------
  clearScreen(0xFF0000, 0xFFFFFF)
  centerText(10, "***** DETONATION *****")
  speak("boom")
  setAllRedstone(15)
  os.sleep(3)
end

--------------------------------------------------
-- MAIN
--------------------------------------------------

local function main()
  initializeComponents()

  if not authenticate() then return end

  speak("self destruct armed")
  runSequence()

  clearScreen(0x000000, 0xFFFFFF)
  centerText(10, "SYSTEM HALTED")
end

main()
