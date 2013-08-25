//
//  NSArray+Jukaela.h
//  JukaelaCore
//
//  Created by Josh on 8/21/13.
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
 NSArray helper methods that may be useful in social networking applications.
 */
@interface NSArray (Jukaela)

///---------------------------------------
/// @name Class Methods
///---------------------------------------

/** Creates and 'NSArray' of URLs as 'NSString's.  
 
 This method is good for checking a given 'NSString' for URLs.  This is quite useful in social networking circumstances.
 
 @param stringToCheck The 'NSString' to check for URLs
 @param error 'NSError' that will be populated by any errors.
 @return 'NSArray' of URLs as 'NSString's
 */
+(NSArray *)arrayOfURLsFromString:(NSString *)stringToCheck error:(NSError *)error;

/** Splits a given 'NSString' into multiple parts, no greater in length than 'maxLength'
 
 This method is useful in circumstances where a long string, such as one being posted to a social network that restricts character count, needs to be split into multiple strings.
 
 @param stringToSplit The 'NSString' that needs to be split into parts
 @param maxLength 'NSInteger' that specifies that maximum length that each 'NSString' the returned 'NSArray' can be
 @return 'NSArray' of 'NSString's that are no greater than 'maxLength'
 */
+(NSArray *)splitString:(NSString *)stringToSplit maxCharacters:(NSInteger)maxLength;

@end
