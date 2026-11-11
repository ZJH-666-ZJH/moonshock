///|
/// Sample the self-similar exact solution at xi=(x-interface)/t.
/// At the contact itself the left star state is returned.
pub fn Riemann::sample(self : Riemann, xi : Double) -> Primitive raise GasError {
  if !finite(xi) {
    raise Invalid("similarity coordinate must be finite")
  }
  let gamma = self.gas.gamma
  let gm = gamma - 1.0
  let gp = gamma + 1.0
  let p = self.pressure
  let u = self.velocity
  let left_side = xi <= u
  let q = if left_side { self.left } else { self.right }
  let c = self.gas.sound_speed(q)
  if p > q.pressure {
    let factor = (gp / (2.0 * gamma) * (p / q.pressure) + gm / (2.0 * gamma)).sqrt()
    let speed = q.velocity + (if left_side { -1.0 } else { 1.0 }) * c * factor
    if (left_side && xi <= speed) || (!left_side && xi >= speed) {
      return q
    }
    return Primitive::new(self.star_density(left_side), u, p)
  }
  let cstar = c * @math.pow(p / q.pressure, gm / (2.0 * gamma))
  if left_side {
    let head = q.velocity - c
    let tail = u - cstar
    if xi <= head {
      return q
    }
    if xi >= tail {
      return Primitive::new(self.star_density(true), u, p)
    }
    let velocity = 2.0 / gp * (c + 0.5 * gm * q.velocity + xi)
    let sound = 2.0 / gp * (c + 0.5 * gm * (q.velocity - xi))
    let ratio = sound / c
    Primitive::new(
      q.rho * @math.pow(ratio, 2.0 / gm),
      velocity,
      q.pressure * @math.pow(ratio, 2.0 * gamma / gm),
    )
  } else {
    let head = q.velocity + c
    let tail = u + cstar
    if xi >= head {
      return q
    }
    if xi <= tail {
      return Primitive::new(self.star_density(false), u, p)
    }
    let velocity = 2.0 / gp * (-c + 0.5 * gm * q.velocity + xi)
    let sound = 2.0 / gp * (c - 0.5 * gm * (q.velocity - xi))
    let ratio = sound / c
    Primitive::new(
      q.rho * @math.pow(ratio, 2.0 / gm),
      velocity,
      q.pressure * @math.pow(ratio, 2.0 * gamma / gm),
    )
  }
}

///|
pub fn Riemann::at(
  self : Riemann,
  x : Double,
  time : Double,
  interface_at : Double,
) -> Primitive raise GasError {
  if !finite(x) || !finite(time) || !finite(interface_at) || time < 0.0 {
    raise Invalid("coordinates must be finite and time nonnegative")
  }
  if time == 0.0 {
    return if x <= interface_at { self.left } else { self.right }
  }
  self.sample((x - interface_at) / time)
}

///|
/// Four moving edges: left wave head/tail, right wave tail/head.
/// A shock occupies a single speed, represented twice.
pub fn Riemann::wave_speeds(self : Riemann) -> Array[Double] raise GasError {
  let g = self.gas.gamma
  let speeds : Array[Double] = []
  for left_side in [true, false] {
    let q = if left_side { self.left } else { self.right }
    let c = self.gas.sound_speed(q)
    let direction = if left_side { -1.0 } else { 1.0 }
    if self.pressure > q.pressure {
      let s = q.velocity +
        direction *
        c *
        (((g + 1.0) * self.pressure / q.pressure + (g - 1.0)) / (2.0 * g)).sqrt()
      speeds.push(s)
      speeds.push(s)
    } else {
      let head = q.velocity + direction * c
      let tail = self.velocity +
        direction *
        c *
        @math.pow(self.pressure / q.pressure, (g - 1.0) / (2.0 * g))
      if left_side {
        speeds.push(head)
        speeds.push(tail)
      } else {
        speeds.push(tail)
        speeds.push(head)
      }
    }
  }
  speeds
}
