extends Node

# References to the container nodes
@onready var chakra_container = null
@onready var chakra_labels = {}

# Flag to track if we're in the battle scene
var in_battle_scene = false
var player_id = "player"

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
        if get_node("/root/ChakraManager"):
            get_node("/root/ChakraManager").connect("chakra_updated", _on_chakra_updated)
            get_node("/root/ChakraManager").connect("chakra_drawn", _on_chakra_drawn)
        else:
            push_error("ChakraManager singleton not found!")
        
        print("[CHAKRA_DISPLAY] Initialized for player: " + player_id)
    
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
    var battle_overlay = current_scene.get_node_or_null("BattleOverlay")
    
    if battle_overlay:
        chakra_container = battle_overlay.get_node_or_null("OverlayLayout/PlayerHandContainer/ChakraContainer")
        
        if chakra_container:
            print("[CHAKRA_DISPLAY] Found chakra container at: " + str(chakra_container.get_path()))
            _setup_chakra_labels()
        else:
            print("[CHAKRA_DISPLAY] Chakra container not found in BattleOverlay! Available nodes:")
            _print_node_tree(battle_overlay, 2)
            push_error("Chakra container not found in BattleOverlay!")
    else:
        # If not found, try a different approach or wait for scene to be ready
        print("[CHAKRA_DISPLAY] BattleOverlay not found, will try again later")
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
        print(indent + "- " + child.name + " [" + child.get_class() + "]")
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
        
        print("[CHAKRA_DISPLAY] Looking for label at path: " + label_path)
        
        var label = chakra_container.get_node_or_null(label_path)
        if label:
            chakra_labels[type] = label
            print("[CHAKRA_DISPLAY] Found label for " + type_name)
        else:
            # Try alternate approaches to find the label
            print("[CHAKRA_DISPLAY] Label not found at path: " + label_path)
            print("[CHAKRA_DISPLAY] Available nodes in chakra container:")
            _print_node_tree(chakra_container, 1)
            
            # Try direct search
            label = _find_label_by_partial_name(chakra_container, type_name.to_lower())
            if label:
                chakra_labels[type] = label
                print("[CHAKRA_DISPLAY] Found label for " + type_name + " using direct search")
            else:
                push_error("Label for " + type_name + " not found")
    
    # Initial update of UI
    refresh_display()

# Helper function to find a label by partial name match
func _find_label_by_partial_name(parent_node, partial_name):
    for child in parent_node.get_children():
        if child is Label and partial_name.to_lower() in child.name.to_lower():
            return child
        
        if child.get_child_count() > 0:
            var result = _find_label_by_partial_name(child, partial_name)
            if result:
                return result
    
    return null

func _on_chakra_updated(updated_player_id, chakra_data):
    # Only update if it's for this player and we're in battle scene
    if updated_player_id == player_id and in_battle_scene:
        print("[CHAKRA_DISPLAY] Chakra updated for player: " + player_id)
        refresh_display()

func _on_chakra_drawn(updated_player_id, new_chakra):
    # Only handle if it's for this player and we're in battle scene
    if updated_player_id == player_id and in_battle_scene:
        print("[CHAKRA_DISPLAY] New chakra drawn for player: " + player_id)
        
        # Could add animations or highlights for newly drawn chakra
        _animate_new_chakra(new_chakra)

func _animate_new_chakra(new_chakra):
    # Only proceed if we're in battle scene
    if !in_battle_scene:
        return
        
    # For each new chakra, animate its label
    var chakra_manager = get_node("/root/ChakraManager")
    
    for chakra_type in new_chakra:
        var type_name = chakra_manager.get_type_name(chakra_type)
        print("[CHAKRA_DISPLAY] Animating new " + type_name + " chakra")
        
        if chakra_labels.has(chakra_type):
            var label = chakra_labels[chakra_type]
            
            # Create a scale animation
            var original_scale = label.scale
            var tween = create_tween()
            tween.tween_property(label, "scale", original_scale * 1.5, 0.2)
            tween.tween_property(label, "scale", original_scale, 0.2)

func refresh_display():
    # Only proceed if we're in battle scene
    if !in_battle_scene:
        return
        
    # Get current chakra data from manager
    var chakra_manager = get_node("/root/ChakraManager")
    if not chakra_manager:
        push_error("ChakraManager not found!")
        return
    
    var chakra_data = chakra_manager.get_all_chakra(player_id)
    
    # Update labels for each chakra type
    for type in chakra_data.keys():
        if chakra_labels.has(type):
            var count = chakra_data[type]
            chakra_labels[type].text = "x " + str(count)
            print("[CHAKRA_DISPLAY] Updated " + chakra_manager.get_type_name(type) + " display to: x " + str(count))
        else:
            print("[CHAKRA_DISPLAY] No label found for type: " + str(type)) 