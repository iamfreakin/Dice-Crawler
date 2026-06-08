class_name EnemyInstance
extends RefCounted
## 전투 중 적 1마리의 런타임 상태. EnemyData(정적 정의)를 감싸 HP/방어/의도 진행을 추적한다.

var data: EnemyData
var current_hp: int
var block: int = 0
var _intent_index: int = 0

func _init(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_hp = enemy_data.max_hp

func current_intent() -> IntentData:
	if data.intent_pattern.is_empty():
		return null
	return data.intent_pattern[_intent_index % data.intent_pattern.size()]

func advance_intent() -> void:
	_intent_index += 1

## 데미지를 받는다. 방어(block)로 먼저 흡수.
func take_damage(amount: int) -> void:
	var absorbed: int = min(block, amount)
	block -= absorbed
	current_hp = max(0, current_hp - (amount - absorbed))

func gain_block(amount: int) -> void:
	block += amount

func is_dead() -> bool:
	return current_hp <= 0
