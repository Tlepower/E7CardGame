extends Node
## Enums - Global type definitions for type safety across the game
## This is an autoload singleton

# ============================================================================
# TURN SYSTEM
# ============================================================================

enum TurnPhase {
	START,    ## Turn start phase - status effects tick, AR resets, draw card
	MAIN,     ## Main phase - play cards, use abilities
	END       ## End phase - cleanup, control effects tick
}

# ============================================================================
# TEAM & PLAYER
# ============================================================================

enum Team {
	PLAYER,   ## Player's team (bottom of screen typically)
	ENEMY     ## Enemy team (top of screen typically)
}

# ============================================================================
# CARD SYSTEM
# ============================================================================

enum CardType {
	SKILL,    ## Unit skill cards (2 per unit)
	BASIC,    ## Basic utility cards (8 in deck)
	ULTIMATE  ## Not actually a card, but used for categorization
}

## Determines which targets are valid for a card/ability
enum TargetType {
	SINGLE_ENEMY,      ## One enemy unit
	SINGLE_ALLY,       ## One ally unit (including self)
	ALL_ENEMIES,       ## All enemy units
	ALL_ALLIES,        ## All ally units
	ALL_UNITS,         ## All units on battlefield
	RANDOM_ENEMY,      ## Random enemy (AI selects)
	RANDOM_ALLY,       ## Random ally (AI selects)
	SELF,              ## Only the caster
	OTHER_ALLIES,      ## All allies except self
	LOWEST_HP_ENEMY,   ## Enemy with lowest HP (auto-target)
	HIGHEST_HP_ENEMY,  ## Enemy with highest HP (auto-target)
	LOWEST_HP_ALLY,    ## Ally with lowest HP (auto-target)
	HIGHEST_HP_ALLY    ## Ally with highest HP (auto-target)
}

# ============================================================================
# STATUS EFFECTS
# ============================================================================
## Elemental types for interesting matchup and drafting
enum ElementType {
	SCARLET, ## its the red element
	AZURE,   ## its the blue element
	JADE,    ## its the green element
	GOLD,    ## its the light element
	ONYX,    ## its the dark element
	BLANK,   ## no element at all
}

enum StatusEffectType {
	BUFF,       ## Positive effect (can be dispelled)
	DEBUFF,     ## Negative effect (can be cleansed)
	CONTROL,    ## Control effect (stun, taunt, etc.) - special cleanse
	DOT,        ## Damage over time (bleed, burn, poison)
	SHIELD,     ## Barrier/shield effect
	IMMUNITY,   ## Prevents debuffs
	INVINCIBILITY, ## Prevents damage
	BLOCK,      ## Prevents buffs
	ANTIHEAL,   ## Prevents Healing
	UNIQUE      ## Special effects that don't fit categories
}

## How status effects stack with themselves
enum StackType {
	NO_STACK,       ## Cannot stack, refresh duration instead
	STACK_COUNT,    ## Stack count increases (e.g., bleed stacks)
	STACK_DURATION, ## Duration stacks (each application adds to duration)
	INDEPENDENT     ## Each application is independent
}

# ============================================================================
# DAMAGE TYPES
# ============================================================================

enum DamageType {
	PHYSICAL,  ## Reduced by DEF
	MAGICAL,   ## Reduced by DEF (could add separate Magic DEF later)
	TRUE       ## Ignores DEF completely
}

# ============================================================================
# CONTROL TYPES
# ============================================================================

enum ControlType {
	STUN,           ## Cannot act, cannot trigger out-of-turn actions
	FREEZE,         ## Cannot act, may have other effects (take more dmg, etc.)
	SLEEP,          ## Cannot act, wakes on damage
	TAUNT,          ## Must target taunter
	PROVOKE,        ## Forces single target abilities on them
	SILENCE,        ## Cannot use skills (passives still work)
	RESTRICT,       ## Cannot use ultimates specifically
	SUPPRESS        ## Cannot use trigger passives
}

# ============================================================================
# BATTLE STATE
# ============================================================================

enum BattleState {
	SETUP,          ## Initializing battle
	STARTING_HAND,  ## Drawing starting hands
	ONGOING,        ## Battle in progress
	QUICK_PLAY,     ## Quick play window active
	RESOLVING,      ## Resolving effect stack
	ENDED           ## Battle complete
}

# ============================================================================
# AI DIFFICULTY
# ============================================================================

enum AIDifficulty {
	EASY,      ## Makes suboptimal plays
	NORMAL,    ## Reasonable decision making
	HARD,      ## Optimal plays with some randomness
	EXPERT     ## Perfect plays
}

# ============================================================================
# ANIMATION STATES
# ============================================================================

enum AnimationState {
	IDLE,
	ATTACKING,
	SKILL_CASTING,
	ULTIMATE_CASTING,
	TAKING_DAMAGE,
	HEALING,
	DYING,
	VICTORY
}

# ============================================================================
# STAT TYPES
# ============================================================================

enum StatType {
	MAX_HP,
	CURRENT_HP,
	BASE_ATK,
	BASE_DEF,
	SPEED,
	CRIT_RATE,
	CRIT_DAMAGE,
	COUNTER_RATE,
	EVASION,
	EFFECTIVENESS,      ## For applying debuffs
	EFFECT_RESISTANCE,  ## For resisting debuffs
	ATK_PERCENT,        ## Multiplicative ATK modifier
	DEF_PERCENT,        ## Multiplicative DEF modifier
	SPEED_PERCENT       ## Multiplicative Speed modifier
}

# ============================================================================
# PASSIVE TYPES
# ============================================================================

enum PassiveType {
	TRIGGER,      ## Activates on specific events
	AURA,         ## Continuous effect (stat boost, etc.)
	CONDITIONAL,  ## Active only under conditions
	MANDATORY     ## Cannot be prevented/ignored, interrupts effects
}

# ============================================================================
# TRIGGER CONDITIONS (for passives and effects)
# ============================================================================

enum TriggerCondition {
	ON_TURN_START,
	ON_TURN_END,
	ON_ATTACK,
	ON_ATTACKED,
	ON_SKILL_USE,
	ON_ULTIMATE_USE,
	ON_DAMAGE_DEALT,
	ON_DAMAGE_TAKEN,
	ON_HEAL,
	ON_ALLY_DEATH,
	ON_ENEMY_DEATH,
	ON_BUFF_APPLIED,
	ON_DEBUFF_APPLIED,
	ON_HP_THRESHOLD,      ## Below X% HP
	ON_CRIT,
	ON_KILL,
	ON_MISS,
	ON_COUNTER,
	ON_BATTLE_START
}

# ============================================================================
# Gear Set 
# ============================================================================
enum GearSet {
	ATK_SET,
	DEF_SET,
	SPD_SET,
	WIND_SET,
	HP_SET,
	COUNTER_SET,
	IMMUNITY_SET,
	CRIT_SET,
	STRIVE_SET,
	FOLLOWUP_SET,
	TIMEWAVE_SET,
	LIFESTEAL_SET,
	HEAL_SET,
	HIT_SET,
	EFF_RATE_SET,
	EFF_RES_SET
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Convert Team enum to string
static func team_to_string(team: Team) -> String:
	match team:
		Team.PLAYER:
			return "Player"
		Team.ENEMY:
			return "Enemy"
		_:
			return "Unknown"

## Convert TurnPhase enum to string
static func phase_to_string(phase: TurnPhase) -> String:
	match phase:
		TurnPhase.START:
			return "Start Phase"
		TurnPhase.MAIN:
			return "Main Phase"
		TurnPhase.END:
			return "End Phase"
		_:
			return "Unknown Phase"

## Convert TargetType enum to readable string
static func target_type_to_string(target_type: TargetType) -> String:
	match target_type:
		TargetType.SINGLE_ENEMY:
			return "Single Enemy"
		TargetType.SINGLE_ALLY:
			return "Single Ally"
		TargetType.ALL_ENEMIES:
			return "All Enemies"
		TargetType.ALL_ALLIES:
			return "All Allies"
		TargetType.ALL_UNITS:
			return "All Units"
		TargetType.SELF:
			return "Self"
		TargetType.LOWEST_HP_ENEMY:
			return "Lowest HP Enemy"
		_:
			return "Unknown Target"

## Check if a target type is multi-target
static func is_multi_target(target_type: TargetType) -> bool:
	return target_type in [
		TargetType.ALL_ENEMIES,
		TargetType.ALL_ALLIES,
		TargetType.ALL_UNITS,
		TargetType.OTHER_ALLIES
	]

## Check if target type is auto-selected (doesn't need player input)
static func is_auto_target(target_type: TargetType) -> bool:
	return target_type in [
		TargetType.SELF,
		TargetType.RANDOM_ENEMY,
		TargetType.RANDOM_ALLY,
		TargetType.LOWEST_HP_ENEMY,
		TargetType.HIGHEST_HP_ENEMY,
		TargetType.LOWEST_HP_ALLY,
		TargetType.HIGHEST_HP_ALLY,
		TargetType.ALL_ENEMIES,
		TargetType.ALL_ALLIES,
		TargetType.ALL_UNITS,
		TargetType.OTHER_ALLIES
	]

## Get opposite team
static func get_opposite_team(team: Team) -> Team:
	return Team.ENEMY if team == Team.PLAYER else Team.PLAYER

## Check if a status effect type is positive
static func is_positive_effect(effect_type: StatusEffectType) -> bool:
	return effect_type in [StatusEffectType.BUFF, StatusEffectType.SHIELD, StatusEffectType.IMMUNITY, StatusEffectType.INVINCIBILITY,]

## Check if a status effect type is negative
static func is_negative_effect(effect_type: StatusEffectType) -> bool:
	return effect_type in [StatusEffectType.DEBUFF, StatusEffectType.CONTROL, StatusEffectType.DOT, StatusEffectType.BLOCK]
