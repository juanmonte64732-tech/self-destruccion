local component = require("component")
local os = require("os")

if not component.isAvailable("speech_box") then
  error("No speech_box detected")
end

local speech = component.speech_box

speech.say("nine")
os.sleep(1)
speech.say("eight")
os.sleep(1)
speech.say("seven")
os.sleep(1)
speech.say("six")
os.sleep(1)
speech.say("five")
os.sleep(1)
speech.say("four")
os.sleep(1)
speech.say("three")
os.sleep(1)
speech.say("two")
os.sleep(1)
speech.say("one")
os.sleep(1)
speech.say("detonation")
