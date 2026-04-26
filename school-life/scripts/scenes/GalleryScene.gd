extends "res://scripts/scenes/BaseScreen.gd"


func _ready() -> void:
    super()
    add_header("갤러리")
    add_body_label("갤러리 콘텐츠는 준비 중입니다.")
    add_button("타이틀", _on_title)


func _on_title() -> void:
    go_to("res://scenes/TitleScene.tscn")
