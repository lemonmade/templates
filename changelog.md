# 0.5.0
- Removed the ability to convert from Curt Clifton's script syntax. At this point, both are equally well known and there are no benefits to be had from offering an easy transition between the two.
# 0.5.0
- Default folder names can now have any level of depth. That is, you can do something like ">>> Work > Clients > John > Smith" and it should select the Smith folder inside the John folder inside the Clients folder inside the Work folder.
- Killed Growl support. More trouble than it was worth, unfortunately. Notifications use Notification Center instead of Growl now.
- Removed the pointless dialog confirming that you want to just duplicate a project with no variables. If it's in a template folder, it's a template project, so it will automatically do the duplication.
- Template folder must, by default, contain the word "Template"
- Removed the ability to copy a project multiple times with "@copy"
- You can now compare two variables for the comparison operators
- You can use `delete: ask`, just as with `complete: ask`, to have the script ask you if the task should be deleted.
- Contexts can now have as many variables as you want (i.e., "$var1 meeting with var2").
- Date parsing now uses Omni's built in parser
- No need to encase string comparisons in conditions in quotes (i.e., write @if $condition == Hello then complete instead of @if $condition == "Hello" then complete)

## 0.5.1
- Fixed a bug where times added with a colon would not add correctly.

## 0.5.2
- Fixed a bug with using contexts without any variables

## 0.5.3
- Fixed bugs related to colons ruining datetime strings used for variable replacement and templates in dropped folders being included in the available template list.

## 0.5.4
- Fixed an issue where date variables using hyphens wouldn't be correctly interpretted in setting due/ start dates.

## 0.5.5
- The script not works nicely when you start and due default times are simply set at 12AM as mine are. Can't believe how long this bug was lying around in there!

## 0.5.6
- Fixed an issue with calculating the due date when adding/ subtracting dates.

## 0.5.7 (September 25, 2014)
- Added recursive folder check to collect all template projects in a template folder regardless of nesting depth.

# Coming
- You can use "-W" or "-w" after any relative date (either hard-coded or entered via an "ask" statement) to count only weekdays. You can use "-S" or "-s" to skip special dates set with the `property` "specialSkipDays"
