class_name RollEntry
extends RefCounted
## 굴림 한 건 = 이벤트 로그의 항목.
## 원본 이벤트만 저장한다. 면 선택과 값 변형은 replay가 ResolvedRoll로 매번 재계산한다.

var entry_id: int = -1 ## RollContext 안에서 유지되는 고유 순서 ID
var index: int          ## 핸드 인덱스
var die: DiceData
var rng_token: float    ## 이 굴림에 쓴 고정 난수 — 정규화 [0,1)

func _init(p_index: int, p_die: DiceData, p_token: float) -> void:
	index = p_index
	die = p_die
	rng_token = p_token

## 리롤은 원본 이벤트의 토큰만 교체한다. 이후 결과는 replay가 다시 만든다.
func reissue(token: float) -> void:
	rng_token = token

## rng_token(정규화)으로 가용 면에서 선택. 면 개수에 독립적.
## TODO(Phase 3): 분포 변경 효과(봉인/오염/EXPAND)를 적용한 면 목록을 받도록 확장.
func select_face() -> FaceData:
	var faces := die.faces
	if faces.is_empty():
		return null
	var i: int = int(floor(rng_token * float(faces.size())))
	i = clampi(i, 0, faces.size() - 1)
	return faces[i]
