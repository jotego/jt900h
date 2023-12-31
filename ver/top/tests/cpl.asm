    ; CPL
    maxmode on
    relaxed on
    org 0

    ld xsp, 0x1000

    ld qh,1
    ld de,0x5555
    ld a,0
    add a,a         ; clear H and N flags
    push f
    cpl de
    push f
    ld wa,0xaaaa
    sub wa,de
    jp ne,bad_end

    ; check the flags
    ld qh,2
    ld a,(xsp)
    ld w,(xsp+1)
    xor a,w
    cp a,0x12       ; H,N must be set
    jp ne,bad_end

    incf
    ld qh,3
    ld wa,0x55be
    ld qwa,wa
    ld b,0
    add b,b         ; clear H,N
    push f
    cpl wa
    push f
    and wa,qwa
    jp nz,bad_end

    ; check the flags
    ld qh,4
    ld a,(xsp)
    ld w,(xsp+1)
    xor a,w
    cp a,0x12       ; H,N must be set
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end