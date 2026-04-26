extends Node

const DATA_FILES = {
    "characters": "res://data/characters.json",
    "weekday_actions": "res://data/weekday_actions.json",
    "weekend_locations": "res://data/weekend_locations.json",
    "regular_events": "res://data/regular_events.json",
    "clues": "res://data/clues.json",
    "perks": "res://data/perks.json",
    "endings": "res://data/endings.json"
}

var data = {}
var errors: Array[String] = []


func _ready() -> void:
    load_all()


func load_all() -> void:
    data.clear()
    errors.clear()

    for key in DATA_FILES:
        var loaded = _load_json(DATA_FILES[key])
        data[key] = _index_by_id(loaded)


func get_all(collection: String) -> Array:
    if not data.has(collection):
        return []
    return data[collection].values()


func get_entry(collection: String, id: String) -> Dictionary:
    if not data.has(collection):
        return {}
    return data[collection].get(id, {})


func has_entry(collection: String, id: String) -> bool:
    return data.has(collection) and data[collection].has(id)


func get_regular_event_for_week(week: int) -> Dictionary:
    for event in get_all("regular_events"):
        if int(event.get("week", -1)) == week:
            return event
    return {}


func _load_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        errors.append("데이터 파일을 찾을 수 없습니다: %s" % path)
        return []

    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        errors.append("데이터 파일을 열 수 없습니다: %s" % path)
        return []

    var parsed = JSON.parse_string(file.get_as_text())
    if parsed == null:
        errors.append("잘못된 JSON입니다: %s" % path)
        return []

    return parsed


func _index_by_id(items: Variant) -> Dictionary:
    var indexed = {}
    if typeof(items) != TYPE_ARRAY:
        errors.append("데이터 파일의 최상위 형식은 배열이어야 합니다.")
        return indexed

    for item in items:
        if typeof(item) != TYPE_DICTIONARY:
            continue
        var id = str(item.get("id", ""))
        if id.is_empty():
            errors.append("id가 없는 데이터 항목입니다: %s" % str(item))
            continue
        indexed[id] = item

    return indexed
