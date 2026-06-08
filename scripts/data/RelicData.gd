class_name RelicData
extends Resource
## 유물 1종의 정의. 런 내내 지속되는 패시브 효과. 콘텐츠는 res://resources/relics/*.tres 로 추가 가능.

## 효과 종류. 적용 시점은 GameManager/BattleManager 의 훅에서 처리한다.
enum Effect {
	EXTRA_REROLL,    ## 전투 시작 시 리롤 토큰 +value
	BLOCK_PER_TURN,  ## 내 턴 시작 시 방어 +value
	BURN_BOOST,      ## 화상 부여량 +value
	MAX_HP_UP,       ## 최대 HP +value (획득 즉시)
}

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var effect: Effect = Effect.EXTRA_REROLL
@export var value: int = 1
