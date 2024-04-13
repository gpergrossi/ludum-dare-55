class_name Rune extends RefCounted

# Runes represent a single 'shape' drawn on the sigil.
# Each edge in a rune is unique. ints in this class are vertices on the sigil:
#       0
#      / \
#    4     1
#     \   /
#      3-2 

# Original path taken to draw this rune.
var path : Array[int] = []
# Should be used as the comparator, etc. for this rune. 
# Invariants: kept sorted, each element's x <= y.
var canonical_edge_list : Array[Vector2i] = []

func _init(path_ : Array[int]):
	path = path_.duplicate()
	for i in range(path.size() - 1):
		var x := path[i]
		var y := path[i + 1]
		if x > y:
			# I do not apologize for this.
			x = x ^ y
			y = y ^ x
			x = x ^ y
		canonical_edge_list.push_back(Vector2i(x, y))
	canonical_edge_list.sort()

func matches(other : Rune):
	return canonical_edge_list == other.canonical_edge_list;
