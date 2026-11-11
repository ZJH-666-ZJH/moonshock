///|
/// Conservative piecewise-constant overlap remapping on the exact same domain.
/// Integrated mass/momentum/energy are preserved to floating-point summation error.
pub fn Gas::remap(
  self : Gas,
  source : Mesh,
  cells : Array[Conserved],
  target : Mesh,
) -> Array[Conserved] raise GasError {
  self.validate_cells(source, cells)
  if source.left != target.left || source.right != target.right {
    raise Invalid("remap domains must have identical edges")
  }
  let output = []
  let mut from = 0
  for j in 0..<target.cells {
    let a = target.edge(j)
    let b = target.edge(j + 1)
    while from + 1 < source.cells && source.edge(from + 1) <= a {
      from = from + 1
    }
    let mut i = from
    let mut total = Conserved::zero()
    let mut covered = 0.0
    while i < source.cells && source.edge(i) < b {
      let overlap = source.edge(i + 1).min(b) - source.edge(i).max(a)
      if overlap > 0.0 {
        total = total.plus(cells[i].scaled(overlap))
        covered = covered + overlap
      }
      i = i + 1
    }
    let width = b - a
    if covered <= 0.0 || (covered - width).abs() > 1.0e-10 * width {
      raise Numerical("remap overlap coverage failed")
    }
    let u = total.scaled(1.0 / width)
    ignore(self.primitive(u))
    output.push(u)
  }
  output
}

///|
/// Remapping starts a new conservation ledger at the same physical time.
/// Accepted-step/retry counters restart; source checkpoint remains unchanged.
pub fn Simulation::remeshed(
  self : Simulation,
  target : Mesh,
) -> Simulation raise GasError {
  Simulation::new(
    self.gas,
    target,
    self.gas.remap(self.mesh, self.cells, target),
    time=self.time,
  )
}

///|
/// Integrate an interval of piecewise constant conserved cell averages.
pub fn Gas::integrate(
  self : Gas,
  mesh : Mesh,
  cells : Array[Conserved],
  left : Double,
  right : Double,
) -> Conserved raise GasError {
  self.validate_cells(mesh, cells)
  if !finite(left) ||
    !finite(right) ||
    left < mesh.left ||
    right > mesh.right ||
    right < left {
    raise Invalid("invalid integration interval")
  }
  let mut total = Conserved::zero()
  for i in 0..<mesh.cells {
    let overlap = mesh.edge(i + 1).min(right) - mesh.edge(i).max(left)
    if overlap > 0.0 {
      total = total.plus(cells[i].scaled(overlap))
    }
  }
  if !finite(total.mass) || !finite(total.momentum) || !finite(total.energy) {
    raise Numerical("interval integral overflow")
  }
  total
}
