; Multi-Mask Auto Layout v2.0
; Matthew Filmer 11/2/2018
;
; V2.0 - 11/14/2018
; Now supports inverting specified mask regions.
;
; v1.1 - 11/4/2018
; Fixed a bug where you could not specify the lppShifts optional parameter in a call to
; generateMultiMask()
;
; v1.0 - 11/2/2018
; Initial release
;
;
; Generates a cell consisting of one or more layers extracted from a source cell, offset
; by a specified amount, and converted to the layer-purpose pair of the first layer.
; This is designed to be used to generate a layout for a stepper mask with multiple layers
; on a single physical mask.
;
; generateMultiMask()
; Generates a multiple mask layout from the currently open and active cell. The new layout
; is saved in the same library as the source cell with "_quad" appended to the cell name. 
; This will overwrite without warning an existing cell of this name. The layers and offsets
; stored in the defaultLppShifts variable (customizable below) are used.
;
; generateMultiMask(lppShifts)
; Same as above except the layer-purpose pairs and corresponding offsets are passed in as
; an argument using the same format as defaultLppShifts below.
; lppShifts -> A list of layer-purpose pairs to operate on and their corresponding offsets
;
; generateMultiMaskInCell(libName sourceCellName multiCellName)
; Same as above except instead of operating on the active cell operates on the cell in
; the specified library and saves in the specified cell in the same library. The layers
; and offsets will be taken from the defaultLppShifts variable (customizable below)
; libName -> Name of the library that contains the source cell. The split cell will be 
;            saved in the same library
; sourceCellName -> Name of the cell to be split
; multiCellName -> Name of the destination split layout. If this file already exists it
;                  will be overwritten without warning.
;
; generateMultiMaskInCell(libName sourceCellName multiCellName lppShifts)
; Same as above except the layer-purpose pairs and corresponding offsets are passed in as
; an argument using the same format as defaultLppShifts below.
; lppShifts -> A list of layer-purpose pairs to operate on and their corresponding offsets


; Default list of layout-purpose pairs and center offsets. Can be customized
cenOff = 5000			; Offset of quadrant centers from mask center in microns
zoneWidth = cenOff*2		; Width of a mask zone. Used when inverting an area
zoneHeight = cenOff*2	; Height of a mask zone. Used when inverting an area
defaultLppShifts = list(
	list(list("EBL1" "EBL")     list(-1*cenOff,  1*cenOff) list('negative, zoneWidth:zoneHeight))
	list(list("EBL2" "EBL")     list( 1*cenOff,  1*cenOff))
	list(list("EBL3" "EBL")     list(-1*cenOff, -1*cenOff))
	list(list("Metal1" "Metal") list( 1*cenOff, -1*cenOff) list('negative, zoneWidth:zoneHeight))
)

procedure(generateMultiMask(@optional (lppShifts defaultLppShifts))
	let((cvid libName sourceCellName quadCellName)
		cvid = deGetCellView()
		libName = cvid~>libName
		sourceCellName = cvid~>cellName
		quadCellName = strcat(sourceCellName "_quad")
		
		generateMultiMaskInCell(libName sourceCellName quadCellName lppShifts)
	)
)

procedure(generateMultiMaskInCell(libName sourceCellName quadCellName @optional (lppShifts defaultLppShifts))
	let((lpp shift tform newShape tempCellName theseShapes)
		lpp1 = nth(0 lppShifts)
		lpp1 = nth(0 lpp1)
		
		tempCellName = strcat(sourceCellName "_quadtemp")
		
		; Get cell views for our input, output, and temporary cells
		sourcecvid = dbOpenCellViewByType(libName sourceCellName "layout" "maskLayout" "r")
		quadcvid = dbOpenCellViewByType(libName quadCellName "layout" "maskLayout" "w")
		tempcvid = dbOpenCellViewByType(libName tempCellName "layout" "maskLayout" "w")
		
		; Instance source into temp
		dbCreateInst(tempcvid sourcecvid nil 0:0 "R0")
		
		; Flatten temp cell
		while(tempcvid~>instances
			foreach(inst tempcvid~>instances
				if(inst~>mosaic
					then dbFlattenInst(inst~>mosaic 1 t)	; Flatten a mosaic
					else dbFlattenInst(inst 1 t)		; Flatten a simple instance
				)
			)
		)
		
		foreach(lppShift lppShifts
			theseShapes = list()
			lpp = nth(0 lppShift)
			shift = nth(1 lppShift)
			specInst = nth(2 lppShift)
			tform = list(shift "R0" 1.0)
			
			; Get array of shapes on the lpp
			shapes = car(setof(x tempcvid~>lpps (x~>layerName == nth(0 lpp) && x~>purpose == nth(1 lpp) )))
			shapes = shapes~>shapes
			
			foreach(shape shapes
				;Copy into the quad cell
				newShape = dbCopyShape(shape quadcvid tform)
				
				; Change the lpp
				newShape~>layerName = nth(0 lpp1)
				newShape~>purpose = nth(1 lpp1)
				
				; add to theseShapes
				theseShapes = cons(newShape theseShapes)
			)
			
			; Invert if requested
			if(nth(0 specInst) == 'negative then
				let((dims width height pos x y bbox bRect)
					dims = nth(1 specInst)
					width = nth(0 dims)
					height = nth(1 dims)
					pos = nth(1 lppShift)
					x = nth(0 pos)
					y = nth(1 pos)
					bbox = list((x-width/2):(y-height/2), (x+width/2):(y+height/2))
					bRect = dbCreateRect(quadcvid lpp1 bbox)
					
					; Invert
					dbLayerXor(quadcvid lpp1 theseShapes list(bRect))
			
					; Delete old shapes
					dbDeleteObject(bRect)
					foreach(shape theseShapes
						dbDeleteObject(shape)
					)
				)
			)
		)	
		
		; Clean up
		dbClose(sourcecvid)
		dbClose(tempcvid)
		dbSave(quadcvid)
		dbClose(quadcvid)
	)
)