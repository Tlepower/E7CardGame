extends Resource
class_name CardTag
## CardTag - Special tags that modify card behavior
## Tags like Breakout, Lead, Retrieve, Combo, Unusable

# ============================================================================
# TAG TYPES
# ============================================================================

enum TagType {
	NONE = 0,
	BREAKOUT,    # At game start, put this card on top of deck
	LEAD,        # If played as first card in turn, refund 1 mana
	RETRIEVE,    # When discarded, return to hand next turn
	COMBO,       # Gain bonus effect if another card was played this turn
	UNUSABLE,    # Cannot be played (but has special trigger conditions)
	TEMPORARY,   # Card is removed from game after use (not to discard)
	ETHEREAL,    # Disappears at end of turn if not played
	ECHO,        # Copy this card back to hand after playing (once per turn)
	EXHAUST,     # Remove from game after playing
	RETAIN,      # Don't discard at end of turn
	SPARK,       # Costs 0 mana but can only be played once per battle
	CLASH,       # Gain bonus effect if played on same target as previous card
	FINALE,      # Gain bonus effect if this is the last card played in turn
}

# ============================================================================
# TAG PROPERTIES
# ============================================================================

## Type of tag
@export var tag_type: TagType = TagType.NONE

## Tag display name
var tag_name: String = ""

## Tag description
var tag_description: String = ""

## Tag color (for UI)
var tag_color: Color = Color.WHITE

## Additional data for tag (varies by type)
var tag_data: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(type: TagType = TagType.NONE) -> void:
	tag_type = type
	_setup_tag_info()

func _setup_tag_info() -> void:
	match tag_type:
		TagType.BREAKOUT:
			tag_name = "Breakout"
			tag_description = "Starts on top of deck"
			tag_color = Color(1.0, 0.8, 0.0)  # Gold
		
		TagType.LEAD:
			tag_name = "Lead"
			tag_description = "Refund 1 mana if first card played"
			tag_color = Color(0.0, 0.8, 1.0)  # Cyan
		
		TagType.RETRIEVE:
			tag_name = "Retrieve"
			tag_description = "Returns to hand when discarded"
			tag_color = Color(0.6, 1.0, 0.6)  # Light green
		
		TagType.COMBO:
			tag_name = "Combo"
			tag_description = "Bonus effect if card played this turn"
			tag_color = Color(1.0, 0.5, 0.0)  # Orange
		
		TagType.UNUSABLE:
			tag_name = "Unusable"
			tag_description = "Cannot be played normally"
			tag_color = Color(0.5, 0.5, 0.5)  # Gray
		
		TagType.TEMPORARY:
			tag_name = "Temporary"
			tag_description = "Removed after use"
			tag_color = Color(0.8, 0.8, 1.0)  # Light blue
		
		TagType.ETHEREAL:
			tag_name = "Ethereal"
			tag_description = "Disappears at end of turn"
			tag_color = Color(0.7, 0.7, 1.0)  # Purple-ish
		
		TagType.ECHO:
			tag_name = "Echo"
			tag_description = "Copy returns to hand (once/turn)"
			tag_color = Color(1.0, 0.8, 1.0)  # Pink
		
		TagType.EXHAUST:
			tag_name = "Exhaust"
			tag_description = "Removed after playing"
			tag_color = Color(0.6, 0.0, 0.0)  # Dark red
		
		TagType.RETAIN:
			tag_name = "Retain"
			tag_description = "Not discarded at end of turn"
			tag_color = Color(0.0, 1.0, 0.8)  # Teal
		
		TagType.SPARK:
			tag_name = "Spark"
			tag_description = "0 cost, once per battle"
			tag_color = Color(1.0, 1.0, 0.0)  # Yellow
		
		TagType.CLASH:
			tag_name = "Clash"
			tag_description = "Bonus if same target as last card"
			tag_color = Color(1.0, 0.2, 0.2)  # Red
		
		TagType.FINALE:
			tag_name = "Finale"
			tag_description = "Bonus if last card played"
			tag_color = Color(0.8, 0.0, 0.8)  # Purple

# ============================================================================
# TAG QUERIES
# ============================================================================

## Get display string for UI
func get_display_string() -> String:
	return "[%s] %s" % [tag_name, tag_description]

## Clone this tag
func duplicate_tag() -> CardTag:
	var new_tag = CardTag.new(tag_type)
	new_tag.tag_data = tag_data.duplicate()
	return new_tag

# ============================================================================
# TAG BEHAVIOR CHECKS
# ============================================================================

## Check if this tag modifies deck placement
func modifies_deck_placement() -> bool:
	return tag_type == TagType.BREAKOUT

## Check if this tag affects playability
func affects_playability() -> bool:
	return tag_type in [TagType.UNUSABLE, TagType.SPARK]

## Check if this tag triggers on discard
func triggers_on_discard() -> bool:
	return tag_type == TagType.RETRIEVE

## Check if this tag prevents discard
func prevents_discard() -> bool:
	return tag_type == TagType.RETAIN

## Check if this tag removes card from game
func removes_from_game() -> bool:
	return tag_type in [TagType.TEMPORARY, TagType.EXHAUST]

## Check if this tag requires turn timing
func requires_turn_timing() -> bool:
	return tag_type in [TagType.LEAD, TagType.COMBO, TagType.FINALE, TagType.ETHEREAL]
