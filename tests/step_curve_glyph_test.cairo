use core::array::{Array, ArrayTrait, Span, SpanTrait};
use core::byte_array::{ByteArray, ByteArrayTrait};
use core::serde::Serde;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};
use starknet::ContractAddress;
use step_curve::glyph_interface::{IGlyphDispatcher, IGlyphDispatcherTrait};
use step_curve::StepCurve::StepCurve::{IStepCurveDispatcher, IStepCurveDispatcherTrait};

fn deploy_step_curve() -> ContractAddress {
    let class = declare("StepCurve").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![];
    let result = class.deploy(@calldata).unwrap();
    let (address, _) = result;
    address
}

fn serialize_bytearray(value: ByteArray) -> Array<felt252> {
    let mut out: Array<felt252> = array![];
    value.serialize(ref out);
    out
}

fn assert_felt_array_eq(left: @Array<felt252>, right: @Array<felt252>) {
    assert(left.len() == right.len(), 'array len mismatch');
    let mut i: usize = 0_usize;
    while i < left.len() {
        assert(*left.at(i) == *right.at(i), 'array mismatch');
        i = i + 1_usize;
    }
}

fn assert_span_eq(actual: Span<felt252>, expected: @Array<felt252>) {
    assert(actual.len() == expected.len(), 'span len mismatch');
    let mut i: usize = 0_usize;
    while i < actual.len() {
        assert(*actual.at(i) == *expected.at(i), 'span mismatch');
        i = i + 1_usize;
    }
}

#[test]
fn d_from_flattened_xy_returns_expected() {
    let contract = deploy_step_curve();
    let dispatcher = IStepCurveDispatcher { contract_address: contract };

    let mut nodes: Array<felt252> = array![0, 0, 100, 100];
    let d = dispatcher.d_from_flattened_xy(nodes.span(), 10_u32);

    let mut expected: ByteArray = Default::default();
    expected.append(@"M 0 0\n C 10 10, 90 90, 100 100\n");

    let d_ser = serialize_bytearray(d);
    let expected_ser = serialize_bytearray(expected);
    assert_felt_array_eq(@d_ser, @expected_ser);
}

#[test]
fn render_matches_d_from_flattened_xy() {
    let contract = deploy_step_curve();
    let dispatcher = IStepCurveDispatcher { contract_address: contract };
    let glyph = IGlyphDispatcher { contract_address: contract };

    let mut params: Array<felt252> = array![10, 0, 0, 100, 100];
    let rendered = glyph.render(params.span());

    let mut nodes: Array<felt252> = array![0, 0, 100, 100];
    let d = dispatcher.d_from_flattened_xy(nodes.span(), 10_u32);
    let expected = serialize_bytearray(d);

    assert_felt_array_eq(@rendered, @expected);
}

#[test]
fn metadata_returns_expected_chunks() {
    let contract = deploy_step_curve();
    let glyph = IGlyphDispatcher { contract_address: contract };
    let meta = glyph.metadata();

    let expected: Array<felt252> = array![
        'name=step_curve;kind=svg;',
        'tag=path-d;version=0.1.0;',
        'params=handle_scale,xy_pairs;',
        'returns=svg_path_d;',
        'immutable=true',
    ];

    assert_span_eq(meta, @expected);
}
