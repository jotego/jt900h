    ; call[cc],mem
    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; RRX, SRAX,SRLX,  
    ; RLCX
    ; RRCX
    ; SRAX

    ld wa,0x0000
    ld xix,(data)
    ld bc,0x00

    rrc a,bc    
    rrc 0,wa    
    rrc (xbc)

    rlc 2,wa    
    ld a,0
    rlc a,bc    
    rlc (xix)
    ld e,0x01

    sra a,de   
    sra 4,de   
    sra (xix)

    sra a,e
    sra 1,e

    rlc 1,e
    rlc a,e

    rrc 1,b
    rrc a,b 

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