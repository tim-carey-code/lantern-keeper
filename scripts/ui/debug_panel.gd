extends CanvasLayer
## Live tuning panel. F1 / gamepad Select toggles it. Works with mouse or
## gamepad (D-pad up/down picks a slider, left/right changes it).

const ROWS := [
	["lantern_max_radius", "Lantern radius (px)", 64.0, 512.0, 8.0],
	["fog_creep_per_sec", "Fog creep (/s)", 0.0, 0.5, 0.01],
	["fog_clear_per_sec", "Fog clear (/s)", 0.1, 3.0, 0.05],
	["fog_slow_min", "Walk speed in full fog", 0.2, 1.0, 0.05],
	["hand_lamp_max_radius", "Hand lamp radius (px)", 48.0, 256.0, 4.0],
	["marsh_creep_mult", "Marsh fog creep x", 1.0, 4.0, 0.1],
	["wick_spawn_sec", "Wickling spawn every (s)", 4.0, 60.0, 1.0],
	["wick_speed", "Wickling speed", 20.0, 160.0, 5.0],
	# M1c: the damage fix (owner M1b playtest)
	["kl_wick_chill_hit", "Wickling touch: warmth a tick", 0.0, 30.0, 0.5],
	["kl_wick_chill_tick", "Wickling touch: s a tick", 0.1, 2.0, 0.05],
	["kl_swarm_chill_cap", "Swarm chill cap (warmth/s)", 0.0, 120.0, 1.0],
	["kl_swarm_chill_burst", "Swarm cap burst (s)", 0.1, 2.0, 0.05],
	["kl_foe_dmg_per_level", "Foe damage a level", 0.0, 0.3, 0.01],
	["kl_clinker_knock", "Clinker roll knockback (px)", 0.0, 300.0, 5.0],
	# M1c: light states
	["kl_dark_dmg_mult", "Damage in the dark x", 0.1, 1.5, 0.05],
	["kl_lit_dmg_mult", "Damage when lit x", 0.5, 2.5, 0.05],
	["kl_lit_shell_mult", "Shell wear when lit x", 0.5, 3.0, 0.05],
	["kl_dark_shell_floor", "Shell floor in the dark", 0.0, 5.0, 0.25],
	["kl_exposed_linger", "Exposed linger (s)", 0.0, 3.0, 0.05],
	# M1c: combos
	["kl_catch_reach", "Catch reach (px)", 4.0, 80.0, 1.0],
	["kl_catch_dmg_add", "Catch: extra damage", 0.0, 6.0, 0.25],
	["kl_catch_split", "Catch: side bolts", 0.0, 6.0, 1.0],
	["kl_catch_spread_deg", "Catch: spread (deg)", 0.0, 60.0, 1.0],
	["kl_catch_split_dmg", "Catch: side bolt damage", 0.0, 6.0, 0.25],
	["kl_flare_reach", "Flare snap reach (px)", 0.0, 120.0, 2.0],
	["kl_flare_dmg", "Flare damage", 0.0, 40.0, 0.5],
	["kl_flare_radius", "Flare radius (px)", 40.0, 300.0, 5.0],
	["kl_flare_light_mult", "Flare light x", 1.0, 3.0, 0.05],
	["kl_flare_time", "Flare lasts (s)", 0.5, 10.0, 0.25],
	["kl_flare_lamp_cd", "Flare lamp cooldown (s)", 0.0, 20.0, 0.5],
	["kl_chain_reach", "Chain reach (px)", 4.0, 80.0, 1.0],
	["kl_chain_max_gap", "Chain max gap (px)", 80.0, 800.0, 10.0],
	["kl_chain_dmg", "Chain damage", 0.0, 20.0, 0.5],
	["kl_chain_width", "Chain width (px)", 4.0, 60.0, 1.0],
	["kl_chain_burn_dps", "Chain burn (hp/s)", 0.0, 10.0, 0.25],
	["kl_feed_light_mult", "Feed: lamp light x", 1.0, 2.0, 0.05],
	["kl_feed_core_mult", "Feed: core burn x", 1.0, 4.0, 0.25],
	# M1c: lamp slots
	["kl_lamp_slots_base", "Lamp slots at level 1", 1.0, 6.0, 1.0],
	["kl_lamp_slot_level_a", "3rd lamp slot at level", 1.0, 12.0, 1.0],
	["kl_lamp_slot_level_b", "4th lamp slot at level", 1.0, 12.0, 1.0],
	["kl_lamp_slot_level_c", "5th lamp slot at level", 1.0, 13.0, 1.0],
	["kl_lamp_replant_cd", "Replant delay (s)", 0.0, 30.0, 0.5],
	# M1c: the Ashbrood
	["kl_ashbrood_puff_snuff", "Puff snuffs lamps (s)", 0.0, 10.0, 0.5],
	["kl_ember_flare_radius", "Ember flare radius (px)", 40.0, 260.0, 5.0],
	["kl_ember_flare_time", "Ember flare lasts (s)", 0.5, 10.0, 0.25],
	["kl_ember_flare_cd", "Ember flare cooldown (s)", 0.0, 20.0, 0.5],
	["kl_ashbrood_bolt_period", "Ashbrood ash bolts every (s)", 0.5, 8.0, 0.1],
	["kl_ashbrood_bolt_tell", "Ashbrood ash bolt tell (s)", 0.5, 2.0, 0.05],
	["kl_ashbrood_bolt_count", "Ashbrood ash bolts a fan", 1.0, 7.0, 1.0],
	["kl_ashbrood_bolt_speed", "Ashbrood ash bolt speed", 60.0, 500.0, 10.0],
	["kl_ashbrood_bolt_warmth", "Ashbrood ash bolt warmth", 0.0, 40.0, 1.0],
	["kl_ashbrood_sweep_radius", "Ashbrood wing sweep (px)", 40.0, 200.0, 4.0],
	["kl_ashbrood_sweep_warmth", "Ashbrood wing sweep warmth", 0.0, 40.0, 1.0],
	["kl_ashbrood_sweep_cd", "Ashbrood wing sweep cooldown (s)", 0.5, 12.0, 0.25],
	["kl_ashbrood_dark_sit", "Ashbrood sits in the dark (s)", 0.2, 4.0, 0.1],
	# M1c: target lock
	["kl_lock_range", "Lock range (px)", 100.0, 800.0, 10.0],
	["kl_lock_cone_deg", "Lock cone (deg)", 10.0, 180.0, 5.0],
	["kl_lock_flick", "Lock flick past", 0.4, 1.0, 0.05],
	["kl_lock_flick_time", "Lock flick time (s)", 0.05, 0.6, 0.01],
	["kl_lock_steer_time", "Lock steer after (s)", 0.05, 0.6, 0.01],
	["kl_lock_chain_radius", "Lock moves on within (px)", 0.0, 400.0, 10.0],
	["kl_lock_break_range", "Lock breaks past (px)", 200.0, 900.0, 10.0],
	["kl_lock_los_grace", "Lock behind rock for (s)", 0.0, 3.0, 0.05],
	["kl_lock_fog_grace", "Lock in deep fog for (s)", 0.0, 5.0, 0.1],
	["kl_lock_lead_max", "Lock lead at most (px)", 0.0, 120.0, 2.0],
	["kl_y_autotarget_deg", "Y auto-target cone (deg)", 0.0, 90.0, 1.0],
	# M1a: fire in the Hollow (GAME_PLAN §4.1, §5, §15)
	["kl_lampfire_dmg", "Lampfire damage (the hit)", 0.0, 10.0, 0.25],
	["kl_lampfire_splash_dmg", "Lampfire splash damage", 0.0, 5.0, 0.25],
	["kl_lampfire_splash", "Lampfire splash (px)", 0.0, 120.0, 2.0],
	["kl_lampfire_period", "Lampfire s per bolt", 0.05, 1.5, 0.01],
	["kl_lampfire_speed", "Lampfire speed (px/s)", 100.0, 1200.0, 10.0],
	["kl_lampfire_range", "Lampfire range (px)", 80.0, 800.0, 10.0],
	["kl_lampfire_charge", "Lampfire charge per hit", 0.0, 0.2, 0.005],
	["kl_lampfire_hit_radius", "Lampfire bolt size (px)", 1.0, 20.0, 1.0],
	["kl_lampfire_pop", "Lampfire light pop (px)", 0.0, 200.0, 4.0],
	["kl_lampfire_pop_clear", "Lampfire pop clears fog", 0.0, 1.0, 0.05],
	["kl_fireglobe_dmg", "Fireglobe damage", 0.0, 30.0, 0.5],
	["kl_fireglobe_radius", "Fireglobe radius (px)", 20.0, 200.0, 5.0],
	["kl_fireglobe_burn_dps", "Burning ground (hp/s)", 0.0, 10.0, 0.25],
	["kl_fireglobe_burn_time", "Burning ground lasts (s)", 0.0, 10.0, 0.25],
	["kl_fireglobe_min", "Fireglobe nearest landing (px)", 40.0, 400.0, 10.0],
	["kl_fireglobe_max", "Fireglobe farthest landing (px)", 60.0, 500.0, 10.0],
	["kl_fireglobe_flight", "Fireglobe flight (s)", 0.1, 2.0, 0.05],
	["kl_fireglobe_arc", "Fireglobe arc height (px)", 0.0, 120.0, 2.0],
	["kl_fireglobe_cost", "Fireglobe charge cost", 0.0, 1.0, 0.05],
	["kl_fireglobe_cd", "Fireglobe cooldown (s)", 0.0, 15.0, 0.25],
	["kl_fireglobe_pop_clear", "Fireglobe burst clears fog", 0.0, 1.0, 0.05],
	["kl_lance_dmg", "Lance damage", 0.0, 20.0, 0.5],
	["kl_lance_pierce", "Lance pierces (foes)", 1.0, 10.0, 1.0],
	["kl_lance_speed", "Lance speed (px/s)", 200.0, 1500.0, 10.0],
	["kl_lance_range", "Lance range (px)", 80.0, 800.0, 10.0],
	["kl_lance_cost", "Lance charge cost", 0.0, 1.0, 0.05],
	["kl_lance_cd", "Lance cooldown (s)", 0.0, 5.0, 0.05],
	["kl_lance_hit_radius", "Lance bolt size (px)", 1.0, 20.0, 1.0],
	["kl_lance_level", "Lance comes at level", 1.0, 12.0, 1.0],
	["kl_bolt_light", "Fire lights the fog (px)", 0.0, 120.0, 4.0],
	["kl_aim_assist_deg", "Pad aim assist (degrees)", 0.0, 45.0, 1.0],
	["kl_aim_hold", "Pad aim hold while firing", 0.0, 1.0, 1.0],
	["kl_autofire_stick", "Auto-fire: stick past", 0.3, 1.0, 0.05],
	["kl_charge_regen", "Charge regen anywhere (/s)", 0.0, 0.5, 0.01],
	["kl_light_charge_hunted", "Charge in light while hunted (/s)", 0.0, 1.0, 0.01],
	["kl_warmth_regen", "Warmth in light, not hunted (/s)", 0.0, 60.0, 1.0],
	["kl_flask_max", "Lamp-oil flasks", 0.0, 5.0, 1.0],
	["kl_flask_heal", "Flask heals (share of warmth)", 0.0, 1.0, 0.05],
	["kl_flask_charge", "Flask gives charge", 0.0, 1.0, 0.05],
	["kl_flask_lockout", "Flask lockout (s)", 0.0, 5.0, 0.1],
	["kl_elite_oil_chance", "Elite oil drop chance", 0.0, 1.0, 0.05],
	["kl_boss_oil_step", "Boss oil at health share", 0.0, 1.0, 0.05],
	["kl_hitstop", "Hit-stop (s)", 0.0, 0.2, 0.005],
	["kl_hitstop_big", "Hit-stop from damage", 0.0, 20.0, 0.5],
	["kl_shake_px", "Screen shake at full (px)", 0.0, 40.0, 1.0],
	["kl_trauma_decay", "Shake decay (/s)", 0.2, 5.0, 0.1],
	["kl_shake_lance_hit", "Shake: Lance hit", 0.0, 1.0, 0.05],
	["kl_shake_lance_cast", "Shake: Lance throw", 0.0, 1.0, 0.01],
	["kl_shake_globe", "Shake: Fireglobe lands", 0.0, 1.0, 0.05],
	["kl_shake_ring", "Shake: Hearth ring", 0.0, 1.0, 0.05],
	["kl_shake_kill", "Shake: a kill", 0.0, 1.0, 0.05],
	["kl_shake_kill_big", "Shake: a big kill", 0.0, 1.0, 0.05],
	["kl_oil_pull", "Oil drop pull (px/s)", 0.0, 600.0, 10.0],
	["kl_pickup_hold", "Hold to pick up a lamp (s)", 0.1, 3.0, 0.05],
	["kl_stick_aim_min", "Pad: stick aims past", 0.05, 0.9, 0.05],
	["kl_stick_tilt_full", "Pad: full stick tilt at", 0.2, 1.0, 0.05],
	# Keeper's Light combat kit (the Beam and Hearth ring are optional skills since M1a)
	["kl_beam_dps", "Beam damage (hp/s)", 1.0, 20.0, 0.5],
	["kl_beam_len", "Beam length (px)", 80.0, 480.0, 10.0],
	["kl_beam_half_width", "Beam half-width (px)", 4.0, 40.0, 1.0],
	["kl_beam_cost", "Beam charge cost (/s)", 0.0, 1.0, 0.05],
	["kl_beam_walk", "Walk speed while beaming", 0.2, 1.0, 0.05],
	["kl_burst_radius", "Hearth ring radius (px)", 40.0, 300.0, 5.0],
	["kl_burst_dmg", "Hearth ring damage", 0.0, 10.0, 0.25],
	["kl_burst_burn_dps", "Hearth ring burn (hp/s)", 0.0, 10.0, 0.25],
	["kl_burst_burn_time", "Hearth ring burn (s)", 0.0, 10.0, 0.25],
	["kl_burst_knock", "Hearth ring push (px)", 0.0, 400.0, 10.0],
	["kl_burst_cd", "Hearth ring cooldown (s)", 0.2, 10.0, 0.1],
	["kl_burst_cost", "Hearth ring charge cost", 0.0, 1.0, 0.05],
	["kl_dash_dist", "Dash distance (px)", 30.0, 300.0, 5.0],
	["kl_dash_cd", "Dash cooldown (s)", 0.1, 5.0, 0.05],
	["kl_dash_cost", "Dash charge cost", 0.0, 0.5, 0.01],
	["hand_lamp_recharge_per_sec", "Lamp recharge in light (/s)", 0.0, 2.0, 0.05],
	["wick_hp", "Wickling hp", 1.0, 20.0, 0.5],
	["kl_elite_hp", "Elite hp", 1.0, 40.0, 0.5],
	["kl_elite_shell", "Elite shell", 0.0, 20.0, 0.5],
	["kl_elite_speed", "Elite speed", 10.0, 160.0, 5.0],
	["kl_shell_regrow_wait", "Shell regrow wait (s)", 0.0, 12.0, 0.25],
	["kl_shell_regrow_per_sec", "Shell regrow speed", 0.0, 5.0, 0.25],
	["kl_spit_period", "Spitwick interval (s)", 0.5, 8.0, 0.1],
	["kl_spit_tell", "Spitwick tell (s)", 0.1, 2.0, 0.1],
	["kl_spit_speed", "Spit speed (px/s)", 40.0, 300.0, 5.0],
	["kl_spitwick_hp", "Spitwick hp", 1.0, 20.0, 0.5],
	["kl_spit_keep_min", "Spitwick closest range", 80.0, 400.0, 5.0],
	["kl_spit_keep_max", "Spitwick farthest range", 100.0, 500.0, 5.0],
	["kl_spit_warmth", "Spit warmth damage", 0.0, 40.0, 1.0],
	["kl_spit_charge", "Spit lamp drain", 0.0, 0.5, 0.01],
	["kl_spit_life", "Spit lifetime (s)", 0.5, 8.0, 0.1],
	["kl_spit_hit_radius", "Spit hit radius", 2.0, 40.0, 1.0],
	["kl_clinker_hp", "Clinker hp", 4.0, 160.0, 1.0],
	["kl_clinker_shell", "Clinker shell", 0.0, 30.0, 1.0],
	["kl_clinker_roll_speed", "Clinker roll speed", 80.0, 500.0, 10.0],
	["kl_clinker_roll_dist", "Clinker roll distance", 80.0, 500.0, 10.0],
	["kl_clinker_roll_tell", "Clinker roll tell (s)", 0.2, 2.0, 0.1],
	["kl_clinker_hit_warmth", "Clinker roll warmth", 0.0, 60.0, 1.0],
	["kl_nest_wake_radius", "Nest wake range (px)", 80.0, 600.0, 10.0],
	["kl_pack_wake_radius", "Pack wake range (px)", 80.0, 600.0, 10.0],
	["kl_post_guard_wake_radius", "Post Lamp guard wake (px)", 32.0, 400.0, 8.0],
	["kl_nest_hatch_count", "Nest Wicklings per hatch", 1.0, 7.0, 1.0],
	["kl_nest_core_dps", "Nest core damage (hp/s)", 0.0, 10.0, 0.25],
	["kl_nest_hatch_sec", "Nest hatch interval (s)", 2.0, 30.0, 0.5],
	["kl_ashbrood_hp", "Ashbrood hp per phase", 5.0, 400.0, 5.0],
	["kl_ashbrood_shell", "Ashbrood shell per phase", 0.0, 40.0, 1.0],
	["kl_ashbrood_puff_period", "Ashbrood puff interval (s)", 2.0, 20.0, 0.5],
	["kl_ashbrood_puff_tell", "Ashbrood puff tell (s)", 0.2, 2.0, 0.1],
	["kl_ashbrood_puff_radius", "Ashbrood puff radius", 40.0, 260.0, 5.0],
	["kl_ashbrood_puff_warmth", "Ashbrood puff warmth", 0.0, 50.0, 1.0],
	["kl_ashbrood_wave_period", "Ashbrood wave interval (s)", 2.0, 20.0, 0.5],
	["kl_ashbrood_dive_period", "Ashbrood dive interval (s)", 2.0, 20.0, 0.5],
	["kl_ashbrood_dive_tell", "Ashbrood dive tell (s)", 0.2, 2.0, 0.1],
	["kl_ashbrood_dive_warmth", "Ashbrood dive warmth", 0.0, 60.0, 1.0],
	["kl_ashbrood_sit_sec", "Ashbrood sits (s)", 1.0, 10.0, 0.5],
	["kl_ashbrood_dive_dist", "Ashbrood dive distance", 40.0, 400.0, 10.0],
	["kl_ashbrood_wave_count", "Ashbrood Wicklings per wave", 1.0, 7.0, 1.0],
	["kl_ashbrood_puff_charge", "Puff leaves lamp charge", 0.0, 1.0, 0.05],
	["kl_focus_shell_mult", "Tight focus shell damage x", 1.0, 3.0, 0.1],
	["kl_linger_duration", "Lingering burn duration (s)", 0.0, 8.0, 0.25],
	["kl_linger_dps", "Lingering burn damage/s", 0.0, 10.0, 0.25],
	["kl_catch_damage", "Catch upgrade damage", 0.0, 10.0, 0.25],
	["kl_wick_base", "Wick curve: base (L1 -> L2)", 1.0, 40.0, 0.5],
	["kl_wick_exp", "Wick curve: exponent", 0.5, 2.5, 0.05],
	["kl_level_cap", "Level cap", 2.0, 20.0, 1.0],
	["kl_wickling_wick", "Wick: Wickling", 0.0, 10.0, 1.0],
	["kl_elite_wick", "Wick: Shelled Wickling", 0.0, 20.0, 1.0],
	["kl_spitwick_wick", "Wick: Spitwick", 0.0, 20.0, 1.0],
	["kl_nest_wick", "Wick: nest", 0.0, 40.0, 1.0],
	["kl_clinker_wick", "Wick: Clinker", 0.0, 80.0, 1.0],
	["kl_ashbrood_wick", "Wick: Ashbrood", 0.0, 150.0, 1.0],
	["kl_wick_kindle", "Wick: kindling a WayLamp", 0.0, 150.0, 1.0],
	["kl_xp_band", "Wick: full up to N levels over a foe", 0.0, 6.0, 1.0],
	["kl_xp_falloff", "Wick: x per level past that", 0.0, 1.0, 0.05],
	["kl_xp_zero_gap", "Wick: none at N levels over", 1.0, 12.0, 1.0],
	["kl_xp_bonus", "Wick: bonus per level under a foe", 0.0, 0.5, 0.05],
	["kl_xp_bonus_max", "Wick: max bonus", 0.0, 1.0, 0.05],
	["kl_xp_level_growth", "Wick: + per foe level", 0.0, 1.0, 0.05],
	["kl_clinker_level", "Clinker level", 1.0, 20.0, 1.0],
	["kl_ashbrood_level", "Ashbrood level", 1.0, 20.0, 1.0],
	# M1b: no more tending (GAME_PLAN §4.6, §6, §12)
	["kl_foe_hp_per_level", "Foe health and shell + a level", 0.0, 0.5, 0.01],
	["kl_dmg_per_level", "Keeper damage + a level", 0.0, 0.5, 0.01],
	["kl_snuff_sec", "Ashbrood dive snuffs a lamp (s)", 0.0, 30.0, 0.5],
	["kl_faint_warmth", "Wake from a faint with warmth x", 0.1, 1.0, 0.05],
	["kl_faint_skip_radius", "Faint: skip lights this near a fight (px)", 0.0, 800.0, 16.0],
	["lamp_upgrade_charge", "Lamp glass: + max charge", 0.0, 0.5, 0.05],
	["kl_ashbrood_add_level", "Ashbrood adds level", 1.0, 20.0, 1.0],
	["warmth_max", "Warmth (health)", 20.0, 300.0, 5.0],
	["kl_timid_share", "Share of timid Wicklings", 0.0, 1.0, 0.05],
	["kl_light_tolerance", "Brave ones last in light (s)", 0.0, 10.0, 0.25],
	["kl_light_burn_dps", "Light burn on brave ones (hp/s)", 0.0, 10.0, 0.25],
	["wick_scrap_chance", "Wickling scrap drop chance", 0.0, 1.0, 0.05],
	# Readability step: telegraphs (ART_DIRECTION §4). Every wind-up timing is here.
	["kl_tell_min", "Tell: shortest warning (s)", 0.1, 2.0, 0.05],
	["kl_tell_commit", "Tell: commit flash (s)", 0.0, 0.5, 0.01],
	["kl_tell_commit_boss", "Tell: boss commit flash (s)", 0.0, 0.5, 0.01],
	["kl_notice_time", "Tell: notice eye flare (s)", 0.0, 1.0, 0.05],
	["kl_tell_gap", "Tell: gap between warnings (s)", 0.0, 1.0, 0.05],
	["kl_tell_budget_radius", "Tell: gap applies within (px)", 0.0, 600.0, 10.0],
	["kl_tell_arrow_range", "Tell: edge arrows within (px)", 200.0, 2000.0, 50.0],
	["kl_wick_latch_tell", "Wickling reach before drain (s)", 0.0, 1.0, 0.05],
	["kl_elite_latch_tell", "Elite reach before drain (s)", 0.0, 1.0, 0.05],
	["kl_spit_aim_lock", "Spitwick aim locks for (s)", 0.0, 1.0, 0.05],
	["kl_spit_onscreen_margin", "Spitwick on-screen margin (px)", 0.0, 128.0, 4.0],
	["kl_nest_hatch_tell", "Nest hatch warning (s)", 0.2, 3.0, 0.1],
	["kl_hatch_fade", "Hatchling fade-in (s)", 0.0, 1.5, 0.05],
	["kl_clinker_wake_time", "Clinker wakes (s)", 0.0, 2.0, 0.05],
	["kl_clinker_recover", "Clinker dizzy after a roll (s)", 0.0, 3.0, 0.05],
	["kl_ashbrood_add_tell", "Ashbrood adds warning (s)", 0.2, 3.0, 0.1],
	["kl_ashbrood_dive_travel", "Ashbrood dive flight (s)", 0.05, 1.5, 0.05],
	["kl_ashbrood_phase_pause", "Ashbrood phase-change pause (s)", 0.0, 5.0, 0.1],
	["kl_ashbrood_hit_radius", "Ashbrood dive landing radius", 16.0, 160.0, 2.0],
	["kl_fx_dash_ghosts", "Dash afterimages", 0.0, 6.0, 1.0],
	["kl_fx_ghost_life", "Dash afterimage life (s)", 0.05, 1.0, 0.01],
	["kl_fx_cast_time", "Cast cue (s)", 0.0, 0.5, 0.01],
	["kl_fx_drink_time", "Drink glow (s)", 0.0, 2.0, 0.05],
	["kl_fx_hurt_time", "Hurt flash (s)", 0.0, 1.0, 0.05],
]

var panel: PanelContainer
var first_slider: HSlider

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(16, 200)   # below the HUD text
	panel.add_theme_stylebox_override("panel", _bg())
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 500)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "Tuning  (F1 / left stick click to close)"
	box.add_child(title)
	for row in ROWS:
		var key: String = row[0]
		var label_text: String = row[1]
		var lbl := Label.new()
		var s := HSlider.new()
		s.min_value = row[2]
		s.max_value = row[3]
		s.step = row[4]
		s.custom_minimum_size = Vector2(280, 22)
		var is_bool: bool = typeof(Tuning.get(key)) == TYPE_BOOL   # a toggle (0 / 1), e.g. the aim hold
		s.value = (1.0 if Tuning.get(key) else 0.0) if is_bool else float(Tuning.get(key))
		lbl.text = "%s: %s" % [label_text, str(Tuning.get(key)) if is_bool else str(snappedf(Tuning.get(key), 0.001))]
		s.value_changed.connect(func(v: float) -> void:
			Tuning.set(key, v >= 0.5 if is_bool else v)
			lbl.text = "%s: %s" % [label_text, str(v >= 0.5) if is_bool else str(snappedf(v, 0.001))])
		box.add_child(lbl)
		box.add_child(s)
		if first_slider == null:
			first_slider = s
	panel.visible = false

static func _bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 0.92)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	return sb

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		panel.visible = not panel.visible
		Tuning.ui_open = panel.visible
		if panel.visible:
			first_slider.grab_focus()
		else:
			get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
