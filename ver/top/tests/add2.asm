; Add operations with complex addressing
    main section code
    org 0
    ld a,0xbf    ; common header
    ; Immediate addressing on bank 0
    ld a,0
    add a,1
    add a,1
    add a,1     ; a=3
    add wa,0x100    ; a=00103
    add xwa,0x10000 ; a=10103
    ; Indexed addressing on bank 1
    lda xix,data
    incf
    ld wa,0x1101
    add wa,(xix)    ; wa = dbff
    add a,1         ; a = 0, carry=1
    adc d,(xix+1)   ; d = cb
    nop
    nop
test_end:
    ld (0xffff),0xff
    jp test_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end