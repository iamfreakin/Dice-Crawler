class_name RollEntry
extends RefCounted
## 굴림 한 건 = 이벤트 로그의 항목.
## 난수(rng_token)와 분포(그 시점 가용 면)를 분리해 저장한다. 토큰을 굳히고 면은 재선택 가능.
## (design.md "롤 컨텍스트" 규약 참조. 분포 변경/값 변형 효과는 Phase 3에서 이 위에 얹는다.)

var index: int          ## 핸드 인덱스
var die: DiceData
var rng_token: float    ## 이 굴림에 쓴 고정 난수 — 정규화 [0,1)
var base_face: FaceData ## 분포 적용 후 토큰으로 선택된 면 (현재는 = 결과)

func _init(p_index: int, p_die: DiceData, p_token: float) -> void:
	index = p_index
	die = p_die
	rng_token = p_token
	base_face = _select()

## 리롤: 토큰만 새로 발급하고 면을 다시 고른다.
func reissue(token: float) -> void:
	rng_token = token
	base_face = _select()

## rng_token(정규화)으로 가용 면에서 선택. 면 개수에 독립적.
## TODO(Phase 3): 분포 변경 효과(봉인/오염/EXPAND)를 적용한 면 목록을 받도록 확장.
func _select() -> FaceData:
	var faces := die.faces
	if faces.is_empty():
		return null
	var i: int = int(floor(rng_token * float(faces.size())))
	i = clampi(i, 0, faces.size() - 1)
	return faces[i]
