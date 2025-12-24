# Step Curve (GLYPH)

Minimal Starknet contract that converts ordered nodes into SVG path-data (`d` string).

The contract supports two usage modes:

## Mode A: contract-native (on-chain composition)
- `d_from_nodes(nodes: Span<Point>, handle_scale: u32) -> ByteArray`
- `d_from_flattened_xy(nodes_xy: Span<felt252>, handle_scale: u32) -> ByteArray`
- `Point` uses signed `i128` coordinates to support negative offsets.

Example (flattened XY pairs):

```bash
sncast call \
  --contract-address 0x... \
  --function d_from_flattened_xy \
  --calldata 4 0 0 100 100 10
```

## Mode B: GLYPH interface (generic)
- `render(params: Span<felt252>) -> Array<felt252>`
- `metadata() -> Span<felt252>`

`render` params layout:

```
[
  handle_scale_u32,
  x0_felt, y0_felt,
  x1_felt, y1_felt,
  ...
]
```

The output is a serialized `ByteArray` containing the SVG `d` string (use Cairo ABI decoding).

Example:

```bash
sncast call \
  --contract-address 0x... \
  --function render \
  --calldata 5 10 0 0 100 100
```

## Build

```bash
scarb build
```

## Notes
- No styling or randomness; callers apply their own stroke/fill/filter.
- `handle_scale` controls handle distance; `0` defaults to `1` to avoid div-by-zero.
