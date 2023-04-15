    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld xsp,0x00000100
    ld xwa,0x00000000
    ld xbc,xwa
    ld xde,0x00000000
    ld xhl,xde

    cp xwa,xsp ; xsp = 0100 
    jp z,bad_end
    cp xwa,xhl
    jp nz,bad_end

    incf
    ld e,1 ; Control Asignation
    decf

    ld xwa,0xffffffff
    ld xbc,0xffffffff
    ld xde,xwa
    ld xhl,xbc
    
    cp xbc,xde
    jp nz,bad_end
    cp xbc,xwa
    jp ne,bad_end

    incf
    or e,2 ; Control Asignation (e = 8'd3)
    decf
    
    sub xwa,xwa
    xor xbc,xbc
    ld xde,xwa  
    ld xde,(data)
    ld xhl,0x00000000

    cp xhl,xwa
    jp nz,bad_end
    cp xbc,data+1
    jp z,bad_end

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