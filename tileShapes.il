procedure(tileShapes(nX, nY, xSteps, ySteps)
	let((x y)
		cvid = deGetCellView()
		
		; Get currently selected objects
		shapes = geGetSelectedSet()
		
		for(i 1 nX
			for(j 1 nY
				if(i != 1 || j != 1 then
					x = (i - 1) * nth(0 xSteps) + (j - 1) * nth(0 ySteps)
					y = (i - 1) * nth(1 xSteps) + (j - 1) * nth(1 ySteps)
					foreach(shape shapes
						dbCopyShape(shape cvid list(x:y "R0" 1))
					)
				)
			)
		)
	)
)