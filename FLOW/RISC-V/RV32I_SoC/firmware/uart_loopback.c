// UART Loopback Test
// Echoes back any character received over UART
// Also lights LED0 immediately to prove CPU is running

#define UART_BASE    0x80000000u
#define LED_BASE     0x80001000u

#define UART_TX_REG  (*((volatile unsigned int *)(UART_BASE + 0)))
#define UART_RX_REG  (*((volatile unsigned int *)(UART_BASE + 4)))
#define UART_STAT_REG (*((volatile unsigned int *)(UART_BASE + 8)))
#define LED_DATA_REG (*((volatile unsigned int *)(LED_BASE)))

#define UART_STAT_TX_BUSY (1u << 0)
#define UART_STAT_RX_READY (1u << 1)

void uart_putchar(char c) {
    while (UART_STAT_REG & UART_STAT_TX_BUSY) {
        asm volatile("nop");
    }
    UART_TX_REG = (unsigned int)c;
}

int uart_getchar(void) {
    if (UART_STAT_REG & UART_STAT_RX_READY) {
        return (int)(UART_RX_REG & 0xFF);
    }
    return -1;
}

void uart_puts(const char *s) {
    while (*s) {
        uart_putchar(*s);
        s++;
    }
}

int main() {
    // Light LED0 immediately
    LED_DATA_REG = 0x01u;
    
    // Send startup message
    uart_puts("UART Loopback Ready\r\n");
    
    // Echo loop: read char, send it back
    for (;;) {
        int ch = uart_getchar();
        if (ch != -1) {
            uart_putchar((char)ch);  // Echo back the character
        }
    }
    return 0;
}
