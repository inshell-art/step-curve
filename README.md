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

Notes:
- `handle_scale_u32` is a u32; `0` defaults to `1`.
- XY values are signed i128 in felts; pass at least two points (4 values after the handle).

The output is a serialized `ByteArray` containing the SVG `d` string (Cairo ABI decode).

Example (Sepolia):

```bash
sncast --network sepolia call \
  --address 0x503bf054e089ea19c7df43091a57cd106cfc2672fea9b1a9633c3dbb7ac335 \
  --function render \
  --calldata 5 0 0 100 100
```

ByteArray decoding (shape):

```
[data_len, data_0, data_1, ..., pending_word, pending_word_len]
```

## Current deployment (Sepolia)

- Class hash: `0x05fe38120788a277d3da91e7992560fc8484576452ab3c4d5dd35a228575f855`
- Contract address: `0x503bf054e089ea19c7df43091a57cd106cfc2672fea9b1a9633c3dbb7ac335`
- Declare tx: `0x429c8c4ef9872ced0fd7e4014cc90e2f6f43faed30b55c7fcc4fb21a25b505e`
- Deploy tx: `0x52c6ae2a6fc3c26f310ddaf6521ce76114f88af7abbdc09fcec1e9beab6e061`
- RPC used: `https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_9/ixt6dg9JuoeZ8Tt6RGcA8`

## Build

```bash
scarb build
```

## Notes
- No styling or randomness; callers apply their own stroke/fill/filter.
- `handle_scale` controls handle distance; `0` defaults to `1` to avoid div-by-zero.
