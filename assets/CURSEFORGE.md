# SNRN Grimoire

**One command lays out an Affliction Warlock on WoW: Forever's gamepad crossbar.**

Dragging thirty-odd spells, items and macros onto four trigger layers with a controller takes a while. `/grimoire apply` does it in one go: the base, LT, RT and LT + RT layers of the native crossbar, plus the back paddles when SNRN Backhand is installed. Run it again after leveling and new spells slot themselves in.

## What's new

- **0.2.0**: A settings page (`/grimoire config`) and `/grimoire check`, which lists every slot that differs from the plan. Grimoire now works with or without Backhand and Rummage, using each only while it is loaded. Bane of Agony is no longer skipped, and slots for spells you have not learned yet are cleared instead of keeping an older layout's action.
- **0.1.0**: First release.

Full history on the Changelog tab of each file.

## The layout

Shown for an Xbox controller: X is the left face button, Y the top, B the right, A the bottom. The base layer's face buttons belong to the client (interact, inspect, back, jump) and are left alone.

| | **Base** | **LT** | **RT** | **LT + RT** |
| --- | --- | --- | --- | --- |
| **P1** | Corruption + pet attack | Healthstone | Pet's 2nd ability | Hellfire |
| **P2** | Bane of Agony | SmartHealthPotion | Seduction / Spell Lock | Hearthstone |
| **P3** | Drain Life | Torment | Pet Passive | SmartDrink |
| **P4** | Life Tap | Sacrifice | Curse of Recklessness, or Tongues, Exhaustion or Drain Mana | Use Soulstone |
| **D-Up** | Drain Soul | Pet Attack | Unending Breath | SmartBandage |
| **D-Right** | Fear | Rain of Fire | Sense Demons | Enslave Demon |
| **D-Down** | Shoot (wand) | Pet Follow | SmartQuestItem | SmartFood |
| **D-Left** | Shadow Bolt | SmartManaPotion | Eye of Kilrogg | SmartFlask |
| **X** | *(client)* | Siphon Life, Searing Pain until then | Summon Voidwalker | Create Healthstone |
| **Y** | *(client)* | Health Funnel | Summon Felhunter, Imp until then | Create Soulstone |
| **B** | *(client)* | Curse of Weakness | Summon Succubus | Ritual of Summoning |
| **A** | *(client: jump)* | Immolate | Demon Armor, Demon Skin until then | Banish |

The base layer and its paddles hold the leveling loop (Corruption, Bane of Agony, Drain Life or the wand, Drain Soul on low mobs, Life Tap between pulls). LT is survival, RT is the pet and LT + RT is everything you do out of combat. Shadow Bolt stays on the base layer for Nightfall procs.

## Setup in one step

Log in on your Warlock in gamepad mode, out of combat, and type `/grimoire apply`. That's it.

- `/grimoire` shows the plan in chat first, with the action slot of each button.
- Whatever was in those slots is replaced. A slot whose spell you have not learned yet is emptied, and nothing else is touched.
- Spells you have not learned yet are listed as skipped. Slots with two spells take the first one you know, so they upgrade themselves when you run it again, or turn on **Apply again after learning a spell**.
- `/grimoire check` compares every slot with the plan and lists the ones that differ.

## Macros

Grimoire creates ten per-character macros starting with `WL` and updates them in place when run again: Corruption with pet attack, pet attack, follow and passive, the Voidwalker's Torment and Sacrifice, the pet's 2nd ability, Seduction or Spell Lock, your best Healthstone and your best Soulstone on yourself.

- Each macro has a fixed icon, so a pet macro does not turn into a question mark while that pet is not out.
- It needs ten free character macro slots the first time, and says so if there are not enough.

## Settings

**Settings > AddOns > Grimoire** (or `/grimoire config`): buttons for the plan, apply and check, which SNRN addons were found, and these options:

- Fill Backhand's paddles
- Empty slots for spells not learned yet
- Update the WL macros, or keep your own edits
- Apply again after learning a spell

## Works with a controller

Grimoire places actions the way the crossbar's own edit mode does, so the layout is saved by the server and follows your character to any computer. The Settings page is built so WoW: Forever's gamepad cursor never touches it, which avoids the client freezing when Settings is closed with the controller. Use the mouse there.

## Slash commands

`/grim` is a shortcut for `/grimoire`.

```
/grimoire          show the planned layout
/grimoire apply    place it on the crossbar and paddles
/grimoire check    compare every slot with the plan and list differences
/grimoire config   open the settings
/grimoire help     list the commands
```

## Notes

- Built for **World of Warcraft: Forever** and its level 30 beta cap. It uses Forever's native crossbar and does nothing useful on other clients.
- Affliction Warlock only for now.
- Works on its own. Backhand adds the paddles and Rummage the consumable slots, each only while it is loaded. Without Rummage, its seven slots are left as they are so you can put your own consumables there.

## Part of the SNRN family

- **[SNRN Backhand](https://www.curseforge.com/wow/addons/snrn-backhand)**: four extra action slots for your controller's rear paddles, built into Forever's native crossbar. Grimoire fills all sixteen of them.
- **[SNRN Rummage](https://www.curseforge.com/wow/addons/snrn-rummage)**: one action slot per item type that always uses the best food, drink, potion, bandage or quest item in your bags. Grimoire puts its Smart macros on your bars.
- **[SNRN Tally](https://www.curseforge.com/wow/addons/snrn-tally-bag-ammo-counter)**: free bag slots and ammo on Forever's gamepad HUD, which shows neither.
- **[SNRN Valet](https://www.curseforge.com/wow/addons/snrn-valet)**: sells greys and repairs at merchants, collects your mail, and declines duels, guild invites and charters, so there are fewer popups to chase with the gamepad cursor.

## Reporting problems

Run `/grimoire check` and include the output with your report, plus your level and which SNRN addons you have installed.
