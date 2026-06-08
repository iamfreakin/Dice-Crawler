class_name MapGenerator
extends RefCounted
## StS 스타일 분기 노드 맵 생성기.
## 반환: Array[Array[MapNode]] — 행(row) 단위, 마지막 행은 보스 단일 노드.
## 모든 노드는 다음 행으로 가는 경로가 최소 1개 보장된다(도달 가능 DAG).

const NORMAL_ROWS: int = 5  ## 일반 행 수 (이후 보스 행 1개 추가)

static func generate() -> Array:
	var rows: Array = []
	var next_id: int = 0

	for r in NORMAL_ROWS:
		var count: int = randi_range(2, 3)
		var row_nodes: Array[MapNode] = []
		for c in count:
			var n := MapNode.new()
			n.id = next_id
			next_id += 1
			n.row = r
			n.column = c
			n.type = _roll_type(r)
			row_nodes.append(n)
		rows.append(row_nodes)

	# 보스 행
	var boss := MapNode.new()
	boss.id = next_id
	boss.row = NORMAL_ROWS
	boss.column = 0
	boss.type = MapNode.Type.BOSS
	rows.append([boss])

	_connect(rows)
	return rows

static func _roll_type(row: int) -> MapNode.Type:
	if row == 0:
		return MapNode.Type.BATTLE          # 첫 행은 항상 전투
	if row == NORMAL_ROWS - 1:
		return MapNode.Type.REST            # 보스 직전은 휴식
	var roll := randf()
	if roll < 0.60:
		return MapNode.Type.BATTLE
	elif roll < 0.78:
		return MapNode.Type.ELITE
	elif roll < 0.90:
		return MapNode.Type.REST
	else:
		return MapNode.Type.SHOP

# --- 연결 ---------------------------------------------------------------
static func _connect(rows: Array) -> void:
	for i in range(rows.size() - 1):
		var cur: Array = rows[i]
		var nxt: Array = rows[i + 1]
		for node in cur:
			for target in _pick_targets(node, cur.size(), nxt):
				if not node.next.has(target.id):
					node.next.append(target.id)
		# 다음 행의 모든 노드가 들어오는 경로를 갖도록 보강
		for tnode in nxt:
			if not _has_incoming(cur, tnode.id):
				var src: MapNode = _nearest(tnode, nxt.size(), cur)
				if not src.next.has(tnode.id):
					src.next.append(tnode.id)

static func _pick_targets(node: MapNode, cur_count: int, nxt: Array) -> Array:
	var ratio: float = float(node.column) / float(max(1, cur_count - 1))
	var idx: int = int(round(ratio * float(nxt.size() - 1)))
	var result: Array = [nxt[idx]]
	# 다음 행에 노드가 2개 이상이면 인접 노드로 한 갈래 더 연결 → 매 노드에서 선택지 보장
	if nxt.size() >= 2:
		var left: int = idx - 1
		var right: int = idx + 1
		var nb: int = -1
		if left >= 0 and right < nxt.size():
			nb = left if randf() < 0.5 else right
		elif left >= 0:
			nb = left
		elif right < nxt.size():
			nb = right
		if nb != -1:
			result.append(nxt[nb])
	return result

static func _nearest(tnode: MapNode, nxt_count: int, cur: Array) -> MapNode:
	var ratio: float = float(tnode.column) / float(max(1, nxt_count - 1))
	var idx: int = int(round(ratio * float(cur.size() - 1)))
	return cur[idx]

static func _has_incoming(cur: Array, target_id: int) -> bool:
	for node in cur:
		if node.next.has(target_id):
			return true
	return false
