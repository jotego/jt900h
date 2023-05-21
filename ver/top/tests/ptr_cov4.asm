    maxmode on
    relaxed on
    org 0
    ld wa,0xbf    ; common header

    ld a,0xff
    ld b,0x00
    ld qiyl,0x00
    ld ixh,0x00
    ld iyl,0x00
    cp a,qiyl
    jp eq,bad_end
    cp a,ixh
    jp eq,bad_end
    cp b,iyl
    jp ne,bad_end

    ld qiyl,0xff
    ld ixh,0xff
    ld iyl,0xff
    cp a,qiyl
    jp ne,bad_end
    cp b,ixh
    jp eq,bad_end
    cp a,iyl
    jp ne,bad_end

    ld qiyl,0x00
    ld ixh,0x00
    ld iyl,0x00
    cp a,qiyl
    jp eq,bad_end
    cp a,ixh
    jp eq,bad_end
    cp b,iyl
    jp ne,bad_end

    include finish.inc
data:
    dw 0x0000, 0x0000, 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end