# battle_resolver.gd — 战斗结算逻辑
extends Node

func resolve() -> Dictionary:
	"""结算一小局的战斗"""
	var player_dmg = _calc_damage(GameState.opponent_spear, GameState.player_shield)
	var opponent_dmg = _calc_damage(GameState.player_spear, GameState.opponent_shield)
	return {
		"player_damage": player_dmg,
		"opponent_damage": opponent_dmg,
		"player_spear": GameState.player_spear,
		"player_shield": GameState.player_shield,
		"opponent_spear": GameState.opponent_spear,
		"opponent_shield": GameState.opponent_shield,
	}

func _calc_damage(spear: int, shield: int) -> int:
	"""伤害公式：max(0, 矛 - 盾)，矛 > 0 时最低 1 点"""
	if spear <= 0:
		return 0
	return max(1, spear - shield)
