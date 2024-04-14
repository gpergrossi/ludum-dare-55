# Bot "AI" controller. Casts spells for the enemy periodically. [WIP]
class_name OpponentController extends AbstractSpellCaster

var cooldowns = [];

func _ready():
	super();
	cooldowns.resize(Spells.definitions.size());
	cooldowns.fill(0);
	teamName = TeamDefs.Enemy.team_name;

func canCast(spell):
	if spell.has('botDoesNotCast'): return false;
	if level < spell['level']: return false;
	if cooldowns[spell['id']] > 0: return false;
	return super(spell);

func cast(spell, location = null):
	var success = super(spell, location);
	if success: cooldowns[spell['id']] = spell['botCooldownSeconds'];

func getDefaultLocation(spell): # TODO D.R.Y.
	var loc = UnitManager._unit_manager_static.summon_default_position_right.global_position;
	loc = Vector2(loc.x, loc.y);
	match spell['preferredLocation']:
		'*': return Vector2.ZERO;
		'ground': return loc;
		'sky': return loc + Vector2(0, -10);

func _process(delta):
	super(delta);
	
	# Tick down cooldowns
	for i in cooldowns.size():
		cooldowns[i] -= delta;
	
	var manaPercent = mana / maxMana * 100.0;
	
	# If mana above 80% summon basic infantry
	if manaPercent >= 80:
		cast(Spells.summonBasicWalker);
