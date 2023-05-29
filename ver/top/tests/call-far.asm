    ; call far to check that the PC is stored correctly
    maxmode on
    relaxed on
    org 0
    ld xsp,$3FFF
    calr far
    ld hl,0x12

    include finish.inc
    db 0x1FF dup (0)
    jp bad_end
far:
    ld bc,0x55
    ld hl,0x34
    ret
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end