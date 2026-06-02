extends Node
class_name Gear

# variables

@export var Name: String = ""
var Level: int = 1
var Tier: int = 1
var MainStatName: Enums.StatType = Enums.StatType.BASE_ATK
var MainStat: int
var SubStat: Dictionary[String,Array]
var GearSet: Enums.GearSet
var Owner: Unit

# funtions

func initialize(name: String, mainstatname: String, mainstat: int, gearset: Enums.GearSet) -> void:
	pass
	
func Getname() -> String:
	return ""

func Setname(nam: String) -> void:
	Name = nam
	 
func GetTier() -> int:
	return Tier
	
func Getlevel() -> int:
	return 1
	
func Inceaselevel(add: int) -> void:
	pass
	
func _UpdateSubStat() -> void:
	pass
	
func GetMainStats() -> int:
	return MainStat
	
func GetSubStats() -> Dictionary:
	return SubStat
	
func equip(Unit) -> void:
	pass
	
func unequip() -> void:
	pass
	 
func _UpdateMainStat() -> void:
	pass
