    ; AND (mem),R  AND (mem),#
    maxmode on
    relaxed on
    org 0

    ld xix,data

    ld xde,data
    ld hl,0x1253
    ld wa,0         ; changes the dst register in the control logic
    andw (xde+),hl
    cpw (xix),0x252
    jp ne,bad_end
    cp xde,data+2
    jp ne,bad_end

    ld wa,0         ; changes the dst register in the control logic
    orw (xde+),hl
    cpw (xix+2),0x33fb
    jp ne,bad_end

    ld wa,0         ; changes the dst register in the control logic
    xorw (xde+),hl
    cpw (xix+4),0xe25c
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0x31a8,0xf00f,0xeeee,0xcccc
    end