#include <avr/io.h>

# Line Schedule (625 line PAL)
#
# |       | Lines                |                                         |
# | Phase | First | Last | Count | Description                             |
# |-------|-------|------|-------|-----------------------------------------|
# |     1 |   623*|    5 |     8 | First field vertical sync               |
# |     2 |     6 |   23*|    18 | First field vertical blanking interval  |
# |     3 |    24 |  310 |   287 | First field picture                     |
# |     4 |   311 |  318*|     8 | Second field vertical sync              |
# |     5 |   319 |  335 |    18 | Second field vertical blanking interval |
# |     6 |   336 |  622 |   287 | Second field picture                    |
#
# *The first and second halves of lines 23, 318 and 623 actually belong to
# different phases, but the repsonsibility for both halves has been assigned
# to one phase here.
#
#
# Types of (Half-)Lines
#
#          ___XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX__
#     |___|
#     Picture line (65 cycles sync, 63 cycles black,
#                   739 cycles of picture, 21 cycles of black)
#
#          _____________________________________________
#     |___|
#     Blank line (65 cycles sync, 823 cycles black)
#
#        ______________________
#     |_|
#     Equalizing pulse half-line (33 cycles sync, 411 cycles black)
#
#                           ___
#     |____________________|
#     Synchronizing pulse half-line (379 cycles sync, 65 cycles black)
#
#
# Vertical Sync (First Field)
#
# 623. first half of blank line (with hsync), equalizing pulse
# 624. equalizing pulse, equalizing pulse
# 625. equalizing pulse, equalizing pulse
#   1. synchronizing pulse, synchronizing pulse
#   2. synchronizing pulse, synchronizing pulse
#   3. synchronizing pulse, equalizing pulse
#   4. equalizing pulse, equalizing pulse
#   5. equalizing pulse, equalizing pulse
#
#
# Vertical Sync (Second Field)
#
# 311. equalizing pulse, equalizing pulse
# 312. equalizing pulse, equalizing pulse
# 313. equalizing pulse, synchronizing pulse
# 314. synchronizing pulse, synchronizing pulse
# 315. synchronizing pulse, synchronizing pulse
# 316. equalizing pulse, equalizing pulse
# 317. equalizing pulse, equalizing pulse
# 318. equalizing pulse, second half of blank-line (no hsync)
#
#

# Timing constants (in 13.875MHz cycles)

LINES         = 625

LINE_T        = 888
FRONT_PORCH_T =  21
HSYNC_T       =  65
BACK_PORCH_T  =  63
PICTURE_T     = 739

HALF_LINE_T   = 444
EQ_PULSE_T    =  33
VSYNC_PULSE_T = 379

NUM_SYNC_LINES    =   8
NUM_BLANK_LINES   =  18
NUM_PICTURE_LINES = 287

# Register allocation constants

temp = 16
# Used by delay_c
delay_lo = 24
delay_hi = 25
# Current line in current phase
line_lo = 26
line_hi = 27

# Timing macros

# Delay n cycles
.macro delay_c n:req
.if \n <= 4
        .rept   \n
        nop
        .endr
.else
        ldi     delay_lo, lo8((\n - 1) / 4)
        ldi     delay_hi, hi8((\n - 1) / 4)
999:
        sbiw    delay_lo, 1
        brne    999b
        .rept   (\n - 1) % 4
        nop
        .endr
.endif
.endm

# Macros for controlling output pins

.macro sync_pin_on
        sbi     _SFR_IO_ADDR(PORTD), 2
.endm

.macro sync_pin_off
        cbi     _SFR_IO_ADDR(PORTD), 2
.endm

.macro luma_pin_white
        cbi     _SFR_IO_ADDR(PORTD), 1
.endm

.macro luma_pin_black
        sbi     _SFR_IO_ADDR(PORTD), 1
.endm

.macro frame_pin_first
        cbi     _SFR_IO_ADDR(PORTB), 0
.endm

.macro frame_pin_second
        sbi     _SFR_IO_ADDR(PORTB), 0
.endm

# Macros used as building blocks for line schedule

# Emit code that runs for half a line time, with the sync pin active during
# the first 't' number of cycles. The 'remove_t' parameter can be used to
# shorten the total time by that number of cycles.
.macro sync_half_line t:req, remove_t=0
        sync_pin_on
        delay_c (\t) - 1
        sync_pin_off
        delay_c HALF_LINE_T - \t - 1 - \remove_t
.endm

.macro blank_line remove_t=0
        sync_pin_on
        delay_c HSYNC_T - 1
        sync_pin_off
        delay_c LINE_T - HSYNC_T - 1 - \remove_t
.endm

.macro picture_line_start remove_t=0
        sync_pin_on
        delay_c HSYNC_T - 1
        sync_pin_off
        delay_c BACK_PORCH_T - 1 - \remove_t
.endm

.macro picture_line_end remove_t=0
        luma_pin_black
        delay_c BACK_PORCH_T - 1 - \remove_t
.endm

# 5 cycles
.macro next_phase next:req
        clr     line_lo
        clr     line_hi
        jmp     \next
.endm

# 13 cycles
.macro repeat_line_or_next_phase count:req, back:req, next:req
        adiw    line_lo, 1
        ldi     temp, lo8(\count)
        cp      line_lo, temp
        ldi     temp, hi8(\count)
        cpc     line_hi, temp
        breq    1f
        nop
        nop
        nop
        jmp     \back
1:
        clr     line_lo
        clr     line_hi
        jmp     \next
.endm

# Code

# "Calling Convention"
#
# Each phase is implemented as a routine that jumps to the next one at
# its end. The routines jump rather then call the next routine, so the stack
# is not used.

.section .text
.global main
main:
        sbi     _SFR_IO_ADDR(DDRD), 1
        cbi     _SFR_IO_ADDR(PORTD), 1
        sbi     _SFR_IO_ADDR(DDRD), 2
        sbi     _SFR_IO_ADDR(PORTD), 2
        sbi     _SFR_IO_ADDR(DDRB), 0
        cbi     _SFR_IO_ADDR(PORTB), 0
        jmp     vsync1

# First field vertical sync
vsync1:
        # Line 623
        sync_half_line HSYNC_T
        sync_half_line EQ_PULSE_T
        # Line 624
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 625
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T, 1
        frame_pin_first
        # Line 1
        sync_half_line VSYNC_PULSE_T
        sync_half_line VSYNC_PULSE_T
        # Line 2
        sync_half_line VSYNC_PULSE_T
        sync_half_line VSYNC_PULSE_T
        # Line 3
        sync_half_line VSYNC_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 4
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 5
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T, 5
        next_phase vbi1

# First field vertical blanking interval
vbi1:
        blank_line 13
        repeat_line_or_next_phase NUM_BLANK_LINES, vbi1, field1

# First field picture
field1:
        picture_line_start
        luma_pin_black
        delay_c (PICTURE_T / 3) - 1
        luma_pin_white
        delay_c (PICTURE_T / 3) - 1
        luma_pin_black
        delay_c PICTURE_T - (2 * (PICTURE_T / 3)) - 1
        picture_line_end 13
        repeat_line_or_next_phase NUM_PICTURE_LINES, field1, vsync2

# Second field vertical sync
vsync2:
        # Line 311
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 312
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 313
        sync_half_line EQ_PULSE_T, 1
        frame_pin_second
        sync_half_line VSYNC_PULSE_T
        # Line 314
        sync_half_line VSYNC_PULSE_T
        sync_half_line VSYNC_PULSE_T
        # Line 315
        sync_half_line VSYNC_PULSE_T
        sync_half_line VSYNC_PULSE_T
        # Line 316
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 317
        sync_half_line EQ_PULSE_T
        sync_half_line EQ_PULSE_T
        # Line 318
        sync_half_line EQ_PULSE_T
        delay_c HALF_LINE_T - 5
        next_phase vbi2

# Second field vertical blanking interval
vbi2:
        blank_line 13
        repeat_line_or_next_phase NUM_BLANK_LINES, vbi2, field2

# Second field picture
field2:
        picture_line_start
        luma_pin_black
        delay_c (PICTURE_T / 3) - 1
        luma_pin_white
        delay_c (PICTURE_T / 3) - 1
        luma_pin_black
        delay_c PICTURE_T - (2 * (PICTURE_T / 3)) - 1
        picture_line_end 13
        repeat_line_or_next_phase NUM_PICTURE_LINES, field2, vsync1

.end
