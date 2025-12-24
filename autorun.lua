local component = require("component")
local computer = require("computer")
local event = require("event")
local term = require("term")
local os = require("os")

-- CONFIG
local ARM_CODE = "10"
local CANCEL_CODE = "99"
local TOTAL_TIME = 20
local WARNING_THRESHOLD = 10

-- COMPONENTS
local gpu = component.gpu
local speech = nil
local redstones = {}

-- NUMBER WORDS (ENGLISH)
local NUMBER_WORDS = {
  [1] = "one",
  [2] = "two",
  [3] = "three",
  [4] = "four",
  [5] = "five",
  [6] = "six",
  [7] = "seven",
  [8] = "eight",
  [9] = "nine",
  [10] = "ten"
}

-- INIT
local function initializeComponents()
  if component.isAvailable("speech") then
    speech = component.speech
    print("[SYSTEM] Computronics speech block detected")
  else
    print("[WARNING] Speech block NOT found (Computronics missing?)")
  end

  for addr in component.list("redstone") do
    table.insert(redstones, component.proxy(addr))
  end

  os.sleep(1)
end

-- REDSTONE
local function setAllRedstone(value)
  for _, rs in pairs(redstones) do
    for side = 0, 5 do
      pcall(function()
        rs.setOutput(side, value)
      end)
    end
  end
end

-- SPEECH SAFE
local function safeSpeak(text)
  if speech then
    pcall(function()
      speech.say(text)
    end)
  end
end

-- UI
local function displayCountdown(remaining)
  term.clear()
  print("===== SELF DESTRUCT SYSTEM =====")
  print("")
  print("TIME REMAINING: " .. remaining .. " SECONDS")
  print("")
  print("ENTER CANCEL CODE TO ABORT")
end

-- VOICE
local function handleVoiceAnnouncements(remaining, spoken)
  if not speech then return end

  if remaining == TOTAL_TIME then
    safeSpeak("self destruct sequence activated")
  elseif remaining == WARNING_THRESHOLD then
    safeSpeak("ten seconds remaining")
  elseif remaining <= 9 and remaining >= 1 and not spoken[remaining] then
    safeSpeak(NUMBER_WORDS[remaining])
    spoken[remaining] = true
  elseif remaining == 0 then
    safeSpeak("detonation")
  end
end

-- MAIN SEQUENCE
local function runSelfDestruct()
  local startTime = computer.uptime()
  local spoken = {}
  local buffer = ""

  handleVoiceAnnouncements(TOTAL_TIME, spoken)

  while true do
    local elapsed = math.floor(computer.uptime() - startTime)
    local remaining = TOTAL_TIME - elapsed

    if remaining < 0 then break end

    displayCountdown(remaining)
    handleVoiceAnnouncements(remaining, spoken)

    local e = {event.pull(0.1)}
    if e[1] == "key_down" then
      local ch = e[3]
      if ch >= 48 and ch <= 57 then
        buffer = buffer .. string.char(ch)
        buffer = buffer:sub(-2)
      end
      if buffer == CANCEL_CODE then
        term.clear()
        print("SELF DESTRUCT ABORTED")
        safeSpeak("self destruct aborted")
        setAllRedstone(0)
        os.sleep(2)
        return
      end
    end
  end

  -- DETONATION
  term.clear()
  print("***** KA-BOOM *****")
  safeSpeak("boom")
  setAllRedstone(15)
end

-- AUTH
local function main()
  initializeComponents()
  term.clear()
  io.write("ENTER ARM CODE: ")
  local code = io.read()

  if code ~= ARM_CODE then
    print("ACCESS DENIED")
    os.sleep(2)
    return
  end

  runSelfDestruct()
end

main()
