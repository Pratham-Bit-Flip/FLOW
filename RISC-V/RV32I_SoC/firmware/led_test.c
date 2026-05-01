#include <stdint.h>

#define LED_ADDR ((volatile uint32_t *)0x80001000u)

/* Simplest possible test: all LEDs ON, forever. No delay logic. */
int main(void)
{
    *LED_ADDR = 0xFFu;   /* all 8 LEDs ON */
    for (;;) {}           /* halt here */
    return 0;
}
