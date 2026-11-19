	db 0 ; species ID placeholder

	db  70,  30,  50, 105,  95, 135
	;   hp  atk  def  spd  sat  sdf

	db ICE, ICE ; type
	db 25 ; catch rate
	db 180 ; base exp
	db NO_ITEM, NEVERMELTICE ; items
	db GENDER_UNKNOWN ; gender ratio
	db 100 ; unknown 1
	db 25 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/cryogonal/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_MINERAL, EGG_MINERAL ; egg groups

	; tm/hm learnset
	tmhm TOXIC, HIDDEN_POWER, SNORE, BLIZZARD, HYPER_BEAM, ICY_WIND, PROTECT, RAIN_DANCE, FRUSTRATION, SOLARBEAM, RETURN, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, REST, ATTRACT, ICE_BEAM
	; end
