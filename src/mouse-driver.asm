; mouse-driver.asm - driver for the ByteBox software mouse.
;
; The mouse is a ByteBox device, not a copy of a hardware adapter. It sits on
; three ports of the #FC00 page:
;
;   #FC00  delta X   signed byte, consumed by the read (motion beyond
;                    -128..127 is kept for the following reads)
;   #FC01  delta Y   same as #FC00
;   #FC02  buttons   bit 0 = left, bit 1 = right
;
; While the mouse is disabled the ports read as #FF; enabled but not captured,
; they read 0. #FC02 never reads #FF while the mouse is enabled, which is how
; mouse_update tells the two apart: read as a delta, #FF would be a move of -1
; on every call. Enable it in the
; settings window (F6, Hardware), with the console command "mouse on", or
; with [mouse] enabled = true in config.toml; then click in the window to
; capture it (middle click releases).
;
; Include this file in a program and call mouse_update once per frame. The
; stack must be in plain RAM: below #4000 or above #C000 the ROMs may be
; mapped, and a RET read from there would be corrupted.

MOUSE_PORT_DX      equ #FC00
MOUSE_PORT_DY      equ #FC01
MOUSE_PORT_BUTTONS equ #FC02
MOUSE_LEFT         equ 1
MOUSE_RIGHT        equ 2

mouse_x       defw 0        ; accumulated position, signed, not clamped
mouse_y       defw 0
mouse_buttons defb 0

; Read the three ports and update mouse_x, mouse_y and mouse_buttons.
; While the mouse is disabled every port reads #FF: nothing moves and the
; buttons are reported as released. Changes A, BC, DE, HL and the flags.
mouse_update
        ld   bc,MOUSE_PORT_BUTTONS
        in   a,(c)
        cp   #FF
        jr   z,absent
        ld   (mouse_buttons),a
        ld   bc,MOUSE_PORT_DX
        in   a,(c)
        ld   hl,mouse_x
        call add_signed
        ld   bc,MOUSE_PORT_DY
        in   a,(c)
        ld   hl,mouse_y
        call add_signed
        ret
absent
        xor  a
        ld   (mouse_buttons),a
        ret

; Add the signed byte in A to the 16-bit variable at (HL).
add_signed
        ld   e,a
        add  a,a            ; sign bit into carry
        sbc  a,a            ; A = #00 or #FF: the sign extension
        ld   d,a
        ld   a,(hl)
        add  a,e
        ld   (hl),a
        inc  hl
        ld   a,(hl)
        adc  a,d
        ld   (hl),a
        ret
