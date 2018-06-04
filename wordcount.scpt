-- This is a really stripped down and simple version of 
-- Daniel Shockley's DocInfo, which I had trouble getting 
-- to work on pandoc converted unicode files. 
-- Thanks to him for the original script:
-- DocInfo (for Skim)
-- version 1.0, Daniel A. Shockley, http://www.danshockley.com
-- http://www.danshockley.com/files/DocInfo.scpt
-- https://gist.github.com/kmlawson/5801900
tell application "Skim"
  set docName to name of document 1
	set docText to get text for document 1
	set selText to get text for selection of document 1
	set docWords to count of words of docText
	display dialog "Total words: " & docWords
end tell
