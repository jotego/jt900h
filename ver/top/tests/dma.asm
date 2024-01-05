    ; load control register
    maxmode on
    relaxed on
    org 0

    ld xsp,0x1000
    ld xix,0xfff0
    ei 0

    ; Prepare DMA channel 0
    ld xwa,data
    ldc DMAS0,xwa
    ld xwa,dst
    ldc DMAD0,xwa
    ld wa,5
    ldc DMAC0,wa
    ld a,0
    ldc DMAM0,a         ; byte transfer, increase DST
    ldw (xix),0x8080    ; trigger DMA interrupt
    ld bc,0x10
loop:
    djnz bc,loop

    ld qe,1
    ldc xwa,DMAS0
    cp xwa,data
    jp ne,bad_end

    ld qe,2
    ldc xwa,DMAD0
    cp xwa,dst+5
    jp ne,bad_end

    ld qe,3
    ldc wa,DMAC0
    and wa,wa
    jp nz,bad_end

    ; check the copied data
    ld qe,4
    ld xiy,dst
    ld a,(data)
    ld bc,5
loop2:
    cp a,(xiy+)
    jp ne,bad_end
    djnz bc,loop2

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
dst:
    end