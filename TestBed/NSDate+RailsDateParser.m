//
//  NSDate+RailsDateParser.m
//  Jukaela
//
//  Created by Josh Barrow on 5/6/12.
//  Copyright (c) 2012 Jukaela Enterprises. All rights reserved.
//

#import "NSDate+RailsDateParser.h"

@implementation NSDate (RailsDateParser)

+ (NSDate *)dateWithISO8601String:(NSString *)dateString withFormatter:(NSDateFormatter *)formatter
{
    if (!dateString) {
        return nil;
    }
    
    if ([dateString hasSuffix:@"Z"]) {
        dateString = [[dateString substringToIndex:(dateString.length-1)] stringByAppendingString:@"-0000"];
    }
    
    return [self dateFromString:dateString withFormat:@"yyyy-MM-dd'T'HH:mm:ssZ" withFormatter:formatter];
}

+ (NSDate *)dateFromString:(NSString *)dateString withFormat:(NSString *)dateFormat withFormatter:(NSDateFormatter *)formatter
{    
    [formatter setDateFormat:dateFormat];
        
    NSDate *date = [formatter dateFromString:dateString];
    
    return date;
}

+(int)daysBetween:(NSDate *)dt1 and:(NSDate *)dt2
{
    NSUInteger unitFlags = NSDayCalendarUnit;
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    
    return [components day]+1;
}

@end
