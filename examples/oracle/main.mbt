///|
fn emit(gamma : Double, l : @gas.Primitive, r : @gas.Primitive) -> Unit raise {
  let g = @gas.Gas::new(gamma)
  let exact = g.riemann(l, r)
  let samples : Array[Json] = []
  for xi in [-4.0, -2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0, 4.0] {
    samples.push(
      Json::object({ "xi": Json::number(xi), "q": exact.sample(xi).to_json() }),
    )
  }
  println(
    Json::object({
      "gamma": Json::number(gamma),
      "left": l.to_json(),
      "right": r.to_json(),
      "p": Json::number(exact.pressure()),
      "u": Json::number(exact.velocity()),
      "rho_l": Json::number(exact.star_density(true)),
      "rho_r": Json::number(exact.star_density(false)),
      "speeds": Json(exact.wave_speeds()),
      "samples": Json::array(samples),
    }).stringify(),
  )
}

///|
fn main {
  try {
    for i in 0..<40 {
      let gamma = 1.2 + (i % 5).to_double() * 0.1
      let l = @gas.Primitive::new(
        0.4 + (i % 7).to_double() * 0.3,
        -0.7 + (i % 6).to_double() * 0.3,
        0.2 + (i % 9).to_double() * 0.4,
      )
      let r = @gas.Primitive::new(
        0.3 + (i % 8).to_double() * 0.2,
        0.6 - (i % 5).to_double() * 0.25,
        0.1 + (i % 4).to_double() * 0.7,
      )
      emit(gamma, l, r)
    }
    let (l, r) = @gas.TubeCase::Sod.states()
    emit(1.4, l, r)
    let (l, r) = @gas.TubeCase::Lax.states()
    emit(1.4, l, r)
  } catch {
    error => abort("oracle export failed: \{error}")
  }
}
