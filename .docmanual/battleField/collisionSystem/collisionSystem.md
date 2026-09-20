# Collision System

The collision system is one of the game's most important mechanisms. It happens only in "Puck-puck time!"

It controls the effects when two pucks collide. It basically follows classical mechanics. 

## Mass

Each puck has a relative mass. The mass depends on the unit it represents. 

Typically, the boss monster puck has a large mass. A knight puck has a larger mass than other enemy hero pucks.

A heavier puck is less likely to be affected by a lighter puck.

## Impulse and velocity

A puck moves when an Impulse is applied to it. It gains velocity. Velocity is an internal state of pucks controlled by the host.

Impulse and velocity are vectors consisting of direction and magnitude. Speed is proportional to velocity.

In the game, the direction is a 3D vector, but in most cases it only takes 2 dimensions because the pucks move on a 2D table. 

## Friction

A moving puck reduces its velocity at a constant rate. Hence, its speed reduces at a constant rate. 

The deceleration rate caused by friction can be affected by the table and by cards or abilities. 

Do the math by calculating the velocity directly, without using impulse.

## 

## Collision between Pucks

When two pucks collide, an Impulse and an opposite Impulse are applied to both pucks. Calculate the following:

### Step1: find the collision normal vector (n)

n = (p1 - p2) / ||p1 - p2||

### Step2: Calculate Relative Closing velocity (vrel)

vrel = (v1 - v2)．n

### Step3: Compute Impulse Scalar (J)

J = ( -(1+e)．vrel ) / ((1/m1) + (1/m2))

### Step4: Apply vector velocities Update

v1f = v1 + (J/m1)n

v2f = v2 - (J/m2)n



where 

p1, p2 are positions

v1, v2 are velocities

m1, m2 are mass

e is the collision factor controlled by energy loss

\*\* For interest, the actual e or J can be affected by the puck units

## Collide with Cushion (or Obstacle)

When a puck collides with the cushion, calculate the rebound velocity in two directions: parallel and perpendicular

### Perpendicular:

Apply the collision formula with m2 = infinity and v2 = 0, we should have:

J = -m1 (1 + e) (v1．n)

velocity applied = - (1+e) (v1．n) n

### Parallel:

velocity applied = - fc (v1-(v1．n)n)

### Final result:

v1f = v1 - (1+e) (v1．n) n - fc (v1-(v1．n)n)

or rearranged:

v1f = (1-fc) (v1 - (v1．n)n) - e (v1．n)n



where 

n is the normalised perpendicular direction

fc is the cushion friction factor

*\* For interest, the actual e or J can be affected by the effects of the puck units

## Collision effects

## Gravity
