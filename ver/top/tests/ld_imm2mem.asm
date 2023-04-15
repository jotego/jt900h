    ; load immediate value to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld a,0
    ldb (data),1
    ldw (data+2),0x1122
    ld xix,data

    ld bc,1

    ; cp (xix),1
    ld d,(xix)
    cp d,1
    jp ne,bad_end
    or bc,2

    ; cpw (xix+2),0x1122
    incf
    ld wa,(xix+2)
    cp wa,0x1122
    jp ne,bad_end
    decf
    or bc,4

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