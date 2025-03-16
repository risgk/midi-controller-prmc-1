# 
# MIDI Controller PRMC-1
# 

require 'uart'
require 'i2c'


class M5Unit8Angle
  # refs https://github.com/m5stack/M5Unit-8Angle

  ANGLE8_I2C_ADDR            = 0x43
  ANGLE8_ANALOG_INPUT_8B_REG = 0x10

  def initialize(i2c)
    @i2c = i2c
  end

  def get_analog_input_8bit(ch)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_ANALOG_INPUT_8B_REG + ch)
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  rescue IOError
    # workaround for IOError: Timeout error in I2C
    retry
  end
end


# setup

uart = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31250)
uart.write "\x90\x3C\x7F"
sleep 1
uart.write "\x80\x3C\x40"

i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 100 * 1000, sda_pin: 6, scl_pin: 7)

m5_unit_8angle = M5Unit8Angle.new(i2c1)

current_analog_inputs = [nil, nil, nil, nil, nil, nil, nil, nil]


# loop

loop do
  (0..7).each do |i|
    analog_input = m5_unit_8angle.get_analog_input_8bit(i) +
                   m5_unit_8angle.get_analog_input_8bit(i) + 2

    if current_analog_inputs[i].nil?
      current_analog_inputs[i] = analog_input
      # p [i, analog_input]
    elsif (analog_input > current_analog_inputs[i] + 2) ||
          (analog_input < current_analog_inputs[i] - 2)
      current_analog_inputs[i] = analog_input
      p [i, current_analog_inputs[i], analog_input, [127 - (analog_input / 4), 127].min]
    end
  end
end
