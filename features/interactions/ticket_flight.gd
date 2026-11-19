class_name TicketFlight
extends Node2D
## The Cabinet pays out (SLICE beat 9; NARR-001 §5.7 item 3): brass tickets stamped EMBER clatter
## from the wall Cabinet and drift in arcs to the Lantern Tree, where they hang in a cluster.
## Visual only, in RuinsLook's lit stage. 1 ticket = 1 Ember (Q-T148); at most `count` are drawn.

var from := Vector2(74, 206)
var to := Vector2(392, 262)
var count := 0
var flight_s := 1.6
var stagger_s := 0.05
## Seconds since the payout began; < 0 = not started.
var time_s := -1.0
## Reduced motion: tickets are shown at the Tree without the flight.
var instant := false


func play(p_count: int, p_flight_s: float, p_stagger_s: float) -> void:
	count = p_count
	flight_s = maxf(0.01, p_flight_s)
	stagger_s = p_stagger_s
	time_s = 0.0


func _process(delta: float) -> void:
	if time_s >= 0.0:
		time_s += delta
		queue_redraw()


## Where ticket `i` is now and whether it has landed.
func ticket_at(i: int) -> Vector2:
	var k := 1.0 if instant else clampf((time_s - stagger_s * float(i)) / flight_s, 0.0, 1.0)
	var rest := to + Vector2(float((i * 7) % 23) - 11.0, float((i * 5) % 13) - 6.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var p := from.lerp(rest, e)
	p.y -= sin(k * PI) * (60.0 + float(i % 5) * 6.0)
	return p


func _draw() -> void:
	if time_s < 0.0:
		return
	for i in count:
		var started := instant or time_s >= stagger_s * float(i)
		if not started:
			continue
		var p := ticket_at(i)
		var spin := (time_s * 3.0 + float(i)) if not instant else float(i)
		var r := Transform2D(sin(spin) * 0.6, p)
		draw_set_transform_matrix(r)
		draw_rect(Rect2(-3, -1.5, 6, 3), Pal.GAS_3)
		draw_rect(Rect2(-3, -1.5, 6, 3), Pal.GAS_1, false, 0.5)
		draw_line(Vector2(-1.5, 0), Vector2(1.5, 0), Pal.GAS_1, 0.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)
