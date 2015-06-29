//
//  TexLege_Prefix.pch
//  Created by Gregory Combs on 7/22/09.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

//
// Prefix header for all source files of the 'TexLege' target in the 'TexLege' project
//

@import Foundation;
@import UIKit;
@import CoreData;

//#import "VTPGAdvancedLog.h"
#import "Constants.h"
#import "TexLegeLibrary.h"
#import "TexLegePrivateStrings.h"

#ifdef DEBUG
#define debug_NSLog(format, ...) do { NSLog(format, ## __VA_ARGS__); } while(0)
#else
#define debug_NSLog(format, ...) do {} while(0)
#endif

#define nice_release(var) if (var) [var release], var = nil
