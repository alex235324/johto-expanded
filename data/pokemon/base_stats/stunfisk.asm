	db 0 ; species ID placeholder

	db 109,  66,  84,  32,  81,  99
	;   hp  atk  def  spd  sat  sdf

	db GROUND, ELECTRIC ; type
	db 75 ; catch rate
	db 165 ; base exp
	db NO_ITEM, SOFT_SAND ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 20 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/stunfisk/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_WATER_1, EGG_INDETERMINATE ; egg groups

	; tm/hm learnset
	tmhm CURSE, TOXIC, HIDDEN_POWER, SNORE, PROTECT, RAIN_DANCE, ENDURE, FRUSTRATION, THUNDER, EARTHQUAKE, RETURN, DIG, MUD_SLAP, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SLUDGE_BOMB, SANDSTORM, REST, ATTRACT, SURF, FLASH, THUNDERBOLT
	; end
