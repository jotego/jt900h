    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    incf
    incf

    ld xwa,0x00000000
    ld xbc,xwa
    ld xde,0x00000000
    ld xhl,xde

    cp xwa,xde
    jp ne,bad_end
    cp xbc,xhl
    jp nz,bad_end

    decf
    ld e,1 ; Control Asignation
    incf

    ld xwa,0xffffffff
    ld xbc,xwa
    ld xde,0xffffffff
    ld xhl,xde

    cp xwa,xde
    jp ne,bad_end
    cp xbc,xhl
    jp nz,bad_end

    decf
    or e,2 ; Control Asignation (e = 8'd3)
    incf

    sub xwa,xwa
    xor xbc,xbc
    ld xde,xwa
    ld xde,(data)
    ld xhl,0x00000000

    cp xhl,xwa
    jp nz,bad_end
    cp xbc,data
    jp z,bad_end

    decf
    decf
    include finish.inc
data:
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end