; Generate a scale bar of the requested length (in um, but sizes less than 1 um are available)
procedure(scalebar(width @optional (formatStr "%1.0f"))
	let( (targetCV targetLPP height position x y unit)
		targetCV = deGetCellView()		; Put this in the current cell
		targetLPP = leGetEntryLayer()	; Create scale bar in current layer
		
		
		height = width/20.0
		leHiSetRefPoint()
		position = leGetRefPoint(targetCV)
		
		; Determine the units and scale the width
		width = float(width)
		cond(
			(width >= 1000 unit = "mm"
			               displayWidth = width / 1000)
			               
			(width >= 1    unit = "um"
			               displayWidth = width)
			
			(t             unit = "nm"
			               displayWidth = width * 1000)
		)
		
		print(unit)
		
		; Draw the scale bar
		x = xCoord(position)
		y = yCoord(position)
		dbCreateRect(targetCV targetLPP list((x-width/2.0):(y-height/2.0) (x+width/2.0):(y+height/2.0)))
		
		; Write the label centered above scale bar
		label = strcat(formatStr " " unit)
		sprintf(label label displayWidth)
		pgTextAtPosition(targetCV targetLPP label height*3.0 "c" "b" x:(y+height*1.5))
	)
)