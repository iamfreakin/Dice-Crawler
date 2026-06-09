class_name MapCanvas
extends Control
## 노드 맵을 좌표 기반으로 그린다: 노드(프레임+아이콘+링) 배치 + 연결선(엣지) 드로잉.
## 노드 크기는 에셋(ring/frame) 크기에 자동으로 맞춰진다. 위치는 정수 스냅으로 또렷하게.

signal node_selected(node: MapNode)

const ASSET := "res://assets/sprites/map/"
const COL_FACTOR := 2.9   # 노드 한 변 대비 가로 간격
const ROW_FACTOR := 1.95  # 노드 한 변 대비 세로 간격

var _frame: Texture2D = load(ASSET + "node_frame.png")
var _ring: Texture2D = load(ASSET + "node_ring.png")
var _dot: Texture2D = load(ASSET + "path_dot.png")

var _box: float = 48.0     # 노드 위젯 한 변 (ring 크기 기준)
var _col_sp: float = 140.0
var _row_sp: float = 96.0
var _margin: float = 56.0

var _map: Array = []
var _available: Array[int] = []
var _current_id: int = -1
var _centers: Dictionary = {}        # node id -> 중심 좌표
var _widgets: Array[Dictionary] = []
var _did_appear: bool = false

func setup(map: Array, available_ids: Array[int], current_id: int) -> void:
	_map = map
	_available = available_ids
	_current_id = current_id
	_did_appear = false
	# 노드 크기를 에셋에서 결정 (ring > frame > 기본)
	if _ring != null:
		_box = _ring.get_size().x
	elif _frame != null:
		_box = _frame.get_size().x + 8.0
	else:
		_box = 48.0
	_col_sp = _box * COL_FACTOR
	_row_sp = _box * ROW_FACTOR
	_margin = _box
	_build()

func _build() -> void:
	for c in get_children():
		c.queue_free()
	_widgets.clear()
	_centers.clear()

	custom_minimum_size = Vector2(0, _map.size() * _row_sp + _margin * 2.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for row in _map:
		for node in row:
			var w := _make_node(node)
			add_child(w)
			_widgets.append({"node": node, "ctrl": w})

	if not resized.is_connected(_relayout):
		resized.connect(_relayout)
	call_deferred("_relayout")

func _make_node(node: MapNode) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(_box, _box)
	box.size = Vector2(_box, _box)
	box.pivot_offset = Vector2(_box, _box) * 0.5

	var is_current: bool = node.id == _current_id
	var is_available: bool = _available.has(node.id)

	# 현재 노드 강조 링 (박스 전체)
	if is_current and _ring != null:
		box.add_child(_centered_tex(_ring))
	# 프레임 (중앙)
	if _frame != null:
		box.add_child(_centered_tex(_frame))
	# 타입 아이콘 (중앙)
	var icon := _icon_for(node.type)
	if icon != null:
		box.add_child(_centered_tex(icon))

	if not (is_available or is_current):
		box.modulate = Color(0.5, 0.5, 0.56)

	if is_available:
		box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		box.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				node_selected.emit(node))
		box.mouse_entered.connect(func(): box.scale = Vector2(1.18, 1.18))
		box.mouse_exited.connect(func(): box.scale = Vector2.ONE)
	return box

## 박스 중앙에 텍스처를 정수 좌표로 배치.
func _centered_tex(t: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = t
	tr.position = ((Vector2(_box, _box) - t.get_size()) * 0.5).round()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _icon_for(type: int) -> Texture2D:
	match type:
		MapNode.Type.BATTLE: return load(ASSET + "node_battle.png")
		MapNode.Type.ELITE: return load(ASSET + "node_elite.png")
		MapNode.Type.REST: return load(ASSET + "node_rest.png")
		MapNode.Type.SHOP: return load(ASSET + "node_shop.png")
		MapNode.Type.BOSS: return load(ASSET + "node_boss.png")
	return null

# --- 배치 / 그리기 ------------------------------------------------------
func _relayout() -> void:
	var w := size.x
	if w <= 1.0:
		w = 700.0
	var total_rows := _map.size()
	for item in _widgets:
		var node: MapNode = item["node"]
		var count := (_map[node.row] as Array).size()
		var cx := roundf(w * 0.5 + (float(node.column) - float(count - 1) / 2.0) * _col_sp)
		var cy := roundf(_margin + float(total_rows - 1 - node.row) * _row_sp)
		_centers[node.id] = Vector2(cx, cy)
		(item["ctrl"] as Control).position = (Vector2(cx, cy) - Vector2(_box, _box) * 0.5).round()
	queue_redraw()
	if not _did_appear:
		_did_appear = true
		_animate_in()

func _animate_in() -> void:
	for item in _widgets:
		var ctrl: Control = item["ctrl"]
		var node: MapNode = item["node"]
		ctrl.scale = Vector2(0.4, 0.4)
		var tw := create_tween()
		tw.tween_interval(0.03 * float(_map.size() - 1 - node.row))
		tw.tween_property(ctrl, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	for r in range(_map.size() - 1):
		for node in _map[r]:
			if not _centers.has(node.id):
				continue
			for nid in node.next:
				if _centers.has(nid):
					_draw_path(_centers[node.id], _centers[nid], node.id == _current_id)

func _draw_path(a: Vector2, b: Vector2, highlight: bool) -> void:
	if _dot != null:
		var dist := a.distance_to(b)
		var spacing := _dot.get_size().x * 1.4
		var n := maxi(1, int(dist / spacing))
		var half := _dot.get_size() * 0.5
		var tint := Color(0.72, 0.66, 1.0, 1.0) if highlight else Color(1, 1, 1, 0.32)
		for i in range(n + 1):
			var p := a.lerp(b, float(i) / float(n))
			draw_texture(_dot, (p - half).round(), tint)
	else:
		var col := Color(0.72, 0.66, 1.0, 0.9) if highlight else Color(0.6, 0.6, 0.7, 0.3)
		draw_line(a, b, col, 2.0)
