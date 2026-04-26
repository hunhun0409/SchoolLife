extends "res://scripts/scenes/BaseScreen.gd"

const WEEKDAY_COUNT = 5
const DAY_NAMES = ["월", "화", "수", "목", "금"]
const ACTION_OPTIONS = [
    {"label": "공부", "action_id": "study_problem"},
    {"label": "운동", "action_id": "run"},
    {"label": "사교", "action_id": "speech"}
]
const INTENSITY_OPTIONS = [
    {"label": "열심히", "intensity_id": "focus"},
    {"label": "평범하게", "intensity_id": "normal"},
    {"label": "대충", "intensity_id": "light"}
]

var selected_day_index = 0
var weekday_schedule = []
var weekday_initialized = []
var day_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var intensity_buttons: Array[Button] = []
var detail_title: Label
var result_label: Label


func _ready() -> void:
    super()
    _initialize_schedule()
    add_header("평일 일정")
    _build_scheduler()


func _initialize_schedule() -> void:
    weekday_schedule.clear()
    weekday_initialized.clear()
    for day_index in range(WEEKDAY_COUNT):
        var previous = weekday_schedule[day_index - 1] if day_index > 0 else {
            "action_id": "study_problem",
            "intensity_id": "normal"
        }
        weekday_schedule.append(previous.duplicate())
        weekday_initialized.append(day_index == 0)


func _build_scheduler() -> void:
    var root = HBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_theme_constant_override("separation", 12)
    content.add_child(root)

    var left_panel = VBoxContainer.new()
    left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left_panel.size_flags_stretch_ratio = 4.0
    left_panel.add_theme_constant_override("separation", 8)
    root.add_child(left_panel)

    var day_row = HBoxContainer.new()
    day_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    day_row.add_theme_constant_override("separation", 8)
    left_panel.add_child(day_row)

    for day_index in range(WEEKDAY_COUNT):
        var button = Button.new()
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.custom_minimum_size = Vector2(96, 80)
        button.toggle_mode = true
        button.pressed.connect(_on_day_selected.bind(day_index))
        day_row.add_child(button)
        day_buttons.append(button)

    result_label = Label.new()
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left_panel.add_child(result_label)

    var control_row = HBoxContainer.new()
    control_row.add_theme_constant_override("separation", 8)
    left_panel.add_child(control_row)
    _add_command_button(control_row, "실행", _on_run)
    _add_command_button(control_row, "메인", _on_main)

    var right_panel = VBoxContainer.new()
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right_panel.size_flags_stretch_ratio = 1.0
    right_panel.add_theme_constant_override("separation", 8)
    root.add_child(right_panel)

    detail_title = Label.new()
    detail_title.add_theme_font_size_override("font_size", 20)
    right_panel.add_child(detail_title)

    var action_label = Label.new()
    action_label.text = "행동"
    right_panel.add_child(action_label)
    for option in ACTION_OPTIONS:
        var button = Button.new()
        button.text = str(option["label"])
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.toggle_mode = true
        button.pressed.connect(_on_action_selected.bind(str(option["action_id"])))
        right_panel.add_child(button)
        action_buttons.append(button)

    var intensity_label = Label.new()
    intensity_label.text = "노력"
    right_panel.add_child(intensity_label)
    for option in INTENSITY_OPTIONS:
        var button = Button.new()
        button.text = str(option["label"])
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.toggle_mode = true
        button.pressed.connect(_on_intensity_selected.bind(str(option["intensity_id"])))
        right_panel.add_child(button)
        intensity_buttons.append(button)

    _refresh_view()


func _add_command_button(parent: Control, text: String, callable: Callable) -> void:
    var button = Button.new()
    button.text = text
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callable)
    parent.add_child(button)


func _on_day_selected(day_index: int) -> void:
    selected_day_index = day_index
    _copy_previous_day_if_needed(day_index)
    _refresh_view()


func _on_action_selected(action_id: String) -> void:
    weekday_schedule[selected_day_index]["action_id"] = action_id
    weekday_initialized[selected_day_index] = true
    _propagate_to_uninitialized_days(selected_day_index)
    _refresh_view()


func _on_intensity_selected(intensity_id: String) -> void:
    weekday_schedule[selected_day_index]["intensity_id"] = intensity_id
    weekday_initialized[selected_day_index] = true
    _propagate_to_uninitialized_days(selected_day_index)
    _refresh_view()


func _on_run() -> void:
    var result = game_state().advance_weekdays(weekday_schedule)
    _update_result(str(result.get("message", "완료")))
    if game_state().day_index >= 5:
        go_to("res://scenes/MainScene.tscn")


func _on_main() -> void:
    go_to("res://scenes/MainScene.tscn")


func _refresh_view() -> void:
    for day_index in range(day_buttons.size()):
        var entry = weekday_schedule[day_index]
        var prefix = "▶ " if day_index == selected_day_index else ""
        day_buttons[day_index].text = "%s%s\n%s / %s" % [
            prefix,
            DAY_NAMES[day_index],
            _action_label(str(entry["action_id"])),
            _intensity_label(str(entry["intensity_id"]))
        ]
        day_buttons[day_index].button_pressed = day_index == selected_day_index

    detail_title.text = "%s요일 일정" % DAY_NAMES[selected_day_index]
    _refresh_option_buttons()
    _update_result("선택: %s요일 %s / %s" % [
        DAY_NAMES[selected_day_index],
        _action_label(str(weekday_schedule[selected_day_index]["action_id"])),
        _intensity_label(str(weekday_schedule[selected_day_index]["intensity_id"]))
    ])


func _refresh_option_buttons() -> void:
    var current_action = str(weekday_schedule[selected_day_index]["action_id"])
    for index in range(action_buttons.size()):
        var button = action_buttons[index]
        button.button_pressed = str(ACTION_OPTIONS[index]["action_id"]) == current_action

    var current_intensity = str(weekday_schedule[selected_day_index]["intensity_id"])
    for index in range(intensity_buttons.size()):
        var button = intensity_buttons[index]
        button.button_pressed = str(INTENSITY_OPTIONS[index]["intensity_id"]) == current_intensity


func _copy_previous_day_if_needed(day_index: int) -> void:
    if day_index <= 0 or bool(weekday_initialized[day_index]):
        return

    weekday_schedule[day_index] = weekday_schedule[day_index - 1].duplicate()
    weekday_initialized[day_index] = true
    _propagate_to_uninitialized_days(day_index)


func _propagate_to_uninitialized_days(from_day_index: int) -> void:
    for day_index in range(from_day_index + 1, WEEKDAY_COUNT):
        if bool(weekday_initialized[day_index]):
            return
        weekday_schedule[day_index] = weekday_schedule[day_index - 1].duplicate()


func _action_label(action_id: String) -> String:
    for option in ACTION_OPTIONS:
        if str(option["action_id"]) == action_id:
            return str(option["label"])
    return action_id


func _intensity_label(intensity_id: String) -> String:
    for option in INTENSITY_OPTIONS:
        if str(option["intensity_id"]) == intensity_id:
            return str(option["label"])
    return intensity_id


func _update_result(text: String) -> void:
    if result_label != null:
        result_label.text = text
