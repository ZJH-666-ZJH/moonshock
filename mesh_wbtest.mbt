///|
test "mesh indexing covers inclusive right endpoint" {
  let m = Mesh::new(-1.0, 1.0, 4)
  assert_eq(m.center(0), -0.75)
  assert_eq(m.locate(1.0), 3)
  assert_eq(m.edge(4), 1.0)
  let bad = Some(m.center(4)) catch { _ => None }
  assert_true(bad is None)
}

///|
test "periodic and reflecting ghost states" {
  let a = Primitive::new(1.0, 2.0, 1.0)
  let b = Primitive::new(3.0, 4.0, 2.0)
  assert_eq(boundary_state([a, b], -1, Periodic), b)
  assert_eq(boundary_state([a, b], 2, Ends(Outflow, Wall)).velocity, -4.0)
  assert_eq(boundary_state([a, b], -1, Ends(Wall, Outflow)).velocity, -2.0)
}
