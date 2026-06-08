class_name MapNode
extends RefCounted
## 맵의 한 칸. 다음 행으로 이동 가능한 노드 id를 가진다.

enum Type { BATTLE, ELITE, REST, SHOP, BOSS }

var id: int
var row: int
var column: int
var type: Type = Type.BATTLE
var next: Array[int] = []


static func type_label(t: Type) -> String:
	match t:
		Type.BATTLE:
			return "전투"
		Type.ELITE:
			return "정예"
		Type.REST:
			return "휴식"
		Type.SHOP:
			return "상점"
		Type.BOSS:
			return "보스"
	return "?"
