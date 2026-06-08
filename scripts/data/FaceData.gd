class_name FaceData
extends Resource
## 주사위 한 면(face)의 정의. 면 교체/강화 보상이 이 값을 바꾼다.

@export var kind: DiceData.FaceKind = DiceData.FaceKind.NUMBER
## 수치 값. NUMBER 면은 데미지/실드량, 효과 면은 효과 강도로 사용.
@export var value: int = 1
## UI에 표시할 라벨/이모지 (예: "5", "🔥3").
@export var label: String = ""
@export var icon: Texture2D

func is_special() -> bool:
	return kind != DiceData.FaceKind.NUMBER
