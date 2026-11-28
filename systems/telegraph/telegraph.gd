class_name Telegraph
extends Node2D
## The shared telegraph system (readability step; docs/ART_DIRECTION.md §4, DRAFT). Every foe attack follows one
## rhythm: notice -> wind-up -> commit -> strike -> recover.
##   - A foe starts a wind-up with Telegraph.begin(...), which returns a Tell. The foe ticks it (tell.tick(delta))
##     and strikes when tell.done(). The foe's hit test is tell.contains(point): the marker IS the hitbox (rule 3).
##   - The marker is drawn at full size from the first frame and fills as the wind-up runs (rule 2). For the last
##     Tuning.kl_tell_commit seconds it flashes (FLASH_STEP); with "reduce flashes" it turns solid instead (rule 11, §1.6 rule 7).
##     Markers are never dimmed by "reduce flashes".
##   - Aim locks at commit (tell.locked()); a foe stops moving its marker then (rule 4).
##   - A discrete hit always gets at least Tuning.kl_tell_min of warning (rule 1).
##   - Near the keeper, two warnings never land within Tuning.kl_tell_gap of each other: a later one waits (rule 9).
##   - A wind-up whose foe or landing point is off-screen shows an edge arrow at the screen border (rule 5).
##   - The wind-up sound slot plays as it starts (§4.2 "Sound slots"): assets/audio/sfx/foe/<subject>_<cue>.ogg if
##     the owner adds one, else a reused Kenney stand-in (SOUND_SLOTS).
## One node on the fog layer draws every marker and arrow, above the fog and the foes (rule 6). Tells live in a
## static list, so foes work (and tests run) without the node; the node only draws.
## Colours: foe markers use the cold threat colour #a3bcd4, never amber (ART_DIRECTION §1.4 rule 1).
## M1c: the same node draws the keeper's target-lock marker (LockOn.marker): warm #ffd27a corner brackets, a shape
## no foe tell uses, drawn by the telegraph rules (above fog, full size from the first frame, never flashing).

enum { CIRCLE, LANE, AIM, SPAWN, REACH }

const COLD := Color(0.639, 0.737, 0.831)        # #a3bcd4
const COLD_DEEP := Color(0.427, 0.561, 0.702)   # #6d8fb3 (fills)
const FLASH_STEP := 0.075                        # s per on or off step of the commit flash (under 7 a second)
const KEEPER_RADIUS := 8.0                       # the keeper's body, for hits that test a reach (the spit)
const SFX_DIR := "res://assets/audio/sfx/foe/"
## Stand-in sounds for the slots (reused Kenney cues, pitched): subject_cue -> [cue, volume dB, pitch].
const SOUND_SLOTS := {
	"wickling_notice": ["ui_tick", -18.0, 0.6],
	"wickling_windup": ["ui_tick", -22.0, 0.5],
	"spitwick_windup": ["ui_open", -16.0, 1.35],
	"spitwick_release": ["ui_close", -14.0, 1.4],
	"clinker_notice": ["place_lantern", -12.0, 0.55],
	"clinker_windup": ["place_lantern", -10.0, 0.7],
	"clinker_release": ["pickup_lantern", -10.0, 0.6],
	"nest_windup": ["gather_scrap", -14.0, 0.7],
	"ashbrood_puff_windup": ["note_open", -8.0, 0.55],
	"ashbrood_puff_release": ["note_close", -6.0, 0.5],
	"ashbrood_adds_windup": ["note_open", -12.0, 0.8],
	"ashbrood_dive_windup": ["ui_open", -8.0, 0.55],
	"ashbrood_dive_impact": ["pickup_lantern", -6.0, 0.5],
	"ashbrood_phase_windup": ["unlock", -6.0, 0.7],
	# M1c: the Ashbrood's ash bolts and wing sweep; a foe stepping into lamp light (exposed).
	"ashbrood_bolt_windup": ["ui_open", -12.0, 0.8],
	"ashbrood_bolt_release": ["ui_close", -12.0, 0.9],
	"ashbrood_sweep_windup": ["note_open", -10.0, 0.7],
	"foe_exposed": ["ui_tick", -22.0, 1.7],
	# M2: the Ashbrood's ash wave and low pass (phases 2-3).
	"ashbrood_wave_windup": ["note_open", -9.0, 0.6],
	"ashbrood_wave_release": ["note_close", -6.0, 0.45],
	"ashbrood_strafe_windup": ["ui_open", -9.0, 0.65],
}

static var inst: Telegraph
static var active: Array[Tell] = []    # every live Tell
static var started := 0                  # wind-ups started since the game began (the bench reports it)

class Tell extends RefCounted:
	var kind := 0
	var subject := ""            # "spitwick", "clinker", "ashbrood_puff" ... (sound slots, tests)
	var owner_id := 0            # the foe's instance id
	var hit := true              # a discrete hit (minimum warning, the gap rule); false: a cue (a reach, spawn glows)
	var boss := false            # commit lasts kl_tell_commit_boss
	var center := Vector2.ZERO   # CIRCLE: the centre. LANE / AIM / REACH: the start
	var to := Vector2.ZERO       # LANE / AIM / REACH: the end (AIM: the target point)
	var reach := 0.0             # AIM: how far past the start the shot can go (the danger continues past `to`)
	var radius := 0.0            # CIRCLE: radius. LANE / AIM: half-width. SPAWN: glow radius
	var points := PackedVector2Array()   # SPAWN: where things will appear
	var duration := 0.5
	var lock_time := 0.15        # aim is locked for this long at the end (at least the commit)
	var t := 0.0
	var alive := true

	func tick(delta: float) -> void:
		t += delta

	func left() -> float:
		return maxf(0.0, duration - t)

	func progress() -> float:
		return clampf(t / maxf(duration, 0.001), 0.0, 1.0)

	func commit_time() -> float:
		return Tuning.kl_tell_commit_boss if boss else Tuning.kl_tell_commit

	func committing() -> bool:
		return left() <= commit_time()

	func locked() -> bool:
		return left() <= maxf(lock_time, commit_time())

	func done() -> bool:
		return t >= duration

	## Ends it (the strike happened, or the foe gave up).
	func finish() -> void:
		alive = false
		Telegraph.active.erase(self)

	## The point that matters most: where it lands, or where it starts for a lane.
	func focus() -> Vector2:
		match kind:
			LANE, AIM:
				return to
			SPAWN:
				return points[0] if points.size() > 0 else center
		return center

	## The danger area: the same shape that is drawn. Foes test their hits with this (rule 3).
	func contains(p: Vector2) -> bool:
		match kind:
			CIRCLE:
				return p.distance_to(center) <= radius
			LANE:
				return Geometry2D.get_closest_point_to_segment(p, center, to).distance_to(p) <= radius
			AIM:
				var dir := (to - center).normalized()
				return Geometry2D.get_closest_point_to_segment(p, center, center + dir * reach).distance_to(p) <= radius
		return false

## Starts a wind-up. kind: CIRCLE, LANE, AIM, SPAWN or REACH. The returned Tell is the foe's to tick and finish.
## duration: the wanted wind-up; a hit gets at least kl_tell_min, and later if another warning would land at the
## same moment near the keeper.
static func begin(owner: Node2D, kind: int, subject: String, duration: float, hit: bool = true) -> Tell:
	var t := Tell.new()
	t.kind = kind
	t.subject = subject
	t.owner_id = owner.get_instance_id() if owner else 0
	t.hit = hit
	t.duration = maxf(duration, Tuning.kl_tell_min) if hit else maxf(duration, 0.0)
	t.lock_time = Tuning.kl_tell_commit
	t.center = owner.global_position if owner else Vector2.ZERO
	t.to = t.center
	_prune()
	active.append(t)
	started += 1
	return t

## Call after setting a hit's shape: it waits its turn if another warning near the keeper would land with it
## (rule 9), and its wind-up sound plays (so a player who can't see the foe still hears it).
static func arm(t: Tell, tree: SceneTree, sound: bool = true) -> Tell:
	if t.hit and tree:
		var keeper := tree.get_first_node_in_group("player") as Node2D
		if keeper and _near(t, keeper.global_position):
			for i in 8:
				var moved := false
				for item in active:
					var o: Tell = item
					if o == t or not o.alive or not o.hit or not _near(o, keeper.global_position):
						continue
					if absf(o.left() - t.left()) < Tuning.kl_tell_gap - 0.0001:
						t.duration = t.t + o.left() + Tuning.kl_tell_gap
						moved = true
				if not moved:
					break
	if sound:
		play_slot(t.subject, "windup")
	return t

static func _near(t: Tell, keeper: Vector2) -> bool:
	var r := Tuning.kl_tell_budget_radius
	match t.kind:
		CIRCLE:
			return t.center.distance_to(keeper) <= r + t.radius
		LANE:
			return Geometry2D.get_closest_point_to_segment(keeper, t.center, t.to).distance_to(keeper) <= r + t.radius
		AIM:
			return t.center.distance_to(keeper) <= t.reach + r
	return false

static func _prune() -> void:
	var i := 0
	while i < active.size():
		var t: Tell = active[i]
		if not t.alive or (t.owner_id != 0 and not is_instance_id_valid(t.owner_id)):
			t.alive = false
			active.remove_at(i)
		else:
			i += 1

## A foe's sound slot: the owner's file if it exists, else the stand-in.
static func play_slot(subject: String, cue: String) -> void:
	var key := subject + "_" + cue
	var own := SFX_DIR + key + ".ogg"
	if ResourceLoader.exists(own):
		Sfx.play(own, -8.0, 0.04)
		return
	var slot: Array = SOUND_SLOTS.get(key, [])
	if slot.is_empty():
		return
	Sfx.play(slot[0], slot[1], 0.04, slot[2])

# --- The screen ---------------------------------------------------------------------------------------------

## The part of the world on screen now (the camera's view), or an empty rect without a viewport.
static func view_rect(node: Node) -> Rect2:
	if node == null or not node.is_inside_tree():
		return Rect2()
	var vp := node.get_viewport()
	if vp == null:
		return Rect2()
	var size := vp.get_visible_rect().size
	return vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, size)

## True when p is on screen, at least `margin` px inside its border. Without a view (no viewport) it is true.
static func on_screen(node: Node, p: Vector2, margin: float = 0.0) -> bool:
	var r := view_rect(node)
	if r.size == Vector2.ZERO:
		return true
	return r.grow(-margin).has_point(p)

## The edge arrow for a tell, or {} when it needs none: {"at": point on the screen border, "dir": unit vector}.
## A wind-up needs one when its landing point or its foe is off-screen (rule 5).
static func arrow_for(t: Tell, view: Rect2, keeper: Vector2) -> Dictionary:
	if view.size == Vector2.ZERO or t.kind == REACH:
		return {}
	var target := t.focus()
	if view.has_point(target):
		var owner := instance_from_id(t.owner_id) as Node2D if t.owner_id != 0 and is_instance_id_valid(t.owner_id) else null
		if owner == null or view.has_point(owner.global_position):
			return {}
		target = owner.global_position
	if target.distance_to(keeper) > Tuning.kl_tell_arrow_range:
		return {}
	var inner := view.grow(-28.0)
	var c := inner.get_center()
	var v := target - c
	if v.length() < 0.001:
		return {}
	# Where the line from the screen's centre to the target leaves the inner rect.
	var sx := (inner.size.x * 0.5) / maxf(absf(v.x), 0.001)
	var sy := (inner.size.y * 0.5) / maxf(absf(v.y), 0.001)
	var at := c + v * minf(sx, sy)
	return {"at": at, "dir": v.normalized()}

# --- How a marker looks (pure, so tests can check it) ---------------------------------------------------------

## Edge alpha, fill alpha and colour of a marker now. The edge is never faint and never dimmed by "reduce flashes";
## at commit it flashes white, or (reduce flashes) turns solid white-blue without flashing.
static func style(t: Tell, reduce_flashes: bool) -> Dictionary:
	var k := t.progress()
	var edge := 0.75 + 0.15 * k
	var fill := 0.14 + 0.16 * k
	var col := COLD
	if t.committing():
		if reduce_flashes or t.done():
			# Solid at commit with "reduce flashes", and solid for everyone once it strikes (the dive's flight):
			# the flash itself lasts only the commit, about two flashes, under three a second.
			col = COLD.lerp(Color.WHITE, 0.6)
			edge = 1.0
			fill = 0.34
		else:
			var on := int(t.t / FLASH_STEP) % 2 == 0
			col = Color.WHITE if on else COLD
			edge = 1.0
			fill = 0.42 if on else 0.3
	return {"edge": edge, "fill": fill, "color": col}

# --- Drawing ------------------------------------------------------------------------------------------------

func _enter_tree() -> void:
	inst = self
	add_to_group("telegraph_layer")

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	z_index = 13   # on the fog layer: over the fog, the foes (6-9) and the fire (12); under damage numbers (14)

func _process(_delta: float) -> void:
	_prune()
	var lock_on := LockOn.current != null and not LockOn.current.marker().is_empty()
	if not active.is_empty() or _drawn or lock_on:
		queue_redraw()

var _drawn := false

func _draw() -> void:
	var lm := LockOn.current.marker() if LockOn.current else {}
	_drawn = not active.is_empty() or not lm.is_empty()
	LockOn.draw_marker(self, lm)
	if active.is_empty():
		return
	var reduce := Settings.reduce_flashes
	var view := view_rect(self)
	var keeper := get_tree().get_first_node_in_group("player") as Node2D
	var kp := keeper.global_position if keeper else view.get_center()
	for item in active:
		var t: Tell = item
		if not t.alive:
			continue
		var st := style(t, reduce)
		var col: Color = st["color"]
		var k := t.progress()
		match t.kind:
			CIRCLE:
				draw_circle(t.center, t.radius * k, Color(COLD_DEEP if not t.committing() else col, st["fill"]))
				draw_arc(t.center, t.radius, 0.0, TAU, 56, Color(col, st["edge"]), 2.5)
				draw_arc(t.center, t.radius - 4.0, 0.0, TAU, 56, Color(col, st["edge"] * 0.35), 1.5)
			LANE:
				_draw_lane(t.center, t.to, t.radius, k, col, st)
			AIM:
				_draw_aim(t, col, st)
			SPAWN:
				for p in t.points:
					draw_circle(p, t.radius * (0.4 + 0.6 * k), Color(COLD_DEEP if not t.committing() else col, st["fill"] + 0.1))
					draw_arc(p, t.radius, 0.0, TAU, 24, Color(col, st["edge"]), 2.0)
					draw_circle(p, 2.5, Color(col, 0.9))
			REACH:
				_draw_reach(t, col, k)
		var arrow := arrow_for(t, view, kp)
		if not arrow.is_empty():
			_draw_arrow(t, arrow, col, st)

func _draw_lane(a: Vector2, b: Vector2, hw: float, k: float, col: Color, st: Dictionary) -> void:
	var v := b - a
	var len := v.length()
	if len < 0.5:
		draw_arc(a, hw, 0.0, TAU, 24, Color(col, st["edge"]), 2.5)
		return
	var d := v / len
	var n := d.orthogonal() * hw
	# The fill grows from the foe outwards; the outline is at full size from the first frame.
	var f := a + v * k
	draw_colored_polygon(PackedVector2Array([a + n, f + n, f - n, a - n]), Color(COLD_DEEP if col == COLD else col, st["fill"]))
	draw_line(a + n, b + n, Color(col, st["edge"]), 2.5)
	draw_line(a - n, b - n, Color(col, st["edge"]), 2.5)
	draw_arc(b, hw, d.angle() - PI / 2.0, d.angle() + PI / 2.0, 16, Color(col, st["edge"]), 2.5)
	draw_arc(a, hw, d.angle() + PI / 2.0, d.angle() + PI * 1.5, 16, Color(col, st["edge"] * 0.6), 1.5)
	# Chevrons along the lane show which way it goes.
	var steps := int(len / 48.0)
	for i in steps:
		var c := a + d * (24.0 + i * 48.0)
		draw_polyline(PackedVector2Array([c - d * 6.0 + n * 0.4, c + d * 2.0, c - d * 6.0 - n * 0.4]), Color(col, st["edge"] * 0.5), 2.0)

func _draw_aim(t: Tell, col: Color, st: Dictionary) -> void:
	var d := (t.to - t.center).normalized()
	if d == Vector2.ZERO:
		return
	var n := d.orthogonal() * t.radius
	var end := t.center + d * t.reach
	var lock_a: float = st["edge"] if t.locked() else st["edge"] * 0.55
	# The shot's path: its full width to the target, then fainter to the end of its flight.
	draw_line(t.center + n, t.to + n, Color(col, lock_a * 0.7), 1.5)
	draw_line(t.center - n, t.to - n, Color(col, lock_a * 0.7), 1.5)
	draw_line(t.to + n, end + n, Color(col, lock_a * 0.25), 1.0)
	draw_line(t.to - n, end - n, Color(col, lock_a * 0.25), 1.0)
	draw_line(t.center, t.to, Color(col, st["edge"] if t.locked() else 0.6), 3.0 if t.locked() else 2.0)
	draw_circle(t.to, t.radius * t.progress(), Color(COLD_DEEP if not t.committing() else col, st["fill"]))
	draw_arc(t.to, t.radius, 0.0, TAU, 24, Color(col, st["edge"]), 2.0)

func _draw_reach(t: Tell, col: Color, k: float) -> void:
	# Two smoke tendrils reaching out from the foe towards the keeper.
	var v := t.to - t.center
	var len := v.length()
	if len < 1.0:
		return
	var d := v / len
	var n := d.orthogonal()
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 7:
			var s := float(i) / 6.0 * k
			pts.append(t.center + d * len * s + n * side * sin(s * PI) * 7.0)
		draw_polyline(pts, Color(0.05, 0.06, 0.1, 0.85), 4.0)
		draw_polyline(pts, Color(col, 0.75), 1.5)

func _draw_arrow(t: Tell, arrow: Dictionary, col: Color, st: Dictionary) -> void:
	var at: Vector2 = arrow["at"]
	var d: Vector2 = arrow["dir"]
	var n := d.orthogonal()
	# It pulses twice over the wind-up, and is solid at commit.
	var pulse := 1.0 if t.committing() else 0.65 + 0.35 * cos(t.progress() * TAU * 2.0)
	draw_circle(at, 17.0, Color(0.02, 0.03, 0.06, 0.75))
	draw_colored_polygon(PackedVector2Array([at + d * 22.0, at + d * 8.0 + n * 9.0, at + d * 8.0 - n * 9.0]), Color(col, pulse))
	draw_arc(at, 17.0, 0.0, TAU, 24, Color(col, pulse * float(st["edge"])), 2.0)
	# The attack's icon: a circle, a lane or a line.
	match t.kind:
		CIRCLE, SPAWN:
			draw_arc(at, 7.0, 0.0, TAU, 16, Color(col, pulse), 2.0)
		LANE:
			draw_rect(Rect2(at - Vector2(7, 4), Vector2(14, 8)), Color(col, pulse), false, 2.0)
		AIM:
			draw_line(at - d * 7.0, at + d * 5.0, Color(col, pulse), 2.0)
