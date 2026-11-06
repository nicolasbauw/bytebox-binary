; screen.asm - write to video memory: mode 1, four pens, vertical stripes.
;
; In mode 1 a byte holds 4 pixels. Pixel p takes its pen number from bit (7-p)
; (low bit) and bit (3-p) (high bit), so #00, #F0, #0F and #FF give pens
; 0, 1, 2 and 3 for four pixels each. Video memory is #C000-#FFFF.

        BUILDSNA V2
        BANKSET 0
        ORG  #4000
        RUN  #4000

start
        di
        ld   sp,#BF00
        ld   bc,#7F8D       ; Gate Array: mode 1, both ROMs off
        out  (c),c

        ld   hl,palette
        ld   b,#7F
        ld   c,0            ; pen number
set_pen
        out  (c),c          ; select pen C
        ld   a,(hl)
        out  (c),a          ; its colour (#40 + hardware colour)
        inc  hl
        inc  c
        ld   a,c
        cp   4
        jr   nz,set_pen

        ld   hl,#C000       ; four bytes of pattern, then copy them forward
        ld   (hl),#00
        inc  hl
        ld   (hl),#F0
        inc  hl
        ld   (hl),#0F
        inc  hl
        ld   (hl),#FF
        ld   hl,#C000
        ld   de,#C004
        ld   bc,#3FFC
        ldir
loop
        jr   loop

palette
        defb #54            ; pen 0: black
        defb #4A            ; pen 1: bright yellow
        defb #53            ; pen 2: bright cyan
        defb #4C            ; pen 3: bright red
