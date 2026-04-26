extends RefCounted
class_name Character

const CHARACTER_IMAGE_DIRS = [
    "res://resource/sprites/characters",
    "res://resources/sprites/characters",
    "res://game/resources/sprites/characters"
]

static var _thumbnail_cache = {}

var data: Dictionary = {}


func _init(character_data: Dictionary = {}) -> void:
    data = character_data


func GetThumbnail() -> Texture2D:
    var character_id = _get_id()
    if _thumbnail_cache.has(character_id):
        return _thumbnail_cache[character_id]

    var texture = _make_temporary_thumbnail(_thumbnail_color(character_id))
    _thumbnail_cache[character_id] = texture
    return texture


func GetCharacterImage(emotion: String = "normal") -> Texture2D:
    var character_id = _get_id()
    var emotion_id = emotion if not emotion.is_empty() else "normal"
    var texture = _load_texture("%s_%s" % [character_id, emotion_id])
    if texture != null:
        return texture

    if emotion_id != "normal":
        texture = _load_texture("%s_normal" % character_id)
        if texture != null:
            return texture

    return GetThumbnail()


func _get_id() -> String:
    return str(data.get("id", "user"))


func _load_texture(file_stem: String) -> Texture2D:
    for dir in CHARACTER_IMAGE_DIRS:
        var path = "%s/%s.png" % [dir, file_stem]
        if ResourceLoader.exists(path):
            var texture = load(path)
            if texture is Texture2D:
                return texture

    return null


func _thumbnail_color(character_id: String) -> Color:
    match character_id:
        "seoyeon":
            return Color(0.20, 0.34, 0.62)
        "minji":
            return Color(0.54, 0.22, 0.22)
        "harin":
            return Color(0.48, 0.24, 0.56)
        "user":
            return Color(0.18, 0.28, 0.42)
        _:
            return Color(0.24, 0.32, 0.42)


func _make_temporary_thumbnail(base_color: Color) -> Texture2D:
    var size = 44
    var center = float(size) * 0.5
    var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
    for y in range(size):
        for x in range(size):
            var dx = float(x) - center
            var dy = float(y) - center
            var distance = sqrt(dx * dx + dy * dy)
            if distance <= center - 1.0:
                var shade = 0.84 + (float(y) / float(size)) * 0.22
                image.set_pixel(x, y, Color(base_color.r * shade, base_color.g * shade, base_color.b * shade, 1.0))
            else:
                image.set_pixel(x, y, Color(0, 0, 0, 0))

    return ImageTexture.create_from_image(image)
