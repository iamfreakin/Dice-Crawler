class_name FaceData
extends Resource
## 주사위 한 면(face)의 정의. 면 교체/강화 보상이 이 값을 바꾼다.

## 기존 UI 아이콘과 대표 분류용 태그. 행동 분기에는 사용하지 않는다.
@export var kind: DiceData.FaceKind = DiceData.FaceKind.NUMBER
## 시너지/조건 판정용 태그. kind는 UI 대표 태그로 유지한다.
@export var tags: Array[DiceData.FaceKind] = []
## 데이터 기반 효과 목록. 실제 실행은 EffectResolver가 담당한다.
@export var effects: Array[FaceEffectData] = []
## 수치 값. NUMBER 면은 데미지/실드량, 효과 면은 효과 강도로 사용.
@export var value: int = 1
## UI에 표시할 라벨/이모지 (예: "5", "🔥3").
@export var label: String = ""
@export var icon: Texture2D

func is_special() -> bool:
	return kind != DiceData.FaceKind.NUMBER


func has_tag(tag: DiceData.FaceKind) -> bool:
	return tags.has(tag) if not tags.is_empty() else kind == tag
