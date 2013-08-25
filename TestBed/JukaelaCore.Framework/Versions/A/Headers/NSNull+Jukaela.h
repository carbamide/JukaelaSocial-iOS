//
//  NSNull+DontCrash.h
//  JukaelaCore
//
//  Created by Josh on 8/31/12.
//  Copyright (c) 2013 Jukaela Enterprises.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@import Foundation;

/**
 A category on NSNull that tries to map all common calls that could occur when accidently calling NSNull
 */
@interface NSNull (DontCrash)

///---------------------------------------
/// @name Class Methods
///---------------------------------------

/** Causes NSNull to warn when a null value is being accessed
 @param warnsOnNullAccess Would you like NSNull to warn you when a null value has been accessed?
 */
+ (void)setWarnsOnNullAccess:(BOOL)warnsOnNullAccess;

///---------------------------------------
/// @name Instance Methods
///---------------------------------------

/** Non-null boolValue
 @return Non-null boolValue
 */
- (BOOL)boolValue;

/** Non-null charValue
 @return Non-null boolValue
 */
- (char)charValue;

/** Non-null decimalValue
 @return Non-null decimalValue
 */
- (NSDecimal)decimalValue;

/** Non-null doubleValue
 @return Non-null doubleValue
 */
- (double)doubleValue;

/** Non-null floatValue
 @return Non-null floatValue
 */
- (float)floatValue;

/** Non-null intValue
 @return Non-null intValue
 */
- (int)intValue;

/** Non-null integerValue
 @return Non-null integerValue
 */
- (NSInteger)integerValue;

/** Non-null longLongValue
 @return Non-null longLongValue
 */
- (long long)longLongValue;

/** Non-null longValue
 @return Non-null longValue
 */
- (long)longValue;

/** Non-null shortValue
 @return Non-null shortValue
 */
- (short)shortValue;

/** Non-null unsignedCharValue
 @return Non-null unsignedCharValue
 */
- (unsigned char)unsignedCharValue;

/** Non-null unsignedIntegerValue
 @return Non-null unsignedIntegerValue
 */
- (NSUInteger)unsignedIntegerValue;

/** Non-null unsignedIntValue
 @return Non-null unsignedIntValue
 */
- (unsigned int)unsignedIntValue;

/** Non-null unsignedLongLongValue
 @return Non-null unsignedLongLongValue
 */
- (unsigned long long)unsignedLongLongValue;

/** Non-null unsignedLongValue
 @return Non-null unsignedLongValue
 */
- (unsigned long)unsignedLongValue;

/** Non-null unsignedShortValue
 @return Non-null unsignedShortValue
 */
- (unsigned short)unsignedShortValue;

/** Non-null valueForKey
 @param key Key to access
 @return Non-null valueForKey
 */
- (id)valueForKey:(NSString *)key;

/** Non-null objectAtIndex
 @param index Index of object to access
 @return Non-null objectAtIndex
 */
- (id)objectAtIndex:(NSUInteger)index;

/** Non-null objectAtIndexedSubscript
 @param index Index of object to access
 @return Non-null objectAtIndexedSubscript
 */
- (id)objectAtIndexedSubscript:(NSUInteger)index;

/** Non-null count
 @return Non-null count
 */
- (NSUInteger)count;

/** Non-null objectForKey
 @param key Key to access
 @return Non-null objectForKey
 */
- (id)objectForKey:(id)key;

/** Non-null objectForKeyedSubscript
 @param key Key to access
 @return Non-null objectForKeyedSubscript
 */
- (id)objectForKeyedSubscript:(id)key;

/** Non-null length
 @return Non-null length
 */
- (NSUInteger)length;

@end
