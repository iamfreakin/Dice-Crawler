class_name FaceEffectData
extends Resource
## 주사위 면 하나에 부착되는 데이터 기반 효과.
## 실행은 EffectResolver가 담당하며 이 리소스는 게임 상태를 직접 변경하지 않는다.

enum Timing {
	COST_CALC,
	BEFORE_ROLL,
	AFTER_ROLL,
	ON_CONFIRM,
	TURN_START,
	TURN_END,
}

enum EffectType {
	DAMAGE,
	BLOCK,
	APPLY_BURN,
	GAIN_REROLL,
	AMPLIFY_PREVIOUS,
	PREHEAT_NEXT,
	TRANSFORM_PREVIOUS,
	DUPLICATE_PREVIOUS,
}

@export var effect_type: EffectType = EffectType.DAMAGE
@export var timing: Timing = Timing.ON_CONFIRM
@export var value: int = 0
## 숫자 면 강화처럼 FaceData.value를 따라가야 하는 효과에 사용한다.
@export var use_face_value: bool = false
## TRANSFORM_PREVIOUS 가 직전 결과를 바꿀 목표 속성 (FIRE/ICE/LIGHTNING).
@export var element: DiceData.FaceKind = DiceData.FaceKind.NUMBER
@export_multiline var log_text: String = ""


func amount(resolved_value: int) -> int:
	return resolved_value if use_face_value else value
