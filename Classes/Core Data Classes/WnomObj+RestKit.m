// 
//  WnomObj.m
//  Created by Gregory Combs on 7/22/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "WnomObj+RestKit.h"
#import "LegislatorObj.h"
#import "TexLegeCoreDataUtils.h"

@implementation WnomObj (RestKit)


#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"wnomID", @"wnomID",
			@"legislatorID", @"legislatorID",
			@"wnomAdj", @"wnomAdj",
			@"session", @"session",
			@"wnomStderr", @"wnomStderr",
			@"adjMean", @"adjMean",
			@"updated", @"updatedDate",
			nil];
}

+ (NSDictionary*)relationshipToPrimaryKeyPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"legislator", @"legislatorID",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"wnomID";
}


#pragma mark Custom Accessors

- (NSNumber *) year {
	return [NSNumber numberWithInteger:1847+(2*[self.session integerValue])];
}

@end
