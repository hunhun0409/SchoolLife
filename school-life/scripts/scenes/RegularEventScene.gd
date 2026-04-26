extends "res://scripts/scenes/BaseScreen.gd"

var event = {}
var result_label: Label


func _ready() -> void:
    super()
    event = game_state().get_due_regular_event()
    add_header("정기 이벤트")
    if event.is_empty():
        add_body_label("진행할 정기 이벤트가 없습니다.")
        add_button("메인", _on_main)
        return

    add_body_label("%s\n%s" % [str(event.get("name", "정기 이벤트")), str(event.get("description", ""))])
    add_separator()
    add_button("해결", _on_run)
    add_button("메인", _on_main)
    result_label = add_body_label("")


func _on_run() -> void:
    var result = game_state().run_regular_event(str(event.get("id", "")))
    result_label.text = "결과: %s / 점수 %d" % [str(result.get("rank", "-")), int(result.get("score", 0))]
    go_to("res://scenes/MainScene.tscn")


func _on_main() -> void:
    go_to("res://scenes/MainScene.tscn")
