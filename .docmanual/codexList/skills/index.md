# Skill Codex Index

Skill lists are categorised by their types in subfolders: move, attack, active, passive.

# Data Format

## Name: {Skill Name}
- ID: {reference Id, last 4 digits only, unique in each list}
- Lv: {optional. if the skill allows levels, it shows the max level}
- Type: {optional. extra type category}
- For: {optional. What type of unit can equip this skill normally, but is not restricted
- Description: {display text to players}
- Effects: {Describe the effects in text, implement this logic}
- Animation: {describe the animation to play. Commonly for Attack or Active Skills}
- Ratio: {Commonly valid for attack or active skills, optional. Describe the attack ratio}
- Dist: {distance to move, common in Move Skills. A random range like 1.00 - 1.50}
- Var: {how the variable is calculated in description or effects, commonly related to Lv, variables are marked as `?\W`}



## Key points

The name row uses Header 2 for Markdown.

The name, level, description, power, and dist are checkable information for players.

Reference ID in this regex format: `S[MAUP](?:A[12345]|BM|MN|CM)\d{4}`. where
- S[MAUP] means Move/Attack/Active/Passive Skills
- A[12345] means Adventurer Skills for level 1-5 classes or above
- BM means Boss Monster; MN means minion; CM means common
- (0000....9999) is the ordering number

Example: SMA10001 skill is a skill for Level 1 or above classes. It is inside SMA1.md in the ./move folder, the first item.

If an adventurer skill is marked for a class, it means that class and all its advanced classes.

If a Skills marked 
- `Skip Movement`, it means if the skill is triggered, that unit no longer trigger the Move Skill. 
- `Hit Level+?`, it means increase the (attack) targets hit level by X  



*Take the wording carefully for the effects and description parts. Avoid misunderstanding by clarify*