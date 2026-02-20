extends Resource
class_name CardData
## CardData - Template for creating card instances
## Defines card properties, cost, targeting, and effects

# ============================================================================
# BASIC PROPERTIES
# ============================================================================

## Name of the card
@export var card_name: String = "Card"

## Card description/flavor text
@export_multiline var description: String = ""

## Card type (SKILL or BASIC)
@export var card_type: Enums.CardType = Enums.CardType.BASIC

## Card icon/artwork
@export var icon: Texture2D

## Card frame/background art
@export var frame: Texture2D

# ============================================================================
# COST & PLAYABILITY
# ============================================================================

## Mana cost to play this card (0-5)
@export_range(0, 5) var mana_cost: int = 1

## Is this a Quick Play card? (can be played in response to other cards)
@export var is_quick_play: bool = false

# ============================================================================
# TARGETING
# ============================================================================

## What can this card target?
@export var target_type: Enums.TargetType = Enums.TargetType.SINGLE_ENEMY

# ============================================================================
# EFFECTS
# ============================================================================

## Effects executed when this card is played
@export var effects: Array[Resource] = []  # Array[CardEffect]

## Can this card's effects ignore passives?
@export var ignore_passives: bool = false

## Card tags for card effects
@export var tags: Array[Resource] = [] # Array[Cardtags]

# ============================================================================
# OWNERSHIP (for skill cards)
# ============================================================================

## Name of the unit that owns this skill card (empty for basic cards)
@export var owner_unit_name: String = ""

## Is this a skill card (belongs to a specific unit)?
func is_skill_card() -> bool:
	return not owner_unit_name.is_empty() and card_type == Enums.CardType.SKILL

## Is this a basic card (shared utility cards)?
func is_basic_card() -> bool:
	return owner_unit_name.is_empty() and card_type == Enums.CardType.BASIC

# ============================================================================
# VALIDATION
# ============================================================================

## Validate that this card data is properly configured
func validate() -> bool:
	if card_name.is_empty():
		push_error("CardData: card_name is empty")
		return false
	
	if mana_cost < 0 or mana_cost > 5:
		push_error("CardData '%s': mana_cost out of range (0-5)" % card_name)
		return false
	
	if effects.is_empty():
		push_error("CardData '%s': no effects defined" % card_name)
		return false
	
	# Validate each effect
	for effect in effects:
		if effect == null:
			push_error("CardData '%s': null effect in effects array" % card_name)
			return false
		
		if not effect is CardEffect:
			push_error("CardData '%s': effect is not a CardEffect" % card_name)
			return false
	
	return true

# ============================================================================
# INSTANCE CREATION
# ============================================================================

## Create a runtime Card instance from this template
func create_instance(owner_player: Node) -> Node:
	if not validate():
		push_error("CardData: validation failed, cannot create instance")
		return null
	
	# Load the Card script
	var card_script = load("res://Scripts/Entities/Card/Card.gd")
	var card = Node.new()
	card.set_script(card_script)
	
	# Initialize the card with this data
	card.initialize_from_data(self, owner_player)
	
	return card

# ============================================================================
# UTILITY
# ============================================================================

## Get full description including effects
func get_full_description() -> String:
	var full_desc = description
	
	if not effects.is_empty():
		full_desc += "\n\nEffects:"
		for effect in effects:
			if effect != null and effect.has_method("get_description"):
				full_desc += "\n• " + effect.get_description()
	
	return full_desc

## Get display cost (might be modified by effects)
func get_display_cost() -> int:
	var cost = mana_cost
	
	# Apply cost modifiers from effects
	for effect in effects:
		if effect != null and effect.has_method("get_cost_modifier"):
			cost += effect.get_cost_modifier()
	
	return maxi(0, cost)

## Get all target types used by this card's effects
func get_all_target_types() -> Array[Enums.TargetType]:
	var target_types: Array[Enums.TargetType] = [target_type]
	
	for effect in effects:
		if effect != null and effect.has_method("get") and effect.get("target_type") != null:
			var effect_target = effect.target_type
			if effect_target not in target_types:
				target_types.append(effect_target)
	
	return target_types

## Check if this card is an auto-play card (doesn't need targeting)
func is_auto_target() -> bool:
	return Enums.is_auto_target(target_type)

## Clone this card data
func duplicate_data() -> CardData:
	var new_data = CardData.new()
	
	new_data.card_name = card_name
	new_data.description = description
	new_data.card_type = card_type
	new_data.icon = icon
	new_data.frame = frame
	new_data.mana_cost = mana_cost
	new_data.is_quick_play = is_quick_play
	new_data.target_type = target_type
	new_data.ignore_passives = ignore_passives
	new_data.owner_unit_name = owner_unit_name
	new_data.tags = tags
	
	# Shallow copy effects (they're resources, shared is fine)
	new_data.effects = effects.duplicate()
	
	return new_data

## Get a short display name for UI
func get_display_name() -> String:
	return card_name

## Get card color based on type (for UI)
func get_card_color() -> Color:
	match card_type:
		Enums.CardType.SKILL:
			return Color(0.8, 0.6, 1.0)  # Purple for skill cards
		Enums.CardType.BASIC:
			return Color(0.6, 0.8, 1.0)  # Blue for basic cards
		_:
			return Color.WHITE

## Get rarity/tier (for future expansion)
func get_rarity() -> String:
	# This could be expanded later
	return "Common"

# ===========================================================================
# Tag methods
# ===========================================================================

## Check if card has a specific tag
func has_tag(tag_type: CardTag.TagType) -> bool:
	for tag in tags:
		if tag != null and tag.tag_type == tag_type:
			return true
	return false

## Get tag of specific type
func get_tag(tag_type: CardTag.TagType) -> Resource:
	for tag in tags:
		if tag != null and tag.tag_type == tag_type:
			return tag
	return null

## Add tag to card
func add_tag(tag: Resource) -> void:
	if tag != null and tag not in tags:
		tags.append(tag)

## Remove tag from card
func remove_tag(tag_type: CardTag.TagType) -> void:
	for i in range(tags.size() - 1, -1, -1):
		if tags[i] != null and tags[i].tag_type == tag_type:
			tags.remove_at(i)

## Get all tag display strings
func get_tag_display_strings() -> Array[String]:
	var displays: Array[String] = []
	for tag in tags:
		if tag != null:
			displays.append(tag.get_display_string())
	return displays
