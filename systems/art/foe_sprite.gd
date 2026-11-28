class_name FoeSprite
extends AnimatedSprite2D
## The placeholder swap hook on a foe, the keeper or a person (ART_DIRECTION §6.3-§6.4).
## FoeSprite.attach(owner, subject) adds one only when owner art exists for the subject (Art.frames); otherwise it
## returns null and the owner keeps drawing its code shape. Owners call play_anim("windup"), never a frame number.
##   - A missing animation falls back: windup, attack, recover, notice -> idle; move -> idle; hurt -> keep the
##     current one (the hit flash does the work). If not even idle exists, the sprite hides and the code shape shows.
##   - A wind-up is stretched to the length of its tuning value, so art never sets gameplay timing.
##   - Overlays (telegraphs, the shell ring, burning edges, health arcs) stay code-drawn by the owner. The sprite
##     draws behind its owner (show_behind_parent), so whatever the owner's _draw() still draws sits on top of it;
##     the shared Telegraph markers are on z 13, over every foe.
##   - The hit flash (the owner's self_modulate) is copied onto the sprite.
##   - play_once() holds a one-shot (an elite's shell cracking, a nest's hatch) over the owner's per-frame choice.
##   - leave_remnant() plays the death strip where a foe died, after the foe itself is gone.

const FALLBACK := {"windup": "idle", "attack": "idle", "recover": "idle", "notice": "idle", "move": "idle",
	"spawn": "idle", "cast": "idle", "lob": "cast", "thrust": "cast", "dash": "move", "drink": "idle", "death": "idle",
	"flee": "move", "crack": "idle", "kindle": "idle", "windup_puff": "windup", "windup_dive": "windup",
	"attack_puff": "attack", "attack_dive": "attack", "phase_rise": "idle", "talk": "idle", "wave": "idle",
	"push": "move", "give": "idle", "laugh": "idle"}

var subject := ""
var variant := ""
var _anim := ""
var _hold_t := 0.0     # > 0: a play_once() one-shot is showing; play_anim() waits

## A sprite for `owner` if the subject has owner art, else null (the code shape stays).
static func attach(owner: Node2D, subj: String, var_name: String = "") -> FoeSprite:
	var sf := Art.frames(subj, var_name)
	if sf == null:
		return null
	var s := FoeSprite.new()
	s.subject = subj
	s.variant = var_name
	s.sprite_frames = sf
	s.name = "Art"
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(Art.SCALE, Art.SCALE)
	s.centered = true
	s.show_behind_parent = true
	s._anchor_to("idle")
	owner.add_child(s)
	s.play_anim("idle")
	return s

## True when it is showing owner art (the owner then draws only its overlays).
func showing() -> bool:
	return visible and sprite_frames != null and _anim != ""

## Swap to another variant's frames (an elite Wickling whose shell broke). False if that variant has no strips:
## the current frames stay.
func set_variant(var_name: String) -> bool:
	if var_name == variant:
		return true
	var sf := Art.frames(subject, var_name)
	if sf == null:
		return false
	variant = var_name
	sprite_frames = sf
	var was := _anim
	_anim = ""
	play_anim(was if was != "" else "idle")
	return true

## The animation that would play for `anim` (after the fallbacks), or "" if none (not even idle).
func resolve(anim: String) -> String:
	var name := anim
	var guard := 0
	while not sprite_frames.has_animation(name) and guard < 4:
		name = FALLBACK.get(name, "idle")
		guard += 1
	return name if sprite_frames.has_animation(name) else ""

## Plays an animation by name, with the fallbacks above. seconds > 0 stretches a one-shot to last that long
## (otherwise its frames file's timed_by tuning value does, if it names one). Asking again for what is already
## showing does nothing, so a finished one-shot holds its last frame instead of restarting.
func play_anim(anim: String, seconds: float = 0.0) -> void:
	if _hold_t > 0.0:
		return
	if anim == "hurt" and _anim != "" and not sprite_frames.has_animation("hurt"):
		return
	var name := resolve(anim)
	if name == "":
		visible = false
		_anim = ""
		return
	visible = true
	if name == _anim:
		return
	_start(name, seconds)

## A one-shot shown for `seconds` (or its own length) whatever the owner asks for meanwhile. False if the strip
## is missing (no fallback: a missing crack is just not shown).
func play_once(anim: String, seconds: float = 0.0) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(anim):
		return false
	visible = true
	_start(anim, seconds)
	var n := sprite_frames.get_frame_count(anim)
	_hold_t = seconds if seconds > 0.0 else n / maxf(sprite_frames.get_animation_speed(anim), 0.01)
	return true

func _start(name: String, seconds: float) -> void:
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

## True while a play_once() one-shot is showing.
func holding() -> bool:
	return _hold_t > 0.0

func _process(delta: float) -> void:
	_hold_t = maxf(0.0, _hold_t - delta)
	var p := get_parent() as CanvasItem
	if p:
		modulate = p.self_modulate

## Where a foe with owner art died: its death strip plays in the foe's place (on the same layer), then fades.
## Nothing if it has no art or no death strip. The remnant is only a picture: no groups, no collision.
static func leave_remnant(owner: Node2D) -> Node2D:
	var s := owner.get_node_or_null("Art") as FoeSprite
	if s == null or not s.showing() or not s.sprite_frames.has_animation("death") or owner.get_parent() == null:
		return null
	var r := AnimatedSprite2D.new()
	r.name = "Remnant"
	r.set_meta("remnant", true)
	r.sprite_frames = s.sprite_frames
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.centered = true
	r.flip_h = s.flip_h
	r.z_index = owner.z_index
	owner.get_parent().add_child(r)
	r.global_transform = s.global_transform
	var size: Vector2i = s.sprite_frames.get_meta("frame_size_death", s.sprite_frames.get_meta("frame_size", Vector2i(16, 16)))
	r.offset = Vector2(0, -size.y / 2.0) if str(s.sprite_frames.get_meta("anchor", "foot")) == "foot" else Vector2.ZERO
	r.play("death")
	var n := s.sprite_frames.get_frame_count("death")
	var life := n / maxf(s.sprite_frames.get_animation_speed("death"), 0.01)
	var tw := r.create_tween()
	tw.tween_interval(life + 0.25)
	tw.tween_property(r, "modulate:a", 0.0, 0.5)
	tw.tween_callback(r.queue_free)
	return r
