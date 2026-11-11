///|
test "numeric profile CSV roundtrip" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 4)
  let s = Simulation::new(g, m, g.entropy_wave(m, 1.0, 0.2, 0.5, 1.0, 0.0))
  let cells = g.import_csv(m, s.profile_csv())
  for i in 0..<4 {
    assert_true(cells[i].minus(s.cells()[i]).max_abs() < 1.0e-13)
  }
}

///|
test "CSV rejects swapped coordinates nonphysical and nonfinite fields" {
  let g = Gas::new(1.4)
  let m = Mesh::new(0.0, 1.0, 2)
  for
    text in [
      "x,rho,velocity,pressure\n0.75,1,0,1\n0.25,1,0,1\n", "x,rho,velocity,pressure\n0.25,-1,0,1\n0.75,1,0,1\n",
      "x,rho,velocity,pressure\n0.25,NaN,0,1\n0.75,1,0,1\n", "x,rho,velocity,pressure\n0.25,1,0,1\n\n0.75,1,0,1\n",
    ] {
    let bad = Some(g.import_csv(m, text)) catch { _ => None }
    assert_true(bad is None)
  }
}
