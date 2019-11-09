#include <avr/io.h>

zero = 1
temp = 16
data = 17
length = 18

LINE_T = 1024                   ; 64 us
SYNC_T = 64                     ; 4 us

.section .data
pattern:
        .rept   45
        .byte   0xFF
        .endr

.section .text

pattern_rom:
        .ascii  "hej"
pattern_rom_end:
        .align  2

.global main
main:
        clr     zero
        rcall   init_timer
        rcall   init_usart
        rcall   copy_pattern
1:
        ldi     length, pattern_rom_end-pattern_rom
        ldi     r27, hi8(pattern)
        ldi     r26, lo8(pattern)
        rcall   send_data
        rjmp 1b

init_timer:
        sbi     _SFR_IO_ADDR(DDRB), 2
        sts     TCNT1H, zero
        sts     TCNT1L, zero
        ldi     temp, hi8(LINE_T-1)
        sts     OCR1AH, temp
        ldi     temp, lo8(LINE_T-1)
        sts     OCR1AL, temp
        ldi     temp, hi8(SYNC_T)
        sts     OCR1BH, temp
        ldi     temp, lo8(SYNC_T)
        sts     OCR1BL, temp
        ldi     temp, (0<<COM1A1)|(0<<COM1A0)|(1<<COM1B1)|(0<<COM1B0)|(1<<WGM11)|(1<<WGM10)
        sts     TCCR1A, temp
        ldi     temp, (0<<ICNC1)|(0<<ICES1)|(1<<WGM13)|(1<<WGM12)|(0<<CS12)|(0<<CS11)|(1<<CS10)
        sts     TCCR1B, temp
        ret

init_usart:
        sts     UBRR0H, zero
        sts     UBRR0L, zero
        sbi     _SFR_IO_ADDR(DDRD), 4
        ldi     temp, (1<<UMSEL00)|(1<<UMSEL01)|(0<<UDORD0)
        sts     UCSR0C, temp
        ldi     temp, (0<<RXEN0)|(1<<TXEN0)
        sts     UCSR0B, temp
        ret

copy_pattern:
        ldi     length, pattern_rom_end-pattern_rom
        ldi     r27, hi8(pattern)
        ldi     r26, lo8(pattern)
        ldi     r31, hi8(pattern_rom)
        ldi     r30, lo8(pattern_rom)
1:
        lpm     data, z+
        st      x+, data
        dec     length
        brne    1b
        ret

send_data:
2:
        ld      data, x+
        sts     UDR0, data
3:
        lds     temp, UCSR0A
        sbrs    temp, UDRE0
        rjmp    3b
        inc     data
        dec     length
        brne    2b
        ldi     length, 0xFF
2:
        dec     length
        brne    2b
        ret

.end
