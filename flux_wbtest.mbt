///|
test "both fluxes are consistent on equal states" {
  let gas = Gas::new(1.4)
  let q = Primitive::new(1.2, 0.7, 0.8)
  for scheme in [Hll, Rusanov] {
    let f = gas.numerical_flux(q, q, scheme)
    assert_true(f.minus(gas.physical_flux(q)).max_abs() < 1.0e-12)
  }
}

///|
test "supersonic HLL is upwind and wall mass flux cancels" {
  let g = Gas::new(1.4)
  let l = Primitive::new(1.0, 4.0, 1.0)
  let r = Primitive::new(0.7, 5.0, 0.4)
  assert_eq(g.numerical_flux(l, r, Hll), g.physical_flux(l))
  for scheme in [Hll, Rusanov] {
    let f = g.numerical_flux(l, reflected(l), scheme)
    assert_eq(f.mass, 0.0)
    assert_eq(f.energy, 0.0)
  }
}
