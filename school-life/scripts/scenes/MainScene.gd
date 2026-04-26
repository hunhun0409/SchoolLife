extends "res://scripts/scenes/BaseScreen.gd"

var log_label: Label


func _ready() -> void:
    super()
    add_header("메인")
    add_button("현재 단계 진행", _on_advance_phase)
    add_button("단서 기록", _on_clue_log)
    add_button("타이틀", _on_title)
    add_separator()
    log_label = add_body_label("")
    game_state().state_changed.connect(_refresh)
    _refresh()


func _refresh() -> void:
    log_label.text = "기록\n%s" % game_state().log_text()


func _on_advance_phase() -> void:
    if game_state().term_finished:
        go_to("res://scenes/EndingScene.tscn")
    elif game_state().is_regular_event_due():
        go_to("res://scenes/RegularEventScene.tscn")
    elif game_state().day_index <= 4:
        go_to("res://scenes/WeekdayScheduleScene.tscn")
    else:
        go_to("res://scenes/WeekendScene.tscn")


func _on_clue_log() -> void:
    go_to("res://scenes/ClueLogScene.tscn")


func _on_title() -> void:
    go_to("res://scenes/TitleScene.tscn")
