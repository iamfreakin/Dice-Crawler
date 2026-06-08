extends Control
## BattleManager를 구동하고 전투 UI 입력/표시를 처리한다.

var _bm: BattleManager
var _has_rolled: bool = false
var _ended: bool = false
var _victory: bool = false

var _enemy_box: HBoxContainer
var _player_label: Label
var _hand_label: Label
var _result_label: Label
var _log: RichTextLabel
var _roll_btn: Button
var _reroll_btn: Button
var _confirm_btn: Button
var _continue_btn: Button


func _ready() -> void:
	theme = UITheme.shared()
	UITheme.add_background(self, "res://assets/sprites/ui/bg_battle.png")
	if GameManager.dice_pool.is_empty():
		GameManager.start_new_run()
	_build_ui()

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


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 40
	root.offset_top = 30
	root.offset_right = -40
	root.offset_bottom = -30
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var title := Label.new()
	title.text = "Dice Crawler - 전투"
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var enemy_hint := Label.new()
	enemy_hint.text = "적을 클릭해서 공격 대상을 선택하세요."
	root.add_child(enemy_hint)

	_enemy_box = HBoxContainer.new()
	_enemy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_box.add_theme_constant_override("separation", 24)
	root.add_child(_enemy_box)

	root.add_child(HSeparator.new())

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_log)

	root.add_child(HSeparator.new())

	_player_label = Label.new()
	root.add_child(_player_label)

	_hand_label = Label.new()
	root.add_child(_hand_label)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 18)
	root.add_child(_result_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)

	_roll_btn = Button.new()
	_roll_btn.text = "굴리기"
	_roll_btn.pressed.connect(_on_roll_pressed)
	buttons.add_child(_roll_btn)

	_reroll_btn = Button.new()
	_reroll_btn.text = "리롤"
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	buttons.add_child(_reroll_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "확정"
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	buttons.add_child(_confirm_btn)

	_continue_btn = Button.new()
	_continue_btn.text = "계속"
	_continue_btn.visible = false
	_continue_btn.pressed.connect(_on_continue_pressed)
	buttons.add_child(_continue_btn)


func _on_roll_pressed() -> void:
	if _ended or _has_rolled:
		return
	_bm.roll_hand()


func _on_reroll_pressed() -> void:
	if _ended or not _has_rolled:
		return
	if not _bm.reroll():
		_append_log("[color=gray]리롤 토큰이 없습니다.[/color]")


func _on_confirm_pressed() -> void:
	if _ended or not _has_rolled:
		return
	_bm.confirm_turn()


func _on_hand_drawn(hand: Array) -> void:
	_has_rolled = false
	_result_label.text = ""
	var names: Array[String] = []
	for d in hand:
		names.append(d.display_name)
	_hand_label.text = "핸드: " + ", ".join(names)
	_refresh()


func _on_dice_rolled(results: Array) -> void:
	_has_rolled = true
	var parts: Array[String] = []
	for r in results:
		var die: DiceData = r["die"]
		var face: FaceData = r["face"]
		parts.append("%s: %s" % [die.display_name, face.label])
	_result_label.text = "결과: " + "   ".join(parts)
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


func _refresh() -> void:
	_refresh_enemies()
	_player_label.text = "플레이어 HP: %d/%d   방어: %d   리롤: %d   골드: %d" % [
		GameManager.current_hp, GameManager.max_hp,
		_bm.player_block if _bm else 0, GameManager.reroll_tokens, GameManager.gold
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
			var prefix := "> " if e == target else ""
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
	tr.custom_minimum_size = tex.get_size() * 3.0
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
	tr.custom_minimum_size = Vector2(24, 24)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return tr


func _intent_kind_name(kind: IntentData.IntentKind) -> String:
	match kind:
		IntentData.IntentKind.CHARGE:
			return "charge"
		IntentData.IntentKind.SNIPE:
			return "snipe"
		IntentData.IntentKind.EXPLODE:
			return "explode"
		IntentData.IntentKind.REINFORCE:
			return "reinforce"
		IntentData.IntentKind.SUMMON:
			return "summon"
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
	_roll_btn.disabled = _ended or _has_rolled
	_reroll_btn.disabled = _ended or not _has_rolled or GameManager.reroll_tokens <= 0
	_confirm_btn.disabled = _ended or not _has_rolled
