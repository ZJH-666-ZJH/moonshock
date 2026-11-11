///|
/// A bounded uniform mesh; coordinates describe cell edges.
pub struct Mesh {
  left : Double
  right : Double
  cells : Int32
  dx : Double
} derive(Debug, Eq)

///|
pub fn Mesh::new(
  left : Double,
  right : Double,
  cells : Int32,
) -> Mesh raise GasError {
  if !finite(left) ||
    !finite(right) ||
    right <= left ||
    cells < 2 ||
    cells > 1000000 {
    raise Invalid("mesh needs finite increasing edges and 2..1000000 cells")
  }
  let dx = (right - left) / cells.to_double()
  if !finite(dx) || dx <= 0.0 || left + dx <= left || right - dx >= right {
    raise Invalid("mesh spacing is not representable")
  }
  { left, right, cells, dx, }
}

///|
pub fn Mesh::cells(self : Mesh) -> Int32 {
  self.cells
}

///|
pub fn Mesh::left(self : Mesh) -> Double {
  self.left
}

///|
pub fn Mesh::right(self : Mesh) -> Double {
  self.right
}

///|
pub fn Mesh::dx(self : Mesh) -> Double {
  self.dx
}

///|
pub fn Mesh::center(self : Mesh, index : Int32) -> Double raise GasError {
  if index < 0 || index >= self.cells {
    raise Invalid("cell index outside mesh")
  }
  self.left + (index.to_double() + 0.5) * self.dx
}

///|
pub fn Mesh::edge(self : Mesh, index : Int32) -> Double raise GasError {
  if index < 0 || index > self.cells {
    raise Invalid("edge index outside mesh")
  }
  if index == self.cells {
    self.right
  } else {
    self.left + index.to_double() * self.dx
  }
}

///|
pub fn Mesh::locate(self : Mesh, x : Double) -> Int32 raise GasError {
  if !finite(x) || x < self.left || x > self.right {
    raise Invalid("coordinate outside mesh")
  }
  if x == self.right {
    self.cells - 1
  } else {
    ((x - self.left) / self.dx).to_int().min(self.cells - 1)
  }
}

///|
/// Both ends are periodic together, or each end independently transmits/reflects.
pub(all) enum EndBoundary {
  Outflow
  Wall
} derive(Debug, Eq)

///|
pub(all) enum Boundaries {
  Periodic
  Ends(EndBoundary, EndBoundary)
} derive(Debug, Eq)

///|
fn reflected(q : Primitive) -> Primitive {
  { rho: q.rho, velocity: -q.velocity, pressure: q.pressure, }
}

///|
pub fn boundary_state(
  q : Array[Primitive],
  index : Int32,
  bc : Boundaries,
) -> Primitive raise GasError {
  let n = q.length()
  if n < 2 || index < -1 || index > n {
    raise Invalid("boundary stencil out of range")
  }
  for state in q {
    state.validate()
  }
  if index >= 0 && index < n {
    return q[index]
  }
  match bc {
    Periodic => q[if index < 0 { n - 1 } else { 0 }]
    Ends(left, right) => {
      let value = q[if index < 0 { 0 } else { n - 1 }]
      match (if index < 0 { left } else { right }) {
        Outflow => value
        Wall => reflected(value)
      }
    }
  }
}

///|
pub fn Gas::validate_cells(
  self : Gas,
  mesh : Mesh,
  states : Array[Conserved],
) -> Unit raise GasError {
  if states.length() != mesh.cells {
    raise Invalid("cell array length differs from mesh")
  }
  for u in states {
    ignore(self.primitive(u))
  }
}

///|
pub extend Mesh with @debug.Debug::{to_repr}

///|
pub extend Mesh with Eq::{equal, not_equal}

///|
pub extend EndBoundary with @debug.Debug::{to_repr}

///|
pub extend EndBoundary with Eq::{equal, not_equal}

///|
pub extend Boundaries with @debug.Debug::{to_repr}

///|
pub extend Boundaries with Eq::{equal, not_equal}
