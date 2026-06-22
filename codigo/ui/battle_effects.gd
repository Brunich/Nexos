## BattleEffects — Efectos visuales de batalla (flashes, sacudidas, wobble de Ofrenda).
## Adjunto al nodo BattleEffects en battle_scene.tscn.
## Todos los métodos públicos son async para poder ser awaited desde BattleScene.
extends Node
class_name BattleEffects

# ─────────────────────────────────────────────────────────────────────────────

## Parpadeo rápido de la pantalla (ej. al recibir daño o lanzar una Ofrenda).
## overlay debe ser el ColorRect ScreenOverlay de BattleScene.
func flash_screen(overlay: ColorRect, color: Color = Color(1, 1, 1, 0.6), duration: float = 0.12) -> void:
	if overlay == null:
		return
	overlay.color   = color
	overlay.visible = true
	await get_tree().create_timer(duration).timeout
	overlay.visible = false

## Sacudida horizontal de un sprite (daño recibido).
func shake_sprite(sprite: Node2D, intensity: float = 6.0, duration: float = 0.3) -> void:
	if sprite == null:
		return
	var origin  := sprite.position
	var elapsed := 0.0
	while elapsed < duration:
		var d : float = await _wait_frame()
		elapsed += d
		var t   := elapsed / duration
		var sin_v := sin(t * TAU * 6.0)
		sprite.position = origin + Vector2(sin_v * intensity * (1.0 - t), 0.0)
	sprite.position = origin

## Animación de wobble de Ofrenda al intentar el vínculo.
## n_wobbles: 1 = falla clara, 2-3 = casi, 4 = éxito garantizado.
## sprite es el Sprite2D que representa la Ofrenda/Cápsula en pantalla.
func play_catch_wobble(sprite: Node2D, n_wobbles: int) -> void:
	if sprite == null:
		return
	var origin := sprite.position
	var clamps : int = clamp(n_wobbles, 1, 4)
	var angle   := 18.0  # grados máximos de inclinación
	for i in clamps:
		# Izquierda
		var t := 0.0
		while t < 1.0:
			var d := await _wait_frame()
			t = minf(t + d / 0.12, 1.0)
			sprite.rotation_degrees = -angle * sin(t * PI)
		# Derecha
		t = 0.0
		while t < 1.0:
			var d := await _wait_frame()
			t = minf(t + d / 0.12, 1.0)
			sprite.rotation_degrees = angle * sin(t * PI)
	sprite.rotation_degrees = 0.0
	sprite.position = origin

## Barra de HP que baja animada (interpola de current a target en duration segundos).
## hp_bar debe ser un ProgressBar.
func animate_hp_bar(hp_bar: ProgressBar, target_val: float, duration: float = 0.35) -> void:
	if hp_bar == null:
		return
	var start_val := hp_bar.value
	var elapsed   := 0.0
	while elapsed < duration:
		var d := await _wait_frame()
		elapsed  = minf(elapsed + d, duration)
		hp_bar.value = lerp(start_val, target_val, elapsed / duration)
	hp_bar.value = target_val

## Barra de EXP que sube animada.
func animate_exp_bar(exp_bar: ProgressBar, target_val: float, duration: float = 0.45) -> void:
	if exp_bar == null:
		return
	var start_val := exp_bar.value
	var elapsed   := 0.0
	while elapsed < duration:
		var d := await _wait_frame()
		elapsed  = minf(elapsed + d, duration)
		exp_bar.value = lerp(start_val, target_val, elapsed / duration)
	exp_bar.value = target_val

# ── Utilidad interna ──────────────────────────────────────────────────────────
func _wait_frame() -> float:
	await get_tree().process_frame
	return get_process_delta_time()
