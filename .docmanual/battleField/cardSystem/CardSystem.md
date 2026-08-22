# Card System

The player needs to prepare a deck consisting of 52 cards before the game. (Given the number and pattern of poker cards for reference)

Inside a game, the cards will be stored in one of the 4 places: Deck, Hands, Casting area, and Discard Pile.

The number of cards in the Deck and the Discard Pile are shown in the bottom right corner. Cards in hands are displayed at the bottom of the screen. The Casting area will put the card which the player just played and not yet goto the discard pile.

The player draws cards from the deck to his hand. When a card is used, it will goto the casting area. Then it will move to the dispile later.

## Hand in the game

In the preparation phase before each wave, all the cards are shuffled back into the Deck. Then the Player draws 5 cards as his starting hand.

The maximum hand size will be 10 cards. When the player has 10 cards in his hand and tries to draw a card, the draw action will be skipped, but a simple animation will be played to notify the player.

There are 4 methods to draw cards:

- At the preparation phase before each wave, as stated above,
- When a health bar of the boss monster is cleared,
- When an enemy hero is defeated, and
- When a card drawing effect is triggered by playing cards or skills

## How to play a card

The player can click a card in their hand to select it (shift it up). Then he can choose a target position on the battlefield to play the card. (project the click position to the battlefield to determine where it is clicked)

When a card is selected, the player can deselect the card by clicking it again or by clicking another card.

When a card is played, it will move to the casting area and play its effects.

When the casting area is full, the player cannot play more cards in his hand. When he clicks on the battlefield after selecting a card, an error message will pop up.

## Casting area

The card in play will be placed here. The casting area can store 1 card at a time.

If the card has a CD (cooldown), a countdown will be shown. The card will move to the discard pile when the CD ends.

Some cards do not have a CD (here does not mean CD time 0, literally no CD). Those cards will stay at the casting area until the card's effects move it out. 

## More details

The deck’s order is invisible (but may be visible in test mode). It will be shuffled in each Preparation Phase.

The discard pile and its order are visible. The player can click the discard pile icon to open a small window to check it.

## Card Types

There are 4 types of cards, and each should occupy 13 cards in the deck:

- Environment Cards: Fixed cards according to the stage
- Monster Skill Cards: Each Boss monster has some prepared cards allowing the player to choose.
- Summoner Cards: The player owns a card storage and can choose some to use.
- Minion Cards: Cards that are used to summon minions. Mainly from the player's card storage. But some boss monsters may unlock special minions.

## Discard Pile Window

The player can click the discard pile icon on the bottom right of the canvas to open a window to check what cards are in the discard pile. The window can be closed by click a cross button on the window. 
