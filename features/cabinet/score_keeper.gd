class_name ScoreKeeper
extends RefCounted
## Act 0 score and lives: the 1983 table (SYS-001 §7.1) and its extra-life rule (PM Q-T107,
## 2026-11-19: at 10,000, then 30,000, then every +40,000 — 70k, 110k … — cap 5). Pure and
## testable; the HUD listens to its signals.

signal score_changed(score: int)
signal lives_changed(lives: int)
signal extra_life_awarded

var score := 0
var lives := 3
var _next_extra := 0
var _extras_passed := 0      ## thresholds crossed so far (picks second vs every)
var _tuning: CabinetTuning


func _init(tuning: CabinetTuning) -> void:
	_tuning = tuning
	lives = tuning.lives_start
	_next_extra = tuning.extra_life_first
	_extras_passed = 0


## Back to a new game: score 0, the starting lives, the first extra-life threshold (CONTINUE, Q-T104c).
func reset() -> void:
	score = 0
	lives = _tuning.lives_start
	_next_extra = _tuning.extra_life_first
	_extras_passed = 0
	score_changed.emit(score)
	lives_changed.emit(lives)


## The score at which the next extra Vigil is awarded.
func next_extra_at() -> int:
	return _next_extra


func add(points: int) -> void:
	if points <= 0:
		return
	score += points
	score_changed.emit(score)
	while score >= _next_extra:
		_advance_threshold()
		if lives < _tuning.lives_cap:
			lives += 1
			lives_changed.emit(lives)
			extra_life_awarded.emit()


## first → second → second + every → … (a second threshold at or below the first is skipped).
func _advance_threshold() -> void:
	_extras_passed += 1
	if _extras_passed == 1 and _tuning.extra_life_second > _next_extra:
		_next_extra = _tuning.extra_life_second
	else:
		_next_extra += maxi(1, _tuning.extra_life_every)


## Spend a life. Returns false when none are left (game over).
func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(maxi(0, lives))
	return lives > 0
