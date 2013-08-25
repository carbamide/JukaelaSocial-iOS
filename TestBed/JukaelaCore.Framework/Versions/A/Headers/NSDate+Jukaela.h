//
//  NSDate+Jukaela.h
//  JukaelaCore
//
//  Created by Josh Barrow on 5/6/12.
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

@interface NSDate (Jukaela)

///---------------------------------------
/// @name Class Methods
///---------------------------------------

/** Convert an ISO8601 'NSString' to 'NSDate'
 
 The user of this class method must supply their own 'NSDateFormatter'.  'NSDateFormatter's are expensive to create, so it's recommended to create your own
 and keep a reference to it.
 
 @param dateString The string to convert
 @param formatter The 'NSDateFormatter' to use
 @return 'NSDate' that had been formatted
 */
+ (NSDate *)dateWithISO8601String:(NSString *)dateString withFormatter:(NSDateFormatter *)formatter;

/** Converts the specified 'NSString' to an 'NSDate' with the specified date format and formatter
 
 The user of this class method must supply their own 'NSDateFormatter'.  'NSDateFormatter's are expensive to create, so it's recommended to create your own
 and keep a reference to it.
 
 @param dateString The string to convert
 @param dateFormat The format of the date, in standard format
 @param formatter The 'NSDateFormatter' to use
 @return 'NSDate' that has been formatted
 */
+ (NSDate *)dateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat withFormatter:(NSDateFormatter *)formatter;

/** Number of days between two 'NSDate's
 
 @param dateOne First date
 @param dateTwo Second date
 @param options 'NSCalendarOptions' to specify for the calculation
 @return Number of days in between the two dates, as an int
 */
+ (int)daysBetweenDate:(NSDate *)dateOne andDate:(NSDate *)dateTwo options:(NSCalendarOptions)options;

@end
