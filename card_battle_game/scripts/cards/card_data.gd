# card_data.gd — 卡牌数据资源
class_name CardData
extends Resource

@export var id: int           # 唯一标识
@export var value: int        # 点数（1-8）
@export var pair_id: int      # 配对 ID（同一对牌共享）
@export var display_name: String
