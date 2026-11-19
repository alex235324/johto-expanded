	db 0 ; species ID placeholder

	db  50,  75,  70,  48,  35,  70
	;   hp  atk  def  spd  sat  sdf

	db DARK, FIGHTING ; type
	db 180 ; catch rate
	db 70 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 15 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/scraggy/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_GROUND, EGG_DRAGON ; egg groups

	; tm/hm learnset
	tmhm HEADBUTT, ROAR, TOXIC, ROCK_SMASH, HIDDEN_POWER, SUNNY_DAY, SNORE, PROTECT, RAIN_DANCE, FRUSTRATION, IRON_TAIL, RETURN, DIG, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, SLUDGE_BOMB, THUNDERPUNCH, DETECT, REST, ATTRACT, FIRE_PUNCH, STRENGTH
	; end
