    ; SBC
    maxmode on
    relaxed on
    org 0

    ld a,0xbf    ; common header
    ld HL,0x1234
    ; 8-bit add and carry
    ld  xwa,1   ; xwa = 1
    ld  w,1     ; w = 1
    add w,a     ; w = 2
    ld  e,0xff  ; e = 0xff
    add e,a     ; e is set to zero, carry is set to 1

    ld c,0      ; c = 2
    sbc e,c     ; e = F

    ;JP OV,bad_end

    scc NOV,HL
    cp hl,0x0001
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end