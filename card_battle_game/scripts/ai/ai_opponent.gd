# ai_opponent.gd — AI 对手逻辑
extends Node

enum Difficulty { EASY, MEDIUM, HARD }

@export var difficulty: Difficulty = Difficulty.MEDIUM

# AI 的记忆：grid_index -> card_value（跨轮持久）
var _memory: Dictionary = {}
var _all_cards: Array = []

# 记忆保留率
var _retention_rate: float:
	get:
		match difficulty:
			Difficulty.EASY: return 0.3
			Difficulty.MEDIUM: return 0.6
			Difficulty.HARD: return 0.9
		return 0.3

func setup(cards: Array) -> void:
	_all_cards = cards
	# 跨轮记忆：只清除本轮不再存在的 index，保留仍有效的记忆
	var valid_indices = {}
	for c in cards:
		valid_indices[c.grid_index] = true
	for key in _memory.keys():
		if not valid_indices.has(key):
			_memory.erase(key)

func observe_card(card: Node3D) -> void:
	"""AI 观察到一张被翻开的牌（玩家翻的也能看到）"""
	if randf() < _retention_rate:
		_memory[card.grid_index] = card.card_data.pair_id

func forget_card(card: Node3D) -> void:
	_memory.erase(card.grid_index)

func choose_two_cards() -> Array:
	var available = _get_available_cards()
	if available.size() < 2:
		return []
	var known_pair = _find_known_pair(available)
	if known_pair.size() == 2:
		return known_pair
	available.shuffle()
	return [available[0], available[1]]

func choose_allocation() -> bool:
	"""AI 决定分配到矛还是盾，返回 true = 矛
	核心策略：玩家矛高就加盾，否则加矛"""
	var player_spear = GameState.player_spear
	var my_hp_ratio = float(GameState.opponent_hp) / GameState.MAX_HP
	var enemy_hp_ratio = float(GameState.player_hp) / GameState.MAX_HP

	match difficulty:
		Difficulty.EASY:
			return randf() > 0.5

		Difficulty.MEDIUM:
			# 玩家本轮矛值超过 4 时优先加盾
			if player_spear >= 4:
				return randf() > 0.7  # 70% 选盾
			if my_hp_ratio < 0.4:
				return randf() > 0.65  # 血少偏防
			return randf() > 0.4  # 默认偏攻

		Difficulty.HARD:
			if enemy_hp_ratio < 0.3:
				return true  # 对手快死，全力攻
			if my_hp_ratio < 0.3:
				return false  # 自己快死，全力防
			# 动态对抗：玩家矛高就加盾，玩家盾高就加矛
			if player_spear > GameState.player_shield:
				return false  # 玩家偏攻，我偏防
			return true  # 玩家偏防，我偏攻

	return randf() > 0.5

func _get_available_cards() -> Array:
	return _all_cards.filter(func(c): return not c.is_face_up and not c.is_locked)

func _find_known_pair(available: Array) -> Array:
	var seen: Dictionary = {}
	for card in available:
		if _memory.has(card.grid_index):
			var pair_id = _memory[card.grid_index]
			if seen.has(pair_id):
				return [seen[pair_id], card]
			seen[pair_id] = card
	return []
