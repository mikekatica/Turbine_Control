--tctl
control = {
  CNST_OFF = -1,
  CNST_SPINUP = 0,
  CNST_STABLE = 1,
  previous_error = 0,
  integral = 0,
  stableCounter = 0,
  stage = -1,
  target = 0,
  previous_error = 0,
  integral = 0,
  stableCounter = 0,
  err = 0,
  isSetUp = function (self)
    if not (t and self.target and m and self.maxFlow) then
      return 0
    else
      return 1
    end
  end,
  setUp = function (self, t, m, f, l)
    t = t
    m = m
    self.maxFlow = f
    self.log = l
  end,
  setTarget = function (self, n)
    self.target = n
  end,
  turnOn = function (self)
    if not self.stage == self.CNST_OFF then
      return -1
    end
    if t.getInputAmount() == 0 or t.getActive() then
      return 0
    else
      t.setInductorEngaged(false)
      t.setActive(true)
      return 1
    end
  end,
  spinUp = function (self)
    if not self.stage == self.CNST_SPINUP then
      return -1
    end
    local curtime = 0
    local prevtime = 0
    local dt = 0
    local calculatedFlow = 0
    local desiredFlow = self.maxFlow
    self.previous_error = 0
    self.integral = 0
    self.stableCounter = 0
    prevtime = os.clock()
    --t.setFluidFlowRateMax(self.maxFlow)
    while self.stableCounter < 1000 do
      term.clear()
      self.err = self.target - t.getRotorSpeed()
      curtime = os.clock()
      dt = curtime - prevtime
      print("dt")
      print(dt)
      print("Error")
      print(self.err)
      self.integral = self.integral + self.err*dt
      print("integral")
      print(self.integral)
      self.derivative = (self.err - self.previous_error)/dt
      print("derivative")
      print(self.derivative)
      self.val = 0.5*self.err + 0.05*self.integral + 2*self.derivative
      print("result")
      print(self.val)
      calculatedFlow = desiredFlow + self.val
      print("Calculated Flow " .. calculatedFlow)
      if calculatedFlow > self.maxFlow then
        t.setFluidFlowRateMax(self.maxFlow)
        print("Set Flow to Max")
        desiredFlow = self.maxFlow
      elseif calculatedFlow < 0 then
        t.setFluidFlowRateMax(0)
        print("Set Flow to 0")
        desiredFlow = 0
      else
        t.setFluidFlowRateMax(calculatedFlow)
        print("Set Flow to " .. calculatedFlow)
        desiredFlow = calculatedFlow
      end
      if t.getRotorSpeed() > self.target and not t.getInductorEngaged() then
        t.setInductorEngaged(true)
        print("Coils Engaged")
      end
      if self.err < 1 and self.err > -1 then
        self.stableCounter = self.stableCounter + 1
        print("Stable for")
        print(self.stableCounter)
      else
        self.stableCounter = 0
      end
      self.previous_error = self.err
      local timer = (math.floor(prevtime) == math.floor(curtime))
      print("Curtime " .. curtime)
      self.log.log(self.log, t, curtime, desiredFlow)
      if not timer then
        self.updateDisplay(self)
      end
      prevtime = curtime
      sleep(0.05)
    end
    self.stage = self.CNST_STABLE
    self.log.close(self.log)
    print("Spin Up Complete")
    return 1
  end,
  disable = function (self)
    t.setActive(false)
    self.stage = self.CNST_OFF
  end,
  begin   =       function (self)
    if not self.isSetUp(self) then
      return 0
    end
    self.result = self.turnOn(self)
    if not self.result == 1 then
      return 0
    end
    self.result = self.spinUp(self)
    if not self.result == 1 then
      return 0
    end
    return 1
  end,
  updateDisplay = function (c)
    local row = 1
    c.monitor.clear()
    c.monitor.setCursorPos(1,row)
    row = row + 1
    c.monitor.setTextColor(colors.lightBlue)
    c.monitor.write("Turbine Controller")
    c.monitor.setCursorPos(1,row)
    row = row + 1
    if c.stage == 0 then
      c.monitor.setTextColor(color.lightGrey)
      c.monitor.write("Turbine Spinning Up")
    elseif c.stage == 1 then
      c.monitor.setTextColor(colors.green)
      c.monitor.write("Turbine Stable")
    elseif c.stage == -1 then
      c.monitor.setTextColor(colors.red)
      c.monitor.write("Turbine Disabled")
    end
    c.monitor.setCursorPos(1,row)
    row = row + 1
    c.monitor.setTextColor(colors.white)
    c.monitor.write("RPM: ")
    local rpm = c.turbine.getRotorSpeed()
    if (rpm < c.target - 5) then
      c.monitor.setTextColor(colors.blue)
    elseif (rpm > 2000) then
      c.monitor.setTextColor(colors.red)
    else
      c.monitor.setTextColor(colors.lime)
    end
    c.monitor.write(rpm)
    if dFlow then
      c.monitor.setCursorPos(1,row)
      row = row + 1
      c.monitor.setTextColor(colors.white)
      c.monitor.write("Flow: ")
      c.monitor.setTextColor(colors.magenta)
      c.monitor.write(c.turbine.getFluidFlowRateMax)
    end
    c.monitor.setCursorPos(1,row)
    row = row + 1
    if c.turbine.getInductorEngaged() then
      c.monitor.setTextColor(colors.green)
      c.monitor.write("Coils Engaged")
      c.monitor.setCursorPos(1,row)
      row = row + 1
      c.monitor.setTextColor(colors.orange)
      c.monitor.write(c.turbine.getEnergyProducedLastTick() .. " RF/t")
    else
      c.monitor.setTextColor(colors.red)
      c.monitor.write("Coils Disengaged")
    end
  end,
}
logger = {
  filename,
  file,
  setFilename = function (self, n)
    if not n then
      self.filename = os.day() .. " " .. os.time()
    else
      self.filename = n
    end
  end,
  createFile = function (self)
    if not fs.exists("/soft/log/"..self.filename) then
      self.file = fs.open("/soft/log/"..self.filename,"w")
      self.file.write("Timestamp  RotorSpeed  Flow\n")
    end
  end,
  log = function (self, tc, t, f)
    self.file.write(t .. "  " .. tc.getRotorSpeed() .. "  " .. f .. "\n")
  end,
  close = function (self)
    self.file.close()
  end,
}
