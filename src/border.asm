; border.asm - the smallest useful program: set the border to bright red.
;
; Assemble and run:  tools/rasm-sna.sh src/border.asm && tools/run.sh border.sna

        BUILDSNA V2         ; write a version 2 snapshot (ByteBox reads v1 and v2)
        BANKSET 0           ; write to the 64K RAM; without it nothing is written
        ORG  #4000
        RUN  #4000          ; entry point stored in the snapshot

start
        ld   bc,#7F10       ; Gate Array: select the border
        out  (c),c
        ld   bc,#7F4C       ; set it to ink 12 (bright red)
        out  (c),c
loop
        jr   loop
