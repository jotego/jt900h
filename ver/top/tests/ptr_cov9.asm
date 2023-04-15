    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld sp,0x0000
    ld qiz,0x0000
    ld qiy,0x0000
    ld iy,0x0000

    cp iy,qiy
    jp ne,bad_end
    cp sp,qiz
    jp ne,bad_end

    ld sp,0xffff
    ld iy,0xffff
    ld qiy,0xffff
    ld qiz,0xffff

    cp iy,qiy
    jp ne,bad_end
    cp sp,qiz
    jp ne,bad_end

    ld sp,0x0000
    ld iy,0x0000
    ld qiy,0x0000
    ld qiz,0x0000

    cp iy,qiy
    jp ne,bad_end
    cp sp,qiz
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end