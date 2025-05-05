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
