class_name DiceData
extends Resource
## 주사위 1개의 정의. 면(face) 배열로 구성되며 보상으로 면을 조각해 빌드업한다.
## 콘텐츠는 이 클래스를 상속하지 말고 res://resources/dice/*.tres 로 추가한다.

## 주사위 속성(타입). 시너지 판정의 기준이 된다.
enum DiceType { ATTACK, DEFENSE, SKILL }

## 면의 대표 태그. UI 아이콘과 기존 시너지 식별에 사용한다.
## 실제 행동은 FaceData.effects의 FaceEffectData가 정의한다.
enum FaceKind {
	NUMBER,   # 숫자 면 (데미지/실드 등 수치)
	FIRE,     # 🔥
	ICE,      # ❄️
	LIGHTNING,# ⚡
	CURSE,    # 💀 저주 (굴리면 리롤 토큰 보너스)
	REROLL,   # 🔄
}

@export var id: StringName              ## 고유 식별자 (예: &"basic_attack")
@export var display_name: String = ""   ## UI 표시 이름
@export var dice_type: DiceType = DiceType.ATTACK
@export var energy_cost: int = 1        ## 굴리는 데 드는 에너지
@export var icon: Texture2D

## 면 목록. 6면이 기본, 확장 보상으로 8면까지 늘어날 수 있다.
## 각 면은 FaceData 리소스 1개.
@export var faces: Array[FaceData] = []

func face_count() -> int:
	return faces.size()

## 무작위 면 하나를 굴린다. 굴림 결과 면을 반환.
func roll() -> FaceData:
	if faces.is_empty():
		return null
	return faces[randi() % faces.size()]
