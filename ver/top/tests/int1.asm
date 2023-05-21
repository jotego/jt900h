    maxmode on
    ; supmode on = so the assembler parses reti
    supmode on
    relaxed on

intctrl equ 0xfff0
    org 0

    ld xix,data
    ld xsp,stack

    ; Set interrupt vectors
    ld xiy,0xffff00
    ldw (xiy+0x00),int0
    ldw (xiy+0x04),int1
    ldw (xiy+0x08),int2
    ldw (xiy+0x0C),int3
    ldw (xiy+0x10),int4
    ldw (xiy+0x14),int5
    ldw (xiy+0x18),int6
    ldw (xiy+0x1C),int7
    ; enable all interrupts
    ei 0
    ; trigger each interrupt and check that it was processed

    ; INTERRUPT LEVEL 0
    ld a,0
    ld w,0x40
    ldw (intctrl),0xff00   ; triggers interrupt 0
l0:  djnz w,l0
    cp a,0
    jp ne,bad_end           ; interrupt 0 should be ignored

    ; INTERRUPT LEVEL 1
    ld a,0
    ld w,0x40
    ldw (intctrl),0xff01   ; triggers interrupt 1
l1:  djnz w,l1
    cp a,1
    jp ne,bad_end           ; check that the interrupt was parsed

    jp end_loop

    ; each interrupt will set a bit at (data) to
    ; identify whether it was executed
int0:
    orb (xix),1
    ld a,1
    reti
    jp bad_end
int1:
    orb (xix),1<<1
    ld a,1
    reti
    jp bad_end
int2:
    orb (xix),1<<2
    ld a,1
    reti
    jp bad_end
int3:
    orb (xix),1<<3
    ld a,1
    reti
    jp bad_end
int4:
    orb (xix),1<<4
    ld a,1
    reti
    jp bad_end
int5:
    orb (xix),1<<5
    ld a,1
    reti
    jp bad_end
int6:
    orb (xix),1<<6
    ld a,1
    reti
    jp bad_end
int7:
    orb (xix),1<<7
    ld a,1
    reti
    jp bad_end

    include finish.inc
    align 16
data:
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
    dw 0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
stack:
    end