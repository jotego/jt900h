    main section code
    org 0
    ld wa,0xbf    ; common header

    incf ; bank 1
    incf ; bank 2
    incf ; bank 3

    ld qsp,0x0000
    cp qsp,0x0456
    jp eq,bad_end
    ld qsp,0xffff
    cp qsp,0xffff
    jp ne,bad_end
    ld qsp,0x0000
    cp qsp,0xffff
    jp eq,bad_end

    ld sp,0x0000
    cp sp,qsp
    jp ne,bad_end
    ld sp,0xffff
    cp sp,qsp
    jp eq,bad_end
    ld sp,0x0000
    cp sp,0x0001
    jp eq,bad_end

    incf ; bank 0

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end