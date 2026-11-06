; ssm-shot.asm - ask the emulator for a screenshot from inside the program.
;
; SSM (ScreenShot Management) is a request made of two inoperative ED opcodes:
; ED LL ED HH asks for a capture numbered HHLL. ByteBox acts on it when it is
; started with --ssm, and saves BYTEBOX_0_HHLL.png. Code #FFFE saves a plain
; screenshot, #FFFF a snapshot, #0000 pauses the emulation.
;
; The request fires at the exact cycle where the opcode executes, which is
; what makes a screenshot comparable from one run to the next.

        BUILDSNA V2
        BANKSET 0
        ORG  #4000
        RUN  #4000

        MACRO SSM code
        defb #ED,{code} & #FF,#ED,{code} / 256
        MEND

start
        ld   sp,#BF00
        ld   bc,#7F10       ; border: bright green
        out  (c),c
        ld   bc,#7F52
        out  (c),c
        call wait_frames    ; let the emulator draw a few frames first

        SSM  #0001          ; saves BYTEBOX_0_0001.png at this exact cycle

        ld   bc,#7F10       ; border: bright red
        out  (c),c
        ld   bc,#7F4C
        out  (c),c
        call wait_frames
        SSM  #0002          ; saves BYTEBOX_0_0002.png
        SSM  #0000          ; pauses (or ends a headless run)
loop
        jr   loop

; Wait for 5 vertical syncs (PPI port B, bit 0).
wait_frames
        ld   d,5
frame
        ld   b,#F5
end_sync
        in   a,(c)
        rra
        jr   c,end_sync     ; wait for the sync to end,
start_sync
        in   a,(c)
        rra
        jr   nc,start_sync  ; then for the next one to begin
        dec  d
        jr   nz,frame
        ret
