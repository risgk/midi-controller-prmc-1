MIDI Controller PRMC-1 (type-3)
===============================

**Version 0.1.2 (2025-09-21)**

MIDI Controller using PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2 PICO2_W 0.5.0 https://github.com/picoruby/R2P2/releases/tag/0.5.0

Required Hardware
-----------------

- Raspberry Pi Pico 2 https://www.raspberrypi.com/products/raspberry-pi-pico-2/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit Dual Button https://docs.m5stack.com/en/unit/dual_button (D18)
- M5Stack Unit MIDI https://docs.m5stack.com/en/unit/Unit-MIDI (Separate Mode, UART1)

Usage
-----

- Before running `prmc-1-type-3.rb` on R2P2, copy `prmc-1-type-3-lib.rb` to `/lib`
- MIDI Channel: 1
    - Alternatively, 9 is used when the red button is pressed at the app startup
- Send Start/Stop: false
    - Alternatively, true is used when the blue button is pressed at the app startup
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
    - bit 0: Sub-step 2 (and 10), ..., bit 6: Sub-step 8 (and 16)
- CH7 Knob: Brightness (Cutoff), 0 - 127 (-64 - +63)
- CH8 Knob: BPM, 56 - 300
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer
- Blue Button: Transpose - (min: -24)
- Red Button: Transpose + (max: +24)

[MIDI Implementation Chart](./MIDI-Implementation-Chart.md)
----------------------------------------------------------

Known Issues
------------

- Calling methods such as `set_blue_led` sometimes result in an IOError (timeout)

Change History
--------------

- Version 0.1.2 (2025-09-21): Add workaround for CH1 blue LED flickering issue
- Version 0.1.1 (2025-09-20): Add "Known Issues" to the README
- Version 0.1.0 (2025-09-20): Same features as PRMC-1 (type-2) 0.5.2

License
-------

MIDI Controller PRMC-1 (type-3) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
