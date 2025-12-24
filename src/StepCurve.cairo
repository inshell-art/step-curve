#[starknet::contract]
pub mod StepCurve {
    use core::array::{Array, ArrayTrait, Span, SpanTrait};
    use core::byte_array::ByteArrayTrait;
    use core::serde::Serde;
    use core::traits::TryInto;
    use crate::glyph_interface::IGlyph;

    const META_0: felt252 = 'name=step_curve;kind=svg;';
    const META_1: felt252 = 'tag=path-d;version=0.1.0;';
    const META_2: felt252 = 'params=handle_scale,xy_pairs;';
    const META_3: felt252 = 'returns=svg_path_d;';
    const META_4: felt252 = 'immutable=true';

    #[derive(Copy, Drop, Serde)]
    pub struct Point {
        pub x: i128,
        pub y: i128,
    }

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl StepCurveImpl of IStepCurve<ContractState> {
        /// Convert ordered nodes into SVG path-data ("d").
        /// `handle_scale` controls handle distance; values <= 0 default to 1 to avoid div-by-zero.
        fn d_from_nodes(self: @ContractState, nodes: Span<Point>, handle_scale: u32) -> ByteArray {
            let safe_handle_scale = if handle_scale == 0_u32 { 1_u32 } else { handle_scale };
            self._to_cubic_bezier(nodes, safe_handle_scale)
        }

        /// Convenience entrypoint: accepts flattened XY felts (as signed i128) and returns path `d`.
        fn d_from_flattened_xy(
            self: @ContractState, nodes_xy: Span<felt252>, handle_scale: u32,
        ) -> ByteArray {
            assert(nodes_xy.len() % 2_usize == 0_usize, 'nodes_xy length must be even');
            let mut points: Array<Point> = array![];
            let mut i: usize = 0_usize;
            while i + 1_usize < nodes_xy.len() {
                let x: i128 = (*nodes_xy.at(i)).try_into().unwrap();
                let y: i128 = (*nodes_xy.at(i + 1_usize)).try_into().unwrap();
                points.append(Point { x, y });
                i = i + 2_usize;
            }
            self.d_from_nodes(points.span(), handle_scale)
        }
    }

    #[abi(embed_v0)]
    impl GlyphImpl of IGlyph<ContractState> {
        fn render(self: @ContractState, params: Span<felt252>) -> Array<felt252> {
            let len = params.len();
            assert(len >= 5_usize, 'params too short');
            assert((len - 1_usize) % 2_usize == 0_usize, 'params must be xy pairs');

            let handle_scale: u32 = (*params.at(0_usize)).try_into().unwrap();
            let mut nodes_xy: Array<felt252> = array![];
            let mut i: usize = 1_usize;
            while i < len {
                nodes_xy.append(*params.at(i));
                i = i + 1_usize;
            }

            let d = self.d_from_flattened_xy(nodes_xy.span(), handle_scale);
            let mut out: Array<felt252> = array![];
            d.serialize(ref out);
            out
        }

        fn metadata(self: @ContractState) -> Span<felt252> {
            let mut data: Array<felt252> = array![];
            data.append(META_0);
            data.append(META_1);
            data.append(META_2);
            data.append(META_3);
            data.append(META_4);
            data.span()
        }
    }

    #[starknet::interface]
    pub trait IStepCurve<TContractState> {
        /// Convert ordered nodes into SVG path-data.
        fn d_from_nodes(self: @TContractState, nodes: Span<Point>, handle_scale: u32) -> ByteArray;

        /// Convenience: same as above but with flattened XY felts.
        fn d_from_flattened_xy(
            self: @TContractState, nodes_xy: Span<felt252>, handle_scale: u32,
        ) -> ByteArray;
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _to_cubic_bezier(
            self: @ContractState, nodes: Span<Point>, handle_scale: u32,
        ) -> ByteArray {
            let len = nodes.len();
            if len < 2_usize {
                return Default::default();
            }

            let mut d: ByteArray = Default::default();
            let first = *nodes.at(0_usize);
            d.append(@"M ");
            d.append(@self._i128_to_string(first.x));
            d.append(@" ");
            d.append(@self._i128_to_string(first.y));
            d.append(@"\n");

            let mut i: usize = 0_usize;
            let last_index = len - 1_usize;
            while i < last_index {
                let p0 = if i == 0_usize {
                    *nodes.at(0_usize)
                } else {
                    *nodes.at(i - 1_usize)
                };
                let p1 = *nodes.at(i);
                let p2 = *nodes.at(i + 1_usize);
                let p3 = if i + 2_usize < len {
                    *nodes.at(i + 2_usize)
                } else {
                    *nodes.at(last_index)
                };

                let delta_x1 = p2.x - p0.x;
                let delta_y1 = p2.y - p0.y;
                let delta_x2 = p3.x - p1.x;
                let delta_y2 = p3.y - p1.y;

                let cp1x = p1.x + self._div_round(delta_x1, handle_scale);
                let cp1y = p1.y + self._div_round(delta_y1, handle_scale);
                let cp2x = p2.x - self._div_round(delta_x2, handle_scale);
                let cp2y = p2.y - self._div_round(delta_y2, handle_scale);

                d.append(@" C ");
                d.append(@self._i128_to_string(cp1x));
                d.append(@" ");
                d.append(@self._i128_to_string(cp1y));
                d.append(@", ");
                d.append(@self._i128_to_string(cp2x));
                d.append(@" ");
                d.append(@self._i128_to_string(cp2y));
                d.append(@", ");
                d.append(@self._i128_to_string(p2.x));
                d.append(@" ");
                d.append(@self._i128_to_string(p2.y));
                d.append(@"\n");

                i = i + 1_usize;
            }

            d
        }

        fn _div_round(self: @ContractState, value: i128, handle_scale: u32) -> i128 {
            let denom: i128 = handle_scale.into();
            if denom == 0_i128 {
                return 0_i128;
            }

            if value >= 0_i128 {
                (value + denom / 2_i128) / denom
            } else {
                (value - denom / 2_i128) / denom
            }
        }

        fn _u128_to_string(self: @ContractState, value: u128) -> ByteArray {
            if value == 0_u128 {
                return "0";
            }

            let mut num = value;
            let mut digits: Array<u8> = array![];

            while num != 0_u128 {
                let digit: u8 = (num % 10_u128).try_into().unwrap();
                digits.append(digit);
                num = num / 10_u128;
            }

            let mut result: ByteArray = Default::default();
            let mut i = digits.len();
            while i > 0_usize {
                i = i - 1_usize;
                let digit = *digits.at(i);
                let digit_char = digit + 48_u8;
                result.append_byte(digit_char);
            }

            result
        }

        fn _i128_to_string(self: @ContractState, value: i128) -> ByteArray {
            if value >= 0_i128 {
                let unsigned: u128 = value.try_into().unwrap();
                return self._u128_to_string(unsigned);
            }

            let positive: u128 = (0_i128 - value).try_into().unwrap();
            let mut result: ByteArray = Default::default();
            result.append(@"-");
            let digits = self._u128_to_string(positive);
            result.append(@digits);
            result
        }
    }
}
