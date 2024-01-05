    ; load control register
    maxmode on
    relaxed on
    org 0

    ld xsp,0x1000
    ld xix,0xfff0
    ei 0

    ; Prepare DMA channel 0
    ld xwa,data+4
    ldc DMAS0,xwa
    ld xwa,dst
    ldc DMAD0,xwa
    ld wa,5
    ldc DMAC0,wa
    ld a,0xc
    ldc DMAM0,a         ; byte transfer, decrease SRC
    ldw (xix),0x8080    ; trigger DMA interrupt
    ld bc,0x10
loop:
    djnz bc,loop

    ld qe,1
    ldc xwa,DMAS0
    cp xwa,data-1
    jp ne,bad_end

    ld qe,2
    ldc xwa,DMAD0
    cp xwa,dst
    jp ne,bad_end

    ld qe,3
    ldc wa,DMAC0
    and wa,wa
    jp nz,bad_end

    ; check the copied data
    ld qe,4
    ld a,(dst)
    cp a,(data)
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
dst:
    end