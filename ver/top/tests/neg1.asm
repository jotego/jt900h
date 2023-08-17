    ; Arithmetic operations that read & write to memory
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

    ld xix,0x0003595F
    neg ix
    cp ix,0xA6A1
    jp ne,bad_end

    ld xhl,0x75bdF9B9
    neg l
    JP NC,bad_end
    cp l,0x47
    jp ne,bad_end


    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end