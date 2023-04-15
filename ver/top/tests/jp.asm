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

    ; F
    JP F,bad_end
    ; LT
    OR HL,1
    LD a,5
    LD b,3
    SUB a,b ; a=2
    JP lt,bad_end
    sub a,b ; a=-1
    JP LT,test_le
    JP bad_end
test_le:
    OR HL,2
    LD a,-2
    LD b,-4
    ADD a,b ; a = -6
    JP LE,test_ule      ; I'm not sure about LE meaning, I'm implementing it as in Higan's
    JP bad_end
test_ule:
    OR HL,4
    LD a,4
    LD b,2
    SUB a,b ; a =2
    JP ULE,bad_end
    SUB a,b
    JP ULE,test_ov
    JP bad_end
test_ov:
    OR HL,8
    LD A,6
    LD B,4
    ADD A,B
    JP OV,bad_end
    LD A,127
    ADD A,B
    JP OV,end_loop
    jp bad_end

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