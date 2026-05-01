#include <stdint.h>

#ifndef LED_COUNT
#define LED_COUNT 4
#endif

#define LED_DATA_REG (*(volatile uint32_t *)0x80001000u)
#define BLINK_DELAY 80000000u

static void delay_cycles(volatile uint32_t n)
{
    while (n--) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    const uint32_t mask = (LED_COUNT >= 8) ? 0xFFu : ((1u << LED_COUNT) - 1u);

    while (1) {
        LED_DATA_REG = mask;
        delay_cycles(BLINK_DELAY);
        LED_DATA_REG = 0u;
        delay_cycles(BLINK_DELAY);
    }

    return 0;
}
