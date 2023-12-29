    ; Add operations
    maxmode on
    relaxed on
    org 0
    ; 8-bit add and carry
    ld qh,1
    ld  xwa,1   ; xwa = 1
    ld  w,1     ; w = 1
    add w,a     ; w = 2
    jp c,bad_end
    jp ov,bad_end

    ld qh,2
    ld  e,0xff  ; e = 0xff
    add e,a     ; e is set to zero, carry is set to 1
    jp nc,bad_end
    jp ov,bad_end

    ld qh,3
    adc d,e     ; d = 1
    ld  l,0x38  ; l = 38
    ld  h,0x1a  ; h = 1a
    add h,l     ; h = 52
    jp mi,bad_end
    jp c,bad_end
    jp ov,bad_end

    ; 16-bit adds
    ld qh,4
    incf            ; bank 1
    ld wa,0x3456    ; wa = 3456
    ld de,0x8000    ; de = 8000
    add wa,de       ; wa = 2426
    jp pl,bad_end
    jp c,bad_end

    ld qh,5
    ld h,0
    scf
    adc h,h         ; h = 1
    jp z,bad_end
    jp c,bad_end

    ;; 32-bit adds
    ld qh,6
    incf
    ld xwa,0x01000000
    ld xde,0x7FFFFFFF
    add xwa,xde
    jp nov,bad_end
    jp c,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end