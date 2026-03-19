# turn_manager.gd — 回合管理
extends Node

var first_card: Node3D = null
var second_card: Node3D = null
var flipped_count: int = 0
var is_player_turn: bool = true

func _ready() -> void:
	EventBus.card_clicked.connect(_on_card_clicked)

func start_turn(player_turn: bool) -> void:
	is_player_turn = player_turn
	flipped_count = 0
	first_card = null
	second_card = null
	GameState.current_state = GameState.State.PLAYER_TURN if player_turn else GameState.State.AI_TURN
	EventBus.turn_started.emit(player_turn)

func _on_card_clicked(card: Node3D) -> void:
	if not is_player_turn:
		return
	# 允许 PLAYER_TURN（第一张）和 WAITING_FOR_FLIP（第二张）两个状态接受点击
	var state = GameState.current_state
	if state != GameState.State.PLAYER_TURN and state != GameState.State.WAITING_FOR_FLIP:
		return

	if flipped_count == 0:
		first_card = card
		card.flip()
		flipped_count = 1
		GameState.current_state = GameState.State.WAITING_FOR_FLIP
	elif flipped_count == 1 and card != first_card:
		# 锁定，防止在检查期间再次点击
		GameState.current_state = GameState.State.CHECKING_MATCH
		second_card = card
		card.flip()
		flipped_count = 2
		await get_tree().create_timer(0.5).timeout
		_check_match()

func _check_match() -> void:
	GameState.current_state = GameState.State.CHECKING_MATCH

	if first_card.card_data.pair_id == second_card.card_data.pair_id:
		# 配对成功
		first_card.mark_matched()
		second_card.mark_matched()
		GameState.matched_pairs += 1
		EventBus.match_found.emit(first_card, second_card)

		# 请求玩家分配矛/盾
		var value = first_card.card_data.value
		if GameState.is_desperate(true):
			value += 1
		GameState.current_state = GameState.State.WAITING_ALLOCATION
		EventBus.allocation_requested.emit(value, true)
	else:
		# 配对失败
		EventBus.match_failed.emit(first_card, second_card)
		await get_tree().create_timer(1.0).timeout
		first_card.flip_back()
		second_card.flip_back()
		await get_tree().create_timer(0.5).timeout
		_end_turn()

func on_allocation_done() -> void:
	"""分配完成后调用"""
	if GameState.all_pairs_matched():
		EventBus.round_completed.emit()
	else:
		_end_turn()

func _end_turn() -> void:
	EventBus.turn_ended.emit(is_player_turn)
	# 通过 start_turn 切换回合，game_manager 监听 turn_started 信号来驱动 AI
	start_turn(not is_player_turn)
