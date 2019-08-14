; cell view from active window
;cvId = deGetCellView()

; cell view by name ("r" -> read only "w" -> read/write)
;cvId = dbOpenCellViewByType("myLib" "myCell" "layout" "r")
; "s" -> scratch mode -> can't save to disk (but... it seems like you actually can)

procedure(pgText(userText fontHeight horizAlign vertAlign @optional (font "ledit"))
	let( (position target_cvId targetLPP)
		target_cvId = deGetCellView()
		leHiSetRefPoint()
		position = leGetRefPoint(target_cvId)
		targetLPP = leGetEntryLayer()
		pgTextAtPosition(target_cvId targetLPP userText fontHeight horizAlign vertAlign position font)
	)
)

procedure(pgTextAtPosition(target_cvId targetLPP userText fontHeight horizAlign vertAlign anchor @optional (font "ledit"))
	; Constants
	baseCharWidth = 3.846
	baseCharHeight = 6.924
	baseHorizStep = 4.5

	; Calculated adjustments
	scale = fontHeight / baseCharHeight
	charWidth = baseCharWidth * scale
	charHeight = baseCharHeight * scale
	horizStep = baseHorizStep * scale
	nChars = strlen(userText)
	stringWidth = (nChars - 1) * horizStep + charWidth
	horizOffset = 0
	vertOffset = 0
	case(horizAlign
		(list("left" "l") horizOffset = 0)
		(list("center" "c") horizOffset = -stringWidth/2)
		(list("right" "r") horizOffset = -stringWidth)
	)
	case(vertAlign
		(list("bottom" "b") vertOffset = 0)
		(list("middle" "m") vertOffset = -charHeight/2)
		(list("top" "t") vertOffset = -charHeight)
	)
	
	scratch_cvId = dbOpenCellViewByType("polygonText" "pgText_scratch" "layout" "maskLayout" "w")
	;text = upperCase(userText)
	text = userText

	;letters = '()
	; Instance and flatten the individual letters into a scratch cell
	xpos = 0
	for(index 1 strlen(text)
		char = getchar(text index)
		if( char != getchar(" " 1) then
			; Special characters have special names
			case(char
				('\\ char = "backslash")
				('\/ char = "slash")
				('\( char = "openParen")
				('\) char = "closeParen")
				('\- char = "hyphen")
				('\+ char = "plus")
				('\_ char = "underscore")
			)
			
			cellName = strcat(font "_" char)
			letter_cvId = dbOpenCellView("polygonText" cellName "layout")
			letter = dbCreateInst(scratch_cvId letter_cvId nil xpos:0 "R0")
			dbClose(letter_cvId)
			if(letter != nil then
				;letters = cons(letter letters)
				dbFlattenInst(letter 1)
			)
		)
		xpos = xpos + baseHorizStep
	)

	; Scale the scratch cell
	dbTransformCellView(scratch_cvId scale 0.0)
	
	; Change the layer in the scratch cell to the desired one
	scratch_cvId~>shapes~>layerName = nth(0 targetLPP)
	scratch_cvId~>shapes~>purpose = nth(1 targetLPP)
	

	; Instance the scratch cell into the real cell
	xpos = xCoord(anchor) + horizOffset
	ypos = yCoord(anchor) + vertOffset
	textInst = dbCreateInst(target_cvId scratch_cvId nil xpos:ypos "R0")
	
	; Flatten the instanced text
	dbFlattenInst(textInst 1)

	; Clean up
	dbClose(scratch_cvId)
)