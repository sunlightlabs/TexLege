/*
 *  OpenLegislativeAPIs.h
 *  TexLege
 *
 *  Created by Gregory Combs on 3/18/11.
 *  Copyright 2011 Gregory S. Combs. All rights reserved.
 *
 */

#import <RestKit/RestKit.h>

extern NSString * const osApiHost;
extern NSString * const osApiBaseURL;
extern NSString * const transApiBaseURL;
extern NSString * const vsApiBaseURL;
extern NSString * const tloApiHost;
extern NSString * const tloApiBaseURL;

@interface OpenLegislativeAPIs : NSObject <RKRequestDelegate> {
	RKClient *osApiClient;	
	RKClient *transApiClient;
	RKClient *vsApiClient;
	RKClient *tloApiClient;
}
+ (OpenLegislativeAPIs *)sharedOpenLegislativeAPIs;
@property (nonatomic, retain) RKClient *osApiClient;
@property (nonatomic, retain) RKClient *transApiClient;
@property (nonatomic, retain) RKClient *vsApiClient;
@property (nonatomic, retain) RKClient *tloApiClient;

- (void)queryOpenStatesBillWithID:(NSString *)billID session:(NSString *)session delegate:(id)sender;


@end