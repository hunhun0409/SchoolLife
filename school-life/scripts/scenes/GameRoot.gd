extends Control

const TITLE_SCREEN = "res://scenes/TitleScene.tscn"
const CharacterModel = preload("res://scripts/models/Character.gd")

const SCREEN_DEFS = {
    "res://scenes/TitleScene.tscn": {
        "name": "타이틀",
        "script": "res://scripts/scenes/TitleScene.gd",
        "hud": false
    },
    "res://scenes/MainScene.tscn": {
        "name": "메인",
        "script": "res://scripts/scenes/MainScene.gd",
        "hud": true
    },
    "res://scenes/WeekdayScheduleScene.tscn": {
        "name": "평일 일정",
        "script": "res://scripts/scenes/WeekdayScheduleScene.gd",
        "hud": true
    },
    "res://scenes/WeekendScene.tscn": {
        "name": "주말",
        "script": "res://scripts/scenes/WeekendScene.gd",
        "hud": true
    },
    "res://scenes/RegularEventScene.tscn": {
        "name": "정기 이벤트",
        "script": "res://scripts/scenes/RegularEventScene.gd",
        "hud": true
    },
    "res://scenes/ClueLogScene.tscn": {
        "name": "단서 기록",
        "script": "res://scripts/scenes/ClueLogScene.gd",
        "hud": true
    },
    "res://scenes/GalleryScene.tscn": {
        "name": "갤러리",
        "script": "res://scripts/scenes/GalleryScene.gd",
        "hud": true
    },
    "res://scenes/EndingScene.tscn": {
        "name": "엔딩",
        "script": "res://scripts/scenes/EndingScene.gd",
        "hud": true
    }
}

var hud_panel: PanelContainer
var avatar_button: TextureButton
var profile_label: Label
var date_label: Label
var screen_label: Label
var content_layer: Control
var popup_layer: Control
var popup_panel: PanelContainer
var popup_avatar: TextureRect
var popup_name_label: Label
var popup_role_label: Label
var popup_status_label: Label
var current_panel: Control
var current_screen_path = TITLE_SCREEN
var popup_character_index = 0


func _ready() -> void:
    _focus_game_window()
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build_layers()
    _build_character_popup()
    game_state().state_changed.connect(_refresh_hud)
    game_state().state_changed.connect(_refresh_character_popup)
    show_screen(TITLE_SCREEN)


func _focus_game_window() -> void:
    if DisplayServer.get_name() == "headless":
        return

    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
    DisplayServer.window_move_to_foreground()


func show_screen(path: String) -> void:
    if not SCREEN_DEFS.has(path):
        push_warning("Unknown screen path: %s" % path)
        return

    current_screen_path = path
    if current_panel != null:
        content_layer.remove_child(current_panel)
        current_panel.queue_free()
        current_panel = null

    var definition = SCREEN_DEFS[path]
    var panel_script = load(str(definition["script"]))
    current_panel = Control.new()
    current_panel.name = str(definition["name"])
    current_panel.set_script(panel_script)
    current_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    content_layer.add_child(current_panel)

    hud_panel.visible = bool(definition["hud"])
    content_layer.offset_top = 72 if hud_panel.visible else 0
    if not hud_panel.visible:
        _hide_character_popup()
    screen_label.text = str(definition["name"])
    _refresh_hud()


func _build_layers() -> void:
    content_layer = Control.new()
    content_layer.name = "ScreenLayer"
    content_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    content_layer.offset_top = 72
    add_child(content_layer)

    hud_panel = PanelContainer.new()
    hud_panel.name = "UserStatusPanel"
    hud_panel.theme_type_variation = "UserHudPanel"
    hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
    hud_panel.offset_left = 12
    hud_panel.offset_top = 10
    hud_panel.offset_right = -12
    hud_panel.offset_bottom = 66
    hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hud_panel)

    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    hud_panel.add_child(row)

    avatar_button = TextureButton.new()
    avatar_button.custom_minimum_size = Vector2(44, 44)
    avatar_button.texture_normal = CharacterModel.new({"id": "user"}).GetThumbnail()
    avatar_button.texture_hover = CharacterModel.new({"id": "user"}).GetThumbnail()
    avatar_button.ignore_texture_size = true
    avatar_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    avatar_button.pressed.connect(_toggle_character_popup)
    row.add_child(avatar_button)

    var info = VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(info)

    profile_label = Label.new()
    profile_label.text = "플레이어"
    profile_label.add_theme_font_size_override("font_size", 16)
    profile_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(profile_label)

    date_label = Label.new()
    date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info.add_child(date_label)

    screen_label = Label.new()
    screen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    screen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    screen_label.add_theme_font_size_override("font_size", 16)
    screen_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(screen_label)

    popup_layer = Control.new()
    popup_layer.name = "PopupLayer"
    popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    popup_layer.z_index = 1000
    popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(popup_layer)


func _build_character_popup() -> void:
    popup_panel = PanelContainer.new()
    popup_panel.name = "CharacterPopup"
    popup_panel.theme_type_variation = "CharacterPopupPanel"
    popup_panel.visible = false
    popup_panel.z_index = 1001
    popup_panel.set_anchors_preset(Control.PRESET_CENTER)
    popup_panel.offset_left = -380
    popup_panel.offset_top = -230
    popup_panel.offset_right = 380
    popup_panel.offset_bottom = 230
    popup_layer.add_child(popup_panel)

    var root = HBoxContainer.new()
    root.add_theme_constant_override("separation", 18)
    popup_panel.add_child(root)

    popup_avatar = TextureRect.new()
    popup_avatar.custom_minimum_size = Vector2(300, 420)
    popup_avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    popup_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    root.add_child(popup_avatar)

    var info_column = VBoxContainer.new()
    info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_column.add_theme_constant_override("separation", 12)
    root.add_child(info_column)

    var header = HBoxContainer.new()
    header.add_theme_constant_override("separation", 10)
    info_column.add_child(header)

    var title_column = VBoxContainer.new()
    title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_column)

    popup_name_label = Label.new()
    popup_name_label.add_theme_font_size_override("font_size", 28)
    title_column.add_child(popup_name_label)

    popup_role_label = Label.new()
    popup_role_label.add_theme_font_size_override("font_size", 18)
    title_column.add_child(popup_role_label)

    var close_button = Button.new()
    close_button.text = "닫기"
    close_button.pressed.connect(_hide_character_popup)
    header.add_child(close_button)

    popup_status_label = Label.new()
    popup_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    popup_status_label.add_theme_font_size_override("font_size", 20)
    popup_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    info_column.add_child(popup_status_label)

    var nav_row = HBoxContainer.new()
    nav_row.add_theme_constant_override("separation", 8)
    info_column.add_child(nav_row)

    var prev_button = Button.new()
    prev_button.text = "←"
    prev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    prev_button.pressed.connect(_on_popup_prev)
    nav_row.add_child(prev_button)

    var next_button = Button.new()
    next_button.text = "→"
    next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    next_button.pressed.connect(_on_popup_next)
    nav_row.add_child(next_button)


func _refresh_hud() -> void:
    if date_label == null:
        return

    date_label.text = "루프 %d | %d주차 %s요일 | %s" % [
        game_state().loop_count,
        game_state().week,
        game_state().get_day_name(),
        game_state().get_phase_label()
    ]


func _toggle_character_popup() -> void:
    if not hud_panel.visible:
        return

    popup_panel.visible = not popup_panel.visible
    if popup_panel.visible:
        _refresh_character_popup()


func _hide_character_popup() -> void:
    if popup_panel != null:
        popup_panel.visible = false


func _on_popup_prev() -> void:
    popup_character_index -= 1
    if popup_character_index < 0:
        popup_character_index = _popup_character_count() - 1
    _refresh_character_popup()


func _on_popup_next() -> void:
    popup_character_index = (popup_character_index + 1) % _popup_character_count()
    _refresh_character_popup()


func _refresh_character_popup() -> void:
    if popup_panel == null or not popup_panel.visible:
        return

    if popup_character_index == 0:
        popup_avatar.texture = CharacterModel.new({"id": "user"}).GetCharacterImage("normal")
        popup_name_label.text = "플레이어"
        popup_role_label.text = "주인공"
        popup_status_label.text = "지력 %d\n체력 %d\n매력 %d\n피로도 %d\n단서 %d\n징표 포인트 %d" % [
            int(game_state().stats["intellect"]),
            int(game_state().stats["stamina"]),
            int(game_state().stats["charm"]),
            int(game_state().stats["fatigue"]),
            game_state().clues.size(),
            game_state().sign_points
        ]
        return

    var character = data_manager().get_all("characters")[popup_character_index - 1]
    var character_id = str(character.get("id", ""))
    var affection = int(game_state().affection.get(character_id, 0))
    popup_avatar.texture = CharacterModel.new(character).GetCharacterImage("normal")
    popup_name_label.text = str(character.get("name", character_id))
    popup_role_label.text = str(character.get("archetype", "히로인"))
    popup_status_label.text = "호감도 %d\n관계 단계 %d\n주 능력치 %s\n보너스: %s" % [
        affection,
        game_rules().relationship_stage(affection),
        game_rules().stat_label(str(character.get("stat", ""))),
        str(character.get("bonus", ""))
    ]


func _popup_character_count() -> int:
    return 1 + data_manager().get_all("characters").size()


func game_state() -> Node:
    return get_node("/root/GameState")


func data_manager() -> Node:
    return get_node("/root/DataManager")


func game_rules() -> Node:
    return get_node("/root/GameRules")
