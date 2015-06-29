//
//  RKAlert.m
//  RestKit
//
//  Created by Blake Watters on 4/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

@import UIKit;

#import "RKAlert.h"

void RKAlert(NSString* message) {
    RKAlertWithTitle(message, @"Alert");
}

void RKAlertWithTitle(NSString* message, NSString* title) {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}
