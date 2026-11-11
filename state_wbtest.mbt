///|
test "ideal gas state validates and exposes sound speed" {
  let gas = Gas::new(1.4)
  let q = Primitive::new(1.0, 0.0, 1.0)
  assert_true((gas.sound_speed(q) - 1.4.sqrt()).abs() < 1.0e-14)
  assert_true((gas.specific_energy(q) - 2.5).abs() < 1.0e-14)
  assert_eq(gas.mach(q), 0.0)
}

///|
test "nonphysical primitive states and gamma are rejected" {
  let a = Some(Primitive::new(0.0, 0.0, 1.0)) catch { _ => None }
  let b = Some(Gas::new(1.0)) catch { _ => None }
  assert_true(a is None)
  assert_true(b is None)
}
