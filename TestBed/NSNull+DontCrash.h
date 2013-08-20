//
//  NSNull+DontCrash.h
//  Jukaela
//
//  Created by Josh on 8/31/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

@import Foundation;

@interface NSNull (DontCrash)

+ (void) setWarnsOnNullAccess:(BOOL) warnsOnNullAccess;

- (BOOL) boolValue;
- (char) charValue;
- (NSDecimal) decimalValue;
- (double) doubleValue;
- (float) floatValue;
- (int) intValue;
- (NSInteger) integerValue;
- (long long) longLongValue;
- (long) longValue;
- (short) shortValue;
- (unsigned char) unsignedCharValue;
- (NSUInteger) unsignedIntegerValue;
- (unsigned int) unsignedIntValue;
- (unsigned long long) unsignedLongLongValue;
- (unsigned long) unsignedLongValue;
- (unsigned short) unsignedShortValue;

- (id) valueForKey:(NSString *) key;

- (id) objectAtIndex:(NSUInteger) index;
- (id) objectAtIndexedSubscript:(NSUInteger) index;
- (NSUInteger) count;

- (id) objectForKey:(id) key;
- (id) objectForKeyedSubscript:(id) key;
- (NSUInteger) length;

@end
