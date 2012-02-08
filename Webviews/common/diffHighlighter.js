var createDiff = function(diff, diffTypeString, element, size, allowHunkSelection, callbacks)
	var DiffType = { sideBySide : 0, unified : 1 };
	
	var diffType = DiffType.sideBySide;
	if (diffTypeString == "unified")
		diffType = DiffType.unified;
	else if (diffTypeString == "sideBySide")
		diffType = DiffType.sideBySide;
	
	var endname = "";	
	var fileHeader = false;
	var finishRun = function(diffType)
		if (diffType == DiffType.sideBySide)
			while (leftLines.length > 0 || rightLines.length > 0)
				var   leftLineNumber = safeShift(leftLineNumbers);
				var  rightLineNumber = safeShift(rightLineNumbers);
				var   leftLine = safeShift(leftLines);
				var  rightLine = safeShift(rightLines);        
				diffContent += '<tr><td class="lineno">'+leftLineNumber+'</td><td class="delline">'+leftLine+'</td><td class="lineno">'+rightLineNumber+'</td><td class="addline">'+rightLine+'</td></tr>';
		else if (diffType == DiffType.unified)
			while (leftLines.length > 0)
				var   leftLineNumber = safeShift(leftLineNumbers);
				var   leftLine = safeShift(leftLines);

				line1 += leftLineNumber + "\n";
				line2 += "\n";
				diffContent += "<div class='delline'>" + leftLine + "</div>";
			while (rightLines.length > 0)
				var  rightLineNumber = safeShift(rightLineNumbers);
				var  rightLine = safeShift(rightLines);        

				line1 += "\n";
				line2 += rightLineNumber + "\n";
				diffContent += "<div class='addline'>" + rightLine + "</div>";
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
			line1 += "...\n";
			line2 += "...\n";
			diffContent += '<div class="hunkheader">' + headerLine + control + '</div>';		
	}

	var addHunkNoOpLine = function(l, diffType)
	{
		if (diffType == DiffType.sideBySide)
			diffContent += '<tr><td class="lineno">'+ ++hunk_start_line_1+'</td><td class="noopline">'+l.slice(1)+'</td><td class="lineno">'+ ++hunk_start_line_2+'</td><td class="noopline">'+l.slice(1)+'</td></tr>';
		else if (diffType == DiffType.unified)
			line1 += ++hunk_start_line_1 + "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div class='noopline'>" + l + "</div>";			
	var finishHunk = function(diffType)
		finishRun(diffType);
			if (diffType == DiffType.sideBySide)
				diffContent += "</tbody>";
			else if (diffType == DiffType.unified)
				diffContent += "</div>";
	
	var startFile = function(diffType)
		line1 = "";
		line2 = "";
		diffContent = "";		
		file_index++;
		startname = "";
		endname = "";

	var createFileHeader = function(title) 
		var diffButton = '<button type="button" class="diffbutton" onclick="doExternalDiffOfFile(\''+title+'\')">external diff</button>';
		return '<div class="fileHeader">' + title + ' ' + diffButton+'</div>';
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
		finishHunk(diffType);
			startFile(diffType);
			startFile(diffType);
		
			finalContent += '<div class="file">' + createFileHeader(title);
			finishContentBody(diffType);
		startFile(diffType);
			fileHeader = true;		// diff always starts with a file header
			finishFile(diffType);	// Finish last file
		if (fileHeader)
				fileHeader = false;
		{			
			rightLineNumbers.push(++hunk_start_line_2);
			rightLines.push(l.slice(1));
			leftLineNumbers.push(++hunk_start_line_1);
			leftLines.push(l.slice(1));
		else if (firstChar == " ")
		    finishRun(diffType);
			addHunkNoOpLine(l, diffType);
		else if (firstChar == "@")
			if (fileHeader)
				fileHeader = false;
			finishHunk(diffType);		// Finish any other hunk
			startHunk(diffType);		// start the new hunk
			addHunkHeader(l, diffType)
	finishFile(diffType);
	element.innerHTML = finalContent;		// This takes about 7ms