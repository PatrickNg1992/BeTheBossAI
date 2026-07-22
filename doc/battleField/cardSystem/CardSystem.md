# Card System

The player needs to prepare a deck consisting of 52 cards before the game. (Given the number and pattern of poker cards for reference)

Inside a game, the cards will be stored in one of the three places: Deck, Hands, and Discard Pile.

The number of cards in the Deck and the Discard Pile are shown in the bottom right corner. Cards in hand are displayed at the bottom of the screen.

The player draws cards from the deck to his hand. After a card is used, it goes to the Discard Pile.

## Hand in the game

In the preparation phase before each wave, all the cards are shuffled back into the Deck. Then the Player draws 5 cards as his starting hand.

The maximum hand size will be 10 cards. When the player has 10 cards in his hand and tries to draw a card, the draw action will be skipped, but a simple animation will be played to notify the player.

There are 4 methods to draw cards:

- At the preparation phase before each wave, as stated above,
- When a health bar of the boss monster is cleared,
- When an enemy hero is defeated, and
- When a card drawing effect is triggered by playing cards or skills

## How to play a card

The player can click a card in his hand to make the card shift up. Then he can choose a target position on the battlefield to play the card.

When a card is shifted up, the player can unchoose the card by clicking it again or by clicking another card.

When a card’s effect is playing, the card will be kept shifted up, and the player cannot click any cards until it ends. Afterwards, the card will move to the discard pile.

## More details

The deck’s order is invisible. It will be shuffled in each Preparation Phase.

The discard pile and its order are visible. The player can click the discard pile icon to open a small window to check it.

## Card Types

There are 4 types of cards, and each should occupy 13 cards in the deck:

- Environment Cards: Fixed cards according to the stage
- Monster Skill Cards: Each Boss monster has some prepared cards allowing the player to choose.
- Summoner Cards: The player owns a card storage and can choose some to use.
- Minion Cards: Cards that are used to summon minions. Mainly from the player's card storage. But some boss monsters may unlock special minions.
