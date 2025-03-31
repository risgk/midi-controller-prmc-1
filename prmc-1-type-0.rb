=begin
MIDI Controller PRMC-1 (type-0) v0.0.0
======================================

2025-01-30 ISGK Instruments


Required Hardware
-----------------

- Raspberry Pi Pico <https://www.raspberrypi.com/products/raspberry-pi-pico/>
- Grove Shield for Pi Pico <https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/>
- M5Stack Unit 8Angle <https://docs.m5stack.com/en/unit/8angle>
- M5Stack Unit MIDI <https://docs.m5stack.com/en/unit/Unit-MIDI>


Required Software
-----------------

- R2P2 0.3.0 <https://github.com/picoruby/R2P2/releases/tag/0.3.0>


Usage
-----

- CH1 Knob: Root of Bar 1 Chord, 1 - 14
- CH2 Knob: Root of Bar 2 Chord, 1 - 14
- CH3 Knob: Root of Bar 3 Chord, 1 - 14
- CH4 Knob: Root of Bar 4 Chord, 1 - 14
- CH5 Knob: Arpeggio Type, 1 - 6
- CH6 Knob: Filter Cutoff (Brightness), 0 - 127
- CH7 Knob: Filter Resonance (Harmonic Content), 0 - 127
- CH8 Knob: BPM, 60 - 240
- SW Switch: 1 to Start Sequencer, 0 to Stop Sequencer


License
-------

![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)

**MIDI Controller PRMC-1 (type-0) by ISGK Instruments (Ryo Ishigaki)**

To the extent possible under law, ISGK Instruments (Ryo Ishigaki)
has waived all copyright and related or neighboring rights
to MIDI Controller PRMC-1 (type-0).

You should have received a copy of the CC0 legalcode along with this
work.  If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
=end

# options
MIDI_CHANNEL = 1
FOR_SAM2695 = true
LED_ON_VALUE = 1
TRANSPOSE = 0


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

  def set_led_color_red(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 0, value)
  rescue StandardError
    retry  # workaround for Timeout error in I2C
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

  def prepare_to_get_digital_input
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_DIGITAL_INPUT_REG)
  rescue StandardError
    retry  # workaround for Timeout error in I2C
  end

  def get_digital_input
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

  def send_program_change(program_number, channel)
    @uart.write((0xC0 + (channel - 1)).chr + program_number.chr)
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
    @root_array = []
    @root_array_candidate = [1, 1, 1, 1]
    @root_array_candidate.each_with_index { |n, idx| @root_array[idx] = n }
    @pattern_array = []
    @pattern_array_candidate = [1, 1, 1, 1, 1, 1, 1, 1]
    @pattern_array_candidate.each_with_index { |n, idx| @pattern_array[idx] = n }
    @scale_note_array = [-1, 48, 50, 52, 53, 55, 57, 59,
                             60, 62, 64, 65, 67, 69, 71,
                             72, 74, 76, 77, 79, 81, 83]
    @bpm = 120

    @playing = false
    @usec = Time.now.usec
    @step = 31
    @sub_step = 11
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

    if @playing == false
      return
    end

    if ((usec - @usec + 1000000) % 1000000) >= (2500000 / @bpm)
      @usec = usec
      clock
    end
  end

  def on_parameter_changed(key, value)
    case key
    when 0..3
      @root_array_candidate[key] = ((value * (14 - 1) * 2) + 127) / 254 + 1
      set_green_leds(((@root_array_candidate[key] - 1) % 7) + 1)
    when 4
      pattern = ((value * (6 - 1) * 2) + 127) / 254 + 1

      case pattern
      when 1
        @pattern_array_candidate = [1, 3, 5, 7, 1, 3, 5, 7]
      when 2
        @pattern_array_candidate = [1, 3, 5, 7, 5, 3, 1, 3]
      when 3
        @pattern_array_candidate = [1, 3, 5, 1, 3, 5, 1, 3]
      when 4
        @pattern_array_candidate = [1, 3, 5, 3, 1, 3, 5, 3]
      when 5
        @pattern_array_candidate = [1, 4, 5, 1, 4, 5, 1, 4]
      when 6
        @pattern_array_candidate = [1, 4, 5, 4, 1, 4, 5, 4]
      end

      set_green_leds(pattern)
    when 5
      @midi.send_control_change(0x4A, value, @midi_channel)

      if FOR_SAM2695
        @midi.send_control_change(0x63, 0x01, @midi_channel)
        @midi.send_control_change(0x62, 0x20, @midi_channel)
        @midi.send_control_change(0x06, value, @midi_channel)
      end

      set_green_leds(((value * (7 - 1) * 2) + 127) / 254 + 1)
    when 6
      @midi.send_control_change(0x47, value, @midi_channel)

      if FOR_SAM2695
        @midi.send_control_change(0x63, 0x01, @midi_channel)
        @midi.send_control_change(0x62, 0x21, @midi_channel)
        @midi.send_control_change(0x06, value, @midi_channel)
      end

      set_green_leds(((value * (7 - 1) * 2) + 127) / 254 + 1)
    when 7
      @bpm = (value * 2) - 8
      @bpm = 60 if @bpm < 60
      @bpm = 240 if @bpm > 240
      set_green_leds(((value * (7 - 1) * 2) + 127) / 254 + 1)
    when 8
      if value > 0
        @step = 31
        @sub_step = 11
        @playing = true
        @midi.send_start()
      else
        if @playing_note != -1
          @midi.send_note_off(@playing_note, 64, @midi_channel)
        end

        @midi.send_stop()
        @playing = false
        @blue_leds_byte = 0x00
      end
    end
  end

  def set_blue_leds(value)
    @blue_leds_byte = [0x00, 0x01, 0x03, 0x02, 0x06, 0x04, 0x0C, 0x08].at(value)
  end

  def set_green_leds(value)
    @green_leds_byte = [0x00, 0x10, 0x30, 0x20, 0x60, 0x40, 0xC0, 0x80].at(value)
  end

  def blue_leds_byte
    @blue_leds_byte
  end

  def green_leds_byte
    @green_leds_byte
  end

  def clock
    @midi.send_clock()

    @sub_step += 1
    return if @sub_step != 12

    @sub_step = 0
    @step += 1
    @step = 0 if @step == 32
    set_blue_leds((@step / 8) * 2 + 1)

    if @step % 8 == 0
      @root_array_candidate.each_with_index { |n, idx| @root_array[idx] = n }
      @pattern_array_candidate.each_with_index { |n, idx| @pattern_array[idx] = n }
    end

    root = @root_array[@step / 8]
    new_note_index = 0

    if root != 0
      new_note_index = root + @pattern_array[@step % 8] - 1
    end

    if @playing_note != -1
      @midi.send_note_off(@playing_note, 64, @midi_channel)
    end

    if new_note_index != 0
      @playing_note = @scale_note_array[new_note_index] + TRANSPOSE
      @midi.send_note_on(@playing_note, 100, @midi_channel)
    else
      @playing_note = -1
    end
  end
end


# setup

uart1 = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31250)
i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 20 * 1000, sda_pin: 6, scl_pin: 7)
angle8 = M5UnitAngle8.new
angle8.begin(i2c1)
midi = MIDI.new
midi.begin(uart1)
prmc_1_core = PRMC1Core.new
prmc_1_core.begin(midi, MIDI_CHANNEL)

if FOR_SAM2695
  midi.send_program_change(0x51, MIDI_CHANNEL)
  midi.send_control_change(0x63, 0x01, MIDI_CHANNEL)
  midi.send_control_change(0x62, 0x66, MIDI_CHANNEL)
  midi.send_control_change(0x06, 0x60, MIDI_CHANNEL)
end

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

    angle8.prepare_to_get_digital_input()

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
