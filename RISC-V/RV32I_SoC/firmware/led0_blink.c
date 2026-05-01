#include <stdint.h>

#define LED_DATA_REG (*(volatile uint32_t *)0x80001000u)

static void delay_cycles(volatile uint32_t cycles)
{
    while (cycles--) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    for (;;) {
        LED_DATA_REG = 0x01u;
        delay_cycles(2000000u);
        LED_DATA_REG = 0x00u;
        delay_cycles(2000000u);
    }

    return 0;
}