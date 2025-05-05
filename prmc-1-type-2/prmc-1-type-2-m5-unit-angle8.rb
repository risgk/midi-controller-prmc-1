class M5UnitAngle8
  # refs https://github.com/m5stack/M5Unit-8Angle
  ANGLE8_I2C_ADDR            = 0x43
  ANGLE8_ANALOG_INPUT_8B_REG = 0x10
  ANGLE8_DIGITAL_INPUT_REG   = 0x20
  ANGLE8_RGB_24B_REG         = 0x30

  def initialize(i2c:)
    @i2c = i2c
  end

  def prepare_to_get_analog_input(ch)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_ANALOG_INPUT_8B_REG + ch)
  end

  def get_analog_input
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  end

  def prepare_to_get_digital_input
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_DIGITAL_INPUT_REG)
  end

  def get_digital_input
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  end

  def set_red_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 0, value)
  end

  def set_green_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 1, value)
  end

  def set_blue_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 2, value)
  end
end
