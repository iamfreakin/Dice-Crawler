extends Control
## BattleManager를 구동하고 전투 UI 입력/표시를 처리한다.
## 플레이어 스프라이트/배경/배치는 씬(Battle.tscn)에서, 동적 요소(적/주사위)는 코드로.
## 주사위는 에너지를 써서 클릭으로 굴린다(슬더스식). 효과는 확정 때 정산.

const ENEMY_SCALE := 3.0
const ENEMY_MAX_H := 170.0
const INTENT_ICON := 32.0
const DICE_BOX := 64.0

var _bm: BattleManager
var _ended: bool = false
var _victory: bool = false

var _enemy_box: HBoxContainer
var _dice_box: HBoxContainer
var _player_label: Label
var _hand_label: Label
var _result_label: Label
var _log: RichTextLabel
var _roll_btn: Button
var _reroll_btn: Button
var _confirm_btn: Button
var _continue_btn: Button

var _hand: Array = []  # 이번 턴 뽑은 주사위 (DiceData)


func _ready() -> void:
	theme = UITheme.shared()
	if GameManager.dice_pool.is_empty():
		GameManager.start_new_run()
	_bind_ui()

	_bm = BattleManager.new()
	add_child(_bm)
	_bm.hand_drawn.connect(_on_hand_drawn)
	_bm.dice_rolled.connect(_on_dice_rolled)
	_bm.log_message.connect(_append_log)
	_bm.battle_ended.connect(_on_battle_ended)
	_bm.state_changed.connect(func(_s): _refresh())
	GameManager.hp_changed.connect(func(_c, _m): _refresh())
	GameManager.reroll_tokens_changed.connect(func(_a): _refresh())
	GameManager.gold_changed.connect(func(_a): _refresh())

	_bm.start_battle(_encounter())
	_refresh()


func _encounter() -> Array[EnemyData]:
	var t := MapNode.Type.BATTLE
	if GameManager.current_node != null:
		t = GameManager.current_node.type
	var list: Array[EnemyData] = []
	match t:
		MapNode.Type.ELITE:
			list.append(EnemyFactory.orc_elite())
			list.append(EnemyFactory.goblin())
		MapNode.Type.BOSS:
			list.append(EnemyFactory.dragon_boss())
		_:
			list.append(EnemyFactory.goblin())
			if randf() < 0.5:
				list.append(EnemyFactory.cave_bat())
	return list


func _bind_ui() -> void:
	_enemy_box = $Root/Arena/EnemyBox as HBoxContainer
	_log = $Root/Log as RichTextLabel
	_player_label = $Root/PlayerLabel as Label
	_hand_label = $Root/HandLabel as Label
	_result_label = $Root/ResultLabel as Label
	_roll_btn = $Root/Buttons/RollButton as Button
	_reroll_btn = $Root/Buttons/RerollButton as Button
	_confirm_btn = $Root/Buttons/ConfirmButton as Button
	_continue_btn = $Root/Buttons/ContinueButton as Button
	# 굴림/리롤은 주사위 클릭으로 처리 → 두 버튼 숨김
	_roll_btn.visible = false
	_reroll_btn.visible = false
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)

	_dice_box = HBoxContainer.new()
	_dice_box.add_theme_constant_override("separation", 12)
	var root := $Root as VBoxContainer
	root.add_child(_dice_box)
	root.move_child(_dice_box, _hand_label.get_index() + 1)
	_result_label.text = ""


func _on_confirm_pressed() -> void:
	if _ended:
		return
	_bm.confirm_turn()


func _on_hand_drawn(hand: Array) -> void:
	_hand = hand.duplicate()
	_render_hand()
	_refresh()


func _on_dice_rolled(_results: Array) -> void:
	_render_hand()
	_refresh()


func _on_battle_ended(victory: bool) -> void:
	_ended = true
	_victory = victory
	_result_label.text = "승리!" if victory else "패배..."
	_roll_btn.visible = false
	_reroll_btn.visible = false
	_confirm_btn.visible = false
	_continue_btn.visible = true
	_refresh()


func _on_continue_pressed() -> void:
	if _victory:
		if GameManager.is_at_boss():
			_append_log("[b]보스를 처치했습니다.[/b]")
			SceneRouter.goto(SceneRouter.MAIN_MENU)
		else:
			SceneRouter.goto(SceneRouter.REWARD)
	else:
		SceneRouter.goto(SceneRouter.MAIN_MENU)


func _append_log(text: String) -> void:
	_log.append_text(text + "\n")


# --- 주사위 (에너지 클릭 굴림) ------------------------------------------
func _render_hand() -> void:
	for c in _dice_box.get_children():
		c.queue_free()
	_hand_label.text = "클릭: 굴림(에너지)  ·  굴린 주사위 클릭: 리롤(토큰)  ·  에너지 %d/%d  토큰 %d" % [
		_bm.energy if _bm else 0, BattleManager.MAX_ENERGY, GameManager.reroll_tokens
	]
	for i in _hand.size():
		_dice_box.add_child(_dice_chip(i))


## 안 굴린 주사위 클릭 = 굴림(에너지). 굴린 주사위 클릭 = 그것만 리롤(토큰).
func _dice_chip(index: int) -> Control:
	var die: DiceData = _hand[index]
	var box := _dice_base(die)

	if _bm.is_rolled(index):
		_overlay_face(box, _bm.face_for(index))
		box.add_child(_accent_bar())
		if not _ended and GameManager.reroll_tokens > 0:
			box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			box.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_bm.reroll_index(index))
	else:
		box.add_child(_cost_badge(die.energy_cost))
		if _bm.can_roll(index):
			box.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			box.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_bm.roll_index(index))
		else:
			box.modulate = Color(0.45, 0.45, 0.5)  # 에너지 부족
	return box


func _dice_base(die: DiceData) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(DICE_BOX, DICE_BOX)
	box.size = Vector2(DICE_BOX, DICE_BOX)
	var body := load("res://assets/sprites/dice/%s.png" % die.id) as Texture2D
	if body != null:
		box.add_child(_centered(body))
	return box


func _accent_bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color("efc127")
	bar.size = Vector2(DICE_BOX, 5)
	bar.position = Vector2(0, DICE_BOX - 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _overlay_face(box: Control, face: FaceData) -> void:
	if face == null:
		return
	if face.kind == DiceData.FaceKind.NUMBER:
		var lbl := Label.new()
		lbl.text = str(face.value)
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.size = Vector2(DICE_BOX, DICE_BOX)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lbl)
	else:
		var ftex := load("res://assets/sprites/faces/%s.png" % _face_name(face.kind)) as Texture2D
		if ftex != null:
			box.add_child(_centered(ftex))


func _cost_badge(cost: int) -> Control:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14, 0.85)
	bg.size = Vector2(18, 18)
	bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = str(cost)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.size = Vector2(18, 18)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(lbl)
	return bg


func _centered(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.position = ((Vector2(DICE_BOX, DICE_BOX) - tex.get_size()) * 0.5).round()
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _face_name(kind: DiceData.FaceKind) -> String:
	match kind:
		DiceData.FaceKind.FIRE: return "fire"
		DiceData.FaceKind.ICE: return "ice"
		DiceData.FaceKind.LIGHTNING: return "lightning"
		DiceData.FaceKind.CURSE: return "curse"
		DiceData.FaceKind.REROLL: return "reroll"
	return ""


# --- 표시 갱신 ----------------------------------------------------------
func _refresh() -> void:
	_refresh_enemies()
	_player_label.text = "플레이어 HP: %d/%d   방어: %d   에너지: %d/%d   리롤: %d   골드: %d" % [
		GameManager.current_hp, GameManager.max_hp, _bm.player_block if _bm else 0,
		_bm.energy if _bm else 0, BattleManager.MAX_ENERGY,
		GameManager.reroll_tokens, GameManager.gold
	]
	_update_buttons()


func _refresh_enemies() -> void:
	if _bm == null:
		return
	for child in _enemy_box.get_children():
		child.queue_free()

	var enemies := _bm.get_enemies()
	var target := _bm.current_target()
	for i in enemies.size():
		var e: EnemyInstance = enemies[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_END
		col.add_theme_constant_override("separation", 2)
		_enemy_box.add_child(col)

		if not e.is_dead():
			col.add_child(_make_intent_row(e.current_intent()))

		var spr := _make_enemy_sprite(e)
		if spr != null:
			col.add_child(spr)

		var btn := Button.new()
		if e.is_dead():
			btn.text = "%s 처치됨" % e.data.display_name
			btn.disabled = true
		else:
			var prefix := "▶ " if e == target else ""
			var status := e.status_text()
			var status_part := ("  [%s]" % status) if status != "" else ""
			btn.text = "%s%s  HP %d/%d  방어 %d%s" % [
				prefix, e.data.display_name, e.current_hp, e.data.max_hp, e.block, status_part
			]
			btn.disabled = _ended
			btn.pressed.connect(_on_target_pressed.bind(i))
		col.add_child(btn)


func _make_enemy_sprite(e: EnemyInstance) -> TextureRect:
	var tex := load("res://assets/sprites/enemies/%s.png" % e.data.id) as Texture2D
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.texture = tex
	var scale := minf(ENEMY_SCALE, ENEMY_MAX_H / tex.get_size().y)
	tr.custom_minimum_size = tex.get_size() * scale
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if e.is_dead():
		tr.modulate = Color(0.35, 0.35, 0.4, 0.5)
	return tr


func _make_intent_row(intent: IntentData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var icon := _make_intent_icon(intent)
	if icon != null:
		row.add_child(icon)
	var lbl := Label.new()
	lbl.text = _intent_value_text(intent)
	row.add_child(lbl)
	return row


func _make_intent_icon(intent: IntentData) -> TextureRect:
	if intent == null:
		return null
	var tex := load("res://assets/sprites/intents/%s.png" % _intent_kind_name(intent.kind)) as Texture2D
	if tex == null:
		return null
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(INTENT_ICON, INTENT_ICON)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return tr


func _intent_kind_name(kind: IntentData.IntentKind) -> String:
	match kind:
		IntentData.IntentKind.CHARGE: return "charge"
		IntentData.IntentKind.SNIPE: return "snipe"
		IntentData.IntentKind.EXPLODE: return "explode"
		IntentData.IntentKind.REINFORCE: return "reinforce"
		IntentData.IntentKind.SUMMON: return "summon"
	return ""


func _intent_value_text(intent: IntentData) -> String:
	if intent == null:
		return ""
	match intent.kind:
		IntentData.IntentKind.REINFORCE:
			return "방어 %d" % intent.value
		IntentData.IntentKind.SUMMON:
			return "증원"
	return str(intent.value)


func _on_target_pressed(index: int) -> void:
	_bm.set_target(index)
	_refresh()


func _update_buttons() -> void:
	_confirm_btn.disabled = _ended
