    ; load to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld (xsp),0x7d
    cp (xsp),0xf2
    jp eq,bad_end

    or ra3,1

    ld (xsp),0x07
    cp (xsp),0x07
    jp ne,bad_end

    ld xwa,0xbacadafa
    ld (0x6412),xwa
    ld (0x6416),xwa

    ld (0x6415),0xff
    cp (0x6415),0xfa
    jp eq,bad_end

    or ra3,2
    
    ld (0x6414),0xf1
    cp (0x6414),0xf1
    jp ne,bad_end
    ld wa,0xfff1
    cp (0x6414),wa
    jp ne,bad_end

    or ra3,4
    
    ld (0x6413),0xca
    cp (0x6413),0xca
    jp ne,bad_end
    ld xwa,0xfafff1ca
    ld xbc,(0x6413)
    cp (0x6413),xwa
    jp ne,bad_end

    or ra3,8

    ld xwa,(0x6413)
    cp wa,0xf1ca
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