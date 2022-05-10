    ; PAA: pointer adjust accumulator
    main section code
    org 0
    ld a,0xbf    ; common header

    ld xix, 1
    paa xix
    cp xix,2
    jp ne,bad_end

    ld xiy,10
    paa xiy
    cp xiy,10
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
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    dw 0,0,0,0,0,0,0,0,0,0
    end