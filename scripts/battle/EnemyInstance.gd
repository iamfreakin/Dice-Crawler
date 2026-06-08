class_name EnemyInstance
extends RefCounted
## 전투 중 적 1마리의 런타임 상태. EnemyData(정적 정의)를 감싸 HP/방어/의도/상태이상을 추적한다.

var data: EnemyData
var current_hp: int
var block: int = 0
var _intent_index: int = 0

## 상태이상
var burn: int = 0        ## 🔥 화상 — 적 턴마다 burn 만큼 피해 후 1 감소
var weak: int = 0        ## 약화 — 남은 턴 동안 적 공격력 감소
var vulnerable: int = 0  ## 취약 — 남은 턴 동안 받는 피해 증가

const VULNERABLE_MULT: float = 1.5
const WEAK_MULT: float = 0.75

func _init(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_hp = enemy_data.max_hp

func current_intent() -> IntentData:
	if data.intent_pattern.is_empty():
		return null
	return data.intent_pattern[_intent_index % data.intent_pattern.size()]

func advance_intent() -> void:
	_intent_index += 1

## 데미지를 받는다. 취약 시 증가, 방어(block)로 먼저 흡수.
func take_damage(amount: int) -> void:
	if vulnerable > 0:
		amount = int(round(amount * VULNERABLE_MULT))
	var absorbed: int = min(block, amount)
	block -= absorbed
	current_hp = max(0, current_hp - (amount - absorbed))

## 취약을 반영한 실제 피해량(로그 표시용).
func effective_damage(amount: int) -> int:
	return int(round(amount * VULNERABLE_MULT)) if vulnerable > 0 else amount

## 약화를 반영한 적 공격력.
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

## 적 턴 시작 시 화상 피해 처리. 입은 피해를 반환.
func tick_burn() -> int:
	if burn <= 0:
		return 0
	var dmg: int = burn
	current_hp = max(0, current_hp - dmg)
	burn -= 1
	return dmg

## 적 턴 종료 시 상태이상 지속시간 감소.
func decay_status() -> void:
	if weak > 0:
		weak -= 1
	if vulnerable > 0:
		vulnerable -= 1

## UI 표시용 상태 요약 (없으면 빈 문자열).
func status_text() -> String:
	var parts: Array[String] = []
	if burn > 0:
		parts.append("🔥%d" % burn)
	if weak > 0:
		parts.append("약화%d" % weak)
	if vulnerable > 0:
		parts.append("취약%d" % vulnerable)
	return "  ".join(parts)

func is_dead() -> bool:
	return current_hp <= 0
