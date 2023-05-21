    ; call[cc],mem
    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; RRX, SRAX,SRLX,
    ; RLCX
    ; RRCX
    ; SRAX

    ld wa,0x9821
    ld xix,(data)
    ld bc,0x01

    rrc a,bc
    rrc 3,wa
    rrc (xbc)

    rlc 2,wa
    ld a,1
    rlc a,bc
    rlc (xix)
    ld e,0x01

    sra a,de
    sra 4,de
    sra (xix)

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
stack:
    end