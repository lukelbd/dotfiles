# Replace the old Omnikey extension that became unusable with Safari 13.
# See: https://apple.stackexchange.com/a/346306/214359
# NOTE: Must grant Safari accessibility permissions in order to use this script.
# NOTE: Currently run this script with Karabiner Safari-specific keyboard shortcut.
use AppleScript version "2.5"
use framework "Foundation"
use scripting additions

property |⌘| : a reference to current application
property shortcuts : {¬
  {"az", "https://amazon.com/s?k={search}"}, ¬
  {"eb", "https://ebay.com/sch?kw={search}"}, ¬
  {"ex", "https://colostate.primo.exlibrisgroup.com/discovery/search?query=any,contains,{search}&vid=01COLSU_INST:01COLSU"}, ¬
  {"db", "https://imdb.com/find?q={search}"}, ¬
  {"gm", "https://maps.google.com/maps?q={search}"}, ¬
  {"gs", "https://scholar.google.com/scholar?q={search}"}, ¬
  {"wa", "https://wolframalpha.com/input/?i={search}"}, ¬
  {"wi", "https://en.wikipedia.org/w/index.php?title=Special:Search&search={search}"}, ¬
  {"yt", "https://youtube.com/results?search_query={search}"}, ¬
  {"sh", "https://sci-hub.se/{search}"} ¬
}

tell application "System Events"
  tell process "Safari"
    set theGroup to 1st group of toolbar 1 of window 1 whose class of text field 1 is text field
    set textValue to value of text field 1 of theGroup
  end tell
end tell

set spaceOffset to offset of space in textValue
if spaceOffset = 0 then return
set userToken to text 1 thru (spaceOffset - 1) of textValue
set userQuery to text (spaceOffset + 1) thru -1 of textValue
set unicodeQuery to |⌘|'s NSString's stringWithString:userQuery
set allowedChars to |⌘|'s NSCharacterSet's URLQueryAllowedCharacterSet()'s mutableCopy()
allowedChars's removeCharactersInString:"&=+"
set encodedQuery to unicodeQuery's stringByAddingPercentEncodingWithAllowedCharacters:allowedChars

repeat with theShortcut in shortcuts
  set {theToken, theURL} to contents of theShortcut
  if theToken is userToken then
    set queryURL to (|⌘|'s NSString's stringWithString:theURL)
    set searchURL to (queryURL's stringByReplacingOccurrencesOfString:"{search}" withString:encodedQuery)
    delay 0.8
    tell application "Safari" to set URL of current tab of window 1 to (searchURL as text)
    exit repeat
  end if
end repeat
