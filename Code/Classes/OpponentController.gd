# Bot "AI" controller. Casts spells for the enemy periodically. [WIP]
class_name OpponentController extends AbstractSpellCaster

var cooldowns = [];

@onready var sigil := %OpponentSigil

var _already_casting := false

func _ready():
	super();
	cooldowns.resize(Spells.definitions.size());
	cooldowns.fill(0);
	team = Team.ENEMY_TEST
	died.connect(_on_died)

func canCast(spell, location):
	if spell.has('botDoesNotCast'): return false;
	if level < spell['level']: return false;
	if cooldowns[spell['id']] > 0: return false;
	return super(spell, location);

func cast(spell, location = null):
	# This will break a little (be ugly) if multiple casts overlap.
	# We're guarding against that with _already_casting.
	if _already_casting: return false
	_already_casting = true
	await sigil.play_rune(spell['rune'])
	var success = super(spell, location);
	if success: cooldowns[spell['id']] = spell['botCooldownSeconds'];
	_already_casting = false
	return success

func getDefaultLocation(spell): # TODO D.R.Y.
	var loc = UnitManager._unit_manager_static.summon_default_position_right.global_position;
	loc = Vector2(loc.x, loc.y);
	match spell['preferredLocation']:
		'none': return loc
		'*': return Vector2.ZERO;
		'ground': return loc;
		'sky': return loc + Vector2(0, -10);
	assert(false, "no default location for %s" % spell['preferredLocation'])

func _process(delta):
	super(delta);
	
	# Tick down cooldowns
	for i in cooldowns.size():
		cooldowns[i] -= delta;

	var manaPercent = mana / maxMana * 100.0;
	
	# If mana above 80% summon something
	if manaPercent < 80:
		return

	var bomber_position = getDefaultLocation(Spells.summonFlyingBomber) + Vector2(-10 - randf() * 50, -10)
	if randf() > 0.8 and canCast(Spells.summonFlyingBomber, bomber_position):
		cast(Spells.summonFlyingBomber, bomber_position)
		return
		
	var ranged_position = getDefaultLocation(Spells.summonRanged) + Vector2(-10 - randf() * 20, -10)
	if randf() > 0.8 and canCast(Spells.summonRanged, ranged_position):
		cast(Spells.summonRanged, ranged_position)
		return
	
	var wall_position = getDefaultLocation(Spells.summonWall) + Vector2(-10 - randf() * 50, -10)
	if randf() > 0.8 and canCast(Spells.summonWall, wall_position):
		cast(Spells.summonWall, wall_position)
		return
	
	var boulder_position = getDefaultLocation(Spells.summonBoulder) + Vector2(-10 - randf() * 20, -10)
	if randf() > 0.8 and canCast(Spells.summonBoulder, boulder_position):
		cast(Spells.summonBoulder, boulder_position)
		return
	
	cast(Spells.summonBasicWalker);

func _on_died() -> void:
	if (LevelLoader.current_level + 1 >= len(Constants.manaByLevel)):
		%AnnounceLabel.text = "You win! :D - Showing credits...."
	else:
		%AnnounceLabel.text = "You win! :D - moving to level %d" % (LevelLoader.current_level + 1)
	await get_tree().create_timer(4.0).timeout
	await %Fader.fade_in()
	# TODO race condition between winning, losing, and moving to the next level.
	LevelLoader.load_level(LevelLoader.current_level + 1)
	
