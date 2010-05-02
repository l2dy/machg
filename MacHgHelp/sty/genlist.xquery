(: The XQuery prolog, where we set up the variables we're expecting :)
declare variable $AppleTopicListStyleSheetURL as xs:string external;
declare variable $AppleTopicListHeadline as xs:string external;
declare variable $AppleTopicListResults external;

<html>
	<head>
		<title>{$AppleTopicListHeadline}</title>
		<link href="AppleTopicListCSS" rel="stylesheet" media="all"/>
	</head>
	<body>
		<div id="list">
		<h1>{$AppleTopicListHeadline}</h1>
{
	for $item in $AppleTopicListResults
	return <p><a href="{data($item/url)}">{data($item/title)}</a></p>
}
		</div>
		<div id="banner">
			<div id="machelp">
				<a class="bread" href="help:anchor='access' bookID=MacHg Help">Home</a></div>
			<div id="index">
				<a class="leftborder" href="help:anchor='x1' bookID=MacHg Help">Index</a></div>
		</div>
	</body>
</html>