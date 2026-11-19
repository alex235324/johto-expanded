CountSetBits::
; Count the number of set bits in b bytes starting from hl.
; Return in a, c and [wNumSetBits].
	ld c, 0
.next
	ld a, [hli]
	ld e, a
	ld d, 8

.count
	srl e
	ld a, 0
	adc c
	ld c, a
	dec d
	jr nz, .count

	dec b
	jr nz, .next

	ld a, c
	ld [wNumSetBits], a
	ret

CountSetBits16::
; Count the number of set bits in bc bytes starting from hl - assumes bc < $1000
; Returns in bc; hl points to the end of the buffer; clobbers everything else
; Assumes that CountSetBits will leave hl pointing to the end of the buffer
	swap b
	ld a, c
	swap a
	and $f
	or b
	ld d, a
	ld a, c
	jr z, .small_count
	ld bc, 0
	and $f
	jr z, .loop
	push de
	call .small_count
	pop de
.loop
	push bc
	push de
	ld b, $10
	call CountSetBits
	pop de
	pop bc
	add a, c
	ld c, a
	jr nc, .handle_loop
	inc b
.handle_loop
	dec d
	jr nz, .loop
	ret

.small_count
	ld b, a
	call CountSetBits
	ld b, 0
	ret

GetWeekday::
	ld a, [wCurDay]
.mod
	sub 7
	jr nc, .mod
	add 7
	ret

SetSeenAndCaughtMon::
	call GetPokemonFlagIndex
	push de
	call SetSeenMonIndex
	pop de
SetCaughtMonIndex::
	ld hl, wPokedexCaught
	jr SetPokedexStatusMonIndex

SetSeenMon::
	call GetPokemonFlagIndex
SetSeenMonIndex::
	ld hl, wPokedexSeen
SetPokedexStatusMonIndex:
	ld b, SET_FLAG
	jr FlagActionBaseOne

CheckCaughtMon::
	call GetPokemonFlagIndex
CheckCaughtMonIndex::
	ld hl, wPokedexCaught
	jr CheckPokedexStatusMonIndex

CheckSeenMon::
	call GetPokemonFlagIndex
CheckSeenMonIndex::
	ld hl, wPokedexSeen
CheckPokedexStatusMonIndex:
	ld b, CHECK_FLAG
FlagActionBaseOne:
	dec de
	; fallthrough

PokedexFlagAction::
; FlagAction (b, bit de, array hl) on wPokedexCaught/wPokedexSeen, which live
; in their own WRAM bank. Like FlagAction, a CHECK returns the result in c and a
; with nz if set.
	ldh a, [rSVBK]
	push af
	ld a, BANK(wPokedexCaught)
	ldh [rSVBK], a
	call FlagAction
	pop af
	ldh [rSVBK], a
	ld a, c
	and a
	ret

CountPokedexFlags16::
; Count the set bits in bc bytes at hl (wPokedexCaught or wPokedexSeen).
; Returns the count in bc; clobbers a, de, hl. Doesn't touch wNumSetBits,
; which is in WRAM bank 1 and can't be written while the flags' bank is mapped.
	ldh a, [rSVBK]
	push af
	ld a, BANK(wPokedexCaught)
	ldh [rSVBK], a
	ld d, b
	ld e, c
	ld bc, 0
.byte_loop
	ld a, d
	or e
	jr z, .done
	dec de
	ld a, [hli]
.bit_loop
	and a
	jr z, .byte_loop
	srl a
	jr nc, .bit_loop
	inc bc
	jr .bit_loop
.done
	pop af
	ldh [rSVBK], a
	ret

GetPokemonFlagIndex:
	call GetPokemonIndexFromID
	ld d, h
	ld e, l
	ret
