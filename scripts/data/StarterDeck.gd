class_name StarterDeck
extends RefCounted
## 시작 덱(기본 주사위 3종) 구성 팩토리.
## 지금은 코드로 생성한다. 콘텐츠가 늘어나면 res://resources/dice/*.tres 로 이관한다.

static func build() -> Array[DiceData]:
	var deck: Array[DiceData] = []
	deck.append(attack_die())
	deck.append(defense_die())
	deck.append(skill_die())
	return deck

# --- 면 헬퍼 ------------------------------------------------------------
static func _number_face(v: int) -> FaceData:
	var f := FaceData.new()
	f.kind = DiceData.FaceKind.NUMBER
	f.value = v
	f.label = str(v)
	return f

static func _special_face(kind: DiceData.FaceKind, v: int, label: String) -> FaceData:
	var f := FaceData.new()
	f.kind = kind
	f.value = v
	f.label = label
	return f

static func _number_faces(values: Array[int]) -> Array[FaceData]:
	var faces: Array[FaceData] = []
	for v in values:
		faces.append(_number_face(v))
	return faces

# --- 기본 주사위 3종 (보상 등에서 재사용하도록 public) --------------------
## ⚔️ 공격 — 1~6 균등 (데미지)
static func attack_die() -> DiceData:
	var d := DiceData.new()
	d.id = &"basic_attack"
	d.display_name = "공격"
	d.dice_type = DiceData.DiceType.ATTACK
	d.faces = _number_faces([1, 2, 3, 4, 5, 6])
	return d

## 🛡️ 방어 — 1~6 균등 (실드/체력)
static func defense_die() -> DiceData:
	var d := DiceData.new()
	d.id = &"basic_defense"
	d.display_name = "방어"
	d.dice_type = DiceData.DiceType.DEFENSE
	d.faces = _number_faces([1, 2, 3, 4, 5, 6])
	return d

## ✨ 스킬 — 🔥 ❄️ ⚡ 💀 🔄 + 숫자
static func skill_die() -> DiceData:
	var d := DiceData.new()
	d.id = &"basic_skill"
	d.display_name = "스킬"
	d.dice_type = DiceData.DiceType.SKILL
	var faces: Array[FaceData] = []
	faces.append(_special_face(DiceData.FaceKind.FIRE, 3, "🔥3"))
	faces.append(_special_face(DiceData.FaceKind.ICE, 3, "❄️3"))
	faces.append(_special_face(DiceData.FaceKind.LIGHTNING, 3, "⚡3"))
	faces.append(_special_face(DiceData.FaceKind.CURSE, 0, "💀"))
	faces.append(_special_face(DiceData.FaceKind.REROLL, 0, "🔄"))
	faces.append(_number_face(2))
	d.faces = faces
	return d
