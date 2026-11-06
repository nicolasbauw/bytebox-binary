; irq-border.asm - an interrupt handler that changes the border colour.
;
; The CPC raises 6 interrupts per frame (every 52 scanlines). The handler
; below steps through the ink list at each one, which paints coloured bands
; across the border. Useful with the debugger: "b 0x0038" stops at every
; interrupt, and the status window (F12) shows the Gate Array counter.

        BUILDSNA V2
        BANKSET 0
        ORG  #4000
        RUN  #4000

start
        di
        ld   sp,#BF00
        ld   bc,#7F8D       ; Gate Array: mode 1, both ROMs off, so that the
        out  (c),c          ; RAM we write at #0038 is the RAM the CPU reads
        im   1
        ld   hl,handler
        ld   (#0039),hl     ; IM 1 jumps to #0038, which holds JP nn
        ld   a,#C3          ; (the firmware's own vector is replaced)
        ld   (#0038),a
        ld   ix,colours
        ei
loop
        jr   loop

handler
        push af
        push bc
        ld   bc,#7F10
        out  (c),c
        ld   a,(ix+0)
        out  (c),a
        inc  ix
        ld   a,(ix+0)
        cp   #FF            ; end marker: wrap around
        jr   nz,keep
        ld   ix,colours
keep
        pop  bc
        pop  af
        ei
        ret

colours
        defb #54,#4C,#4A,#4B,#55,#5C,#FF
