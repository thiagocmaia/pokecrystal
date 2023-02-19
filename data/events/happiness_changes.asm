HappinessChanges:
; entries correspond to HAPPINESS_* constants
	table_width 3, HappinessChanges
	; change if happiness < 100, change if happiness < 200, change otherwise
	db  +5,  +5,  +5 ; Gained a level
	db  +0,  +0,  +0 ; Vitamin
	db  +0,  +0,  +0 ; X Item
	db  +0,  +0,  +0 ; Battled a Gym Leader
	db  +0,  +0,  +0 ; Learned a move
	db  -0,  -0,  -0 ; Lost to an enemy
	db  -0,  -0, -0 ; Fainted due to poison
	db  -0,  -0, -0 ; Lost to a much stronger enemy
	db  +0,  +0,  +0 ; Haircut (older brother) 1
	db  +0,  +0,  +0 ; Haircut (older brother) 2
	db  +0,  +0,  +0 ; Haircut (older brother) 3
	db  +0,  +0,  +0 ; Haircut (younger brother) 1
	db  +0,  +0,  +0 ; Haircut (younger brother) 2
	db +0, +0,  +0 ; Haircut (younger brother) 3
	db  -0,  -0, -0 ; Used Heal Powder or Energypowder (bitter)
	db -0, -0, -0 ; Used Energy Root (bitter)
	db -0, -0, -0 ; Used Revival Herb (bitter)
	db  +0,  +0,  +0 ; Grooming
	db +5,  +5,  +5 ; Gained a level in the place where it was caught
	assert_table_length NUM_HAPPINESS_CHANGES
