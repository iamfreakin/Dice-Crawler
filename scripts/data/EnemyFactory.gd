class_name EnemyFactory
extends RefCounted
## 적 정의(EnemyData) 코드 팩토리. 추후 res://resources/enemies/*.tres 로 이관한다.

static func _intent(kind: IntentData.IntentKind, value: int) -> IntentData:
	var it := IntentData.new()
	it.kind = kind
	it.value = value
	return it

## 고블린 — 기본 일반 적. 돌격↔강화 패턴 반복.
static func goblin() -> EnemyData:
	var e := EnemyData.new()
	e.id = &"goblin"
	e.display_name = "고블린"
	e.tier = EnemyData.Tier.NORMAL
	e.max_hp = 18
	var pattern: Array[IntentData] = []
	pattern.append(_intent(IntentData.IntentKind.CHARGE, 6))
	pattern.append(_intent(IntentData.IntentKind.REINFORCE, 4))
	pattern.append(_intent(IntentData.IntentKind.SNIPE, 8))
	e.intent_pattern = pattern
	return e

## 오크 정예 — 엘리트. 더 단단하고 강한 공격.
static func orc_elite() -> EnemyData:
	var e := EnemyData.new()
	e.id = &"orc_elite"
	e.display_name = "오크 정예"
	e.tier = EnemyData.Tier.ELITE
	e.max_hp = 34
	var pattern: Array[IntentData] = []
	pattern.append(_intent(IntentData.IntentKind.CHARGE, 9))
	pattern.append(_intent(IntentData.IntentKind.REINFORCE, 7))
	pattern.append(_intent(IntentData.IntentKind.EXPLODE, 12))
	e.intent_pattern = pattern
	return e

## 드래곤 — 보스.
static func dragon_boss() -> EnemyData:
	var e := EnemyData.new()
	e.id = &"dragon_boss"
	e.display_name = "고룡 드래곤"
	e.tier = EnemyData.Tier.BOSS
	e.max_hp = 60
	var pattern: Array[IntentData] = []
	pattern.append(_intent(IntentData.IntentKind.SNIPE, 10))
	pattern.append(_intent(IntentData.IntentKind.EXPLODE, 16))
	pattern.append(_intent(IntentData.IntentKind.REINFORCE, 10))
	pattern.append(_intent(IntentData.IntentKind.CHARGE, 13))
	e.intent_pattern = pattern
	return e
