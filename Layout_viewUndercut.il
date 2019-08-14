; Open a new layout viewer window and show that the undercut resist looks like
procedure(viewUndercut()
	source_cvid = deGetCellView()
	viewUndercutFromView(source_cvid)
)


procedure(viewUndercutFromView(source_cvid)
	let( (lpp, dxdy)
		dxdy = 0.2
		;lpp = leGetEntryLayer()
		lpp = list("EBL1" "EBL")
		
		temp_cvid = dbOpenCellViewByType("sandbox" "undercut_tmp" "layout" "maskLayout" "w")
		dest_cvid = dbOpenCellViewByType("sandbox" "undercut" "layout" "maskLayout" "w")
		winID = deOpenCellView("sandbox" "undercut" "layout" "maskLayout" list(list(100 50) list(1200 800)) "a")

		; Instance source into tmp
		dbCreateInst(temp_cvid source_cvid nil 0:0 "R0")
		
		; Flatten dest cell
		while(temp_cvid~>instances
			foreach(inst temp_cvid~>instances
				if(inst~>mosaic
					then dbFlattenInst(inst~>mosaic 1 t)	; Flatten a mosaic
					else dbFlattenInst(inst 1 t)		; Flatten a simple instance
				)
			)
		)
		
		; Get array of shapes on the active lpp
		shapes = car(setof(x temp_cvid~>lpps (x~>layerName == nth(0 lpp) && x~>purpose == nth(1 lpp) )))
		shapes = shapes~>shapes

		; Copy each shape into the dest cell as well as a shifted copy
		holeShapes = list()
		undercutShapes = list()
		tform = list(0:0 "R0" 1.0)		; Original
		foreach(shape shapes
			newHoleShape = dbCopyShape(shape dest_cvid tform)
			newUndercutShape = dbCopyShape(shape dest_cvid tform)
			leSizeShape(newUndercutShape dxdy)
			newUndercutShape~>layerName = "EBL2"

			; add to theseShapes array
			holeShapes = cons(newHoleShape holeShapes)
			undercutShapes = cons(newUndercutShape undercutShapes)
		)

		; Get bounding box
		bbox = dbComputeBBoxNoNLP(dest_cvid)
		
		; Cut undercut hole
		bottomResist = dbCreateRect(dest_cvid list("EBL3" "EBL") bbox)
		dbLayerXor(dest_cvid list("EBL3" "EBL") list(bottomResist) undercutShapes)
		dbDeleteObject(bottomResist)
		
		; Cut bridge holes
		dbLayerXor(dest_cvid list("EBL2" "EBL") holeShapes undercutShapes)

		; Delete shapes
		foreach(shape holeShapes
			dbDeleteObject(shape)
		)
		foreach(shape undercutShapes
			dbDeleteObject(shape)
		)

		dbClose(temp_cvid)
		dbClose(dest_cvid)
		dbSave(dest_cvid)
	)
)