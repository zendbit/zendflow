type
  Months* = enum
    Januari,
    Februari,
    Maret,
    April,
    Mei,
    Juni,
    Juli,
    Agustus,
    September,
    Oktober,
    November,
    Desember

  PlantingPeriod* = enum
    One,
    Two

let monthList = ["Januari", "Februari", "Maret", "April",
  "Mei", "Juni", "Juli", "Agustus",
  "September", "Oktober", "November", "Desember"]

let r80 = [
  [142.00, 76.00, 51.00, 239.00, 31.00, 99.00, 0.00, 0.00, 0.00, 0.00, 29.50, 124.00],
  [218.00, 281.00, 138.00, 68.50, 32.00, 1.00, 0.00, 0.00, 0.00, 0.00, 190.00, 156.00]]

let r50 = [
  [9.40, 10.20, 7.45, 8.94, 2.35, 2.80, 0.00, 0.00, 0.00, 7.60, 8.90, 9.727],
  [10.31, 9.35, 10.00, 5.38, 5.00, 1.40, 0.10, 0.00, 0.00, 8.90, 9.147, 9.797]]

proc evalPadiWaterIntake(
  ) =
