# Grimoire changelog

## Unreleased

- `/grimoire check` compares every crossbar and paddle slot with the plan and lists the slots that hold something else or are empty.
- Fixed: the Agony DoT on base P2 was skipped. Forever calls it Bane of Agony; Grimoire now looks for that name first and falls back to Curse of Agony.

## 0.1.0 — First release

Grimoire is part of the SNRN addon family.

- `/grimoire apply` places an Affliction Warlock leveling layout on all four crossbar layers (no trigger, LT, RT, LT + RT) and, with Backhand installed, on the P1-P4 paddles of each layer. `/grimoire` shows the plan first.
- Spells you have not learned yet are skipped and listed; run it again after learning them. Slots with a fallback (Siphon Life before Searing Pain, Felhunter before Imp, Demon Armor before Demon Skin) upgrade themselves.
- Creates ten per-character `WL` macros for the pet commands, pet abilities, Corruption with pet attack, Healthstone and Soulstone. Each gets a fixed icon, so pet macros do not show a question mark while that pet is not out.
- Uses Rummage's Smart macros for food, drink, potions, bandages, flasks and quest items when they exist.
- Built for the level 30 cap of the WoW: Forever beta.
