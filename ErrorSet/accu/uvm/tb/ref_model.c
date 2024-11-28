
#include <stdint.h>
#include <stdbool.h>
#include "/Business/EDA_wx_company/public/tools/vcs_R-2020.12-SP2/linux64/include/svdpi.h"

void accu_reference_model(uint8_t data_in, bool valid_in, bool rst_n, uint16_t *data_out, bool *valid_out) {
    static uint16_t sum = 0;
    static int count = 0;
    static bool last_valid_out = false;

    if (!rst_n) {
        sum = 0;
        count = 0;
        *data_out = 0;
        *valid_out = false;
        last_valid_out = false;
        return;
    }

    if (valid_in || !last_valid_out) {
        if (count == 0) {
            sum = data_in;
        } else {
            sum += data_in;
        }
        count++;
    }

    if (count == 4) {
        *data_out = sum;
        *valid_out = true;
        count = 0;
    } else {
        *valid_out = false;
    }

    last_valid_out = *valid_out;
}
