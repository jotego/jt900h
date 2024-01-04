    ; load control register
    maxmode on
    relaxed on
    org 0

    ld xsp,0x1000
    ld xwa,0x12345678

    ; check read/write from DMAS0 to DMAD3
    ld b,8
loop:
    ldc DMAS0,xwa
    ldc xde,DMAS0
    cp xde,xwa
    jp ne,bad_end
    incb 4,(loop+2)       ; modify OP code to check the next 32-bit CR
    incb 4,(loop+5)
    call rand           ; randomize xwa contents
    djnz loop

    ; check read/write from DMAC0 to DMAC3
    ld b,4
loop16:
    ldc DMAC0,wa
    ldc de,DMAC0
    cp de,wa
    jp ne,bad_end
    incb 4,(loop16+2)       ; modify OP code to check the next 16-bit CR
    incb 4,(loop16+5)
    call rand           ; randomize xwa contents
    djnz loop16

    ; check read/write from DMAM0 to DMAM3
    ld b,4
loop8:
    ldc DMAM0,a
    ldc e,DMAM0
    cp e,a
    jp ne,bad_end
    incb 4,(loop8+2)       ; modify OP code to check the next 16-bit CR
    incb 4,(loop8+5)
    call rand           ; randomize xwa contents
    djnz loop8

    jp end_loop

rand:   ; easy LFSR
    ldcf  15,wa
    xorcf 7,wa
    rl 1,xwa
    ret

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end