# event_bus.gd — 全局信号总线（Autoload）
# 所有模块通过这里通信，避免直接耦合
extends Node

# 卡牌相关
signal card_clicked(card)
signal card_flip_completed(card)
signal card_flipped(card)
signal match_found(card_a, card_b)
signal match_failed(card_a, card_b)

# 矛盾分配
signal allocation_requested(value: int, is_player: bool)
signal allocation_chosen(to_spear: bool, value: int, is_player: bool)

# 回合相关
signal turn_started(is_player_turn: bool)
signal turn_ended(is_player_turn: bool)

# 战斗相关
signal round_completed()
signal battle_resolved(player_dmg: int, opponent_dmg: int)

# 道具相关
signal item_used(item_type: String, is_player: bool)

# 游戏流程
signal game_over(player_won: bool)
