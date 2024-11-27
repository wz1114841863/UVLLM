
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include "/Business/EDA_wx_company/public/tools/vcs_R-2020.12-SP2/linux64/include/svdpi.h"

#define ADD 0x20
#define ADDU 0x21
#define SUB 0x22
#define SUBU 0x23
#define AND 0x24
#define OR 0x25
#define XOR 0x26
#define NOR 0x27
#define SLT 0x2A
#define SLTU 0x2B
#define SLL 0x00
#define SRL 0x02
#define SRA 0x03
#define SLLV 0x04
#define SRLV 0x06
#define SRAV 0x07
#define LUI 0x0F


void alu_model(uint32_t a, uint32_t b, uint8_t aluc, uint32_t *r, bool *zero, bool *carry, bool *negative, bool *overflow, uint32_t *flag) {
    int64_t temp_res; 
	int32_t a_signed = (int32_t)a;
    int32_t b_signed = (int32_t)b;
    *carry = false;
    *overflow = false;
    *negative = false;

    switch (aluc) {
        case ADD:
            temp_res = (int64_t)a_signed + b_signed;
            *r = (uint32_t)temp_res;
            *overflow = (temp_res > INT32_MAX || temp_res < INT32_MIN);
            break;
        case ADDU:
            temp_res = (uint64_t)a + b;
            *r = (uint32_t)temp_res;
            *carry = (temp_res > UINT32_MAX);
            break;
        case SUB:
            temp_res = (int64_t)a_signed - b_signed;
            *r = (uint32_t)temp_res;
            *overflow = (temp_res > INT32_MAX || temp_res < INT32_MIN);
            break;
        case SUBU:
            temp_res = (uint64_t)a - b;
            *r = (uint32_t)temp_res;
            *carry = (a < b);
            break;
        case AND:
            *r = a & b;
            break;
        case OR:
            *r = a | b;
            break;
        case XOR:
            *r = a ^ b;
            break;
        case NOR:
            *r = ~(a | b);
            break;
        case SLT:
            *r = (a_signed < b_signed) ? 1 : 0;
            break;
        case SLTU:
            *r = (a < b) ? 1 : 0;
            break;
        case SLL:
            *r = b << (a & 0x1F);
            break;
        case SRL:
            *r = b >> (a & 0x1F);
            break;
        case SRA:
            *r = (uint32_t)(b_signed >> (a_signed & 0x1F));
        break;
        case SLLV:
            *r = b << (a & 0x1F);
            break;
        case SRLV:
            *r = b >> (a & 0x1F);
            break;
        case SRAV:
            *r = (uint32_t)(b_signed >> (a & 0x1F));
            break;
        case LUI:
            *r = a << 16;
            break;
        default:
            *r = 0; 
            break;
    }

    *zero = (*r == 0);
    *negative = ((int32_t)*r < 0);

    if (aluc == SLT) {
        *flag = (a_signed < b_signed);
    } else if (aluc == SLTU) {
        *flag = (a < b);
    } else {
        *flag = 0; 
    }
}
