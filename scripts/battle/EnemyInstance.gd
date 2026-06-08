class_name EnemyInstance
extends RefCounted
## 전투 중 적 한 마리의 런타임 상태.

const VULNERABLE_MULT: float = 1.5
const WEAK_MULT: float = 0.75

var data: EnemyData
var current_hp: int
var block: int = 0
var burn: int = 0
var weak: int = 0
var vulnerable: int = 0

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


func take_damage(amount: int) -> void:
	if vulnerable > 0:
		amount = int(round(amount * VULNERABLE_MULT))
	var absorbed: int = min(block, amount)
	block -= absorbed
	current_hp = max(0, current_hp - (amount - absorbed))


func effective_damage(amount: int) -> int:
	return int(round(amount * VULNERABLE_MULT)) if vulnerable > 0 else amount


func weakened(amount: int) -> int:
	return int(round(amount * WEAK_MULT)) if weak > 0 else amount


func gain_block(amount: int) -> void:
	block += amount


func apply_burn(amount: int) -> void:
	burn += amount


func apply_weak(turns: int) -> void:
	weak = max(weak, turns)


func apply_vulnerable(turns: int) -> void:
	vulnerable = max(vulnerable, turns)


func tick_burn() -> int:
	if burn <= 0:
		return 0
	var dmg: int = burn
	current_hp = max(0, current_hp - dmg)
	burn -= 1
	return dmg


func decay_status() -> void:
	if weak > 0:
		weak -= 1
	if vulnerable > 0:
		vulnerable -= 1


func status_text() -> String:
	var parts: Array[String] = []
	if burn > 0:
		parts.append("화상%d" % burn)
	if weak > 0:
		parts.append("약화%d" % weak)
	if vulnerable > 0:
		parts.append("취약%d" % vulnerable)
	return "  ".join(parts)


func is_dead() -> bool:
	return current_hp <= 0
