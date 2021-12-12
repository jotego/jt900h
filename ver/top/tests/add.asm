    ; Add operations
    main section code
    org 0
    ld a,0xbf    ; common header
    ; 8-bit add and carry
    ld  xwa,1   ; xwa = 1
    ld  w,1     ; w = 1
    add w,a     ; w = 2
    ld  e,0xff  ; e = 0xff
    add e,a     ; e is set to zero, carry is set to 1
    adc d,e     ; d = 1
    ld  l,0x38  ; l = 38
    ld  h,0x1a  ; h = 1a
    add h,l     ; h = 52
    ; 16-bit adds
    incf            ; bank 1
    ld wa,0x3456    ; wa = 3456
    ld de,0xf000    ; de = f000
    add wa,de       ; wa = 2426 + carry
    adc h,h         ; h = 1
    ;; 32-bit adds
    incf
    ld xwa,0x10000000
    ld xde,0x0FFFFFFF
    add xwa,xde
    nop
    nop
    nop
    nop
test_end:
    ld (0xffff),0xff
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end