local component = require("component")
local term = require("term")

term.clear()

print("GPU:", component.isAvailable("gpu"))
print("Speech box:", component.isAvailable("speech_box"))
print("Redstone:", component.isAvailable("redstone"))

if component.isAvailable("speech_box") then
  local sb = component.speech_box
  sb.setVolume(1)
  sb.setPitch(1)
  sb.setSpeed(1)
  sb.speak("diagnostic test successful")
end

print("Press any key to exit")
os.pullEvent("key_down")
