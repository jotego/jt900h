    ; call[cc],mem
    main section code
    org 0
    ld wa,0xbf    ; RRX, SRAX,SRLX,  
    ; RLCX
    ; RRCX
    ; SRAX

    ld wa,0x9821
    ld xix,(data)
    ld bc,0x01

    rrc a,bc    ; bc = 0x8000
    rrc 3,wa    ; wa = 0x3304
    rrc (xbc)

    rlc 2,wa    ; wa = 0xCC10
    ld a,1
    rlc a,bc    ; wb = 0x01
    rlc (xix)
    ld e,0x01

    sra a,de   ; de = 0x8000
    sra 4,de   ; de = 0x0800
    sra (xix) 

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
stack:
    end