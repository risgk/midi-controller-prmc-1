MIDI Controller PRMC-1 (type-6)
===============================

**Version 0.0.0 (2026-**-**)**

MIDI Controller using PicoRuby/R2P2 by ISGK Instruments (Ryo Ishigaki)

Required Software
-----------------

- R2P2 PICORUBY 3.4.2 PICO2_W https://github.com/picoruby/picoruby/releases/3.4.2
- R2P2 Web Terminal https://picoruby.org/terminal

Required Hardware
-----------------

- Raspberry Pi Pico 2 https://www.raspberrypi.com/products/raspberry-pi-pico-2/
- Grove Shield for Pi Pico https://wiki.seeedstudio.com/Grove-Starter-Kit-for-Raspberry-Pi-Pico/ (5V)
- M5Stack Unit 8Angle https://docs.m5stack.com/en/unit/8angle (I2C1)
- M5Stack Unit ByteSwitch https://docs.m5stack.com/en/unit/Unit%20ByteSwitch (I2C1)
    - It is better to connect the ByteSwitch upside down
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
- CH5 Knob: Arpeggio Pattern, 1 - 16
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
- CH7 Knob: Brightness (Cutoff), 0 - 127 (-64 - +63)
- CH8 Knob: BPM, 56 - 300
    - BPM setting is disabled when MIDI clock is received
    - BPM setting is enabled by turning the knob
- SW Switch: 0 to Stop Sequencer, 1 to Start Sequencer
- Blue Button: Transpose - (min: -24)
- Red Button: Transpose + (max: +24)
    - With the Blue Button pressed, press the Red Button to increment the program number from 0 to 7 (Program Change)
- Byte Switch: Sub-Steps of On, 0 - 255
    - bit 0: Sub-Step 1 (and 9), ..., bit 7: Sub-Step 8 (and 16)

[MIDI Implementation Chart](./MIDI-Implementation-Chart.md)
----------------------------------------------------------

Known Issues
------------

- Calling methods such as `set_blue_led` sometimes result in an IOError (timeout)

Change History
--------------

- Version 0.0.0 (2026-**-**): Initial release

License
-------

MIDI Controller PRMC-1 (type-6) by ISGK Instruments (Ryo Ishigaki) is marked with CC0 1.0.
To view a copy of this license, visit https://creativecommons.org/publicdomain/zero/1.0/
