#include <avr/io.h>

zero = 1
temp = 16
data = 17
counter = 18

LINE_T = 1024                   ; 64 us
SYNC_T = 64                     ; 4 us

.section .text
.global main

main:
        clr     zero
        rcall   init_timer
        rcall   init_usart
1:
        ldi     data, 0
        ldi     counter, 45
2:
        sts     UDR0, data
3:
        lds     temp, UCSR0A
        sbrs    temp, UDRE0
        rjmp    3b
        inc     data
        dec     counter
        brne    2b
        ldi     counter, 0xFF
2:
        dec     counter
        brne    2b
        rjmp    1b

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

.end
