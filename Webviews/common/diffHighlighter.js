// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined')
{
	Controller = console;
	Controller.log_ = console.log;
}

var safeShift = function(v)
{
    return (v.length > 0) ? v.shift() : "";
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  createSideBySideDiff
// -----------------------------------------------------------------------------------------------------------------------------------------

var createDiff = function(diff, diffTypeString, element, size, allowHunkSelection, showExternalDiffButton, callbacks)
{
	if (!diff || diff == "")
		return;
	
	if (!callbacks)
		callbacks = {};
	var start = new Date().getTime();
	element.className = "diff"
	var content = diff.replace(/\t/g, "    ");
	
	var DiffType = { sideBySide : 0, unified : 1 };
	
	var diffType = DiffType.sideBySide;
	if (diffTypeString == "unified")
		diffType = DiffType.unified;
	else if (diffTypeString == "sideBySide")
		diffType = DiffType.sideBySide;
	
	var file_index = 0;
	
	var startname = "";
	var endname = "";	
	var line1 = "";
	var line2 = "";
	var leftLines = [];
	var leftLineNumbers = [];
	var rightLines = [];
	var rightLineNumbers = [];
	
	var diffContent = "";
	var finalContent = "";
	var lines = content.split('\n');
	var binary = false;
	var mode_change = false;
	var old_mode = "";
	var new_mode = "";
	
	var colSizeForLineNumber = parseInt(size)*3.0 + 10;
	
	var hunk_start_line_1 = -1;
	var hunk_start_line_2 = -1;
	
	var inHunk = false;		// When we are inside a hunk this is true
	var fileHeader = false;
	
	
	var finishRun = function(diffType)
    {
		if (diffType == DiffType.sideBySide)
			while (leftLines.length > 0 || rightLines.length > 0)
			{
				var   leftLineNumber = safeShift(leftLineNumbers);
				var  rightLineNumber = safeShift(rightLineNumbers);
				var   leftLine = safeShift(leftLines);
				var  rightLine = safeShift(rightLines);        
				diffContent += '<tr><td class="lineno">'+leftLineNumber+'</td><td class="delline">'+leftLine+'</td><td class="lineno">'+rightLineNumber+'</td><td class="addline">'+rightLine+'</td></tr>';
			}
		else if (diffType == DiffType.unified)
		{
			while (leftLines.length > 0)
			{
				var   leftLineNumber = safeShift(leftLineNumbers);
				var   leftLine = safeShift(leftLines);

				line1 += leftLineNumber + "\n";
				line2 += "\n";
				diffContent += "<div class='delline'>" + leftLine + "</div>";
			}
			while (rightLines.length > 0)
			{
				var  rightLineNumber = safeShift(rightLineNumbers);
				var  rightLine = safeShift(rightLines);        

				line1 += "\n";
				line2 += rightLineNumber + "\n";
				diffContent += "<div class='addline'>" + rightLine + "</div>";
			}
		}
    }


	var startHunk = function(diffType)
	{
		if (diffType == DiffType.sideBySide)
			diffContent += '<tbody class="hunk">';
		else if (diffType == DiffType.unified)
			diffContent += '<div class="hunk">';
		inHunk = true;
	}

	var addHunkHeader = function(l, diffType)
	{
		var newId="hunk-index-control";	// should be replaced by the id passed in from MacHg
		var headerLine = l;
		if (m = headerLine.match(/(@@ \-([0-9]+),?\d* \+(\d+),?\d* @@)\s*(\w*)/))
		{
			headerLine = m[1]
			hunk_start_line_1 = parseInt(m[2]) - 1;
			hunk_start_line_2 = parseInt(m[3]) - 1;
			if (m.length >= 5)
				newId = m[4];
		}		
		var control = '';
		if (allowHunkSelection != "no")
			control = '<button type="button" class="hunkselector" onclick="handleHunkStatusClick(event)" id="' + newId + '">exclude</button>';

		if (diffType == DiffType.sideBySide)
			diffContent += '<tr class="hunkheader"><td class="lineno">...</td><td colspan="2">'+ headerLine +'</td><td align="right">' + control + '</td></tr>';
		else if (diffType == DiffType.unified)
		{
			line1 += "...\n";
			line2 += "...\n";
			diffContent += '<div class="hunkheader">' + headerLine + control + '</div>';		
		}
	}

	var addHunkNoOpLine = function(l, diffType)
	{
		if (diffType == DiffType.sideBySide)
			diffContent += '<tr><td class="lineno">'+ ++hunk_start_line_1+'</td><td class="noopline">'+l.slice(1)+'</td><td class="lineno">'+ ++hunk_start_line_2+'</td><td class="noopline">'+l.slice(1)+'</td></tr>';
		else if (diffType == DiffType.unified)
		{
			line1 += ++hunk_start_line_1 + "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div class='noopline'>" + l + "</div>";			
		}
	}

	var finishHunk = function(diffType)
	{
		finishRun(diffType);
		if (inHunk && diffContent != "")
		{
			if (diffType == DiffType.sideBySide)
				diffContent += "</tbody>";
			else if (diffType == DiffType.unified)
				diffContent += "</div>";
			inHunk = false;
		} 
	}
	
	
	var startFile = function(diffType)
	{
		line1 = "";
		line2 = "";
		diffContent = "";		
		file_index++;
		startname = "";
		endname = "";
	}
	

	var createFileHeader = function(title)
	{
		var diffButton = '';
		if (showExternalDiffButton == 'yes')
			diffButton = ' <button type="button" class="diffbutton" onclick="doExternalDiffOfFile(\''+title+'\')">external diff</button>';
		return '<div class="fileHeader">' + title + diffButton + '</div>';
	}
	
	var finishContentBody = function(diffType)
	{
		if (diffType == DiffType.sideBySide)
		{
			finalContent +=
			'<table class="diffcontent"><col width="'+colSizeForLineNumber+'px" /><col width="50%" /><col width="'+colSizeForLineNumber+'px" /><col width="50%" />' +
			diffContent +
			'</table>';			
		}
		else if (diffType == DiffType.unified)
		{
			finalContent +=		'<div class="diffcontent">' +
			'<div class="lineno">' + line1 + "</div>" +
			'<div class="lineno">' + line2 + "</div>" +
			'<div class="lines">' + diffContent + "</div>" +
			'</div>';			
		}
	}

	
	var finishFile = function(diffType)
	{
		finishHunk(diffType);
		if (!file_index)
		{
			startFile(diffType);
			return;
		}
		
		if (callbacks["newfile"])
			callbacks["newfile"](startname, endname, "file_index_" + (file_index - 1), mode_change, old_mode, new_mode);
		
		var title = startname;
		var binaryname = endname;
		if (endname == "/dev/null")
		{
			binaryname = startname;
			title = startname;
		}
		else if (startname == "/dev/null")
			title = endname;
		else if (startname != endname)
			title = startname + " renamed to " + endname;
		
		if (binary && endname == "/dev/null") 	// in cases of a deleted binary file, there is no diff/file to display
		{
			startFile(diffType);
			return;				// so printing the filename in the file-list is enough
		}
		
		if (diffContent != "" || binary)
			finalContent += '<div class="file">' + createFileHeader(title);
		
		if (!binary && (diffContent != ""))
			finishContentBody(diffType);
		else
		{
			if (binary)
			{
				if (callbacks["binaryFile"])
					finalContent += callbacks["binaryFile"](binaryname);
				else
					finalContent += "<div>Binary file differs</div>";
			}
		}
		
		if (diffContent != "" || binary)
			finalContent += '</div>';
		
		startFile(diffType);
	}
	
	for (var lineno = 0, lindex = 0; lineno < lines.length; lineno++)
	{
		var l = lines[lineno];
		
		var firstChar = l.charAt(0);
		
		if (firstChar == "d" && l.charAt(1) == "i")
		{			// "diff", i.e. new file, we have to reset everything
			fileHeader = true;		// diff always starts with a file header
			
			finishFile(diffType);	// Finish last file
			
			binary = false;
			mode_change = false;
			
			if (match = l.match(/^diff --git (a\/)+(.*) (b\/)+(.*)$/))
			{										// there are cases when we need to capture filenames from
				startname = match[2];				// the diff line, like with mode-changes.
				endname = match[4];					// this can get overwritten later if there is a diff or if
			}										// the file is binary
			continue;
		}
		
		if (fileHeader)
		{
			if (firstChar == "n")
			{
				if (l.match(/^new file mode .*$/))
					startname = "/dev/null";
				
				if (match = l.match(/^new mode (.*)$/))
				{
					mode_change = true;
					new_mode = match[1];
				}
				continue;
			}
			if (firstChar == "o")
			{
				if (match = l.match(/^old mode (.*)$/))
				{
					mode_change = true;
					old_mode = match[1];
				}
				continue;
			}
			
			if (firstChar == "d")
			{
				if (l.match(/^deleted file mode .*$/))
					endname = "/dev/null";
				continue;
			}
			if (firstChar == "-")
			{
				if (match = l.match(/^--- (a\/)?(.*)$/))
					startname = match[2];
				continue;
			}
			if (firstChar == "+")
			{
				if (match = l.match(/^\+\+\+ (b\/)?(.*)$/))
					endname = match[2];
				continue;
			}
			// If it is a complete rename, we don't know the name yet
			// We can figure this out from the 'rename from.. rename to.. thing
			if (firstChar == 'r')
			{
				if (match = l.match(/^rename (from|to) (.*)$/))
				{
					if (match[1] == "from")
						startname = match[2];
					else
						endname = match[2];
				}
				continue;
			}
			if (firstChar == "B") // "Binary files .. and .. differ"
			{
				binary = true;
				// We might not have a diff from the binary file if it's new.
				// So, we use a regex to figure that out
				
				if (match = l.match(/^Binary files (a\/)?(.*) and (b\/)?(.*) differ$/))
				{
					startname = match[2];
					endname = match[4];
				}
			}
			
			// Finish the header
			if (firstChar == "@")
				fileHeader = false;
			else
				continue;
		}
		
		if (firstChar == "+")
		{			
			rightLineNumbers.push(++hunk_start_line_2);
			rightLines.push(l.slice(1));
		}
		else if (firstChar == "-")
		{
			leftLineNumbers.push(++hunk_start_line_1);
			leftLines.push(l.slice(1));
		}
		else if (firstChar == " ")
		{
		    finishRun(diffType);
			addHunkNoOpLine(l, diffType);
		}
		else if (firstChar == "@")
		{
			if (fileHeader)
				fileHeader = false;
			finishHunk(diffType);		// Finish any other hunk
			startHunk(diffType);		// start the new hunk
			addHunkHeader(l, diffType)
		}
		lindex++;
	}
	
	finishFile(diffType);
	
	element.innerHTML = finalContent;		// This takes about 7ms

	machgWebviewController.excludeHunksAccordingToModel();
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Exclusion Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

function elementIsHunkButton(element)
{
	return (element.type === "button" && element.className === "hunkselector" && element.nodeName === "BUTTON");
}

function getFileNameOfHunkHash(hunkHash)
{
	var element = $(hunkHash);
	var theFile = element;
	while (theFile && theFile.className !== "file")
		theFile = theFile.parentNode;
	
	try {
		return theFile.firstChild.firstChild.nodeValue;
	}
	catch(err) { }
	return null;
}

function getHunkDivOfHunkHash(hunkHash)
{
	var element = $(hunkHash);
	var theHunk = element;
	while (theHunk && theHunk.className !== "hunk" && theHunk.className !== "disabledhunk")
		theHunk = theHunk.parentNode;
	return theHunk;
}

function handleHunkStatusClick(event)
{
	var element = event.target;
	if (!elementIsHunkButton(element)) return;

	var action = element.firstChild.nodeValue;		// This should be "include" or "exclude"
	changeViewHunkStatus(element.id, action);
	changeModelHunkStatus(element.id, action);
}

function excludeViewHunkStatus(hunkHash)
{
	changeViewHunkStatus(hunkHash, "exclude");
}

function includeViewHunkStatus(hunkHash)
{
	changeViewHunkStatus(hunkHash, "include");
}

function changeViewHunkStatus(hunkHash, action)
{
	if (action !== "exclude" && action !== "include")	return;

	var element = $(hunkHash);
	if (!elementIsHunkButton(element)) return;

	var theHunk = getHunkDivOfHunkHash(hunkHash);
	element.firstChild.nodeValue = (action === "exclude") ? "include" : "exclude";
	if (theHunk)
		theHunk.className = (action === "exclude") ? "disabledhunk" : "hunk";
}


function changeModelHunkStatus(hunkHash, action)
{
	if (action !== "exclude" && action !== "include") return;

	var element = $(hunkHash);
	if (!elementIsHunkButton(element)) return;

	var fileNamePath = getFileNameOfHunkHash(hunkHash);
	if (!fileNamePath) return;
			
	if (action === "exclude")
		machgWebviewController.disableHunkForFileName(hunkHash, fileNamePath);
	else
		machgWebviewController.enableHunkForFileName(hunkHash, fileNamePath);
}

function doExternalDiffOfFile(fileNamePath)
{
	machgWebviewController.doExternalDiffOfFile(fileNamePath);
}
