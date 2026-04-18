MIDI Controller PRMC-1 (type-4)
===============================

**Version 0.2.0 (2026-04-19)**

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

- MIDI Channel: 1
    - Alternatively, 9 is used when the red button is pressed at the app startup
- Send and receive Start/Stop: false
    - Alternatively, true is used when the blue button is pressed at the app startup
- CH1 Knob: Root of Step 1 Chord, 1 - 16 degree (C3 - D5 in C Major Scale)
- CH2 Knob: Root of Step 2 Chord, Ditto
- CH3 Knob: Root of Step 3 Chord, Ditto
- CH4 Knob: Root of Step 4 Chord, Ditto
- CH5 Knob: Arpeggio Pattern, 1 - 8
    - Pattern 1, 9: Root + 3rd + 5th + 7th, Up
    - Pattern 2, 10: Root + 3rd + 5th + 7th, Up & Down
    - Pattern 3, 11: Root + 5th + 7th + 10th, Up
    - Pattern 4, 12: Root + 5th + 7th + 10th, Up & Down
    - Pattern 5, 13: Root + 5th + 7th + 11th, Up
    - Pattern 6, 14: Root + 5th + 7th + 11th, Up & Down
    - Pattern 7, 15: Root + 4th + 5th + 7th, Up
    - Pattern 8, 16: Root + 4th + 5th + 7th, Up & Down
    - Pattern 1 - 8: 8th Note
    - Pattern 9 - 16: 16th Note
- CH6 Knob: Sub-Steps of On, 0 - 127
    - bit 0: Sub-Step 2 (and 10), ..., bit 6: Sub-Step 8 (and 16)
- CH7 Knob: Brightness (Cutoff), 0 - 127 (-64 - +63)
- CH8 Knob: BPM, 56 - 300
    - BPM setting is disabled when MIDI clock is received
    - BPM setting is enabled by turning the knob
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer
- Blue Button: Transpose - (min: -24)
- Red Button: Transpose + (max: +24)
    - With the Blue Button pressed, press the Red Button to increment the program number from 0 to 7 (Program Change)

[MIDI Implementation Chart](./MIDI-Implementation-Chart.md)
----------------------------------------------------------

Known Issues
------------

- Calling methods such as `set_blue_led` sometimes result in an IOError (timeout)

Change History
--------------

- Version 0.2.0 (2026-04-19): Add 8th-note arpeggio patterns
- Version 0.1.0 (2026-04-18): Initial release

License
-------

MIDI Controller PRMC-1 (type-4) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
