#include <stdint.h>

#define LED_ADDR ((volatile uint32_t *)0x80001000u)

static void delay(volatile uint32_t n)
{
    while (n--) {
        __asm__ volatile ("nop");
    }
}

int main(void)
{
    uint8_t val = 1u;

    for (;;) {
        *LED_ADDR = val;
        delay(250000u);
        val = (uint8_t)((val << 1) | (val >> 7));
    }

    return 0;
}
