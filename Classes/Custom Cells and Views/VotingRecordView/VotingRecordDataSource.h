//
//  VotingRecordDataSource.h
//  Created by Gregory Combs on 3/25/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <Foundation/Foundation.h>
#import "S7GraphView.h"


@interface VotingRecordDataSource : NSObject <S7GraphViewDataSource,S7GraphViewDelegate>{
	NSNumber *legislatorID;
	NSDictionary *chartData;
}
@property (nonatomic,retain) NSNumber *legislatorID;
@property (nonatomic,retain) NSDictionary *chartData;

- (void)prepareVotingRecordView:(S7GraphView *)aView;

@end
