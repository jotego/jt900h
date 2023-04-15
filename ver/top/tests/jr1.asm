    ; load to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ld (xsp),0x7d
    cp (xsp),0xf2
    jp eq,bad_end

    ld a,1

    ld (xsp),0x07
    cp (xsp),0x07
    jp ne,bad_end

    ld (0x6415),0xff
    cp (0x6415),0xfa
    jp eq,bad_end

    ld a,2
    
    ld (0x6414),0xf1
    cp (0x6414),0xf1
    jp ne,bad_end

    ld a,3
    
    ld (0x6413),0xff
    cp (0x6413),0xf1
    jp eq,bad_end

    ld xwa,(0x6413)
    cp wa,0xf1ff
    jp eq,end_loop
    jp ne,bad_end

bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
end