#!/usr/bin/osascript
if application "iTerm" is running then
    tell application "iTerm"
        create window with profile "Scratchpad"
    end tell
else
    activate application "iTerm"
end if

