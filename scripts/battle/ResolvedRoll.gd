class_name ResolvedRoll
extends RefCounted
## RollEntry 원본 이벤트를 replay해 만든 파생 결과. FaceData 원본은 절대 수정하지 않는다.

var entry_id: int
var hand_index: int
var die: DiceData
var face: FaceData
var value: int
var tags: Array[DiceData.FaceKind] = []

## 복제/반향에서 사용할 생성 출처 정보. 현재 일반 굴림은 generated=false.
var generated: bool = false
var copy_depth: int = 0
var source_entry_id: int = -1
var modified_by_entry_ids: Array[int] = []

## 보존되어 지난 턴에서 이번 턴으로 넘어온 결과(TURN_START 복원). 핸드 슬롯 없음.
var preserved: bool = false


func _init(
	p_entry_id: int,
	p_hand_index: int,
	p_die: DiceData,
	p_face: FaceData
) -> void:
	entry_id = p_entry_id
	hand_index = p_hand_index
	die = p_die
	face = p_face
	source_entry_id = p_entry_id
	if face != null:
		value = face.value
		tags = face.tags.duplicate()
		if tags.is_empty():
			tags.append(face.kind)


func has_tag(tag: DiceData.FaceKind) -> bool:
	return tags.has(tag)


func modify_value(amount: int, source_id: int) -> void:
	value += amount
	modified_by_entry_ids.append(source_id)


## 변환: 시너지 판정 태그를 목표 속성으로 교체한다. 값/효과는 그대로 둔다.
func convert_to(tag: DiceData.FaceKind, source_id: int) -> void:
	tags.clear()
	tags.append(tag)
	modified_by_entry_ids.append(source_id)


## 복제: source의 (보정 후) 값·태그·면을 그대로 가진 파생 굴림을 만든다.
## generated=true 로 표시하며, 핸드 슬롯은 source와 공유한다(별도 주사위 칩 없음).
static func new_copy(source: ResolvedRoll, by_entry_id: int) -> ResolvedRoll:
	var copy := ResolvedRoll.new(source.entry_id, source.hand_index, source.die, source.face)
	copy.value = source.value
	copy.tags = source.tags.duplicate()
	copy.generated = true
	copy.copy_depth = source.copy_depth + 1
	copy.source_entry_id = source.entry_id
	copy.modified_by_entry_ids.append(by_entry_id)
	return copy


## 보존: 현재 (보정·변환 반영된) 결과를 다음 턴으로 넘길 고정 스냅샷으로 만든다.
## 핸드 슬롯은 없음(hand_index = -1). 매 replay마다 다시 복제해 원본 스냅샷을 보호한다.
func snapshot() -> ResolvedRoll:
	var snap := ResolvedRoll.new(entry_id, -1, die, face)
	snap.value = value
	snap.tags = tags.duplicate()
	snap.preserved = true
	snap.source_entry_id = source_entry_id
	return snap
