class_name EnemyData
extends Resource
## 적 1종의 정의. 콘텐츠는 res://resources/enemies/*.tres 로 추가한다.

## 적 등급. 의도 공개 범위와 보상 보장에 영향.
enum Tier { NORMAL, ELITE, BOSS }

@export var id: StringName
@export var display_name: String = ""
@export var tier: Tier = Tier.NORMAL
@export var max_hp: int = 10
@export var sprite: Texture2D

## 이 적의 의도 패턴(순환). 매 턴 다음 의도를 가져온다.
@export var intent_pattern: Array[IntentData] = []

## 등급별 의도 공개 규칙에 따라 표시 여부 결정.
## 일반=전부 공개, 엘리트=hidden 플래그 존중, 보스=페이즈 단위만.
func reveals_full_intent() -> bool:
	return tier == Tier.NORMAL
