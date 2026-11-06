; crt0.s - start-up code for a C program built with SDCC (z80 target).
;
; The snapshot starts at #4000: this file puts the stack in plain RAM
; (below the screen, above the code), disables interrupts (the firmware's
; handler is not in memory in a RASM snapshot) and calls main().
; Code is linked at #4010, data at #8000 (see tools/c-sna.sh).

        .module crt0
        .globl  _main

        .area   _HEADER (ABS)
        .org    0x4000
start:
        di
        ld      sp,#0xBF00
        call    _main
halt_loop:
        jr      halt_loop

        .area   _CODE
        .area   _DATA
