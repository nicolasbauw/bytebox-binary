; mouse-demo.asm - move a character-sized block with the mouse.
;
; Mode 2 (640x200, 1 bit per pixel). The block follows the mouse; holding the
; left button leaves a trail, the right button clears the screen.
;
; Enable the mouse first ("mouse on" in the F10 bar), then click in the
; window to capture it.
;
;   tools/rasm-sna.sh src/mouse-demo.asm && tools/run.sh mouse-demo.sna

        BUILDSNA V2
        BANKSET 0
        ORG  #4000
        RUN  #4000

        jp   start
        INCLUDE "mouse-driver.asm"

start
        di
        ld   sp,#BF00
        ld   bc,#7F8E       ; Gate Array: mode 2, both ROMs off
        out  (c),c
        ld   bc,#7F00       ; pen 0: black
        out  (c),c
        ld   bc,#7F54
        out  (c),c
        ld   bc,#7F01       ; pen 1: bright white
        out  (c),c
        ld   bc,#7F4B
        out  (c),c
        call clear_screen
        ld   hl,320         ; start in the middle
        ld   (mouse_x),hl
        ld   hl,100
        ld   (mouse_y),hl

main_loop
        call wait_frame
        ld   a,(mouse_buttons)
        and  MOUSE_LEFT
        jr   nz,keep        ; left button was down: leave the block there
        ld   hl,(drawn_at)
        xor  a
        call fill_cell      ; otherwise erase it before moving
keep
        call mouse_update
        call clamp_position
        ld   a,(mouse_buttons)
        and  MOUSE_RIGHT
        call nz,clear_screen
        call cursor_address
        ld   (drawn_at),hl
        ld   a,#FF
        call fill_cell      ; draw it at the new position
        jr   main_loop

drawn_at defw #C000

; Keep the position inside the screen: x in 0-639, y in 0-199.
clamp_position
        ld   hl,(mouse_x)
        ld   de,639
        call clamp
        ld   (mouse_x),hl
        ld   hl,(mouse_y)
        ld   de,199
        call clamp
        ld   (mouse_y),hl
        ret

; Clamp the signed value in HL to 0..DE.
clamp
        bit  7,h
        jr   z,positive
        ld   hl,0
        ret
positive
        push hl
        or   a
        sbc  hl,de
        pop  hl
        ret  c              ; below the maximum: keep it
        ex   de,hl          ; otherwise use the maximum
        ret

; HL = address of the first scanline of the character cell under the mouse:
; #C000 + row * 80 + column.
cursor_address
        ld   hl,(mouse_y)
        srl  h
        rr   l
        srl  h
        rr   l
        srl  h
        rr   l              ; row = y / 8
        ld   c,l
        ld   b,0
        add  hl,hl          ; x2
        add  hl,hl          ; x4
        add  hl,bc          ; x5
        add  hl,hl          ; x10
        add  hl,hl          ; x20
        add  hl,hl          ; x40
        add  hl,hl          ; x80
        ld   de,#C000
        add  hl,de
        ld   de,(mouse_x)
        srl  d
        rr   e
        srl  d
        rr   e
        srl  d
        rr   e              ; column = x / 8
        add  hl,de
        ret

; Write A to the 8 scanlines of the cell at HL. Scanlines of a character
; row are #800 bytes apart.
fill_cell
        ld   b,8
        ld   de,#0800
fill_line
        ld   (hl),a
        add  hl,de
        djnz fill_line
        ret

clear_screen
        ld   hl,#C000
        ld   de,#C001
        ld   bc,#3FFF
        ld   (hl),0
        ldir
        ret

; Wait for the next vertical sync (PPI port B, bit 0).
wait_frame
        ld   b,#F5
end_sync
        in   a,(c)
        rra
        jr   c,end_sync
start_sync
        in   a,(c)
        rra
        jr   nc,start_sync
        ret
