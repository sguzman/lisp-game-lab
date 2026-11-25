# Room format v1

A room is a single ASCII S-expression, read as data, not evaluated:

```lisp
(:room 1
  (:item 1 100 150 160 112 0 0 t nil)
  (:item 2 340 150 56 40 0 2 nil nil))
```

Each item uses the schema:

```text
(:item id x y width height quarter-turn palette stackable support-id)
```

IDs are unique positive integers up to 9999. Coordinates are logical pixels; dimensions are at least 24 pixels; orientation is 0–3 clockwise quarter-turns. Palette 0–3 means brown, teal, gold, purple. Stackable is T or NIL; support is another item ID or NIL. The board is 800x480 with its top 64 pixels reserved. The format has a 16 KiB limit and at most 64 items. Validation covers bounds, duplicate IDs, containment, single-child support, acyclicity and unrelated overlap.

## Migration contract

- Existing IDs retain their actual instance, position, rotation and support. New definitions change dimensions, color and stackability. Defaults for existing IDs do not teleport objects.
- New IDs use authored placement; absent IDs are removed. Removing an occupied support while retaining its child is rejected, not silently detached.
- Validate authored defaults, then separately validate a staged migrated board. No live instance changes until both pass.
- Changes during a drag are deferred until release or cancellation. The last working room remains on rejection.
- Trusted local development only: reader evaluation is disabled, but the Lisp reader is not a hostile-input sandbox. No general schema evolution or persistent save migration is implied.

The three fixtures demonstrate initial, changed and conflicting scenes. The conflict fixture introduces new ID 6 at (650,330), overlapping item 3 only if the player has moved it there.
