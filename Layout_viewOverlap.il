; Open a new layout viewer window and show that the undercut resist looks like
procedure(viewOverlap()
	source_cvid = deGetCellView()
	viewOverlapFromView(source_cvid)
)

procedure(viewOverlapFromView(source_cvid)
	let( (lpp, dx, dy)
		dx = 0.090
		dy = 0.0
		source_cvid = deGetCellView()

		dest_cvid = dbOpenCellViewByType("sandbox" "overlap" "layout" "maskLayout" "w")
		winID = deOpenCellView("sandbox" "overlap" "layout" "maskLayout" list(list(100 50) list(1200 800)) "a")

		; Instance source into dest twice, with an offset
		dbCreateInst(dest_cvid source_cvid nil 0:0 "R0")
		dbCreateInst(dest_cvid source_cvid nil dx:dy "R0")

		dbSave(dest_cvid)
		dbClose(dest_cvid)
	)
)

