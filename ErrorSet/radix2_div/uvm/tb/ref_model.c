
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "/Business/EDA_wx_company/public/tools/vcs_R-2020.12-SP2/linux64/include/svdpi.h"


void radix2_div_model(uint8_t dividend, uint8_t divisor, bool sign, uint16_t *result) {
    int16_t temp_dividend = dividend;
    int16_t temp_divisor = divisor;
    int16_t temp_remainder, temp_quotient;

    // Handle sign
    if (sign) {
        if (temp_dividend & 0x80) {
            temp_dividend = -((int8_t)temp_dividend); 
        }
        if (temp_divisor & 0x80) {
            temp_divisor = -((int8_t)temp_divisor); 
        }
    }

    // Perform division
    temp_remainder = 0;
    temp_quotient = 0;
    for (int i = 0; i < 8; i++) {
        temp_remainder = (temp_remainder << 1) | ((temp_dividend >> (7 - i)) & 1);
        temp_quotient <<= 1;
        if (temp_remainder >= temp_divisor) {
            temp_remainder -= temp_divisor;
            temp_quotient |= 1;
        }
    }

    // Adjust sign for remainder and quotient
    if (sign) {
        if ((dividend & 0x80) ^ (divisor & 0x80)) {
            temp_quotient = -temp_quotient; 
        }
        if (dividend & 0x80) {
            temp_remainder = -temp_remainder; 
        }
    }

    // Combine remainder and quotient into result
    *result = ((uint8_t)temp_remainder << 8) | (uint8_t)temp_quotient;
}


