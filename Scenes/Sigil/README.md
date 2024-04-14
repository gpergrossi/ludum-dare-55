System for drawing runes.

To use:
* instantiate sigil.tscn
* for player input: listen to output Runes from the rune_drawn signal.
* for rendering NPC casting: set is_interactable=false and call play_rune().
