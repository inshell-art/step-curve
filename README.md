# Step Curve (GLYPH)

Minimal Starknet contract that converts ordered nodes into SVG path-data (`d` string).

- Contract: `StepCurve` (pure converter)
- ABI: `d_from_nodes(nodes: Span<Point>, tension: u32) -> ByteArray`
- Optional helper: `d_from_flattened_xy(nodes_xy: Span<felt252>, tension: u32) -> ByteArray`
- Point uses signed `i128` coordinates to support negative offsets.

## Build

```bash
scarb build
```

## Notes
- No styling or randomness; callers apply their own stroke/fill/filter.
- `tension` controls handle distance; `0` defaults to `3` to avoid div-by-zero.
