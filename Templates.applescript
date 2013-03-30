(*
	# DESCRIPTION
	
	This script looks for a Template folder and asks you to pick one of the templates within to create 
	an instance of. It then allows you to select a folder for the instance and to choose the desired values
	for any variables designated in the last paragraph of the project's note (by default, "$" before a word
	designates it as a variable, an ode to my favorite CSS preprocessor, SASS).
	
	Some other goodies:
		-	You can specify relative start or due dates (one or the other, not both… yet) for the project
			and/or each task individually. To do so, put a paragraph somewhere in the note of that item that
			starts with either "Due" or "Start". Then use the same natural language date syntax as you can usually
			use in OmniFocus/ my "Later" Applescript: things like "today + 2d", "2d", "3w 4d 2pm", etc., will all
			work as expected, hopefully. All of these will be relative to the date you run the script.
		-	Variables can be used in project names and notes, task names and notes, and task context names
		-	On the first run it detects if you have projects using Curt Clifton's OmniFocus template syntax
			(to which I owe a lot of the good ideas in this script) and offers to change it for you.
		-	It offers to show you the new instance of the template once it has populated the instance.
		-	Automagically changes the new project instance to "Active" if the template project was "On Hold"
	
	
	# LICENSE
	
	Use it, change it, enjoy it. Please don't blatently pass off my work as your own. Be cool.
	
	
	# INSTALLATION
	
	-	Copy this script to ~/Library/Scripts/Applications/Omnifocus (you may have to use the
		Go > Go to Folder… menu in your file navigation application of choice as the user library
		folder is hidden on Mac OS X 10.7+. After you select this menu item, type the path above and
		hit enter).
	-	If you prefer, you can have this script be activated by a utility like Keyboard Maestro or FastScripts
	
	
	# VERSION INFORMATION
		
		0.3.6 (March 27, 2013): Bugfixes. You can also now specify a specific folder path as the default folder using > for a subfolder 
		(i.e., ">>>Folder > Subfolder" will put the new instance in Subfolder under Folder).
		0.3.5 (March 18, 2013): Added the ability to set dates in the format specified in as the short date format
		in your Languages and Text preference pane.
		0.3.1 (February 28, 2013): Bugfixes.
		0.3.0 (February 24, 2013): Fixed an issue with subtracting dates. Improved Growl alerts. Added an option to put "attachment: ask" in
		the task notes to have the script ask you for an attachment to that task. Variables can now be given a list of values to choose from
		using the notation $variableName {option 1, option 2, option3} in the project note. If you use the variable "$today", the
		variable will automatically be assigned the date you create the new instance. Added a screencast, readme, and website.
		0.2.9 (February 13, 2013): Preserves non-embedded attachments to tasks
		0.2.8 (February 13, 2013): Fixed the compile-time option of putting the project at the beginning of the list.
		Changed notifications over to Growl. You can also have the script ask if a certain task should be completed or
		not by putting "complete: ask" anywhere in its note.
		0.2.7 (February 11, 2013): Fixed an issue where the template wouldn't instantiate properly if there were no variables.
		Added a compile-time option to put the project at the beginning of the project list
		0.2.6 (February 7, 2013): Now works with template folders that are dropped.
		0.2.5 (January 30, 2013): New "$date" variables — will ask you for a date instead of a string (you can use all of the
		same relative/ absolute shorthand forms in defining the date, and it can be used in conjunction with the "start" / 
		"due" identifiers)
		0.2.4 (January 22, 2013): Other bugfixes
		0.2.3 (January 22, 2013): Fix for setting default folder to a subfolder
		0.2.2 (January 22, 2013): Allows you to set both a start and due date. Fixes a bug where due/ start declarations
		in projects wouldn't be eliminated when a new instance was created.
		0.2.1 (January 22, 2013): Does a better job of cleaning up notes and allows variables on any line of project
		0.2 (January 21, 2013): using the keyword "ask" in after the start/due declaration in the note of a task/ project will have the
		script prompt you to enter a relative or absolute start/due date for that item. Similarly, you can use the keyword
		"project" to set the start/ due date relative to that of the project; the script will take whatever is
		after the keyword and subtract it from the due date/ add it to the start date of the project, as the
		case may be. Finally, using the (by default) ">>>" operator in the second, followed by a string that EXACTLY matches
		one of the folders in your OF library will skip the folder selection dialog and put the new instance
		directly in the designated folder. Plus, fancy icon.
		0.1.1 (January 18, 2013): Handles projects in a template folder without variables more gracefully (thanks, Sven!)
		0.1 (January 18, 2013): Initial release
		
	
	# BEING WORKED ON
	
	-	Nothing
	
	
	# KNOWN ISSUES

	- 	Nothing
*)

property startOrEndOfFolder : "end" -- change to "end" to put the new project at the end of the selected folder
property variableSymbol : "$" -- change to whatever delimiter you want to denote your variables
property defaultFolderPointer : ">>>" -- change to whatever delimtier you want to denote a default folder pointer
property optionListStartDelimiter : "{" -- start of a list of options for the preceeding variable
property optionListEndDelimiter : "}" -- end of a list of options for the preceeding variable

-- Don't change these
property firstRun : true
property specialTemplateFolder : null

-- Growl variables, don't change these either
property applicationName : "Templates.scpt"
property scriptStartNotify : "Script Started"
property scriptEndNotify : "Script Ended"
property dateNotify : "Date Mismatch"
property allNotifications : {scriptStartNotify, scriptEndNotify, dateNotify}
property defaultNotifications : allNotifications
property iconApplication : "OmniFocus.app"

property checkingSomething : ""

tell application "OmniFocus"
	tell default document
		if firstRun then
			set otherTemplateScriptProjects to my checkForOtherTemplate()
			if otherTemplateScriptProjects is -1 then return
			if length of otherTemplateScriptProjects is not 0 then
				set changeOldTemplates to button returned of (display dialog "It appears that you have some projects using Curt Clifton's OmniFocus template script syntax. Would you like to automatically adjust these to use this script's syntax?" buttons {"No, Thanks", "Yes, Change Syntax"} default button 2)
				if changeOldTemplates is "Yes, Change Syntax" then my adjustOldTemplateSyntax(otherTemplateScriptProjects)
			end if
			
			try
				set variableSymbol to text returned of (display dialog "What symbol would you like to use to designate variable names in your templates?" default answer "$")
			on error errorText number errorNumber
				if errorNumber is -128 then
					return
				end if
			end try
			
			set firstRun to false
		end if
		
		set theCount to (count of (every flattened folder where (its name contains "Template")))
		if ((count of (every flattened folder where (its name contains "Template"))) is 0) then
			set templateFolderList to every flattened folder where (its hidden is false)
			set templateFolderNameList to {}
			repeat with theFolder in templateFolderList
				set nextListItem to ""
				if the class of theFolder's container is folder then set nextListItem to "↳ "
				set nextListItem to nextListItem & (name of theFolder)
				set the end of templateFolderNameList to nextListItem
			end repeat
			set selectedTemplateFolder to choose from list templateFolderNameList with title "Choose Template Folder" with prompt "No obvious template folders were found. Please select the folder in which you store templates." OK button name "Set as Template Folder"
			if selectedTemplateFolder is false then return
			set templateFolderPosition to my selectionPositions(selectedTemplateFolder, templateFolderNameList, false)
			set specialTemplateFolder to item templateFolderPosition of templateFolderList
		else
			set specialTemplateFolder to null
		end if
		
		if specialTemplateFolder is null then
			set projectList to every flattened project where (name of its folder contains "Template") and (its status is not dropped) and (its status is not done)
		else
			set projectList to every flattened project where (its folder is specialTemplateFolder) and (its status is not dropped) and (its status is not done)
		end if
		set projectNameList to {}
		repeat with theProject in projectList
			set the end of projectNameList to the name of theProject
		end repeat
		if length of projectNameList is 0 then
			display alert "No projects in a \"Template\" folder were found. Make sure that the folder name contains the word \"Template\" so that it can be found."
			return
		end if
		
		set chooseListTitle to "Select a Template Project"
		set chooseListText to "Which one of your template projects would you like to make a new instance of?"
		set chooseListOK to "Select This Project"
		set selectedProject to choose from list projectNameList with title chooseListTitle with prompt chooseListText OK button name chooseListOK
		if selectedProject is false then return
		set projectPosition to my selectionPositions(selectedProject, projectNameList, false)
		set selectedProjectTemplate to item projectPosition of projectList
		
		set defaultFolderFound to false
		if the note of selectedProjectTemplate contains defaultFolderPointer then
			set paraWithPointer to 1
			repeat with i from (count of paragraphs in the note of selectedProjectTemplate) to 1 by -1
				if (paragraph i of the note of selectedProjectTemplate starts with defaultFolderPointer) then set paraWithPointer to i
			end repeat
			set folderPointer to paragraph paraWithPointer of the note of selectedProjectTemplate
			set my text item delimiters to {">>> ", ">>>", " > ", " >", "> ", ">"}
			set newFolderText to every text item of folderPointer
			set my text item delimiters to ""
			set cleanedFolderText to {}
			repeat with i from 1 to length of newFolderText
				if item i of newFolderText is not "" then
					set the end of cleanedFolderText to (paragraph 1 of (item i of newFolderText as string))
				end if
			end repeat
			try
				if length of cleanedFolderText is 1 then
					set selectedFolderTemplate to first flattened folder whose (name is item 1 of cleanedFolderText)
				else
					set theFolder to every flattened folder where (its name is item -1 of cleanedFolderText)
					repeat with i from 1 to length of theFolder
						set containFolder to container of item i of theFolder
						if name of containFolder is (item -2 of cleanedFolderText) then
							set selectedFolderTemplate to item i of theFolder
							exit repeat
						end if
					end repeat
				end if
				set defaultFolderFound to true
			end try
		end if
		
		set theVariables to item 1 of my findTheVariables(selectedProjectTemplate)
		set theListVariableOptions to item 2 of my findTheVariables(selectedProjectTemplate)
		
		set justDuplicate to ""
		if the length of theVariables is 0 then
			set justDuplicate to button returned of (display alert "No variables were found in the selected project. Do you want to simply copy this project to the selected folder? (Make sure that any variables are all in one paragraph in the project's note and are in the format: " & quote & variableSymbol & "variableName" & quote & ")." buttons {"No, Nevermind", "Yes, Duplicate"} default button 2)
			if justDuplicate is not "Yes, Duplicate" then return
		end if
		
		if not defaultFolderFound then
			set folderList to every flattened folder where (its name does not contain "Template") and (its effectively hidden is false)
			set folderNameList to {"(Top Level)"}
			repeat with theFolder in folderList
				set nextListItem to ""
				if the class of theFolder's container is folder then set nextListItem to "↳ "
				set nextListItem to nextListItem & (name of theFolder)
				set the end of folderNameList to nextListItem
			end repeat
			
			set chooseListTitle to "Select a Folder For The New Template Instance"
			set chooseListText to "In which folder would you like to create a new instance of this template?"
			set chooseListOK to "Make Template Instance"
			set selectedFolder to choose from list folderNameList with title chooseListTitle with prompt chooseListText OK button name chooseListOK
			if selectedFolder is false then
				return
			else if selectedFolder is {"(Top Level)"} then
				set selectedFolderTemplate to "Top Level"
			else
				set folderPosition to ((my selectionPositions(selectedFolder, folderNameList, false)) - 1)
				set selectedFolderTemplate to item folderPosition of folderList
			end if
		end if
		
		if justDuplicate is "Yes, Duplicate" then
			if selectedFolderTemplate is "Top Level" then
				if startOrEndOfFolder is "start" then
					set newProjectInstance to (duplicate selectedProjectTemplate to the front of projects of it)
				else
					set newProjectInstance to (duplicate selectedProjectTemplate to the end of projects of it)
				end if
			else
				if startOrEndOfFolder is "start" then
					set newProjectInstance to (duplicate selectedProjectTemplate to the front of projects of selectedFolderTemplate)
				else
					set newProjectInstance to (duplicate selectedProjectTemplate to the end of projects of selectedFolderTemplate)
				end if
			end if
			my notify("Creating New Template Instance", "More input may be needed…", scriptStartNotify, "")
			my populateTemplate(newProjectInstance, {}, {})
			if (status of newProjectInstance is on hold) or (status of newProjectInstance is dropped) then set status of newProjectInstance to active
			set theURL to "omnifocus:///task/" & (id of newProjectInstance)
			my notify("Template Instance Created", "Click here to see the new project instance.", scriptEndNotify, theURL)
			set justDuplicate to ""
			try
				synchronize
			end try
			return
		end if
		my notify("Creating New Template Instance", "More input may be needed…", scriptStartNotify, "")
		set theReplacements to my findTheReplacements(theVariables, theListVariableOptions)
		if the result is false then return
		
		if selectedFolderTemplate is "Top Level" then
			if startOrEndOfFolder is "start" then
				set newProjectInstance to (duplicate selectedProjectTemplate to the front of projects of it)
			else
				set newProjectInstance to (duplicate selectedProjectTemplate to the end of projects of it)
			end if
		else
			if startOrEndOfFolder is "start" then
				set newProjectInstance to (duplicate selectedProjectTemplate to the front of projects of selectedFolderTemplate)
			else
				set newProjectInstance to (duplicate selectedProjectTemplate to the end of projects of selectedFolderTemplate)
			end if
		end if
		if status of newProjectInstance is on hold then set status of newProjectInstance to active
		if defaultFolderFound then
			copy the note of newProjectInstance to tempNote
			repeat with i from (count of paragraphs in the note of selectedProjectTemplate) to 1 by -1
				if paragraph i of tempNote starts with defaultFolderPointer then set paraWithPointer to i
				exit repeat
			end repeat
			set my text item delimiters to {return}
			if paraWithPointer is 1 then
				set the newNote to paragraphs 2 thru -1 of tempNote as string
			else if paraWithPointer is (count of paragraphs of note of selectedProjectTemplate) then
				set the newNote to paragraphs 1 thru -2 of tempNote as string
			else
				set the newNote to ((paragraphs 1 thru (paraWithPointer - 1) of tempNote) & (paragraphs (paraWithPointer + 1) thru -1 of tempNote)) as string
			end if
			set my text item delimiters to ""
			set the note of newProjectInstance to newNote
		end if
		
		set theAttachments to my populateTemplate(newProjectInstance, theVariables, theReplacements)
		
		set theURL to "omnifocus:///task/" & (id of newProjectInstance)
		my notify("Script ended", "Click here to see the new project instance.", scriptEndNotify, theURL)
		try
			synchronize
		end try
	end tell
end tell


on selectionPositions(selectList, originalList, multipleSelections)
	if multipleSelections then
		set choicesFound to 0
		set positionOfSelections to {}
		set j to 1
		repeat until (j > (length of originalList)) or (choicesFound = (length of selectList))
			set k to 1
			set aChoiceFound to false
			repeat until (k > (length of selectList)) or aChoiceFound
				if (item k of selectList) contains (item j of originalList) then
					set end of positionOfSelections to j
					set aChoiceFound to true
					set choicesFound to (choicesFound + 1)
				end if
				set k to k + 1
			end repeat
			set j to j + 1
		end repeat
	else
		set j to 1
		set positionOfSelections to null
		repeat until (j > (length of originalList) or (positionOfSelections is not null))
			set k to 1
			repeat until ((k > (length of selectList)) or (positionOfSelections is not null))
				if (item k of selectList) contains (item j of originalList) then
					set positionOfSelections to j
				end if
				set k to k + 1
			end repeat
			set j to j + 1
		end repeat
	end if
	return positionOfSelections
end selectionPositions


on populateTemplate(theProject, cleanedVariables, theReplacements)
	set delimCleanedVariables to {}
	repeat with i from 1 to (length of cleanedVariables)
		set the end of delimCleanedVariables to (variableSymbol & (item i of cleanedVariables))
	end repeat
	tell application "OmniFocus"
		tell default document
			tell theProject
				set theAttachmentList to my attachmentList(id of it, class of it as string)
				if length of cleanedVariables > 0 then
					set its name to my replaceVariables(its name, delimCleanedVariables, theReplacements)
				end if
				set possibleDateChange to {""}
				repeat while item 1 of possibleDateChange is not missing value
					set possibleDateChange to my checkingForDateInformation(it, delimCleanedVariables, theReplacements)
					if item 1 of possibleDateChange is not missing value then
						if item 2 of possibleDateChange is "Start" then
							set its start date to item 1 of possibleDateChange
						else
							set its due date to item 1 of possibleDateChange
						end if
						set its note to item 3 of possibleDateChange
					else if the length of possibleDateChange is 2 then
						set its note to item 2 of possibleDateChange
					end if
				end repeat
				if length of cleanedVariables > 0 then
					set theFullNote to its note
					set theNewNote to my eliminateVariables(theFullNote)
					set its note to my replaceVariables(theNewNote, delimCleanedVariables, theReplacements)
				end if
				set attachmentRequest to false
				if its note contains "attachment: ask" or its note contains "attachment:ask" then
					set attachmentRequest to true
					set its note to my replaceVariables(its note, {"attachment:ask", "attachment: ask"}, {"", ""})
				end if
				set its note to my cleanExcessBreaks(its note)
				if attachmentRequest then
					try
						set theAttachFilePathAlias to (choose file with prompt "You indicated you would like to attach a file to the project \"" & name of it & "\". Please select the file to attach.") as rich text
						tell its note
							make new file attachment with properties {file name:theAttachFilePathAlias, embedded:false}
						end tell
					end try
				end if
				tell its note
					repeat with theAttachment in theAttachmentList
						make new file attachment with properties {file name:theAttachment, embedded:false}
					end repeat
				end tell
				set attachmentRequest to false
				
				-- Going through the tasks
				repeat with i from 1 to (count of flattened tasks in it)
					tell flattened task i
						set theAttachmentList to my attachmentList(id of it, class of it as string)
						if length of cleanedVariables > 0 then
							set its name to my replaceVariables(its name, delimCleanedVariables, theReplacements)
						end if
						set completeTheTask to false
						if its note contains "complete:ask" or its note contains "complete: ask" then
							set completeTheTask to (button returned of (display dialog "In the note, you indicated that you wanted to be asked whether to complete the task \"" & (name of it) & "\" when you create a new instance of this project. Would you like to complete this task?" buttons {"Yes, Complete", "No, Leave Incomplete"} default button 2) is "Yes, Complete")
						end if
						if completeTheTask then
							set its completed to true
						else
							set its note to my replaceVariables(its note, {"complete:ask", "complete: ask"}, {"", ""})
							set possibleDateChange to {""}
							repeat while item 1 of possibleDateChange is not missing value
								set possibleDateChange to my checkingForDateInformation(it, delimCleanedVariables, theReplacements)
								if item 1 of possibleDateChange is not missing value then
									if item 2 of possibleDateChange is "Start" then
										set its start date to item 1 of possibleDateChange
									else
										set its due date to item 1 of possibleDateChange
									end if
									set its note to item 3 of possibleDateChange
								else if the length of possibleDateChange is 2 then
									set its note to item 2 of possibleDateChange
								end if
							end repeat
							if length of cleanedVariables > 0 then
								set its note to my replaceVariables(its note, delimCleanedVariables, theReplacements)
								if its context is not missing value then
									set its context to my workingTheContext(its context, delimCleanedVariables, theReplacements)
								end if
							end if
							set attachmentRequest to false
							if its note contains "attachment: ask" or its note contains "attachment:ask" then
								set attachmentRequest to true
								set its note to my replaceVariables(its note, {"attachment:ask", "attachment: ask"}, {"", ""})
							end if
							set its note to my cleanExcessBreaks(its note)
							if attachmentRequest then
								try
									set theAttachFilePathAlias to (choose file with prompt "You indicated you would like to attach a file to the task \"" & name of it & "\". Please select the file to attach.") as rich text
									
									tell its note
										make new file attachment with properties {file name:theAttachFilePathAlias, embedded:false}
									end tell
								end try
							end if
							tell its note
								repeat with theAttachment in theAttachmentList
									make new file attachment with properties {file name:theAttachment, embedded:false}
								end repeat
							end tell
							set attachmentRequest to false
						end if
						set completeTheTask to false
					end tell
				end repeat
				return theAttachmentList
			end tell
		end tell
	end tell
end populateTemplate


on replaceVariables(theText, theVariables, theReplacements)
	if length of theVariables is 0 then return theText
	repeat with i from 1 to (length of theVariables)
		set my text item delimiters to (item i of theVariables)
		set theText to every text item of theText
		if class of (item i of theReplacements) is date then
			set my text item delimiters to (date string of (item i of theReplacements)) as text
		else
			set my text item delimiters to (item i of theReplacements)
		end if
		set theText to theText as string
		set my text item delimiters to {}
	end repeat
	return theText
end replaceVariables


on eliminateVariables(theNote)
	if (count of paragraphs of theNote) is 1 then
		return ""
	else
		repeat with i from (count of paragraphs of theNote) to 1 by -1
			if paragraph i of theNote starts with variableSymbol then
				set variablePosition to i
				exit repeat
			end if
		end repeat
		set my text item delimiters to {return}
		if variablePosition is (count of the paragraphs of theNote) then
			set returnNote to ((paragraphs 1 thru -2) of theNote) as text
		else if variablePosition is 1 then
			set returnNote to ((paragraphs 2 thru -1 of theNote)) as text
		else
			set returnNote to ((paragraphs 1 thru (variablePosition - 1) of theNote) & (paragraphs (variablePosition + 1) thru -1 of theNote)) as text
		end if
		set my text item delimiters to ""
		return returnNote
	end if
end eliminateVariables


on workingTheContext(theContext, theVariables, theReplacements)
	tell application "OmniFocus"
		if theContext is missing value then
			return
		else
			set i to 1
			set variableFound to false
			repeat while (i ≤ (length of theVariables)) and (not variableFound)
				if (name of theContext contains (item i of theVariables)) then set variableFound to true
				set i to i + 1
			end repeat
			if not variableFound then
				return theContext
			else
				set desiredContextName to my replaceVariables(name of theContext, theVariables, theReplacements)
				if (class of (container of theContext) is document) then
					set contextsInFolder to every context of default document
				else
					set contextsInFolder to every context in (container of theContext)
				end if
				
				set positionOfFound to null
				set namesOfContextsInFolder to {}
				repeat with i from 1 to (length of contextsInFolder)
					set end of namesOfContextsInFolder to name of (item i of contextsInFolder)
					if (item i of namesOfContextsInFolder) is desiredContextName then set positionOfFound to i
				end repeat
				
				if positionOfFound is not null then
					return (item positionOfFound of contextsInFolder)
				else
					set theContainer to the container of theContext
					tell theContainer
						set newContext to make new context at the end of contexts of it with properties {name:desiredContextName}
					end tell
					return newContext
				end if
			end if
		end if
	end tell
end workingTheContext


on findTheVariables(theProject)
	tell application "OmniFocus"
		tell default document
			set theFullNote to note of theProject
			if theFullNote is missing value then return {{}, {}}
			set theNote to null
			repeat with i from (count of paragraphs of theFullNote) to 1 by -1
				if paragraph i of theFullNote starts with variableSymbol then
					set theNote to paragraph i of theFullNote
					exit repeat
				end if
			end repeat
			if theNote is null then return {{}, {}}
			set cleanedVariables to {}
			set my text item delimiters to {" " & variableSymbol, variableSymbol}
			set theVariables to every text item of theNote
			
			repeat with theVar from 1 to (length of theVariables)
				if item theVar of theVariables is not "" then
					set the end of cleanedVariables to item theVar of theVariables
				end if
			end repeat
			
			set optionLists to {}
			repeat with i from 1 to length of cleanedVariables
				if (item i of cleanedVariables contains optionListStartDelimiter) and (item i of cleanedVariables contains optionListEndDelimiter) then
					set my text item delimiters to {space & optionListStartDelimiter & space, space & optionListEndDelimiter & space, space & optionListStartDelimiter, space & optionListEndDelimiter, optionListStartDelimiter, optionListEndDelimiter}
					set theSplit to every text item of (item i of cleanedVariables)
					set (item i of cleanedVariables) to (item 1 of theSplit)
					set newOptionListText to item 2 of theSplit
					set my text item delimiters to {", ", ","}
					set newOptionList to every text item of newOptionListText
					set emptyFound to true
					repeat while emptyFound
						repeat with j from 1 to length of newOptionList
							set emptyFound to false
							if item j of newOptionList is "" then
								if j is 1 then
									set newOptionList to items 2 thru -1 of newOptionList
								else if j is length of newOptionList then
									set newOptionList to items 1 thru -2 of newOptionList
								else
									set newOptionList to (items 1 thru (j - 1) of newOptionList) & (items (j + 1) thru -1 of newOptionList)
								end if
								set emptyFound to true
								exit repeat
							end if
						end repeat
					end repeat
					set end of optionLists to newOptionList
				else
					set end of optionLists to {}
				end if
			end repeat
			set my text item delimiters to {}
			
		end tell
	end tell
	return {cleanedVariables, optionLists}
end findTheVariables


on findTheReplacements(theVariables, optionLists)
	tell application "OmniFocus"
		tell default document
			set theReplacements to {}
			set theTitle to "Select Replacements for Variables"
			repeat with i from 1 to (length of theVariables)
				if item i of theVariables contains "today" then
					set the end of theReplacements to (current date)
				else if item i of theVariables starts with "date" then
					set theText to "What date would you like to use for the date variable " & quote & (item i of theVariables) & quote & "? You can use an absolute or relative date."
				else if item i of optionLists is not {} then
					set theText to "Which of the following options would you like to assign to the variable \"" & (item i of theVariables) & "\"?"
				else
					set theText to "What would you like to replace " & quote & (item i of theVariables) & quote & " with?"
				end if
				if item i of theVariables does not contain "today" then
					try
						if item i of optionLists is {} then
							set theReturnInput to text returned of (display dialog theText default answer "")
							if item i of theVariables starts with "date" then
								set theReturnInput to my englishTime(theReturnInput)
								set theCurrentDate to (current date)
								set time of theCurrentDate to 0
								set theReturnInput to theCurrentDate + theReturnInput
							end if
							set the end of theReplacements to theReturnInput
						else
							set the end of theReplacements to (choose from list (item i of optionLists) with prompt theText) as string
						end if
					on error errorText number errorNumber
						if errorNumber is -128 then
							return false
						end if
					end try
				end if
			end repeat
		end tell
	end tell
	return theReplacements
end findTheReplacements


on cleanExcessBreaks(theText)
	if theText is missing value then return missing value
	if theText is "" then return ""
	if (count of paragraphs of theText) is 1 then return theText
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
	set text item delimiters to {return}
	set theNewText to paragraphs textStarts thru textEnds of theText as text
	set text item delimiters to ""
	return theNewText
end cleanExcessBreaks


on checkForOtherTemplate()
	tell application "OmniFocus"
		tell default document
			set theCount to (count of (every flattened folder where (its name contains "Template")))
			if (theCount is 0) then
				set templateFolderList to every flattened folder
				set templateFolderNameList to {}
				repeat with theFolder in templateFolderList
					set nextListItem to ""
					if the class of theFolder's container is folder then set nextListItem to "↳ "
					set nextListItem to nextListItem & (name of theFolder)
					set the end of templateFolderNameList to nextListItem
				end repeat
				set selectedTemplateFolder to choose from list templateFolderNameList with title "Choose Template Folder(s)" with prompt "No obvious template folders were found. Please select the folder(s) in which you store templates." OK button name "Set as Template Folder" with multiple selections allowed
				if selectedTemplateFolder is false then return -1
				set templateFolderPosition to my selectionPositions(selectedTemplateFolder, templateFolderNameList, true)
				set existingTemplateFolders to {}
				repeat with i from 1 to (length of templateFolderPosition)
					set the end of existingTemplateFolders to item i of templateFolderList
				end repeat
			else
				set existingTemplateFolders to every flattened folder where (its name contains "Template")
			end if
			
			set oldTemplateProjects to {}
			set possibleTemplateProjects to {}
			repeat with i from 1 to (length of existingTemplateFolders)
				set templateFolderIsDropped to (hidden of item i of existingTemplateFolders is true)
				try
					if not templateFolderIsDropped then
						set possibleTemplateProjects to possibleTemplateProjects & (every flattened project where (its container is (item i of existingTemplateFolders)) and (its status is not dropped) and (its status is not done))
					else
						set possibleTemplateProjects to possibleTemplateProjects & (every flattened project where (its container is (item i of existingTemplateFolders)) and (its status is not done))
					end if
				end try
			end repeat
			repeat with i from 1 to (length of possibleTemplateProjects)
				if the note of (item i of possibleTemplateProjects) contains "«" then set the end of oldTemplateProjects to (item i of possibleTemplateProjects)
			end repeat
		end tell
	end tell
	return oldTemplateProjects
end checkForOtherTemplate


on adjustOldTemplateSyntax(oldTemplateProjects)
	tell application "OmniFocus"
		tell default document
			repeat with i from 1 to (length of oldTemplateProjects)
				tell item i of oldTemplateProjects
					set my text item delimiters to "«"
					set tempName to its name
					set tempName to (every text item of tempName)
					set tempNote to its note
					set tempNote to (every text item of tempNote)
					set my text item delimiters to variableSymbol
					set tempName to tempName as string
					set tempNote to tempNote as string
					set my text item delimiters to "»"
					set tempName to (every text item of tempName)
					set tempNote to (every text item of tempNote)
					set my text item delimiters to ""
					set its name to tempName as string
					set its note to tempNote as string
					repeat with i from 1 to (count of flattened tasks in it)
						tell flattened task i
							set my text item delimiters to "«"
							set tempName to its name
							set tempName to (every text item of tempName)
							set tempNote to its note
							set tempNote to (every text item of tempNote)
							set my text item delimiters to variableSymbol
							set tempName to tempName as string
							set tempNote to tempNote as string
							set my text item delimiters to "»"
							set tempName to (every text item of tempName)
							set tempNote to (every text item of tempNote)
							set my text item delimiters to ""
							set its name to tempName as string
							set its note to tempNote as string
						end tell
					end repeat
				end tell
			end repeat
			set my text item delimiters to ""
		end tell
	end tell
end adjustOldTemplateSyntax


on checkingForDateInformation(theItem, theVariables, theReplacements)
	tell application "OmniFocus"
		tell default document
			tell front document window
				tell content
					set theNote to the note of theItem
					copy theNote to theOriginalNote
					
					set dueOrStart to null
					set askForDate to false
					set relativeToProject to false
					set dateVariable to false
					
					set theNoteParagraphs to every paragraph of theNote
					repeat with i from 1 to (length of theNoteParagraphs)
						if (item i of theNoteParagraphs starts with "start:") or (item i of theNoteParagraphs starts with "due:") then
							set theNote to item i of theNoteParagraphs
							exit repeat
						end if
					end repeat
					
					if (theNote starts with "Due") then
						set dueOrStart to "due"
					else if (theNote starts with "Start") then
						set dueOrStart to "start"
					end if
					
					if dueOrStart is null then
						return {missing value}
					else
						if theNote contains "Ask" then set askForDate to true
						if theNote contains "Project" then set relativeToProject to true
						repeat with i from 1 to (length of theVariables)
							if item i of theVariables is in theNote then
								set dateVariable to true
								set dateVariablePosition to i
								exit repeat
							end if
						end repeat
						
						if askForDate then
							set classOfItem to "item"
							if class of theItem is task then
								set classOfItem to "task"
							else if class of theItem is project then
								set classOfItem to "project"
							end if
							set displayText to "When would you like the " & dueOrStart & " date of the " & classOfItem & " " & quote & (name of theItem) & quote & " to be? You can use relative (i.e., \"3d 2pm\"), absolute (i.e., \"Jan 19 15:00\"), or the short date format from your \"Language and Text\" preferences (i.e., \"13.01.19\" or \"01-19\") dates in your input."
							try
								set inputDate to text returned of (display dialog displayText default answer "1d 12am")
							on error errorText number errorNumber
								if errorNumber is -128 then
									return {missing value, my getRidOfDateInfo(theOriginalNote, dueOrStart)}
								end if
							end try
						else
							set possibleDelimiters to {"Due:", "Start:", "Due", "Start", "Project", "today", "at"}
							if dateVariable then set end of possibleDelimiters to (item dateVariablePosition of theVariables) as string
							set my text item delimiters to possibleDelimiters
							copy every text item of theNote to tempDate
							set my text item delimiters to ""
							set inputDate to tempDate as string
						end if
					end if
					
					
					set secondsDeferred to my englishTime(inputDate)
					if secondsDeferred = -1 then return {missing value, my getRidOfDateInfo(theOriginalNote, dueOrStart)}
					if not dateVariable then
						if not relativeToProject then
							set desiredDate to (current date)
							set time of desiredDate to 0
							set desiredDate to desiredDate + secondsDeferred
							
						else
							if class of theItem is project then return {missing value}
							if dueOrStart is "due" then
								set relativeDate to due date of containing project of theItem
								if relativeDate is missing value then
									return {missing value, my getRidOfDateInfo(theOriginalNote, dueOrStart)}
								end if
								set desiredDate to relativeDate + secondsDeferred
							else
								set relativeDate to start date of containing project of theItem
								if relativeDate is missing value then
									set relativeDate to (current date)
									set time of relativeDate to 0
								end if
								set desiredDate to relativeDate + secondsDeferred
							end if
						end if
					else
						set desiredDate to (item dateVariablePosition of theReplacements) + secondsDeferred
					end if
					
					if (class of theItem is not project) then
						if dueOrStart is "Due" and (due date of containing project of theItem is not missing value) then
							if desiredDate < (current date) then
								my notify("Due Date in the Past", "Check task \"" & name of theItem & "\".", dateNotify, "")
							else if desiredDate > due date of containing project of theItem then
								my notify("Due Date After Project Due", "Check task \"" & name of theItem & "\".", dateNotify, "")
							end if
						else if (due date of containing project of theItem is not missing value) then
							if desiredDate > due date of containing project of theItem then
								my notify("Start Date After Project Start", "Check task \"" & name of theItem & "\".", dateNotify, "")
							end if
						end if
					end if
					
					set theNote to my getRidOfDateInfo(theOriginalNote, dueOrStart)
					return {desiredDate, dueOrStart, theNote}
				end tell
			end tell
		end tell
	end tell
end checkingForDateInformation


on englishTime(dateDesired)
	if dateDesired is "0" then return 0
	
	set monthFound to 0
	set weekdayFound to 0
	-- Solves an issue with the treatment of leading zeros for the minutes (i.e., 12:01am)
	set minuteLeadingZero to false
	
	-- Figures out if the user excluded any of the components
	set timeMissing to false
	set daysMissing to false
	set weeksMissing to false
	
	-- Sets up the delimiters for different items
	set timeDelimiters to {"am", "pm", "a", "p", ":"}
	set dayDelimiters to {"days", "day", "d"}
	set weekDelimiters to {"weeks", "week", "w"}
	set monthDelimiters to {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
	set weekdayDelimiters to {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
	set specialRelativeDayDelimiters to {"Today", "Tomorrow", "at"}
	set otherDelimiters to {" ", "th", "st", "rd", "nd"}
	
	set inThe to "unknown"
	set howManyNumbersInputted to 0
	set numList to {}
	
	-- See if they included AM/PM
	if isNumberIdentifier("a", dateDesired) then set inThe to "AM"
	if isNumberIdentifier("p", dateDesired) then set inThe to "PM"
	
	-- See if they gave an absolute date formatted in YY.MM.DD or some other similar format
	set my text item delimiters to specialRelativeDayDelimiters & otherDelimiters & timeDelimiters
	set checkInput to every text item of dateDesired
	set checkInputCleaned to {}
	repeat with i from 1 to (length of checkInput)
		if item i of checkInput is not "" then
			set the end of checkInputCleaned to item i of checkInput
		end if
	end repeat
	try
		set theDateCheck to item 1 of checkInputCleaned
		if (theDateCheck contains ".") or (theDateCheck contains "-") or (theDateCheck contains "/") then
			set todaysDate to (current date)
			set time of todaysDate to 0
			set targetDate to my understandAbsoluteDate(theDateCheck)
			if targetDate = -1 then return -1
			set my text item delimiters to ""
			if length of checkInputCleaned is 1 then
				return (targetDate - todaysDate) as number
			else
				set theTime to items 2 thru -1 of checkInputCleaned
				set numList to {}
				
				set timeStoreLocation to length of theTime
				repeat while timeStoreLocation > 0
					try
						-- If the minutes have a leading zero, just combine them with the hours
						if (numList = {}) and ((item timeStoreLocation of theTime) starts with "0") then
							set the end of numList to ((item (timeStoreLocation - 1) of theTime) & (item timeStoreLocation of theTime)) as number
							set minuteLeadingZero to true
							set timeStoreLocation to timeStoreLocation - 2
						else
							-- Otherwise, get the numbers only
							set tempNum to (item timeStoreLocation of theTime) as number
							if tempNum ≠ 0 then set the end of numList to tempNum
							set timeStoreLocation to timeStoreLocation - 1
						end if
					end try
				end repeat
				
				set theTime to figureOutTheTime(numList, false, true, true, minuteLeadingZero)
				set theTime to understandTheTime(theTime, inThe, false)
				return (targetDate + theTime - todaysDate) as number
			end if
		end if
	end try
	
	-- See if they gave an absolute date, a relative one, or a day of the week
	repeat with i from 1 to (length of monthDelimiters)
		if dateDesired contains (item i of monthDelimiters) then
			set monthFound to i
			exit repeat
		end if
		if i ≤ (length of weekdayDelimiters) then
			if dateDesired contains (item i of weekdayDelimiters) then
				set weekdayFound to i
			end if
		end if
	end repeat
	
	-- Getting rid of all the bits I could imagine being around the numbers
	set text item delimiters to (specialRelativeDayDelimiters & monthDelimiters & weekDelimiters & dayDelimiters & timeDelimiters & otherDelimiters)
	set inputList to every text item of dateDesired
	-- Resetting delimiters
	set text item delimiters to {""}
	
	repeat with i from 1 to (length of inputList)
		if item i of inputList is "-" and (character 1 of item (i + 1) of inputList is in "123456789") then
			set item (i + 1) of inputList to item i of inputList & item (i + 1) of inputList
		end if
	end repeat
	
	-- Count how many numbers were given
	repeat with i from 1 to (length of inputList)
		if (item i of inputList) is not "" then
			try
				set tempItem to (item i of inputList) as integer
				if class of tempItem is integer then set howManyNumbersInputted to howManyNumbersInputted + 1
			end try
		end if
		set tempItem to ""
	end repeat
	
	-- Get the numbers of the input — start from the back to get the minutes first
	set timeStoreLocation to length of inputList
	repeat while timeStoreLocation > 0
		try
			-- If the minutes have a leading zero, just combine them with the hours
			if (numList = {}) and ((item timeStoreLocation of inputList) starts with "0") then
				set the end of numList to ((item (timeStoreLocation - 1) of inputList) & (item timeStoreLocation of inputList)) as number
				set minuteLeadingZero to true
				set timeStoreLocation to timeStoreLocation - 2
			else
				-- Otherwise, get the numbers only
				try
					set tempNum to (item timeStoreLocation of inputList) as number
				on error
					set timeStoreLocation to timeStoreLocation - 1
				end try
				if tempNum ≠ 0 then set the end of numList to tempNum
				set timeStoreLocation to timeStoreLocation - 1
			end if
		end try
	end repeat
	
	-- Reverse it so the order is from biggest to smallest time increment
	set numList to reverse of numList
	
	if (monthFound is 0) and (weekdayFound is 0) then
		-- If the user gave a relative date...
		tell dateDesired
			set daysMissing to not my isNumberIdentifier("d", it)
			set weeksMissing to not my isNumberIdentifier("w", it)
			if (howManyNumbersInputted - ((not daysMissing) as integer) - ((not weeksMissing) as integer)) = 0 then set timeMissing to true
		end tell
		
		-- Figure out how many weeks
		if not weeksMissing then
			set weeksDeferred to item 1 of numList
		else
			set weeksDeferred to 0
		end if
		
		-- Figure out how many days
		if not daysMissing then
			set daysDeferred to howManyDays(numList, weeksMissing)
		else
			if dateDesired contains "Tomorrow" then
				-- Special case where they put "tomorrow"
				set daysDeferred to 1
			else
				-- If they exclude it entirely or put "Today"
				set daysDeferred to 0
			end if
		end if
		
		-- Figure out the time
		set timeDeferredTemp to figureOutTheTime(numList, timeMissing, daysMissing, weeksMissing, minuteLeadingZero)
		-- Understand the meaning of the time component
		set timeDeferred to understandTheTime(timeDeferredTemp, inThe, timeMissing)
		
		-- Creating the time deferred based on minutes and hours calculated
		if timeDeferred ≥ 0 then
			set totalTimeDeferred to timeDeferred + daysDeferred * days + weeksDeferred * weeks
		else
			set totalTimeDeferred to timeDeferred
		end if
		-- end of relative date-only code
		
	else if (weekdayFound > 0) and (monthFound is 0) then
		if length of numList < 1 then set timeMissing to true
		-- Same as if the day and the week were missing on a relative date
		set timeDeferredTemp to figureOutTheTime(numList, timeMissing, true, true, minuteLeadingZero)
		set timeDeferred to understandTheTime(timeDeferredTemp, inThe, timeMissing)
		set daysDeferred to daysFromTodayToWeekday(weekdayFound)
		if timeDeferred ≥ 0 then
			set totalTimeDeferred to daysDeferred * days + timeDeferred
		else
			set totalTimeDeferred to timeDeferred
		end if
	else
		-- If the user gave an absolute date...
		if length of numList < 2 then set timeMissing to true
		-- Same as if the day were there but week wasn't on a relative date
		set timeDeferredTemp to figureOutTheTime(numList, timeMissing, false, true, minuteLeadingZero)
		set timeDeferred to understandTheTime(timeDeferredTemp, inThe, timeMissing)
		set timeFromTodayUntilDesired to figuringTimeToDesiredDay(monthFound, (item 1 of numList))
		if timeDeferred ≥ 0 then
			set totalTimeDeferred to timeFromTodayUntilDesired + timeDeferred
		else
			set totalTimeDeferred to timeDeferred
		end if
	end if
	
	return totalTimeDeferred
	
end englishTime


on isNumberIdentifier(possibleIdentifier, containerString)
	set numberIdentifier to true
	set identifierIsInContainer to false
	set positionOfLastIdentifier to 0
	set charList to every character of containerString
	
	repeat with i from 1 to (length of charList)
		if (item i of charList) = possibleIdentifier then
			set identifierIsInContainer to true
			set positionOfLastIdentifier to i
		end if
	end repeat
	
	if (positionOfLastIdentifier is 0) or (positionOfLastIdentifier is 1) then
		set numberIdentifier to false
	else
		set characterBefore to character (positionOfLastIdentifier - 1) of containerString
		try
			set characterBefore to characterBefore as integer
		end try
		if (characterBefore is not " ") and (class of characterBefore is not integer) then set numberIdentifier to false
	end if
	return numberIdentifier
end isNumberIdentifier


on howManyDays(numList, weeksMissing)
	if not weeksMissing then
		set daysDeferred to item 2 of numList
	else
		set daysDeferred to item 1 of numList
	end if
	return daysDeferred
end howManyDays


on figureOutTheTime(numList, timeMissing, daysMissing, weeksMissing, minuteLeadingZero)
	if not timeMissing then
		if minuteLeadingZero then
			set timeDeferredTemp to item -1 of numList
		else
			set text item delimiters to ""
			set timeDeferredTemp to ((items -1 thru (1 + ((not daysMissing) as integer) + ¬
				((not weeksMissing) as integer)) of numList) as text) as integer
		end if
	else
		set timeDeferredTemp to 0
	end if
	return timeDeferredTemp
end figureOutTheTime


to understandTheTime(timeDeferredTemp, inThe, timeMissing)
	if timeMissing then
		set timeDeferred to 0
	else
		if timeDeferredTemp > 2400 then
			-- If the time is greater than the 24 hour clock...
			display alert "Please try again: the time you entered was not a valid time of day."
			set timeDeferred to -1
			
		else if timeDeferredTemp = 2400 then
			-- If the time is equal to 2400...
			set timeDeferred to days
			
		else if timeDeferredTemp ≥ 100 then
			-- if they entered the time as a full hour:minute pair (with or without AM/PM and with or without the colon)
			set minutesDeferred to (((characters -2 thru -1 of (timeDeferredTemp as text)) as text) as integer)
			set hoursDeferred to (((characters 1 thru -3 of (timeDeferredTemp as text)) as text) as integer)
			-- Figuring out the minutes and hours in the time given (minutes are last two numbers)
			
			if inThe = "PM" then
				-- For any number specifically designated as PM
				set timeDeferred to ((hoursDeferred + 12) * hours + minutesDeferred * minutes)
			else if hoursDeferred = 12 and inThe = "AM" then
				-- For 12:00AM exactly
				set timeDeferred to minutesDeferred * minutes
			else
				-- For times in the AM (implicit or explicit) and explicit times in the PM (i.e., 16:00)
				set timeDeferred to (hoursDeferred * hours + minutesDeferred * minutes)
			end if
			
		else if timeDeferredTemp > 24 then
			-- If they entered the time as a single number above 24
			display alert "Please try again: the time you entered was not a valid time of day."
			set timeDeferred to -1
			
		else if timeDeferredTemp ≤ 24 then
			-- If the entered the time as a single number (with or without AM/PM)	
			if timeDeferredTemp = 24 then
				-- If they entered 24 hours exactly (treat as a full extra delay)
				set timeDeferred to days
			else if (timeDeferredTemp = 12) and (inThe ≠ "AM") then
				-- If they entered "12" (treat it as 12PM)
				set timeDeferred to 12 * hours
			else if (timeDeferredTemp ≥ 12) or (inThe ≠ "PM") then
				-- For implicit and explicit AM entries and for implicit PM entries
				set timeDeferred to timeDeferredTemp * hours
			else
				-- For explicit PM entries
				set timeDeferred to (timeDeferredTemp + 12) * hours
			end if
		end if
	end if
	return timeDeferred
end understandTheTime


to figuringTimeToDesiredDay(monthDesired, dayDesired)
	set todaysDate to (current date)
	set time of todaysDate to 0
	-- Creating an intial date object
	copy todaysDate to exactDesiredDate
	set (day of exactDesiredDate) to dayDesired
	set (month of exactDesiredDate) to monthDesired
	if exactDesiredDate < (current date) then
		set (year of exactDesiredDate) to ((year of todaysDate) + 1)
	end if
	return (exactDesiredDate - todaysDate)
end figuringTimeToDesiredDay


on daysFromTodayToWeekday(weekdayDesired)
	set currentWeekday to (weekday of (current date)) as integer
	if currentWeekday = weekdayDesired then
		set daysDeferred to 0
	else if currentWeekday < weekdayDesired then
		set daysDeferred to weekdayDesired - currentWeekday
	else
		set daysDeferred to 7 + weekdayDesired - currentWeekday
	end if
	return daysDeferred
end daysFromTodayToWeekday

on understandAbsoluteDate(theText)
	set theDate to (current date)
	set the day of theDate to 1
	set the month of theDate to 2
	set theDate to (theDate - 1 * days)
	set theDate to short date string of theDate
	
	set text item delimiters to {".", "-", "/", "–", "—", "|", "\\"}
	set theDate to every text item of theDate
	set thePositions to {theDay:0, theMonth:0, theYear:0}
	
	-- Checks the positions of the date components based on January 31 of this year
	repeat with i from 1 to (length of theDate)
		tell item i of theDate
			if it is in "01" then
				set (theMonth in thePositions) to i
			else if it is in "31" then
				set (theDay in thePositions) to i
			else
				set (theYear in thePositions) to i
			end if
		end tell
	end repeat
	
	set theText to every text item of theText
	
	set targetDate to (current date)
	set time of targetDate to 0
	if (length of theText is not 2) and (length of theText is not 3) then
		-- If they don't input at 2-3 numbers, return the error
		return -1
	else
		if length of theText is 3 then
			-- If the input has three numbers
			set the year of targetDate to solveTheYear((item (theYear of thePositions) of theText) as number)
		else
			-- If the input has two numbers (left out the year)
			set thePositions to adjustPositionsForNoYear(thePositions)
		end if
		set the month of targetDate to (item (theMonth of thePositions) of theText) as number
		set the day of targetDate to (item (theDay of thePositions) of theText) as number
		if targetDate is less than (current date) then
			set the year of targetDate to (the year of (current date)) + 1
		end if
	end if
	return targetDate
end understandAbsoluteDate

to adjustPositionsForNoYear(thePositions)
	if (theYear in thePositions) is 1 then
		set (theMonth in thePositions) to (theMonth in thePositions) - 1
		set (theDay in thePositions) to (theDay in thePositions) - 1
	else if yearPosition is 2 then
		if (theDay in thePositions) < (theMonth in thePositions) then
			set (theMonth in thePositions) to (theMonth in thePositions) - 1
		else
			set (theDay in thePositions) to (theDay in thePositions) - 1
		end if
	end if
	return thePositions
end adjustPositionsForNoYear

to solveTheYear(num)
	if num ≥ 1000 then
		return num
	else
		return (2000 + num)
	end if
end solveTheYear


to notify(theTitle, theDescription, theType, theURL)
	tell application "System Events"
		set isRunning to (count of (every process whose bundle identifier is "com.Growl.GrowlHelperApp")) > 0
	end tell
	if isRunning then
		tell application "Growl"
			register as application applicationName all notifications allNotifications default notifications defaultNotifications icon of application iconApplication
			if length of theURL is 0 then
				notify with name theType title theTitle application name applicationName description theDescription
			else
				notify with name theType title theTitle application name applicationName description theDescription callback URL theURL
			end if
		end tell
	end if
end notify

on attachmentList(theID, theClass)
	set theAttachmentList to {}
	tell front document of application "OmniFocus"
		if theClass is "task" then
			tell note of task id theID
				set NumberOfFileAttached to number of file attachment
				set i to 1
				repeat while i ≤ NumberOfFileAttached
					if file attachment i is not embedded then
						set end of theAttachmentList to file name of file attachment i as string
					end if
					set i to i + 1
				end repeat
			end tell
		end if
		if theClass is "project" then
			tell note of project id theID
				set NumberOfFileAttached to number of file attachment
				set i to 1
				repeat while i ≤ NumberOfFileAttached
					if file attachment i is not embedded then
						set end of theAttachmentList to file name of file attachment i as string
					end if
					set i to i + 1
				end repeat
			end tell
		end if
	end tell
	return theAttachmentList
end attachmentList

on getRidOfDateInfo(theOriginalNote, dueOrStart)
	set numParagraphs to (length of paragraphs of theOriginalNote)
	repeat with i from 1 to numParagraphs
		if paragraph i of theOriginalNote starts with dueOrStart then
			set dateSpot to i
			exit repeat
		end if
	end repeat
	set my text item delimiters to {return}
	if dateSpot is 1 then
		if (count of paragraphs of theOriginalNote) is 1 then
			set theNote to ""
		else
			set theNote to (paragraphs 2 thru -1 of the theOriginalNote) as string
		end if
	else if dateSpot is numParagraphs then
		set theNote to ((paragraphs 1 thru -2) of theOriginalNote) as string
	else
		set theNote to (((paragraphs 1 thru (dateSpot - 1)) of theOriginalNote) & ((paragraphs (dateSpot + 1) thru -1) of theOriginalNote)) as string
	end if
	set my text item delimiters to ""
	return theNote
end getRidOfDateInfo
