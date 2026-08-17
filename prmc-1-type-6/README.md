MIDI Controller PRMC-1 (type-6)
===============================

**Version 0.5.1 (2026-08-17)**

MIDI Controller using PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2 PICO2_W 0.5.0 https://github.com/picoruby/R2P2/releases/tag/0.5.0

Required Hardware
-----------------

- Raspberry Pi Pico 2 https://www.raspberrypi.com/products/raspberry-pi-pico-2/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit ByteSwitch https://docs.m5stack.com/en/unit/Unit%20ByteSwitch (I2C1)
- M5Stack Unit Dual Button https://docs.m5stack.com/en/unit/dual_button (D18)
- M5Stack Unit MIDI https://docs.m5stack.com/en/unit/Unit-MIDI (Separate Mode, UART1)

Usage
-----

- MIDI Channel: 1
    - Alternatively, 2 is used when the red button is pressed at the app startup
- Send and receive Start/Stop: true
    - Alternatively, false is used when the blue button is pressed at the app startup
- CH1 Knob: Root of Step 1 Chord, 1 - 16 degree (C3 - D5 in C Major Scale)
- CH2 Knob: Root of Step 2 Chord, Ditto
- CH3 Knob: Root of Step 3 Chord, Ditto
- CH4 Knob: Root of Step 4 Chord, Ditto
- CH5 Knob: Arpeggio Pattern, 1 - 32
    - Pattern 1, 17: Root + 3rd + 5th + 7th, Up
    - Pattern 2, 18: Root + 3rd + 5th + 7th, Up & Down
    - Pattern 3, 19: Root + 3rd + 5th, Up
    - Pattern 4, 20: Root + 3rd + 5th, Up & Down
    - Pattern 5, 21: Root + 4th + 5th, Up
    - Pattern 6, 22: Root + 4th + 5th, Up & Down
    - Pattern 7, 23: Root + 4th + 5th + 7th, Up
    - Pattern 8, 24: Root + 4th + 5th + 7th, Up & Down
    - Pattern 9, 25:  Root + 3rd + 5th + 7th, Up
    - Pattern 10, 26: Root + 3rd + 5th + 7th, Up & Down
    - Pattern 11, 27: Root + 5th + 7th + 10th, Up
    - Pattern 12, 28: Root + 5th + 7th + 10th, Up & Down
    - Pattern 13, 29: Root + 5th + 7th + 11th, Up
    - Pattern 14, 30: Root + 5th + 7th + 11th, Up & Down
    - Pattern 15, 31: Root + 4th + 5th + 7th, Up
    - Pattern 16, 32: Root + 4th + 5th + 7th, Up & Down
    - Pattern 1 - 16: 8th Note
    - Pattern 17 - 32: 16th Note
- CH6 Knob: Diatonic Transpose, 1 - 8
- CH7 Knob: Brightness (Cutoff), 0 - 64 - 127 (-64 - +0 - +63)
- CH8 Knob: BPM, 30 - 120 - 240
    - BPM setting is disabled when MIDI clock is received
    - BPM setting is enabled by turning the knob
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer
- Blue Button: Transpose - (min: -24)
- Red Button: Transpose + (max: +24)
    - With the Blue Button pressed, press the Red Button to increment the program number from 0 to 7 (Program Change)
- Byte Switch: Sub-Steps of On, 0 - 255
    - bit 7: Sub-Step 1 (and 9), ..., bit 0: Sub-Step 8 (and 16)

[MIDI Implementation Chart](./MIDI-Implementation-Chart.md)
----------------------------------------------------------

Known Issues
------------

- Calling methods such as `set_blue_led` sometimes result in an IOError (timeout)

Change History
--------------

- Version 0.5.1 (2026-08-17): Fix NoMethodError by adding nil check
- Version 0.5.0 (2026-08-16): Change GATE_TIME to 3
- Version 0.4.0 (2026-08-16): Change to use R2P2 PICO2_W 0.5.0
- Version 0.3.1 (2026-07-10): Fix MIDI Implementation Chart
- Version 0.3.0 (2026-07-10): Change the BPM range to 30 - 240; reverse the Sub-Steps bits
- Version 0.2.1 (2026-06-28): Fix README
- Version 0.2.0 (2026-06-28): Add arpeggio patterns; add "Diatonic Transpose"; change GATE_TIME
- Version 0.1.0 (2026-06-21): Initial release

License
-------

MIDI Controller PRMC-1 (type-6) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
