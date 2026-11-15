# Scavenging at Harlow Junction

Thirteen marked caches span the platform, both warehouses and the freight yard. Approach a
SUPPLIES marker, aim the centre reticle at the cache and press E. Targeting in both camera
modes checks reach and line of sight. Searching takes 1–4 seconds; E, Esc, movement, jumping or leaving
reach cancels without changing loot. A brief highlight and a notice confirm completion.
Searched caches turn green. E collects remaining items after you make room in the backpack.

| Area | Finds |
|---|---|
| Platform (2 caches) | Small food, scrap and basic-supply rolls |
| Warehouse A (4) | Tools, scrap, general stores and a coal reserve, including the upper floor |
| Warehouse B (4) | Medical supplies, better general stores and a guaranteed component at the far end |
| Freight yard (3) | Industrial materials, fuel reserve and equipment; one cache is on a car roof |

Loot is configured in `resources/loot/`, not in interaction code. The run seed is 2017 by
default, mixed with each cache's stable ID. Resetting the station restores the same draws;
change the seed for a different reproducible layout of rewards.

## Backpack and cargo

The backpack has six slots. Stacks have item-specific limits. Weight is shown for planning;
it does not change ordinary movement or impose an additional weight capacity this milestone.

| Item | Stack limit | Unit weight | Carrying |
|---|---:|---:|---|
| Canned food | 4 | 0.5 kg | Backpack |
| Bandages | 5 | 0.2 kg | Backpack |
| Medicine | 3 | 0.3 kg | Backpack |
| Scrap metal | 8 | 0.8 kg | Backpack |
| Tools | 2 | 2.0 kg | Backpack |
| Lantern oil | 3 | 0.7 kg | Backpack |
| Coal sack | 1 | 18.0 kg | Heavy |
| Fuel drum | 1 | 32.0 kg | Heavy |
| Machine component | 1 | 24.0 kg | Heavy |

Tab or I opens the ledger. Click a slot or press 1–6 to select it; hover for details.
Q drops one selected item, and Drop stack releases the whole stack. E recovers loose supplies.
If only part of a pickup fits, its remainder stays in the world. Search overflow stays in
its original container, so freeing a slot and returning with E is safe.

Heavy objects occupy your hands, not backpack slots. E lifts one while standing on firm
ground, movement slows to 2.5 m/s and sprint is disabled. G immediately releases it; it
remains recoverable in the world. Ladders, rail grabs, vaulting and climbing require putting
it down first and show a hands-full notice. Jumping and boarding the flat car remain possible.
V switches perspectives while preserving the same cargo object: a camera anchor holds it
in first person, and an animated body anchor holds it in third person. Held objects cannot
block or push the player. Released cargo collides with world/train floors
but not the player or other cargo; this is reliable carrying, not a stacking physics puzzle.

## Train hold

The marked SUPPLY HOLD is on the flat car and moves with it. Approach from the platform or
deck, look at the hold and press E. R deposits all backpack supplies and held cargo. Deposit selected moves
one selected backpack stack. Click a storage row (or use ↑/↓), then Enter or Withdraw selected
moves a stack into available backpack space; heavy cargo goes directly into free hands.

The hold has 48 configurable slots. Each heavy object uses one slot; small items stack as in
the backpack. Quantities and the HUD's ABOARD total update immediately. Partial transfers
leave the remainder in the source. ABOARD means the count currently secured in storage,
including heavy objects; it excludes loose cargo on the deck. There is no score or lifetime
counter. Storage rows group by item ID; repeated withdrawal accesses subsequent stacks.

Opening the ledger blocks movement input but does not pause the train or the world. You
continue riding a deck normally. If the hold leaves reach, its ledger closes. Each transaction
checks reach again. Close the ledger to resume walking; G remains available for immediate drop.

## Reset behavior

| Debug action | Supplies |
|---|---|
| Reset player | Backpack and held cargo remain with the player; storage and loose items remain intact; search cancels |
| Reset train | Stored supplies remain; loose cargo resting on a car returns with that car; search/ledger closes |
| Reset entire station | All inventories, held/loose items and search progress clear; the original seeded caches regenerate |
| Quit and relaunch | A fresh station; supplies are not saved |

Graphics and camera preferences persist. Item future-use metadata is inert: no crafting, healing,
fuel consumption, upgrades, damage or dangerous advancing fog is implemented.
