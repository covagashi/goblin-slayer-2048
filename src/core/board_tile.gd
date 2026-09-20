class_name BoardTile
extends RefCounted
## A single board cell occupant. Logic packet — NOT a node.

enum Kind { GOBLIN, CHEST, SHOP }

var id: int = -1
var kind: Kind = Kind.GOBLIN
var value: int = 0
var hp: int = 1
var max_hp: int = 1
var poisoned: int = 0
var variant_file: String = ""   # cosmetic rare skin (filename in variants/)
var is_golden: bool = false     # ultra-rare: gold x10

var row: int = 0
var col: int = 0


func duplicate_tile() -> TileData:
	var t := TileData.new()
	t.id = id
	t.kind = kind
	t.value = value
	t.hp = hp
	t.max_hp = max_hp
	t.poisoned = poisoned
	t.variant_file = variant_file
	t.is_golden = is_golden
	t.row = row
	t.col = col
	return t


func is_goblin() -> bool:
	return kind == Kind.GOBLIN


func label() -> String:
	if is_golden:
		return "Golden Goblin(%d)" % value
	return "Goblin(%d)" % value
