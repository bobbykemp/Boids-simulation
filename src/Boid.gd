extends Node2D
class_name Boid

onready var detectors = $ObsticleDetectors
onready var sensors = $ObsticleSensors

const starting_steering 	= 50.0
const starting_cohesion 	= 0.6
const starting_speed 		= 100
const starting_align 		= 0.6
const starting_seperation   = 0.1
const starting_avoidance	= 1.0
const tm 					= Color(1,1,1,1)

var boids 					= []
var perception_radius 		= 50
var velocity 				= Vector2()
var acceleration 			= Vector2()
var move_speed 				= starting_speed
var steer_force 			= starting_steering
var alignment_force 		= starting_align
var cohesion_force 			= starting_cohesion
var seperation_force 		= starting_seperation
var avoidance_force 		= starting_avoidance

var fleeing = false

export (Array, Color) var colors 

func _ready():
    randomize()
    
    position = Vector2(rand_range(0, get_viewport().size.x), rand_range(0, get_viewport().size.y))
    velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * move_speed
    modulate = tm


func _process(delta):
    
    if not fleeing:
        var neighbors = get_neighbors(perception_radius)
        acceleration += process_cohesion(neighbors) * cohesion_force
        acceleration += process_alignments(neighbors) * alignment_force
        acceleration += process_seperation(neighbors) * seperation_force

    if is_obsticle_ahead():
        acceleration += process_obsticle_avoidance() * avoidance_force
        
    velocity += acceleration * delta
    velocity = velocity.clamped(move_speed)
    rotation = velocity.angle()
    
    translate(velocity * delta)
    
    position.x = wrapf(position.x, -32, get_viewport().size.x + 32)
    position.y = wrapf(position.y, -32, get_viewport().size.y + 32)
    
func _input(event):
    # Mouse in viewport coordinates
    if event is InputEventMouseButton:
        if event.is_pressed() and (position.distance_to(get_global_mouse_position()) < perception_radius * 2):
            fleeing = true
            move_speed = starting_speed + 75
            steer_force = starting_steering / 2
            alignment_force = starting_align / 2
            cohesion_force = starting_cohesion / 2
            seperation_force = starting_seperation / 2
            # avoidance_force = 1
            modulate = Color(1,0,0,1)
            acceleration = position - get_global_mouse_position()
            $Timer.start()
            
# func _draw():
#     draw_line(position, (position - get_global_mouse_position()), Color(1,0,0,1))

func process_cohesion(neighbors):
    var vector = Vector2()
    if neighbors.empty():
        return vector
        
    for boid in neighbors:
        vector += boid.position
    vector /= neighbors.size()
    return steer((vector - position).normalized() * move_speed)
        
func process_alignments(neighbors):
    var vector = Vector2()
    if neighbors.empty():
        return vector
        
    for boid in neighbors:
        vector += boid.velocity
    vector /= neighbors.size()
    return steer(vector.normalized() * move_speed)

func process_seperation(neighbors):
    var vector = Vector2()
    var close_neighbors = []
    for boid in neighbors:
        if position.distance_to(boid.position) < perception_radius / 2:
            close_neighbors.push_back(boid)
    if close_neighbors.empty():
        return vector
    
    for boid in close_neighbors:
        var difference = position - boid.position
        vector += difference.normalized() / difference.length()
    
    vector /= close_neighbors.size()
    return steer(vector.normalized() * move_speed)
    
func steer(var target):
    var steer = target - velocity
    steer = steer.normalized() * steer_force
    return steer
    
func is_obsticle_ahead():
    for ray in detectors.get_children():
        if ray.is_colliding():
            return true
    return false

func process_obsticle_avoidance():
    for ray in sensors.get_children():
        if not ray.is_colliding():
            return steer( (ray.cast_to.rotated(ray.rotation + rotation)).normalized() * move_speed )
            
    return Vector2.ZERO

func get_neighbors(view_radius):
    var neighbors = []

    for boid in boids:
        if position.distance_to(boid.position) <= view_radius and not boid == self:
            neighbors.push_back(boid)
    return neighbors

func _on_Timer_timeout():
    fleeing = false
    move_speed = starting_speed
    steer_force = starting_steering
    alignment_force = starting_align
    cohesion_force = starting_cohesion
    seperation_force = starting_seperation
    avoidance_force = starting_avoidance
    modulate = tm
    velocity = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * move_speed

