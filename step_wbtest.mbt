///|
test "finite volume preserves a uniform moving gas" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 16)
  let cells = g.uniform(m, Primitive::new(1.0, 0.3, 1.0))
  for integrator in [ForwardEuler, SspRk2] {
    let dt = g.stable_dt(m, cells, 0.4)
    let next = g.advance(m, cells, dt, Periodic, Minmod, Hll, integrator)
    assert_eq(next.cells, cells)
    assert_eq(next.boundary_change, Conserved::zero())
  }
}

///|
test "invalid timestep leaves input unchanged" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 4)
  let cells = g.uniform(m, Primitive::new(1.0, 0.0, 1.0))
  let original = cells.copy()
  let result = Some(
    g.advance(m, cells, 1.0, Periodic, Constant, Hll, ForwardEuler),
  ) catch {
    _ => None
  }
  assert_true(result is None)
  assert_eq(cells, original)
}
