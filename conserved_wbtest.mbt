///|
test "primitive conservative roundtrip and physical flux" {
  let g = Gas::new(1.4)
  let q = Primitive::new(2.0, 3.0, 4.0)
  let u = g.conserved(q)
  assert_true((u.energy - 19.0).abs() < 1.0e-12)
  let r = g.primitive(u)
  assert_true((r.pressure - 4.0).abs() < 1.0e-12)
  let f = g.physical_flux(q)
  assert_true((f.energy - 69.0).abs() < 1.0e-12)
  assert_eq(f.mass, 6.0)
  assert_eq(f.momentum, 22.0)
}

///|
test "negative internal energy is an error" {
  let g = Gas::new(1.4)
  let r = Some(g.primitive({ mass: 1.0, momentum: 10.0, energy: 1.0, })) catch {
    _ => None
  }
  assert_true(r is None)
}
