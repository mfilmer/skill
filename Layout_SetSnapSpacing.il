procedure( Layout_SetSnapSpacing( snap @optional window "ng" )
     unless( window
         window = hiGetCurrentWindow()
     )
     window->xSnapSpacing = snap
     window->ySnapSpacing = snap
)

