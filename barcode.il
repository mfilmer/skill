; GCA Barcode Generator v1.1
; Matthew Filmer 9/7/2018
;
; Changelog
; v1.1 - 9/10/2018
; Added the ability to generate at either mask scale (positions -5 and 5) or design scale (positions -1 and 1)
; Default position is now "-1" which is on the bottom right side at design scale
;
; v1.0 - 9/7/2018
; Initial release
;
;
; Generate a barcode compatible with the GCA Alphastep 200 (and probably other GCA steppers)
; Barcodes are made up of 1-10 characters.
; Valid characters include A-Z, 0-9, and select special characters (ascii characters 32 - 95)
; lowercase letters are converted to uppercase automatically.
;
; Barcode spec (mask dimensions)
; Height: 3 mm
; Start quiet zone: 4 mm
; Each segment is an integer multiple of 0.15 mm long
; Sync 1: 3x space-line all 1-1-1-1-1-1               total: 6  (0.9 mm)
; Start character: 3x space-line 4-1-2-1-1-1          total: 10 (1.5 mm)
; 1-10 characters: 3x space-line varying weights      total: 10 (1.5 mm)
; Checksum character: 3x space-line varying weights   total: 10 (1.5 mm)
; Stop character: 3x space-line 5-1-1-1-1-1           total: 10 (1.5 mm)
; Sync 2: 3x line-space all 1-1-1-1-1-1               total: 6  (0.9 mm)
; End quiet zone: 4 mm
; Total barcode length: 15.8mm (1 char) to 29.3 mm (10 chars)
;
; makeBarcode(barcodeText)
; Generates a barcode in the default position of "-1": bottom right, design scale.
; Uses the currenty active layer in the active cell. 
; This is what most users probably want as it will result in the stepper imaging
; patterns rotated "as designed". 
; barcodeText: 1-10 character string (will be truncated to 10 characters if > 10 are given)
;
; makeBarcode(barcodeText position)
; Generates a barcode in the currently active layer in the active cell.
; barcodeText: 1-10 character string (will be truncated to 10 characters if > 10 are given)
; position: 1, -1, 5, or -5 to indicate barcode position and scale.
;   1, 5 -> top left            -1,-5 -> bottom right
;   1,-1 -> design scale         5,-5 -> mask scale
procedure(makeBarcode(barcodeText @optional (position -1))
	let( (target_cvId targetLPP)
		target_cvId = deGetCellView()
		targetLPP = leGetEntryLayer()
		generateBarcodeInCell(barcodeText position target_cvId targetLPP)
	)
)

; generateBarcodeInCell(barcodeText position target_cvId targetLPP)
; Generates a barcode in the specified cell in the specified layer-purpose-pair
; barcodeText: 1-10 character string (will be truncated to 10 characters if > 10 are given)
; position: 1, -1, 5, or -5 to indicate barcode position and scale.
;   1, 5 -> top left            -1,-5 -> bottom right
;   1,-1 -> design scale         5,-5 -> mask scale
; target_cvId: Cell to generate the barcode in.
; targetLPP: Layer-Purpose-Pair to use to generate the barcode shapes
procedure(generateBarcodeInCell(barcodeText position target_cvId targetLPP)
	let( (barcodeHeight unitWidth startingPos currentX constantY nChars ordSum quietLength fiducialXs fiducialYs fiducialSize)
		; Check for valid position
		if((position != 1 && position != -1 && position != 5 && position != -5) then
			printf("Warning: Invalid position, using default;: -1\n")
			position = -1
		)
		
		; Constants
		barcodeHeight = position * 3000 / 5
		unitWidth = position * 150 / 5
		quietLength = position * 4000 / 5
		startingPos = (position * -50000 / 5):(position * 56000 / 5)
		fiducialXs = list(position*-11000/5 0 position*11000/5)
		fiducialYs = list(position*-57500/5 position*57500/5)
		fiducialSize = position * 2000 / 5
		
		; Initialization
		barcodeText = upperCase(barcodeText)
		currentX = xCoord(startingPos)
		constantY = yCoord(startingPos)
		
		; Write quiet zone 1
		bcode_writeQuietZone(currentX:constantY position)
		currentX = currentX + quietLength
		
		; Write sync 1
		bcode_writeSequence('(1 1 1 1 1 1) currentX:constantY position)
		currentX = currentX + 6*unitWidth
		
		; Write start sequence
		bcode_writeCharacter("start" currentX:constantY position)
		currentX = currentX + 10*unitWidth
		
		; Write 1-10 characters
		nChars = strlen(barcodeText)
		ordSum = 0
		if(nChars > 10 then
			printf("Warning: Barcode truncated to first 10 characetrs!\n")
			printf("Barcode will be: %s\n" substring(barcodeText 1 10))
		)
		for(ind 1 min(10 nChars)
			char = getchar(barcodeText ind)
			ord = bcode_calcCodeOrd(char)
			if(ord < 1 || ord > 64 then
				printf("Illegal character: %c replaced with _" char)
				char = '_
			)
			bcode_writeCharacter(char currentX:constantY position)
			currentX = currentX + 10*unitWidth
			ordSum = ordSum + bcode_calcCodeOrd(char)
		)
		
		; Write check character
		bcode_writeCheckChar(ordSum currentX:constantY position)
		currentX = currentX + 10*unitWidth
		
		; Write stop character
		bcode_writeCharacter("stop" currentX:constantY position)
		currentX = currentX + 10*unitWidth
		
		; Write sync 2
		currentX = currentX - unitWidth	; sync 2 goes 3x line-space, this shift makes it work
		bcode_writeSequence('(1 1 1 1 1 1) currentX:constantY position)
		currentX = currentX + unitWidth	; undo the shift
		currentX = currentX + 6*unitWidth
		
		; Write quiet zone 2
		bcode_writeQuietZone(currentX:constantY position)
		currentX = currentX + quietLength
		
		
		; Barcode generation complete
		; Now to write the mask fiducial marks
		
		let( (x y)
			foreach(x fiducialXs
				foreach(y fiducialYs
					dbCreateRect(target_cvId targetLPP list((x-fiducialSize/2):(y-fiducialSize/2) (x+fiducialSize/2):(y+fiducialSize/2)))
				)
			)
		)
	)
) ; end makeBarcode()

; Helper function for the ascii table
; Returns the first character in a string
; This effectively converts a single character string into a single character
procedure(bcode_toChar(str "S")
	getchar(str 1)
)

; Association Table to convert characters to their barcode sequences (table is incomplete, more characters could be supported from ascii 32 to 97)
barcode_table = makeTable("barcode_table" list(0 0 0 0 0 0))
; ascii 32 - 47
barcode_table[bcode_toChar(" ")] = list(1 5 1 1 1 1)
barcode_table[bcode_toChar("!")] = list(1 4 1 2 1 1)
barcode_table[bcode_toChar("\"")] = list(1 4 1 1 1 2)
barcode_table[bcode_toChar("#")] = list(1 3 1 3 1 1)
barcode_table[bcode_toChar("$")] = list(1 3 1 2 1 2)
barcode_table[bcode_toChar("%")] = list(1 3 1 1 1 3)
barcode_table[bcode_toChar("&")] = list(1 3 1 1 3 1)
barcode_table[bcode_toChar("'")] = list(1 3 2 1 2 1)
barcode_table[bcode_toChar("(")] = list(1 3 3 1 1 1)
barcode_table[bcode_toChar(")")] = list(1 2 1 4 1 1)
barcode_table[bcode_toChar("*")] = list(1 2 1 3 1 2)
barcode_table[bcode_toChar("+")] = list(1 2 1 2 1 3)
barcode_table[bcode_toChar(",")] = list(1 2 1 2 3 1)
barcode_table[bcode_toChar("-")] = list(1 2 1 1 1 4)
barcode_table[bcode_toChar(".")] = list(1 2 1 1 3 2)
barcode_table[bcode_toChar("/")] = list(1 2 2 2 2 1)

; ascii 48 - 57
barcode_table[bcode_toChar("0")] = list(1 2 2 1 2 2)
barcode_table[bcode_toChar("1")] = list(1 2 3 2 1 1)
barcode_table[bcode_toChar("2")] = list(1 2 3 1 1 2)
barcode_table[bcode_toChar("3")] = list(1 1 1 5 1 1)
barcode_table[bcode_toChar("4")] = list(1 1 1 4 1 2)
barcode_table[bcode_toChar("5")] = list(1 1 1 3 1 3)
barcode_table[bcode_toChar("6")] = list(1 1 1 3 3 1)
barcode_table[bcode_toChar("7")] = list(1 1 1 2 1 4)
barcode_table[bcode_toChar("8")] = list(1 1 1 2 3 2)
barcode_table[bcode_toChar("9")] = list(1 1 1 1 1 5)

; ascii 58 - 64
barcode_table[bcode_toChar(":")] = list(1 1 1 1 3 3)
barcode_table[bcode_toChar(";")] = list(1 1 1 1 5 1)
barcode_table[bcode_toChar("<")] = list(1 1 2 3 2 1)
barcode_table[bcode_toChar("=")] = list(1 1 2 2 2 2)
barcode_table[bcode_toChar(">")] = list(1 1 2 1 2 3)
barcode_table["?"] = list(1 1 2 1 4 1)
barcode_table[bcode_toChar("@")] = list(1 1 3 3 1 1)

; ascii 65 - 90
barcode_table['A] = list(1 1 3 2 1 2)
barcode_table['B] = list(1 1 3 1 1 3)
barcode_table['C] = list(1 1 3 1 3 1)
barcode_table['D] = list(1 1 4 1 2 1)
barcode_table['E] = list(1 1 5 1 1 1)
barcode_table['F] = list(2 3 1 1 2 1)
barcode_table['G] = list(2 3 2 1 1 1)
barcode_table['H] = list(2 2 1 2 2 1)
barcode_table['I] = list(2 2 1 1 2 2)
barcode_table['J] = list(2 2 2 2 1 1)
barcode_table['K] = list(2 2 2 1 1 2)
barcode_table['L] = list(2 1 1 3 2 1)
barcode_table['M] = list(2 1 1 2 2 2)
barcode_table['N] = list(2 1 1 1 2 3)
barcode_table['O] = list(2 1 1 1 4 1)
barcode_table['P] = list(2 1 2 3 1 1)
barcode_table['Q] = list(2 1 2 2 1 2)
barcode_table['R] = list(2 1 2 1 1 3)
barcode_table['S] = list(2 1 2 1 3 1)
barcode_table['T] = list(2 1 3 1 2 1)
barcode_table['U] = list(2 1 4 1 1 1)
barcode_table['V] = list(3 3 1 1 1 1)
barcode_table['W] = list(3 2 1 2 1 1)
barcode_table['X] = list(3 2 1 1 1 2)
barcode_table['Y] = list(3 1 1 3 1 1)
barcode_table['Z] = list(3 1 1 2 1 2)

; ascii 91 - 96 + start, stop
barcode_table[bcode_toChar("[")] = list(3 1 1 1 1 3)
barcode_table[bcode_toChar("\\")] = list(3 1 1 1 3 1)
barcode_table[bcode_toChar("]")] = list(3 1 2 1 2 1)
barcode_table[bcode_toChar("^")] = list(3 1 3 1 1 1)
barcode_table[bcode_toChar("_")] = list(4 1 1 1 2 1)
barcode_table["start"] = list(4 1 2 1 1 1)
barcode_table["stop"] = list(5 1 1 1 1 1)

; bcode_verifyAsciiTable()
; Verify that the ascii table contains only valid sequences
; and that all characters are within ascii range 32 - 97
procedure(bcode_verifyAsciiTable(ascii)
	let( (total valid invalid sum)
		total = 0
		valid = 0
		invalid = 0
		foreach(key ascii
			sum = nth(0 barcode_table[key]) + nth(1 barcode_table[key]) + nth(2 barcode_table[key]) + nth(3 barcode_table[key]) +nth(4 barcode_table[key]) + nth(5 barcode_table[key])
			if(sum != 10
				then
					printf("Character '%c' sequence invalid\n" key)
					invalid = invalid + 1
				else
					valid = valid + 1
			)
			total = total + 1
		)
		
		printf("%d character sequences checked\n" total)
		printf("%d character sequences valid\n" valid)
		printf("%d character sequences invalid\n" invalid)
	)
)

; bcode_writeSequence(seq pos layer)
; Draw a piece of the barcode
; seq: List of integer barcode weights, 6 elements long
; pos: Coordinate where the lower left corner of this sequence should be generated
procedure(bcode_writeSequence(seq pos direction)
	let( (x x2 y1 y2 unitWidth)
		unitWidth = direction * 150 / 5
		x = xCoord(pos)
		y1 = yCoord(pos)
		y2 = y1 + barcodeHeight
		for(ind 0 2
			; Space
			x = x + nth((ind*2) seq)*unitWidth
			
			; Line
			x2 = x + nth((ind*2 + 1) seq)*unitWidth
			dbCreateRect(target_cvId targetLPP list(x:y1 x2:y2))
			x = x2
		)
	)
)

; bcode_calcCodeOrd()
; Calculate the ordinal value of each character
procedure(bcode_calcCodeOrd(char)
	charToInt(char) - 32 + 1 ; The ordinal values are ascii values shifted by 32 but are 1 indexed
)

; bcode_writeCharacter(char charIndex)
; Draw the barcode corresponding to a single character
; char: The character to draw
; pos: Coordinate where the lower left corner of this sequence should be generated
procedure(bcode_writeCharacter(char pos direction)
	let( (seq)
		; Apparently '? is a special index for an associaton table in skill
		; so we have a special case just for that one
		case(char
			(? seq = barcode_table["?"])
			(t seq = barcode_table[char])
		)
		bcode_writeSequence(seq pos direction)
	)
)

; bcode_writeCheckChar(ordSum pos)
; Write the check character
; val: Value used to determine proper check character
; pos: Coordinate where the lower left corner of this sequence should be generated
procedure(bcode_writeCheckChar(ordSum pos direction)
	let( (checkVal checkChar)
		checkVal = mod(ordSum-1 64) + 1
		checkChar = intToChar(checkVal + 32 - 1)
		bcode_writeCharacter(checkChar pos direction)
	)
)

; bcode_writeQuietZone(pos)
procedure(bcode_writeQuietZone(pos direction)
	let( (x y)
		x = xCoord(pos)
		y = yCoord(pos)
		dbCreateRect(target_cvId targetLPP list(pos (x+direction*4000/5):(y+direction*3000/5)))
	)
)
