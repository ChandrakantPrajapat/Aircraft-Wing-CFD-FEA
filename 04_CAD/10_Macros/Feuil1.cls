VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Feuil1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
'//============================================================================
'// COPYRIGHT DASSAULT SYSTEMES 2001
'//============================================================================
'// Generative Shape Design
'// point, splines, loft generation tool
'//============================================================================
Const Cst_iSTARTCurve    As Integer = 1
Const Cst_iENDCurve      As Integer = 11
Const Cst_iSTARTLoft     As Integer = 2
Const Cst_iENDLoft       As Integer = 22
Const Cst_iSTARTCoord    As Integer = 3
Const Cst_iENDCoord      As Integer = 33
Const Cst_iERRORCool     As Integer = 99
Const Cst_iEND           As Integer = 9999

Const Cst_strSTARTCurve    As String = "StartCurve"
Const Cst_strENDCurve      As String = "EndCurve"
Const Cst_strSTARTLoft     As String = "StartLoft"
Const Cst_strENDLoft       As String = "EndLoft"
Const Cst_strSTARTCoord    As String = "StartCoord"
Const Cst_strENDCoord      As String = "EndCoord"
Const Cst_strEND           As String = "End"

'------------------------------------------------------------------------
'To define the kind of elements to create (1: create only points
'2: creates points and splines
'3: Creates points, splines and loft
'------------------------------------------------------------------------
Function GetTypeFile() As Integer
    Dim strInput As String, strMsg As String
    
    choice = 0
    While (choice < 1 Or choice > 3)
        strMsg = "Type in the kind of entities to create (1 for points, 2 for points and splines, 3 for points, splines and loft):"
        strInput = InputBox(Prompt:=strMsg, _
            Title:="User Info", XPos:=2000, YPos:=2000)
    
        'Validation of the choice
        choice = CInt(strInput)
        If (choice < 1 Or choice > 3) Then
            MsgBox "Invalid value: must be 1, 2 or 3"
        End If
    Wend
    GetTypeFile = choice
End Function

'------------------------------------------------------------------------
'Get the active cell
'------------------------------------------------------------------------
Function GetCell(iindex As Integer, column As Integer) As String
    Dim Chain As String
    
    Sheets("Feuil1").Select
    If (column = 1) Then
        Chain = "A" + CStr(iindex)
    ElseIf (column = 2) Then
        Chain = "B" + CStr(iindex)
    ElseIf (column = 3) Then
        Chain = "C" + CStr(iindex)
    End If
    Range(Chain).Select
    GetCell = ActiveCell.Value
End Function
Function GetCellA(iRang As Integer) As String
    GetCellA = GetCell(iRang, 1)
End Function
Function GetCellB(iRang As Integer) As String
    GetCellB = GetCell(iRang, 2)
End Function
Function GetCellC(iRang As Integer) As String
    GetCellC = GetCell(iRang, 3)
End Function
'------------------------------------------------------------------------
'Syntax of the parameter file
'------------------------
'StartCurve                 -> to start the list of points defining the spline
' double  ,  double  ,  double
' double  ,  double  ,  double      -> as many points as necessary to define the spline
'EndCurve                   -> to end the list of points defining the spline
'
'
'Example:
'--------
'StartCurve
' -10.89, 10 , 46.78
'1.56, 4, 6
'EndCurve  -> spline composed of 2 points
'------------------------------------------------------------------------
Sub ChainAnalysis(ByRef iRang As Integer, ByRef X As Double, ByRef Y As Double, ByRef Z As Double, ByRef iValid As Integer)
    Dim Chain As String
    Dim Chain2 As String
    Dim Chain3 As String
    
    Chain = GetCellA(iRang)
    
    Select Case Chain
        Case Cst_strSTARTCurve
            iValid = Cst_iSTARTCurve
        Case Cst_strENDCurve
            iValid = Cst_iENDCurve
        Case Cst_strSTARTLoft
            iValid = Cst_iSTARTLoft
        Case Cst_strENDLoft
            iValid = Cst_iENDLoft
        Case Cst_strSTARTCoord
            iValid = Cst_iSTARTCoord
        Case Cst_strENDCoord
            iValid = Cst_iENDCoord
        Case Cst_strEND
            iValid = Cst_iEND
        Case Else
            iValid = 0
    End Select
    If (iValid <> 0) Then
        Exit Sub
    End If
    
    
    
    'Conversion string -> double
    Chain2 = GetCellB(iRang)
    Chain3 = GetCellC(iRang)
    If ((Len(Chain) > 0) And (Len(Chain2) > 0) And (Len(Chain3) > 0)) Then
        X = CDbl(Chain)
        Y = CDbl(Chain2)
        Z = CDbl(Chain3)
    Else
        iValid = Cst_iERRORCool
        X = 0#
        Y = 0#
        Z = 0#
    End If
End Sub
'------------------------------------------------------------------------
' Get CATIA Application
'------------------------------------------------------------------------
'Remark:
'   When KO, update CATIA registers with:
'                       CNEXT /unregserver
'                       CNEXT /regserver
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Function GetCATIA() As Object
    Set CATIA = GetObject(, "CATIA.Application")
    If CATIA Is Nothing Then
       Set CATIA = CreateObject("CATIA.Application")
       CATIA.Visible = True
    End If
    
    Set GetCATIA = CATIA
End Function
'------------------------------------------------------------------------
' Get CATIADocument
'------------------------------------------------------------------------
Function GetCATIAPartDocument() As Object
    Set CATIA = GetCATIA
    
    Dim MyPartDocument As Object
    Set MyPartDocument = CATIA.ActiveDocument
    
    Set GetCATIAPartDocument = MyPartDocument
End Function
'------------------------------------------------------------------------
' Creates all usable points from the parameter file
'------------------------------------------------------------------------
Sub CreationPoint()

    'Get CATIA
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    ' Get the HybridBody
    Dim myHBody As Object
    Set myHBody = PtDoc.Part.HybridBodies.Item("GeometryFromExcel")
    
    Dim iLigne As Integer
    Dim iValid As Integer
    Dim X As Double
    Dim Y As Double
    Dim Z As Double
    Dim Point As Object
    
    iLigne = 1
    'Analyze file
    While iValid <> Cst_iEND
        'Read a line
        ChainAnalysis iLigne, X, Y, Z, iValid
        iLigne = iLigne + 1
        
        'Not on a startcurve or endcurve -> valid point
        If (iValid = 0) Then
            Set Point = PtDoc.Part.HybridShapeFactory.AddNewPointCoord(X, Y, Z)
            myHBody.AppendHybridShape Point
        End If
    Wend
    
    'Model update
    PtDoc.Part.Update
End Sub
'------------------------------------------------------------------------
' Creates all usable points and splines from the parameter file
'------------------------------------------------------------------------
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
'Limitations:
'   ============================> NO MORE THAN 500 POINTS PER SPLINE
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Sub CreationSpline()
    'Limitation : points per spline
    Const NBMaxPtParSpline As Integer = 500
    
    'Get CATIA
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    'Get HybridBody
    Dim myHBody As Object
    Set myHBody = PtDoc.Part.HybridBodies.Item("GeometryFromExcel")
    
    
    
    Dim iRang As Integer
    Dim iValid As Integer
    Dim X1 As Double
    Dim Y1 As Double
    Dim Z1 As Double
    Dim index As Integer
    Dim PassingPtArray(1 To NBMaxPtParSpline) As Object
    Dim spline As Object
    Dim ReferenceOnPoint   As Object
    Dim SplineCtrPt As Object
    
    
    iValid = 0
    iRang = 1
    'Analyze file
    While iValid <> Cst_iEND
    
        'reinitialization of point array of the spline
        index = 0
        
        
        'Remove records before StartCurve
        While ((iValid <> Cst_iSTARTCurve) And (iValid <> Cst_iEND))
            ChainAnalysis iRang, X1, Y1, Z1, iValid
            iRang = iRang + 1
        Wend
        
        If (iValid <> Cst_iEND) Then
            'Read until endcurve -> Spline completed
            While ((iValid <> Cst_iENDCurve) And (iValid <> Cst_iEND))
                ChainAnalysis iRang, X1, Y1, Z1, iValid
                iRang = iRang + 1
        
        
                'valid point
                If (iValid = 0) Then
                    index = index + 1
                    If (index > NBMaxPtParSpline) Then
                        MsgBox "Too many points for a spline. Point deleted"
                    Else
                        Set PassingPtArray(index) = PtDoc.Part.HybridShapeFactory.AddNewPointCoord(X1, Y1, Z1)
                        myHBody.AppendHybridShape PassingPtArray(index)
                    End If
                End If
            Wend
    
        
        
        
            'Start building spline
            'Are there enough points ?
            If (index < 2) Then
                MsgBox "Not enough points for a spline. Spline deleted"
            Else
                Set spline = PtDoc.Part.HybridShapeFactory.AddNewSpline
                spline.SetSplineType 0
                spline.SetClosing 0
     
    
                'Creates and adds points to the spline
                For i = 1 To index
                    Set ReferenceOnPoint = PtDoc.Part.CreateReferenceFromObject(PassingPtArray(i))
                    '    ---- Version Before V5R12
                    ' Set SplineCtrPt = PtDoc.Part.HybridShapeFactory.AddNewControlPoint(ReferenceOnPoint)
                    ' spline.AddControlPoint SplineCtrPt
                                       
                    '    ---- Since V5R12
                     spline.AddPointWithConstraintExplicit ReferenceOnPoint, Nothing, -1, 1, Nothing, 0

                Next i
    
                myHBody.AppendHybridShape spline
            End If
        End If
    Wend
    
    PtDoc.Part.Update
End Sub
Sub LookForNextSpline(ByRef iRang As Integer, ByRef spline As Object, ByRef iValid As Integer, ByRef iOKSpline)
    'Limitation number off point per spline
    Const NBMaxPtParSpline As Integer = 500
    
    'Get CATIA
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    'Get HybridBody
    Dim myHBody As Object
    Set myHBody = PtDoc.Part.HybridBodies.Item("GeometryFromExcel")
    
    Dim X1 As Double
    Dim Y1 As Double
    Dim Z1 As Double
    Dim index As Integer
    Dim PassingPtArray(1 To NBMaxPtParSpline) As Object
    Dim ReferenceOnPoint   As Object
    Dim SplineCtrPt As Object
    
    
    iValid = 0
    iOKSpline = 0
    
    'reinitialization of point array of the spline
    index = 0
        
        
    'Remove records before StartCurve
    While ((iValid <> Cst_iSTARTCurve) And (iValid <> Cst_iEND))
        ChainAnalysis iRang, X1, Y1, Z1, iValid
        iRang = iRang + 1
    Wend
        
    If (iValid <> Cst_iEND) Then
        'Read until endcurve -> Spline completed
        While ((iValid <> Cst_iENDCurve) And (iValid <> Cst_iEND))
            ChainAnalysis iRang, X1, Y1, Z1, iValid
            iRang = iRang + 1
        
        
            'valid point
            If (iValid = 0) Then
                index = index + 1
                If (index > NBMaxPtParSpline) Then
                    MsgBox "Too many points for a spline. Point deleted"
                Else
                    Set PassingPtArray(index) = PtDoc.Part.HybridShapeFactory.AddNewPointCoord(X1, Y1, Z1)
                    myHBody.AppendHybridShape PassingPtArray(index)
                End If
            End If
        Wend
    
        
        
        
        'Start building spline
        'Are there enough points ?
        If (index < 2) Then
            MsgBox "Not enough points for a spline. Spline deleted"
        Else
            Set spline = PtDoc.Part.HybridShapeFactory.AddNewSpline
    
            'Creates and adds points to the spline
            For i = 1 To index
                Set ReferenceOnPoint = PtDoc.Part.CreateReferenceFromObject(PassingPtArray(i))
           '    ---- Version Before V5R12
           '    Set SplineCtrPt = PtDoc.Part.HybridShapeFactory.AddNewControlPoint(ReferenceOnPoint)
           '    spline.AddControlPoint SplineCtrPt
           
           
           '    ---- Since V5R12
                spline.AddPointWithConstraintExplicit ReferenceOnPoint, Nothing, -1, 1#, Nothing, 0#

            Next i
    
            myHBody.AppendHybridShape spline
            spline.SetSplineType 0
            spline.SetClosing 0
            iOKSpline = 1
        End If
    End If
End Sub
'------------------------------------------------------------------------
' Creates all usable points, splines and loft from the parameter file
'------------------------------------------------------------------------
'Limitations:
'   ============================> NO MORE THAN 500 POINTS PER SPLINE
'   ============================> NO MORE THAN 50 SPLINEs PER LOFT
'-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
Sub CreationLoft()
    'Limitations
    Const NBMaxPtParSpline As Integer = 500
    Const NBMaxSplineParLoft As Integer = 50

    'Get CATIA
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    'Get HybridBody
    Dim myHBody As Object
    Set myHBody = PtDoc.Part.HybridBodies.Item("GeometryFromExcel")
    
    
    
    Dim iRang As Integer
    Dim iValid As Integer
    Dim X1 As Double
    Dim Y1 As Double
    Dim Z1 As Double
    Dim index As Integer
    Dim indexSpline As Integer
    Dim SplineArray(1 To NBMaxSplineParLoft) As Object
    Dim Ref   As Object
    Dim CtrPt As Object
    
    
    indexSpline = 1
    iValid = 0
    iRang = 1
    
    'Analyze file
    While iValid <> Cst_iEND
    
        index = 0
        
        'Remove records before StartLoft
        While (iValid <> Cst_iSTARTLoft)
            ChainAnalysis iRang, X1, Y1, Z1, iValid
            iRang = iRang + 1
        Wend
        
        'Search curve defining the loft
        While (iValid <> Cst_iEND)
            If (indexSpline > NBMaxSplineParLoft) Then
                MsgBox "Too many splines for the loft"
                iValid = Cst_iEND
            Else
                LookForNextSpline iRang, SplineArray(indexSpline), iValid, iOKSpline
                If (iOKSpline = 1) Then
                    indexSpline = indexSpline + 1
                End If
                If (iValid = Cst_iEND) Then
                    indexSpline = indexSpline - 1
                End If
            End If
        Wend
    Wend
    
    
    '--------------------------------------------------------------------------------------------
    ' Create the loft
    '--------------------------------------------------------------------------------------------
    If (indexSpline > 1) Then
        Dim Loft As Object
        Set Loft = PtDoc.Part.HybridShapeFactory.AddNewLoft
        
        Dim LocalRefSpline As Object
        Dim SectionLoft As Object
        
        For i = 1 To indexSpline
            Set LocalRefSpline = PtDoc.Part.CreateReferenceFromGeometry(SplineArray(i))
            '    ---- Version Before V5R12
            ' Set SectionLoft = PtDoc.Part.HybridShapeFactory.AddNewLoftSection(LocalRefSpline, 1)
            ' Loft.AddSection SectionLoft
                      
            '    ---- Since V5R12
            Loft.AddSectionToLoft LocalRefSpline, 1, Nothing

            
        Next i
        
        myHBody.AppendHybridShape Loft
    End If
    ' Model update
    PtDoc.Part.Update
End Sub
'------------------------------------------------------------------------
'Main program
'------------------------------------------------------------------------
Sub Main()
Attribute Main.VB_ProcData.VB_Invoke_Func = "j\n14"
        
    'Get the type of operations to do:
    '   Points                  --> 1
    '   Splines + Points        --> 2
    '   Loft + Splines + Points --> 3
    
    
    Dim TypeFile As Integer
    TypeFile = GetTypeFile
    
    ' V5R12 - Create dedicate opneBody for created geometry
    'Get CATIA
    Dim PtDoc As Object
    Set PtDoc = GetCATIAPartDocument
    
    ' Create Open body
    Set myHBody = PtDoc.Part.HybridBodies.Add()
    Set referencebody = PtDoc.Part.CreateReferenceFromObject(myHBody)
    PtDoc.Part.HybridShapeFactory.ChangeFeatureName referencebody, "GeometryFromExcel"
    
    
    If TypeFile = 1 Then
        CreationPoint
    ElseIf TypeFile = 2 Then
        CreationSpline
    ElseIf TypeFile = 3 Then
        CreationLoft
    End If
    
    
End Sub
