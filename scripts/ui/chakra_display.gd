extends Node

# References to the container nodes
@onready var chakra_container = null
@onready var chakra_labels = {}

# Flag to track if we're in the battle scene
var in_battle_scene = false
var player_id = "PLAYER1"  # Updated to match BattleStateManager.PlayerId.PLAYER1

func _ready():
    # Connect to scene change signals
    var scene_manager = get_node_or_null("/root/SceneManager")
    if scene_manager:
        scene_manager.connect("scene_changed", _on_scene_changed)
        
        # Check if we're already in battle scene
        in_battle_scene = scene_manager.is_in_battle_scene()
        if in_battle_scene:
            _find_chakra_container()
        
        # Connect to ChakraManager signals
        var chakra_manager = get_node_or_null("/root/ChakraManager")
        if chakra_manager:
            chakra_manager.connect("chakra_updated", _on_chakra_updated)
            chakra_manager.connect("chakra_drawn", _on_chakra_drawn)
            Logger.info("CHAKRA_DISPLAY", "Connected to ChakraManager signals")
        else:
            Logger.warning("CHAKRA_DISPLAY", "ChakraManager singleton not found!")
        
        Logger.info("CHAKRA_DISPLAY", "Initialized for player: " + player_id)
    else:
        Logger.warning("CHAKRA_DISPLAY", "SceneManager not found!")

# Handle scene changes
func _on_scene_changed(scene_path):
    if scene_path == "res://scenes/battle/battle_scene.tscn":
        in_battle_scene = true
        # Short delay to ensure scene is loaded
        get_tree().create_timer(0.2).timeout.connect(_find_chakra_container)
    else:
        in_battle_scene = false
        # Clear references when leaving battle scene
        chakra_container = null
        chakra_labels.clear()

func _find_chakra_container():
    # Only try to find container if we're in battle scene
    if !in_battle_scene:
        return
        
    # Try to find the chakra container in the current scene
    var current_scene = get_tree().current_scene
    chakra_container = current_scene.get_node_or_null("BattleLayout/PlayerHandContainer/HandCards/ChakraContainer")
    
    if chakra_container:
        Logger.info("CHAKRA_DISPLAY", "Found chakra container at: " + str(chakra_container.get_path()))
        _setup_chakra_labels()
    else:
        Logger.warning("CHAKRA_DISPLAY", "Chakra container not found! Available nodes:")
        _print_node_tree(current_scene.get_node_or_null("BattleLayout/PlayerHandContainer/HandCards"), 2)
        # Schedule a retry after a small delay
        get_tree().create_timer(0.5).timeout.connect(_find_chakra_container)

# Helper function to print node tree for debugging
func _print_node_tree(node, depth = 0):
    if depth > 5:  # Limit recursion depth
        return
        
    var indent = ""
    for i in range(depth):
        indent += "  "
        
    for child in node.get_children():
        Logger.info("CHAKRA_DISPLAY", indent + "- " + child.name + " [" + child.get_class() + "]")
        _print_node_tree(child, depth + 1)

func _setup_chakra_labels():
    # Only proceed if we're in battle scene
    if !in_battle_scene or !chakra_container:
        return
        
    # Get references to all chakra type labels
    var chakra_types = get_node("/root/ChakraManager").ChakraType
    
    for type in chakra_types.values():
        var type_name = chakra_types.keys()[type]
        # Convert to title case (first letter capitalized, rest lowercase)
        var container_name = type_name.substr(0, 1) + type_name.substr(1).to_lower() + "Container"
        var label_path = "VBoxContainer/" + container_name + "/Label"
        
        Logger.info("CHAKRA_DISPLAY", "Looking for label at path: " + label_path)
        
        var label = chakra_container.get_node_or_null(label_path)
        if label:
            chakra_labels[type] = label
            Logger.info("CHAKRA_DISPLAY", "Found label for " + type_name)
        else:
            Logger.warning("CHAKRA_DISPLAY", "Label not found at path: " + label_path)
    
    # Initial update of UI
    refresh_display()

func _on_chakra_updated(updated_player_id, chakra_data):
    # Only update if it's for this player and we're in battle scene
    if updated_player_id == player_id and in_battle_scene:
        Logger.info("CHAKRA_DISPLAY", "Chakra updated for player: " + player_id)
        refresh_display()

func _on_chakra_drawn(updated_player_id, new_chakra):
    # Only handle if it's for this player and we're in battle scene
    if updated_player_id == player_id and in_battle_scene:
        Logger.info("CHAKRA_DISPLAY", "New chakra drawn for player: " + player_id)
        _animate_new_chakra(new_chakra)

func _animate_new_chakra(new_chakra):
    # Only proceed if we're in battle scene
    if !in_battle_scene:
        return
        
    # For each new chakra, animate its label
    var chakra_manager = get_node("/root/ChakraManager")
    
    for chakra_type in new_chakra:
        var type_name = chakra_manager.get_type_name(chakra_type)
        Logger.info("CHAKRA_DISPLAY", "Animating new " + type_name + " chakra")
        
        if chakra_labels.has(chakra_type):
            var label = chakra_labels[chakra_type]
            
            # Create a scale animation
            var original_scale = label.scale
            var tween = create_tween()
            tween.tween_property(label, "scale", original_scale * 1.5, 0.2)
            tween.tween_property(label, "scale", original_scale, 0.2)

# Update the display with current chakra values
func refresh_display():
    if !chakra_container:
        Logger.warning("CHAKRA_DISPLAY", "Cannot refresh display - no container found")
        return
        
    var chakra_manager = get_node_or_null("/root/ChakraManager")
    if !chakra_manager:
        Logger.warning("CHAKRA_DISPLAY", "Cannot refresh display - ChakraManager not found")
        return
        
    var chakra_data = chakra_manager.get_all_chakra(player_id)
    if !chakra_data:
        Logger.warning("CHAKRA_DISPLAY", "No chakra data found for player: " + player_id)
        return
        
    Logger.info("CHAKRA_DISPLAY", "Refreshing display with chakra data: " + str(chakra_data))
    
    # Update each label with its corresponding chakra value
    for chakra_type in chakra_labels.keys():
        if !chakra_labels.has(chakra_type) || !chakra_labels[chakra_type]:
            Logger.warning("CHAKRA_DISPLAY", "Label not found for chakra type: " + str(chakra_type))
            continue
            
        var label = chakra_labels[chakra_type]
        var value = chakra_data[chakra_type] if chakra_data.has(chakra_type) else 0
        
        # Format text to show chakra count
        label.text = str(value)
        
        # Add visual feedback for debugging
        if value > 0:
            label.add_theme_color_override("font_color", Color(0, 1, 0))  # Green for positive values
        else:
            label.remove_theme_color_override("font_color")  # Default color for zero
            
        Logger.info("CHAKRA_DISPLAY", "Updated " + str(chakra_manager.get_type_name(chakra_type)) + " label to: " + str(value)) 