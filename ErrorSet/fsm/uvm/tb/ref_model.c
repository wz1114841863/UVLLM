
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "/Business/EDA_wx_company/public/tools/vcs_R-2020.12-SP2/linux64/include/svdpi.h"

enum state { S0, S1, S2, S3, S4, S5 };

void fsm_model(int IN, int RST, int *MATCH) {
    static enum state current_state = S0;
    enum state next_state = current_state;

    // Reset logic
    if (RST) {
        current_state = S0;
        *MATCH = 0;
    } else {
        // State transition logic
        switch (current_state) {
            case S0:
                next_state = (IN == 0) ? S0 : S1;
                break;
            case S1:
                next_state = (IN == 0) ? S2 : S1;
                break;
            case S2:
                next_state = (IN == 0) ? S3 : S1;
                break;
            case S3:
                next_state = (IN == 0) ? S0 : S4;
                break;
            case S4:
                next_state = (IN == 0) ? S2 : S5;
                break;
            case S5:
                next_state = (IN == 0) ? S2 : S1;
                break;
        }

        // Output logic
        *MATCH = (current_state == S4 && IN == 1) ? 1 : 0;
    }

    // Update current state
    current_state = next_state;
}
