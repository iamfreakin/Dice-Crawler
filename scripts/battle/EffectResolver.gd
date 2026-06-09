class_name EffectResolver
extends RefCounted
## FaceEffectData를 순수 정산값으로 변환한다. 게임 상태에는 직접 접근하지 않는다.


static func resolve_face(
	die: DiceData,
	face: FaceData,
	timing: FaceEffectData.Timing,
	outcome: BattleOutcome
) -> void:
	if die == null or face == null:
		return
	for effect in face.effects:
		if effect == null or effect.timing != timing:
			continue
		_apply(effect, face, outcome)


static func _apply(effect: FaceEffectData, face: FaceData, outcome: BattleOutcome) -> void:
	var amount := effect.amount(face)
	match effect.effect_type:
		FaceEffectData.EffectType.DAMAGE:
			outcome.damage += amount
		FaceEffectData.EffectType.BLOCK:
			outcome.block += amount
		FaceEffectData.EffectType.APPLY_BURN:
			outcome.burn += amount
		FaceEffectData.EffectType.GAIN_REROLL:
			outcome.token_gain += amount
	if effect.log_text != "":
		outcome.logs.append(effect.log_text)
