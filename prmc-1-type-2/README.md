MIDI Controller PRMC-1 (type-2)
===============================

**Version 0.2.1 (2025-05-06)**

MIDI Controller using PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2_PICO 0.4.1 https://github.com/picoruby/R2P2/releases/tag/0.4.1
- mruby compiler 3.3.0 (mrubyコンパイラ3.3.0) https://www.s-itoc.jp/support/technical-support/mrubyc/mrubyc-download/
    - Required when modifying `mrbc prmc-1-type-2-lib.rb`
    - Run `mrbc prmc-1-type-2-lib.rb` to get `prmc-1-type-2-lib.mrb` on PC or Mac

Required Hardware
-----------------

- Raspberry Pi Pico https://www.raspberrypi.com/products/raspberry-pi-pico/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit Dual Button https://docs.m5stack.com/en/unit/dual_button (D18)
- M5Stack Unit MIDI https://docs.m5stack.com/en/unit/Unit-MIDI (Separate Mode, UART1)

Usage
-----

- Before running `prmc-1-type-2.rb` on R2P2, copy `prmc-1-type-2-lib.mrb` to `/lib`
- MIDI Channel: 1
    - Alternatively, 9 is used when the red button is pressed at the app startup
- CH1 Knob: Root of Step 1 Chord, 1 - 14 degree (C3 - B4 in C Major Scale)
- CH2 Knob: Root of Step 2 Chord, ditto
- CH3 Knob: Root of Step 3 Chord, ditto
- CH4 Knob: Root of Step 4 Chord, ditto
- CH5 Knob: Arpeggio Pattern, 1 - 16
    - Pattern 1, 9:  7th Chord, Up
    - Pattern 2, 10: 7th Chord, Up & Down
    - Pattern 3, 11: Triad, Up
    - Pattern 4, 12: Triad, Up & Down
    - Pattern 5, 13: Root + 4th + 5th, Up
    - Pattern 6, 14: Root + 4th + 5th, Up & Down
    - Pattern 7, 15: Root + 4th + 5th + 7th, Up
    - Pattern 8, 16: Root + 4th + 5th + 7th, Up & Down
    - Pattern 1 - 8: 8th Note
    - Pattern 9 - 16: 16th Note
- CH6 Knob: Sub-steps of On, 0 - 127
    - bit 0: Sub-step 2, ..., bit 6: Sub-step 8
- CH7 Knob: Brightness (Cutoff), 0 - 127
- CH8 Knob: BPM, 30 - 240
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer
- Blue Button: Transpose - (min: -12)
- Red Button: Transpose + (max: +12)

Change History
--------------

- Version 0.2.1 (2025-05-06): Combine the files for library
- Version 0.2.0 (2025-05-06): Add Arpeggio Patterns; Improve LED display; Expand BPM range; Smooth Cutoff changes
- Version 0.1.0 (2025-05-06): Remove Resonance control; Use 8 green LEDs; Add Arpeggio Patterns, Sub-steps of On, Transpose by buttons, and MIDI_CHANNEL_ALT
- Version 0.0.4 (2025-05-06): Fix README
- Version 0.0.3 (2025-05-05): Swap the contents of `prmc-1-type-2-m5-unit-angle8.rb` and `prmc-1-type-2-midi.rb`
- Version 0.0.2 (2025-05-05): Add M5Stack Unit Dual Button
- Version 0.0.1 (2025-05-05): Same features as PRMC-1 (type-1) 0.2.0

License
-------

MIDI Controller PRMC-1 (type-2) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
