#include <stdint.h>

#define LED_DATA_REG (*(volatile uint32_t *)0x80001000u)

int main(void)
{
    for (;;) {
        LED_DATA_REG = 0xFFu;
    }

    return 0;
}
