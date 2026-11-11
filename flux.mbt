///|
/// HLL uses two signal speeds; Rusanov uses a symmetric local maximum.
pub(all) enum FluxMethod {
  Hll
  Rusanov
} derive(Debug, Eq)

///|
pub fn Gas::numerical_flux(
  self : Gas,
  left : Primitive,
  right : Primitive,
  scheme : FluxMethod,
) -> Conserved raise GasError {
  let ul = self.conserved(left)
  let ur = self.conserved(right)
  let fl = self.physical_flux(left)
  let fr = self.physical_flux(right)
  let cl = self.sound_speed(left)
  let cr = self.sound_speed(right)
  let result = match scheme {
    Rusanov => {
      let a = (left.velocity.abs() + cl).max(right.velocity.abs() + cr)
      fl.plus(fr).scaled(0.5).minus(ur.minus(ul).scaled(0.5 * a))
    }
    Hll => {
      let sl = (left.velocity - cl).min(right.velocity - cr)
      let sr = (left.velocity + cl).max(right.velocity + cr)
      if sl >= 0.0 {
        fl
      } else if sr <= 0.0 {
        fr
      } else {
        fl
        .scaled(sr)
        .minus(fr.scaled(sl))
        .plus(ur.minus(ul).scaled(sl * sr))
        .scaled(1.0 / (sr - sl))
      }
    }
  }
  if !finite(result.mass) || !finite(result.momentum) || !finite(result.energy) {
    raise Numerical("numerical flux exceeds floating point range")
  }
  result
}

///|
pub extend FluxMethod with @debug.Debug::{to_repr}

///|
pub extend FluxMethod with Eq::{equal, not_equal}
