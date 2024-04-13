class_name Spells

static var definitions = [{
	'programmaticName': 'summonBasicWalker',
	'name': 'Summon Broccoli',
	'level': 1,
	'manaSecondsAtLevel': 5,
	'preferredLocation': 'surface',
	'rune': null,
	'castFunc': Spells.dummy,
}];

static var summonBasicWalker = Spells.definitions[0];

static func _static_init():
	for spell in definitions:
		var level : int = spell['level'];
		var manaAtLevel : int = Constants.manaByLevel[level];
		var manaPerSecondAtLevel : float = PlayerController.getManaRegenPerSecond(manaAtLevel);
		spell['manaCost'] = manaPerSecondAtLevel * spell['manaSecondsAtLevel'];

static func getSpellFor(rune):
	for spell in definitions:
		if spell['rune'] == rune: return spell;
	return null;

static func dummy(spell, location: Vector2, team):
	print('Spell cast function not yet implemented ', spell['name']);
