    ; call far to check that the PC is stored correctly
    maxmode on
    relaxed on
    org 0
    ld xsp,$4000
    calr far
    cp hl,0x34
    jp ne,bad_end
    cp bc,0x55
    jp ne,bad_end

    include finish.inc
    db 0x1F00 dup (0)
    jp bad_end
far:
    ld bc,0x55
    ld hl,0x34
    ret
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end