    main section code
    org 0
    ld wa,0xbf    ; common header

    ld ixl,4
    cp ixl,4
    jp nz,bad_end
    ld d,ixl ; d = 4

    ld iyl,1
    cp iyl,2
    jp z,bad_end
    ld d,iyl ; d = 1

    ld izl,0xf
    cp izl,3
    jp z,bad_end
    ld d,izl ; d = f

    ld spl,6
    cp spl,6
    jp nz,bad_end;
    ld d,spl ; d = 6

    ld ixh,8
    cp ixh,9  
    jp z,bad_end
    ld c,ixh
    
    ld iyh,0xa
    cp iyh,6
    jp z,bad_end
    ld b,iyh

    ld izh,9
    cp izh,9
    jp nz,bad_end
    ld h,izh

end_loop:
    ld hl,0xbabe
    ld (0xffff),0xff
    jp end_loop
bad_end:
    ld hl,0xdead
    ld (0xffff),0xff
    jp bad_end
data:
    dw 0xcafe,0xbeef,0xffff,0xeeee,0xcccc
    end