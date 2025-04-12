=begin
MIDI Controller PRMC-1 (type-0)
===============================

**Version 0.0.0 (2025-04-12)**

MIDI Controller with PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2 0.3.0 https://github.com/picoruby/R2P2/releases/tag/0.3.0

Required Hardware
-----------------

- Raspberry Pi Pico https://www.raspberrypi.com/products/raspberry-pi-pico/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit MIDI https://docs.m5stack.com/en/unit/Unit-MIDI (UART1)

Usage
-----

- CH1 Knob: Root of Step 1 Chord, 1 - 14 degree (C3 - B4 in C Major Scale)
- CH2 Knob: Root of Step 2 Chord, ditto
- CH3 Knob: Root of Step 3 Chord, ditto
- CH4 Knob: Root of Step 4 Chord, ditto
- CH5 Knob: Arpeggio Pattern, 1 - 6
    - Pattern 1: Triad, Up, 8th Note
    - Pattern 2: Triad, Up & Down, 8th Note
    - Pattern 3: 7th Chord, Up, 8th Note
    - Pattern 4: 7th Chord, Up & Down, 8th Note
    - Pattern 5: Root + 4th + 5th, Up, 8th Note
    - Pattern 6: Root + 4th + 5th, Up & Down, 8th Note
- CH6 Knob: Brightness (Cutoff), 0 - 127
- CH7 Knob: Harmonic Content (Resonance), 0 - 127
- CH8 Knob: BPM, 60 - 240
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer

License
-------

MIDI Controller PRMC-1 (type-0) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
=end

require 'i2c'
require 'uart'

# options
MIDI_CHANNEL = 1
TRANSPOSE = 0
GATE_TIME = 3  # min: 1, max: 6
NOTE_ON_VELOCITY = 100
NOTE_OFF_VELOCITY = 64
LED_ON_VALUE = 1
FOR_SAM2695 = true

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
  rescue
    retry
  end

  def get_analog_input
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  rescue
    retry
  end

  def prepare_to_get_digital_input
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_DIGITAL_INPUT_REG)
  rescue
    retry
  end

  def get_digital_input
    @i2c.read(ANGLE8_I2C_ADDR, 1).bytes[0]
  rescue
    retry
  end

  def set_red_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 0, value)
  rescue
    retry
  end

  def set_green_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 1, value)
  rescue
    retry
  end

  def set_blue_led(ch, value)
    @i2c.write(ANGLE8_I2C_ADDR, ANGLE8_RGB_24B_REG + ch * 4 + 2, value)
  rescue
    retry
  end
end

class MIDI
  # refs https://github.com/FortySevenEffects/arduino_midi_library
  def initialize(uart:)
    @uart = uart
  end

  def send_note_on(note_number, velocity, channel)
    @uart.write((0x90 + channel - 1).chr + note_number.chr + velocity.chr)
  end

  def send_note_off(note_number, velocity, channel)
    @uart.write((0x80 + channel - 1).chr + note_number.chr + velocity.chr)
  end

  def send_control_change(control_number, control_value, channel)
    @uart.write((0xB0 + channel - 1).chr + control_number.chr + control_value.chr)
  end

  def send_program_change(program_number, channel)
    @uart.write((0xC0 + channel - 1).chr + program_number.chr)
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
  NUMBER_OF_STEPS = 4
  CLOCKS_PER_STEP = 96

  def initialize(midi:, midi_channel:)
    @midi = midi
    @midi_channel = midi_channel
    @bpm = 0
    @root_degrees = []
    @root_degrees_candidate = []
    @arpeggio_intervals = []
    @arpeggio_intervals_candidate = []
    @step_division = 8
    @step_division_candidate = 8
    @scale_notes = [-1, 48, 50, 52, 53, 55, 57, 59,
                        60, 62, 64, 65, 67, 69, 71,
                        72, 74, 76, 77, 79, 81, 83]
    @playing = false
    @playing_note = -1
    @step = 0
    @clock = 0
    @usec = 0
    @usec_remain = 0
    @step_status_bits = 0x0
    @parameter_status_bits = 0x0
  end

  def process_sequencer
    if @playing
      usec = Time.now.usec
      @usec_remain += (usec - @usec + 1_000_000) % 1_000_000
      @usec = usec
      usec_per_clock = 2_500_000 / @bpm
      while @usec_remain >= usec_per_clock
        @usec_remain -= usec_per_clock
        receive_midi_clock
      end
    end
  end

  def change_parameter(key, value)
    case key
    when 0..3
      @root_degrees_candidate[key] = (value * (14 - 1) * 2 + 127) / 254 + 1
      set_parameter_status((@root_degrees_candidate[key] - 1) % 7 + 1)
    when 4
      arpeggio_pattern = (value * (6 - 1) * 2 + 127) / 254 + 1

      case arpeggio_pattern
      when 1
        @arpeggio_intervals_candidate = [1, 3, 5, 7, 1, 3, 5, 7]
        @step_division_candidate = 8
      when 2
        @arpeggio_intervals_candidate = [1, 3, 5, 7, 5, 3, 1, 3]
        @step_division_candidate = 8
      when 3
        @arpeggio_intervals_candidate = [1, 3, 5, 1, 3, 5, 1, 3]
        @step_division_candidate = 8
      when 4
        @arpeggio_intervals_candidate = [1, 3, 5, 3, 1, 3, 5, 3]
        @step_division_candidate = 8
      when 5
        @arpeggio_intervals_candidate = [1, 4, 5, 1, 4, 5, 1, 4]
        @step_division_candidate = 8
      when 6
        @arpeggio_intervals_candidate = [1, 4, 5, 4, 1, 4, 5, 4]
        @step_division_candidate = 8
      end

      set_parameter_status(arpeggio_pattern)
    when 5
      # filter cutoff
      @midi.send_control_change(0x4A, value, @midi_channel)

      if FOR_SAM2695
        @midi.send_control_change(0x63, 0x01, @midi_channel)
        @midi.send_control_change(0x62, 0x20, @midi_channel)
        @midi.send_control_change(0x06, value, @midi_channel)
      end

      set_parameter_status((value * (7 - 1) * 2 + 127) / 254 + 1)
    when 6
      # filter resonance
      @midi.send_control_change(0x47, value, @midi_channel)

      if FOR_SAM2695
        @midi.send_control_change(0x63, 0x01, @midi_channel)
        @midi.send_control_change(0x62, 0x21, @midi_channel)
        @midi.send_control_change(0x06, value, @midi_channel)
      end

      set_parameter_status((value * (7 - 1) * 2 + 127) / 254 + 1)
    when 7
      @bpm = value * 2 - 8
      @bpm = 60 if @bpm < 60
      @bpm = 240 if @bpm > 240
      set_parameter_status((value * (7 - 1) * 2 + 127) / 254 + 1)
    when 8
      if value > 0
        @midi.send_start
        @playing = true
        @playing_note = -1
        @step = NUMBER_OF_STEPS - 1
        @clock = CLOCKS_PER_STEP - 1
        @usec = Time.now.usec
        @usec_remain = 0
      else
        @midi.send_stop
        @playing = false
        @midi.send_note_off(@playing_note, NOTE_OFF_VELOCITY, @midi_channel) if @playing_note != -1
        set_step_status(0)
      end
    end
  end

  def step_status_bits
    @step_status_bits
  end

  def parameter_status_bits
    @parameter_status_bits
  end

  # private

  def receive_midi_clock
    @midi.send_clock
    @clock += 1

    if @clock == CLOCKS_PER_STEP
      @clock = 0
      @root_degrees_candidate.each_with_index { |item, index| @root_degrees[index] = item }
      @arpeggio_intervals_candidate.each_with_index { |item, index| @arpeggio_intervals[index] = item }
      @step_division = @step_division_candidate
      @step += 1
      @step = 0 if @step == NUMBER_OF_STEPS
      set_step_status(@step + 1)
    end

    playing_note_old = @playing_note

    if @clock % (CLOCKS_PER_STEP / @step_division) == 0
      root = @root_degrees[@step]
      interval = @arpeggio_intervals[@clock / (CLOCKS_PER_STEP / @step_division)]
      @playing_note = -1
      @playing_note = @scale_notes[root + interval - 1] + TRANSPOSE if root > 0 && interval > 0
      @midi.send_note_on(@playing_note, NOTE_ON_VELOCITY, @midi_channel) if @playing_note != -1
    end

    if @clock % (CLOCKS_PER_STEP / @step_division) ==
       CLOCKS_PER_STEP * GATE_TIME / 6 / @step_division % (CLOCKS_PER_STEP / @step_division)
      @midi.send_note_off(playing_note_old, NOTE_OFF_VELOCITY, @midi_channel) if playing_note_old != -1
    end
  end

  def set_step_status(value)
    @step_status_bits = [0x0, 0x1, 0x2, 0x4, 0x8].at(value)
  end

  def set_parameter_status(value)
    @parameter_status_bits = [0x0, 0x1, 0x3, 0x2, 0x6, 0x4, 0xC, 0x8].at(value)
  end
end

# setup
i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 20_000, sda_pin: 6, scl_pin: 7)
angle8 = M5UnitAngle8.new(i2c: i2c1)
uart1 = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31_250)
midi = MIDI.new(uart: uart1)
prmc_1_core = PRMC1Core.new(midi: midi, midi_channel: MIDI_CHANNEL)
current_inputs = []

if FOR_SAM2695
  midi.send_program_change(0x51, MIDI_CHANNEL)
  midi.send_control_change(0x63, 0x01, MIDI_CHANNEL)
  midi.send_control_change(0x62, 0x66, MIDI_CHANNEL)
  midi.send_control_change(0x06, 0x60, MIDI_CHANNEL)
end

# loop
loop do
  (0..7).each do |ch|
    prmc_1_core.process_sequencer
    angle8.prepare_to_get_analog_input(ch)
    prmc_1_core.process_sequencer
    analog_input = angle8.get_analog_input

    if current_inputs[ch].nil? ||
       analog_input > current_inputs[ch] + 1 ||
       analog_input < current_inputs[ch] - 1
      current_inputs[ch] = analog_input
      prmc_1_core.change_parameter(ch, 127 - current_inputs[ch] / 2)
    end
  end

  begin
    prmc_1_core.process_sequencer
    angle8.prepare_to_get_digital_input
    prmc_1_core.process_sequencer
    digital_input = angle8.get_digital_input

    if current_inputs[8] != digital_input
      current_inputs[8] = digital_input
      prmc_1_core.change_parameter(8, current_inputs[8])
    end
  end

  (0..3).each do |ch|
    prmc_1_core.process_sequencer
    angle8.set_blue_led(ch, (prmc_1_core.step_status_bits >> ch & 0x01) * LED_ON_VALUE)
  end

  (4..7).each do |ch|
    prmc_1_core.process_sequencer
    angle8.set_green_led(ch, (prmc_1_core.parameter_status_bits << 4 >> ch & 0x01) * LED_ON_VALUE)
  end
end
