/*
	This file is part of the PolKit library.
	Copyright (C) 2008-2009 Pierre-Olivier Latour <info@pol-online.net>
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Modified by Jason F Harris, in February 2011

#import "NSURL+Parameters.h"
#import "Common.h"

// See http://www.faqs.org/rfcs/rfc1738.html
NSString* createEscapedUserPassword(NSString* str)
{
	CFStringRef strRef = ( __bridge CFStringRef)str;
	CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, strRef, NULL, CFSTR(":@/?!"), kCFStringEncodingUTF8);
	return CFBridgingRelease(escapedStr);
}

NSString* escapeString(NSString* str)
{
	CFStringRef strRef = ( __bridge CFStringRef)str;
	CFStringRef escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, strRef, NULL, NULL, kCFStringEncodingUTF8);
	return CFBridgingRelease(escapedStr);
}

NSString* unescapeString(NSString* str)
{
	CFStringRef strRef = ( __bridge CFStringRef)str;
	CFStringRef escapedStr = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, strRef, CFSTR(""), kCFStringEncodingUTF8);
	return CFBridgingRelease(escapedStr);
}

@implementation NSURL (Parameters)

+ (NSURL*) URLWithScheme:(NSString*)scheme host:(NSString*)host path:(NSString*)path
{
	return [self URLWithScheme:scheme user:nil password:nil host:host port:0 path:path query:nil];
}

+ (NSURL*) URLWithScheme:(NSString*)scheme user:(NSString*)user password:(NSString*)password host:(NSString*)host port:(UInt16)port path:(NSString*)path
{
	return [self URLWithScheme:scheme user:user password:password host:host port:port path:path query:nil];
}

+ (NSURL*) URLWithScheme:(NSString*)scheme user:(NSString*)user password:(NSString*)password host:(NSString*)host port:(UInt16)port path:(NSString*)path query:(NSString*)query
{
	NSMutableString* string = [NSMutableString string];
	
	if (IsEmpty(scheme) || IsEmpty(host))
		return nil;
	
	[string appendFormat:@"%@://", scheme];
	
	if (IsNotEmpty(user))
	{
		NSString* escapedUser = createEscapedUserPassword(user);
		NSString* escapedPassword = IsNotEmpty(password) ? createEscapedUserPassword(password) : nil;
		
		if (escapedUser && escapedPassword)
			[string appendFormat:@"%@:%@@", escapedUser, escapedPassword];
		else
			[string appendFormat:@"%@@", escapedUser];
	}
	
	[string appendString:host];
	
	if (port)
		[string appendFormat:@":%i", port];
	
	if (IsNotEmpty(path))
	{
		if ([path characterAtIndex:0] != '/')
			[string appendString:@"/"];
		[string appendString:escapeString(path)];
	}
	
	if (IsNotEmpty(query))
	{
		[string appendString:@"?"];
		[string appendString:escapeString(query)];
	}
	
	return [NSURL URLWithString:string];
}

- (NSString*) passwordByReplacingPercentEscapes
{
	NSString* string = self.password;
	return IsNotEmpty(string) ? unescapeString(string) : nil;
}

- (NSString*) queryByReplacingPercentEscapes
{
	NSString* string = self.query;
	return IsNotEmpty(string) ? unescapeString(string) : nil;
}

- (NSURL*) URLByDeletingPassword
{
	return [NSURL URLWithScheme:self.scheme user:self.user password:nil host:self.host port:[self.port unsignedShortValue] path:self.path];
}

- (NSURL*) URLByDeletingUserAndPassword
{
	return [NSURL URLWithScheme:self.scheme user:nil password:nil host:self.host port:[self.port unsignedShortValue] path:self.path];
}

- (NSURL*) URLByReplacingUser:(NSString*)newUser
{
	return [NSURL URLWithScheme:self.scheme user:newUser password:self.password host:self.host port:[self.port unsignedShortValue] path:self.path];
}

- (NSURL*) URLByReplacingPassword:(NSString*)newPassword
{
	return [NSURL URLWithScheme:self.scheme user:self.user password:newPassword host:self.host port:[self.port unsignedShortValue] path:self.path];
}

- (NSURL*) URLByReplacingBaseURL:(NSString*)newBase
{
	NSURL* newBaseURL = [NSURL URLWithString:newBase];
	NSString* newUserIfAny     = IsNotEmpty([newBaseURL user])     ? newBaseURL.user     : self.user;
	NSString* newPasswordIfAny = IsNotEmpty([newBaseURL password]) ? newBaseURL.password : self.password;
	return [NSURL URLWithScheme:[newBaseURL scheme] user:newUserIfAny password:newPasswordIfAny host:[newBaseURL host] port:[newBaseURL.port unsignedShortValue] path:[newBaseURL path]];
}

@end
