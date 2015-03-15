t = peripheral.wrap("back")
m = peripheral.wrap("top")
while not multishell.getFocus() == "display" do
  tctl.control.updateDisplay(t,m)
  sleep(0.5)
end