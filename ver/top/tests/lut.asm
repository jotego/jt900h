    ; Verifies the LUT table at $400
    main section code
    org 0
ref   equ 0x800
    ld a,0xbf    ; common header

    ld xix,ref
    ld wa,0xff
    ld bc,0x80
test_loop:
    cpi wa,(xix+)
    jp ne,bad_end
    jp nov,end_loop
    inc 1,w
    dec 1,a
    inc 2,de
    jp test_loop

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
    align 2
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    align 4
stack:
    end