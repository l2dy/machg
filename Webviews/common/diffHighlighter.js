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

var createSideBySideDiff = function(diff, element, size, allowHunkSelection, callbacks)
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
	
	var file_index = 0;
	
	var startname = "";
	var endname = "";
	
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
	var header = false;
	
	
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
    }


	var startHunk = function(diffType)
	{
		if (diffType == DiffType.sideBySide)
			diffContent += '<tbody class="hunk">';
		inHunk = true;
	}
	
	var finishHunk = function(diffType)
	{
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
		file_index++;
	}
	

	var createFileHeader = function(title) 
	{
		var diffButton = '<button type="button" class="diffbutton" onclick="doExternalDiffOfFile(\''+title+'\')">external diff</button>';
		return '<div class="fileHeader">' + title + ' ' + diffButton+'</div>';
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
		finishRun(diffType);
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
			diffContent = "";
			startFile(diffType);
			startname = "";
			endname = "";
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
		
		diffContent = "";
		startFile(diffType);
		startname = "";
		endname = "";
	}
	
	for (var lineno = 0, lindex = 0; lineno < lines.length; lineno++)
	{
		var l = lines[lineno];
		
		var firstChar = l.charAt(0);
		
		if (firstChar == "d" && l.charAt(1) == "i")
		{			// "diff", i.e. new file, we have to reset everything
			header = true;		// diff always starts with a header
			
			finishHunk(diffType);		// Finish last hunk if any
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
		
		if (header)
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
				header = false;
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
		else if (firstChar == "@")
		{
			if (header)
				header = false;
			finishHunk(diffType);		// Finish any other hunk
			startHunk(diffType);		// start the new hunk
			var newId="hunk-index-control";	// should be replaced by the id passed in from MacHg
			var headerLine = l;
			if (m = l.match(/(@@ \-([0-9]+),?\d* \+(\d+),?\d* @@)\s*(\w*)/))
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
		    diffContent += '<tr class="hunkheader"><td class="lineno">...</td><td colspan="2">'+ headerLine +'</td><td align="right">' + control + '</td></tr>';
		}
		else if (firstChar == " ")
		{
		    finishRun(diffType);
		    diffContent += '<tr><td class="lineno">'+ ++hunk_start_line_1+'</td><td class="noopline">'+l.slice(1)+'</td><td class="lineno">'+ ++hunk_start_line_2+'</td><td class="noopline">'+l.slice(1)+'</td></tr>';
		}
		lindex++;
	}
	
	finishFile(diffType);
	
	element.innerHTML = finalContent;		// This takes about 7ms

	machgWebviewController.excludeHunksAccordingToModel();
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  createUnifiedDiff
// -----------------------------------------------------------------------------------------------------------------------------------------

var createUnifiedDiff = function(diff, element, size, allowHunkSelection, callbacks)
{
	if (!diff || diff == "")
		return;
	
	if (!callbacks)
		callbacks = {};
	var start = new Date().getTime();
	element.className = "diff"
	var content = diff.replace(/\t/g, "    ");
	
	var file_index = 0;
	
	var startname = "";
	var endname = "";
	var line1 = "";
	var line2 = "";
	var diffContent = "";
	var finalContent = "";
	var lines = content.split('\n');
	var binary = false;
	var mode_change = false;
	var old_mode = "";
	var new_mode = "";
	
	var hunk_start_line_1 = -1;
	var hunk_start_line_2 = -1;
	
	var inHunk = false;		// When we are inside a hunk this is true
	var header = false;
	
	var finishHunk = function()
	{
		if (inHunk && diffContent != "")
		{
			diffContent += "</div>";
			inHunk = false;
		} 
	}
	
	var startHunk = function()
	{
		inHunk = true;
	}
	
	var startFile = function()
	{
		file_index++;
	}
	
	
	var finishFile = function()
	{
		finishHunk();
		if (!file_index)
		{
			startFile();
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
			line1 = "";
			line2 = "";
			diffContent = "";
			startFile();
			startname = "";
			endname = "";
			return;				// so printing the filename in the file-list is enough
		}
				
		if (diffContent != "" || binary)
		{
			var diffButton = '<button type="button" class="diffbutton" onclick="doExternalDiffOfFile(\''+title+'\')">external diff</button>';
			finalContent += '<div class="file" id="file_index_' + (file_index - 1) + '">' + '<div class="fileHeader">' + title + ' ' + diffButton+'</div>';
		}
		
		if (!binary && (diffContent != ""))
		{
			finalContent +=		'<div class="diffcontent">' +
			'<div class="lineno">' + line1 + "</div>" +
			'<div class="lineno">' + line2 + "</div>" +
			'<div class="lines">' + diffContent + "</div>" +
			'</div>';
		}
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
		
		line1 = "";
		line2 = "";
		diffContent = "";
		startFile();
		startname = "";
		endname = "";
	}
	
	for (var lineno = 0, lindex = 0; lineno < lines.length; lineno++)
	{
		var l = lines[lineno];
		
		var firstChar = l.charAt(0);
		
		if (firstChar == "d" && l.charAt(1) == "i")
		{			// "diff", i.e. new file, we have to reset everything
			header = true;						// diff always starts with a header
			
			finishHunk();		// Finish last hunk if any
			finishFile();	// Finish last file
			
			binary = false;
			mode_change = false;
			
			if (match = l.match(/^diff --git (a\/)+(.*) (b\/)+(.*)$/))
			{										// there are cases when we need to capture filenames from
				startname = match[2];				// the diff line, like with mode-changes.
				endname = match[4];					// this can get overwritten later if there is a diff or if
			}										// the file is binary
			continue;
		}
		
		if (header)
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
				header = false;
			else
				continue;
		}
		
		if (firstChar == "+")
		{
			// Highlight trailing whitespace
			if (m = l.match(/\s+$/))
				l = l.replace(/\s+$/, "<span class='whitespace'>" + m + "</span>");
			
			line1 += "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div class='addline'>" + l + "</div>";
		}
		else if (firstChar == "-")
		{
			line1 += ++hunk_start_line_1 + "\n";
			line2 += "\n";
			diffContent += "<div class='delline'>" + l + "</div>";
		}
		else if (firstChar == "@")
		{
			if (header)
				header = false;
			finishHunk();		// Finish any other hunk
			startHunk();		// start the new hunk
			var newId="hunk-index-control-";	// should be replaced by the id passed in from MacHg
			var headerLine = l;
			if (m = l.match(/(@@ \-([0-9]+),?\d* \+(\d+),?\d* @@)\s*(\w*)/))
			{
				headerLine = m[1]
				hunk_start_line_1 = parseInt(m[2]) - 1;
				hunk_start_line_2 = parseInt(m[3]) - 1;
				if (m.length >= 5)
					newId = m[4];
			}
			line1 += "...\n";
			line2 += "...\n";
			var control = '';
			if (allowHunkSelection != "no")
				control = '<button type="button" class="hunkselector" onclick="handleHunkStatusClick(event)" id="' + newId + '">exclude</button>';
			diffContent += '<div class="hunk"><div class="hunkheader">' + headerLine + control + '</div>';
		}
		else if (firstChar == " ")
		{
			line1 += ++hunk_start_line_1 + "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div class='noopline'>" + l + "</div>";
		}
		lindex++;
	}
	
	finishFile();
	
	// This takes about 7ms
	element.innerHTML = finalContent;

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
