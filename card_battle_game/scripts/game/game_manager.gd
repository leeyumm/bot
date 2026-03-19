# game_manager.gd — 游戏主循环
extends Node

@export var card_scene: PackedScene
@onready var turn_manager: Node = $TurnManager
@onready var card_grid: Node3D = $Table/CardGrid
@onready var camera: Camera3D = $Table/Camera3D

var all_cards: Array = []
var ai: Node = null

func _ready() -> void:
	# 加载 AI
	var ai_script = load("res://scripts/ai/ai_opponent.gd")
	ai = Node.new()
	ai.set_script(ai_script)
	add_child(ai)

	EventBus.allocation_chosen.connect(_on_allocation_chosen)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.card_flipped.connect(_on_card_flipped_for_ai)
	_setup_new_round()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var space = get_viewport().get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(event.position)
	var ray_end = ray_origin + camera.project_ray_normal(event.position) * 100.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result = space.intersect_ray(query)
	if result.is_empty():
		return
	var collider = result["collider"]
	# collider 是 Area3D（ClickArea），父节点就是 Card
	var card_node = collider.get_parent()
	if card_node and card_node.get("grid_index") != null:
		print("Ray hit card: index=", card_node.grid_index)
		if not card_node.is_locked and not card_node.is_face_up:
			EventBus.card_clicked.emit(card_node)

func _on_turn_started(is_player: bool) -> void:
	if not is_player:
		# 延迟后让 AI 执行
		await get_tree().create_timer(0.8).timeout
		_run_ai_turn()

func _run_ai_turn() -> void:
	if GameState.current_state != GameState.State.AI_TURN:
		return
	ai.setup(all_cards)
	var chosen = ai.choose_two_cards()
	if chosen.size() < 2:
		turn_manager.start_turn(true)
		return

	# AI 翻第一张
	var card_a = chosen[0]
	card_a.is_locked = false
	card_a.flip()
	await get_tree().create_timer(0.6).timeout

	# AI 翻第二张
	var card_b = chosen[1]
	card_b.is_locked = false
	card_b.flip()
	await get_tree().create_timer(0.6).timeout

	# 检查配对
	if card_a.card_data.pair_id == card_b.card_data.pair_id:
		card_a.mark_matched()
		card_b.mark_matched()
		GameState.matched_pairs += 1
		EventBus.match_found.emit(card_a, card_b)
		# AI 自动分配矛/盾
		var value = card_a.card_data.value
		if GameState.is_desperate(false):
			value += 1
		var to_spear = ai.choose_allocation()
		EventBus.allocation_chosen.emit(to_spear, value, false)
	else:
		EventBus.match_failed.emit(card_a, card_b)
		await get_tree().create_timer(1.0).timeout
		card_a.flip_back()
		card_b.flip_back()
		await get_tree().create_timer(0.5).timeout
		# AI 回合结束，切回玩家
		if GameState.all_pairs_matched():
			EventBus.round_completed.emit()
		else:
			turn_manager.start_turn(true)

func _on_card_flipped_for_ai(card) -> void:
	if ai != null:
		ai.observe_card(card)

func _setup_new_round() -> void:
	"""初始化新一小局"""
	# 清理旧卡牌
	for card in all_cards:
		card.queue_free()
	all_cards.clear()

	# 生成 8 对牌（值 1-8）
	var values = []
	for i in range(1, 9):
		values.append(i)
		values.append(i)
	values.shuffle()

	# 4x4 网格布局（第一人称视角：近排在 Z 正方向靠近玩家，远排在 Z 负方向）
	var spacing_x = 1.0
	var spacing_z = 1.1
	var start_x = -1.5
	var start_z = -1.65

	for i in range(16):
		var card = card_scene.instantiate()
		var row = i / 4
		var col = i % 4
		card.position = Vector3(start_x + col * spacing_x, 0, start_z + row * spacing_z)

		var data = CardData.new()
		data.id = i
		data.value = values[i]
		data.pair_id = values[i]  # 同值即为一对
		data.display_name = str(values[i])

		card.setup(data, i)
		card_grid.add_child(card)
		all_cards.append(card)

	# 开始玩家回合
	turn_manager.start_turn(true)

func _on_allocation_chosen(to_spear: bool, value: int, is_player: bool) -> void:
	if is_player:
		if to_spear:
			GameState.player_spear += value
		else:
			GameState.player_shield += value
	else:
		if to_spear:
			GameState.opponent_spear += value
		else:
			GameState.opponent_shield += value

	turn_manager.on_allocation_done()

func _on_round_completed() -> void:
	"""小局结束，结算战斗"""
	GameState.current_state = GameState.State.BATTLE_SEQUENCE

	# 计算伤害
	var player_dmg = max(0, GameState.opponent_spear - GameState.player_shield)
	if GameState.opponent_spear > 0 and player_dmg == 0:
		player_dmg = 1  # 最低1点伤害

	var opponent_dmg = max(0, GameState.player_spear - GameState.opponent_shield)
	if GameState.player_spear > 0 and opponent_dmg == 0:
		opponent_dmg = 1

	GameState.player_hp -= player_dmg
	GameState.opponent_hp -= opponent_dmg

	EventBus.battle_resolved.emit(player_dmg, opponent_dmg)

	await get_tree().create_timer(2.0).timeout

	# 检查游戏结束
	if GameState.player_hp <= 0 or GameState.opponent_hp <= 0:
		EventBus.game_over.emit(GameState.player_hp > 0)
		GameState.current_state = GameState.State.GAME_OVER
	else:
		# 开始新一小局
		GameState.reset_round()
		_setup_new_round()
