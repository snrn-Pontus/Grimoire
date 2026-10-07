# Grimoire

One command lays out an Affliction Warlock on **WoW: Forever**'s gamepad crossbar. Dragging thirty-odd spells, items and macros onto four trigger layers with a controller takes a while; `/grimoire apply` does it in one go, and fills the back paddles too when [Backhand](https://github.com/snrn-Pontus/Backhand) is installed.

Grimoire is part of the SNRN addon family, next to [Backhand](https://github.com/snrn-Pontus/Backhand), [Rummage](https://github.com/snrn-Pontus/Rummage), [Tally](https://github.com/snrn-Pontus/Tally) and [Valet](https://github.com/snrn-Pontus/Valet).

Built for **World of Warcraft: Forever** (Interface 16001) and its level 30 beta cap. It uses Forever's native crossbar and does nothing useful on other clients.

## The layout

Shown for an Xbox controller: X is the left face button, Y the top, B the right, A the bottom. The base layer's face buttons belong to the client (interact, inspect, back, jump) and are left alone.

| | **Base** | **LT** | **RT** | **LT + RT** |
|---|---|---|---|---|
| **P1** | Corruption + pet attack | Healthstone | Pet's 2nd ability | Hellfire |
| **P2** | Bane of Agony | SmartHealthPotion | Seduction / Spell Lock | Hearthstone |
| **P3** | Drain Life | Torment | Pet Passive | SmartDrink |
| **P4** | Life Tap | Sacrifice | Curse of Recklessness, or Tongues, Exhaustion or Drain Mana | Use Soulstone |
| **D-Up** | Drain Soul | Pet Attack | Unending Breath | SmartBandage |
| **D-Right** | Fear | Rain of Fire | Sense Demons | Cannibalize or Rapid Regeneration, or Enslave Demon |
| **D-Down** | Shoot (wand) | Pet Follow | SmartQuestItem | SmartFood |
| **D-Left** | Shadow Bolt | SmartManaPotion | Racial damage cooldown, or Eye of Kilrogg | SmartFlask |
| **X** | *(client)* | Siphon Life, Searing Pain until then | Summon Voidwalker | Create Healthstone |
| **Y** | *(client)* | Health Funnel | Summon Felhunter, Imp until then | Create Soulstone |
| **B** | *(client)* | Curse of Weakness | Summon Succubus | Ritual of Summoning |
| **A** | *(client: jump)* | Immolate | Demon Armor, Demon Skin until then | Banish |

The idea: the base layer and its paddles hold the leveling loop (Corruption, Bane of Agony, Drain Life or the wand, Drain Soul on low mobs, Life Tap between pulls), LT is survival, RT is the pet and LT + RT is everything you do out of combat. Shadow Bolt stays on the base layer for Nightfall procs.

## Racials

Only the racials worth pressing while leveling get a slot, and they take the place of a spell you rarely need:

| Slot | Racial | Others keep |
| --- | --- | --- |
| RT D-Left | Blood Fury (Orc), Berserking (Troll), Eureka! (Gnome): damage cooldown for the pull | Eye of Kilrogg |
| LT + RT D-Right | Cannibalize (Undead, needs a Humanoid or Undead corpse), Rapid Regeneration (Troll, cancelled by moving, acting or damage): heal between pulls | Enslave Demon |

The breaks (Will of the Forsaken, Will to Survive, Shatter Curse, Escape Artist) and the Human's Perception are left out: they are answers to PvP crowd control and stealth that leveling rarely calls for. Cast them from the spellbook.

## Usage

1. Log in on your Warlock in gamepad mode, out of combat.
2. `/grimoire` prints the planned layout in chat, with the action slot of each button.
3. `/grimoire apply` places it. Whatever was in those slots is replaced, and a slot whose spell you have not learned yet is emptied; nothing else is touched.
4. `/grimoire check` compares every slot with the plan and lists the ones that differ.
5. `/grimoire report` opens the same comparison as text you can select and copy (Ctrl+C), since chat cannot be copied from. It shows the spell IDs the client finds for each planned name, the WL macros, the action bar page, the slot each crossbar button fires, your last button presses, and the output of the last command. Paste it into a bug report.
6. Spells you have not learned yet, and pet abilities, are listed as skipped. Run `/grimoire apply` again after leveling or learning a new demon, or turn on *Apply again after learning a spell* in the settings. Slots with two spells take the first one you know, so they upgrade themselves.

## Settings

Settings > AddOns > Grimoire, or `/grimoire config`. With a controller, use the mouse there: like the other SNRN addons, the page stays out of the gamepad cursor's reach because Forever freezes when Settings is closed after the cursor has been inside an addon page.

The page has buttons for the plan, apply, check and the report, shows whether Backhand's paddle slots and Rummage's Smart macros were found, and has these options:

| Option | Default | Does |
| --- | --- | --- |
| Fill Backhand's paddles | On | Places the P1-P4 actions; off fills only the crossbar |
| Empty slots for spells not learned yet | On | Clears a slot whose spell you do not know yet, so an older layout's action does not linger there |
| Update the WL macros | On | Rewrites existing WL macros on every apply; off keeps your own edits |
| Apply again after learning a spell | Off | Applies the layout a moment after you learn a spell, after combat if needed |

## Macros

Grimoire creates ten per-character macros, all starting with `WL`, and updates them in place when run again:

| Macro | Does |
| --- | --- |
| WL Corruption | `/petattack`, then Corruption, so the opener sends the pet in |
| WL PetAttack, WL PetFollow, WL PetPassive | Pet commands |
| WL Torment, WL Sacrifice | Voidwalker abilities, only with the Voidwalker out |
| WL PetAbility | Suffering, Phase Shift, Lash of Pain or Devour Magic, whichever pet is out |
| WL PetCC | Seduction (Succubus) or Spell Lock (Felhunter) |
| WL Healthstone | The best healthstone in your bags |
| WL UseSoulstn | The best soulstone in your bags, on yourself |

Each macro has a fixed icon from its spell or item, so a pet macro does not turn into a question mark while that pet is not summoned. Grimoire needs ten free character macro slots the first time; it stops and says so if there are not enough.

The food, drink, potion, bandage, flask and quest item slots use [Rummage](https://github.com/snrn-Pontus/Rummage)'s Smart macros. Without Rummage loaded, those seven slots are left exactly as they are, so you can put your own consumables there; old Smart macros left over from an uninstalled Rummage are never placed.

## With or without the other SNRN addons

Grimoire works on its own and fills the crossbar. Backhand adds the paddles and Rummage the consumable slots; each is used only while it is loaded, and the settings page shows which ones were found.

## How it works

Grimoire places actions the way the native crossbar's own edit mode does: it asks `GamepadActionBarBindingUtil` for the storage slot of each button on the current page and puts the spell, item or macro there with `PlaceAction`. Paddle actions go into the native slots Backhand reserved for the character. Action slots are saved by the server, so the layout follows your character to any computer.

## Commands

```
/grimoire          show the planned layout
/grimoire apply    place it on the crossbar and paddles
/grimoire check    compare every slot with the plan and list differences
/grimoire report   open a copyable report for bug reports
/grimoire config   open the settings
/grimoire help     list the commands
```

`/grim` is a shortcut for `/grimoire`.

## License

MIT.
