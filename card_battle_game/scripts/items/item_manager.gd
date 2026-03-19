# item_manager.gd — 道具管理
extends Node

enum ItemType { PEEK, SHUFFLE, DOUBLE, MIRROR }

# 道具池配置
const ITEM_POOL: Array = [
	{ "type": ItemType.PEEK, "name": "窥视", "desc": "偷看1张牌（3秒）", "max": 2 },
	{ "type": ItemType.SHUFFLE, "name": "洗牌", "desc": "打乱未配对的牌", "max": 1 },
	{ "type": ItemType.DOUBLE, "name": "双倍", "desc": "下次配对点数×2", "max": 1 },
	{ "type": ItemType.MIRROR, "name": "镜像", "desc": "复制对手上回合分配", "max": 1 },
]

var player_items: Array = []
var opponent_items: Array = []
var double_active_player: bool = false
var double_active_opponent: bool = false

func distribute_items() -> void:
	"""小局开始时随机发放道具"""
	player_items = _random_items(randi_range(2, 3))
	opponent_items = _random_items(randi_range(2, 3))
	double_active_player = false
	double_active_opponent = false

func use_item(item_type: ItemType, is_player: bool) -> bool:
	"""使用道具，返回是否成功"""
	var items = player_items if is_player else opponent_items
	var idx = -1
	for i in items.size():
		if items[i]["type"] == item_type:
			idx = i
			break
	if idx == -1:
		return false
	items.remove_at(idx)
	EventBus.item_used.emit(_type_to_name(item_type), is_player)
	return true

func _random_items(count: int) -> Array:
	var result = []
	var pool = ITEM_POOL.duplicate(true)
	pool.shuffle()
	for i in min(count, pool.size()):
		result.append(pool[i].duplicate())
	return result

func _type_to_name(t: ItemType) -> String:
	match t:
		ItemType.PEEK: return "窥视"
		ItemType.SHUFFLE: return "洗牌"
		ItemType.DOUBLE: return "双倍"
		ItemType.MIRROR: return "镜像"
	return ""
