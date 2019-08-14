; SETPcell.il

;; This is the function that does all the work in creating the
;; PCell shapes, labels etc.  This routine can be tested outside
;; of the pcDefinePCell statement, and it goes through SKILL Lint
;; with better results too.

procedure(CreateCap(cv nFingers fLength "dnn")
  ; Some constants. Probably should be in a let()
  lpp = list("EBL1" "EBL")
  width = 0.05
  gap = 0.05
  endGap = 0.16
  period = (width + gap) * 2
  edge = fLength/2.0 + endGap
  
  ; Create Primary Fingers
  yStart = -(nFingers-1)/2.0 * period
  for(i 1 nFingers
    dbCreateRect(cv lpp list( -(fLength/2.0+endGap):(yStart + period*(i-1) - width/2.0)  fLength/2.0:(yStart + period*(i-1) + width/2.0) ))
  )

  ; Create secondary fingers
  yStart = -nFingers/2.0 * period
  for(i 1 nFingers + 1
    dbCreateRect(cv lpp list( -fLength/2.0:(yStart + period*(i-1) - width/2.0)  (fLength/2.0+endGap):(yStart + period*(i-1) + width/2.0) ))
  )

  ; Create finger bases
  dbCreateRect(cv lpp list( -(edge+width):-(period*(nFingers-1)+width)/2.0  -edge:(period*(nFingers-1)+width)/2.0 ))	; Primary
  dbCreateRect(cv lpp list(  (edge+width):-(period*nFingers+width)/2.0   edge:(period*nFingers+width)/2.0 ))	; Secondary

  ; Merge everything

  ; Create labels

); procedure CCScreateBoxAndLabelsk

;; Create the PCell, the "drawing routine" is encapsulated in the
;; CCScreateBoxAndLabels function which does all the work

pcDefinePCell(
  list(ddGetObj("DM_utility") "CapPcell" "layout")
  (
    (nFingers 2)
    (fLength 2)
  )
  let( ((cv pcCellView))
    CreateCap(cv nFingers fLength)
  ); let
)

;; Create the CDF for the parameters, the width (w)
let( (cellId cdfId)
  when(cellId = ddGetObj("DM_utility" "CapPcell")
    ;; if the cell CDF already exists, delete it
    when( cdfId = cdfGetBaseCellCDF(cellId)
      cdfDeleteCDF(cdfId)
    )
    ;; create the base cell CDF
    cdfId = cdfCreateBaseCellCDF(cellId)
    ;; create the parameters
    cdfCreateParam( cdfId
      ?name     "nFingers"
      ?prompt   "Finger Count"
      ?defValue 2
      ?type     "int"
      ?display  "t"
    )
    cdfCreateParam( cdfId
      ?name     "fLength"
      ?prompt   "Finger Length"
      ?defValue 2.00
      ?type     "float"
      ?display  "t"
    )
    
    cdfSaveCDF(cdfId)
  ); when
); let for CDF creation 