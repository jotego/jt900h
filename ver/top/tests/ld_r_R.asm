    main section code
    org 0
    ld wa,0xbf    ; common header

    incf
    ld xwa,0x00000000
    ld xbc,0x00000000
    ld xde,0x00000000
    ld xhl,0x00000000
    ld xwa,0xffffffff
    ld xbc,0xffffffff
    ld xde,0xffffffff
    ld xhl,0xffffffff
    ld xwa,0x00000000
    ld xbc,0x00000000
    ld xde,0x00000000
    ld xhl,0x00000000


;    ld qixl,a
;    cp qixl,15  
;    ld qiyl,a
;    cp qiyl,15
;    ld qizl,a
;    cp qizl,15
;    ld qspl,a
;    cp qspl,15

;    ld ixh,e
;    cp ixh,7
;    ld iyh,e
;    cp iyh,7
;    ld izh,e
;    cp izh,7
;    ld sph,e
;    cp sph,7

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