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
var _player_hp_box: HBoxContainer
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

	var root := $Root as VBoxContainer

	# 로그에 패널 배경 (배경 위 가독성)
	var panel_box := UITheme.shared().get_stylebox("panel", "PanelContainer")
	if panel_box != null:
		_log.add_theme_stylebox_override("normal", panel_box)

	# 플레이어 HP 바 (PlayerLabel 위에 삽입)
	_player_hp_box = HBoxContainer.new()
	root.add_child(_player_hp_box)
	root.move_child(_player_hp_box, _player_label.get_index())

	# 주사위 칩을 패널 안에 넣어 HandLabel 아래 배치
	_dice_box = HBoxContainer.new()
	_dice_box.add_theme_constant_override("separation", 12)
	var dice_panel := PanelContainer.new()
	dice_panel.add_child(_dice_box)
	root.add_child(dice_panel)
	root.move_child(dice_panel, _hand_label.get_index() + 1)
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
	_hand_label.text = "주사위 클릭=굴림(에너지)  ·  굴린 주사위의 리롤 버튼=재굴림(토큰)  ·  에너지 %d/%d  토큰 %d" % [
		_bm.energy if _bm else 0, BattleManager.MAX_ENERGY, GameManager.reroll_tokens
	]
	# 지난 턴에서 넘어온 보존 결과를 핸드 앞에 읽기 전용 칩으로 표시한다.
	if _bm:
		for kept in _bm.get_preserved():
			_dice_box.add_child(_preserved_chip(kept))
	for i in _hand.size():
		_dice_box.add_child(_dice_chip(i))


## 안 굴린 주사위 클릭 = 굴림(에너지). 굴린 주사위 클릭 = 그것만 리롤(토큰).
func _dice_chip(index: int) -> Control:
	var die: DiceData = _hand[index]
	var box := _dice_base(die)

	if _bm.is_rolled(index):
		_overlay_face(box, _bm.resolved_for(index))
		box.add_child(_accent_bar())
		# 본체 클릭은 무반응 — 전용 리롤 버튼으로만 리롤(오클릭 방지)
		if not _ended and GameManager.reroll_tokens > 0:
			box.add_child(_reroll_button(index))
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


## 보존된 결과 칩 (읽기 전용, 흐리게 + "보존" 표식). 주사위 슬롯이 아니라 결과 스냅샷이다.
func _preserved_chip(resolved: ResolvedRoll) -> Control:
	var box := _dice_base(resolved.die)
	box.modulate = Color(1, 1, 1, 0.6)
	_overlay_face(box, resolved)
	var tag := _face_label("보존", 11)
	tag.position = Vector2(0, 0)
	tag.size = Vector2(DICE_BOX, 16)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	tag.add_theme_color_override("font_color", Color("7f77dd"))
	box.add_child(tag)
	box.tooltip_text = "보존된 결과 — 지난 턴에서 유지됨"
	return box


func _dice_base(die: DiceData) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(DICE_BOX, DICE_BOX)
	box.size = Vector2(DICE_BOX, DICE_BOX)
	var body := load("res://assets/sprites/dice/%s.png" % die.id) as Texture2D
	if body != null:
		box.add_child(_centered(body))
	return box


## 굴린 주사위 우상단의 전용 리롤 버튼 (토큰 1 소모).
func _reroll_button(index: int) -> Control:
	const SZ := 18.0
	var holder := Control.new()
	holder.size = Vector2(SZ, SZ)
	holder.position = Vector2(DICE_BOX - SZ, 0)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.14, 0.85)
	bg.size = Vector2(SZ, SZ)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	var rb := TextureButton.new()
	rb.texture_normal = load("res://assets/sprites/faces/reroll.png")
	rb.ignore_texture_size = true
	rb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	rb.size = Vector2(SZ, SZ)
	rb.position = Vector2.ZERO
	rb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	rb.tooltip_text = "리롤 (토큰 1)"
	rb.pressed.connect(func(): _bm.reroll_index(index))
	holder.add_child(rb)
	return holder


func _accent_bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color("efc127")
	bar.size = Vector2(DICE_BOX, 5)
	bar.position = Vector2(0, DICE_BOX - 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _overlay_face(box: Control, resolved: ResolvedRoll) -> void:
	if resolved == null or resolved.face == null:
		return
	var face := resolved.face
	if face.kind == DiceData.FaceKind.NUMBER:
		box.add_child(_face_label(str(resolved.value), 30))
	else:
		var path := "res://assets/sprites/faces/%s.png" % _face_name(face.kind)
		var ftex: Texture2D = load(path) as Texture2D if ResourceLoader.exists(path) else null
		if ftex != null:
			box.add_child(_centered(ftex))
		else:
			box.add_child(_face_label(face.label, 20))
	if face.kind == DiceData.FaceKind.AMPLIFY:
		box.tooltip_text = "증폭: 직전 굴림 결과 +2"
	elif face.kind == DiceData.FaceKind.PREHEAT:
		box.tooltip_text = "예열: 다음에 굴릴 주사위 결과 +2"
	elif face.kind == DiceData.FaceKind.TRANSFORM:
		box.tooltip_text = "변환: 직전 굴림을 %s 속성으로 (시너지 완성용)" % _transform_target_text(face)
	elif face.kind == DiceData.FaceKind.DUPLICATE:
		box.tooltip_text = "복제: 직전 굴림 결과를 하나 더 (피해·시너지 2배)"
	elif face.kind == DiceData.FaceKind.PRESERVE:
		box.tooltip_text = "보존: 직전 굴림 결과를 다음 턴까지 유지"
	# 값이 변형된 굴림(증폭/예열 등으로 보정된 결과)에는 보정 배지를 띄운다.
	if resolved.value != face.value:
		var delta := resolved.value - face.value
		var badge := _face_label("%+d" % delta, 13)
		badge.position = Vector2(2, DICE_BOX - 21)
		badge.size = Vector2(28, 18)
		badge.add_theme_color_override("font_color", Color("efc127"))
		box.add_child(badge)
		box.tooltip_text = "보정: %d → %d (%+d)" % [face.value, resolved.value, delta]
	# 변환된 굴림(속성 태그가 면 본래 태그와 달라짐)에는 바뀐 속성 표식을 띄운다.
	elif resolved.tags != face.tags and not resolved.tags.is_empty():
		var elem: DiceData.FaceKind = resolved.tags[0]
		var marker := _face_label(_element_emoji(elem), 13)
		marker.position = Vector2(DICE_BOX - 20, DICE_BOX - 21)
		marker.size = Vector2(18, 18)
		box.add_child(marker)
		box.tooltip_text = "변환됨: %s 속성" % _element_emoji(elem)


func _face_label(text: String, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.size = Vector2(DICE_BOX, DICE_BOX)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


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
	var rect := TextureRect.new()
	rect.texture = tex
	rect.position = ((Vector2(DICE_BOX, DICE_BOX) - tex.get_size()) * 0.5).round()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _face_name(kind: DiceData.FaceKind) -> String:
	match kind:
		DiceData.FaceKind.FIRE: return "fire"
		DiceData.FaceKind.ICE: return "ice"
		DiceData.FaceKind.LIGHTNING: return "lightning"
		DiceData.FaceKind.CURSE: return "curse"
		DiceData.FaceKind.REROLL: return "reroll"
		DiceData.FaceKind.AMPLIFY: return "amplify"
		DiceData.FaceKind.PREHEAT: return "preheat"
		DiceData.FaceKind.TRANSFORM: return "transform"
		DiceData.FaceKind.DUPLICATE: return "duplicate"
		DiceData.FaceKind.PRESERVE: return "preserve"
	return ""


func _element_emoji(kind: DiceData.FaceKind) -> String:
	match kind:
		DiceData.FaceKind.FIRE: return "🔥"
		DiceData.FaceKind.ICE: return "❄️"
		DiceData.FaceKind.LIGHTNING: return "⚡"
	return "?"


## 변환 면이 가리키는 목표 속성을 effects에서 찾아 이모지로 돌려준다.
func _transform_target_text(face: FaceData) -> String:
	for effect in face.effects:
		if effect != null and effect.effect_type == FaceEffectData.EffectType.TRANSFORM_PREVIOUS:
			return _element_emoji(effect.element)
	return "속성"


# --- 표시 갱신 ----------------------------------------------------------
func _refresh() -> void:
	_refresh_enemies()
	for c in _player_hp_box.get_children():
		c.queue_free()
	_player_hp_box.add_child(_hp_bar(GameManager.current_hp, GameManager.max_hp, 260.0, Color("4caf50")))
	_player_label.text = "방어 %d   ·   에너지 %d/%d   ·   리롤 %d   ·   골드 %d" % [
		_bm.player_block if _bm else 0, _bm.energy if _bm else 0, BattleManager.MAX_ENERGY,
		GameManager.reroll_tokens, GameManager.gold
	]
	if not _ended and _bm != null and _bm.get_state() == BattleManager.State.PLAYER_TURN:
		_update_preview()
	_update_buttons()


## 확정 시 예상 결과 미리보기 (preview() 사용).
func _update_preview() -> void:
	var o := _bm.preview()
	var parts: Array[String] = []
	if o.dealt > 0:
		parts.append("피해 %d" % o.dealt)
	if o.block > 0:
		parts.append("방어 %d" % o.block)
	if o.burn > 0:
		parts.append("화상 +%d" % o.burn)
	if o.apply_weak > 0:
		parts.append("약화")
	if o.apply_vulnerable > 0:
		parts.append("취약")
	if o.token_gain > 0:
		parts.append("토큰 +%d" % o.token_gain)
	_result_label.text = "확정 시 →  " + (" · ".join(parts) if not parts.is_empty() else "-")


## HP 바 위젯 (배경 + 채움 + 수치 텍스트).
func _hp_bar(cur: int, mx: int, width: float, fill: Color) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(width, 20)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.9)
	bg.size = Vector2(width, 20)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var frac := clampf(float(cur) / float(maxi(1, mx)), 0.0, 1.0)
	var fr := ColorRect.new()
	fr.color = fill
	fr.size = Vector2(width * frac, 20)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fr)
	var lbl := Label.new()
	lbl.text = "%d/%d" % [cur, mx]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.size = Vector2(width, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lbl)
	return root


func _refresh_enemies() -> void:
	if _bm == null:
		return
	for child in _enemy_box.get_children():
		child.queue_free()

	var enemies := _bm.get_enemies()
	var target := _bm.current_target()
	var intent_forecasts := _bm.preview_enemy_intents()

	for i in enemies.size():
		var e: EnemyInstance = enemies[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_END
		col.add_theme_constant_override("separation", 2)
		_enemy_box.add_child(col)

		if not e.is_dead():
			var forecast: Dictionary = intent_forecasts[i]
			if forecast["will_act"]:
				col.add_child(_make_intent_row(e.current_intent(), forecast["hp_loss"]))

		var spr := _make_enemy_sprite(e)
		if spr != null:
			col.add_child(spr)

		if not e.is_dead():
			col.add_child(_hp_bar(e.current_hp, e.data.max_hp, 140.0, Color("c0392b")))

		var btn := Button.new()
		if e.is_dead():
			btn.text = "%s 처치됨" % e.data.display_name
			btn.disabled = true
		else:
			var prefix := "> " if e == target else ""
			var status := e.status_text()
			var status_part := ("  [%s]" % status) if status != "" else ""
			btn.text = "%s%s  방어 %d%s" % [prefix, e.data.display_name, e.block, status_part]
			if status != "":
				btn.tooltip_text = _status_tooltip(e)
			btn.disabled = _ended
			btn.pressed.connect(_on_target_pressed.bind(i))
		col.add_child(btn)


func _status_tooltip(e: EnemyInstance) -> String:
	var lines: Array[String] = []
	if e.burn > 0:
		lines.append("화상 %d: 적 행동 전에 %d 피해 후 1 감소" % [e.burn, e.burn])
	if e.weak > 0:
		lines.append("약화 %d: 공격력 ×0.75 (%d턴)" % [e.weak, e.weak])
	if e.vulnerable > 0:
		lines.append("취약 %d: 받는 피해 ×1.5 (%d턴)" % [e.vulnerable, e.vulnerable])
	return "\n".join(lines)


func _make_enemy_sprite(e: EnemyInstance) -> TextureRect:
	var tex := load("res://assets/sprites/enemies/%s.png" % e.data.id) as Texture2D
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	var scale := minf(ENEMY_SCALE, ENEMY_MAX_H / tex.get_size().y)
	rect.custom_minimum_size = tex.get_size() * scale
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if e.is_dead():
		rect.modulate = Color(0.35, 0.35, 0.4, 0.5)
	return rect


func _make_intent_row(intent: IntentData, net_hp: int = -1) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var icon := _make_intent_icon(intent)
	if icon != null:
		row.add_child(icon)
	var lbl := Label.new()
	var txt := _intent_value_text(intent)
	if net_hp >= 0:
		txt += "  (-%dHP)" % net_hp  # 막고 나면 실제로 받을 HP 피해
	lbl.text = txt
	row.add_child(lbl)
	return row


func _make_intent_icon(intent: IntentData) -> TextureRect:
	if intent == null:
		return null
	var tex := load("res://assets/sprites/intents/%s.png" % _intent_kind_name(intent.kind)) as Texture2D
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(INTENT_ICON, INTENT_ICON)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


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
