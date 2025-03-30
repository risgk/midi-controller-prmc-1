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

  def begin(i2c)
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

  def prepare_to_get_analog_input_8bit(ch)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_ANALOG_INPUT_8B_REG + ch)
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end

  def get_analog_input_8bit
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


class MIDI
  # refs https://github.com/FortySevenEffects/arduino_midi_library

  def begin(uart)
    @uart = uart
  end

  def send_note_on(note_number, velocity, channel)
    @uart.write((0x90 + (channel - 1)).chr + note_number.chr + velocity.chr)
  end

  def send_note_off(note_number, velocity, channel)
    @uart.write((0x80 + (channel - 1)).chr + note_number.chr + velocity.chr)
  end

  def send_control_change(control_number, control_value, channel)
    @uart.write((0xB0 + (channel - 1)).chr + control_number.chr + control_value.chr)
  end

  def send_clock
    @uart.write(0xF8.chr)
  end

  def send_start
    @uart.write(0xFA.chr)
  end

  def send_stop
    @uart.write(0xFC.chr)
  end
end


class PRMC1Core
  def initialize
    @root_array_candidate = [0, 0, 0, 0]
    @root_array = []
    @root_array_candidate.each_with_index { |n, idx| @root_array[idx] = n }
    @pattern_array_candidate = [0, 2, 4, 6, 4, 2, 0, 2]
    @pattern_array = []
    @pattern_array_candidate.each_with_index { |n, idx| @pattern_array[idx] = n }
    @scale_note_array = [-1, 48, 50, 52, 53, 55, 57, 59,
                             60, 62, 64, 65, 67, 69, 71,
                             72, 74, 76, 77, 79, 81, 83]
    @bpm = 120

    @usec = Time.now.usec
    @count = 0
    @step = 31
    @sub_step = 7
    @playing_note = -1

    @blue_leds_byte = 0x00
    @green_leds_byte = 0x00
  end

  def begin(midi, midi_channel)
    @midi = midi
    @midi_channel = midi_channel
  end

  def process
    usec = Time.now.usec

    if ((usec - @usec + 1000000) % 1000000) >= 200000
      @usec = usec
      @count += 1

      clock
    end
  end

  def clock
    @step += 1
    @step = 0 if @step == 32

    if @step % 8 == 0
      @root_array_candidate.each_with_index { |n, idx| @root_array[idx] = n }
      @pattern_array_candidate.each_with_index { |n, idx| @pattern_array[idx] = n }
    end

    set_blue_leds_for_step(@step)

    p @step

    root = @root_array[@step / 8]
    new_note_index = 0

    if root != 0
      new_note_index = root + @pattern_array[@step % 8]
    end

    if @playing_note != -1
      @midi.send_note_off(@playing_note, 64, @midi_channel)
    end

    if new_note_index != 0
      @playing_note = @scale_note_array[new_note_index]
      @midi.send_note_on(@playing_note, 100, @midi_channel)
    else
      @playing_note = -1
    end
  end

  def on_parameter_changed(key, value)
    p [key, value]

    case key
    when 0..3
      @root_array_candidate[key] = ((value * 14 * 2) + 127) / 254 + 1
      set_green_leds_for_root(@root_array_candidate[key])
    when 4
      if value < 32
        @pattern_array_candidate = [0, 2, 4, 6, 4, 2, 0, 2]
        @green_leds_byte = 0x10
      elsif value < 96
        @pattern_array_candidate = [0, 2, 4, 0, 2, 4, 0, 2]
        @green_leds_byte = 0x20
      else
        @pattern_array_candidate = [0, 3, 4, 0, 3, 4, 0, 3]
        @green_leds_byte = 0x40
      end
    when 5
      @midi.send_control_change(0x4A, value, @midi_channel)
      @midi.send_control_change(0x63, 0x01, @midi_channel)
      @midi.send_control_change(0x62, 0x20, @midi_channel)
      @midi.send_control_change(0x06, value, @midi_channel)
      @green_leds_byte = 0x00
    when 6
      @midi.send_control_change(0x47, value, @midi_channel)
      @midi.send_control_change(0x63, 0x01, @midi_channel)
      @midi.send_control_change(0x62, 0x21, @midi_channel)
      @midi.send_control_change(0x06, value, @midi_channel)
      @green_leds_byte = 0x00
    when 7
      @bpm = value + 56
      @green_leds_byte = 0x00
    when 8
      # todo
    end
  end

  def set_blue_leds_for_step(step)
    case step / 8
    when 0
      @blue_leds_byte = 0x01
    when 1
      @blue_leds_byte = 0x02
    when 2
      @blue_leds_byte = 0x04
    when 3
      @blue_leds_byte = 0x08
    end
  end

  def set_green_leds_for_root(root)
    case root
    when 0
      @green_leds_byte = 0x00
    when 1, 8
      @green_leds_byte = 0x10
    when 2, 9
      @green_leds_byte = 0x30
    when 3, 10
      @green_leds_byte = 0x20
    when 4, 11
      @green_leds_byte = 0x60
    when 5, 12
      @green_leds_byte = 0x40
    when 6, 13
      @green_leds_byte = 0xC0
    when 7, 14
      @green_leds_byte = 0x80
    end
  end

  def blue_leds_byte
    @blue_leds_byte
  end

  def green_leds_byte
    @green_leds_byte
  end
end


# setup

LED_ON_VALUE = 1
MIDI_CHANNEL = 1

uart1 = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31250)

i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 20 * 1000, sda_pin: 6, scl_pin: 7)
angle8 = M5UnitAngle8.new
angle8.begin(i2c1)

midi = MIDI.new
midi.begin(uart1)

# uart1.write((0xC0 + (MIDI_CHANNEL - 1)).chr + 0x26.chr)
midi.send_note_on(60, 100, MIDI_CHANNEL)
sleep 1
midi.send_note_off(60, 64, MIDI_CHANNEL)

prmc_1_core = PRMC1Core.new
prmc_1_core.begin(midi, MIDI_CHANNEL)

current_analog_input_array = [nil, nil, nil, nil, nil, nil, nil, nil, nil]
current_digital_input      = nil


# loop

loop do
  (0..7).each do |ch|
    prmc_1_core.process()

    angle8.prepare_to_get_analog_input_8bit(ch)

    prmc_1_core.process()

    analog_input = angle8.get_analog_input_8bit

    if current_analog_input_array[ch].nil? ||
       (analog_input > current_analog_input_array[ch] + 1) ||
       (analog_input < current_analog_input_array[ch] - 1)
      current_analog_input_array[ch] = analog_input
      prmc_1_core.on_parameter_changed(ch, 127 - (current_analog_input_array[ch] / 2))
    end
  end

  begin
    prmc_1_core.process()

    digital_input = angle8.get_digital_input()

    if current_digital_input != digital_input
      current_digital_input = digital_input
      prmc_1_core.on_parameter_changed(8, digital_input)
    end
  end

  (0..3).each do |ch|
    prmc_1_core.process()

    angle8.set_led_color_blue(ch, ((prmc_1_core.blue_leds_byte >> ch) & 0x01) * LED_ON_VALUE)
  end

  (4..7).each do |ch|
    prmc_1_core.process()

    angle8.set_led_color_green(ch, ((prmc_1_core.green_leds_byte >> ch) & 0x01) * LED_ON_VALUE)
  end
end
