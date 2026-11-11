///|
test "experiment configuration roundtrip preserves inputs and produces same run" {
  let g = Gas::new(1.4)
  let (l, r) = Sod.states()
  let e = Experiment::new(
    "Sod JSON",
    g,
    Mesh::new(0.0, 1.0, 24),
    l,
    r,
    0.5,
    0.05,
    SolverConfig::standard(),
  )
  let restored = parse_experiment(e.json_config())
  assert_eq(restored.json_config(), e.json_config())
  assert_eq(restored.run().simulation.cells(), e.run().simulation.cells())
}

///|
test "strict experiment JSON rejects duplicate keys unknown enums and fractional counts" {
  let g = Gas::new(1.4)
  let (l, r) = Sod.states()
  let e = Experiment::new(
    "Sod",
    g,
    Mesh::new(0.0, 1.0, 24),
    l,
    r,
    0.5,
    0.05,
    SolverConfig::standard(),
  )
  for
    text in [
      "{}",
      e
      .json_config()
      .replace(old="\"schema\":1", new="\"schema\":1,\"schema\":1"),
      e.json_config().replace(old="\"hll\"", new="\"hllc\""),
      e.json_config().replace(old="\"cells\":24", new="\"cells\":24.5"),
    ] {
    let result = Some(parse_experiment(text)) catch { _ => None }
    assert_true(result is None)
  }
}
