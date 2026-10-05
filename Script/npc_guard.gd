extends Node2D

var conversation: Array[Dictionary] = [
	{
		"speaker": "Guard:",
		"text": "Oops! Asa man imong ID Ga?"
	},
	{
		"speaker": "Student:",
		"text": "Ayy, nakalimot ko ate ba, na-bilin\nsa balay;.Pero naa koy dala Form 1—"
	},
	{
		"speaker": "Guard:",
		"text": ".... Nag LAST WARNING NAMAN KO\nSAIMOHA GAHAPON!!"
	},
	{
		"speaker": "Guard:",
		"text": "Ing ani nalang. Pampunita ang mga\nbasura na maagihan nimo."
	},
	{
		"speaker": "Guard:",
		"text": "Pagkahuman, i-shoot ra sa basurahan!"
	},
	{
		"speaker": "Student:",
		"text": "Aah, kakapuy ana Ate Guard! Ma-late\nnako sa akong klase!"
	},
	{
		"speaker": "Guard:",
		"text": "Hmm... Pili:mamunit kag basura, o\ndili tika pasudlon?"
	},
	{
		"speaker": "Student:",
		"text": "Haysstt. Sige nalang! Basta\nmakasulod lang;;."
	},
	{
		"speaker": "Guard:",
		"text": "Ana ba! Student raba ka sa Yu Em."
	},
	{
		"speaker": "Guard:",
		"text": "Sige na, pagsulod na kay daghan pa\nmangasulod! Wala nay next time, okey?"
	}
]

# Direct path since it's a child node inside this scene:
@onready var dialogue_bubble: Control = $DialogueBubble

#func _ready() -> void:
	#_set_player_movement(false)
	
	#if dialogue_bubble:
		#dialogue_bubble.dialogue_finished.connect(_on_dialogue_finished)
		#await get_tree().create_timer(0.2).timeout
		#dialogue_bubble.start_dialogue(conversation)

func _ready() -> void:
	_set_player_movement(false)
	print("Player frozen. Searching for dialogue_bubble...")
	
	if dialogue_bubble:
		print("Dialogue bubble found! Starting conversation...")
		dialogue_bubble.dialogue_finished.connect(_on_dialogue_finished)
		await get_tree().create_timer(0.2).timeout
		dialogue_bubble.start_dialogue(conversation)
	else:
		print("ERROR: DialogueBubble node is NULL! Unfreezing player.")
		_set_player_movement(true)

func _on_dialogue_finished() -> void:
	_set_player_movement(true)

func _set_player_movement(enabled: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "can_move" in player:
			player.can_move = enabled
		else:
			player.set_physics_process(enabled)
