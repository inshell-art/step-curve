use core::array::{Array, Span};

#[starknet::interface]
pub trait IGlyph<TContractState> {
    fn render(self: @TContractState, params: Span<felt252>) -> Array<felt252>;
    fn metadata(self: @TContractState) -> Span<felt252>;
}
