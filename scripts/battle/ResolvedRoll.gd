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
