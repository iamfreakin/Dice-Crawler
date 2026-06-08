class_name MapNode
extends RefCounted
## 노드 맵의 한 칸. 절차적 생성되며 다음 행의 노드들로 연결된다.

enum Type { BATTLE, ELITE, REST, SHOP, BOSS }

var id: int
var row: int
var column: int
var type: Type = Type.BATTLE
var next: Array[int] = []   ## 다음 행에서 이동 가능한 노드 id들

static func type_label(t: Type) -> String:
	match t:
		Type.BATTLE: return "⚔️ 전투"
		Type.ELITE: return "💀 정예"
		Type.REST: return "🔥 휴식"
		Type.SHOP: return "🛒 상점"
		Type.BOSS: return "👑 보스"
	return "?"
