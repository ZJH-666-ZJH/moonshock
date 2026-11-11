///|
test "limiters suppress extrema and preserve linear slopes" {
  assert_eq(limited(1.0, -2.0, MonotonizedCentral), 0.0)
  assert_eq(limited(2.0, 2.0, Minmod), 2.0)
  assert_eq(limited(-1.0, -2.0, MonotonizedCentral), -1.5)
  let q = [
    Primitive::new(1.0, 0.0, 1.0),
    Primitive::new(2.0, 0.0, 2.0),
    Primitive::new(3.0, 0.0, 3.0),
  ]
  let (l, r) = reconstruct(q, Ends(Outflow, Outflow), MonotonizedCentral)
  assert_eq(l[1].rho, 1.5)
  assert_eq(r[1].pressure, 2.5)
}

///|
test "reconstructed wall flux has no mass or energy leakage" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 8)
  let states = g.uniform(m, Primitive::new(1.0, 0.7, 1.0))
  let f = g.interface_fluxes(
    m,
    states,
    Ends(Wall, Wall),
    MonotonizedCentral,
    Hll,
  )
  assert_eq(f.length(), 9)
  assert_eq(f[0].mass, 0.0)
  assert_eq(f[8].energy, 0.0)
}
