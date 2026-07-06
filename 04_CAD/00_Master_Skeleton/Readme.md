# 04_CAD/00_Master_Skeleton/Airfoils

# Airfoil Generation Workflow (MATLAB → Excel VBA → CATIA V5)

## Overview

This document describes the finalized workflow for generating parametric NACA airfoils for the aircraft wing master skeleton.

The workflow is intended for:

- CATIA V5-6R2020
- Generative Shape Design (GSD)
- MATLAB-generated coordinates
- Professional aerospace CAD workflow
- Subsequent CFD and FEA analysis

This document also preserves all discovered issues, failed approaches, successful methods, engineering decisions, and future improvements.

---

# Current Workflow (Approved)

```
MATLAB
        │
        ▼
Root_Airfoil_100pts.csv
Tip_Airfoil_100pts.csv
        │
        ▼
Paste into Excel VBA Template
        │
        ▼
Run VBA Macro
        │
        ▼
CATIA V5
Generative Shape Design
        │
        ▼
Airfoil Points
        │
        ▼
Spline Generation
        │
        ▼
Wing Surface Development
```

Status

```
WORKING
```

---

# Software Versions

MATLAB

CATIA

```
CATIA V5-6R2020 (P3)
```

Microsoft Office

```
Latest Microsoft Office
```

---

# Aircraft Configuration (Frozen)

Aircraft Configuration Version 1

| Parameter | Value |
|------------|---------|
| Wing Area | 17.73 m² |
| Span | 12.63 m |
| Root Chord | 2.005 m |
| Tip Chord | 0.802 m |
| Taper Ratio | 0.40 |
| Leading Edge Sweep | 5° |
| Front Spar | 25% chord |
| Rear Spar | 65% chord |
| Rib Spacing | 0.5 m |
| Skin Thickness | 3 mm |

Status

```
DESIGN FROZEN
```

Date

```
2026-05-16
```

---

# Coordinate Generation

Coordinates are generated in MATLAB.

Current export:

```
Root_Airfoil_100pts.csv
Tip_Airfoil_100pts.csv
```

Characteristics

- 100 coordinate points
- Cosine spacing
- High density near Leading Edge
- High density near Trailing Edge
- Smooth spline generation
- Suitable for CATIA lofts
- Suitable for CFD

---

# Coordinate Order

```
TE Upper
      │
      ▼
Upper Surface
      │
      ▼
Leading Edge
      │
      ▼
Lower Surface
      │
      ▼
TE Lower
```

This ordering shall NOT be modified.

---

# Excel Template

The CATIA VBA macro expects the following structure.

```
StartLoft
StartCurve

X    Y    Z
...
...
...

EndCurve
EndLoft
End
```

---

# IMPORTANT

The macro parser is sensitive to termination keywords.

The workbook SHALL preserve this exact order.

---

# Issue Log

---

## Issue 1

Infinite Loop After EndCurve

Status

```
SOLVED
```

Symptoms

After generating all points the VBA macro continued indefinitely until CATIA eventually crashed.

The macro never terminated after creating the final coordinate.

---

Incorrect Ending

```
EndCurve
EndCurve
EndCurve
```

This caused the VBA parser to continue reading.

---

Working Ending

```
EndCurve
EndLoft
End
```

The parser terminates correctly.

---

Engineering Note

The VBA macro expects the complete Loft structure, not only EndCurve.

Future modifications should preserve these keywords exactly.

---

## Issue 2

Excel Formatting

Status

```
VERIFIED
```

Formatting was investigated.

The formatting itself was NOT the cause.

Verified

- EndCurve in Column A
- Empty remaining columns
- No formulas
- No merged cells
- No trailing spaces

Root cause was Issue 1.

---

## Issue 3

Importing Into Sketcher

Status

```
PARTIALLY WORKING
```

### Attempt A

Generate directly inside Sketch.1

Expected

```
Sketch.1

│

Points

Spline
```

Observed

The VBA macro ignores the active sketch.

Instead it creates

```
GeometryFromExcel
```

inside a new Geometrical Set.

Even when Sketch.1 is active.

Current Status

```
NOT SOLVED
```

Possible Cause

The VBA macro creates HybridShape geometry only.

No Sketch Factory API is used.

Future Work

Modify VBA to create native Sketch entities using Factory2D instead of HybridShapeFactory.

---

### Attempt B

Generate in GSD

```
GeometryFromExcel

↓

Spline

↓

Project into Sketch
```

Status

```
WORKING
```

Warnings

Projected geometry

- is reference geometry
- is not fully editable
- may complicate future parametric modifications

Recommended only if native Sketch import is unavailable.

---

## Issue 4

Trailing Edge Kink

Status

```
NOT OBSERVED
```

Reason

Direct VBA spline generation produced a smooth airfoil.

Manual spline creation previously introduced a trailing edge kink.

Current Recommendation

Leave VBA spline generation unchanged.

---

# Recommended Spline Settings

Spline

```
Enabled
```

Point Continuity

```
Enabled
```

Tangency Continuity

```
Enabled
```

Curvature Continuity

```
Enabled
```

Connect with Arc

```
Disabled
```

Connect with Line

```
Disabled
```

Close Spline Automatically

```
Disabled
```

---

# Scaling Requirements

MATLAB exports a normalized airfoil.

Current export chord

```
100 mm
```

Required CAD scaling

Root Airfoil

```
100 mm

↓

2005 mm
```

Scale Factor

```
20.05
```

Tip Airfoil

```
100 mm

↓

802 mm
```

Scale Factor

```
8.02
```

Scaling should be performed AFTER spline generation.

Scaling should occur before loft creation.

---

# Wing Positioning

Root Station

```
Y = 0
```

Tip Station

```
Y = 6315 mm
```

Leading Edge Sweep

```
5°
```

Chord Reduction

```
2005 mm

↓

802 mm
```

---

# Current Folder Structure

```
04_CAD

└── 00_Master_Skeleton

        ├── Airfoils

        │       Root_Airfoil_100pts.csv

        │       Tip_Airfoil_100pts.csv

        │

        ├── Root_Airfoil_GSD

        ├── Guided_Curves

        ├── Wing_Surface

        └── Validation
```

---

# Working Procedure

1

Generate coordinates in MATLAB.

2

Export

```
Root_Airfoil_100pts.csv
```

3

Paste into Excel VBA template.

4

Run VBA.

5

Verify generated points.

6

Verify spline quality.

7

Scale to project dimensions.

8

Move to correct station.

9

Create guide curves.

10

Create Multi Section Surface.

---

# Lessons Learned

Manual CATIA point creation

```
NOT RECOMMENDED
```

Manual spline construction

```
NOT RECOMMENDED
```

MATLAB

↓

Excel VBA

↓

CATIA

is currently the fastest and most reliable workflow.

---

# Remaining Work

- Modify VBA to create native Sketch geometry.
- Eliminate creation of "GeometryFromExcel".
- Automatic scaling using aircraft chord.
- Automatic placement on span stations.
- Automatic root/tip import.
- Automatic guide curve generation.
- Automatic wing surface creation.

---

# Future Improvements

Desired Fully Automated Workflow

```
MATLAB

↓

CSV Export

↓

Excel VBA

↓

CATIA

↓

Root Sketch

↓

Tip Sketch

↓

Scale Automatically

↓

Place Automatically

↓

Generate Guide Curves

↓

Generate Multi Section Surface

↓

Wing Skeleton Completed
```

Target

```
Single-click airfoil generation
```

---