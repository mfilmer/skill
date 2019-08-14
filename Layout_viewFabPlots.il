; Open a new layout viewer window and show that the undercut resist looks like
procedure(viewFabPlots()
	source_cvid = deGetCellView()
	viewOverlapFromView(source_cvid)
	viewUndercutFromView(source_cvid)
)