class_name ItemEffectHeal extends ItemEffect

@export var heal_amount : int = 1
@export var audio : AudioStream

func use() -> void:
	# Curar al jugador usando el manager central
	if PlayerManager.player:
		PlayerManager.player.update_hp( heal_amount )
	
	# CORRECCIÓN: Reproducir el audio a través del HUD o el Manager de Audio
	# Si tienes un AudioManager global, es mejor usarlo:
	if audio:
		if is_instance_valid(AudioManager):
			AudioManager.play_audio( audio )
		elif is_instance_valid(PlayerHud):
			PlayerHud.play_audio( audio )
