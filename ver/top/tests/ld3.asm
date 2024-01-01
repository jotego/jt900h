    ; ld<w> (#16),(mem) and ld<w> (mem),(#16)
    maxmode on
    relaxed on
    org 0

    ld xix,0x200
    ld xiy,0x300
    ld xwa,0xcafe

    ; word write, LD<W> (mem),(#16)
    ld (xix),wa        ; (0x200) = 0xcafe
    ldw (0x300),(0x200)
    ld bc,(xiy)
    cp bc,0xcafe
    jp ne,bad_end

    ; byte write, LD<W> (mem),(#16)
    ld bc,0
    ld (0x300),bc
    ldb (0x300),(0x200)
    ld bc,(0x300)
    cp bc,0xfe
    jp ne,bad_end

    ; word write, LD<W> (#16),(mem)
    ld (xix),wa        ; (0x200) = 0xcafe
    ldw (0x300),(xix)
    ld bc,(xiy)
    cp bc,0xcafe
    jp ne,bad_end

    ; byte write, LD<W> (#16),(mem)
    ld bc,0
    ld (0x300),bc
    ldb (0x300),(xix)
    ld bc,(0x300)
    cp bc,0xfe
    jp ne,bad_end

    include finish.inc
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end