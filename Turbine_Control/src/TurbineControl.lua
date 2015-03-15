if not tctl then
  os.loadAPI("soft/tctl")
end
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
            term.setBackgroundColoe(colors.black)
            end
c = tctl.control
t = peripheral.wrap("back")
m = peripheral.wrap("top")
l = tctl.logger
exit = false
l.setFilename(l, nil)
l.createFile(l)
c.setUp(c,t,m,800,l)
term.clear()
while not exit do
local event, button, xPos, yPos = os.pullEvent("mouse_click")
rstTerm()
printMenu()
c.updateDisplay(c, nil)
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