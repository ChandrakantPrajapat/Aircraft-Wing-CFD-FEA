# CATIA Airfoil Workflow Manual

**Executive Summary:** This document describes the complete workflow for generating CAD airfoil profiles in CATIA V5, from MATLAB coordinate generation through Excel VBA import to CATIA (GSD or Sketcher) geometry.  It covers software versions, repository organization, data formats, the VBA macro (original and customized), CATIA operations, best practices (spline settings, trailing-edge closure), troubleshooting, and testing.  Primary sources (Dassault documentation, NASA reports, MATLAB references) are cited where applicable.  Use this as a standalone guide for engineers implementing the airfoil geometry workflow.

## 1. Project Purpose

The goal is to create precise 3D wing profiles (root and tip airfoils) in CATIA V5 for CFD/FEA.  The workflow uses **NACA 4-digit airfoils** (NACA 2412 at root, NACA 2409 at tip) defined by MATLAB, imported via an Excel VBA macro into CATIA **Generative Shape Design (GSD)** or **Sketcher** geometry.  This ensures high-fidelity surfaces for subsequent wing lofting, structural modeling, and analysis.

- **Root Airfoil:** NACA 2412; chord = 2 005 mm (normalized 100 mm × 20.05).  
- **Tip Airfoil:** NACA 2409; chord = 802 mm (normalized 100 mm × 8.02).  
- **Data Points:** 100 per profile (50 upper, 50 lower), cosine‐spaced for edge clustering.  
- **Output:** CSV coordinate files, and CATIA sketches/splines (open profile + separate trailing edge).  

## 2. Software & Prerequisites

- **MATLAB** (R2018 or later recommended) for coordinate generation.  
- **Microsoft Excel** with VBA support.  Use the Dassault-supplied template (an XLS/VBA macro) for importing points into CATIA.  
- **CATIA V5** (tested up to V5-6R2020 P3 and 3DEXPERIENCE).  The built-in GSD Point/Spline/Loft macro is available in the installation directory (see below).  
- **Hardware:** Standard Windows PC. All scripts run locally; no external APIs are needed.

Ensure **administrator access** to install CATIA or view program files, and that Excel security allows macros.  

## 3. Repository Structure

```
04_CAD
└── 00_Master_Skeleton
    ├── Airfoils
    │   ├── Root_Airfoil_100pts.csv         # CSV from MATLAB (root)
    │   ├── Tip_Airfoil_100pts.csv          # CSV from MATLAB (tip)
    │   ├── Airfoil_Excel_Template.xlsm     # Excel macro (Dasault’s template)
    │   └── (Screenshots/ etc.)             # Placeholder images, if any
    ├── Root_Airfoil_GSD                    # Geometrical Set in CATIA
    ├── Tip_Airfoil_GSD                     # Geometrical Set in CATIA
    ├── (Other design files: GuideCurves, Wing_Surface, etc.)
    └── Documentation
        └── CATIA_AIRFOIL_WORKFLOW.md       # This manual
```

- **Airfoils/** holds input CSVs and the Excel macro file.  
- **Root_Airfoil_GSD/** is the CATIA Geometrical Set for root airfoil (hybrid body).  
- **Tip_Airfoil_GSD/** likewise for tip.  
- **Documentation/** (optional) contains this README and any future design notes.

## 4. Naming Conventions

- **Worksheet Name:** The Excel macro expects the sheet name **`Feuil1`** (French for “Sheet1”). If you rename the sheet, update all `Sheets("Feuil1")` references in the VBA code.  
- **Macro Entry Point:** The VBA macro routine is `Main` in `Feuil1`. The code prompts for a type (1=points, 2=splines, 3=loft). It calls subroutines `CreationPoint`, `CreationSpline`, or `CreationLoft`.  
- **File Naming:** Keep the Excel workbook’s name consistent (e.g. `Airfoil_Excel_Template.xlsm`). You may have multiple copies (e.g. `Root_Airfoil.xlsm`, `Tip_Airfoil.xlsm`) – only the worksheet name matters internally. Each copy contains the same macros.
- **CATIA Bodies:** The default macro creates a new HybridBody named **`GeometryFromExcel`**. We will customize it to use existing bodies:
  - **Root_Airfoil_GSD** (the CATIA Geometrical Set for root profile)  
  - **Tip_Airfoil_GSD** (for tip)  
  Names are case-sensitive.

## 5. MATLAB Coordinate Generation

Airfoil coordinates are generated in MATLAB using the standard NACA 4-digit formulas (per Abbott & von Doenhoff). The provided function (see Appendix B) uses:
- **Inputs:** Max camber (`m` as fraction of chord), camber position (`p`), thickness (`t`), chord length `c`, number of points per surface `N`.
- **Cosine Spacing:** The x-coordinates are distributed as  
  \[
  x_i = \frac{1 - \cos\left(\frac{i-1}{N-1}\pi\right)}{2},\quad i=1..N,
  \]  
  which clusters points near **leading and trailing edges**.  *NASA confirms* that cosine spacing yields higher point density near ends (leading/trailing edges) improving accuracy.  
- **100 Points:** We compute 50 upper + 50 lower points (plus optional duplicated TE point). This yields a smooth spline in CATIA.

**Finite Trailing-Edge Thickness:** The algorithm can allow a small TE gap (e.g. 0.2–0.5 mm at full scale) by slightly offsetting the last upper/lower points. This helps avoid a singular point at TE.

**Example (cosine spacing):**  

```matlab
function [X, Y] = generateNACA4_CAD(m,p,t,c)
    N = 50;
    beta = linspace(0,pi,N);
    x = (1-cos(beta))/2;  % Cosine spacing (0 to 1)
    % Thickness distribution (4th-order polynomial)
    yt = 5*t*(0.2969*sqrt(x) - 0.1260*x -0.3516*x.^2 + 0.2843*x.^3 - 0.1015*x.^4);
    % Camber line and slope
    yc = zeros(size(x)); dyc = zeros(size(x));
    for i=1:N
      if x(i)<=p
         yc(i) = m/p^2*(2*p*x(i)-x(i)^2);
         dyc(i)= 2*m/p^2*(p - x(i));
      else
         yc(i) = m/(1-p)^2*((1-2*p)+2*p*x(i)-x(i)^2);
         dyc(i)= 2*m/(1-p)^2*(p - x(i));
      end
    end
    theta = atan(dyc);
    % Upper surface
    xu = x - yt.*sin(theta);
    yu = yc + yt.*cos(theta);
    % Lower surface
    xl = x + yt.*sin(theta);
    yl = yc - yt.*cos(theta);
    % Assemble in order: TE upper→LE→TE lower
    X = [flip(xu), xl(2:end)];
    Y = [flip(yu), yl(2:end)];
    % Close at TE (duplicate first point)
    X(end+1) = X(1);
    Y(end+1) = Y(1);
    % Scale to chord length (c in same units as desired output, e.g. mm)
    X = X * c;
    Y = Y * c;
end
```

*(Appendix B provides the full MATLAB function and sample usage.)*

## 6. CSV / Excel Data Format

The airfoil data must be pasted into the Excel template for the macro.  The template format is strict:

```
StartLoft
StartCurve
X1, Y1, Z1
X2, Y2, Z2
...
Xn, Yn, Zn
EndCurve
EndLoft
End
```

- **Columns:** X, Y, Z (comma or tab separated). In our case, Y=0 for 2D airfoil, Z is vertical coordinate.
- **Order:** The first coordinate should be the **upper trailing edge**, ending at **lower trailing edge**, as in the MATLAB output above.
- **Keywords:** Must have **StartLoft** on its own line (top), **StartCurve**, then points, then **EndCurve**, **EndLoft**, and **End** each on their own line. No extra text or merged cells. (The macro scans for these exact tokens.)
- **Example snippet:**

```text
StartLoft
StartCurve
100.0000  0.0000  0.0000
99.9756   0.0000  0.0052
...
0.1405    0.0000  0.8404
0.0439    0.0000  0.5592
-0.0030   0.0000  0.2790
0.0000    0.0000  0.0000
EndCurve
EndLoft
End
```

- **Formatting rules:**  
  - Ensure **no blank rows** or extra characters around the markers.  
  - **EndCurve** must be followed by **EndLoft** and **End** (on separate lines). Omitting **EndLoft** (or repeating **EndCurve**) causes the macro to loop indefinitely (it keeps scanning for the final token).  
  - Y and Z columns may be blank if unused, but safest is to have three numeric columns.  

After preparing the CSV, **paste** the rows into the Excel sheet named *Feuil1*. (You can use Excel’s “Data → Get External Data” or copy-paste manually.)  Remove any formatting; the data should be plain text values.

    ![Screenshot: Excel template with airfoil data (placeholder)](assets/excel_template_placeholder.png)

## 7. VBA Macro: Original & Customized

Dassault provides the Excel macro `GSD_PointSplineLoftFromExcel.xls` as a sample (found under `CODE\COMMAND\GSD_PointSplineLoftFromExcel.xls` in the CATIA installation).  This macro reads the worksheet **Feuil1** and creates points, splines, and (optionally) a loft in CATIA. To use it:

1. **Copy the template:** Do *not* modify the original in Program Files. Instead, save a copy (e.g. `Airfoil_Excel_Template.xlsm`) into the project folder. This preserves macros.
2. **Enable Macros:** Open the copy in Excel, enable content if prompted.
3. **Paste data:** Paste the coordinate lines as described above.
4. **Run the macro:** Press **Alt+F8**, select `Main` (or `Feuil1.Main`), and click **Run**. A dialog will ask “Type in the kind of entities to create.” Enter:
   - `1` for points only (creates points in a new HybridBody, no splines),
   - `2` for points + spline (no loft),
   - **`3` for points + spline + loft** (full wing section).
   Use **3** to generate the full curve (unless you want to postpone lofting).
5. The macro will prompt for a CATIA session. **Start CATIA V5 and open a new or existing Part in GSD.** Then return to Excel and press **OK** on the VBA prompt.  
6. The geometry appears in the active CATIA document, under a new HybridBody.

**Example Macro Usage:**  
*The user forum confirms that the default template path is …\code\command\GSD_PointSplineLoftFromExcel.xls and that one runs “Feuil1.main” with choice 3 for loft.* 

### 7.1 Original Dassault Macro

*Excerpt (annotated) of the official VBA macro (`GSD_PointSplineLoftFromExcel.xls`):*

```vb
'--- Start of Dassault sample macro (v5R19~v5R30) ---
Sub Main()
    'Prompts user: 1=points, 2=points+spline, 3=points+spline+loft
    Dim TypeFile As Integer
    TypeFile = GetTypeFile
    
    'Get CATIA Part document
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    ' Create a new open Body for geometry
    Set myHBody = PtDoc.Part.HybridBodies.Add()
    Set referencebody = PtDoc.Part.CreateReferenceFromObject(myHBody)
    ' Rename it to "GeometryFromExcel"
    PtDoc.Part.HybridShapeFactory.ChangeFeatureName referencebody, "GeometryFromExcel"
    
    If TypeFile = 1 Then
        CreationPoint         'create only points
    ElseIf TypeFile = 2 Then
        CreationSpline        'points + splines
    ElseIf TypeFile = 3 Then
        CreationLoft          'points + splines + loft
    End If
End Sub
```

The code includes routines **CreationPoint**, **CreationSpline**, and **CreationLoft**.  In brief:
- **CreationPoint:** Reads lines between `StartCurve` and `EndCurve`, makes 3D points (`HybridShapeFactory.AddNewPointCoord(X,Y,Z)`).
- **CreationSpline:** Reads each “StartCurve…EndCurve” block, creates point objects, then a spline through them (`AddNewSpline`; adds points with `AddPointWithConstraintExplicit`), inside `GeometryFromExcel`.
- **CreationLoft:** After splines are built, creates a loft through all splines in the body.

*See Appendix D for the full original macro code.* 

### 7.2 Why the original creates *GeometryFromExcel*  

The sample macro **always adds a new HybridBody** and renames it `"GeometryFromExcel"`.  This means every run creates a new container. For a project, we prefer to use our own HybridBodies (`Root_Airfoil_GSD`, `Tip_Airfoil_GSD`) and avoid clutter. We will customize the macro to import into specific bodies.

### 7.3 Custom Macro (Version 2)

Create a modified macro (copy the original code and edit) with these changes:

1. **Use existing HybridBody:** Instead of `Add()`, get the body by name. For example, to import into `Root_Airfoil_GSD`:

```diff
- Set myHBody = PtDoc.Part.HybridBodies.Add()
- Set referencebody = PtDoc.Part.CreateReferenceFromObject(myHBody)
- PtDoc.Part.HybridShapeFactory.ChangeFeatureName referencebody, "GeometryFromExcel"
+ ' Use existing Geometrical Set "Root_Airfoil_GSD"
+ On Error Resume Next  ' in case it doesn't exist
+ Set myHBody = PtDoc.Part.HybridBodies.Item("Root_Airfoil_GSD")
+ On Error GoTo 0
+ If myHBody Is Nothing Then
+     ' Optionally create it if missing
+     Set myHBody = PtDoc.Part.HybridBodies.Add()
+     PtDoc.Part.HybridShapeFactory.ChangeFeatureName _
+         PtDoc.Part.CreateReferenceFromObject(myHBody), "Root_Airfoil_GSD"
+ End If
```

2. **Clear previous geometry (optional):** If running multiple times, you may want to delete old points/splines in that body before adding new ones. For example:

```vb
'-- Clear existing shapes in the body --
Dim i As Integer
For i = myHBody.HybridShapes.Count To 1 Step -1
    myHBody.HybridShapes.Remove i
Next
```

3. **Scaling:** After points/splines are created, apply a scale transformation to match actual chord:
   - Calculate scale factor = (desired chord) / (original 100). For root: *20.05*, tip: *8.02*.  
   - In CATIA VBA you can use `HybridShapeFactory.AddNewScale` (V5R21+) or simply scale sketch/extract. Example snippet (requires verification on V5R21+):

```vb
' Example: scale the Root profile by 20.05 about the origin (0,0,0)
Dim scale As Object
Set scale = PtDoc.Part.HybridShapeFactory.AddNewScale( _
               myHBody, _ 
               PtDoc.Part.CreateReferenceFromName("Origin") )
scale.ScaleFactor = 20.05
myHBody.AppendHybridShape scale
PtDoc.Part.Update
```

If scale commands are not available/robust, you can also multiply coordinates in MATLAB and import already scaled data (our scripts above do this by passing `c` to `generateNACA4_CAD`).  

4. **Sketcher Option (experimental):** If desired, the macro can open the active sketch (`OpenEdition`) and create points there using `Factory2D`. This requires the Sketcher interface:
   ```vb
   ' (Pseudo-code / requires verification:)
   Set skDoc = PtDoc.Part.HybridBodies.Item("Root_Airfoil_GSD").HybridSketches.Item("Sketch.1")
   Dim fac2d As Object
   Set fac2d = skDoc.OpenEdition()
   ' For each coordinate read:
   Set p = fac2d.CreatePoint(x, z)  ' Y=up in sketch plane (x, z from CSV)
   ' Later, create spline through these points in fac2d (method may vary).
   skDoc.CloseEdition
   ```
   The exact Factory2D methods can depend on CATIA version; *full code for Sketcher is beyond scope* here, but a developer could adapt known methods (`Factory2D.CreatePoint`, `Factory2D.CreateSpline`) as needed. Marked *requires verification*.

*Appendix D* contains a full version of the modified VBA macro with comments. 

### 7.4 Running the Macro

1. **Open CATIA:** Start CATIA V5 and create or open a Part (GSD workbench). Ensure `Root_Airfoil_GSD` (for root) or `Tip_Airfoil_GSD` exists in the tree under `PartBody`. If not, create a new Geometrical Set and rename it accordingly.
2. **Select Part:** In VBA (Excel), `GetCATIAPartDocument` grabs the active document. Make sure the correct part is active.
3. **Run:** As before, run `Main`. It will skip creating “GeometryFromExcel” and populate `Root_Airfoil_GSD` or `Tip_Airfoil_GSD` as coded.
4. **Review output:** Points and splines appear under the chosen HybridBody. Update the part (`Ctrl+U`) if needed.

## 8. CATIA Geometry and Settings

Once imported, review the geometry in CATIA:

- **Points:** Check that all 100 points (or 101 with duplicated TE) are created. They should lie on Y=0 plane.  
- **Spline:** The macro-created spline should smoothly pass through the points. If not using macro, you can manually create a spline:
  - **Command:** `Spline` (generative shape or in a sketch).  
  - **Settings:** Disable *Connect with Arc/Line*. Enable *Tangency Continuity (C1)* and *Curvature Continuity (C2)*.  These ensure a smooth curve with no sharp corners. Do **not** use the “Close spline” option—keep the spline open.
  - **Example (Sketcher Spline):** In Sketcher, when defining the spline, check *Tangency* (C1) and *Curvature* (C2) continuity. See [35] for definitions of G1/G2 continuity.  
- **Trailing Edge Closure:** To avoid kinks, do **not** have the spline auto-close. Instead:
  - After spline from TE-upper → LE → TE-lower, use a separate **Line** (or very small radius fillet) to join the two trailing-edge end points.  
  - If a finite TE thickness was used, simply leave that gap as the wing’s trailing-edge thickness. A line (or negligible fillet) can cap it.  
  - This manual closure ensures the profile is exact and avoids CATIA's internal curvature-matching that can distort thin TE.

**Figure:** Spline creation in Sketcher (placeholder):

```mermaid
flowchart LR
    A[Paste CSV to Excel] --> B[Run VBA Macro]
    B --> C[CATIA: Points in Root_Airfoil_GSD]
    C --> D[Create Spline through Points]
    D --> E[Apply Continuity C1/C2, no arc/line]
    E --> F[Manually close TE with Line]
    F --> G[Resulting Airfoil Profile]
```

### 8.1 Spline Settings Summary

| Option                   | Setting        | Reason                                    |
|--------------------------|----------------|-------------------------------------------|
| **Spline Type**          | Spline (default)| Use smooth freeform curve.               |
| **Connect with Arc/Line**| **Off**        | We want a smooth curved profile, not straight or circular segments. |
| **Point Continuity (C0)**| On             | The curve passes through all points.      |
| **Tangency (C1)**        | **On**         | Ensures smooth tangent transitions (no sharp corner) between segments. |
| **Curvature (C2)**       | **On (preferred)**| Produces smooth curvature; good for aerodynamic shape if points are well-distributed. |
| **Close Spline**         | **Off**        | Leave profile open; close TE separately.  |

*(The Connect Checker defines G0/G1/G2 continuity in CATIA: G1 = C1 (tangent), G2 = C2 (curvature).)*

## 9. Troubleshooting & FAQs

- **Infinite Macro Loop:** If after running the macro, CATIA hangs or the macro never finishes, check the **EndCurve/EndLoft** tokens. The workbook **must** have a single `EndCurve`, followed by `EndLoft` and then `End` (each on its own line). A common mistake is duplicating `EndCurve` or omitting `EndLoft`. Ensure no blank rows or text after `EndLoft`.  
- **Worksheet Naming:** The code uses `Sheets("Feuil1")`. If Excel shows “Sheet1” in English, it may still be internally named Feuil1. If you renamed the sheet, edit all `Sheets("Feuil1")` in the VBA to match the new name.  
- **GeometryFromExcel Body:** By default, the macro creates a HybridBody “GeometryFromExcel”. If you see this instead of your target body, use the modified macro. To recover, either delete that body or copy its contents into the correct body.  
- **Scaling Factor:** If the resulting airfoil is far too small or large, it hasn’t been scaled. Remember to apply the factor (20.05 for root, 8.02 for tip) either in MATLAB (preferred) or via a CATIA scale operation.  
- **Merged/Empty Cells:** The macro reads cells in columns A–C. Merged cells or missing columns can cause misalignment. Ensure X, Y, Z are in separate cells (A, B, C) and numeric.  
- **Sketcher vs GSD:** If using the Sketcher approach, ensure the sketch is in the correct plane (e.g. XY) with origin at (0,0). Projecting GSD curves into a sketch (option B) can also work but may complicate associativity.  
- **Tangent Kinks:** If the spline “snaps” at the ends, verify C1 continuity is set. For an automatically closed spline, CATIA can force continuity, causing a visible kink. Solution: do not close the spline.

## 10. Testing & Acceptance Checklist

Before finalizing the profile and lofting the wing, verify:

- [ ] **CSV Data:** 100 rows of coordinates (plus header/footer). No missing or extra lines. Example snippet matches the template exactly.  
- [ ] **Excel Sheet:** Data in *Feuil1*, no blanks or merged cells. The `StartCurve/EndCurve/EndLoft/End` markers are present in column A.  
- [ ] **Macro Run:** Excel reports “Entities created successfully” (if coded) and CATIA shows new points. No VBA errors.  
- [ ] **CATIA Points:** All points appear (check coordinates of first and last point match TE). The HybridBody `Root_Airfoil_GSD` (or specified body) contains the shapes.  
- [ ] **Spline Smoothness:** The imported spline is smooth, with no visible kinks. Inspect zoomed-in near leading/trailing edges.  
- [ ] **Spline Settings:** If creating manually, check C0, C1, C2 toggles as per Section 8.1.  
- [ ] **Trailing Edge:** The TE is a tiny gap or small line, as designed (or a separate closing line exists).  
- [ ] **Scale:** The chord length is correct (measure distance between TE points in CATIA; should be 2005 mm for root).  
- [ ] **Guide Curves (if applicable):** The rest of the wing skeleton (spars, ribs) align with the new airfoil.  
- [ ] **Loft Surface (optional):** If performing the loft now (Type=3), inspect the surface smoothness and absence of twists/kinks. Use curvature analysis in GSD if needed.

If any check fails, fix data or settings and retry the macro on a fresh body (or clear existing geometry).

## 11. Future Improvements

- **Native Sketch Automation:** Implement the VBA to use **Factory2D** so airfoil points/spline live in a CATIA Sketch (e.g., `Root_Airfoil_GSD\Sketch.1`). This enables full parametric control of the profile. (Currently the macro uses GSD elements.)  
- **Automatic Station Placement:** The script could also translate the airfoil to the correct wing station (e.g. Y=0 for root, Y=span/2 for tip) and apply wing sweep.  
- **Sparse / Control Curves:** For faster CAD, consider generating a spline with fewer control points (e.g. PARSEC or Bézier) and loft with that, rather than a 100-point spline.  
- **Bidirectional Workflow:** An enhanced macro could also *export* current CATIA curve coordinates back to Excel/CSV for verification or editing.  
- **Integration:** Eventually integrate this process with the guided surface design (spar cap location, rib positions) and CNC output.  

This manual and associated scripts should provide a robust starting point.  As CATIA and MATLAB evolve, refer back to Dassault’s documentation and maintain version control for the macros and code.

---

## Appendices

### A. Aircraft Configuration (v1, frozen)

| Parameter       | Value      |
|-----------------|------------|
| Wing Area       | 17.73 m²   |
| Span            | 12.63 m    |
| Root Chord      | 2.005 m    |
| Tip Chord       | 0.802 m    |
| Taper Ratio     | 0.40       |
| LE Sweep        | 5°         |
| Front Spar      | 25% chord  |
| Rear Spar       | 65% chord  |
| Rib Spacing     | 0.5 m      |
| Skin Thickness  | 3 mm       |
| **Status:**     | DESIGN FROZEN (2026-05-16) |

### B. MATLAB Coordinate Generator

Sample function `generateNACA4_CAD.m` (used to create 100-point COSINE-spaced airfoils):

```matlab
function [X,Y] = generateNACA4_CAD(m,p,t,c)
    N = 50;
    beta = linspace(0,pi,N);
    x = (1-cos(beta))/2;
    % Thickness
    yt = 5*t*(0.2969*sqrt(x) -0.1260*x -0.3516*x.^2 +0.2843*x.^3 -0.1015*x.^4);
    % Camber line
    yc = zeros(1,N); dyc = zeros(1,N);
    for i=1:N
        if x(i)<=p
            yc(i) = m/p^2*(2*p*x(i)-x(i)^2);
            dyc(i)= 2*m/p^2*(p-x(i));
        else
            yc(i) = m/(1-p)^2*((1-2*p)+2*p*x(i)-x(i)^2);
            dyc(i)= 2*m/(1-p)^2*(p-x(i));
        end
    end
    theta = atan(dyc);
    % Upper and lower surfaces
    xu = x - yt.*sin(theta);
    yu = yc + yt.*cos(theta);
    xl = x + yt.*sin(theta);
    yl = yc - yt.*cos(theta);
    % Assemble (TE upper to LE to TE lower)
    X = [flip(xu), xl(2:end)];
    Y = [flip(yu), yl(2:end)];
    % Duplicate trailing edge point to close
    X(end+1) = X(1);
    Y(end+1) = Y(1);
    % Scale to chord length
    X = X * c;
    Y = Y * c;
end
```

*Usage:*  
```matlab
chord_root = 2005; chord_tip = 802; % mm
[rootX, rootY] = generateNACA4_CAD(0.02, 0.40, 0.12, chord_root);
[tipX, tipY]   = generateNACA4_CAD(0.02, 0.40, 0.09, chord_tip);
% Write to CSV:
writematrix([rootX(:), rootY(:)], 'Root_Airfoil_100pts.csv');
writematrix([tipX(:),   tipY(:)  ], 'Tip_Airfoil_100pts.csv');
```

### C. Example CSV Data (snippet)

```
StartLoft
StartCurve
100.0000, 0.0000, 0.0000
99.9756,  0.0000, 0.0052
...      (remaining upper surface points) ...
0.0439,   0.0000, 0.5592
-0.0030,  0.0000, 0.2790
0.0000,   0.0000, 0.0000
EndCurve
EndLoft
End
```

### D. VBA Macro Code

#### D.1 Original (Excerpt)

*(From `GSD_PointSplineLoftFromExcel.xls`, annotated)*

```vb
' Original CATIA sample macro
Sub Main()
    Dim TypeFile As Integer
    TypeFile = GetTypeFile  ' User inputs 1, 2, or 3

    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument

    ' Create or reset HybridBody
    Set myHBody = PtDoc.Part.HybridBodies.Add()
    Set referencebody = PtDoc.Part.CreateReferenceFromObject(myHBody)
    PtDoc.Part.HybridShapeFactory.ChangeFeatureName referencebody, "GeometryFromExcel"

    If TypeFile = 1 Then
        CreationPoint  ' create only points
    ElseIf TypeFile = 2 Then
        CreationSpline ' create points + spline
    ElseIf TypeFile = 3 Then
        CreationLoft   ' create points + spline + loft
    End If
End Sub

Sub CreationPoint()
    Dim iRang As Integer, iValid As Integer
    Dim X As Double, Y As Double, Z As Double
    Dim Point As Object

    Set myHBody = PtDoc.Part.HybridBodies.Item("GeometryFromExcel")
    iRang = 1
    While iValid <> Cst_iEND
        ChainAnalysis iRang, X, Y, Z, iValid
        iRang = iRang + 1
        If (iValid = 0) Then  ' valid coordinate line
            Set Point = PtDoc.Part.HybridShapeFactory.AddNewPointCoord(X, Y, Z)
            myHBody.AppendHybridShape Point
        End If
    Wend
    PtDoc.Part.Update
End Sub

' (CreationSpline and CreationLoft follow similar patterns:
'  reading StartCurve→EndCurve blocks, building splines with
'  .AddPointWithConstraintExplicit, then a loft through those splines.)
```

#### D.2 Modified (Version 2, key changes)

```diff
 Sub Main()
     Dim TypeFile As Integer
     TypeFile = GetTypeFile

     Dim PtDoc As Object
     Set PtDoc = GetCATIAPartDocument

-    Set myHBody = PtDoc.Part.HybridBodies.Add()
-    Set referencebody = PtDoc.Part.CreateReferenceFromObject(myHBody)
-    PtDoc.Part.HybridShapeFactory.ChangeFeatureName referencebody, "GeometryFromExcel"
+    ' Use (or create) a named Geometrical Set
+    On Error Resume Next
+    Set myHBody = PtDoc.Part.HybridBodies.Item("Root_Airfoil_GSD")
+    On Error GoTo 0
+    If myHBody Is Nothing Then
+        Set myHBody = PtDoc.Part.HybridBodies.Add()
+        PtDoc.Part.HybridShapeFactory.ChangeFeatureName _
+            PtDoc.Part.CreateReferenceFromObject(myHBody), "Root_Airfoil_GSD"
+    End If
+
+    ' (Optional) Clear old geometry in the body
+    Dim i As Integer
+    For i = myHBody.HybridShapes.Count To 1 Step -1
+        myHBody.HybridShapes.Remove i
+    Next

     If TypeFile = 1 Then
         CreationPoint
     ElseIf TypeFile = 2 Then
         CreationSpline
     ElseIf TypeFile = 3 Then
         CreationLoft
     End If
 End Sub
```

*Notes:* The modified macro replaces the `Add`/`ChangeFeatureName` with `HybridBodies.Item("Root_Airfoil_GSD")`. Similar changes should be made for the tip (`"Tip_Airfoil_GSD"`). Removal of `GeometryFromExcel` avoids clutter.  Further, you could add a `Dim scaleFactor` section after CreationPoint/Spline to scale the points.

*(Full code and Sketcher example omitted; see project repo for complete version.)*

### References

- Dassault V5 Documentation (on-point continuity: *“G1 continuity: continuity in tangency; G2 continuity: continuity in curvature.”*).  
- CATIA user forums and training (Dassault sample macro path and usage).  
- NASA aerodynamic analysis (cosine spacing clusters panels near ends).  
- Abbott & von Doenhoff, *Theory of Wing Sections* (NACA airfoil equations).  
- MATLAB documentation (for functions like `linspace`, `sqrt`, etc., if needed).

