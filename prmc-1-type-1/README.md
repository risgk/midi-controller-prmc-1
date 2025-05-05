MIDI Controller PRMC-1 (type-1)
===============================

**Version 0.2.1 (2025-05-05)**

MIDI Controller using PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2_PICO 0.4.1 https://github.com/picoruby/R2P2/releases/tag/0.4.1
- mruby compiler 3.3.0 (mrubyコンパイラ3.3.0) https://www.s-itoc.jp/support/technical-support/mrubyc/mrubyc-download/
    - Required when modifying `prmc-1-type-1-m5-unit-angle8.rb` or `prmc-1-type-1-midi.rb`
    - Run `mrbc prmc-1-type-1-m5-unit-angle8.rb` to get `prmc-1-type-1-m5-unit-angle8.mrb` on PC or Mac
    - Same for `prmc-1-type-1-midi.mrb`

Required Hardware
-----------------

- Raspberry Pi Pico https://www.raspberrypi.com/products/raspberry-pi-pico/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit MIDI https://docs.m5stack.com/en/unit/Unit-MIDI (Separate Mode, UART1)

Usage
-----

- Before running `prmc-1-type-1.rb` on R2P2, copy `prmc-1-type-1-m5-unit-angle8.mrb` and `prmc-1-type-1-midi.mrb` to `/lib`
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

Change History
--------------

- Version 0.2.1 (2025-05-05): Swap the contents of `prmc-1-type-1-m5-unit-angle8.rb` and `prmc-1-type-1-midi.rb`
- Version 0.2.0 (2025-05-04): Split `prmc-1-type-1.rb` for ease of modification
- Version 0.1.0 (2025-05-03): Same features as PRMC-1 (type-0) 0.2.1

License
-------

MIDI Controller PRMC-1 (type-1) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
