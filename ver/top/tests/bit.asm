    ; jump tests
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; common header

; F   (false)
; LT  (signed less than)
; LE  (signed less than or equal)
; ULE (unsigned less than or equal)
; OV  (overflow)
; MI  (minus)
; EQ  (equal)
; ULT (unsigned less than)
; T   (true)
; GE  (signed greater than or equal)
; GT  (signed greater than)
; UGT (unsigned greater than)
; NOV (no overflow)
; PL  (plus)
; NE  (not equal)
; UGE (unsigned greater than or equal)

    ld wa,1
    ld bc,0
    bit 0,wa
    jp eq,bad_end
    or de,1

    ld wa,2
    ld bc,0
    bit 1,wa
    jp eq,bad_end
    or de,2

    ld wa,4
    ld bc,0
    bit 2,wa
    jp eq,bad_end
    or de,4

    ld wa,0x40
    ld bc,0
    bit 6,wa
    jp eq,bad_end
    or de,0x40

    ld wa,0x80
    ld bc,0
    bit 7,wa
    jp eq,bad_end
    or de,0x80

    ld wa,0x100
    ld bc,0
    bit 8,wa
    jp eq,bad_end
    or de,0x100

    ld wa,0x200
    ld bc,0
    bit 9,wa
    jp eq,bad_end
    or de,0x200

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end