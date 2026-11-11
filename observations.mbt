///|
/// A spatial cell-average probe with no interpolation across discontinuities.
pub(all) struct Probe {
  x : Double
  index : Int32
  state : Primitive
  mach : Double
} derive(Debug, ToJson)

///|
pub fn Simulation::probes(
  self : Simulation,
  coordinates : Array[Double],
) -> Array[Probe] raise GasError {
  if coordinates.length() > 1000000 {
    raise Invalid("too many probe coordinates")
  }
  let output = []
  for x in coordinates {
    let index = self.mesh.locate(x)
    let state = self.gas.primitive(self.cells[index])
    output.push({ x, index, state, mach: self.gas.mach(state), })
  }
  output
}

///|
/// Lightweight monitor entry; no full cell array is retained.
pub(all) struct Monitor {
  time : Double
  steps : Int32
  retries : Int32
  diagnostics : Diagnostics
  conservation_residual : Conserved
  probes : Array[Probe]
} derive(Debug, ToJson)

///|
pub fn Simulation::monitor(
  self : Simulation,
  coordinates : Array[Double],
) -> Monitor raise GasError {
  {
    time: self.time,
    steps: self.steps,
    retries: self.retries,
    diagnostics: self.diagnostics(),
    conservation_residual: self.conservation_residual(),
    probes: self.probes(coordinates),
  }
}

///|
/// Ordered output times permit equal entries, but reject backward or nonfinite times.
/// Evolution is continuous between observations; every source snapshot is immutable.
pub fn Simulation::observe(
  self : Simulation,
  times : Array[Double],
  coordinates : Array[Double],
  config : SolverConfig,
) -> (Simulation, Array[Monitor]) raise GasError {
  if times.length() > 10000 ||
    coordinates.length() > 10000 ||
    times.length().to_double() * coordinates.length().to_double() > 1000000.0 {
    raise Invalid("observation request exceeds bounded output budget")
  }
  let mut previous = self.time
  for t in times {
    if !finite(t) || t < previous {
      raise Invalid(
        "observation times must be finite and ordered after snapshot",
      )
    }
    previous = t
  }
  for x in coordinates {
    ignore(self.mesh.locate(x))
  }
  let mut current = self
  let output = []
  for t in times {
    current = current.run_until(t, config)
    output.push(current.monitor(coordinates))
  }
  (current, output)
}

///|
pub fn monitors_json(monitors : Array[Monitor]) -> String {
  Json::array(monitors.map(fn(m) { m.to_json() })).stringify()
}

///|
pub extend Probe with @debug.Debug::{to_repr}

///|
pub extend Probe with ToJson::{to_json}

///|
pub extend Monitor with @debug.Debug::{to_repr}

///|
pub extend Monitor with ToJson::{to_json}
