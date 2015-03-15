--functions
rstTerm = function ()
  term.clear()
  term.setCursorPos(1,1)
end
printMenu = function (t)
  row = 1
  term.setCursorPos(1,row)
  row = row + 1
  term.setBackgroundColor(colors.red)
  term.write("Activate Turbine")
  term.setCursorPos(1,row)
  term.setBackgroundColor(colors.black)
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
      if yPos < 2 and yPos > 0 then
        rstTerm()
        print("Turbine Spinning Up")
        c.setTarget(c, 1800)
        c.begin(c)
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