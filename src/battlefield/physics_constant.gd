@tool
class_name PhysicsConstant
extends RefCounted

## Central tuning constants for Cue Table physics, Cue-Shot launch impulse,
## friction, cushion rebound, pocket capture, and collision damage calculation.
## Edit values here to fine-tune the physical feel and collision damage balance.

# ==================== COLLISION DAMAGE ====================
## Divisor in the collision damage formula: `damage = (J / COLLISION_DAMAGE_IMPULSE_DIVISOR) * hitter_POW`
const COLLISION_DAMAGE_IMPULSE_DIVISOR: float = 40.0

# ==================== TIMING & GLIDE SPEED ====================
## Energy charging speed multiplier in live gameplay (0.50 = 50% slower than 1.0 slot/sec -> 2.0s per slot).
const ENERGY_CHARGING_SPEED: float = 0.50
## Adventurer Move Skill constant glide speed in table units/sec (20% slower than 7.5 -> 6.0).
const GLIDE_SPEED_UNITS_PER_SEC: float = 6.0

# ==================== CUE-SHOT & AIMING ====================
const MIN_SHOT_ENERGY: float = 1.0
const MAX_SHOT_ENERGY: float = 9.0
const ENERGY_STEP: float = 0.5
const IMPULSE_PER_ENERGY: float = 7.2
const DEADZONE_RADIUS: float = 0.65
const DRAG_DISTANCE_PER_ENERGY: float = 1.0
const BOSS_CLICK_RADIUS: float = 1.25
const AIM_LENGTH_PER_IMPULSE: float = 0.45
const POST_HIT_LENGTH_PER_SPEED: float = 0.50

# ==================== PUCK VELOCITY, RESTITUTION & GRAVITY ====================
const VELOCITY_TICK_INTERVAL: float = 0.05
const STOP_SPEED_THRESHOLD: float = 0.002
const DEFAULT_DECELERATION: float = 1.2
const DEFAULT_PUCK_RESTITUTION: float = 0.85
const DEFAULT_CUSHION_RESTITUTION: float = 0.85
const DEFAULT_CUSHION_FRICTION: float = 0.10
const BOSS_VS_BOSS_VELOCITY_DAMPING: float = 0.20
const TABLE_GRAVITY: float = 25.0

# ==================== FLOOR FRICTION & POCKET CAPTURE ====================
const FRICTION_GRASS: float = 1.0
const FRICTION_STONE: float = 0.75
const FRICTION_MUD: float = 2.0
const FRICTION_ICE: float = 0.20

const POCKET_CAPTURE_RATIO: float = 0.75
const POCKET_DECELERATION: float = 28.0
const POCKET_PULL_SPEED: float = 6.0
const POCKET_Y_DROP: float = 0.30
const POCKET_RESPAWN_MIDDLE_RATIO: float = 0.80
