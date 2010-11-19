//
//  AppUtilities.h
//  Sidestep
//
//  Created by Chetan Surpur on 10/28/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppUtilities : NSObject 
{
}    
extern void XLog(id object, NSString *format, ...);
extern void XFTimeLog(id object, CFAbsoluteTime *time, NSString *format, ...);

// Loops thorugh an array checking if given object's value already
// exists in the given array.  If it does, returns true.
- (bool) object: (NSObject *) object existsInArray: (NSArray *) array;

@end