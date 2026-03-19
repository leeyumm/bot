# game_state.gd — 全局游戏状态（Autoload）
extends Node

enum State {
	IDLE,
	PLAYER_TURN,
	AI_TURN,
	WAITING_FOR_FLIP,
	CHECKING_MATCH,
	WAITING_ALLOCATION,
	BATTLE_SEQUENCE,
	GAME_OVER
}

var current_state: State = State.IDLE

# 血量
var player_hp: int = 25
var opponent_hp: int = 25
const MAX_HP: int = 25

# 矛盾值（小局内累积）
var player_spear: int = 0
var player_shield: int = 0
var opponent_spear: int = 0
var opponent_shield: int = 0

# 绝境加成阈值
const DESPERATION_THRESHOLD: float = 0.3

# 已配对数量
var matched_pairs: int = 0
const TOTAL_PAIRS: int = 8

func reset_round() -> void:
	"""小局结束后重置矛盾值和配对计数"""
	player_spear = 0
	player_shield = 0
	opponent_spear = 0
	opponent_shield = 0
	matched_pairs = 0

func reset_game() -> void:
	"""完全重置游戏"""
	player_hp = MAX_HP
	opponent_hp = MAX_HP
	current_state = State.IDLE
	reset_round()

func is_desperate(is_player: bool) -> bool:
	"""判断是否触发绝境加成"""
	var hp = player_hp if is_player else opponent_hp
	return float(hp) / float(MAX_HP) <= DESPERATION_THRESHOLD

func all_pairs_matched() -> bool:
	return matched_pairs >= TOTAL_PAIRS
