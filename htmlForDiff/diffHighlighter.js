// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined')
{
	Controller = console;
	Controller.log_ = console.log;
}


var highlightDiff = function(diff, element, callbacks)
{
	if (!diff || diff == "")
		return;
	
	if (!callbacks)
		callbacks = {};
	var start = new Date().getTime();
	element.className = "diff"
	var content = diff.escapeHTML().replace(/\t/g, "    ");;
	
	var file_index = 0;
	var hunk_index = 0;
	
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
		hunk_index++;
		inHunk = true;
	}
	
	var startFile = function()
	{
		file_index++;
	}
	
	
	var finishContent = function()
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
			finalContent += '<div class="file" id="file_index_' + (file_index - 1) + '">' + '<div class="fileHeader">' + title + '</div>';
		
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
			finishContent();	// Finish last file
			
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
		
		sindex = "index=" + lindex.toString() + " ";
		if (firstChar == "+")
		{
			// Highlight trailing whitespace
			if (m = l.match(/\s+$/))
				l = l.replace(/\s+$/, "<span class='whitespace'>" + m + "</span>");
			
			line1 += "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div " + sindex + "class='addline'>" + l + "</div>";
		}
		else if (firstChar == "-")
		{
			line1 += ++hunk_start_line_1 + "\n";
			line2 += "\n";
			diffContent += "<div " + sindex + "class='delline'>" + l + "</div>";
		}
		else if (firstChar == "@")
		{
			if (header)
				header = false;
			finishHunk();		// Finish any other hunk
			startHunk();		// start the new hunk
			
			if (m = l.match(/@@ \-([0-9]+),?\d* \+(\d+),?\d* @@/))
			{
				hunk_start_line_1 = parseInt(m[1]) - 1;
				hunk_start_line_2 = parseInt(m[2]) - 1;
			}
			line1 += "...\n";
			line2 += "...\n";
			var encodedFileNamePlusHunk = encodeURIComponent(endname+':'+hunk_index);
			diffContent += '<div class="hunk" id="hunk-index-' + hunk_index + '"><div ' + sindex + 'class="hunkheader">' + l +
			'<span class="includehunk"><input type="checkbox" class="hunkselector" checked="yes" onclick="handleHunkStatusClick(event)" id="' + encodedFileNamePlusHunk + '">include</input></span></div>';
		}
		else if (firstChar == " ")
		{
			line1 += ++hunk_start_line_1 + "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div " + sindex + "class='noopline'>" + l + "</div>";
		}
		lindex++;
	}
	
	finishContent();
	
	// This takes about 7ms
	element.innerHTML = finalContent;
	
	// TODO: Replace this with a performance pref call
	if (false)
		Controller.log_("Total time:" + (new Date().getTime() - start));

	macHgPatchesTableView.excludeHunksAccordingToModel();
}


function handleHunkStatusClick(event)
{
	var element = event.target;
	if (element.type === "checkbox" && element.className === "hunkselector" && element.nodeName === "INPUT")
	{
		var action = element.checked ?  "include" : "exclude";	// This is counter-intuitive but we are reacting after the click.
																// Ie if the click turned off the checkbox then we are "excluding"
		changeViewHunkStatus(element.id, action);
		changeModelHunkStatus(element.id, action);
	}
}

function excludeViewHunkStatus(fileName, hunkNumber)
{
	var encodedFileNamePlusHunk = encodeURIComponent(fileName + ':' + hunkNumber);
	changeViewHunkStatus(encodedFileNamePlusHunk, "exclude");
}

function changeViewHunkStatus(theId, action)
{
	var element = $(theId);
	if (element.type === "checkbox" && element.className === "hunkselector" && element.nodeName === "INPUT")
	{
		if (action !== "exclude" && action !== "include")	return;
		element.checked = (action === "exclude") ? false : true;
		var theHunk = element.parentNode.parentNode.parentNode;
		if (theHunk)
			theHunk.className = (action === "exclude") ? "disabledhunk" : "hunk";
	}
}

function changeModelHunkStatus(theId, action)
{
	var element = $(theId);
	if (element.type === "checkbox" && element.className === "hunkselector" && element.nodeName === "INPUT")
	{
		if (action !== "exclude" && action !== "include")
			return;
		var fileNamePlusHunk = decodeURIComponent(element.id);
		var regex = /(.*):(\d+)$/g;
		theMatch = regex.exec(fileNamePlusHunk);
		if (theMatch)
		{
			var fileNamePath = theMatch[1];
			var hunkNumber = theMatch[2];
			if (action === "exclude")
				macHgPatchesTableView.disableHunkForFileName(hunkNumber, fileNamePath);
			else
				macHgPatchesTableView.enableHunkForFileName(hunkNumber, fileNamePath);
		}
	}
}

