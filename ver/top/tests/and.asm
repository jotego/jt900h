    ; AND operations with complex addressing
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header
    ; Immediate addressing on bank 0
    ld wa,0xffff
    and wa,0x5555   ; wa=0x5555
    ld de,0x8001
    and de,0xffff   ; de=0x8001
    ; Indexed addressing on bank 1
    ld xix,data
    incf
    ld wa,0x1102
    ld de,(xix)
    and wa,(xix)    ; wa = dbff
    ;and wa,de
    ; Register to register on bank 2
    incf
    ld a,0xfe
    ld b,0x33
    and a,b     ; a=32
test_end:
    ld (0xffff),0xff
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end