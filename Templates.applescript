(*
	TEMPLATES.SCPT
	By Chris Sauve of [pxldot](http://pxldot.com).
	See README for details.
*)

--        ___       ___          ___          ___       ___
--       /  /\     /  /\        /  /\        /  /\     /  /\
--      /  /::\   /  /::\      /  /::\      /  /::\   /  /:/_
--     /  /:/\:\ /  /:/\:\    /  /:/\:\    /  /:/\:\ /  /:/ /\
--    /  /:/~/://  /:/~/:/   /  /:/  \:\  /  /:/~/://  /:/ /::\
--   /__/:/ /://__/:/ /:/___/__/:/ \__\:\/__/:/ /://__/:/ /:/\:\
--   \  \:\/:/ \  \:\/:::::/\  \:\ /  /:/\  \:\/:/ \  \:\/:/~/:/
--    \  \::/   \  \::/~~~~  \  \:\  /:/  \  \::/   \  \::/ /:/
--     \  \:\    \  \:\       \  \:\/:/    \  \:\    \__\/ /:/
--      \  \:\    \  \:\       \  \::/      \  \:\     /__/:/
--       \__\/     \__\/        \__\/        \__\/     \__\/

property startOrEndOfFolder : "start" -- change to "end" to put the new project at the end of the selected folder
property variableSymbol : "$" -- change to whatever delimiter you want to denote your variables
property defaultFolderPointer : ">>>" -- change to whatever delimtier you want to denote a default folder pointer
property defaultSubfolderPointer : ">"
property theOptionListstartDelimiter : "{" -- start of a list of options for the preceeding variable
property optionListEndDelimiter : "}" -- end of a list of options for the preceeding variable
property defaultTemplateFolder : "Template"
property specialSkipDays : {}

property dateFormat : "YYYY.MM.DD" -- sets the format that dates will be displayed in when shown as text (i.e., in notes)
(*
Use the following, in addition to any extra text, to create a custom date format (make sure to keep the simple quotes):

YEAR: "YYYY" - year with four digits (i.e., 2013), or "YY" - year with two digits (i.e., 13)
MONTH: "MMMM" - Month as text (i.e., June), "MMM" Month as text truncated to three letters (i.e., Jun), "MM" - Month with two digits using zero as padding (i.e., 06), or "M" - Month with no padding (i.e., 6)
DAY: "DD" - Day with two digits using zero as padding (i.e., 09), or "D" = Day without padding (i.e., 9)
WEEKDAY: "W" - Weekday as text (i.e., Monday)

# EXAMPLES (AS AT MONDAY, JUNE 17, 2013)

"YY-MM-DD" => "13-06-17"
"MMMM the D, YY" => "June the 17, 13"
"D/M/YYYY" => "17/6/2013"
*)

-- Don't change these
property firstRun : true
property specialTemplateFolder : null



--        ___          ___                     ___
--       /__/\        /  /\       ___         /__/\
--      |  |::\      /  /::\     /  /\        \  \:\
--      |  |:|:\    /  /:/\:\   /  /:/         \  \:\
--    __|__|:|\:\  /  /:/~/::\ /__/::\     _____\__\:\
--   /__/::::| \:\/__/:/ /:/\:\\__\/\:\__ /__/::::::::\
--   \  \:\~~\__\/\  \:\/:/__\/   \  \:\/\\  \:\~~\~~\/
--    \  \:\       \  \::/         \__\::/ \  \:\  ~~~
--     \  \:\       \  \:\         /__/:/   \  \:\
--      \  \:\       \  \:\        \__\/     \  \:\
--       \__\/        \__\/                   \__\/


try
	if firstRun then
		-- Get the variable symbol
		set variableSymbol to text returned of (display dialog "What symbol would you like to use to designate variable names in your templates?" default answer variableSymbol)
		set firstRun to false
	end if
	
	-- Get the list of projects in the template folder
	set templateProjectList to createTemplateProjectList()
	set projectNameList to nameListFromProjects(templateProjectList)
	
	-- Choose a project
	set selectedProject to promptWithList(projectNameList, "Select a Template Project", "Which one of your template projects would you like to make a new instance of?", "Select This Project")
	if selectedProject is false then die("")
	
	-- Get the selected project based on the user's list selection
	set projectPosition to my selectionPositions(selectedProject, projectNameList)
	set selectedProject to item projectPosition of templateProjectList
	
	
	tell application "OmniFocus"
		tell default document
			
			-- Key variables:
			-- targetFolder: the folder in which to put the new template instance
			-- selectedProject: the project to use as a template
			-- theVariables: list of plain variable names
			-- theReplacements: list of replacements for those variable names
			
			
			-- Determine which folder to put the new instance in.
			-- If a default folder is specified, put it there. Otherwise, prompt with all folders.
			set defaultFolder to my findDefaultFolder(note of selectedProject)
			
			set targetFolder to null
			if defaultFolder is false then
				-- Get all possible destination folders if no default folder exists
				-- "" & specialTemplateFolder prevents against null specialTemplateFolder
				set folderList to every flattened folder where (its name does not contain defaultTemplateFolder) and (its name does not contain ("" & specialTemplateFolder)) and (its effectively hidden is false)
				set folderNameList to {"(Top Level)"} & my nameListFromFolders(folderList)
				set selectedFolder to my promptWithList(folderNameList, "Select a Folder For The New Template Instance", "In which folder would you like to create a new instance of this template?", "Make Template Instance")
				
				-- Get the actual folder
				if selectedFolder is false then
					my die("")
				else if selectedFolder is {"(Top Level)"} then
					-- Set to default document
					set targetFolder to it
				else
					-- Subtract 1 to account for "Top Level"
					set folderPosition to (my selectionPositions(selectedFolder, folderNameList)) - 1
					set targetFolder to item folderPosition of folderList
				end if
			else
				set targetFolder to defaultFolder
			end if
			
			-- Find the variables and associated replacements
			set variableDetails to my findTheVariables(selectedProject)
			set theVariables to item 1 of variableDetails
			set thetheOptionLists to item 2 of variableDetails
			set theReplacements to my findTheReplacements(theVariables, thetheOptionLists)
			
			-- Copy project to the proper location in the designated folder
			-- Property startOrEndOfFolder controls where project is duplicated to
			set newProjectInstance to null
			if startOrEndOfFolder is "start" then
				set newProjectInstance to (duplicate selectedProject to the front of projects of targetFolder)
			else
				set newProjectInstance to (duplicate selectedProject to the end of projects of targetFolder)
			end if
			
			if newProjectInstance is null then my die("Sorry, something went wrong while copying this project.")
			
			-- Mark on hold projects as active in the case that they put their template projects on hold
			-- to prevent them appearing in certain views (like I do)
			if status of newProjectInstance is on hold then set status of newProjectInstance to active
			
			-- Kill the default folder and variable paragraphs of the new project
			if defaultFolder is not false then my killParagraphStartingWithString(newProjectInstance, defaultFolderPointer)
			if (length of theVariables > 0) then my killParagraphStartingWithString(newProjectInstance, variableSymbol)
			
			my populateTemplate(newProjectInstance, theVariables, theReplacements)
			my syncit()
			display notification "Project \"" & (name of newProjectInstance) & "\" is ready for action!" with title "OmniFocus Templates" subtitle "Created New Template Instance"
		end tell
	end tell
on error err
	
end try

--        ___          ___                   ___          ___
--       /  /\        /  /\         ___     /__/\        /  /\
--      /  /:/_      /  /:/_       /  /\    \  \:\      /  /::\
--     /  /:/ /\    /  /:/ /\     /  /:/     \  \:\    /  /:/\:\
--    /  /:/ /::\  /  /:/ /:/_   /  /:/  ___  \  \:\  /  /:/~/:/
--   /__/:/ /:/\:\/__/:/ /:/ /\ /  /::\ /__/\  \__\:\/__/:/ /:/
--   \  \:\/:/~/:/\  \:\/:/ /://__/:/\:\\  \:\ /  /:/\  \:\/:/
--    \  \::/ /:/  \  \::/ /:/ \__\/  \:\\  \:\  /:/  \  \::/
--     \__\/ /:/    \  \:\/:/       \  \:\\  \:\/:/    \  \:\
--       /__/:/      \  \::/         \__\/ \  \::/      \  \:\
--       \__\/        \__\/                 \__\/        \__\/

-- Determines the template folder and creates the list of projects in that template folder.
on createTemplateProjectList()
	tell application "OmniFocus"
		tell default document
			set projectList to {}
			
			-- Special template folder has been set previously
			if specialTemplateFolder is not null then
				set projectList to my projectListWithExclusions(specialTemplateFolder)
				
				-- No previously-set template folder
			else
				set projectList to my projectListWithExclusions(defaultTemplateFolder)
				
				-- No projects in a folder called "Template"
				if length of projectList is 0 then
					-- Get all possible special template folders
					set templateFolderList to every flattened folder where (its hidden is false) and (its name does not contain "!exclude")
					set templateFolderNameList to my nameListFromFolders(templateFolderList)
					
					-- No folders that match required criteria
					if length of templateFolderNameList is 0 then my die("You do not have any non-dropped folders. Please create a \"Templates\" folder and at least one project to use this script.")
					
					-- Get user-selected special template folder and remember it
					set selectedTemplateFolder to my promptWithList(templateFolderNameList, "Choose Template Folder", "No obvious template folders were found. Please select the folder in which you store templates.", "Set as Template Folder")
					if selectedTemplateFolder is false then my die("")
					set specialTemplateFolder to selectedTemplateFolder
					
					set projectList to my projectListWithExclusions(specialTemplateFolder)
					
					if length of projectList is 0 then my die("No projects exist in the selected Templates folder. Please add at least one incomplete, non-dropped project to use this script.")
				end if
			end if
		end tell
	end tell
	
	return projectList
end createTemplateProjectList

-- Finds the default folder based on the project note.
-- Default folders are delimited by a leading defaultFolderPointer
-- string, with subfolders delimited by defaultSubfolderPointer.
on findDefaultFolder(projectNote)
	tell application "OmniFocus"
		tell default document
			-- Find the paragraph with the default folder pointer
			set folderDescriptor to null
			repeat with i from (count of paragraphs in projectNote) to 1 by -1
				if (paragraph i of projectNote starts with defaultFolderPointer) then set folderDescriptor to (paragraph i of projectNote) as string
			end repeat
			-- If no paragraph starts with the symbol, bail out
			if folderDescriptor is null then return false
			
			-- Get the components of the path description
			set folderDescriptor to my cleanTextPiecesWithDelimiters(folderDescriptor, {defaultFolderPointer & space, defaultFolderPointer, space & defaultSubfolderPointer & space, space & defaultSubfolderPointer, defaultSubfolderPointer & space, defaultSubfolderPointer})
			if length of folderDescriptor < 1 then return false
			
			-- If a subfolder is specified, go through each subfolder (up the hierarchy)
			-- and check if the current set of matching folders has a container by the appropriate name
			-- If so, add the folder to the set of matching folders and repeat
			set possibleFolders to every flattened folder where (its name is (item 1 of folderDescriptor))
			
			if length of folderDescriptor > 1 then
				
				-- For items 2 to -1 of the folder path description
				-- Find subfolders that match that name
				repeat with i from 2 to (length of folderDescriptor)
					set matchingFolders to {}
					set childProjectName to item i of folderDescriptor
					
					-- For each possible folder...
					repeat with theFolder in possibleFolders
						-- Add all of its matching subfolders to the matching list
						set matchingFolders to matchingFolders & (every flattened folder of theFolder where (its name is childProjectName))
					end repeat
					
					copy matchingFolders to possibleFolders
				end repeat
			end if
			
			-- If no matching folders, return false
			if length of possibleFolders < 1 then return false
			
			-- Return the first matching folder
			return first item of possibleFolders
		end tell
	end tell
end findDefaultFolder



--                                ___                   ___
--                   ___         /  /\         ___     /  /\
--                  /  /\       /  /:/_       /  /\   /  /:/_
--    ___     ___  /  /:/      /  /:/ /\     /  /:/  /  /:/ /\
--   /__/\   /  /\/__/::\     /  /:/ /::\   /  /:/  /  /:/ /::\
--   \  \:\ /  /:/\__\/\:\__ /__/:/ /:/\:\ /  /::\ /__/:/ /:/\:\
--    \  \:\  /:/    \  \:\/\\  \:\/:/~/://__/:/\:\\  \:\/:/~/:/
--     \  \:\/:/      \__\::/ \  \::/ /:/ \__\/  \:\\  \::/ /:/
--      \  \::/       /__/:/   \__\/ /:/       \  \:\\__\/ /:/
--       \__\/        \__\/      /__/:/         \__\/  /__/:/
--                               \__\/                 \__\/

-- Create a limited set of projects in the passed containing folder.
-- This creation limits the matching projects to those that 1) don't
-- have a dropped status, 2) don't have a done status, and 3) don't
-- include the string "!exclude" in their name
on projectListWithExclusions(containingFolder)
	tell application "OmniFocus"
		tell default document
			return every flattened project where (name of its folder contains containingFolder) and (effectively hidden of its folder is false) and (its status is not dropped) and (its status is not done) and (its name does not contain "!exclude")
		end tell
	end tell
end projectListWithExclusions

-- Create a list of all project names in the passed project list.
on nameListFromProjects(projectList)
	tell application "OmniFocus"
		tell default document
			set nameList to {}
			repeat with theProject in projectList
				set the end of nameList to the name of theProject
			end repeat
		end tell
	end tell
	
	return nameList
end nameListFromProjects

-- Create a list of all folder names in the passed folder list.
on nameListFromFolders(folderList)
	tell application "OmniFocus"
		tell default document
			set nameList to {}
			repeat with theFolder in folderList
				set nextListItem to ""
				
				-- Go up the hierarchy until something is not a folder.
				-- For every folder level, add some indentation spaces
				set theContainer to container of theFolder
				if class of theContainer is folder then
					set theContainer to container of theContainer
					repeat while class of theContainer is folder
						set nextListItem to nextListItem & "   "
						set theContainer to container of theContainer
					end repeat
				end if
				
				-- Append a new folder symbol
				if the class of theFolder's container is folder then set nextListItem to nextListItem & "↳ "
				set nextListItem to nextListItem & (name of theFolder)
				set the end of nameList to nextListItem
			end repeat
		end tell
	end tell
	
	return nameList
end nameListFromFolders

-- Gets the index of each item in selectList from originalList.
-- Can handle multiple or a single item in selectList.
on selectionPositions(selectList, originalList)
	set multipleSelections to (length of selectList) > 1
	set positionOfSelections to {}
	set selectIndex to 1
	
	repeat until selectIndex > (length of selectList)
		set selected to (item selectIndex of selectList)
		set originalIndex to 1
		
		repeat until originalIndex > (length of originalList)
			-- If they are the same, either return the index (if it's only a single choice)
			-- or add to the set of matching indexes
			if selected is (item originalIndex of originalList) then
				if not multipleSelections then
					return originalIndex
				else
					set end of positionOfSelections to originalIndex
				end if
			end if
			set originalIndex to originalIndex + 1
		end repeat
		
		-- If no item found, set to null
		if (length of positionOfSelections) < selectIndex then set end of positionOfSelections to null
		set selectIndex to selectIndex + 1
	end repeat
	
	return positionOfSelections
end selectionPositions



--        ___                   ___                     ___          ___
--       /  /\         ___     /  /\       ___         /__/\        /  /\
--      /  /:/_       /  /\   /  /::\     /  /\        \  \:\      /  /:/_
--     /  /:/ /\     /  /:/  /  /:/\:\   /  /:/         \  \:\    /  /:/ /\
--    /  /:/ /::\   /  /:/  /  /:/~/:/  /__/::\     _____\__\:\  /  /:/_/::\
--   /__/:/ /:/\:\ /  /::\ /__/:/ /:/___\__\/\:\__ /__/::::::::\/__/:/__\/\:\
--   \  \:\/:/~/://__/:/\:\\  \:\/:::::/   \  \:\/\\  \:\~~\~~\/\  \:\ /~~/:/
--    \  \::/ /:/ \__\/  \:\\  \::/~~~~     \__\::/ \  \:\  ~~~  \  \:\  /:/
--     \__\/ /:/       \  \:\\  \:\         /__/:/   \  \:\       \  \:\/:/
--       /__/:/         \__\/ \  \:\        \__\/     \  \:\       \  \::/
--       \__\/                 \__\/                   \__\/        \__\/

-- Returns all non-empty strings in theText that are delimited by the
-- passed list of delimiters.
on cleanTextPiecesWithDelimiters(theText, theDelimiters)
	set my text item delimiters to theDelimiters
	set textPieces to every text item of theText
	set my text item delimiters to ""
	
	set cleanedPieces to null
	repeat with textPiece in textPieces
		if length of textPiece is not 0 then
			if cleanedPieces is null then
				set cleanedPieces to {textPiece}
			else
				set the end of cleanedPieces to textPiece
			end if
		end if
	end repeat
	return cleanedPieces
end cleanTextPiecesWithDelimiters

-- Sets the note to the current note with all but the last paragraph
-- that begins with startString
on killParagraphStartingWithString(theProject, startString)
	tell application "OmniFocus"
		tell default document
			
			-- Get a copy of the note to manipulate
			copy the note of theProject to tempNote
			
			-- Get the paragraph starting with the passed string (or integer)
			set paraWithString to null
			set numberOfParagraphs to (count of paragraphs in tempNote)
			if class of startString is integer then
				set paraWithString to startString
			else
				repeat with i from numberOfParagraphs to 1 by -1
					if ((paragraph i of tempNote) as string) starts with startString then
						set paraWithString to i
						exit repeat
					end if
				end repeat
			end if
			
			-- Prevents destroying line breaks
			set my text item delimiters to {return}
			
			set newNote to null
			
			if paraWithString is null then
				-- No paragraph found
				set newNote to tempNote
			else if numberOfParagraphs is 1 then
				-- Paragraph found but there's only 1
				set newNote to ""
			else if paraWithString is 1 then
				-- First paragraph
				set newNote to (paragraphs 2 thru -1 of tempNote) as string
			else if paraWithString is numberOfParagraphs then
				-- Last paragraph
				set newNote to (paragraphs 1 thru -2 of tempNote) as string
			else
				-- Not first, not last
				set newNote to ((paragraphs 1 thru (paraWithString - 1) of tempNote) & (paragraphs (paraWithString + 1) thru -1 of tempNote)) as string
			end if
			
			set my text item delimiters to ""
			
			set the note of theProject to newNote
		end tell
	end tell
end killParagraphStartingWithString

-- Clean up any breaks at the beginning and end of the note
on cleanExcessBreaks(theText)
	-- For empty text or text with a single paragraph
	if (theText is missing value) or (length of theText is 0) or ((count of paragraphs of theText) is 1) then return theText
	
	-- Get start and end of paragraphs that have actual contents
	repeat with i from (count of paragraphs of theText) to 1 by -1
		if paragraph i of theText is not "" then
			set textEnds to i
			exit repeat
		end if
	end repeat
	
	repeat with j from 1 to (count of paragraphs of theText)
		if paragraph j of theText is not "" then
			set textStarts to j
			exit repeat
		end if
	end repeat
	
	-- Creates newlines between those paragraphs
	set text item delimiters to {return}
	set theNewText to paragraphs textStarts thru textEnds of theText as text
	set text item delimiters to ""
	
	return theNewText
end cleanExcessBreaks

-- Simple find and replace
on findReplace(theText, find, replace)
	set my text item delimiters to find
	set theText to every text item of theText
	set my text item delimiters to replace
	set theText to theText as text
	set my text item delimiters to ""
	return theText
end findReplace



--                     ___          ___                     ___
--       _____        /  /\        /  /\       ___         /  /\
--      /  /::\      /  /::\      /  /:/_     /  /\       /  /:/
--     /  /:/\:\    /  /:/\:\    /  /:/ /\   /  /:/      /  /:/
--    /  /:/~/::\  /  /:/~/::\  /  /:/ /::\ /__/::\     /  /:/  ___
--   /__/:/ /:/\:|/__/:/ /:/\:\/__/:/ /:/\:\\__\/\:\__ /__/:/  /  /\
--   \  \:\/:/~/:/\  \:\/:/__\/\  \:\/:/~/:/   \  \:\/\\  \:\ /  /:/
--    \  \::/ /:/  \  \::/      \  \::/ /:/     \__\::/ \  \:\  /:/
--     \  \:\/:/    \  \:\       \__\/ /:/      /__/:/   \  \:\/:/
--      \  \::/      \  \:\        /__/:/       \__\/     \  \::/
--       \__\/        \__\/        \__\/                   \__\/

-- Prompts the user to select from a list and returns the result.
-- Title, prompt, and OK button title are all passed as arguments.
on promptWithList(theList, theTitle, thePrompt, OKButton)
	tell application "OmniFocus"
		tell default document
			return choose from list theList with title theTitle with prompt thePrompt OK button name OKButton
		end tell
	end tell
end promptWithList

-- Kills execution of the script by sending a "User Cancelled" error.
-- If a message is passed, alers the user with that message.
on die(msg)
	tell application "OmniFocus"
		tell default document
			if msg is not "" then display alert msg
			error number -128
		end tell
	end tell
end die

-- Tries to sync the OF database
on syncit()
	try
		synchronize
	end try
end syncit








--        ___          ___                       ___       ___          ___
--       /__/\        /  /\                     /  /\     /  /\        /  /\
--       \  \:\      /  /:/_                   /  /::\   /  /:/_      /  /::\
--        \__\:\    /  /:/ /\   ___     ___   /  /:/\:\ /  /:/ /\    /  /:/\:\
--    ___ /  /::\  /  /:/ /:/_ /__/\   /  /\ /  /:/~/://  /:/ /:/_  /  /:/~/:/
--   /__/\  /:/\:\/__/:/ /:/ /\\  \:\ /  /://__/:/ /://__/:/ /:/ /\/__/:/ /:/___
--   \  \:\/:/__\/\  \:\/:/ /:/ \  \:\  /:/ \  \:\/:/ \  \:\/:/ /:/\  \:\/:::::/
--    \  \::/      \  \::/ /:/   \  \:\/:/   \  \::/   \  \::/ /:/  \  \::/~~~~
--     \  \:\       \  \:\/:/     \  \::/     \  \:\    \  \:\/:/    \  \:\
--      \  \:\       \  \::/       \__\/       \  \:\    \  \::/      \  \:\
--       \__\/        \__\/                     \__\/     \__\/        \__\/

-- Gets the (string) class of an item as either item, task, or project
on itemsClass(theItem)
	-- Default type
	set classOfItem to "item"
	
	tell application "OmniFocus"
		tell default document
			
			if class of theItem is task then
				set classOfItem to "task"
			else if class of theItem is project then
				set classOfItem to "project"
			end if
			
		end tell
	end tell
	
	return classOfItem
end itemsClass





--                    ___          ___          ___
--        ___        /  /\        /  /\        /  /\
--       /__/\      /  /::\      /  /::\      /  /:/_
--       \  \:\    /  /:/\:\    /  /:/\:\    /  /:/ /\
--        \  \:\  /  /:/~/::\  /  /:/~/:/   /  /:/ /::\
--    ___  \__\:\/__/:/ /:/\:\/__/:/ /:/___/__/:/ /:/\:\
--   /__/\ |  |:|\  \:\/:/__\/\  \:\/:::::/\  \:\/:/~/:/
--   \  \:\|  |:| \  \::/      \  \::/~~~~  \  \::/ /:/
--    \  \:\__|:|  \  \:\       \  \:\       \__\/ /:/
--     \__\::::/    \  \:\       \  \:\        /__/:/
--         ~~~~      \__\/        \__\/        \__\/

-- Returns two lists:
-- 1) List of variable names
-- 2) List of possible variable values, if a list of such values has been given,
--    for the corresponding variable in the first list. If the corresponding variable
--    in the first list did not have a choice list, its item in this list will be null.
on findTheVariables(theProject)
	tell application "OmniFocus"
		tell default document
			set theFullNote to the note of theProject
			
			-- No note, kick back out
			if theFullNote is missing value then return {{}, {}}
			
			-- Go through paragraphs from first to last to find the one that starts with
			-- the variable symbol.
			set theNote to null
			repeat with i from (count of paragraphs of theFullNote) to 1 by -1
				if paragraph i of theFullNote starts with variableSymbol then
					set theNote to (paragraph i of theFullNote) as text
					exit repeat
				end if
			end repeat
			
			-- No variables found
			if theNote is null then return {{}, {}}
			
			-- Extract the variables from the note
			set cleanedVariables to my cleanTextPiecesWithDelimiters(theNote, {space & variableSymbol, variableSymbol})
			
			-- Options lists will be delimited by the theOptionListstartDelimiter and optionListEndDelimite. If
			-- items in the cleanedVariables list have both delimited, they probably contain an option list.
			-- Extract this list, append it to the list of option lists, and clean the variable of this list.
			set theOptionLists to {}
			repeat with i from 1 to length of cleanedVariables
				set cleanedVariable to item i of cleanedVariables
				
				if (cleanedVariable contains theOptionListstartDelimiter) and (cleanedVariable contains optionListEndDelimiter) then
					
					-- Split it into variable name and options list
					set theSplit to my cleanTextPiecesWithDelimiters(cleanedVariable, {space & theOptionListstartDelimiter & space, space & optionListEndDelimiter & space, space & theOptionListstartDelimiter, space & optionListEndDelimiter, theOptionListstartDelimiter, optionListEndDelimiter})
					
					-- Reset the cleanedVariable to just the variable name
					set (item i of cleanedVariables) to (item 1 of theSplit)
					
					-- All of the options, delimited by commas
					set newOptionList to my cleanTextPiecesWithDelimiters(item 2 of theSplit, {" , ", " ,", ", ", ","})
					
					-- Append this options list
					set end of theOptionLists to newOptionList
				else
					-- No options list, append null
					set end of theOptionLists to null
				end if
			end repeat
		end tell
	end tell
	return {cleanedVariables, theOptionLists}
end findTheVariables

-- Creates a list of replacements corresponding to the passed variable list
-- Option list variables are resolved using theOptionLists
on findTheReplacements(theVariables, theOptionLists)
	tell application "OmniFocus"
		tell default document
			-- Here's where to store the repalcements
			set theReplacements to {}
			set theTitle to "Select Replacements for Variables"
			set thePrompt to ""
			
			repeat with i from 1 to (length of theVariables)
				-- special variable: "today", replaced with today's date
				if item i of theVariables contains "today" then
					set the end of theReplacements to (current date)
					
					-- All other variable types
				else
					-- First: create the prompt for the user input
					-- special variable: date variables
					if item i of theVariables starts with "date" then
						set thePrompt to "What date would you like to use for the date variable " & quote & (item i of theVariables) & quote & "? You can use an absolute or relative date."
						
						-- regular variable
					else if item i of theOptionLists is null then
						set thePrompt to "What would you like to replace " & quote & (item i of theVariables) & quote & " with?"
						
						-- special variable: option list
					else
						set thePrompt to "Which of the following options would you like to assign to the variable \"" & (item i of theVariables) & "\"?"
					end if
					
					-- non-option list variable
					if item i of theOptionLists is null then
						set theReturnInput to text returned of (display dialog thePrompt default answer "")
						
						-- Special variable: date variables
						if item i of theVariables starts with "date" then
							-- set theReturnInput to my englishTime(theReturnInput)
							-- set theCurrentDate to (current date)
							-- set time of theCurrentDate to 0
							-- set theReturnInput to theCurrentDate + theReturnInput
							set theReturnInput to my findReplace(theReturnInput, ":", "")
							set dateHelperVariable to first item of (parse tasks into it with transport text ("Template Helper #" & theReturnInput & "#1d"))
							set theReturnInput to (defer date of dateHelperVariable) as date
							delete dateHelperVariable
						end if
						
						-- Append to replacements
						set the end of theReplacements to theReturnInput
						
					else
						-- special variable: option list
						-- Append to the replacements from the option list
						set the end of theReplacements to my promptWithList((item i of theOptionLists), "Set value for " & quote & (item i of theVariables) & quote, thePrompt, "Set " & quote & (item i of theVariables) & quote) as string
					end if
				end if
			end repeat
		end tell
	end tell
	
	return theReplacements
end findTheReplacements

-- Replaces variables in the text with the corresponding item in theReplacements
on replaceVariables(theText, theVariables, theReplacements)
	if (length of theVariables is 0) or (length of theText is 0) then return theText
	
	repeat with i from 1 to (length of theVariables)
		
		-- Split on the variable
		set my text item delimiters to (item i of theVariables)
		set theText to every text item of theText
		
		-- Set the replacement text. If it's a date, set it to the custom format that's
		-- been specified.
		if class of (item i of theReplacements) is date then
			set my text item delimiters to my customDateStyle(item i of theReplacements)
		else
			set my text item delimiters to (item i of theReplacements)
		end if
		
		-- Create the replaced variable string
		set theText to theText as string
		set my text item delimiters to ""
	end repeat
	
	return theText
end replaceVariables








--        ___       ___          ___       ___                       ___                   ___
--       /  /\     /  /\        /  /\     /__/\                     /  /\         ___     /  /\
--      /  /::\   /  /::\      /  /::\    \  \:\                   /  /::\       /  /\   /  /:/_
--     /  /:/\:\ /  /:/\:\    /  /:/\:\    \  \:\   ___     ___   /  /:/\:\     /  /:/  /  /:/ /\
--    /  /:/~/://  /:/  \:\  /  /:/~/:/___  \  \:\ /__/\   /  /\ /  /:/~/::\   /  /:/  /  /:/ /:/_
--   /__/:/ /://__/:/ \__\:\/__/:/ /://__/\  \__\:\\  \:\ /  /://__/:/ /:/\:\ /  /::\ /__/:/ /:/ /\
--   \  \:\/:/ \  \:\ /  /:/\  \:\/:/ \  \:\ /  /:/ \  \:\  /:/ \  \:\/:/__\//__/:/\:\\  \:\/:/ /:/
--    \  \::/   \  \:\  /:/  \  \::/   \  \:\  /:/   \  \:\/:/   \  \::/     \__\/  \:\\  \::/ /:/
--     \  \:\    \  \:\/:/    \  \:\    \  \:\/:/     \  \::/     \  \:\          \  \:\\  \:\/:/
--      \  \:\    \  \::/      \  \:\    \  \::/       \__\/       \  \:\          \__\/ \  \::/
--       \__\/     \__\/        \__\/     \__\/                     \__\/                 \__\/

-- Populate all items in the project
on populateTemplate(theProject, cleanedVariables, theReplacements)
	-- Recreate the delimited variables so they can be found in notes/ folders
	set delimCleanedVariables to {}
	repeat with cleanedVariable in cleanedVariables
		set the end of delimCleanedVariables to (variableSymbol & cleanedVariable)
	end repeat
	
	tell application "OmniFocus"
		tell default document
			tell theProject
				my populateItem(it, delimCleanedVariables, cleanedVariables, theReplacements)
				
				-- Going through the tasks
				repeat with theTask in (every flattened task of it)
					my populateItem(theTask, delimCleanedVariables, cleanedVariables, theReplacements)
				end repeat
				
				-- Cycle through again to delete tasks that must be deleted
				-- This is done separately to prevent the flattened task list being
				-- modified mid-iteration
				set taskList to every flattened task of it
				repeat with i from (length of taskList) to 1 by -1
					if note of (item i of taskList) contains "!!!Delete" then delete (item i of taskList)
				end repeat
				
			end tell -- telling project
		end tell -- telling document
	end tell -- telling OF
end populateTemplate

-- Does all the required work to populate variables, adjust dates, edit the context,
-- check for completion statement, check for @support requests, and evaluate conditionals
on populateItem(theItem, delimCleanedVariables, cleanedVariables, theReplacements)
	tell application "OmniFocus"
		tell default document
			tell theItem
				-- Replace project name
				set its name to my replaceVariables(its name, delimCleanedVariables, theReplacements)
				
				set possibleDateChange to true
				repeat while possibleDateChange
					set possibleDateChange to my checkingForDateInformation(it, delimCleanedVariables, theReplacements)
				end repeat
				
				-- Replace project note
				set its note to my replaceVariables(its note, delimCleanedVariables, theReplacements)
				
				-- Sort out the context
				if its context is not missing value then
					set targetContext to my workingTheContext(its context, delimCleanedVariables, theReplacements)
					try
						if targetContext is not null then set its context to targetContext
					end try
				end if
				
				-- Add @support string if asked for
				if (its note contains "@support: ask" or its note contains "@support:ask") and (its class is project) then
					-- Get the folder path for support
					set theSupportPath to (choose folder with prompt "Select the folder that contains the reference material for the project " & quote & (name of it) & quote & ".") as string
					
					-- Replace ask with the folder path
					set my text item delimiters to {": ask", ":ask"}
					set theSupportNote to every text item of (its note as string)
					set my text item delimiters to {space & theSupportPath}
					set its note to theSupportNote as string
					set my text item delimiters to ""
				end if
				
				-- Check for complete: ask statements
				set completeTheTask to false
				set deleteTheTask to false
				if (its class is not project) and (its note contains "complete:ask" or its note contains "complete: ask") then
					set completeTheTask to (button returned of (display dialog "In the note, you indicated that you wanted to be asked whether to complete the task \"" & (name of it) & "\" when you create a new instance of this project. Would you like to complete this task?" buttons {"Yes, Complete", "No, Leave Incomplete"} default button 2) is "Yes, Complete")
					my killParagraphStartingWithString(it, "complete:")
				end if
				
				if (its class is not project) and (its note contains "delete:ask" or its note contains "delete: ask") then
					set deleteTheTask to (button returned of (display dialog "In the note, you indicated that you wanted to be asked whether to delete the task \"" & (name of it) & "\" when you create a new instance of this project. Would you like to delete this task?" buttons {"Yes, Delete", "No, Leave It Alone"} default button 2) is "Yes, Delete")
					my killParagraphStartingWithString(it, "complete:")
				end if
				
				-- Check for conditional actions
				set conditionalAction to false
				if its class is not project then
					set conditionalAction to my conditionalCheck(it)
				end if
				
				if conditionalAction is "complete" then set completeTheTask to true
				if conditionalAction is "delete" then set deleteTheTask to true
				
				if completeTheTask is true then
					set its completed to true
					
				else if deleteTheTask is true then
					set its note to "!!!DELETE"
					
				else
					-- Don't bother setting the dates if we are just completing/ deleting it
					-- Set due/ start date if required
					
				end if
				
				-- Clean any excess breaks
				set its note to my cleanExcessBreaks(its note)
			end tell
		end tell
	end tell
end populateItem





--       _____         ___                   ___          ___
--      /  /::\       /  /\         ___     /  /\        /  /\
--     /  /:/\:\     /  /::\       /  /\   /  /:/_      /  /:/_
--    /  /:/  \:\   /  /:/\:\     /  /:/  /  /:/ /\    /  /:/ /\
--   /__/:/ \__\:| /  /:/~/::\   /  /:/  /  /:/ /:/_  /  /:/ /::\
--   \  \:\ /  /://__/:/ /:/\:\ /  /::\ /__/:/ /:/ /\/__/:/ /:/\:\
--    \  \:\  /:/ \  \:\/:/__\//__/:/\:\\  \:\/:/ /:/\  \:\/:/~/:/
--     \  \:\/:/   \  \::/     \__\/  \:\\  \::/ /:/  \  \::/ /:/
--      \  \::/     \  \:\          \  \:\\  \:\/:/    \__\/ /:/
--       \__\/       \  \:\          \__\/ \  \::/       /__/:/
--                    \__\/                 \__\/        \__\/

-- Finds the target start/ due date, either using date variables, ask statements,
-- or date amounts hard-coded in
-- TODO: variables are already replaced, so date variable thing probably won't work
on checkingForDateInformation(theItem, theVariables, theReplacements)
	tell application "OmniFocus"
		tell default document
			
			-- Get a copy of the note to work with
			set theOriginalNote to the note of theItem
			copy theOriginalNote to theNote
			
			-- Dates could be in the following forms:
			-- due: ask
			-- due:ask +- sometime
			-- due someTime
			-- start: project
			-- start project +- someTime
			-- defer: $dateVar
			-- defer $dateVar +- someTime
			
			-- Any of the someTime styles can also have -W/-S to specify
			-- that weekends and special days (respectively) shouldn't be counted
			
			
			-- State variables
			set dueOrStart to null
			set askForDate to false
			set relativeToProject to false
			set dateVariable to false
			set dateVariablePosition to -1
			set plusOrMinus to null
			
			-- First element is the base date, second is the someTime amount
			set target to {0, 0}
			
			-- Find and store the part of the note that contains due/ start info
			repeat with theParagraph in (every paragraph of theNote)
				if (theParagraph starts with "start:") or (theParagraph starts with "defer:") or (theParagraph starts with "due:") then
					set theNote to theParagraph
					exit repeat
				end if
			end repeat
			
			-- Determine whether its due or start
			if (theNote starts with "due") then
				set dueOrStart to "due"
			else if (theNote starts with "start") then
				set dueOrStart to "start"
			else if (theNote starts with "defer") then
				set dueOrStart to "defer"
			end if
			
			-- Clean the item's note
			my killParagraphStartingWithString(theItem, dueOrStart)
			
			-- Neither due nor start was found
			if dueOrStart is null then
				return false
			else
				-- User wants to be asked for the date
				if theNote contains "ask" then set askForDate to true
				
				-- User wants date to be relative to the project
				if theNote contains "project" then set relativeToProject to true
				
				-- There is a variable required to compute the date
				repeat with i from 1 to (length of theVariables)
					if item i of theVariables is in theNote then
						set dateVariable to true
						set dateVariablePosition to i
						exit repeat
					end if
				end repeat
				
				-- Special adjustments that can be used. -W or -w at the end of the note will only count weekdays
				-- when calculating relative dates.
				set specialAdjustForWeekends to ((theNote contains "-W") or (theNote contains "-w"))
				set specialAdjustForOtherDays to ((theNote contains "-S") or (theNote contains "-s"))
				
				-- Get rid of the special adjustment vars
				set my text item delimiters to {"-W", "-w", "-S", "-s"}
				set theNote to every text item of theNote
				set my text item delimiters to ""
				set theNote to theNote as string
				
				-- Figure out if time is added or subtracted
				if (theNote contains "-") then set plusOrMinus to "minus"
				if (theNote contains "+") then set plusOrMinus to "plus"
				
				set possibleDelimiters to {"Due: ", "Start: ", "Defer: ", "Due:", "Start:", "Defer:", "Due ", "Start ", "Defer ", "ask", "project", "today", " + ", " - ", " +", " -", "+ ", "- ", "+", "-"}
				if dateVariable is not false then set end of possibleDelimiters to (item dateVariablePosition of theVariables)
				
				-- The pieces left over after all of the above are accounted for: should leave only someTime
				set someTime to my cleanTextPiecesWithDelimiters(theNote, possibleDelimiters)
				set my text item delimiters to ""
				set someTime to someTime as string
				
				log someTime
				
				if someTime is not "null" then set item 2 of target to my calculateExtraTime(someTime, specialAdjustForWeekends, specialAdjustForOtherDays)
				
				if askForDate then
					-- Prompt for amount of time to add
					set classOfItem to my itemsClass(theItem)
					set displayText to "When would you like the " & dueOrStart & " date of the " & classOfItem & " " & quote & (name of theItem) & quote & " to be? You can use relative (i.e., \"3d 2pm\"), absolute (i.e., \"Jan 19 15:00\"), or the short date format from your \"Language and Text\" preferences (i.e., \"13.01.19\" or \"01-19\") dates in your input."
					try
						set inputDate to text returned of (display dialog displayText default answer "1d 12am")
					on error errorText number errorNumber
						my die("")
					end try
					
					-- Add back current date to get base date
					set inputToTime to my calculateExtraTime(inputDate, specialAdjustForWeekends, specialAdjustForOtherDays)
					set now to (current date)
					set time of now to 0
					set item 1 of target to (now + inputToTime)
					
				else if relativeToProject then
					-- Doesn't work for projects
					if class of theItem is project then return false
					
					set projectRelativeDate to missing value
					if dueOrStart is "start" then
						set projectRelativeDate to defer date of containing project of theItem
					else
						set projectRelativeDate to due date of containing project of theItem
					end if
					
					-- No associated date
					if projectRelativeDate is missing value then return false
					
					-- Otherwise, store as the base date
					set item 1 of target to projectRelativeDate
					
				else if dateVariable then
					-- Set the base date to the (already dateified) replacement for the dateVariable
					set item 1 of target to (item dateVariablePosition of theReplacements)
					
				else
					-- No base date, set it as today
					set now to (current date)
					set time of now to 0
					set item 1 of target to now
					set plusOrMinus to "plus"
					
				end if
				
				log (name of theItem) & ":"
				log target
				
				set base to item 1 of target
				
				if (plusOrMinus is null) and (item 2 of target > 0) then set plusOrMinus to "plus"
				
				-- Final target date
				if plusOrMinus is "plus" then
					set target to base + (item 2 of target)
				else if plusOrMinus is "minus" then
					set target to base - (item 2 of target)
				else
					set target to base
				end if
				
				-- Set the date
				if dueOrStart is "start" or dueOrStart is "defer" then
					set defer date of theItem to target
				else
					set due date of theItem to target
				end if
				
				return true
			end if
			
			-- set desiredDate to my adjustForSpecialAndWeekends(desiredDate, specialAdjustForWeekends, specialAdjustForOtherDays)
			
			-- TODO: Warn when due/ start dates don't work with project
			
			-- return {desiredDate, dueOrStart, theNote}
			
		end tell
	end tell
end checkingForDateInformation


on calculateExtraTime(str, specialAdjustForWeekends, specialAdjustForOtherDays)
	tell application "OmniFocus"
		tell default document
			
			set str to my findReplace(str, ":", "")
			
			-- Make a helper task with target date
			set helperTask to first item of (parse tasks into it with transport text ("Template Helper #" & str & "#1d"))
			try
				set deferredDate to (defer date of helperTask) as date
			on error
				delete helperTask
				return 0
			end try
			
			delete helperTask
			
			log deferredDate
			
			if deferredDate is missing value then return 0
			
			-- Subtract the current time
			set now to (current date)
			set time of now to 0
			return deferredDate - now
		end tell
	end tell
end calculateExtraTime







--        ___          ___                                ___
--       /__/\        /  /\         ___     _____        /  /\
--      |  |::\      /  /::\       /__/|   /  /::\      /  /:/_
--      |  |:|:\    /  /:/\:\     |  |:|  /  /:/\:\    /  /:/ /\
--    __|__|:|\:\  /  /:/~/::\    |  |:| /  /:/~/::\  /  /:/ /:/_
--   /__/::::| \:\/__/:/ /:/\:\ __|__|:|/__/:/ /:/\:|/__/:/ /:/ /\
--   \  \:\~~\__\/\  \:\/:/__\//__/::::\\  \:\/:/~/:/\  \:\/:/ /:/
--    \  \:\       \  \::/        ~\~~\:\\  \::/ /:/  \  \::/ /:/
--     \  \:\       \  \:\          \  \:\\  \:\/:/    \  \:\/:/
--      \  \:\       \  \:\          \__\/ \  \::/      \  \::/
--       \__\/        \__\/                 \__\/        \__\/

-- Controller for doing the conditional checks.
-- Supports <=, >=, <, >, == and !=
on conditionalCheck(theTask)
	-- State variables
	set theOperation to ""
	set theFunction to ""
	set condition to false
	
	-- Delimiters
	set operationDelimiters to {"@if ", " then ", " delete", " complete", "delete", "complete"}
	set conditionalDelimiters to {" && ", "&& ", " &&", "&&", " || ", "|| ", " ||", "||"}
	set combinators to {"and", "or"}
	
	tell application "OmniFocus"
		tell default document
			copy (note of theTask) to theNote
			
			-- Check if a conditional exists
			set paraWithConditional to null
			repeat with i from 1 to (count of paragraphs of theNote)
				if ((paragraph i of theNote) as string) starts with "@if" then
					set paraWithConditional to i
					set theNote to (paragraph i of theNote) as string
					exit repeat
				end if
			end repeat
			
			-- No conditionals found
			if paraWithConditional is null then return false
			
			-- Figure out which connector exists
			set connector to "OR"
			if theNote contains "&&" then set connector to "AND"
			
			-- Get the operation
			set theOperation to my determineOperation(theNote)
			
			-- Get the note without the commands
			set theNote to (my cleanTextPiecesWithDelimiters(theNote, operationDelimiters)) as string
			
			-- Get the discrete comparisons
			set theComparisons to my cleanTextPiecesWithDelimiters(theNote, conditionalDelimiters)
			set theResults to {}
			
			-- Do all comparisons
			repeat with theCompare in theComparisons
				set the end of theResults to my evaluateComparison(theCompare)
			end repeat
			
			-- Cleanup the note
			my killParagraphStartingWithString(theTask, paraWithConditional)
			
			-- Check if conditional evaluates to true overall
			if ((connector is "OR") and (theResults contains true)) or ((connector is "AND") and (theResults does not contain false)) then
				return theOperation
			else
				return false
			end if
		end tell
	end tell
end conditionalCheck

-- Evaluate a single comparison in string form
on evaluateComparison(comparison)
	set functionDelimiters to {" <= ", "<= ", " <=", "<=", " ² ", "² ", " ²", "²", " >= ", ">= ", " >=", ">=", " ³ ", "³ ", " ³", "³", " == ", "== ", " ==", "==", " != ", "!= ", " !=", "!=", " > ", "> ", " >", ">", " < ", "< ", " <", "<"}
	
	-- Figure out which function is being evaluated
	set theFunction to determineComparison(comparison)
	
	-- Get the pieces of the comparison
	set comparePieces to my cleanTextPiecesWithDelimiters(comparison, functionDelimiters & {quote})
	if length of comparePieces is not 2 then return false
	
	-- Get the variables being compared
	set var1 to item 1 of comparePieces
	set var2 to item 2 of comparePieces
	
	-- Try to convert them to numbers
	try
		set var1 to var1 as real
		set var2 to var2 as real
	end try
	
	-- Default to false
	set condition to false
	
	-- Evaluate the comparison
	try
		if (theFunction is ">=") and (var1 ≥ var2) then
			set condition to true
		else if (theFunction is "<=") and (var1 ≤ var2) then
			set condition to true
		else if (theFunction is ">") and (var1 > var2) then
			set condition to true
		else if (theFunction is "<") and (var1 < var2) then
			set condition to true
		else if (class of var1 is real) and (class of var2 is real) then
			if ((var1 is var2 and theFunction is "==") or (var1 is not var2 and theFunction is "!=")) then
				set condition to true
			end if
		else if ((((var1 contains var2) or (var2 contains var1)) and (length of var1 is length of var2) and (theFunction is "==")) or ((var1 is not var2) and (theFunction is "!="))) then
			set condition to true
		end if
	end try
	
	return condition
end evaluateComparison

-- Determine what operation is being performed
on determineOperation(theNote)
	if theNote contains "delete" then return "delete"
	if theNote contains "complete" then return "complete"
end determineOperation

-- Determine what comparison is being performed
on determineComparison(theNote)
	if theNote contains "<=" then return "<="
	if theNote contains ">=" then return ">="
	if theNote contains "==" then return "=="
	if theNote contains "!=" then return "!="
	if theNote contains "<" then return "<"
	if theNote contains ">" then return ">"
end determineComparison











on workingTheContext(theContext, theVariables, theReplacements)
	tell application "OmniFocus"
		tell default document
			if theContext is missing value then
				-- Prevent against doing work on non-existent contexts
				return null
			else
				-- Copy context name to compare against the replaced version
				copy (name of theContext) as string to originalContextName
				copy originalContextName to desiredContextName
				
				-- Do required replacements
				set desiredContextName to my replaceVariables(desiredContextName, theVariables, theReplacements)
				
				-- If they are the same, bail out
				if (originalContextName as string) is equal to (desiredContextName as string) then return null
				
				-- Otherwise, check to see if there is already a context with that name
				if (class of (container of theContext) is document) then
					set contextsInFolder to every context of it
				else
					set contextsInFolder to every context in (container of theContext)
				end if
				
				-- Check to see if context is in the possible contexts
				set contextFound to null
				repeat with possibleContext in contextsInFolder
					if name of possibleContext is desiredContextName then
						set contextFound to possibleContext
						exit repeat
					end if
				end repeat
				
				if contextFound is not null then
					-- If found, return it
					return contextFound
				else
					-- Otherwise, make a new context and return it
					set theContainer to the container of theContext
					set newContext to make new context at the end of contexts of theContainer with properties {name:desiredContextName}
					return newContext
				end if
			end if
		end tell
	end tell
end workingTheContext








--       _____         ___                   ___          ___
--      /  /::\       /  /\         ___     /  /\        /  /\
--     /  /:/\:\     /  /::\       /  /\   /  /:/_      /  /:/_
--    /  /:/  \:\   /  /:/\:\     /  /:/  /  /:/ /\    /  /:/ /\
--   /__/:/ \__\:| /  /:/~/::\   /  /:/  /  /:/ /:/_  /  /:/ /::\
--   \  \:\ /  /://__/:/ /:/\:\ /  /::\ /__/:/ /:/ /\/__/:/ /:/\:\
--    \  \:\  /:/ \  \:\/:/__\//__/:/\:\\  \:\/:/ /:/\  \:\/:/~/:/
--     \  \:\/:/   \  \::/     \__\/  \:\\  \::/ /:/  \  \::/ /:/
--      \  \::/     \  \:\          \  \:\\  \:\/:/    \__\/ /:/
--       \__\/       \  \:\          \__\/ \  \::/       /__/:/
--                    \__\/                 \__\/        \__\/

-- Creates a date string based on the custom date style property
on customDateStyle(theDate)
	set storeDelimiters to my text item delimiters
	set my text item delimiters to ""
	copy dateFormat to returnDate
	
	set yearFormat to "YYYY"
	set monthFormat to "MMMM"
	set dayFormat to "D"
	
	set theMonth to month of theDate
	set theDay to day of theDate as text
	set theYear to year of theDate as text
	set theWeekday to weekday of theDate as text
	
	if dateFormat contains "YYYY" then
		set yearFormat to "YYYY"
	else
		set yearFormat to "YY"
		set theYear to characters -2 thru -1 of (theYear) as text
	end if
	
	if dateFormat contains "DD" then
		set dayFormat to "DD"
		if length of theDay is 1 then set theDay to "0" & theDay
	else
		set dayFormat to "D"
	end if
	
	if dateFormat contains "MMMM" then
		set monthFormat to "MMMM"
		set theMonth to theMonth as text
	else if dateFormat contains "MMM" then
		set monthFormat to "MMM"
		set theMonth to characters 1 thru 3 of (theMonth as text) as text
	else if dateFormat contains "MM" then
		set monthFormat to "MM"
		set theMonth to (theMonth as integer) as text
		if length of theMonth is 1 then set theMonth to "0" & theMonth
	else
		set monthFormat to "M"
		set theMonth to (theMonth as integer) as text
	end if
	
	set returnDate to findReplace(returnDate, yearFormat, theYear)
	set returnDate to findReplace(returnDate, monthFormat, theMonth)
	set returnDate to findReplace(returnDate, dayFormat, theDay)
	set returnDate to findReplace(returnDate, "W", theWeekday)
	
	set my text item delimiters to storeDelimiters
	return returnDate
end customDateStyle
