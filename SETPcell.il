; SETPcell.il

;; This is the function that does all the work in creating the
;; PCell shapes, labels etc.  This routine can be tested outside
;; of the pcDefinePCell statement, and it goes through SKILL Lint
;; with better results too.

procedure(CreateSET(cv width gap gate1dist gate2dist gateWidth evapShift islWidth xOL yOL "dnnnnnnn")
  ; Some constants. Probably should be in a let()
  lpp = list("EBL1" "EBL")
  w1 = 0.25
  w2 = 0.1

  ; Instead of manually drawing the frame, instance it
  ; Set should fit into the 5x5 um template
  ; First, outer rectangles 2 um long, 0.25 um wide
  ;dbCreateRect(cv lpp list( -w1/2:3 w1/2:5 ))	; Top
  ;dbCreateRect(cv lpp list( -w1/2:-3 w1/2:-5 ))	; Bottom
  ;dbCreateRect(cv lpp list( -5:-w1/2 -3:w1/2 ))	; Left
  ;dbCreateRect(cv lpp list( 5/2:-w1/2 3:w1/2 ))	; Right

  ; Create frame instance
  sourcecvid = dbOpenCellViewByType("DM_utility" "MD_frame" "layout" "maskLayout" "r")
  dbCreateInst(cv sourcecvid nil 0:0 "R0")
  dbClose(sourcecvid)

  ; Next, the next level of rectangles 2 um long, 0.1 um wide
  dbCreateRect(cv lpp list( -w2/2:1 w2/2:3 ))	; Top
  dbCreateRect(cv lpp list( -w2/2:-1 w2/2:-3 ))	; Bottom
  
  ; Create Gate leads
  dbCreateRect(cv lpp list( -3:-gateWidth/2         -gate1dist:gateWidth/2 ))
  dbCreateRect(cv lpp list( gate2dist:-gateWidth/2  3:gateWidth/2 ))
  
  ; Create SET leads
  dbCreateRect(cv lpp list( -width/2:-1  width/2:-gap/2 ))
  dbCreateRect(cv lpp list( -width/2:gap/2   width/2:1 ))

  ; Create Island
  dbCreateRect(cv lpp list( (evapShift+width/2-xOL):(-gap/2-yOL)  (evapShift+width/2+islWidth-xOL):(gap/2+yOL) ))

); procedure CCScreateBoxAndLabelsk

;; Create the PCell, the "drawing routine" is encapsulated in the
;; CCScreateBoxAndLabels function which does all the work

pcDefinePCell(
  list(ddGetObj("trainingGrounds") "SETPcell" "layout")
  (
    (width 0.040)
    (gap 0.060)
    (gate1dist 0.200)
    (gate2dist 0.300)
    (gateWidth 0.100)
    (evapShift 0.110)
    (islWidth 0.040)
    (xOL 0.010)
    (yOL 0.010)
  )
  let( ((cv pcCellView))
    CreateSET(cv width gap gate1dist gate2dist gateWidth evapShift islWidth xOL yOL)
  ); let
)

;; Create the CDF for the parameters, the width (w)
let( (cellId cdfId)
  when(cellId = ddGetObj("trainingGrounds" "SETPcell")
    ;; if the cell CDF already exists, delete it
    when( cdfId = cdfGetBaseCellCDF(cellId)
      cdfDeleteCDF(cdfId)
    )
    ;; create the base cell CDF
    cdfId = cdfCreateBaseCellCDF(cellId)
    ;; create the parameters
    cdfCreateParam( cdfId
      ?name     "width"
      ?prompt   "Width"
      ?defValue 0.040
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "gap"
      ?prompt   "Gap"
      ?defValue 0.060
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "gate1dist"
      ?prompt   "Gate 1 Distance"
      ?defValue 0.200
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "gate2dist"
      ?prompt   "Gate 2 Distance"
      ?defValue 0.300
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "gateWidth"
      ?prompt   "Gate Width"
      ?defValue 0.300
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "evapShift"
      ?prompt   "Evaporation Shift"
      ?defValue 0.110
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "islWidth"
      ?prompt   "Island Width"
      ?defValue 0.040
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "xOL"
      ?prompt   "X Overlap"
      ?defValue 0.010
      ?type     "float"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "yOL"
      ?prompt   "Y Overlay"
      ?defValue 0.010
      ?type     "float"
      ?display  "t"
    )
    
    cdfSaveCDF(cdfId)
  ); when
); let for CDF creation 