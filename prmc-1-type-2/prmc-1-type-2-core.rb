class PRMC1Core
  NUMBER_OF_STEPS = 4
  CLOCKS_PER_STEP = 96

  def initialize(midi:, midi_channel:)
    @midi = midi
    @midi_channel = midi_channel
    @bpm = 120
    @root_degrees_candidate = []
    @root_degrees = []
    @arpeggio_intervals_candidate = []
    @arpeggio_intervals = []
    @step_division_candidate = 8
    @step_division = @step_division
    @sub_steps_of_on_bits_candidate = 0xFF
    @sub_steps_of_on_bits = @sub_steps_of_on_bits
    @scale_notes = [-1, 48, 50, 52, 53, 55, 57, 59,
                        60, 62, 64, 65, 67, 69, 71,
                        72, 74, 76, 77, 79, 81, 83]
    @playing = false
    @playing_note = -1
    @step = 0
    @clock = 0
    @usec = Time.now.usec
    @usec_remain = 0
    @step_status_bits = 0x0
    @parameter_status_bits = 0x0
    @transpose_candidate = TRANSPOSE
    @transpose = @transpose_candidate
  end

  def process_sequencer
    usec = Time.now.usec
    @usec_remain += (usec - @usec + 1_000_000) % 1_000_000
    @usec = usec
    usec_per_clock = 2_500_000 / @bpm
    while @usec_remain >= usec_per_clock
      @usec_remain -= usec_per_clock
      receive_midi_clock
    end
  end

  def change_parameter(key, value)
    case key
    when 0..3
      @root_degrees_candidate[key] = (value * (14 - 1) * 2 + 127) / 254 + 1
      set_parameter_status((@root_degrees_candidate[key] - 1) % 7 + 1)
    when 4
      arpeggio_pattern = (value * (16 - 1) * 2 + 127) / 254 + 1

      case arpeggio_pattern
      when 1, 9
        @arpeggio_intervals_candidate = [1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7, 1, 3, 5, 7]
      when 2, 10
        @arpeggio_intervals_candidate = [1, 3, 5, 7, 5, 3, 1, 3, 5, 7, 5, 3, 1, 3, 5, 7]
      when 3, 11
        @arpeggio_intervals_candidate = [1, 3, 5, 1, 3, 5, 1, 3, 5, 1, 3, 5, 1, 3, 5, 1]
      when 4, 12
        @arpeggio_intervals_candidate = [1, 3, 5, 3, 1, 3, 5, 3, 1, 3, 5, 3, 1, 3, 5, 3]
      when 5, 13
        @arpeggio_intervals_candidate = [1, 4, 5, 1, 4, 5, 1, 4, 5, 1, 4, 5, 1, 4, 5, 1]
      when 6, 14
        @arpeggio_intervals_candidate = [1, 4, 5, 4, 1, 4, 5, 4, 1, 4, 5, 4, 1, 4, 5, 4]
      when 7, 15
        @arpeggio_intervals_candidate = [1, 4, 5, 7, 1, 4, 5, 7, 1, 4, 5, 7, 1, 4, 5, 7]
      when 8, 16
        @arpeggio_intervals_candidate = [1, 4, 5, 7, 5, 4, 1, 4, 5, 7, 5, 4, 1, 4, 5, 7]
      end

      case arpeggio_pattern
      when 1..8
        @step_division_candidate = 8
      when 9..16
        @step_division_candidate = 16
      end

      set_parameter_status((arpeggio_pattern - 1) % 8 + 1)
    when 5
      @sub_steps_of_on_bits_candidate = (value << 1) + 1
      @parameter_status_bits = @sub_steps_of_on_bits_candidate
    when 6
      # filter cutoff
      @midi.send_control_change(0x4A, value, @midi_channel)

      if FOR_SAM2695
        @midi.send_control_change(0x63, 0x01, @midi_channel)
        @midi.send_control_change(0x62, 0x20, @midi_channel)
        @midi.send_control_change(0x06, value, @midi_channel)
      end

      set_parameter_status_with_center_mark(value)
    when 7
      @bpm = value * 2 - 8
      @bpm = 30 if @bpm < 30
      @bpm = 240 if @bpm > 240
      set_parameter_status_with_center_mark(value)
    when 8
      if value > 0
        @midi.send_start if SEND_START_STOP
        @playing = true
        @playing_note = -1
        @step = NUMBER_OF_STEPS - 1
        @clock = CLOCKS_PER_STEP - 1
      else
        @midi.send_stop if SEND_START_STOP
        @playing = false
        @midi.send_note_off(@playing_note, NOTE_OFF_VELOCITY, @midi_channel) if @playing_note != -1
        set_step_status(0)
      end
    when 9
      @transpose_candidate -= 1 if @transpose_candidate > -12 && value == 1
      set_parameter_status_for_transpose(@transpose_candidate)
    when 10
      @transpose_candidate += 1 if @transpose_candidate < +12 && value == 1
      set_parameter_status_for_transpose(@transpose_candidate)
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
    return if !@playing
    @clock += 1

    if @clock == CLOCKS_PER_STEP
      @clock = 0
      @root_degrees_candidate.each_with_index {|item, index| @root_degrees[index] = item }
      @arpeggio_intervals_candidate.each_with_index {|item, index| @arpeggio_intervals[index] = item }
      @step_division = @step_division_candidate
      @sub_steps_of_on_bits = @sub_steps_of_on_bits_candidate
      @transpose = @transpose_candidate
      @step += 1
      @step = 0 if @step == NUMBER_OF_STEPS
      set_step_status(@step + 1)
    end

    playing_note_old = @playing_note

    if @clock % (CLOCKS_PER_STEP / @step_division) == 0
      root = @root_degrees[@step]
      sub_step = @clock / (CLOCKS_PER_STEP / @step_division)
      interval = @arpeggio_intervals[sub_step % @arpeggio_intervals.length]
      @playing_note = -1
      @playing_note = @scale_notes[root + interval - 1] + @transpose if
                      root > 0 && interval > 0 && ((1 << (sub_step % 8)) & @sub_steps_of_on_bits) > 0
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
    @parameter_status_bits = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80].at(value)
  end

  def set_parameter_status_with_center_mark(value)
    set_parameter_status((value * (8 - 1) * 2 + 127) / 254 + 1)
    @parameter_status_bits = 0x18 if value == 64
  end

  def set_parameter_status_for_transpose(value)
    @parameter_status_bits = [0x01, 0x03, 0x02, 0x06, 0x04, 0x08, 0x18, 0x10, 0x30, 0x20, 0x60, 0x40].at((value + 12) % 12)
  end
end
