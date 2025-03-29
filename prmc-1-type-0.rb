=begin
MIDI Controller PRMC-1 (type-0) v0.0.0
======================================

2025-01-30 ISGK Instruments


Hardware
--------

- Raspberry Pi Pico <https://www.raspberrypi.com/products/raspberry-pi-pico/>
- Grove Shield for Pi Pico <https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/>
- M5Stack Unit 8Angle <https://docs.m5stack.com/en/unit/8angle>
- M5Stack Unit MIDI <https://docs.m5stack.com/en/unit/Unit-MIDI>


Software
--------

- R2P2 0.3.0 <https://github.com/picoruby/R2P2/releases/tag/0.3.0>


Usage
-----

- TODO
=end

require 'uart'
require 'i2c'


class M5UnitAngle8
  # refs https://github.com/m5stack/M5Unit-8Angle

  ANGLE8_I2C_ADDR            = 0x43
  ANGLE8_ANALOG_INPUT_8B_REG = 0x10
  ANGLE8_DIGITAL_INPUT_REG   = 0x20
  ANGLE8_RGB_24B_REG         = 0x30

  def initialize(i2c)
    @i2c = i2c
  end

  def set_led_color_green(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 1, value)
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end

  def set_led_color_blue(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 2, value)
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end

  def get_analog_input_8bit(ch)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_ANALOG_INPUT_8B_REG + ch)
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end

  def get_digital_input
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_DIGITAL_INPUT_REG)
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end
end


class PRMC1Core
  def initialize
    @led_byte = 0xFF
  end

  def on_parameter_changed(key, value)
    p [key, value]
  end

  def get_led_byte
    @led_byte
  end
end


# setup

LED_ON_VALUE = 1

uart = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31250)
uart.write "\x90\x3C\x7F"
sleep 1
uart.write "\x80\x3C\x40"

i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 25 * 1000, sda_pin: 6, scl_pin: 7)
angle8 = M5UnitAngle8.new(i2c1)
prmc_1_core = PRMC1Core.new

current_analog_input_array = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
current_digital_input      = nil


# loop

loop do
  (0..7).each do |ch|
    analog_input = angle8.get_analog_input_8bit(ch)

    if current_analog_input_array[ch].nil?
      current_analog_input_array[ch] = analog_input
    elsif (analog_input > current_analog_input_array[ch] + 1) ||
          (analog_input < current_analog_input_array[ch] - 1)
      current_analog_input_array[ch] = analog_input
      prmc_1_core.on_parameter_changed(ch, 127 - (analog_input / 2))
    end
  end

  digital_input = angle8.get_digital_input()

  if current_digital_input != digital_input
    current_digital_input = digital_input
    prmc_1_core.on_parameter_changed(8, digital_input)
  end

  led_byte_output = prmc_1_core.get_led_byte()

  (0..3).each do |ch|
    angle8.set_led_color_blue(ch, ((led_byte_output >> ch) & 0x01) * LED_ON_VALUE)
  end

  (4..7).each do |ch|
    angle8.set_led_color_green(ch, ((led_byte_output >> ch) & 0x01) * LED_ON_VALUE)
  end
end
