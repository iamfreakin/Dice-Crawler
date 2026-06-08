class_name IntentData
extends Resource
## 적의 한 턴 의도(intent). 전투 진입 전/턴 시작 시 아이콘으로 공개된다.
## 공개 범위는 적 등급에 따라 다르다 (일반=전부, 엘리트=일부, 보스=페이즈만).

enum IntentKind {
	CHARGE,     # ⚔️ 돌격 — 근접 러시
	SNIPE,      # 🎯 저격 — 원거리 고데미지
	EXPLODE,    # 💣 폭발 — 광역 공격
	REINFORCE,  # 🛡️ 강화 — 방어력 상승
	SUMMON,     # 📡 증원 — 추가 적 소환
}

@export var kind: IntentKind = IntentKind.CHARGE
@export var value: int = 0          ## 데미지량/방어량/소환 수 등 의도별 수치
@export var icon: Texture2D
@export var hidden: bool = false    ## true면 미공개(엘리트/보스 비공개 의도)
