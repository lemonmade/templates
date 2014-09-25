build: templates.applescript
	   rm templates.scpt
	   osacompile -o templates.scpt templates.applescript
	   # Take an image and make the image its own icon:
	   sips -i icon.png
	   # Extract the icon to its own resource file:
	   DeRez -only icns icon.png > tmpicns.rsrc
	   # append this resource to the file you want to icon-ize.
	   Rez -append tmpicns.rsrc -o templates.scpt
	   # Use the resource to set the icon.
	   SetFile -a C templates.scpt
	   # clean up.
	   rm tmpicns.rsrc
