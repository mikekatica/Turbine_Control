--functions
rstTerm = function ()
  term.clear()
  term.setCursorPos(1,1)
end
printMenu = function (t)
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
    printMenu()
    local event, button, xPos, yPos = os.pullEvent("mouse_click")
    if event then
      if yPos == 1 then
        rstTerm()
        if c.target then
          print("Turbine Spinning Up")
          c.begin(c)
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
c.setUp(c,t,m,800,l)
c.setTarget(c,1800)
parallel.waitForAny(function() run(c) end, function() updateDisp(c) end)
print("Complete")
