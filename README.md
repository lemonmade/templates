# Templates.scpt
## by Chris Sauvé of [pxldot](http://pxldot.com)

## Screencast
A screencast illustrating almost all of the features of this script can be seen on the [Template project's page](http://cmsauve.com/projects/templates/) of my website.

## Why I Built This Script
OmniFocus is an incredible piece of software. I and countless others rely on it every day to manage increasingly hectic lives and complex, multi-facetted projects. A central tenet of "good" productivity tools (as opposed to those we simply indulge in for their own sake, the "productivity porn") is that they reduce friction. This script is an effort to reduce one of the largest sources of friction remaining in my OmniFocus setup: maintaining and creating projects that don't recur on even intervals, but occur frequently enough that their planning and capture becomes a time sink. The script allows you to create templates as simple or complex as you need them to be, and to quickly create instances of those templates so you can get back to what's important.


## Script Basics
You need a few things before the script will work as intended. The script looks for a folder that contains the word "Template" in the name, and assumes that this is the folder from which you want to select template projects. This folder can be Dropped, and the actual template projects can be On Hold (the script will automatically switch the new template instances to Active). If it doesn't find an obvious template folder, it will ask you which folder to use.

When the script runs, it does a number of things. It will first ask you which project inside the template folder you would like to create a new instance of, then ask in which folder you would like to put the new project instance. If there are any variables or "ask" statements (discussed later) the script will prompt you to provide any additional input required. If you have Growl installed, a Growl alert will come up when you start the script and when you finish it. The alert indicating the end of the script can be clicked to quickly show you the new instance of your template project.

On first run, the script will ask you to choose a variable symbol and, if it detects that you have projects already using [Curt Clifton's OmniFocus template syntax](http://www.curtclifton.net/projects/) (which were a big inspiration for this project), it will offer to convert these to this script's syntax.


## Script Components
### Variables
You can use variables in your script to have the script prompt you for a string that will be used in multiple places of the new template instance. For example, a template for contacting someone may use a person's name for a number of tasks/ notes/ context names, and the name to use may change for each project instance. This is an ideal time to use a basic variable. Note that all variables are case-insensitive.

**Basic Variables** are the most important part of the script. By default, you declare a basic variable by writing that variables name, preceeded by the "$" sign, anywhere in the template project's note (on the first run the script will prompt you to select an alternate variable symbol, if you wish). Variable names can contain spaces and you can have as many as you wish (though must all be in the same paragraph of the project's note; for example, `$variable1 $another variable $the last variable` would declare three variables for use in the script). Once these variables are declared, you can use them almost anywhere: the project note, project name, task name, task note, and/or task context. When the script is run, it will detect the variables, ask you what you would like to replace each with, and then do a search and replace through the entire project based on your input.

*Example: You declare `$person $subject` in your project note. One of the task names is "Email $person about $subject", and when prompted you choose to replace "$person" with "John" and "$subject" with "TPS Report". In the new project instance, the task will have the name "Email John about TPS Report".*

**Choose Variables** are a special kind of variable that allow you define a list of options from which you will choose when creating a new instance of the project. You declare these along with your basic variables (that is, using the same variable symbol and in the same paragraph as your basic variables), but use the following adjusted notation: `$variableName {option 1, option 2, option 3}`. Upon creating a new instance of the project, you will be asked which of these options to replace the variable `$variableName` with.

**Date Variables** are another special variable that you give a relative or absolute date as input. You declare these just like basic variables, but their name must start with the word "date" (for example, `$date of module 1` or `$date-stage1`). When prompted for input, you can use any of the relative or absolute date strings you can normally use with OmniFocus; things like "19:00", "1d" (1 day), "3w 4d 2pm" (3 weeks and 4 days at 2:00PM), "sun" (next Sunday), "Feb 28", and "February 28" will all work. The "short date" format you have specified in the Languages and Test preference pane will also work as an absolute date. The order of the year, month and date are all that matter, and the year, month and date can the be stated with or without leading ones and with any of the following seperators: ".", "/", and "-". So, if your short date format is YY/MM/DD, all of the following would represent January 31, 2014: "14.01.31", "2014/01/31", and "01-31". These date variables can then be used in place of basic variables (that is, as text) or, more interestingly, in assigning start and due dates (see below).

When using date variables for inserting the date in task notes/ names, you can specify a custom format in which the date will be inserted by changing the `dateFormat` property within the script. The default will be to insert the date in the format "June 17, 2013". You can change the way in which the year, month, day, and/or weekday will be displayed, as well as what other text you would like to have in the date. For the details on setting up your own custom format, see the comments included below the `dateFormat` property at the top of the script.

**"Today" Variable** is a special date variable. A variable declared as "Today" will automatically be assigned today's date, which can then be used in the same places as any other variable.

### Start and Due Dates
The script can assign due dates to any subset of tasks in the template projects, or to the project itself. Start dates are set using the phrase `start: ` in a new paragraph of the project/ task's note, while due dates are set using `due: `. You then include one of the following date declaration types:

**Relative to Today**: stating a relative date after the start/ due statement will set the task's start/ due to today (at 12:00AM) plus the relative date indicated. For example, if today is January 1 and you create a new instance of a template that has a task whose note contains `start: 1w` on a new line, the new instance of the project will have a start date of January 8. If it also has `due: 1w 2d 2pm` on another new line, the task's due date will be January 10 at 2:00PM.

**Relative to Project**: for all tasks inside a template project, you can set the start/due date relative to those of the project. To do so, you use the keywork `project` and the math you want to perform. So, for example, `start: project + 3d` will set the start date of that task to 3 days after the start date of the project.

**Using Date Variables**: if you declared date variables in the project note, you can use them in any task or project start/ due date (with additional date math, if you wish). For example, `start: $dateVariable` will set the start date to $dateVariable (if it is declared), while `due: $dateVariable + 2w` will set the due date to the date of $dateVariable plus 2 weeks.

**`ask`**: the last option is to use the keyword `ask`. This will get the script to prompt you for the date. For example, setting the note of the project to have both `start: ask` and `due: ask` (on separate lines) will make the script prompt you for a start and a due date (using the same relative/ absolute dates as before).

The script will try to be smart about telling you that you have a mismatch in your project and task due/ start dates (for example, a task has a due date after that of the project, or has a due date in the past).

### Default Folder
You can select a default folder into which to place new instances of a template project. To do so, place the following in a new paragraph of the project note: `>>> defaultFolder`, where you replace defaultFolder with the exact name of the target folder. For example, `>>> Work` will place new instances of that template project in the folder whose name is "Work". You can specify a subfolder to place it in as well, if you have a more complex folder structure: this is done using the symbol `>` to denote a subfolder. For example, `>>> Work > Job1` would place all new instances of the project in the Job1 folder under the Work folder.

### Conditionals
The script can complete or delete tasks or task groups within the projects contingently (i.e., using an if/else statement). In order to use this feature, you include a conditional statement in the note of the desired tasks/ task groups in the following format: `@if $variableName [<=, >=, ==, !=, >, <] comparison then [complete, delete]`. The entire statement must be all by itself on a new line in the task note for the conditional statement to work.

The operators are self-explanatory, but are explained here in case you are not familiar with them: `>=` means equal to or greater than; `<=` means equal to or less than; `==` means equal to; `!=` means not equal to; `>` means greater than; and `<` means less than. The comparison can be either numbers or strings (if you are comparing to a string, the comparison string must be in simple quotes (`"string"`), and only the `==` and `!=` operators will work). The conditionals rely on comparing your comparison amount/ string to one of the project variables, which must be declared in the project note as with any variable. You can combine multiple comparisons together using either "and" (&&) or "or" (||) keywords (but not both).

A few examples conditional statements are shown below:

- `@if $amount < 5000 then complete` will complete the task if the `$amount` variable is given a numeric value less than 5000.

- `@if $person == "Fred" then delete` will delete the task if the `$person` variable is Fred.

- `@if $friend != "Nick" && $price > 2 then complete` will complete the task if the `$friend` variable is *not* Nick *and* the $price variable is greater than 2.

### Other
Attachments to the template that are not embedded (i.e., that are aliases to the files in your filesystem) should be preserved when a new instance of the project is created.

You can tell the script to ask you for an attachment to a note/ project by putting `attachment: ask` anywhere in the note. Likewise, you can put `complete: ask` anywhere in the note to have the script ask you whether or not to complete a particular task in the new instance of the template.

You can get the script to automatically ask you for a support folder for use with my [`Support` AppleScript](http://github.com/pxldot/support). To do so, include the string `@support: ask` on a new line anywhere in the project note.

There are a few compile-time options that you can change for this script. If you open the file in AppleScript Editor, changes to the following properties can be made without breaking anything:

`property startEndOfFolder`: either "start" or "end", with end putting the new project instance at the top of the folder and end putting it at the bottom.
`property variableSymbol`: the string that will denote a variable in your scripts.
`property defaultFolderPointer`: the string that will denote your choice for a default folder for new project instances.
`property optionListStartDelimiter` and `property optionListEndDelimiter`: the symbols that denote the start and end of options for a chooser variable.


## Glossary of Commands
- `complete: ask`: will ask you whether or not to complete the task on instantiation of the project.

- `attachment: ask`: will ask you for an attachment to the project/ task on instantiation of the project.

- `due (or start): ask`: will ask you for the due/ start date of the project.

- `due (or start): <relative date>`: will defer the start/ due date to the date of instantiation (at 12:00AM) + `<relative date>`.

- `due (or start): project ± <relative date>`: will defer the start/ due date to the start/ due date of the project plus or minus the relative date given.

- `due (or start): $dateVariable ± <relative date>`: will defer the start/ due date to the date of $dateVariable plus or minus the relative date given.

- `$<anything>`: declare a basic variable (all variables must be on the same paragraph in the project notes).

- `$today`: declares a variable that is automatically assigned today's date.

- `$date<anything>`: declare a date variable (all variables must be on the same paragraph in the project notes).

- `$<anything> {option1, option2}`: declare a chooser variable with the options declared in the curly braces (all variables must be on the same paragraph in the project notes).

- `>>>defaultFolderName`: will automatically place the new instances of this project in the folder whose name is exactly "defaultFolderName". You can specify a subfolder by using `>>>defaultFolderContainer > defaultFolderName`.

- `@support: ask`: will ask you for a support folder for use with my [`Support` AppleScript](http://github.com/pxldot/support) by opening up a folder choice dialog.

- `@if conditional(s) then (complete | delete)`: will complete or delete the task based on the conditional statement(s) you specify. See the Conditionals section for more details.

## Installation
Download the most recent version of the script. Once you have downloaded the script, navigate to your Application script folder located at `~/Library/Scripts/Applications/OmniFocus`. Apple hides the Library folder in Mac OS X 10.7 or later by default, so the easiest way to get to this folder is to select the menu item `Go > Go To Folder...` in Finder.app. You may have to manually create an OmniFocus folder in the `~/Library/Scripts/Applications` directory if you do not have any previous scripts for OmniFocus (you may have to create more of the folders in the directory; if you don't have an Applications folder or even a Scripts folder, you will have to create those as well).


## Using The Script
There are countless ways you can run the script. If you are a pro user, you likely know even more ways than I do: options like launching the script from FastScripts, Alfred, LaunchBar, or a Keyboard Maestro macro are all available to you. Below I'll explain two ways to run the script, primarily targetted at more novice users.

Your first option is to run the script from Apple's AppleScript menu. If you don't have a little script icon near the clock in your Mac's menubar, you need to turn this on manually. Open AppleScript Editor.app from your `Applications > Utilities` folder. Go to AppleScript's preferences by selecting `AppleScript Editor > Preferences...` from the menubar. On the "General" pane, you should check the checkbox to "Show Script menu in menu bar". Now, when in OmniFocus, select the new script menubar item and you will see the script at the bottom of the list, ready to be clicked and run.

OmniFocus has another way to run scripts, and it's even easier than the method described above. Once the script is installed, go to OmniFocus and right- (control-) click on the toolbar (the gray bar at the top of the window that shows icons for your inbox, projects, and more). Choose "Customize Toolbar..." from the contextual menu that pops up. You will then see a list of all items that can be put in your menubar, including (at the bottom) any scripts that you have installed. Drag the script anywhere on the toolbar and click "Done". You now have one-click access to run this script!


## Version History
- **0.4.1** (June 17, 2013): Bug fixes. Added custom date text formats and the ability to use and/ or with conditional statements.

- **0.4.0** (March 31, 2013): Added conditional deletion/ completion.

- **0.3.6** (March 27, 2013): Bugfixes. You can also now specify a specific folder path as the default folder using > for a subfolder (i.e., ">>>Folder > Subfolder" will put the new instance in Subfolder under Folder).

- **0.3.5** (March 18, 2013): Added the ability to set dates in the format specified in as the short date format in your Languages and Text preference pane.

- **0.3.1** (February 28, 2013): Bugfixes.

- **0.3.0** (February 24. 2013): Fixed an issue with subtracting dates. Improved Growl alerts. Added an option to put "attachment: ask" in the task notes to have the script ask you for an attachment to that task. Variables can now be given a list of values to choose from using the notation $variableName {option 1, option 2, option3} in the project note. If you use the variable "$today", the variable will automatically be assigned the date you create the new instance. Added a screencast, readme, and [website](http://cmsauve.com/projects/templates/).

- **0.2.9** (February 13, 2013): Preserves non-embedded attachments to tasks

- **0.2.8** (February 13, 2013): Fixed the compile-time option of putting the project at the beginning of the list. Changed notifications over to Growl. You can also have the script ask if a certain task should be completed or not by putting "complete: ask" anywhere in its note.

- **0.2.7** (February 11, 2013): Fixed an issue where the template wouldn't instantiate properly if there were no variables. Added a compile-time option to put the project at the beginning of the project list

- **0.2.6** (February 7, 2013): Now works with template folders that are dropped.

- **0.2.5** (January 30, 2013): New "$date" variables — will ask you for a date instead of a string (you can use all of the same relative/ absolute shorthand forms in defining the date, and it can be used in conjunction with the "start" / "due" identifiers)

- **0.2.4** (January 22, 2013): Other bugfixes

- **0.2.3** (January 22, 2013): Fix for setting default folder to a subfolder

- **0.2.2** (January 22, 2013): Allows you to set both a start and due date. Fixes a bug where due/ start declarations in projects wouldn't be eliminated when a new instance was created.

- **0.2.1** (January 22, 2013): Does a better job of cleaning up notes and allows variables on any line of project

- **0.2.0** (January 21, 2013): using the keyword "ask" in after the start/due declaration in the note of a task/ project will have the script prompt you to enter a relative or absolute start/due date for that item. Similarly, you can use the keyword "project" to set the start/ due date relative to that of the project; the script will take whatever is after the keyword and subtract it from the due date/ add it to the start date of the project, as the case may be. Finally, using the (by default) ">>>" operator in the second, followed by a string that EXACTLY matches one of the folders in your OF library will skip the folder selection dialog and put the new instance directly in the designated folder. Plus, fancy icon.

- **0.1.1** (January 18, 2013): Handles projects in a template folder without variables more gracefully (thanks, Sven!)

- **0.1.0** (January 18, 2013): Initial release


## License
Use it, change it, repackage it, whatever. Try not to take credit for my work.