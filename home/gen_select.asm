; Pokégear Gen Select: wild grass/water lookup for wGenSelect = 1-5.
; Called from _GrassWildmonLookup/_WaterWildmonLookup (bankA) instead of the
; default tables. Finds the current map in the selected generation's Johto,
; then Kanto table, copies its entry to wGenWildBuffer and returns
; hl = wGenWildBuffer with carry set (carry clear if the map has no entry).

GenGrassWildmonLookup::
	ld hl, GenGrassWildMonTables
	ld bc, GRASS_WILDDATA_LENGTH
	jr GenWildmonLookup

GenWaterWildmonLookup::
	ld hl, GenWaterWildMonTables
	ld bc, WATER_WILDDATA_LENGTH
	; fallthrough

GenWildmonLookup:
	ld a, [wGenSelect]
	dec a
	ld e, a
	add a
	add a
	add e ; 5 bytes per generation: bank, Johto table, Kanto table
	ld e, a
	ld d, 0
	add hl, de
	ldh a, [hROMBank]
	push af
	ld a, [hli]
	rst Bankswitch
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push hl
	ld h, d
	ld l, e
	call .Search
	pop de
	jr c, .found
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	call .Search
	jr nc, .not_found
.found
	ld de, wGenWildBuffer
	call CopyBytes
	pop af
	rst Bankswitch
	ld hl, wGenWildBuffer
	scf
	ret

.not_found
	pop af
	rst Bankswitch
	and a
	ret

.Search:
; hl = table, bc = entry length; carry + hl = entry if the current map is in it
	ld a, [hl]
	cp -1
	ret z ; carry is clear
	ld a, [wMapGroup]
	cp [hl]
	jr nz, .next
	inc hl
	ld a, [wMapNumber]
	cp [hl]
	dec hl
	jr z, .match
.next
	add hl, bc
	jr .Search
.match
	scf
	ret

GenGrassWildMonTables:
for n, 1, NUM_GEN_SELECT
	db BANK(JohtoGrassWildMonsGen{d:n})
	dw JohtoGrassWildMonsGen{d:n}, KantoGrassWildMonsGen{d:n}
endr

GenWaterWildMonTables:
for n, 1, NUM_GEN_SELECT
	db BANK(JohtoWaterWildMonsGen{d:n})
	dw JohtoWaterWildMonsGen{d:n}, KantoWaterWildMonsGen{d:n}
endr
