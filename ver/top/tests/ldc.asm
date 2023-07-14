    ; load control register
    maxmode on
    relaxed on
    org 0

    ld xwa,0x12345678

    ; ASL only lets us test full DMA register access
    ; the CPU seemed to be able to access individual bytes, though
    ldc DMAS0,XWA
    ldc XDE,DMAS0
    cp xde,xwa
    jp ne,bad_end
    ld xde,0

    rl 1,xwa

    ldc DMAD0,XWA
    ldc XDE,DMAD0
    cp xde,xwa
    jp ne,bad_end

    ; to do: test the rest


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end