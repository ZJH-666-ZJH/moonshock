///|
test "Sod exact sampler resolves fan star contact and shock" {
  let g = Gas::new(1.4)
  let l = Primitive::new(1.0, 0.0, 1.0)
  let r = Primitive::new(0.125, 0.0, 0.1)
  let s = g.riemann(l, r)
  assert_eq(s.sample(-2.0), l)
  assert_eq(s.sample(3.0), r)
  assert_true((s.sample(0.0).rho - 0.4263194281784952).abs() < 1.0e-10)
  assert_true((s.sample(1.0).rho - 0.2655737117053071).abs() < 1.0e-10)
  let fan = s.sample(-0.5)
  assert_true(fan.rho < 1.0 && fan.rho > 0.42)
  assert_true((fan.pressure / @math.pow(fan.rho, 1.4) - 1.0).abs() < 1.0e-10)
}

///|
test "exact solution is invariant under reflection and velocity translation" {
  let g = Gas::new(1.4)
  let l = Primitive::new(1.0, 0.0, 1.0)
  let r = Primitive::new(0.125, 0.0, 0.1)
  let a = g.riemann(l, r)
  let b = g.riemann(reflected(r), reflected(l))
  for x in [-2.0, -0.5, 0.0, 1.0, 3.0] {
    let p = a.sample(x)
    let q = b.sample(-x)
    assert_true((p.rho - q.rho).abs() < 1.0e-10)
    assert_true((p.velocity + q.velocity).abs() < 1.0e-10)
  }
  assert_eq(a.at(0.0, 0.0, 0.5), l)
  assert_eq(a.wave_speeds().length(), 4)
}
