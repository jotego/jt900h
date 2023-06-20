    maxmode on
    relaxed on
    org 0

    ; test pre-decrement
    ld xix,dataend
    ld wa,(-xix)
    ld de,(-xix)
    ld hl,(-xix)

    cp xix,data
    jp ne,bad_end
    cp wa,0x1234
    jp ne,bad_end
    cp de,0xbeef
    jp ne,bad_end
    cp hl,0xcafe
    jp ne,bad_end

    ; test post increment
    incf
    ld wa,(xix+)
    ld de,(xix+)
    ld hl,(xix+)

    cp xix,dataend
    jp ne,bad_end
    cp hl,0x1234
    jp ne,bad_end
    cp de,0xbeef
    jp ne,bad_end
    cp wa,0xcafe
    jp ne,bad_end

    incf
    include finish.inc
data:
    dw 0xcafe,0xbeef,0x1234
dataend:
    end