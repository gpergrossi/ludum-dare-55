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

static func dummy(spell, location: Vector2, team):
	print('Spell cast function not yet implemented ', spell['name']);
