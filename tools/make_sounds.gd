extends SceneTree
## 0.13+ sound pass, drawn in code (original to Solaria, CC0): room ambience loops by
## region and small sounds for the new moments (loot landing, doors, traps, entering a room).
## godot --headless --path . -s tools/make_sounds.gd
const SR := 22050
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	rng.seed = 13
	save("amb_forest", loop(forest(9.0), 1.0), 0.8)
	save("amb_crypt", loop(crypt(9.0), 1.0), 0.8)
	save("amb_water", loop(water(9.0), 1.0), 0.8)
	save("amb_fire", loop(fire(9.0), 1.0), 0.8)
	save("amb_void", loop(void_hum(9.0), 1.0), 0.8)
	save("drop", drop(), 0.8)
	save("door", door(), 0.85)
	save("trap", trap(), 0.85)
	save("whoosh", whoosh(), 0.7)
	print("SOUNDS DONE")
	quit()

# ---------------------------------------------------------------- building blocks

func buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * SR))
	return b

func noise(sec: float) -> PackedFloat32Array:
	var b := buf(sec)
	for i in b.size():
		b[i] = rng.randf_range(-1.0, 1.0)
	return b

## One-pole low-pass (cutoff in Hz).
func lp(x: PackedFloat32Array, hz: float) -> PackedFloat32Array:
	var a := 1.0 - exp(-TAU * hz / SR)
	var y := x.duplicate()
	var s := 0.0
	for i in y.size():
		s += a * (x[i] - s)
		y[i] = s
	return y

func hp(x: PackedFloat32Array, hz: float) -> PackedFloat32Array:
	var l := lp(x, hz)
	var y := x.duplicate()
	for i in y.size():
		y[i] = x[i] - l[i]
	return y

func bp(x: PackedFloat32Array, lo: float, hi: float) -> PackedFloat32Array:
	return lp(hp(x, lo), hi)

## Adds `src` into `dst` at `at` seconds (clipped to dst).
func add(dst: PackedFloat32Array, src: PackedFloat32Array, at: float, gain := 1.0) -> void:
	var o := int(at * SR)
	for i in src.size():
		var j := o + i
		if j >= 0 and j < dst.size():
			dst[j] += src[i] * gain

## A short tone gliding f0 -> f1 with a sharp attack and exponential decay.
func ping(f0: float, f1: float, sec: float, decay: float, wave := "sine") -> PackedFloat32Array:
	var b := buf(sec)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / b.size()
		ph += lerpf(f0, f1, t) / SR
		var x := fmod(ph, 1.0)
		var s := sin(x * TAU) if wave == "sine" else 1.0 - 4.0 * absf(x - 0.5)
		b[i] = s * minf(1.0, i / (SR * 0.002)) * exp(-float(i) / SR / decay)
	return b

func burst(sec: float, lo: float, hi: float, decay: float) -> PackedFloat32Array:
	var b := bp(noise(sec), lo, hi)
	for i in b.size():
		b[i] *= exp(-float(i) / SR / decay)
	return b

## Simple echo/reverb: a few feedback delays.
func verb(x: PackedFloat32Array, wet: float, tail: float) -> PackedFloat32Array:
	var y := x.duplicate()
	y.resize(x.size() + int(tail * SR))
	for k in [0.029, 0.037, 0.053, 0.071]:
		var d := int(float(k) * SR)
		var g := 0.55
		for i in range(d, y.size()):
			y[i] += y[i - d] * g * wet * 0.5
	return y

## Makes a seamless loop: the last `fade` seconds crossfade into the start.
func loop(x: PackedFloat32Array, fade: float) -> PackedFloat32Array:
	var f := int(fade * SR)
	var n := x.size() - f
	var y := x.slice(0, n)
	for i in f:
		var t := float(i) / f
		y[i] = x[i] * t + x[n + i] * (1.0 - t)
	return y

func save(name: String, x: PackedFloat32Array, peak: float) -> void:
	var m := 0.0001
	for v in x:
		m = maxf(m, absf(v))
	var data := PackedByteArray()
	data.resize(x.size() * 2)
	for i in x.size():
		data.encode_s16(i * 2, int(clampf(x[i] / m * peak, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	w.save_to_wav("res://sounds/%s.wav" % name)

# ---------------------------------------------------------------- ambience

## Wind through leaves, crickets, the odd rustle.
func forest(sec: float) -> PackedFloat32Array:
	var wind := lp(noise(sec), 500.0)
	for i in wind.size():
		var t := float(i) / SR
		wind[i] *= 0.6 + 0.4 * sin(t * TAU / 4.5) * sin(t * TAU / 2.9 + 1.0)
	var out := buf(sec)
	add(out, wind, 0.0, 0.9)
	var t := 0.2
	while t < sec:
		for k in rng.randi_range(2, 4):  # a cricket's trill: a few quick chirps
			add(out, ping(4300, 4200, 0.03, 0.012), t + k * 0.06, 0.12)
		t += rng.randf_range(0.5, 1.4)
	for k in 4:
		add(out, burst(0.4, 1500, 5000, 0.12), rng.randf_range(0, sec - 0.5), 0.25)
	return out

## Low stone drone, slow air, distant drips.
func crypt(sec: float) -> PackedFloat32Array:
	var out := lp(noise(sec), 180.0)
	for i in out.size():
		var t := float(i) / SR
		out[i] = out[i] * 1.6 + 0.10 * sin(TAU * 55.0 * t) * (0.7 + 0.3 * sin(t * TAU / 6.0)) + 0.06 * sin(TAU * 82.6 * t)
	for k in 5:
		add(out, verb(ping(1700, 900, 0.12, 0.03), 0.9, 0.6), rng.randf_range(0, sec - 0.8), 0.18)
	return out

## Running water and many drips.
func water(sec: float) -> PackedFloat32Array:
	var stream := bp(noise(sec), 300.0, 1400.0)
	for i in stream.size():
		var t := float(i) / SR
		stream[i] *= 0.7 + 0.3 * sin(t * TAU * 0.7) * sin(t * TAU * 1.3)
	var out := buf(sec)
	add(out, stream, 0.0, 0.6)
	for k in 14:
		var f := rng.randf_range(1200, 2400)
		add(out, verb(ping(f, f * 0.55, 0.1, 0.025), 0.7, 0.4), rng.randf_range(0, sec - 0.6), rng.randf_range(0.15, 0.3))
	return out

## Fire crackle over a low rumble.
func fire(sec: float) -> PackedFloat32Array:
	var out := lp(noise(sec), 120.0)
	for i in out.size():
		out[i] *= 2.2
	var t := 0.0
	while t < sec:
		add(out, burst(0.02, 1500, 7000, 0.004), t, rng.randf_range(0.2, 0.8))
		t += rng.randf_range(0.03, 0.35)
	add(out, lp(noise(sec), 900.0), 0.0, 0.25)
	return out

## Shimmering detuned tones and a whisper of moving air.
func void_hum(sec: float) -> PackedFloat32Array:
	var out := buf(sec)
	var air := bp(noise(sec), 600.0, 2200.0)
	for i in out.size():
		var t := float(i) / SR
		var shimmer := sin(TAU * 220.0 * t) + 0.7 * sin(TAU * 221.3 * t) + 0.4 * sin(TAU * 330.9 * t) + 0.25 * sin(TAU * 440.0 * t + sin(t * 0.9) * 2.0)
		out[i] = shimmer * 0.06 * (0.6 + 0.4 * sin(t * TAU / 3.0)) + air[i] * 0.35 * (0.5 + 0.5 * sin(t * TAU / 4.5))
	return out

# ---------------------------------------------------------------- moments

## Loot landing: a metal clink and a smaller bounce.
func drop() -> PackedFloat32Array:
	var out := buf(0.5)
	add(out, ping(2600, 2500, 0.25, 0.06), 0.0, 0.5)
	add(out, ping(3900, 3800, 0.2, 0.04), 0.0, 0.3)
	add(out, burst(0.03, 2000, 8000, 0.006), 0.0, 0.5)
	add(out, ping(2600, 2500, 0.15, 0.03), 0.16, 0.25)
	return verb(out, 0.6, 0.3)

## A heavy wooden door: a creak and a thud.
func door() -> PackedFloat32Array:
	var out := buf(0.9)
	var creak := buf(0.5)
	var ph := 0.0
	for i in creak.size():
		var t := float(i) / creak.size()
		ph += lerpf(180, 260, t) / SR
		var pulse := 1.0 if fmod(ph, 1.0) < 0.12 else 0.0  # a stick-slip buzz
		creak[i] = pulse * sin(t * PI)
	add(out, bp(creak, 300, 2500), 0.0, 0.8)
	add(out, lp(ping(90, 50, 0.4, 0.1), 400), 0.45, 1.0)
	add(out, burst(0.1, 80, 600, 0.03), 0.45, 0.6)
	return verb(out, 0.7, 0.5)

## A trap springing: a snap and a metal ring.
func trap() -> PackedFloat32Array:
	var out := buf(0.6)
	add(out, burst(0.05, 1000, 9000, 0.01), 0.0, 1.0)
	add(out, ping(140, 70, 0.2, 0.05), 0.0, 0.8)
	add(out, ping(1800, 1750, 0.5, 0.12), 0.01, 0.25)
	return verb(out, 0.5, 0.3)

## Stepping into a new room: a soft rising rush of air.
func whoosh() -> PackedFloat32Array:
	var n := noise(0.6)
	var out := buf(0.6)
	var s := 0.0
	for i in n.size():
		var t := float(i) / n.size()
		var a := 1.0 - exp(-TAU * lerpf(300, 2500, t) / SR)
		s += a * (n[i] - s)
		out[i] = s * sin(t * PI)
	return out
