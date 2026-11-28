class_name FoeSprite
extends AnimatedSprite2D
## The placeholder swap hook on a foe or the keeper (readability step; ART_DIRECTION §6.3-§6.4, DRAFT).
## FoeSprite.attach(owner, subject) adds one only when owner art exists for the subject (Art.frames); otherwise it
## returns null and the owner keeps drawing its code shape. Owners call play_anim("windup"), never a frame number.
##   - A missing animation falls back: windup, attack, recover, notice -> idle; move -> idle; hurt -> keep the
##     current one (the hit flash does the work). If not even idle exists, the sprite hides and the code shape shows.
##   - A wind-up is stretched to the length of its tuning value, so art never sets gameplay timing.
##   - Overlays (telegraphs, the shell ring, burning edges, health arcs) stay code-drawn by the owner.
##   - The hit flash (the owner's self_modulate) is copied onto the sprite.

const FALLBACK := {"windup": "idle", "attack": "idle", "recover": "idle", "notice": "idle", "move": "idle",
	"spawn": "idle", "cast": "idle", "lob": "cast", "thrust": "cast", "dash": "move", "drink": "idle", "death": "idle"}

var subject := ""
var _anim := ""

## A sprite for `owner` if the subject has owner art, else null (the code shape stays).
static func attach(owner: Node2D, subj: String, variant: String = "") -> FoeSprite:
	var sf := Art.frames(subj, variant)
	if sf == null:
		return null
	var s := FoeSprite.new()
	s.subject = subj
	s.sprite_frames = sf
	s.name = "Art"
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(Art.SCALE, Art.SCALE)
	s.centered = true
	s._anchor_to("idle")
	owner.add_child(s)
	s.play_anim("idle")
	return s

## True when it is showing owner art (the owner then draws only its overlays).
func showing() -> bool:
	return visible and sprite_frames != null and _anim != ""

## Plays an animation by name, with the fallbacks above. seconds > 0 stretches a one-shot to last that long
## (otherwise its frames file's timed_by tuning value does, if it names one).
func play_anim(anim: String, seconds: float = 0.0) -> void:
	var name := anim
	var guard := 0
	while not sprite_frames.has_animation(name) and guard < 4:
		if anim == "hurt" and _anim != "":
			return
		name = FALLBACK.get(name, "idle")
		guard += 1
	if not sprite_frames.has_animation(name):
		visible = false
		_anim = ""
		return
	visible = true
	if name == _anim and is_playing():
		return
	_anim = name
	_anchor_to(name)
	var t := seconds
	if t <= 0.0 and sprite_frames.has_meta("timed_by_" + name):
		var v = Tuning.get(str(sprite_frames.get_meta("timed_by_" + name)))
		t = float(v) if v != null else 0.0
	var fps := sprite_frames.get_animation_speed(name)
	var n := sprite_frames.get_frame_count(name)
	speed_scale = (n / maxf(fps, 0.01)) / t if t > 0.0 and not sprite_frames.get_animation_loop(name) else 1.0
	play(name)

## Each strip can have its own frame size (a 24x24 elite strip next to a 16x16 fallback): with the foot anchor the
## bottom-centre stays on the owner's origin, so a bigger frame grows upward, never into the ground.
func _anchor_to(anim: String) -> void:
	var size: Vector2i = sprite_frames.get_meta("frame_size_" + anim, sprite_frames.get_meta("frame_size", Vector2i(16, 16)))
	offset = Vector2(0, -size.y / 2.0) if str(sprite_frames.get_meta("anchor", "foot")) == "foot" else Vector2.ZERO

func current() -> String:
	return _anim

func _process(_delta: float) -> void:
	var p := get_parent() as CanvasItem
	if p:
		modulate = p.self_modulate
