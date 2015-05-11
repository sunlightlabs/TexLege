//
//  TXLDetailProtocol.h
//  TexLege
//
//  Created by Gregory Combs on 5/10/15.
//  Copyright (c) 2015 Gregory S. Combs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TXLDetailProtocol <NSObject>

- (id)dataObject;
- (void)setDataObject:(id)newObj;

@optional

- (IBAction)resetTableData:(id)sender;
@property (nonatomic,retain) UIPopoverController *masterPopover;

@end
