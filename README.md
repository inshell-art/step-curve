# Step Curve (GLYPH)

Minimal Starknet contract that converts ordered nodes into SVG path-data (`d` string).

The contract exposes the GLYPH interface:
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
