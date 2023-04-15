    ; push 
    maxmode on
    relaxed on
    org 0
    ld a,0xbf    ; XSP = 0100

    
    pushw (xix)  ; XSP = 00FE
    cp xsp,0xfe
    jp ne,bad_end

    pushw (xix)  ; XSP = 00FC
    cp xsp,0xf2
    jp eq,bad_end

    pushw (xix)  ; XSP = 00fa
    pushw (xix)  ; XSP = 00F8
    pushw (xix)  ; XSP = 00F6     
    cp xsp,0x00f8
    jp eq,bad_end

    pushw (xix)  ; XSP = 00F4
    pushw (xix)  ; XSP = 00F2
    pushw (xix)  ; XSP = 00F0
    cp xsp,0x00f0
    jp ne,bad_end

    pushw (xix)  ; XSP = 00EE
    pushw (xix)  ; XSP = 00EC
    pushw (xix)  ; XSP = 00EA
    cp xsp,0x00ea
    jp ne,bad_end

    push xix     ; XSP = E6
    push xix     ; XSP = E2
    cp xsp,0x00e3
    jp eq,bad_end

    push xix     ; XSP = DE
    push xix     ; xsp = DA
    cp xsp,0x00da
    jp ne,bad_end


end_loop:
    ldf 0
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    db 0x12,0x34,0x56,0x78,0x9A,0xBC,0xDE,0xF0
    dw 0xbbbb,0x0000,0x0000,0x0000
ref:
    db 0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF
    dw 0x0000,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
copy:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
stack:
    end