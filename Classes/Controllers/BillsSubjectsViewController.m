//
//  BillsSubjectsViewController.m
//  Created by Greg Combs on 12/1/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsSubjectsViewController.h"
#import "SLFDataModels.h"
#import "SLFTheme.h"
#import "SLFRestKitManager.h"
#import "BillsViewController.h"
#import "BillSearchParameters.h"
#import "SLFBadgeCell.h"

@interface BillsSubjectsViewController()
- (void)configureTableViewModel;
- (void)configureStandaloneChamberScopeBar;
- (void)chamberScopeSelectedIndexDidChange:(UISegmentedControl *)scopeBar;
@end

@implementation BillsSubjectsViewController
@synthesize state;
@synthesize tableViewModel = __tableViewModel;

- (id)initWithState:(SLFState *)newState {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Subjects", @"");
        [self reconfigureForState:newState];
    }
    return self;
}

- (void)dealloc {
	self.state = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    self.tableViewModel = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.opaque = YES;
    [self configureStandaloneChamberScopeBar];
    [self configureTableViewModel];
    if (self.state) {
        self.title = [NSString stringWithFormat:@"%@ %@", self.state.name, NSLocalizedString(@"Subjects",@"")];
        [self reconfigureForState:self.state];
    }
}

- (void)reconfigureForState:(SLFState *)newState {
    self.state = newState;
    if (!newState || !self.tableViewModel)
        return;
    NSInteger chamberScope = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
    NSString *chamber = [SLFChamber chamberTypeForSearchScopeIndex:chamberScope];
    NSString *resourcePath = [BillSearchParameters pathForSubjectsWithState:newState chamber:chamber];
    [__tableViewModel loadTableFromResourcePath:resourcePath withBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.cacheTimeoutInterval = SLF_HOURS_TO_SECONDS(12);
        objectLoader.objectMapping = [BillsSubjectsEntry mapping];
    }];
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.state];
}

- (void)configureTableViewModel {
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    __tableViewModel.delegate = self;
    __tableViewModel.objectManager = [RKObjectManager sharedManager];
    __tableViewModel.pullToRefreshEnabled = YES;
    
    RKTableViewCellMapping *objCellMap = [RKTableViewCellMapping cellMappingWithBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.cellClass = [SLFBadgeCell class];
        [cellMapping mapKeyPath:@"self" toAttribute:@"subjectEntry"];
        cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            SLFAlternateCellForIndexPath(cell, indexPath);
        };
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
            if (!object || ![object isKindOfClass:[BillsSubjectsEntry class]])
                return;
            if ([cell respondsToSelector:@selector(isClickable)]) {
                BOOL clickable = [[cell valueForKey:@"isClickable"] boolValue];
                if (!clickable)
                    return;
            }
            BillsSubjectsEntry *subject = object;
            NSInteger chamberScope = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
            NSString *chamber = [SLFChamber chamberTypeForSearchScopeIndex:chamberScope];
            NSString *resourcePath = [BillSearchParameters pathForSubject:subject.name chamber:chamber];
            BillsViewController *vc = [[BillsViewController alloc] initWithState:self.state resourcePath:resourcePath];
            if (IsEmpty(chamber))
                vc.title = [NSString stringWithFormat:@"%@ %@ Bills", self.state.name, subject.name];
            else {
                NSString *chamberName = [SLFChamber chamberWithType:chamber forState:self.state].shortName;
                vc.title = [NSString stringWithFormat:@"%@ %@ %@ Bills", [self.state.stateID uppercaseString], chamberName, subject.name];
            }
            [self stackOrPushViewController:vc];
            [vc release];
        };
    }];
    [__tableViewModel mapObjectsWithClass:[BillsSubjectsEntry class] toTableCellsWithMapping:objCellMap];
}

- (void)configureStandaloneChamberScopeBar {
    NSArray *buttonTitles = [SLFChamber chamberSearchScopeTitlesWithState:state];
    if (IsEmpty(buttonTitles))
        return;
    UISegmentedControl *scopeBar = [[UISegmentedControl alloc] initWithItems:buttonTitles];
    scopeBar.selectedSegmentIndex = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
    [scopeBar addTarget:self action:@selector(chamberScopeSelectedIndexDidChange:) forControlEvents:UIControlEventValueChanged];
    scopeBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    scopeBar.segmentedControlStyle = 7; // magic number (it's cheating)
    scopeBar.opaque = YES;
    CGFloat barOriginY = self.titleBarView.opticalHeight;
    CGFloat barHeight = scopeBar.height;
    CGFloat barWidth = self.tableView.bounds.size.width;
    scopeBar.origin = CGPointMake(0,barOriginY);
    scopeBar.size = CGSizeMake(barWidth, barHeight);
    CGRect tableRect = self.tableView.frame;
    tableRect.size.height -= (scopeBar.height);
    self.tableView.frame = CGRectOffset(tableRect, 0, scopeBar.height);
    [self.view addSubview:scopeBar];
    [scopeBar release];
}

- (void)chamberScopeSelectedIndexDidChange:(UISegmentedControl *)scopeBar {
    if (!scopeBar || ![scopeBar isKindOfClass:[UISegmentedControl class]])
        return;
    NSInteger selectedScope = scopeBar.selectedSegmentIndex;
    SLFSaveSelectedScopeIndexForKey(selectedScope, NSStringFromClass([self class]));
    [self reconfigureForState:self.state];
}

- (void)tableViewModelDidFinishLoad:(RKAbstractTableViewModel *)tableViewModel {
    // since we reload our table items, we can't use our usual finishLoading or risk an infinite loop.
    if (IsEmpty(tableViewModel.sections))
        return;
    RKTableViewSection *section = [tableViewModel sectionAtIndex:0];
    if (!section)
        return;
    NSArray *sortedObjects = [section.objects sortedArrayUsingDescriptors:[BillsSubjectsEntry sortDescriptors]];
    [__tableViewModel loadObjects:sortedObjects];
}

@end