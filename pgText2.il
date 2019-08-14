
procedure(pgText(userText fontHeight @optional (horizAlign "c") (vertAlign "B") (font "CS"))
	let( (position cvid)
		cvid = deGetCellView()
		leHiSetRefPoint()
		position = leGetRefPoint(cvid)
		pgTextAtPosition(position userText fontHeight horizAlign vertAlign font)
	)
)

procedure(pgTextAtPosition(position userText fontHeight @optional (horizAlign "c") (vertAlign "B") (font "CS"))
	let( (cvid lpp)
		cvid = deGetCellView()
		lpp = leGetEntryLayer()
		pgTextInCell(cvid lpp position userText fontHeight horizAlign vertAlign font)
	)
)

procedure(pgTextInCell(cvid lpp anchor userText fontHeight @optional (horizAlign "c") (vertAlign "B") (font "CS"))
	prog( (tmp i k c fontMap fontMapName scale textLines nLines blockWidth blockHeight horizOffset vertOffset tmp_cvid letter_cvid)
		; load font map
		fontMapName = strcat("SKILL/" font ".fontmap")
		if(isReadable(fontMapName)
		then
			load(fontMapName)
		else
			printf("Error: fontmap not found for font: %s" font)
			return()
		)
		
		; Determine font scaling
		fontMap["scale"] = float(fontHeight) / float(fontMap["height"])
		
		; Break up text into list of lines and get length per line
		textLines = parseString(userText "\n")
		nLines = length(textLines)
		lineLengths = list()
		blockWidth = 0
		
		foreach(line textLines
			tmp = 0
			for(i 1 strlen(line) 
				c = get_pname(getchar(line i))
				printf(c)
				tmp = tmp + fontMap["symbols"][c]["width"]
			)
			
			tmp = tmp + ((strlen(line) - 1) * fontMap["space"])
			lineLengths = cons(tmp lineLengths)
			blockWidth = max(blockWidth tmp)
		)
		lineLengths = reverse(lineLengths)
		blockHeight = (nLines - 1) * fontMap["baselineSkip"] + fontMap["height"]
		blockHeight = blockHeight
		
		horizOffset = 0
		vertOffset = 0
		case(horizAlign
			(list("left" "l") horizOffset = 0)
			(list("center" "c") horizOffset = -blockWidth/2)
			(list("right" "r") horizOffset = -blockWidth)
		)
		case(vertAlign
			(list("bottom" "b") vertOffset = blockHeight - fontMap["height"])
			(list("middle" "m") vertOffset = blockHeight/2 - fontMap["height"])
			(list("top" "t") vertOffset = -fontMap["height"])
			(list("base" "B") vertOffset = 0)
		)
		
		tmp_cvid = dbOpenCellViewByType("polygonText" "pgText2_tmp" "layout" "maskLayout" "w")
		
		xpos = 0
		ypos = 0
		foreach(line textLines
			i = 1
			while( i <= strlen(line)
				char = get_pname(getchar(line i))
				if(strcmp(char " ") then
					; handle escaped ($ surrounded) characters later
					letter_cvid = dbOpenCellView(fontMap["symbols"][char]["library"] fontMap["symbols"][char]["cell"] "layout")
					letter = dbCreateInst(tmp_cvid letter_cvid nil xpos:ypos "R0")
					dbClose(letter_cvid)
					if(letter != nil then
						dbFlattenInst(letter 1)
					)
					xpos = xpos + fontMap["symbols"][char]["width"]
				)
				xpos = xpos + fontMap["space"]
				i = i + 1
			)
			ypos = ypos - fontMap["baselineSkip"]
			xpos = 0
		)
	
		; Scale the temporary cell
		dbTransformCellView(tmp_cvid fontMap["scale"] 0.0)
		
		; Change the layer in the temporary cell to the desired one
		tmp_cvid~>shapes~>layerName = nth(0 lpp)
		tmp_cvid~>shapes~>purpose = nth(1 lpp)
	
		; Instance the scratch cell into the real cell
		xpos = xCoord(anchor) + horizOffset * fontMap["scale"]
		ypos = yCoord(anchor) + vertOffset * fontMap["scale"]
		textInst = dbCreateInst(cvid tmp_cvid nil xpos:ypos "R0")
		
		; Flatten the instanced text
		dbFlattenInst(textInst 1)
	
		; Clean up
		dbClose(tmp_cvid)
	)
)
