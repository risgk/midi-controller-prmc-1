=begin
MIDI Controller PRMC-1 (type-0) v0.0.0
======================================

2025-01-30 ISGK Instruments


Hardware
--------

- Raspberry Pi Pico <https://www.raspberrypi.com/products/raspberry-pi-pico/>
- Grove Shield for Pi Pico <https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/>
- M5Stack Unit ByteButton <https://docs.m5stack.com/en/unit/Unit%20ByteButton>
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


class M5UnitByteButton
  # refs https://github.com/m5stack/M5Unit-ByteButton

  UNIT_BYTE_BUTTON_I2C_ADDR = 0x47
  UNIT_BYTE_STATUS_REG      = 0x00

  def initialize(i2c)
    @i2c = i2c
  end

  def get_switch_status
    @i2c.write(UNIT_BYTE_BUTTON_I2C_ADDR, UNIT_BYTE_STATUS_REG)
    @i2c.read(UNIT_BYTE_BUTTON_I2C_ADDR, 1).bytes[0]
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end
end


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


# setup

ANGLE8_LED_ON_VALUE = 64

uart = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31250)
uart.write "\x90\x3C\x7F"
sleep 1
uart.write "\x80\x3C\x40"

i2c1        = I2C.new(unit: :RP2040_I2C1, frequency: 50 * 1000, sda_pin: 6, scl_pin: 7)
byte_button = M5UnitByteButton.new(i2c1)
angle8      = M5UnitAngle8.new(i2c1)

current_byte_button_switch_status = nil
current_angle8_analog_input_array = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
current_angle8_digital_input      = nil
current_angle8_led_g_array        = [1, 1, 1, 1, 1, 1, 1, 1]


# loop

loop do
  byte_button_switch_status = 0xFF & ~byte_button.get_switch_status()

  if current_byte_button_switch_status != byte_button_switch_status
    current_byte_button_switch_status = byte_button_switch_status
    p [-1, current_byte_button_switch_status]
  end

  (0..7).each do |ch|
    angle8_analog_input_8bit = angle8.get_analog_input_8bit(ch)

    if current_angle8_analog_input_array[ch].nil?
      current_angle8_analog_input_array[ch] = angle8_analog_input_8bit
    elsif (angle8_analog_input_8bit > current_angle8_analog_input_array[ch] + 1) ||
          (angle8_analog_input_8bit < current_angle8_analog_input_array[ch] - 1)
      current_angle8_analog_input_array[ch] = angle8_analog_input_8bit
      p [ch, current_angle8_analog_input_array[ch], angle8_analog_input_8bit, 127 - (angle8_analog_input_8bit / 2)]
    end
  end

  angle8_digital_input = angle8.get_digital_input()

  if current_angle8_digital_input != angle8_digital_input
    current_angle8_digital_input = angle8_digital_input
    p [8, angle8_digital_input]
  end

  (0..7).each do |ch|
    angle8.set_led_color_green(ch, current_angle8_led_g_array[ch] * ANGLE8_LED_ON_VALUE)
  end
end
