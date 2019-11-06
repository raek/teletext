#include <avr/io.h>
        
zero = 1
temp = 16
data = 17
counter = 18

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
        
