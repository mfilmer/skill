; [outLayer=] geomXor( inLayer1 [inLayer2])
; newShapes = leMergeShapes(shapes)

procedure(xorLayer()
	let((cvid lpp bbox)
		cvid = deGetCellView()
		lpp = leGetEntryLayer()
		bbox = dbComputeBBoxNoNLP(cvid)
		
		xorLayerInCell(cvid lpp bbox)
	)
)

procedure(xorLayerInCell(cvid lpp bbox)
	let((shapes bRect)
		; Select all shapes of the desired LPP
		;shapes = cvid~>shapes
		;shapes = setof(x shapes (x~>lpp == lpp))
		; Apparently it is faster to find the lpp we want and then grab all the shapes that it has.
		; This is better than the naive approach (above) of getting all the shapes and filtering out the lpps we don't want
		shapes = car(setof(x cvid~>lpps (x~>layerName == nth(0 lpp) && x~>purpose == nth(1 lpp) )))
		shapes = shapes~>shapes
		
		; Merge these shapes
		;shapes = leMergeShapes(shapes)
		
		; Draw bounding box rectangle
		bRect = dbCreateRect(cvid lpp bbox)
		
		; xor the layer
		;shapes = geomXor(lpp)
		dbLayerXor(cvid lpp shapes list(bRect))
		
		; Delete old shapes
		dbDeleteObject(bRect)
		foreach(shape shapes
			dbDeleteObject(shape)
		)
	)
)
