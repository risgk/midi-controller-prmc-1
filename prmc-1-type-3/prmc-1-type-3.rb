require 'prmc-1-type-3-lib'
require 'i2c'
require 'uart'

# options
MIDI_CHANNEL = 1
MIDI_CHANNEL_ALT = 9  # used when the red button is pressed at the app startup
SEND_START_STOP = false  # inverted when the blue button is pressed at the app startup
TRANSPOSE = 0  # min: -12, max: +12
GATE_TIME = 3  # min: 1, max: 6
NOTE_ON_VELOCITY = 100
NOTE_OFF_VELOCITY = 64
LED_ON_VALUE = 1
FOR_SAM2695 = true

# setup
i2c1 = I2C.new(unit: :RP2040_I2C1, frequency: 400_000, sda_pin: 6, scl_pin: 7, timeout: 2)
angle8 = M5UnitAngle8.new(i2c: i2c1)
dual_button = M5UnitDualButton.new(gpio_blue_button: 18, gpio_red_button: 19)
uart1 = UART.new(unit: :RP2040_UART1, txd_pin: 4, rxd_pin: 5, baudrate: 31_250)
midi = MIDI.new(uart: uart1)
current_inputs = [nil, nil, nil, nil, nil, nil, nil, nil, 0, 0, 0]
current_inputs[9] = dual_button.get_blue_button_input
current_inputs[10] = dual_button.get_red_button_input
midi_channel = MIDI_CHANNEL
midi_channel = MIDI_CHANNEL_ALT if current_inputs[10] == 1
send_start_stop = SEND_START_STOP
send_start_stop = !send_start_stop if current_inputs[9] == 1
prmc_1_core = PRMC1Core.new(midi: midi, midi_channel: midi_channel, send_start_stop: send_start_stop)

if FOR_SAM2695
  midi.send_program_change(0x51, midi_channel)

  # filter resonance
  midi.send_control_change(0x63, 0x01, midi_channel)
  midi.send_control_change(0x62, 0x21, midi_channel)
  midi.send_control_change(0x06, 0x7F, midi_channel)

  # envelope release time
  midi.send_control_change(0x63, 0x01, midi_channel)
  midi.send_control_change(0x62, 0x66, midi_channel)
  midi.send_control_change(0x06, 0x60, midi_channel)
end

led_builtin = GPIO.new(25, GPIO::OUT)
led_builtin.write(1)

# loop
loop do
  analog_input = 0
  digital_input = 0
  blue_button_input = 0
  red_button_input = 0

  [6, 0, 1, 2, 3, 4, 5, 6, 7].each do |ch|
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

  prmc_1_core.process_sequencer
  angle8.prepare_to_get_digital_input
  prmc_1_core.process_sequencer
  digital_input = angle8.get_digital_input

  if current_inputs[8] != digital_input
    current_inputs[8] = digital_input
    prmc_1_core.change_parameter(8, current_inputs[8])
  end

  blue_button_input = dual_button.get_blue_button_input

  if current_inputs[9] != blue_button_input
    current_inputs[9] = blue_button_input
    prmc_1_core.change_parameter(9, current_inputs[9])
  end

  red_button_input = dual_button.get_red_button_input

  if current_inputs[10] != red_button_input
    current_inputs[10] = red_button_input
    prmc_1_core.change_parameter(10, current_inputs[10])
  end

  (0..3).each do |ch|
    prmc_1_core.process_sequencer
    angle8.set_blue_led(ch, (prmc_1_core.step_status_bits >> ch & 0x01) * LED_ON_VALUE)
  end

  (0..7).each do |ch|
    prmc_1_core.process_sequencer
    angle8.set_green_led(ch, (prmc_1_core.parameter_status_bits >> ch & 0x01) * LED_ON_VALUE)
  end
end
