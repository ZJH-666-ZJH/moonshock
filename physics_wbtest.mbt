///|
test "all numerical policies preserve a uniform periodic moving state" {
  let g = Gas::new(1.4)
  let m = Mesh::new(-1.0, 1.0, 20)
  let q = Primitive::new(0.8, 0.7, 1.2)
  let s = Simulation::new(g, m, g.uniform(m, q))
  for mode in [Constant, Minmod, MonotonizedCentral] {
    for flux in [Hll, Rusanov] {
      for integrator in [ForwardEuler, SspRk2] {
        let config = SolverConfig::new(Periodic, mode, flux, integrator)
        let out = s.run_until(0.1, config)
        for u in out.cells {
          assert_true(u.minus(g.conserved(q)).max_abs() < 1.0e-12)
        }
        assert_true(out.conservation_residual().max_abs() < 1.0e-12)
      }
    }
  }
}

///|
test "reflecting walls conserve mass and total energy in a symmetric collision" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 64)
  let l = Primitive::new(1.0, 0.8, 0.5)
  let r = Primitive::new(1.0, -0.8, 0.5)
  let s = Simulation::new(g, m, g.shock_tube(m, l, r, 0.5))
  let c = SolverConfig::new(Ends(Wall, Wall), MonotonizedCentral, Hll, SspRk2)
  let out = s.run_until(0.1, c)
  let before = s.diagnostics().totals
  let after = out.diagnostics().totals
  assert_true((after.mass - before.mass).abs() < 1.0e-12)
  assert_true((after.energy - before.energy).abs() < 1.0e-12)
  for i in 0..<32 {
    let a = g.primitive(out.cells[i])
    let b = g.primitive(out.cells[63 - i])
    assert_true(
      (a.rho - b.rho).abs() < 1.0e-11 &&
      (a.velocity + b.velocity).abs() < 1.0e-11,
    )
  }
}

///|
test "strong shock and nonvacuum double rarefaction stay physical" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 64)
  for
    pair in [
      (Primitive::new(1.0, 0.0, 1000.0), Primitive::new(1.0, 0.0, 0.01)),
      (Primitive::new(1.0, -2.0, 0.4), Primitive::new(1.0, 2.0, 0.4)),
    ] {
    let (l, r) = pair
    let out = Simulation::new(g, m, g.shock_tube(m, l, r, 0.5)).run_until(
      0.004,
      SolverConfig::standard(),
    )
    let d = out.diagnostics()
    assert_true(d.min_density > 0.0 && d.min_pressure > 0.0)
    assert_true(out.conservation_residual().max_abs() < 1.0e-9)
  }
}

///|
test "exact Riemann solution is Galilean covariant" {
  let g = Gas::new(1.4)
  let (l, r) = Lax.states()
  let shift = 1.7
  let base = g.riemann(l, r)
  let moved = g.riemann(
    Primitive::new(l.rho, l.velocity + shift, l.pressure),
    Primitive::new(r.rho, r.velocity + shift, r.pressure),
  )
  assert_true((base.pressure - moved.pressure).abs() < 1.0e-10)
  for xi in [-3.0, -0.5, 0.0, 1.0, 3.0] {
    let a = base.sample(xi)
    let b = moved.sample(xi + shift)
    assert_true((a.rho - b.rho).abs() < 1.0e-10)
    assert_true((a.velocity + shift - b.velocity).abs() < 1.0e-10)
  }
}

///|
test "checkpoint rejects duplicates extra keys and nonphysical states" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 4)
  let text = Simulation::new(g, m, g.uniform(m, Primitive::new(1.0, 0.0, 1.0))).checkpoint()
  for
    bad in [
      text.replace(old="\"schema\":1", new="\"schema\":1,\"schema\":1"),
      text.replace(old="\"schema\":1", new="\"schema\":1,\"unknown\":0"),
      text.replace(old="\"cells\":[{\"mass\":1", new="\"cells\":[{\"mass\":0"),
    ] {
    let result = Some(restore_checkpoint(bad)) catch { _ => None }
    assert_true(result is None)
  }
}
