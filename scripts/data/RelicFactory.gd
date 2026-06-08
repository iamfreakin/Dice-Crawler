class_name RelicFactory
extends RefCounted
## 유물 정의 코드 팩토리. 추후 res://resources/relics/*.tres 로 이관한다.

static func _make(id: StringName, name: String, desc: String, effect: RelicData.Effect, value: int) -> RelicData:
	var r := RelicData.new()
	r.id = id
	r.display_name = name
	r.description = desc
	r.effect = effect
	r.value = value
	return r

## 전체 유물 풀.
static func all() -> Array[RelicData]:
	return [
		_make(&"reroll_charm", "🔁 리롤의 부적", "전투 시작 시 리롤 토큰 +1",
			RelicData.Effect.EXTRA_REROLL, 1),
		_make(&"steel_scale", "🛡️ 강철 비늘", "내 턴 시작 시 방어 +3",
			RelicData.Effect.BLOCK_PER_TURN, 3),
		_make(&"ember_core", "🔥 불씨 정수", "화상 부여량 +2",
			RelicData.Effect.BURN_BOOST, 2),
		_make(&"life_rune", "❤️ 생명의 룬", "최대 HP +12",
			RelicData.Effect.MAX_HP_UP, 12),
	]
