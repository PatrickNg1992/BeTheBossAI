# Adventurer Class Codex

This codex does not have subfolders. Classes are stored in 5 Markdown files in this folder, according to the class hierarchy trees. They are 

- guard.md

- brawler.md

- scout.md

- acolyte.md

- others.md (Exceptional Class that is not an Advanced class of the 4 trees)

## Data structure

## Name: {class name}

- ID: {reference Id}

- Lv: {Class Level}

- Description: {Display only text in Codex function}

- Skills: {Skill ID of skills that designed for this class}

- From: {Direct prerequisite class}

- Trait: {brief description of the special point of this class}

## Key points

The name row uses Header 2 for Markdown.

The name, level, description, and from class are checkable information for players.

The Skills listed here are a list of skills that have a high chance to be equipped by a unit of this class or its advanced classes (Detail should be done in the Unit generation logic). Only the skills actually equipped by a unit can be seen in the battlefields.

The trait of a Level 1 class is a general trait. The trait of a Level 2 or 3 class is the development direction of the Class advancement. The trait of a Level 4 or 5 class 

The reference ID of Adventurer Class are in the format of regex  `AC[GBSAO][12345]\d{4}`, which means

- `AC`: adventurer class

- `[GBSAO]`: Guard/Brawler/Scout/Acolyte/Others

- `[12345]`: Class level

- `\d{4}`: running number in order
