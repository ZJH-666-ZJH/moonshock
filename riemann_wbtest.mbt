///|
test "Sod star pressure and velocity match published analytic reference" {
  let g = Gas::new(1.4)
  let r = g.riemann(
    Primitive::new(1.0, 0.0, 1.0),
    Primitive::new(0.125, 0.0, 0.1),
  )
  assert_true((r.pressure() - 0.3031301780506468).abs() < 1.0e-10)
  assert_true((r.velocity() - 0.9274526200489499).abs() < 1.0e-10)
  assert_true((r.star_density(true) - 0.4263194281784952).abs() < 1.0e-10)
  assert_true((r.star_density(false) - 0.2655737117053071).abs() < 1.0e-10)
}

///|
test "equal state star and vacuum rejection" {
  let g = Gas::new(1.4)
  let q = Primitive::new(1.0, 0.2, 1.0)
  let r = g.riemann(q, q)
  assert_true((r.pressure() - 1.0).abs() < 1.0e-10)
  assert_eq(r.velocity(), 0.2)
  let bad = Some(
    g.riemann(Primitive::new(1.0, -10.0, 1.0), Primitive::new(1.0, 10.0, 1.0)),
  ) catch {
    _ => None
  }
  assert_true(bad is None)
}
