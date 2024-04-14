class_name Spells

static var definitions = [{
	'programmaticName': 'summonBasicWalker',
	'name': 'Summon Broccoli',
	'level': 1,
	'manaSecondsAtLevel': 5,
	'preferredLocation': 'ground',
	'rune': Rune.new([0, 3, 2]), # For visual runes, see the Miro board at https://miro.com/app/board/uXjVKUq1fIo=/
	'castFunc': UnitManager.summonBasicWalker,
	'botCooldownSeconds': 1,
}, {
	'programmaticName': 'summonFlyingBomber',
	'name': 'Summon Crow',
	'level': 2,
	'manaSecondsAtLevel': 30,
	'preferredLocation': 'sky',
	'rune': Rune.new([0, 3, 1, 2, 0]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 5,
}, {
	'programmaticName': 'summonRanged',
	'name': 'Summon Tomato',
	'level': 2,
	'manaSecondsAtLevel': 20,
	'preferredLocation': 'ground',
	'rune': Rune.new([0, 3, 2, 1]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 5,
}, {
	'programmaticName': 'summonWall',
	'name': 'Summon Lettuce',
	'level': 3,
	'manaSecondsAtLevel': 15,
	'preferredLocation': 'ground',
	'rune': Rune.new([2, 0, 4, 1, 3]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 5,
}, {
	'programmaticName': 'summonBoulder',
	'name': 'Summon Pumpkin',
	'level': 3,
	'manaSecondsAtLevel': 25,
	'preferredLocation': 'ground',
	'rune': Rune.new([0, 1, 3, 4, 2, 0]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 10,
}, {
	'programmaticName': 'summonFallingSpear',
	'name': 'Summon Carrot',
	'level': 3,
	'manaSecondsAtLevel': 10,
	'preferredLocation': '*',
	'rune': Rune.new([0, 1, 4, 0]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 5,
}, {
	'programmaticName': 'summonExploder',
	'name': 'Summon Popcorn',
	'level': 4,
	'manaSecondsAtLevel': 15,
	'preferredLocation': 'ground',
	'rune': Rune.new([4, 1, 2]),
	'castFunc': Spells.dummy, # TODO
	'botCooldownSeconds': 15,
}, {
	'programmaticName': 'summonMeme',
	'name': 'Summon Potato', # is potato
	'level': 1,
	'manaSecondsAtLevel': 100,
	'preferredLocation': '*',
	'rune': Rune.new([2, 0, 1, 3, 4, 2, 1, 4, 0, 3, 2]),
	'castFunc': Spells.dummy, # TODO
	'botDoesNotCast': true,
}];

static var summonBasicWalker = Spells.definitions[0];

static func _static_init():
	var id = 0;
	for spell in definitions:
		var level : int = spell['level'];
		var manaPerSecondAtLevel : float = PlayerController.getManaRegenPerSecond(level);
		spell['manaCost'] = manaPerSecondAtLevel * spell['manaSecondsAtLevel'];
		spell['id'] = id;
		id += 1;

static func getSpellFor(rune: Rune):
	for spell in definitions:
		if rune.matches(spell['rune']): return spell;
	return null;

static func dummy(spell, _location: Vector2, _team):
	print('Spell cast function not yet implemented ', spell['name']);
