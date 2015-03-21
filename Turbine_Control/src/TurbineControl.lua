--functions
rstTerm = function ()
  term.clear()
  term.setCursorPos(1,1)
end
printMenu = function (c)
  row = 1
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.green)
  term.write("Activate Turbine")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.black)
  term.write("  ")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.red)
  term.write("Set Target RPM")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.black)
  term.write("  ")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.orange)
  term.write("Set PID Constants")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.black)
  term.write("  ")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  term.write("Disable Reactor")
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.write("  ")
  term.setCursorPos(1,row)
  row = row + 1
  term.write("Target:  "..c.target.."  Kp: "..c.kp.."  Ki: "..c.ki.."  Kd: "..c.kd)
end
updateDisp = function (c)
  while true do
    c.updateDisplay(c)
    sleep(0.1)
  end
end
run = function (c)
  exit = false
  term.clear()
  while not exit do
    rstTerm()
    printMenu(c)
    local event, button, xPos, yPos = os.pullEvent("mouse_click")
    if event then
      if yPos == 1 then
        rstTerm()
        if c.target then
          print("Turbine Spinning Up")
          c.begin(c)
        elseif not c.isSetUp(c) then
          print("Not Set Up")
        else
          print("No Target Set")
        end
      elseif yPos == 3 then
        rstTerm()
        print("Set Target: ")
        local trg = read()
        c.setTarget(c, tonumber(trg))
      elseif yPos == 5 then
        rstTerm()
        print("Kp: ")
        local cnP = read()
        print("Ki: ")
        local cnI = read()
        print("Kd: ")
        local cnD = read()
        c.setConstants(c, tonumber(cnP), tonumber(cnI), tonumber(cnD))
       elseif yPos == 7 then
        c.disable(c)
      end
    end
    sleep(0.5)
  end
end
--init
if not tctl then
  os.loadAPI("soft/tctl")
end
c = tctl.control
t = peripheral.wrap("back")
m = peripheral.wrap("top")
l = tctl.logger
l.setFilename(l, nil)
l.createFile(l)
print("Reactor Max Intake")
maxF = read()
c.setUp(c,t,m,tonumber(maxF),l)
c.setTarget(c,1800)
parallel.waitForAny(function() run(c) end, function() updateDisp(c) end)
print("Complete")
