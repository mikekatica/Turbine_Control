--tctl
control = {
  CNST_OFF = -1,
  CNST_SPINUP = 0,
  CNST_STABLE = 1,
  previous_error = 0,
  stage = -1,
  target = 0,
  kp = 0.5,
  ki = 0,
  kd = 2,
  isSetUp = function (self)
    if not (self.turbine and self.target and self.monitor and self.maxFlow) then
      return 0
    else
      return 1
    end
  end,
  setUp = function (self, t, m, f, l)
    self.turbine = t
    self.monitor = m
    self.maxFlow = f
    self.log = l
  end,
  setConstants = function (self, p, i, d)
    self.kp = p
    self.kd = d
    self.ki = i
  end,
  setTarget = function (self, n)
    self.target = n
  end,
  turnOn = function (self)
    if not self.stage == self.CNST_OFF then
      return -1
    end
    if self.turbine.getInputAmount() == 0 or self.turbine.getActive() then
      return 0
    else
      self.turbine.setInductorEngaged(false)
      self.turbine.setActive(true)
      return 1
    end
  end,
  spinUp = function (self)
    if not self.stage == self.CNST_SPINUP then
      return -1
    end
    curtime = 0
    prevtime = 0
    dt = 0
    calculatedFlow = 0
    desiredFlow = self.maxFlow
    val = 0
    integral = 0
    derivative = 0
    err = 0
    previous_error = 0
    stableCounter = 0
    prevtime = os.clock() - 0.01
    --t.setFluidFlowRateMax(self.maxFlow)
    while stableCounter < 1000 do
      term.clear()
      term.setCursorPos(1,1)
      err = self.target - self.turbine.getRotorSpeed()
      curtime = os.clock()
      dt = curtime - prevtime
      print("dt: "..dt)
      print("Error: "..err)
      integral = integral + err*dt
      print("integral: "..integral)
      derivative = (err - previous_error)/dt
      print("derivative: "..derivative)
      val = self.kp*err + self.ki*integral + self.kd*derivative
      print("result: "..val)
      calculatedFlow = desiredFlow + val
      print("Desired Flow: " .. desiredFlow)
      print("Calculated Flow: " .. calculatedFlow)
      if calculatedFlow > self.maxFlow then
        self.turbine.setFluidFlowRateMax(self.maxFlow)
        print("Set Flow to Max")
        desiredFlow = self.maxFlow
      elseif calculatedFlow < 0 then
        self.turbine.setFluidFlowRateMax(0)
        print("Set Flow to 0")
        desiredFlow = 0
      else
        self.turbine.setFluidFlowRateMax(calculatedFlow)
        print("Set Flow to " .. calculatedFlow)
        desiredFlow = calculatedFlow
      end
      if self.turbine.getRotorSpeed() > (self.target - 50) and not self.turbine.getInductorEngaged() then
        self.turbine.setInductorEngaged(true)
        print("Coils Engaged")
      end
      if err < 1 and err > -1 then
        stableCounter = stableCounter + 1
        print("Stable for")
        print(stableCounter)
      else
        stableCounter = 0
      end
      previous_error = err
      local timer = (math.floor(prevtime) == math.floor(curtime))
      print("Curtime " .. curtime)
      self.log.log(self.log, self.turbine, curtime, desiredFlow)
      --if not timer then
      --self.updateDisplay(self)
      --end
      prevtime = curtime
      sleep(0.05)
    end
    self.stage = self.CNST_STABLE
    self.log.close(self.log)
    print("Spin Up Complete")
    return 1
  end,
  disable = function (self)
    self.turbine.setActive(false)
    while self.turbine.getRotorSpeed() > 10 do
      sleep(1)
    end
    self.turbine.setInductorEngaged(false)
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
  updateDisplay = function (self)
    local row = 1
    self.monitor.clear()
    self.monitor.setCursorPos(1,row)
    row = row + 1
    self.monitor.setTextColor(colors.lightBlue)
    self.monitor.write("Turbine Controller")
    self.monitor.setCursorPos(1,row)
    row = row + 1
    self.monitor.setTextColor(colors.white)
    self.monitor.write("RPM: ")
    local rpm = self.turbine.getRotorSpeed()
    if (rpm < self.target - 5) then
      self.monitor.setTextColor(colors.blue)
    elseif (rpm > 2000) then
      self.monitor.setTextColor(colors.red)
    else
      self.monitor.setTextColor(colors.lime)
    end
    self.monitor.write(rpm)
    self.monitor.setCursorPos(1,row)
    row = row + 1
    self.monitor.setTextColor(colors.white)
    self.monitor.write("Flow: ")
    self.monitor.setTextColor(colors.magenta)
    self.monitor.write(self.turbine.getFluidFlowRateMax())
    self.monitor.setCursorPos(1,row)
    row = row + 1
    if self.turbine.getInductorEngaged() then
      self.monitor.setTextColor(colors.green)
      self.monitor.write("Coils Engaged")
      self.monitor.setCursorPos(1,row)
      row = row + 1
      self.monitor.setTextColor(colors.orange)
      self.monitor.write(self.turbine.getEnergyProducedLastTick() .. " RF/t")
    else
      self.monitor.setTextColor(colors.red)
      self.monitor.write("Coils Disengaged")
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
