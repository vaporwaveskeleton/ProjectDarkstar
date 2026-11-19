extends RefCounted
## Frame-time statistics for perf windows (TECH-001 §8.3, §9.1): nearest-rank percentiles over
## per-frame wall-clock times in ms. No class_name: release builds exclude core/automation.


## Returns {frames, mean_ms, p50_ms, p95_ms, p99_ms, max_ms}; all zero for an empty window.
static func summarise(samples_ms: PackedFloat64Array) -> Dictionary:
	var n := samples_ms.size()
	if n == 0:
		return {"frames": 0, "mean_ms": 0.0, "p50_ms": 0.0, "p95_ms": 0.0, "p99_ms": 0.0, "max_ms": 0.0}
	var sorted := samples_ms.duplicate()
	sorted.sort()
	var total := 0.0
	for v in sorted:
		total += v
	return {
		"frames": n,
		"mean_ms": snappedf(total / n, 0.001),
		"p50_ms": snappedf(percentile(sorted, 50.0), 0.001),
		"p95_ms": snappedf(percentile(sorted, 95.0), 0.001),
		"p99_ms": snappedf(percentile(sorted, 99.0), 0.001),
		"max_ms": snappedf(sorted[n - 1], 0.001),
	}


## Nearest-rank percentile of an already sorted array (p in 0..100).
static func percentile(sorted: PackedFloat64Array, p: float) -> float:
	var n := sorted.size()
	if n == 0:
		return 0.0
	var rank := int(ceil(p / 100.0 * n))
	return sorted[clampi(rank - 1, 0, n - 1)]
