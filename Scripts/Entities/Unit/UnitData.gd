extends Resource
class_name UnitData
## UnitData - Template/definition for a unit (like a unit card in your collection)
## Used to create Unit instances in battle

# ============================================================================
# BASIC INFO
# ============================================================================

## Display name of the unit
@export var unit_name: String = "Unit"

## Unit description/lore
@export_multiline var description: String = ""

## Portrait image for UI
@export var portrait: Texture2D

## Full sprite/model for battle scene
@export var battle_sprite: Texture2D

## Rarity or class (for future use)
@export_enum("Common", "Rare", "Epic", "Legendary") var rarity: String = "Common"

## Types (for future use)
@export_enum("Fire","Water","G","Light","Dark") var Type: String = "Fire"

# ============================================================================
# STATS
# ============================================================================

## Base statistics for this unit
@export var base_stats: UnitStats

# ============================================================================
# ABILITIES
# ============================================================================

## Passive ability (can be trigger-based, aura, or both)
@export var passive_script: Script  # Must extend Passive class

## Skill 1 card data (first skill card)
@export var skill1_card_data: Resource  # CardData

## Skill 2 card data (second skill card)
@export var skill2_card_data: Resource  # CardData

## Ultimate ability data
@export var ultimate_data: UltimateData

## Basic attack data
@export var basic_attack_data: BasicAttackData

# ============================================================================
# VALIDATION
# ============================================================================

## Validate that all required data is present
func validate() -> bool:
	if unit_name.is_empty():
		push_error("UnitData: unit_name is empty")
		return false
	
	if base_stats == null:
		push_error("UnitData '%s': base_stats is null" % unit_name)
		return false
	
	if skill1_card_data == null:
		push_error("UnitData '%s': skill1_card_data is null" % unit_name)
		return false
	
	if skill2_card_data == null:
		push_error("UnitData '%s': skill2_card_data is null" % unit_name)
		return false
	
	if ultimate_data == null:
		push_error("UnitData '%s': ultimate_data is null" % unit_name)
		return false
	
	if basic_attack_data == null:
		push_error("UnitData '%s': basic_attack_data is null" % unit_name)
		return false
	
	# Passive is optional, but if provided should be valid
	if passive_script != null and not passive_script.can_instantiate():
		push_error("UnitData '%s': passive_script cannot be instantiated" % unit_name)
		return false
	
	return true

# ============================================================================
# INSTANCE CREATION
# ============================================================================

## Create a runtime Unit instance from this template
func create_instance(team: Enums.Team) -> Node:
	if not validate():
		push_error("UnitData: validation failed, cannot create instance")
		return null
	
	# Load the Unit scene/script
	var unit_script = load("res://Scripts/Entities/Unit/Unit.gd")
	var unit = Node.new()
	unit.set_script(unit_script)
	
	# Initialize the unit with this data
	unit.initialize_from_data(self, team)
	
	return unit

# ============================================================================
# UTILITY
# ============================================================================

## Get all skill card datas as an array
func get_skill_cards() -> Array[Resource]:
	var skills: Array[Resource] = []
	if skill1_card_data != null:
		skills.append(skill1_card_data)
	if skill2_card_data != null:
		skills.append(skill2_card_data)
	return skills

## Create a copy of this UnitData
func duplicate_data() -> UnitData:
	var new_data = UnitData.new()
	
	new_data.unit_name = unit_name
	new_data.description = description
	new_data.portrait = portrait
	new_data.battle_sprite = battle_sprite
	new_data.rarity = rarity
	
	# Deep copy stats
	if base_stats != null:
		new_data.base_stats = base_stats.duplicate_stats()
	
	# Copy resource references (these are templates, shared is fine)
	new_data.passive_script = passive_script
	new_data.skill1_card_data = skill1_card_data
	new_data.skill2_card_data = skill2_card_data
	new_data.ultimate_data = ultimate_data
	new_data.basic_attack_data = basic_attack_data
	
	return new_data
