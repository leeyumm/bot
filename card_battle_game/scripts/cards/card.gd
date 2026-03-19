# card.gd — 单张卡牌行为
extends Node3D

signal flip_completed(card)

var card_data: CardData
var is_face_up: bool = false
var is_locked: bool = false  # 已配对或动画中时锁定
var grid_index: int = -1     # 在网格中的位置索引

@onready var mesh: MeshInstance3D = $CardMesh
@onready var collision_area: Area3D = $ClickArea
@onready var label: Label3D = $Label3D

# 卡牌正面颜色（根据点数不同显示不同颜色）
const CARD_COLORS: Array = [
	Color(0.9, 0.2, 0.2),  # 1 - 红
	Color(0.2, 0.7, 0.2),  # 2 - 绿
	Color(0.2, 0.3, 0.9),  # 3 - 蓝
	Color(0.9, 0.8, 0.1),  # 4 - 黄
	Color(0.8, 0.3, 0.8),  # 5 - 紫
	Color(0.1, 0.8, 0.8),  # 6 - 青
	Color(0.9, 0.5, 0.1),  # 7 - 橙
	Color(0.6, 0.6, 0.6),  # 8 - 灰
]

const BACK_COLOR: Color = Color(0.15, 0.25, 0.45)

func _ready() -> void:
	# 每张卡牌创建独立材质，避免共享同一个材质对象
	var mat = StandardMaterial3D.new()
	mat.albedo_color = BACK_COLOR
	mesh.set_surface_override_material(0, mat)
	_set_back_face()

func setup(data: CardData, index: int) -> void:
	card_data = data
	grid_index = index

func flip() -> void:
	if is_locked:
		return
	is_locked = true
	var origin_y = position.y
	# 轻微随机倾斜，模拟真实纸牌不完全平整
	var tilt_z = randf_range(-0.05, 0.05)

	var tween = create_tween()
	tween.set_parallel(false)

	# 阶段1：绕 X 轴翻起到竖立（-90°），同时上抬
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation:x", -PI / 2.0, 0.18)
	tween.parallel().tween_property(self, "position:y", origin_y + 0.15, 0.18)
	tween.parallel().tween_property(self, "rotation:z", tilt_z, 0.18)

	# 中点切换材质
	tween.tween_callback(_swap_face)

	# 阶段2：落回桌面，带弹性感
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation:x", 0.0, 0.18)
	tween.parallel().tween_property(self, "position:y", origin_y, 0.18)
	tween.parallel().tween_property(self, "rotation:z", 0.0, 0.18)

	tween.tween_callback(_on_flip_done)

func flip_back() -> void:
	if is_face_up:
		is_face_up = false
		var origin_y = position.y
		var tween = create_tween()
		tween.set_parallel(false)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "rotation:x", -PI / 2.0, 0.18)
		tween.parallel().tween_property(self, "position:y", origin_y + 0.15, 0.18)
		tween.tween_callback(_set_back_face)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "rotation:x", 0.0, 0.18)
		tween.parallel().tween_property(self, "position:y", origin_y, 0.18)
		tween.tween_callback(func(): is_locked = false)

func mark_matched() -> void:
	"""配对成功后标记，不再可点击"""
	is_locked = true
	# 轻微上浮表示已配对
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 0.1, 0.3)

func _swap_face() -> void:
	is_face_up = !is_face_up
	if is_face_up:
		_set_front_face()
	else:
		_set_back_face()

func _set_front_face() -> void:
	var mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	var color_index = (card_data.value - 1) % CARD_COLORS.size()
	mat.albedo_color = CARD_COLORS[color_index]
	label.text = str(card_data.value)
	label.modulate = Color(1, 1, 1, 1)

func _set_back_face() -> void:
	var mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = BACK_COLOR
	label.text = "?"
	label.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _on_flip_done() -> void:
	if is_face_up:
		is_locked = false
		EventBus.card_flipped.emit(self)
	flip_completed.emit(self)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Card clicked: index=", grid_index, " locked=", is_locked, " face_up=", is_face_up)
		if not is_locked and not is_face_up:
			EventBus.card_clicked.emit(self)
