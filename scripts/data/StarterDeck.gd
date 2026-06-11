class_name StarterDeck
extends RefCounted
## 시작 덱 구성. 주사위 정의는 res://resources/dice/*.tres 에서 로드한다.
## 풀에 넣는 주사위는 deep duplicate 해서 인스턴스를 독립시킨다
## (보상으로 한 주사위 면을 강화해도 다른 주사위에 영향 없도록).

const ATTACK_PATH := "res://resources/dice/basic_attack.tres"
const DEFENSE_PATH := "res://resources/dice/basic_defense.tres"
const SKILL_PATH := "res://resources/dice/basic_skill.tres"
const MANIP_PATH := "res://resources/dice/manipulation_die.tres"

static func _load_die(path: String) -> DiceData:
	var die := Content.load_one(path) as DiceData
	if die == null:
		return null
	return die.duplicate(true)  # 면(FaceData)까지 깊은 복제

static func attack_die() -> DiceData:
	return _load_die(ATTACK_PATH)

static func defense_die() -> DiceData:
	return _load_die(DEFENSE_PATH)

static func skill_die() -> DiceData:
	return _load_die(SKILL_PATH)

static func manip_die() -> DiceData:
	return _load_die(MANIP_PATH)

## 시작 덱: 기본 주사위 각 2개씩 (공격2 / 방어2 / 스킬2) + 조작 주사위 1개, 총 7개.
static func build() -> Array[DiceData]:
	var deck: Array[DiceData] = []
	for i in 2:
		deck.append(attack_die())
		deck.append(defense_die())
		deck.append(skill_die())
	deck.append(manip_die())
	return deck
