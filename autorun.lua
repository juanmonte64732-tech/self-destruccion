local component = require("component")

print(component.isAvailable("speech_box"))

local sb = component.speech_box

sb.setVolume(1)
sb.speak("hello world")
