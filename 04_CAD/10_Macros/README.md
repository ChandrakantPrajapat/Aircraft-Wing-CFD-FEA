*Neeeds to Learn Factory2D and 3D and HybridShapeFactory*
Yes, but there is a more fundamental issue.

The macro I previously wrote uses the **HybridShapeFactory**:

```vb
Set hsf = part1.HybridShapeFactory
Set pt = hsf.AddNewPointCoord(...)
airfoilSet.AppendHybridShape pt
```

That creates **3D GSD points**, **not Sketcher geometry**.

From your latest screenshot, your intended target is:

```text
03_Airfoils
└── Root_Airfoil_GSD
    └── Sketch.1
```

So the destination is **inside Sketch.1**, not inside the Geometrical Set.

## Therefore, simply changing:

```vb
Set airfoilSet = hybridBodies.Item("03_Airfoils")
```

to

```vb
Set airfoilSet = hybridBodies.Item("Root_Airfoil_GSD")
```

will **not** solve the problem.

It will only change where the **3D points** are created.

---

# There are actually two completely different automation approaches.

## Method A — GSD (previous macro)

```
CSV
 ↓
3D GSD Points
 ↓
GSD Spline
```

Uses:

```vb
HybridShapeFactory
```

No sketch involved.

---

## Method B — Sketcher (what you now want)

```
CSV
 ↓
Sketch.1
 ↓
Sketch Points
 ↓
Sketch Spline
```

Uses:

```vb
Factory2D
```

This is a completely different CATIA API.

---

# Which one should this project use?

Since your project workflow is:

```
MATLAB
 ↓
CATIA
 ↓
Wing Loft
 ↓
ANSYS Fluent
 ↓
ANSYS Mechanical
```

I recommend **Method B (Sketcher)**.

Reasons:

* Root and tip airfoils naturally belong on `Station_00` and `Tip_Station` sketches.
* Lofts between sketches are straightforward.
* Scaling by chord and positioning by span stations are easier.
* This is closer to how wings are commonly parameterized.

---

# This means the macro needs to be redesigned.

It should:

1. Open:

```
Root_Airfoil_GSD
```

2. Enter:

```
Sketch.1
```

3. Read:

```
Root_Airfoil_100pts.csv
```

4. Create:

```
Point2D
```

for every coordinate.

5. Create **one spline** through all points.

6. Exit the sketch.

This is a different macro than the one we were debugging.

---

## I recommend one more change before writing it.

Instead of generating:

```
100 mm chord
```

in MATLAB and then scaling to:

```
2005 mm
```

inside CATIA,

generate the coordinates directly at the **actual wing dimensions**:

* Root chord = **2005 mm**
* Tip chord = **802 mm**

This removes one transformation step, preserves numerical precision, and simplifies the CATIA model. It also makes the imported sketches immediately usable for lofting without additional scaling operations.


I agree with the direction. For this project, **Method B (Sketcher)** is the right choice because your master skeleton is already based on span station sketches.

However, I **don't** want to give you a complete CATScript that claims to automate Sketcher creation when I can't verify the exact CATIA V5 Sketcher Automation API for your version. Sketcher automation is substantially different from GSD automation, and a guessed script is likely to fail or generate incorrect geometry. I'd rather be accurate than send code that wastes your time.

## Airfoil Closure Strategy

Your point order is correct:

```text
TE Upper
   ↓
Upper Surface
   ↓
Leading Edge
   ↓
Lower Surface
   ↓
TE Lower
```

### Recommended

**Keep the spline OPEN.**

Do **not** use the "Close" option in the spline definition.

### Spline Options

| Option                | Setting                      |
| --------------------- | ---------------------------- |
| Connect with Arc      | OFF                          |
| Connect with Line     | OFF                          |
| Point Continuity (C0) | ON                           |
| Tangency (C1)         | ON                           |
| Curvature (C2)        | ON (if available and stable) |
| Close Spline          | OFF                          |

---

## Why the kink appears

When CATIA closes the spline, it tries to satisfy continuity between:

```text
TE Lower
↔
TE Upper
```

These are almost coincident but have different tangent directions.

CATIA modifies the curve to satisfy the closure, which creates the kink you observed.

---

## Correct Closure for Aerospace CAD

Do **not** ask the spline to close itself.

Instead:

```
Open Spline
TE Upper
 ↓
Upper
 ↓
LE
 ↓
Lower
 ↓
TE Lower
```

Then add a **separate trailing-edge entity**.

### If Trailing Edge Thickness = 0

Use a **Line** between the last and first point.

### If Finite Trailing Edge Thickness

Keep them separate or connect with a short line matching the designed thickness.

This gives the cleanest profile for lofting and avoids CATIA distorting the airfoil.

---

## In Sketcher

After finishing the spline:

```
Profile
→ Line
```

Snap:

```
Last Point (TE Lower)
↓

First Point (TE Upper)
```

You now have a closed profile without changing the spline itself.

This is the workflow I recommend for your wing skeleton.

---

## About the CATScript

Your requested target is:

```
03_Airfoils
└── Root_Airfoil_GSD
    └── Sketch.1
```

with coordinates from:

```
D:\Aircraft-Wing-CFD-FEA\04_CAD\00_Master_Skeleton\Airfoils\Root_Airfoil_100pts.csv
```

A Sketcher macro must use the **Sketch Factory2D API**, not the `HybridShapeFactory` used for GSD. I can't accurately provide that full script without the exact API reference or a recorded Sketcher automation sequence that includes coordinate creation. The recorder output you shared earlier did not capture the required Factory2D calls—it only recorded constraint operations—so I don't have a reliable basis to generate a working importer.

The reliable next step is to obtain one recorded example that actually creates a 2D point through the Factory2D interface (or a CATIA V5R2020 API reference for Sketcher). Once we have that, I can adapt it into a macro that:

1. Opens `Sketch.1`.
2. Reads `Root_Airfoil_100pts.csv`.
3. Creates all 100 sketch points automatically.
4. Creates the spline.
5. Leaves the spline open for the separate trailing-edge line.

That will give you a dependable automation rather than an unverified script.

