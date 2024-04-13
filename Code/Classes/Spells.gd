class_name Spells

# UnitManager.summonBasicWalker(spell_def : Dictionary, position : Vector2, team : String)

static var definitions = [{
	'programmaticName': 'summonBasicWalker',
	'name': 'Summon Broccoli',
	'level': 1,
	'manaSecondsAtLevel': 5,
	'preferredLocation': 'surface',
	'rune': Rune.new([0, 3, 2]), # For visual runes, see the Miro board at https://miro.com/app/board/uXjVKUq1fIo=/
	'castFunc': UnitManager.summonBasicWalker,
}, {
	'programmaticName': 'summonFlyingBomber',
	'name': 'Summon Crow',
	'level': 2,
	'manaSecondsAtLevel': 30,
	'preferredLocation': 'sky',
	'rune': Rune.new([0, 3, 1, 2, 0]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonRanged',
	'name': 'Summon Tomato',
	'level': 2,
	'manaSecondsAtLevel': 20,
	'preferredLocation': 'surface',
	'rune': Rune.new([0, 3, 2, 1]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonWall',
	'name': 'Summon Lettuce',
	'level': 3,
	'manaSecondsAtLevel': 15,
	'preferredLocation': 'surface',
	'rune': Rune.new([2, 0, 4, 1, 3]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonBoulder',
	'name': 'Summon Pumpkin',
	'level': 3,
	'manaSecondsAtLevel': 25,
	'preferredLocation': 'surface',
	'rune': Rune.new([0, 1, 3, 4, 2, 0]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonFallingSpear',
	'name': 'Summon Carrot',
	'level': 3,
	'manaSecondsAtLevel': 10,
	'preferredLocation': '*',
	'rune': Rune.new([0, 1, 4, 0]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonExploder',
	'name': 'Summon Popcorn',
	'level': 4,
	'manaSecondsAtLevel': 15,
	'preferredLocation': 'ground',
	'rune': Rune.new([4, 1, 2]),
	'castFunc': Spells.dummy, # TODO
}, {
	'programmaticName': 'summonMeme',
	'name': 'Summon Potato', # is potato
	'level': 1,
	'manaSecondsAtLevel': 100,
	'preferredLocation': '*',
	'rune': Rune.new([2, 0, 1, 3, 4, 2, 1, 4, 0, 3, 2]),
	'castFunc': Spells.dummy, # TODO
}];

static var summonBasicWalker = Spells.definitions[0];

static func _static_init():
	for spell in definitions:
		var level : int = spell['level'];
		var manaAtLevel : int = Constants.manaByLevel[level];
		var manaPerSecondAtLevel : float = PlayerController.getManaRegenPerSecond(manaAtLevel);
		spell['manaCost'] = manaPerSecondAtLevel * spell['manaSecondsAtLevel'];

static func getSpellFor(rune: Rune):
	for spell in definitions:
		if rune.matches(spell['rune']): return spell;
	return null;

static func dummy(spell, _location: Vector2, _team):
	print('Spell cast function not yet implemented ', spell['name']);
