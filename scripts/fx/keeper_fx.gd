class_name KeeperFx
extends Node2D
## The keeper's own feedback (readability step; ART_DIRECTION §5 "What is missing everywhere"), code-drawn until
## the owner draws poses. One node on the fog layer, so it shows over the fog:
##   - dash: a warm smear from where the dash started, kl_fx_dash_ghosts afterimages that fade over
##     kl_fx_ghost_life, a small ember puff at the start, and a warm shimmer while nothing can hurt you;
##   - cast (Lampfire, Fireglobe, Lance): a lamp flare thrust out along the aim for kl_fx_cast_time (the keeper's
##     sprite also uses the Puny raise and thrust frames: player.gd pose());
##   - drink: warm motes rising up the coat for kl_fx_drink_time;
##   - hurt: a cold flash ring for kl_fx_hurt_time; while a Wickling drains you, a frost edge.
## Warm is the keeper's, cold is the dark's (ART_DIRECTION §1.4): the hurt and frost cues are the cold colour.

const WARM := Color(1.0, 0.82, 0.48)
const AMBER := Color(0.96, 0.65, 0.26)

static var inst: KeeperFx

var _ghosts: Array = []      # [position, frame, row, age]
var _dashes_seen := 0
var _ghost_next := 0.0
var _puff_t := 0.0
var _puff_at := Vector2.ZERO
var _t := 0.0

func _enter_tree() -> void:
	inst = self

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	z_index = 11   # over the foes, under the fire and the telegraphs

func _keeper() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

## Afterimages alive now (tests).
func ghost_count() -> int:
	return _ghosts.size()

func _process(delta: float) -> void:
	_t += delta
	var k := _keeper()
	if k == null or k.combat == null:
		return
	var c = k.combat
	if c.dashes != _dashes_seen:
		_dashes_seen = c.dashes
		_puff_t = 0.25
		_puff_at = c.dash_from
		_ghost_next = 0.0
	if c.is_dashing():
		_ghost_next -= delta
		if _ghost_next <= 0.0 and Tuning.kl_fx_dash_ghosts > 0:
			var ps: Array = k.pose()
			_ghosts.append([k.global_position, ps[0], ps[1], 0.0])
			_ghost_next = Tuning.kl_dash_time / float(Tuning.kl_fx_dash_ghosts)
	var i := 0
	while i < _ghosts.size():
		_ghosts[i][3] += delta
		if _ghosts[i][3] >= Tuning.kl_fx_ghost_life:
			_ghosts.remove_at(i)
		else:
			i += 1
	_puff_t = maxf(0.0, _puff_t - delta)
	var busy: bool = c.is_dashing() or c.cast_t > 0.0 or k.drink_t > 0.0 or k.hurt_t > 0.0 or k.frost_t > 0.0 \
		or not _ghosts.is_empty() or _puff_t > 0.0
	if busy or _was_busy:
		queue_redraw()
	_was_busy = busy

var _was_busy := false

func _draw() -> void:
	var k := _keeper()
	if k == null or k.combat == null:
		return
	var c = k.combat
	var kp: Vector2 = k.global_position
	var f := Art.KEEPER_FRAME
	var fm := maxf(Settings.flash_mult(), 0.5)
	# Dash: the smear behind, the afterimages, the ember puff where it started, and the shimmer.
	if c.is_dashing():
		var from: Vector2 = c.dash_from
		var d: Vector2 = kp - from
		if d.length() > 2.0:
			var n := d.normalized().orthogonal() * 9.0
			var body := Vector2(0, -16)
			draw_colored_polygon(PackedVector2Array([from + body + n * 0.3, kp + body + n, kp + body - n, from + body - n * 0.3]), Color(WARM, 0.22 * fm))
		draw_arc(kp + Vector2(0, -16), 22.0, 0.0, TAU, 24, Color(WARM, (0.35 + 0.25 * sin(_t * 40.0)) * fm), 1.5)
	for g in _ghosts:
		var a: float = 1.0 - float(g[3]) / maxf(Tuning.kl_fx_ghost_life, 0.01)
		var gp: Vector2 = g[0]
		draw_texture_rect_region(Art.KEEPER_SHEET, Rect2(gp + Vector2(-f, -f - 10), Vector2(f, f) * 2.0), Rect2(int(g[1]) * f, int(g[2]) * f, f, f), Color(1.0, 0.78, 0.5, 0.5 * a))
	if _puff_t > 0.0:
		var pk := 1.0 - _puff_t / 0.25
		for j in 6:
			var v := Vector2.from_angle(j * TAU / 6.0 + 0.3) * (6.0 + 18.0 * pk)
			draw_rect(Rect2(_puff_at + v + Vector2(-1.5, -6.0 - 6.0 * pk), Vector2(3, 3)), Color(AMBER, (1.0 - pk) * fm))
	# Cast: the lamp thrust out along the aim, with a flare at its tip.
	if c.cast_t > 0.0:
		var ck: float = 1.0 - c.cast_t / maxf(Tuning.kl_fx_cast_time, 0.01)
		var reach := 8.0 + 14.0 * sin(minf(ck * 1.6, 1.0) * PI * 0.5)
		if c.cast_kind == "lob":
			reach *= 0.6
		var hand: Vector2 = kp + Vector2(0, -16) + c.cast_dir * reach
		draw_line(kp + Vector2(0, -16), hand, Color(0.36, 0.2, 0.12, 0.9), 2.0)
		var glow := 7.0 + (5.0 if c.cast_kind == "thrust" else 3.0) * (1.0 - ck)
		draw_circle(hand, glow, Color(WARM, 0.35 * (1.0 - ck) * fm + 0.15))
		draw_circle(hand, 3.0, Color(1.0, 0.95, 0.8, 0.95))
	# Drink: warm motes rise up the coat.
	if k.drink_t > 0.0:
		var dk: float = 1.0 - k.drink_t / maxf(Tuning.kl_fx_drink_time, 0.01)
		draw_arc(kp + Vector2(0, -2), 14.0 + 6.0 * dk, 0.0, TAU, 20, Color(AMBER, 0.6 * (1.0 - dk)), 2.0)
		draw_texture_rect(LightTex.radial(), Rect2(kp + Vector2(-22, -40 - 14.0 * dk), Vector2(44, 44)), false, Color(AMBER, 0.45 * (1.0 - dk) * fm))
		for j in 8:
			var y := -fmod(dk * 56.0 + j * 8.0, 56.0)
			var x := sin(j * 2.3 + dk * 6.0) * 11.0
			draw_rect(Rect2(kp + Vector2(x - 2.0, y), Vector2(4, 4)), Color(WARM, 0.95 * (1.0 - dk * 0.7)))
	# Hurt: a cold flash ring. Drained: a frost edge of small ice spikes.
	if k.hurt_t > 0.0:
		var hk: float = k.hurt_t / maxf(Tuning.kl_fx_hurt_time, 0.01)
		# The cold hit silhouette, drawn here over the fog: on the keeper's own layer the darkness and the warm hand
		# lamp would turn it grey-green.
		var ps: Array = k.pose()
		if int(ps[0]) == k.PUNY_HIT:
			draw_texture_rect_region(Art.KEEPER_SHEET, Rect2(kp + Vector2(-f, -f - 10), Vector2(f, f) * 2.0), Rect2(int(ps[0]) * f, int(ps[1]) * f, f, f), Color(0.64, 0.78, 1.0, 0.95))
		draw_arc(kp + Vector2(0, -16), 18.0 + 10.0 * (1.0 - hk), 0.0, TAU, 24, Color(Telegraph.COLD, 0.8 * hk), 2.5)
	if k.frost_t > 0.0 or k.hurt_t > 0.0:
		var fa: float = 0.85 if k.frost_t > 0.0 else 0.5 * k.hurt_t / maxf(Tuning.kl_fx_hurt_time, 0.01)
		for j in 8:
			var a := j * TAU / 8.0 + 0.2
			var base := kp + Vector2(0, -16) + Vector2(cos(a) * 15.0, sin(a) * 20.0)
			var out := Vector2(cos(a), sin(a) * 1.3).normalized()
			draw_line(base, base + out * (4.0 + 2.0 * sin(_t * 9.0 + j)), Color(Telegraph.COLD, fa), 1.5)
		draw_arc(kp + Vector2(0, -16), 17.0, 0.0, TAU, 28, Color(Telegraph.COLD, fa * 0.5), 1.0)
