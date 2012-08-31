//
//  NSNull+DontCrash.m
//  Jukaela
//
//  Created by Josh on 8/31/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "NSNull+DontCrash.h"

#define PrintAccessLog(selector) \
if (warnsOnNullAccess) { \
NSLog(@"Attempting to access null value from \"%@\": %@", NSStringFromSelector(selector), [NSThread callStackSymbols]); \
}

@implementation NSNull (DontCrash)

static BOOL warnsOnNullAccess = YES;
+ (void) setWarnsOnNullAccess:(BOOL) shouldWarnOnNullAccess {
	warnsOnNullAccess = shouldWarnOnNullAccess;
}

#pragma mark -

- (BOOL) boolValue {
	PrintAccessLog(_cmd)
    
	return NO;
}

- (char) charValue {
	PrintAccessLog(_cmd)
    
	return '\0';
}

- (NSDecimal) decimalValue {
	PrintAccessLog(_cmd)
    
	return [[NSDecimalNumber zero] decimalValue];
}

- (double) doubleValue {
	PrintAccessLog(_cmd)
    
	return 0.0;
}

- (float) floatValue {
	PrintAccessLog(_cmd)
    
	return 0.0;
}

- (int) intValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (NSInteger) integerValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (long long) longLongValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (long) longValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (short) shortValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (unsigned char) unsignedCharValue {
	PrintAccessLog(_cmd)
    
	return '\0';
}

- (NSUInteger) unsignedIntegerValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (unsigned int) unsignedIntValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (unsigned long long) unsignedLongLongValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (unsigned long) unsignedLongValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (unsigned short) unsignedShortValue {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (id) valueForKey:(NSString *) key {
	PrintAccessLog(_cmd)
    
	return nil;
}

- (id) objectAtIndex:(NSUInteger) index {
	PrintAccessLog(_cmd)
    
	return nil;
}

- (id) objectAtIndexedSubscript:(NSUInteger) index {
	PrintAccessLog(_cmd)
    
	return nil;
}

- (NSUInteger) count {
	PrintAccessLog(_cmd)
    
	return 0;
}

- (id) objectForKey:(id) key {
	PrintAccessLog(_cmd)
    
	return nil;
}

- (id) objectForKeyedSubscript:(id) key {
	PrintAccessLog(_cmd)
    
	return nil;
}

- (NSUInteger) length {
	PrintAccessLog(_cmd)
    
	return 0;
}

@end
