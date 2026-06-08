extends Control
## 노드 맵 화면. 행 단위로 노드를 표시하고, 이동 가능한 노드만 선택할 수 있다.
## 전투 노드 → Battle 씬으로 전환. 휴식/상점 → 효과 적용 후 맵 갱신.

const REST_HEAL: int = 12
const SHOP_HEAL: int = 6  # 상점 임시 처리 (정식 상점은 추후)

var _rows_box: VBoxContainer
var _status_label: Label

func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_top = 24
	root.offset_right = -40
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "🗺️ 노드 맵 — 다음 목적지를 선택하세요"
	title.add_theme_font_size_override("font_size", 22)
	root.add_child(title)

	_status_label = Label.new()
	root.add_child(_status_label)

	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows_box)

	_render()

func _render() -> void:
	for child in _rows_box.get_children():
		child.queue_free()

	var relic_names: Array[String] = []
	for r in GameManager.relics:
		relic_names.append(r.display_name)
	var relic_part := ("   |   유물: " + ", ".join(relic_names)) if not relic_names.is_empty() else ""
	_status_label.text = "HP: %d/%d   |   층: %d%s" % [
		GameManager.current_hp, GameManager.max_hp, GameManager.current_floor, relic_part
	]

	var available := GameManager.get_available_nodes()
	var available_ids: Array[int] = []
	for n in available:
		available_ids.append(n.id)

	# 보스 행이 위로 오도록 역순 표시 (위로 올라가는 진행감)
	for r in range(GameManager.map.size() - 1, -1, -1):
		var row: Array = GameManager.map[r]
		var hbox := HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 12)
		_rows_box.add_child(hbox)

		for node in row:
			var btn := Button.new()
			var is_available: bool = available_ids.has(node.id)
			var is_current: bool = GameManager.current_node != null and GameManager.current_node.id == node.id
			var mark := ""
			if is_current:
				mark = " ◀ 현재"
			btn.text = MapNode.type_label(node.type) + mark
			btn.custom_minimum_size = Vector2(120, 40)
			btn.disabled = not is_available
			if is_available:
				btn.pressed.connect(_on_node_selected.bind(node))
			hbox.add_child(btn)

func _on_node_selected(node: MapNode) -> void:
	GameManager.move_to(node)
	match node.type:
		MapNode.Type.BATTLE, MapNode.Type.ELITE, MapNode.Type.BOSS:
			SceneRouter.goto(SceneRouter.BATTLE)
		MapNode.Type.REST:
			GameManager.heal(REST_HEAL)
			_render()
		MapNode.Type.SHOP:
			GameManager.heal(SHOP_HEAL)
			_render()
