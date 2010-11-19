//
//  AppUtilities.m
//  Sidestep
//
//  Created by Chetan Surpur on 11/18/10.
//  Copyright 2010 Chetan Surpur. All rights reserved.
//


#include "AppUtilities.h"
#import "Configurations.h"

@implementation AppUtilities

void _XLog(CFAbsoluteTime *lastTime, NSString *format, va_list argList) 
{
	
	//CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
	//static unsigned logcount = 0;
	//if (logcount++ % 100 == 0) NSLog(@"logcount: %i", logcount);
	static CFTimeZoneRef zone = nil;
	if (!zone) zone = CFTimeZoneCopyDefault();
	
	/*
	CFGregorianDate date = CFAbsoluteTimeGetGregorianDate(time, zone);
	if (lastTime) {
		double elapsed_time = time - *lastTime;
		unsigned total_sec = elapsed_time;
		double fraction = elapsed_time - (double)total_sec;
		unsigned milli = fraction * 1000.0f;
		unsigned micro = fraction * 1000000.0f;
		micro %= 1000;
		// log elapsed time [sec.ms_us|pid]
		NSLog(@"[%03i.%03i_%03i|%i] ", total_sec, milli, micro, getpid());
	} else {
		unsigned sec = date.second;
		double fraction = date.second - (double)sec;
		unsigned milli = fraction * 1000.0f;
		// log standard time [hours:min:sec.ms|pid]
		NSLog(@"[%02i:%02i:%02i.%03i|%i] ", date.hour, date.minute, sec, milli, getpid());
	}
	 */
	
	CFStringRef log = CFStringCreateWithFormatAndArguments(NULL, NULL, (CFStringRef)format, argList);
	char *ptr = (char *)CFStringGetCStringPtr(log, kCFStringEncodingUTF8);
	if (ptr) 	
		NSLog(@"%s\n", ptr);
	else {
		unsigned buflen = CFStringGetLength(log) * 4;
		ptr = malloc(buflen);
		if (CFStringGetCString(log, ptr, buflen, kCFStringEncodingUTF8));
		NSLog(@"%s\n", ptr);
		free(ptr);
	}
	CFRelease(log);
	
}

void XLog(id object, NSString *format, ...) {
	format = [NSString stringWithFormat:@"%@ - %@", [object className], format];
	if (debuggingEnabled) {
		va_list argList;
		va_start(argList, format);
		_XLog(nil, format, argList);
		va_end(argList);
	}
}

void XFTimeLog(id object, CFAbsoluteTime *time, NSString *format, ...)
{
	format = [NSString stringWithFormat:@"%@ - %@", [object className], format];
	if (debuggingEnabled) {
		va_list argList;
		va_start(argList, format);
		_XLog(time, format, argList);
		va_end(argList);
        
		if (time) *time = CFAbsoluteTimeGetCurrent();
	}
}

- (bool) object: (NSObject *) object existsInArray: (NSArray *) array
{
    int loopIter = 0;
    while (loopIter < [array count])
    {
        if ([[array objectAtIndex:loopIter] isEqualTo:object]) return true;
        loopIter++;
    }
    return false;
}

@end