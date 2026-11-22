# Timing System

To let the player enjoy both the snooker and auto-fighting, game time should be separated into different sections.

Therefore, at least the following timings are required:

- All things stopped and allow the player to aim

- During a cur-shot, the pucks are allowed to move freely by force and collide with each other

- Auto-fighting: the pucks interact with each other.

To be executable, five timings are defined as follows.

## Charging Time

The fundamental time section.

Energy is charging; the energy bar is moving. Nothing else is acting. It takes *1s* to charge a slot. Make the wait time for 1 shot configurable.

If the player clicks the *Play* Button, it enters the Play time.

If an energy slot with action tags is charged, it enters the Action Time.

## Action Time

Units on the battlefield make their actions automatically.

If a guard or other special puck makes a cue-shot, it enters the Puck-puck Time.

Otherwise, it enters the Settle Time when ends.

## Play Time

The player can make a cue-shot by dragging or playing a card. Everything is stopped and waits for user action.

If a cue-shot is made, either by dragging or card effects, it enters the Puck-puck Time.

The player can cancel the Play time and go back by pressing the button again.

Otherwise, enter Charging Time or Action Time based on the card effect.

## Puck-puck Time!

The time section where pucks move with force and collide with others.

Wait until all pucks stop and settle the damage calculation and effects.

It goes to the Settle Time when it ends.

To keep the collision time complete, don't remove any pucks on the table even if corresponding units are defeated. Only calculate the damages *to be dealt* to the units first and apply the damages to the units in Settle Time.

There should be exciting Visual effects since it is a main theme of the game. 

- Collision effects between pucks should be displayed,

- Running number display for damage to be dealt, etc

## Settle Time

This is a special, short timing compared to the other timings. It happens *AFTER* other timings if any events happened during them.

Before transitioning from one timing to another, if any of the situations below happen, it will trigger the settlement before entering the next timing

- A puck is defeated,

- A puck falls into the pocket area,

- A player's health bar is cleared, and

- Other situations TBC

It will take a short time to display the event that happened.

## Prepare Time

Time spent in the preparation phase. 

The player can click to start the next phase and do some preparations.

## Pause and Fast Play

At any timing, the game allows the player to pause. 

Also, add a switch button on the battlefield screen to enable fast play in single-player games. Fast play should affect all timing except Play Time and Prepare Time because these two are basically waiting for user actions.
