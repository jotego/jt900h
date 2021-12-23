    ; Arithmetic operations that read & write to memory
    main section code
    org 0
    ld a,0xbf    ; common header

    ; ADD (XIX)
    lda xix,data
    ld a,1
    add (xix),a
    ld b,(xix+)
    cp b,0xff
    jp ne,bad_end

    ld c,(xix+)
    add c,0x10
    cp c,0xda
    jp ne,bad_end

    ; AND (XIX)
    ld w,0x7
    and (xix),w ; 0xef
    ld d,(xix+)
    cp d,7
    jp ne,bad_end

    INCF

    ; OR (XIX)
    ld a,(xix)  ; 0xbe
    ld w,1
    or (xix),w
    ld w,(xix)
    cp w,0xbf
    jp ne,bad_end

    ; SUB (XIX)
    ld a,(xix)
    ld b,a
    sub (xix),a
    ld a,(xix)
    jp ne,bad_end

    ; XOR (XIX)
    ld a,0x18
    xor (xix),a
    ld c,(xix)
    cp c,0x18
    jp ne,bad_end

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end