//
//  MapViewController.m
//  Created by Gregory Combs on 8/16/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "MapViewController.h"
#import "TexLegeTheme.h"
#import "UtilityMethods.h"
#import "LegislatorDetailViewController.h"
#import "DistrictOfficeObj+MapKit.h"
#import "DistrictMapObj+MapKit.h"
#import "DistrictMapDataSource.h"

#import "UserPinAnnotation.h"
#import "UserPinAnnotationView.h"

#import "TexLegeAppDelegate.h"
#import "TexLegeCoreDataUtils.h"

#import "LocalyticsSession.h"
#import "UIColor-Expanded.h"

#import "TexLegeMapPins.h"
#import "DistrictPinAnnotationView.h"
#import <CoreLocation/CoreLocation.h>

@interface MapViewController()
@property (nonatomic,assign,getter=isLocationServicesDenied) BOOL locationServicesDenied;
@property (nonatomic,assign) BOOL wantsUserLocation;
@property (nonatomic,retain) CLGeocoder *clGeocoder;
@property (nonatomic,retain) CLRegion *texasAreaRegion;
@property (nonatomic,retain) CLLocationManager *locationManager;

@end

static MKCoordinateSpan kStandardZoomSpan = {2.f, 2.f};

@implementation MapViewController
@synthesize mapTypeControl, mapTypeControlButton;
@synthesize mapView, userLocationButton, searchLocation;
@synthesize toolbar, searchBar, searchBarButton, districtOfficesButton;
@synthesize texasRegion;
@synthesize senateDistrictView, houseDistrictView;
@synthesize masterPopover;
@synthesize genericOperationQueue;
@synthesize colorIndex=colorIndex;
@synthesize clGeocoder = _clGeocoder;
@synthesize texasAreaRegion = _texasAreaRegion;
@synthesize locationManager = _locationManager;

#pragma mark -
#pragma mark Initialization and Memory Management

- (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"MapViewController~ipad";
	else
		return @"MapViewController~iphone";
}

- (void) dealloc {
	//[self invalidateDistrictView:BOTH_CHAMBERS];
	
	/*if (self.mapView) {
		[self.mapView removeAnnotations:self.mapView.annotations];
		[self.mapView removeOverlays:self.mapView.overlays];
	}*/
	self.mapView = nil;

    if (self.clGeocoder) {
        [self.clGeocoder cancelGeocode];
        self.clGeocoder = nil;
    }
	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
	
	self.mapTypeControl = nil;
	self.searchBarButton = nil;
	self.mapTypeControlButton = nil;
	self.userLocationButton = nil;
	self.districtOfficesButton = nil;
	self.searchBar = nil;
	self.masterPopover = nil;
	self.searchLocation = nil;
    self.texasAreaRegion = nil;
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
    self.locationManager = nil;
	[super dealloc];
}

- (void) didReceiveMemoryWarning {	
	[self clearOverlaysExceptRecent];

	[super didReceiveMemoryWarning];
}

- (void) viewDidLoad {
	[super viewDidLoad];
		
	colorIndex = 0;

    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _locationManager.distanceFilter = 3000;
    _locationManager.delegate = self;

    _clGeocoder = [[CLGeocoder alloc] init];

	[self.view setBackgroundColor:[TexLegeTheme backgroundLight]];
	self.mapView.showsUserLocation = NO;
    self.mapView.showsBuildings = YES;
	
	// Set up the map's region to frame the state of Texas.
	// Zoom = 6
	self.mapView.region = self.texasRegion;
	
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	self.toolbar.tintColor = [TexLegeTheme navbar];
	self.searchBar.tintColor = [TexLegeTheme navbar];
	if ([UtilityMethods isIPadDevice]) {
		self.navigationItem.titleView = self.toolbar; 
	}
	else {
		self.hidesBottomBarWhenPushed = YES;
		self.navigationItem.titleView = self.searchBar;
	}
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	longPressRecognizer.delegate = self;
	[self.mapView addGestureRecognizer:longPressRecognizer];        
	[longPressRecognizer release];
	
	
}

- (void) viewDidUnload {	

    if (self.clGeocoder)
    {
        [self.clGeocoder cancelGeocode];
        self.clGeocoder = nil;
    }

	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
	
	[super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
		
	NSURL *tempURL = [NSURL URLWithString:[UtilityMethods texLegeStringWithKeyPath:@"ExternalURLs.googleMapsWeb"]];		
	if (![TexLegeReachability canReachHostWithURL:tempURL])// do we have a good URL/connection?
		return;
}

- (void) viewDidDisappear:(BOOL)animated {
	[self.mapView removeOverlays:self.mapView.overlays];	// frees up memory
	
	[super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Animation and Zoom

- (void) clearAnnotationsAndOverlays {
	[self.mapView removeOverlays:self.mapView.overlays];
	[self.mapView removeAnnotations:self.mapView.annotations];
}

- (void) clearAnnotationsAndOverlaysExcept:(id)keep {
	NSMutableArray *annotes = [[NSMutableArray alloc] initWithCapacity:[self.mapView.annotations count]];
	for (id object in self.mapView.annotations) {
		if (![object isEqual:keep])
			[annotes addObject:object];
	}
	if (annotes && [annotes count]) {
		[self.mapView removeOverlays:self.mapView.overlays];
		[self.mapView removeAnnotations:annotes];
	}
	[annotes release];
}

- (void) clearOverlaysExceptRecent {
	NSMutableArray *toRemove = [[NSMutableArray alloc] init];
	if (toRemove) {
		[toRemove setArray:self.mapView.overlays];
		if ([toRemove count]>2) {
			[toRemove removeLastObject];
			[toRemove removeLastObject];
			[self.mapView removeOverlays:toRemove];
		}
		[toRemove release];
	}
}

- (void) resetMapViewWithAnimation:(BOOL)animated {
	[self clearAnnotationsAndOverlays];
	if (animated)
		[self.mapView setRegion:self.texasRegion animated:YES];
	else
		[self.mapView setRegion:self.texasRegion animated:NO];
	
}

- (void)animateToState
{    
    [self.mapView setRegion:self.texasRegion animated:YES];
}

- (void)animateToAnnotation:(id<MKAnnotation>)annotation
{
	if (!annotation)
		return;
	
    MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, kStandardZoomSpan);
    [self.mapView setRegion:region animated:YES];	
}

- (void)moveMapToAnnotation:(id<MKAnnotation>)annotation {
	if (masterPopover)
		[masterPopover dismissPopoverAnimated:YES];
	
	if (![self region:self.mapView.region isEqualTo:self.texasRegion]) { // it's another region, let's zoom out/in
		[self performSelector:@selector(animateToState) withObject:nil afterDelay:0.3];
		[self performSelector:@selector(animateToAnnotation:) withObject:annotation afterDelay:1.7];        
	}
	else
		[self performSelector:@selector(animateToAnnotation:) withObject:annotation afterDelay:0.7];	
}

#pragma mark -
#pragma mark Gesture Recognizer

#pragma mark Handling long presses

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	id theView = gestureRecognizer.view;

	if ([theView isKindOfClass:[MKPinAnnotationView class]])
		return NO;
	else if ([theView isKindOfClass:[MKMapView class]])
		return YES;
	else
		return NO;

}

-(void)handleLongPress:(UILongPressGestureRecognizer*)longPressRecognizer {
    
    /*
     For the long press, the only state of interest is Began.
     If there is a row at the location, create a suitable menu controller and display it.
     */
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressRecognizer locationInView:self.mapView];
		CLLocationCoordinate2D touchCoord = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
		
		[self clearAnnotationsAndOverlays];
		
		[self.mapView setCenterCoordinate:touchCoord animated:YES];
		
		[self geocodeAddressWithCoordinate:touchCoord];
    }
}

#pragma mark -
#pragma mark Popover Support


- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
    barButtonItem.title = NSLocalizedStringFromTable(@"District Maps", @"StandardUI", @"Short name for district maps tab");
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    self.masterPopover = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	//debug_NSLog(@"Entering landscape, hiding the button: %@", [aViewController class]);
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    self.masterPopover = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
	if ([UtilityMethods isLandscapeOrientation]) {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"ERR_POPOVER_IN_LANDSCAPE"];
	}		 
}	


#pragma mark -
#pragma mark Properties

- (MKCoordinateRegion) texasRegion {
	// Set up the map's region to frame the state of Texas.
	// Zoom = 6	
	static CLLocationCoordinate2D texasCenter = {31.709476f, -99.997559f};
	static MKCoordinateSpan texasSpan = {10.f, 10.f};
	const MKCoordinateRegion txreg = MKCoordinateRegionMake(texasCenter, texasSpan);
	return txreg;
}

- (BOOL) region:(MKCoordinateRegion)region1 isEqualTo:(MKCoordinateRegion)region2 {
	MKMapPoint coord1 = MKMapPointForCoordinate(region1.center);
	MKMapPoint coord2 = MKMapPointForCoordinate(region2.center);
	BOOL coordsEqual = MKMapPointEqualToPoint(coord1, coord2);
	
	BOOL spanEqual = region1.span.latitudeDelta == region2.span.latitudeDelta; // let's just only do one, okay?
	return (coordsEqual && spanEqual);
}

#pragma mark -
#pragma DistrictMapSearchOperationDelegate

- (void) searchDistrictMapsForCoordinate:(CLLocationCoordinate2D)aCoordinate {	

	NSArray *list = [TexLegeCoreDataUtils allDistrictMapIDsWithBoundingBoxesContaining:aCoordinate];
	
	DistrictMapSearchOperation *op = [[DistrictMapSearchOperation alloc] initWithDelegate:self 
																			   coordinate:aCoordinate 
																				searchDistricts:list];
	if (op) {
		if (!self.genericOperationQueue)
			self.genericOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
		[self.genericOperationQueue addOperation:op];
		[op release];
	}
}

- (void)districtMapSearchOperationDidFinishSuccessfully:(DistrictMapSearchOperation *)op {	
	//debug_NSLog(@"Found some search results in %d districts", [op.foundDistricts count]);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	for (NSNumber *districtID in op.foundIDs) {
		DistrictMapObj *district = [DistrictMapObj objectWithPrimaryKeyValue:districtID];
		if (district) {
			[self.mapView addAnnotation:district];

            __block MapViewController *bself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!bself)
                    return;
                [bself.mapView addOverlay:district.polygon];
            });

			[[DistrictMapObj managedObjectContext] refreshObject:district mergeChanges:NO];	// re-fault it to free memory
		}
	}	
	
	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
	
	[pool drain];
}

- (void)districtMapSearchOperationDidFail:(DistrictMapSearchOperation *)op 
							 errorMessage:(NSString *)errorMessage 
								   option:(DistrictMapSearchOperationFailOption)failOption {	
	
	if (failOption == DistrictMapSearchOperationFailOptionLog) {
		NSLog(@"%@", errorMessage);
	}
	
	if (self.genericOperationQueue)
		[self.genericOperationQueue cancelAllOperations];
	self.genericOperationQueue = nil;
}

#pragma mark -
#pragma mark Control Element Actions

- (IBAction)changeMapType:(id)sender {
	NSInteger index = self.mapTypeControl.selectedSegmentIndex;
	self.mapView.mapType = index;
}

- (void)showLocateUserButton {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	UIBarButtonItem *locateItem = [[UIBarButtonItem alloc] 
								   initWithImage:[UIImage imageNamed:@"locationarrow.png"]
									style:UIBarButtonItemStyleBordered
									target:self
									action:@selector(locateUser:)];

	locateItem.tag = 999;
    if (self.isLocationServicesDenied)
        locateItem.enabled = NO;
	
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.toolbar.items];

    __block NSUInteger buttonIndex = NSNotFound;
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIBarButtonItem *item = obj;
        if (item.tag == 999 || item.tag == 998)
        {
            *stop = YES;
            buttonIndex = idx;
        }
    }];

    if (buttonIndex != NSNotFound)
        [items removeObjectAtIndex:buttonIndex];
    else
        buttonIndex = 0;
	[items insertObject:locateItem atIndex:buttonIndex];

	self.userLocationButton = locateItem;
	[self.toolbar setItems:items animated:YES];
	[locateItem release];
	[items release];
}

- (void)showLocateActivityButton {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;


	UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	[activityIndicator startAnimating];
	UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
	[activityIndicator release];
	activityItem.tag = 998;
    if (self.isLocationServicesDenied)
        activityItem.enabled = NO;

	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:self.toolbar.items];

    __block NSUInteger buttonIndex = NSNotFound;
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIBarButtonItem *item = obj;
        if (item.tag == 999 || item.tag == 998)
        {
            *stop = YES;
            buttonIndex = idx;
        }
    }];

    if (buttonIndex != NSNotFound)
        [items removeObjectAtIndex:buttonIndex];
    else
        buttonIndex = 0;
    [items insertObject:activityItem atIndex:buttonIndex];

	[self.toolbar setItems:items animated:YES];
	[activityItem release];
	[items release];
}

- (IBAction)locateUser:(id)sender {
	[self clearAnnotationsAndOverlays];
	[self showLocateActivityButton];				// this gets changed in viewForAnnotation once we receive the location

    self.wantsUserLocation = YES;
	if ([self determineOrRequestLocationAuthorization])
    {
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark -
#pragma mark MapKit

- (void)setLocationServicesDenied:(BOOL)locationServicesDenied
{
    _locationServicesDenied = locationServicesDenied;
    if (_locationServicesDenied &&
        self.userLocationButton)
    {
        self.userLocationButton.enabled = NO;
    }
}

- (BOOL)determineOrRequestLocationAuthorization
{
    BOOL locationEnabled = NO;

    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusNotDetermined:
        {
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                [self.locationManager requestWhenInUseAuthorization];
            else
                [CLLocationManager locationServicesEnabled];
            break;
        }
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            self.locationServicesDenied = YES;
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            self.locationServicesDenied = NO;
            locationEnabled = YES;
            break;
        }
    }

    return locationEnabled;
}


#if 0 // can't get custom objects while using propertiesToFetch: anymore
- (IBAction) showAllDistricts:(id)sender {
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"SHOWING_ALL_DISTRICTS"];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *districts = [TexLegeCoreDataUtils allDistrictMapsLight];
	if (districts) {
		[self resetMapViewWithAnimation:YES];
		[self.mapView addAnnotations:districts];
	}
	[pool drain];
}
#endif

/*
- (IBAction) showAllDistrictOffices:(id)sender {
	
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"SHOWING_ALL_DISTRICT_OFFICES"];
	
	NSArray *districtOffices = [TexLegeCoreDataUtils allObjectsInEntityNamed:@"DistrictOfficeObj" context:self.managedObjectContext];
	if (districtOffices) {
		[self resetMapViewWithAnimation:YES];
		[self.mapView addAnnotations:districtOffices];
	}
}
*/


- (void)showLegislatorDetails:(LegislatorObj *)legislator
{
	if (!legislator)
		return;
	
	LegislatorDetailViewController *legVC = [[LegislatorDetailViewController alloc] initWithNibName:@"LegislatorDetailViewController" bundle:nil];
	legVC.legislator = legislator;
	[self.navigationController pushViewController:legVC animated:YES];
	[legVC release];
}


#pragma mark -
#pragma mark Geocoding

- (void) searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
	[self clearAnnotationsAndOverlays];
	[self geocodeCoordinateWithSearchAddress:theSearchBar.text];
}

- (CLRegion *)getCircularTexasRegion
{
    if (!self.texasAreaRegion)
        _texasAreaRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(31.391533, -99.170633) radius:700000 identifier:@"Area of Texas"];
    return self.texasAreaRegion;
}

- (BOOL)geocodeCoordinateWithSearchAddress:(NSString *)address {
    if (!address.length || self.clGeocoder.isGeocoding)
        return NO;

	[self showLocateActivityButton];

    CLRegion *circularTexas = [self getCircularTexasRegion];
    __block typeof(self) bself = self;
    [self.clGeocoder geocodeAddressString:address inRegion:circularTexas completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!bself)
            return;
        if (error || !placemarks.count)
        {
            [bself showLocateUserButton];
            NSLog(@"Geocoder error - unable to geocode location: (%@)", error);
            return;
        }
        [bself geocoderDidFindPlacemark:placemarks[0]];
    }];

    return YES;
}

- (BOOL)geocodeAddressWithCoordinate:(CLLocationCoordinate2D)newCoord
{
    if (!CLLocationCoordinate2DIsValid(newCoord) || self.clGeocoder.isGeocoding)
        return NO;

	[self showLocateActivityButton];

    CLLocation *location = [[[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude] autorelease];
    __block typeof(self) bself = self;
    [self.clGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!bself)
            return;
        if (error || !placemarks.count)
        {
            CLLocation *localLocation = [[CLLocation alloc] initWithLatitude:newCoord.latitude longitude:newCoord.longitude];
            [bself showLocateUserButton];
            NSLog(@"Geocoder error - unable to geocode location: %@ (%@)", localLocation, error);
            [localLocation release];
            return;
        }
        [bself geocoderDidFindPlacemark:placemarks[0]];
    }];

    return YES;
}

- (void)geocoderDidFindPlacemark:(CLPlacemark *)placemark
{
	NSLog(@"Geocoder found placemark: %@ (was %@)", placemark, self.searchLocation);
	[self showLocateUserButton];

///	[self clearAnnotationsAndOverlays];			??????

	if (self.searchLocation) {
		[self.mapView removeAnnotation:self.searchLocation];
		self.searchLocation = nil;
	}
	UserPinAnnotation *annotation = [[UserPinAnnotation alloc] initWithPlacemark:placemark];
	annotation.coordinateChangedDelegate = self;
	
	[self.mapView addAnnotation:annotation];
	[self searchDistrictMapsForCoordinate:annotation.coordinate];
	[self moveMapToAnnotation:annotation];
	
	self.searchLocation = annotation;
	[annotation release];
	
	// is this necessary??? because we will have just created the related annotation view, so we don't need to redisplay it.
	[[NSNotificationCenter defaultCenter] postNotificationName:kUserPinAnnotationAddressChangeKey object:self.searchLocation];
			
	[self.searchBar resignFirstResponder];
}

- (void)annotationCoordinateChanged:(id)sender {
	if (![sender isKindOfClass:[UserPinAnnotation class]])
		return;
	
	if (!self.searchLocation || ![sender isEqual:self.searchLocation])
		self.searchLocation = sender;
	
	[self clearAnnotationsAndOverlaysExcept:sender];

    if ([self geocodeAddressWithCoordinate:self.searchLocation.coordinate])
        [self searchDistrictMapsForCoordinate:self.searchLocation.coordinate];
}

#pragma mark -
#pragma mark MapViewDelegate

// Only in 4.0+
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	if (!self || !self.isViewLoaded || !self.mapView)
        return;

	NSString *message = [NSString stringWithFormat:
						 NSLocalizedStringFromTable(@"Failed to determine your geographic location due to the following: %@", @"AppAlerts", @""), 
						 [error localizedDescription]];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Geolocation Error", @"AppAlerts", @"Alert box title for an error")
													message:message
												   delegate:nil 
										  cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"StandardUI", @"Confirming a selection")
										  otherButtonTitles: nil];
	[alert show];
	[alert release];

    [self showLocateUserButton];
}

// Only in 4.0+
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!self || !self.isViewLoaded || !self.mapView)
        return;

    [self showLocateUserButton];
    if (!locations.count)
        return;

    CLLocation *foundLocation = [locations firstObject];

    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    [self searchDistrictMapsForCoordinate:foundLocation.coordinate];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (!self)
        return;
    if (status == kCLAuthorizationStatusAuthorizedAlways ||
        status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        self.locationServicesDenied = NO;
        if (self.wantsUserLocation)
            [self.locationManager startUpdatingLocation];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
	//if (oldState == MKAnnotationViewDragStateDragging)
	if (newState == MKAnnotationViewDragStateEnding)
	{
		if ([annotationView.annotation isEqual:self.searchLocation]) {
			if (self.searchLocation.coordinateChangedDelegate)
            {
				self.searchLocation.coordinateChangedDelegate = nil;		// it'll handle it once, then we'll do it.
			}
			else {
				debug_NSLog(@"MapView:didChangeDrag - when does this condition happen???");
				[self annotationCoordinateChanged:self.searchLocation];	
			}
		}
	}
}


- (void)mapView:(MKMapView *)theMapView didAddAnnotationViews:(NSArray *)views
{
}

- (void)mapView:(MKMapView *)theMapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	id <MKAnnotation,LegislatorAnnotation> annotation = (id<MKAnnotation,LegislatorAnnotation>)view.annotation;
	
    if ([annotation conformsToProtocol:@protocol(LegislatorAnnotation)])
    {
        LegislatorObj *legislator = [annotation legislator];
        if (legislator)
            [self showLegislatorDetails:legislator];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[DistrictOfficeObj class]] || [annotation isKindOfClass:[DistrictMapObj class]]) 
    {
        static NSString* districtAnnotationID = @"districtObjectAnnotationID";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:districtAnnotationID];
        if (!pinView)
        {
            DistrictPinAnnotationView* customPinView = [[[DistrictPinAnnotationView alloc]
												   initWithAnnotation:annotation reuseIdentifier:districtAnnotationID] autorelease];
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
            if ([pinView isKindOfClass:[DistrictPinAnnotationView class]])
            {
                [(DistrictPinAnnotationView *)pinView resetPinColorWithAnnotation:annotation];
            }
        }		

        return pinView;
    }
	
	if ([annotation isKindOfClass:[UserPinAnnotation class]])  
    {
        static NSString* customAnnotationIdentifier = @"customAnnotationIdentifier";
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:customAnnotationIdentifier];
        if (!pinView)
        {
            UserPinAnnotationView *customPinView = [[[UserPinAnnotationView alloc] initWithAnnotation:annotation
                                                                             reuseIdentifier:customAnnotationIdentifier] autorelease];            
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
	NSArray *colors = [[UIColor randomColor] triadicColors];
	UIColor *myColor = [[colors objectAtIndex:colorIndex] colorByDarkeningTo:0.50f];
	colorIndex++;
	if (colorIndex > 1)
		colorIndex = 0;
	
	if ([overlay isKindOfClass:[MKPolygon class]])
    {		
		BOOL senate = NO;
		
		NSString *ovTitle = [overlay title];
		if (ovTitle && [ovTitle hasSubstring:stringForChamber(HOUSE, TLReturnFull) caseInsensitive:NO]) {
			if (self.mapView.mapType > MKMapTypeStandard)
				myColor = [UIColor cyanColor];
			else
				myColor = [TexLegeTheme texasGreen];
			senate = NO;
		}
		else if (ovTitle && [ovTitle hasSubstring:stringForChamber(SENATE, TLReturnFull) caseInsensitive:NO]) {
			myColor = [TexLegeTheme texasOrange];
			senate = YES;
		}

		MKPolygonRenderer *aView = [[[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon*)overlay] autorelease];
		if (senate) {
			self.senateDistrictView = aView;
		}
		else {
			self.houseDistrictView = aView;
		}

		aView.fillColor = [myColor colorWithAlphaComponent:0.2];
        aView.strokeColor = [myColor colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
        return aView;
    }
	
	else if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer*    aView = [[[MKPolylineRenderer alloc] initWithPolyline:(MKPolyline*)overlay] autorelease];
				
        aView.strokeColor = myColor;// colorWithAlphaComponent:0.7];
        aView.lineWidth = 3;
		
        return aView;
    }
	
	return nil;
}



- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView
{
	
	id<MKAnnotation> annotation = aView.annotation;
	if (!annotation)
		return;
	
	if (![aView isSelected])
		return;
	
	[self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
	
	if ([annotation isKindOfClass:[UserPinAnnotation class]])
    {
		self.searchLocation = (UserPinAnnotation *)annotation;
	}	

	if ([annotation isKindOfClass:[DistrictMapObj class]])
    {
        DistrictMapObj *districtMap = (DistrictMapObj *)annotation;
        NSString *districtTitle = districtMap.title;

        MKCoordinateRegion region;
		region = [(DistrictMapObj *)annotation region];
		
		NSMutableArray *toRemove = [[NSMutableArray alloc] initWithArray:self.mapView.overlays];
		BOOL foundOne = NO;
		for (id<MKOverlay>item in self.mapView.overlays)
        {
            NSString *itemTitle = [item title];
            if (itemTitle.length && districtTitle.length)
            {
                if ([itemTitle isEqualToString:districtTitle])
                {	// we clicked on an existing overlay
                    if ([itemTitle isEqualToString:[self.senateDistrictView.polygon title]] ||
                        [itemTitle isEqualToString:[self.houseDistrictView.polygon title]])
                    {
                        [toRemove removeObject:item];
                        foundOne = YES;
                        break;
                    }
                }
            }
		}
		
		if (!IsEmpty(toRemove))
            [self.mapView removeOverlays:toRemove];
		[toRemove release];
		
		if (!foundOne) {
			MKPolygon *mapPoly = [(DistrictMapObj*)annotation polygon];

            __block MapViewController *bself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!bself)
                    return;
                [bself.mapView addOverlay:mapPoly];
            });

			[[DistrictMapObj managedObjectContext] refreshObject:(DistrictMapObj*)annotation mergeChanges:NO];
		}
		[self.mapView setRegion:region animated:TRUE];
	}			
}

#pragma mark -
#pragma mark Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation { // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
	return YES;
}

@end
