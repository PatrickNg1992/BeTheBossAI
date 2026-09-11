# Glossary

# Stage and Battlefield

## Boss Monster

The main character the player controls. If defeated, the game is over. There is a boss pucks on the battlefield.

## Stage

Simply a game stage that the player can choose to play.

## Wave

A game stage consists of multiple waves. Each wave will generate a Hero Team. The player needs to defeat the team to pass the wave. A hero team typically consists of 4 - 10 Enemy Heroes, with a hard cap of 12 per wave.

## Preparation Phase (Prep Phase)

Before each wave, there is a short rest for the player to do some preparation, including shuffling the deck and redrawing cards.

## Hero Team

A group of *Enemy Heroes* that come to challenge the player in each wave. A hero team typically consists of 6 - 10 Enemy Heroes.

## Enemy Hero

An enemy unit of the player. Each may have a *Class*, some *Equipment* and some *Hero Skills*.

## Class

The type (occupation) of an Enemy Hero. Examples are Warrior, Mage, Ranger, Knight, etc.

## Battlefield

The field where the battle takes place. Including the Snooker table and pucks.

## Snooker Table (Table)

The table in the battlefield where pucks are placed. 

## Pucks

A short cylinder-shaped object on the *Table* that represents different units. 

## Pocket Area

A hole in the table that a puck may fall into. 

## Cushion

4 sides of the table. 

# Cue and Collision System

## Cue-shot

The player makes a fast move with the Boss Pucks. The pucks hit the opponents to deal damage.

It can be made by either

- use the basic drag and release by mouse

- play a card effect

## Force

Similar to classical physics, a force is applied to a puck to make it move when playing a cue shot.

## Friction

Similar to classical physics, when a puck is moving, friction gradually slows it until it stops. The friction should be constant so that the puck's travel distance should be ∝ force².

## Energy

Energy is the resource for the player to make a shot to make a cue-shot. Energy is regenerated over time.

## Energy Bar

The energy fill on the *Time Board*, showing how much energy the player owns. It has 20 slots laid out as two 10-slot bars (upper and lower).

One slot is charged per *Turn* during *Charging Time* (default 1s per slot, configurable). Slots can carry *Action Tags*.

## Time Board

The board at the top of the battlefield scene canvas that visualizes battle time: the *Energy Bar*, the charging progress, and the *Action Tags*. Contents glide smoothly one slot per *Turn* — left to right on the lower bar, then (teleporting with a fade) from the lower-right to the upper-right, then right to left toward the goal at the upper-left slot. Frozen outside *Charging Time* unless an effect moves it (e.g. gaining or spending energy). At full energy the fill stops but tags keep moving.

## Turn

One tick of the battle clock — the time to charge 1 energy slot (default 1s, configurable). The minimum gap between two consecutive *Action Times*.

# Timing system

The main game time always falls into one of the six timings below; only one type of thing happens at a time. Mechanics and transitions are specified in `.docmanual/battleField/timingSystem/`; canonical terms in `CONTEXT.md`.

## Prepare Time

The timing of the *Preparation Phase*. The timing state machine does not run, no unit acts and energy does not regenerate. On entering, the *Time Board* animates to the coming wave's opening state (energy set to exactly 10, old *Action Tags* removed, the new team's initial tags placed), then freezes so the player can read it and plan.

## Charging Time

Energy charges one slot per *Turn*; nothing else moves or acts. The player's thinking time. Ends when the player enters Play Time (at most once per slot) or a *Turn* lands an *Action Tag* on the goal slot.

## Play Time

Everything waits for exactly one player action: one cue-shot, one card, or cancel back to Charging Time.

## Action Time

The units whose Action Tags reached the goal act, one action each, in spawn order (buff/debuff first — TBC; cue-shot actions like the Knight's last). Everyone else spectates.

## Action Tag

A marker a Hero or Minion places on a slot of the *Time Board*, meaning "this unit acts when the tag reaches the goal (upper-left slot)." Tags are independent of energy. After acting, the unit places its next tag some slots ahead of the goal; faster units use smaller offsets and act more often.

Displayed as a simple arrow pointing into the bar, with two integers — how many units share the tag, and how many *Turns* until the goal. The Turns integer is also shown on each unit's icon in the canvas. During *Action Time* the firing tag stays at the goal, its unit count decreasing as each unit acts; replacement tags fade in one-by-one as each action completes, and the firing tag vanishes when Action Time ends.

## Puck-puck Time!

Pucks move with force and collide until all stop. Damage is calculated but only staged; it is applied in Settle Time.

## Settle Time

A short timing that applies staged damage and displays events (puck defeated, puck pocketed, a health bar cleared). Skipped entirely when nothing settle-worthy happened. *Action Tag* membership changes are also applied here — a tag whose unit count reaches zero is removed; a unit entering the table joins an existing tag for its acting slot or places a new one.

# Card system

## Card

The player can play effects with cards. The player can hold a maximum of 10 cards in their hand. 

## Deck

The player makes a 52-card deck before the game. Then the player draws cards from it.

## Casting Area

Holds the last card played to prevent the player from playing cards too frequently. The card held here will move to the discard pile after the CD is done.

## Discard Pile

The place where a used card is finally placed.

# Action system

# TBC

## Equipment

An Enemy Hero may randomly equip some equipment. Equipment provides stats, and some may provide extra effects. This system adds randomness to differentiate heroes.

(TBC)

## Hero Skill

An Enemy Hero may randomly equip some Hero Skills that have special effects. At least one basic attack skill is equipped according to the Hero Class.

(TBC)

## Minion

A smaller monster that is summoned by the player side, either by cards or the Boss Monster’s effect.

(TBC)

# Scenes

## Menu

The game's first page — the scene the player sees on launch (the project's main scene) and where they pick where to go. Demo version: **Play** and **Multiplayer** buttons only, labels via the multiLang holder (title "Be The Boss" hardcoded as a placeholder — a picture will replace it later). **Play** enters the Single-Player Scene; **Multiplayer** enters the Multiplayer Scene. Also called "Main Menu" — same thing. Disconnected multiplayer Peers land here with a Notification.

## Single-Player Scene

An invisible scene (like the Multiplayer Scene) that sets up an `OfflineMultiplayerPeer` and loads the Battlefield as its child. Entered via the Menu's **Play** button. Keeps one Battlefield load path across single- and multiplayer.

# Multiplayer

## Host

The player who opened the multiplayer room and runs the game server. The Host is also a player — in PvP they control one of the two Boss Monsters.

## Opponent

The second player connecting to the Host's room. In PvP they control the other Boss Monster.

## Spectator

A non-playing peer watching the game. The Host can toggle whether Spectators are accepted.

## Peer

Any participant in a multiplayer session — Host, Opponent, or Spectator. Used when a rule applies to all three roles.

## Multiplayer Scene

The scene that controls multiplayer connection logic. Itself invisible — it swaps sub-scenes inside a container and drives them via a manager script. Three sub-scenes: **Role Selector**, **Waiting Room**, and **Battlefield** (loaded into the container when the game starts). Responsibility split: the manager controls the **connection** (connect/disconnect, rejoin grace period, notifications); the Battlefield controls the **synchronization of objects in the field** (positions, actions, hands).

## Connection Mode

How peers connect. **Dev mode**: direct IP + port (default 8910). **Steam mode**: via Steam — undecided, to investigate later. For now, only Dev (IP) mode is implemented.

## Game Config

The room configuration the Host sets in the Waiting Room. v1 scope: Spectator acceptance toggle and Dev-mode port; the battle always uses the **demo battlefield** for now. Stage/config details are a separate future design (not the single-player World Map list).

## Waiting Room

The sub-scene where Peers wait before and after a game. It has **two seats** — one for the Host, one for the Opponent — plus a simple list showing Spectator names. The Host sees **Start Game** (enabled only when the Opponent seat is filled — PvP must start with 2 players present; no "ready" flag in v1) and **Close Room** (closes the room, kicks all Peers, and returns the Host to the Menu). The Opponent and Spectators see a **Leave** button (disconnects and returns them to the Menu). After a game ends, all Peers return to the Waiting Room with the connection still open. The manual also calls this "the room" informally.

## Notification

A generic localized popup for connection events: version mismatch, host offline/disconnected, connection lost, host closed the room. One UI, message text from the multiLang holder.

## Connecting State

A state shown in the Role Selector while a Peer is trying to connect (not a separate sub-scene). On success, the Peer is swapped to the Waiting Room; on failure, the Peer stays in the Role Selector with a localized message. Timeout: ENet default for development.

## Version Check

On connection, the Host validates the Peer's game version (a constant string in code). Mismatch → reject the Peer; both sides see a localized "version mismatch" message.

## Rejoin Grace Period

When the **Host↔Opponent link drops mid-battle** — in either direction; each side only knows "the other is gone" — the battle freezes for all Peers and a grace period starts (v1 default: **30 seconds**). If the link is restored within the grace period — the Peer re-enters via the Role Selector, with Version Check, skipping the Waiting Room straight into the frozen battle — the Host restores a snapshot and the battle resumes. If the grace period expires, the game ends: still-connected Peers return to the Waiting Room, and the dropped Peer always lands on the Menu; a late joiner is rejected with a Notification. The frozen screens carry a **Leave** button that ends the grace period immediately (still-connected Peers → Waiting Room; dropped Peer → Menu). A Spectator disconnect does nothing (the slot just frees up). The only *clean* session end is the Host's explicit **Close Room** command: Peers receive the signal, get kicked to the Menu with a Notification. (The frozen state screen shows "Opponent disconnected, waiting…".)

## Spectator Exclusion List

What is hidden from Spectators. v1: both players' hands and deck contents — a card's identity is visible to its owner only. Note this secrecy is **visibility-only**: the Host syncs both decks and the game logic knows their full order (see ADR-0003); hiding happens at the UI layer. Hand counts and the discard pile are visible to all Peers (including Spectators). Spectators get a dedicated **Spectator HUD** (a special canvas item) showing both players' info side by side. Everything else is an open item, to be detailed when the game is more prepared.

## Spectator Cap

Fixed maximum of 4 Spectators per room in v1. Not host-configurable yet.

## Player Name

A **mandatory** display name the player enters in the Role Selector, used to identify Peers in the Waiting Room. Capped at 32 characters.
