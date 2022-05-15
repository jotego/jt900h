    ; more jump tests
    main section code
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

test_mi:
    LD HL,0
    ld c,0
    add c,1     ; c=1
    jp mi,bad_end
    sub c,4     ; c=-3
    jp pl,bad_end

test_eq:
    OR HL,0x1
    sub c,c
    jp ne,bad_end
    jp eq,test_carry
    jp bad_end
test_carry:
    OR HL,0x2
    ld a,0xff
    add a,1 ; A=0, carry=1
    jp uge,bad_end
    add a,a
    jp ult,bad_end
test_true:
    OR HL,0x4
    ld xix,test_ugt
    jp xix
    jp bad_end
test_ugt:
    OR HL,0x8
    ld a,3
    sub a,10
    jp ugt,bad_end
    ld a,10
    sub a,3
    jp ugt,ugt_ok
    jp bad_end
ugt_ok:
    OR hl,0x10

end_loop:
    ld de,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld de,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end