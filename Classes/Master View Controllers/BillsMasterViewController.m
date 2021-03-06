//
//  BillsMasterViewController.m
//  Created by Gregory Combs on 2/6/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsMasterViewController.h"
#import "BillsDetailViewController.h"
#import "UtilityMethods.h"

#import "TexLegeAppDelegate.h"
#import "TableDataSourceProtocol.h"

#import "TexLegeTheme.h"
#import "OpenLegislativeAPIs.h"

#import "BillsMenuDataSource.h"
#import "BillSearchDataSource.h"
#import "OpenLegislativeAPIs.h"
#import "LocalyticsSession.h"

#import <objc/message.h>

#define LIVE_SEARCHING 1

@interface BillsMasterViewController (Private)
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;
@end

@implementation BillsMasterViewController
@synthesize billSearchDS;

// Set this to non-nil whenever you want to automatically enable/disable the view controller based on network/host reachability
- (NSString *)reachabilityStatusKey {
	return @"openstatesConnectionStatus";
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.billSearchDS = nil;

	[super dealloc];
}

- (NSString *)nibName {
	return NSStringFromClass([self class]);
}

/*- (void)loadView {	
	[super runLoadView];
}*/

- (void)viewDidLoad {
	[super viewDidLoad];
		
	if (!self.billSearchDS)
		self.billSearchDS = [[[BillSearchDataSource alloc] initWithSearchDisplayController:self.searchDisplayController] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData:) name:kBillSearchNotifyDataLoaded object:billSearchDS];	
	
	self.searchDisplayController.searchBar.tintColor = [TexLegeTheme accent];	
	
	self.searchDisplayController.searchBar.scopeButtonTitles = [NSArray arrayWithObjects:
																stringForChamber(BOTH_CHAMBERS, TLReturnFull),
																stringForChamber(HOUSE, TLReturnFull),
																stringForChamber(SENATE, TLReturnFull),
																nil];

#if 0
	if ([UtilityMethods isIPadDevice]) {
		self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);

		/* This "avoids" a bug on iPads where the scope bar get's crammed into the top line in landscape. */
		if ([self.searchDisplayController.searchBar respondsToSelector:@selector(setCombinesLandscapeBars:)]) 
		{ 
			objc_msgSend(self.searchDisplayController.searchBar, @selector(setCombinesLandscapeBars:), NO );
		}
	}
#endif
		
/*	for (id subview in self.searchDisplayController.searchBar.subviews )
	{
		if([subview isMemberOfClass:[UISegmentedControl class]])
		{
			UISegmentedControl *scopeBar=(UISegmentedControl *) subview;
			scopeBar.segmentedControlStyle = UISegmentedControlStyleBar; //required for color change
			scopeBar.tintColor =  [TexLegeTheme accent];         
		}
	}
*/	
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.billSearchDS = nil;
	
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
	UINavigationController *nav = [self navigationController];
	if (nav && [nav.viewControllers count]>3) {
		[nav popToRootViewControllerAnimated:YES];
	}
	
	[super didReceiveMemoryWarning];
}

- (void)reloadData:(NSNotification *)notification {
	[self.tableView reloadData];
	if (self.searchDisplayController.searchResultsTableView)
		[self.searchDisplayController.searchResultsTableView reloadData];
}

- (Class)dataSourceClass {
	return [BillsMenuDataSource class];
}

- (void)viewWillAppear:(BOOL)animated
{	
	[super viewWillAppear:animated];
	
	// this has to be here because GeneralTVC will overwrite it once anyone calls self.dataSource,
	//		if we remove this, it will wind up setting our searchResultsDataSource to the BillsMenuDataSource
	self.searchDisplayController.searchResultsDataSource = self.billSearchDS;	
	[self.searchDisplayController.searchBar setHidden:NO];

#if LIVE_SEARCHING == 0
	self.searchDisplayController.searchBar.delegate = self;
#endif
	
	if ([UtilityMethods isIPadDevice])
		[self.tableView reloadData];
}

#pragma -
#pragma UITableViewDelegate

// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath withAnimation:(BOOL)animated {
	TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
	
	if (![UtilityMethods isIPadDevice])
		[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];
	
	BOOL isSplitViewDetail = ([UtilityMethods isIPadDevice]) && (self.splitViewController != nil);
	
	//if (!isSplitViewDetail)
	//	self.navigationController.toolbarHidden = YES;
	
	id dataObject = nil;
	BOOL changingDetails = NO;

//	IF WE'RE CLICKING ON SOME SEARCH RESULTS ... PULL UP THE BILL DETAIL VIEW CONTROLLER
	if (aTableView == self.searchDisplayController.searchResultsTableView) { // we've clicked in a search table
		dataObject = [self.billSearchDS dataObjectForIndexPath:newIndexPath];
		//[self searchBarCancelButtonClicked:nil];
		
		if (dataObject) {

			if (!self.detailViewController || ![self.detailViewController isKindOfClass:[BillsDetailViewController class]]) {
				self.detailViewController = [[[BillsDetailViewController alloc] initWithNibName:@"BillsDetailViewController" bundle:nil] autorelease];
				changingDetails = YES;
			}
			if ([self.detailViewController respondsToSelector:@selector(setDataObject:)])
				[self.detailViewController performSelector:@selector(setDataObject:) withObject:dataObject];
			
			[[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:[dataObject objectForKey:@"bill_id"] 
																			   session:[dataObject objectForKey:@"session"] 
																			  delegate:self.detailViewController];			
			if (isSplitViewDetail == NO) {
				// push the detail view controller onto the navigation stack to display it				
				[self.navigationController pushViewController:self.detailViewController animated:YES];
				self.detailViewController = nil;
			}
			else if (changingDetails)
				[[[TexLegeAppDelegate appDelegate] detailNavigationController] setViewControllers:[NSArray arrayWithObject:self.detailViewController] animated:NO];
		}			
	}
//	WE'RE CLICKING ON ONE OF OUR STANDARD MENU ITEMS
	else {
		dataObject = [self.dataSource dataObjectForIndexPath:newIndexPath];
	
		// save off this item's selection to our AppDelegate
		[appDelegate setSavedTableSelection:newIndexPath forKey:NSStringFromClass([self class])];
	
		if (!dataObject || ![dataObject isKindOfClass:[NSDictionary class]])
			return;

		NSString *theClass = [dataObject objectForKey:@"class"];
		if (!theClass || !NSClassFromString(theClass))
			return;
		
		UITableViewController *tempVC = nil;
		tempVC = [[[NSClassFromString(theClass) alloc] initWithStyle:UITableViewStylePlain] autorelease];	// we don't want a nib for this one
		
		if (aTableView == self.searchDisplayController.searchResultsTableView) { // we've clicked in a search table
			[self searchBarCancelButtonClicked:nil];
		}
		
		NSDictionary *tagMenu = [[NSDictionary alloc] initWithObjectsAndKeys:theClass, @"FEATURE", nil];
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"BILL_MENU" attributes:tagMenu];
		[tagMenu release];
		
		// push the detail view controller onto the navigation stack to display it				
		[self.navigationController pushViewController:tempVC animated:YES];
	}
}

#pragma mark -
#pragma mark Search Distplay Controller

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
#if LIVE_SEARCHING == 1
	nice_release(_searchString);

	if (searchString && [searchString length]) {
		_searchString = [searchString copy];
		if (_searchString && [_searchString length] >= 3) {
			[self.billSearchDS startSearchForText:_searchString chamber:self.searchDisplayController.searchBar.selectedScopeButtonIndex];
		}		
	}
#endif
	return NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
	if (!controller || !controller.searchBar || !controller.searchBar.text || ![controller.searchBar.text length]) 
		return NO;
	
	nice_release(_searchString);

	_searchString = [controller.searchBar.text copy];
	[self.billSearchDS startSearchForText:_searchString chamber:searchOption];
	return NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	nice_release(_searchString);

	_searchString = [[NSString alloc] initWithString:@""];

	self.searchDisplayController.searchBar.text = _searchString;
	[self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
#if LIVE_SEARCHING == 0
	if (IsEmpty(searchBar.text)) 
		return;
	
	nice_release(_searchString);

	_searchString = [searchBar.text copy];
	//if ([_searchString length] >= 3) {
		[self.billSearchDS startSearchForText:_searchString 
										 chamber:self.searchDisplayController.searchBar.selectedScopeButtonIndex];
	//}		
#endif
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
	////////self.dataSource.hideTableIndex = YES;
	// for some reason, these get zeroed out after we restart searching.
	if (self.tableView && self.searchDisplayController.searchResultsTableView) {
		self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
		self.searchDisplayController.searchResultsTableView.backgroundColor = self.tableView.backgroundColor;
		self.searchDisplayController.searchResultsTableView.sectionIndexMinimumDisplayRowCount = self.tableView.sectionIndexMinimumDisplayRowCount;
	}
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
	////////self.dataSource.hideTableIndex = NO;
}
@end
