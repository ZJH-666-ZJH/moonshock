///|
/// A deliberately fixed numeric table rather than a general CSV dialect.
/// Columns: x,rho,velocity,pressure; CRLF and a single terminal newline accepted.
pub fn Simulation::profile_csv(self : Simulation) -> String raise GasError {
  let lines = ["x,rho,velocity,pressure"]
  for i in 0..<self.mesh.cells {
    let q = self.gas.primitive(self.cells[i])
    lines.push("\{self.mesh.center(i)},\{q.rho},\{q.velocity},\{q.pressure}")
  }
  lines.join("\n") + "\n"
}

///|
fn csv_number(text : StringView) -> Double raise GasError {
  if text.length() == 0 || text.trim() != text {
    raise Invalid("empty or padded CSV field")
  }
  let n = @string.parse_double(text) catch {
    _ => raise Invalid("invalid numeric CSV field")
  }
  if !finite(n) {
    raise Invalid("CSV fields must be finite")
  }
  n
}

///|
/// Import primitive cell averages on a supplied mesh. Coordinates must match centers.
/// Quoting, comments, extra columns/rows and blank interior rows are rejected.
pub fn Gas::import_csv(
  self : Gas,
  mesh : Mesh,
  text : String,
) -> Array[Conserved] raise GasError {
  if text.length() > 256000000 {
    raise Invalid("CSV exceeds input limit")
  }
  let rows = text.split("\n").collect()
  if rows.length() > 0 && rows[rows.length() - 1] == "" {
    ignore(rows.pop())
  }
  if rows.length() != mesh.cells + 1 {
    raise Invalid("CSV must have exactly one header and one row per cell")
  }
  let header = rows[0].trim_end(chars="\r")
  if header != "x,rho,velocity,pressure" {
    raise Invalid("unsupported CSV header")
  }
  let cells = []
  for i in 0..<mesh.cells {
    let line = rows[i + 1].trim_end(chars="\r").to_owned()
    let fields = line.split(",").collect()
    if fields.length() != 4 {
      raise Invalid("CSV row requires four fields")
    }
    let x = csv_number(fields[0])
    let expected = mesh.center(i)
    // Absolute tolerance is scaled by cell width, avoiding accidental row swaps
    // on small domains offset by a large coordinate.
    let tolerance = (1.0e-8 * mesh.dx)
      .max(4.0e-15 * expected.abs())
      .min(0.25 * mesh.dx)
    if (x - expected).abs() > tolerance {
      raise Invalid("CSV coordinate does not match mesh center")
    }
    cells.push(
      self.conserved(
        Primitive::new(
          csv_number(fields[1]),
          csv_number(fields[2]),
          csv_number(fields[3]),
        ),
      ),
    )
  }
  self.validate_cells(mesh, cells)
  cells
}
