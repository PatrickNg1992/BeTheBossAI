# Spec: Menu (Demo)

Status: ready-for-agent

Vocabulary per `GLOSSARY.md` (# Scenes, # Multiplayer) and `CONTEXT.md`. Source manual: `.docmanual/menu.md` (do not edit). Related spec: `.scratch/multiplayer-scene/spec.md` (shares the pending-Notification autoload).

## Problem Statement

The game currently boots straight into the battlefield test scene. For testing and demo purposes, the player needs a first page — a Menu — where they choose between single-player (Play) and multiplayer. Multiplayer flows (already spec'd) also need somewhere to land when players are kicked or disconnect: the Menu, with a Notification explaining why.

## Solution

A **Menu** scene that becomes the project's main scene — the first page on launch. Demo version: a title placeholder plus two buttons, **Play** and **Multiplayer**. **Play** enters the **Single-Player Scene** (an invisible loader that sets up an `OfflineMultiplayerPeer` and loads the Battlefield as its child). **Multiplayer** loads the existing multiplayer scene stub. A tiny autoload holds one pending Notification that the Menu displays and clears on entry, so kicked/disconnected players see why they landed here.

## User Stories

1. As a player, I want the game to open on the Menu, so that I can choose what to do before entering a battle.
2. As a player, I want to see the game title "Be The Boss" on the Menu, so that I know what game I'm playing.
3. As a player, I want a **Play** button, so that I can start a single-player game.
4. As a player, I want Play to take me into the Battlefield via the Single-Player Scene (OfflineMultiplayerPeer), so that single-player and multiplayer share one Battlefield load path.
5. As a player, I want a **Multiplayer** button that takes me to the Multiplayer Scene, so that I can host or join a PvP game.
6. As a player, I want button labels in my language (multiLang holder, EN/ZH), so that the Menu stays multi-language per repo convention.
7. As a kicked or disconnected multiplayer Peer, I want to land on the Menu with a Notification explaining why (connection lost, host closed the room, …), so that I'm not confused about how I got here.
8. As a player, I want the pending Notification to show once and clear, so that it doesn't reappear on later Menu visits.
9. As a developer, I want the old battlefield test scene to remain in the repo (no longer the main scene), so that existing battlefield work is undisturbed.
10. As a developer, I want the multiplayer role-selector stub's nodes renamed from "Menu" to "RoleSelector", so that "Menu" unambiguously means the game's first page.

## Implementation Decisions

- **New Menu scene** under `src/menu/`: a Control-based UI — centered vertical layout with a title label and two buttons (**Play**, **Multiplayer**), default theme, minimal demo polish.
- **Main scene switch**: the project's `run/main_scene` setting points to the Menu scene. The existing `test_scene.tscn` stays in the repo, no longer the main scene, and is what the Single-Player Scene loads as its Battlefield.
- **New Single-Player Scene** (invisible, no UI): on entry it sets up an `OfflineMultiplayerPeer` and instantiates the Battlefield as its child. Entered via Play.
- **New pending-Notification autoload**: holds at most one pending Notification (a localization key). The Menu checks it on entry, shows the generic Notification popup, and clears the slot. Written by multiplayer flows before they switch to the Menu. Kept separate from the localization autoload (which stays purely about text).
- **Title**: hardcoded "Be The Boss" label as a placeholder (a picture will replace it later) — a sanctioned demo exception to the multiLang rule. **Button labels go through the multiLang holder** per AGENTS.md.
- **Multiplayer button** loads the existing multiplayer scene stub unchanged; the stub's full rework belongs to the `multiplayer-scene` spec.
- **Rename**: the role-selector stub's root node and its instance inside the multiplayer scene are renamed from "Menu" to "RoleSelector" (the name "Menu" is now reserved for the game's first page).
- **No exit from battle in the demo**: once in a battle, the player quits the app to leave.

## Testing Decisions

- **What makes a good test**: drive the real scene tree at the highest point — make the Menu the current scene, interact with it, and assert external outcomes only (which scene became current, whether an `OfflineMultiplayerPeer` is active, whether a Battlefield instance exists, which Notification localization key was displayed, whether the pending slot was cleared). Never assert internal node paths or layout details below the Menu's root.
- **Seams**: none new — tests run through the real scene tree and the real pending-Notification autoload (agreed with the user). No navigator abstraction, no mocks.
- **Modules tested**: the Menu (button navigation, pending-Notification display/clear), the Single-Player Scene (OfflineMultiplayerPeer set up + Battlefield loaded), and the project main-scene setting pointing at the Menu.
- **Prior art**: none — this repo has no GDScript tests yet. Suites live in `res://tests/` as `test_*.gd` files with `test_*` methods, discovered by the editor's test runner. Whichever of this spec and `multiplayer-scene` lands first establishes the pattern.

## Out of Scope

- Future-version buttons: World Map, Codex, Leave (quit) — parked per the manual.
- Language toggle / config page — user will add separately later.
- Title picture — placeholder text for now.
- Battlefield in-game menu (exit to Menu mid-battle) — parked, **unconfirmed** open item; deliberately not in the glossary.
- Multiplayer scene rework (Role Selector fields, Waiting Room, manager logic) — covered by `.scratch/multiplayer-scene/spec.md`.
- Any theming or art pass.

## Further Notes

- Glossary: `GLOSSARY.md` # Scenes (**Menu**, **Single-Player Scene**); `CONTEXT.md` scenes list points to them.
- The pending-Notification autoload is shared with the `multiplayer-scene` spec — whichever spec is implemented first creates it; the other consumes it.
- The multiplayer glossary entries that say Peers "return to the Menu" now have a concrete destination: this scene, plus a pending Notification in the autoload.
