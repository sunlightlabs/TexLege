/*
 
 File: Reachability.h
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.1.2ddg
*/

/*
 Significant additions made by Andrew W. Donoho, August 11, 2009.
 This is a derived work of Apple's Reachability v2.0 class.
 
 The below license is the new BSD license with the OSI recommended personalizations.
 <http://www.opensource.org/licenses/bsd-license.php>
 
 Extensions Copyright (C) 2009 Donoho Design Group, LLC. All Rights Reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
 * Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of Andrew W. Donoho nor Donoho Design Group, L.L.C.
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY DONOHO DESIGN GROUP, L.L.C. "AS IS" AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
*/


/*
 
 Apple's Original License on Reachability v2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
*/

/*
 DDG extensions include:
 Each reachability object now has a copy of the key used to store it in a
 dictionary. This allows each observer to quickly determine if the event is
 important to them.
 
 -currentReachabilityStatus also has a significantly different decision criteria than 
 Apple's code.
 
 A multiple convenience test methods have been added. They are implemented as 
 properties. Hence, they now support KVC/KVO. KVO events are triggered
 when a network transition event occurs. (Due to the way SCNetworkReachability 
 is exposed to the application [and the way network events are totally 
 asynchronous to program events], the -willChangeValueForKey: method cannot be called 
 before the event occurs.)
 
 -touchHostWithPath: is a convenience routine to bring up the radios.
*/

#import <netinet/in.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define USE_DDG_EXTENSIONS 1 // Use DDG's Extensions to test network criteria.
// This is a moot #define. Apple's criteria have been removed from DDG's class.
// Since NSAssert and NSCAssert are used in this code, 
// I recommend you set NS_BLOCK_ASSERTIONS=1 in the release versions of your projects.

enum {
	
	// DDG NetworkStatus Constant Names.
	kNotReachable = 0, // Apple's code depends upon 'NotReachable' being the same value as 'NO'.
	kReachableViaWWAN, // Switched order from Apple's enum. WWAN is active before WiFi.
	kReachableViaWiFi
};
typedef	uint32_t NetworkStatus;

enum {
	
	// Apple NetworkStatus Constant Names.
	NotReachable     = kNotReachable,
	ReachableViaWiFi = kReachableViaWiFi,
	ReachableViaWWAN = kReachableViaWWAN
};


extern NSString *const kInternetConnection;
extern NSString *const kLocalWiFiConnection;
extern NSString *const kReachabilityChangedNotification;

// Key paths
extern NSString *const kReachableKey;
extern NSString *const kReachableViaWWANKey;
extern NSString *const kReachableViaWiFiKey;
extern NSString *const kConnectionRequiredKey;
extern NSString *const kConnectionOnDemandKey;
extern NSString *const kInterventionRequiredKey;

@interface Reachability: NSObject {
	
@private
	NSString *key_;
	NSObject *delegate_;
	
	SCNetworkReachabilityRef reachabilityRef_;
}

@property (copy)   NSString *key;
@property (assign) NSObject *delegate; // NSURLConnection delegate.

// The main direct test of reachability.
@property (readonly, getter=isReachable)            BOOL reachable;

// Routines for specific connection testing by your app.
@property (readonly, getter=isReachableViaWWAN)     BOOL reachableViaWWAN;
@property (readonly, getter=isReachableViaWiFi)     BOOL reachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
@property (readonly, getter=isConnectionRequired)   BOOL connectionRequired;

// Dynamic, on demand connection?
@property (readonly, getter=isConnectionOnDemand)   BOOL connectionOnDemand;

// Is user intervention required?
@property (readonly, getter=isInterventionRequired) BOOL interventionRequired;

// Designated Initializer.
- (Reachability *) initWithReachabilityRef: (SCNetworkReachabilityRef) ref;

// Comparison routines to enable choosing actions in a notification.
- (BOOL) isEqual: (Reachability *) r;

// Use to check the reachability of a particular host name. 
+ (Reachability *) reachabilityWithHostName: (NSString*) hostName;

// Use to check the reachability of a particular IP address. 
+ (Reachability *) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;

// Use to check whether the default route is available.  
// Should be used to, at minimum, establish network connectivity.
+ (Reachability *) reachabilityForInternetConnection;

// Use to check whether a local wifi connection is available.
+ (Reachability *) reachabilityForLocalWiFi;

//Start listening for reachability notifications on the current run loop.
- (BOOL) startNotifier;
- (void)  stopNotifier;

// These are the status tests in Apple's Reachability class. (Both v2.0 & v2.1)
- (NetworkStatus) currentReachabilityStatus;
- (BOOL) connectionRequired; // The Apple equivalent of -isConnectionRequired.

// To interpret these yourself.
- (SCNetworkReachabilityFlags) reachabilityFlags;

// Bring up the radios by touching the host.
//
// The path will be appended to the Reachability key/host. It can be nil or
// or any valid http path. ("/" or "/ping.html" for example).
// If "yourserver.com" is the key in your Reachability instance, 
// then the URL used is: <http://yourserver.com/ping.html>. 
//
// Set the delegate to catch the NSURLConnection delegate methods.
// Otherwise, the instance's delegate methods will cause log entries on success or failure.
//
- (void) touchHostWithPath: (NSString *) path synchronously: (BOOL) synchronous;

@end
