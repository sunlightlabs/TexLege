// 
//  LinkObj.m
//  Created by Gregory Combs on 7/10/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LinkObj+RestKit.h"
#import "UtilityMethods.h"

@implementation LinkObj (RestKit)

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"sortOrder", @"sortOrder",
			@"url", @"url",
			@"label", @"label",
			@"section", @"section",
			@"updated", @"updatedDate",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"sortOrder";
}


#pragma mark Custom Accessors

- (NSURL *) actualURL {	
	NSURL * actualURL = nil;
	NSString *followTheMoney = [UtilityMethods texLegeStringWithKeyPath:@"ExternalURLs.nimspWeb"];

	if ([self.url isEqualToString:@"aboutView"]) {
		NSString *file = nil;

		if ([UtilityMethods isIPadDevice])
			file = @"TexLegeInfo~ipad.htm";
		else
			file = @"TexLegeInfo~iphone.htm";
		
		NSURL *baseURL = [UtilityMethods urlToMainBundle];
		actualURL = [NSURL URLWithString:file relativeToURL:baseURL];
	}
	else if ([self.url hasPrefix:followTheMoney]) {		
		actualURL = [NSURL URLWithString:followTheMoney];
	}
	else if ([self.url hasPrefix:@"mailto:"]) {
		actualURL = nil;
	}
	else if (self.url) {
		actualURL = [NSURL URLWithString:self.url];
	}
	
	return actualURL;	
}

@end
