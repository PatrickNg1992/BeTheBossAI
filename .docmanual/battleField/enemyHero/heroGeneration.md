# Hero Generation

There are two types of heroes:  legendary heroes and random heroes. 

## Legendary Hero

A legend hero is a fixed, pre-designed hero which appears in specific stages. They are usually stronger than random heroes and often serve as the main enemies of the stages. 

Additionally, there is a page in the codex to record the Legend Heroes that the player has taken down. (For codex scene only, not related to battlefield)

## Random Hero

A random hero is a normal hero whose properties are generated randomly by some algorithm. 

A random hero will assigned a random class (include the basic attack method), some random skills, and a random LV (and equipment TBC).

These properties combined to determine the Max HP, action speed and attack power of the hero units.

## Stage generation Logic

At the beginning of a stage, all the enemies of all waves will be randomly generated. However, the player only knows the hero teams of the incoming wave. 

The generation logic should use a seed (maybe by date) so the hero combination of a stage over a period of time (maybe daily) is always the same, including classes, skills, LV, etc. 

However, the generation seed does not control the positions the heroes appear in a wave. It also does not affect the card order. Players should experience some degree of difference even though they play a stage with exactly the same hero team combination.

To balance the difficulty of stages, the combat power of each hero is calculated to adjust the strength of the hero teams. The combat power of hero is calculated by class, skills, and level. 

For the seeded generation logic, it should determine the following steps in order:

1. What is the estimated combat power of each wave?

2. Any Legendary Heroes? If yes, in which wave?

3. How many heroes in each wave?

4. What are the classes of the heroes?

5. What random skills should be assigned to each heroes?

6. What are the equipments? (TBC)

7. What are the level of the heroes? (Adjust the value to meet the estimated combat power)

The above is the high-level idea of the formula. Details and fine-tune are left for the implementation. It is to remind that the classes combination of each wave should not be too condense on some classes.
