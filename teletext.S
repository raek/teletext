#include <avr/io.h>

# Constants

LINE_T        = 888
FRONT_PORCH_T = 21
SYNC_T        = 65
BACK_PORCH_T  = 63

# Register allocation

temp = 0
zero = 1
delay_lo = 24
delay_hi = 25

# Macros

# Delay n cycles
.macro delay_c n:req
.if \n <= 4
        .rept   \n
        nop
        .endr
.else
        ldi     delay_lo, ((\n - 1) / 4) & 0xFF
        ldi     delay_hi, ((\n - 1) / 4) >> 8
999:
        sbiw    delay_lo, 1
        brne    999b
        .rept   (\n - 1) % 4
        nop
        .endr
.endif
.endm

# Code

.section .text
.global main
main:
        sbi     _SFR_IO_ADDR(DDRD), 1
        cbi     _SFR_IO_ADDR(PORTD), 1
        sbi     _SFR_IO_ADDR(DDRD), 2
        sbi     _SFR_IO_ADDR(PORTD), 1

hsync_start:
        sbi     _SFR_IO_ADDR(PORTD), 2
        delay_c SYNC_T - 1

        cbi     _SFR_IO_ADDR(PORTD), 2
        delay_c BACK_PORCH_T - 1

        cbi     _SFR_IO_ADDR(PORTD), 1
        delay_c LINE_T - SYNC_T - FRONT_PORCH_T - BACK_PORCH_T - 1

        sbi     _SFR_IO_ADDR(PORTD), 1
        delay_c FRONT_PORCH_T - 3
        rjmp    hsync_start

.end
