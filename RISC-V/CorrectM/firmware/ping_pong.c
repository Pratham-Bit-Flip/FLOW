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
    uint8_t on = 0x0Fu;   // LED[3:0] ON
    uint8_t off = 0x00u;  // all OFF
    const uint32_t blink_delay = 25000000u; // ~0.25 s at 100 MHz

    for (;;) {
        *LED_ADDR = on;
        delay(blink_delay);
        *LED_ADDR = off;
        delay(blink_delay);
    }

    return 0;
}
