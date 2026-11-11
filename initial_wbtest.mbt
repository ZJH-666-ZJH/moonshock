///|
test "initial discontinuity integrates fractional cells conservatively" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 4)
  let (l, r) = Sod.states()
  let q = g.shock_tube(m, l, r, 0.375)
  assert_eq(q[0].mass, 1.0)
  assert_eq(q[1].mass, 0.5625)
  assert_eq(q[2].mass, 0.125)
}

///|
test "entropy wave cell averages sum to mean density" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 32)
  let q = g.entropy_wave(m, 1.0, 0.2, 0.5, 1.0, 0.3)
  let mut total = 0.0
  for u in q {
    total = total + u.mass * m.dx
  }
  assert_true((total - 1.0).abs() < 1.0e-14)
}
