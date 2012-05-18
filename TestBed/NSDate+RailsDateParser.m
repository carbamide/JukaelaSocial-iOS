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

-(NSString *)distanceOfTimeInWordsToNow 
{
    return [self distanceOfTimeInWordsSinceDate:[NSDate date]];
}

-(NSString *)distanceOfTimeInWordsSinceDate:(NSDate *)aDate 
{
    double interval = [self timeIntervalSinceDate:aDate];
    
    NSString *timeUnit;
    int timeValue = 0;
    
    if (interval < 0) {
        interval = interval * -1;        
    }
    
    if (interval< 60) {
        return @"seconds";
    } 
    else if (interval< 3600) { // minutes
        
        timeValue = round(interval / 60);
        
        if (timeValue == 1) {
            timeUnit = @"minute";
        } 
        else {
            timeUnit = @"minutes";
        }
    } 
    else if (interval< 86400) {
        timeValue = round(interval / 60 / 60);
        
        if (timeValue == 1) {
            timeUnit = @"hour";
            
        } 
        else {
            timeUnit = @"hours";
        }        
    } 
    else if (interval< 2629743) {
        int days = round(interval / 60 / 60 / 24);
        
        if (days < 7) {
            
            timeValue = days;
            
            if (timeValue == 1) {
                timeUnit = @"day";
            }
            else {
                timeUnit = @"days";
            }
        }
        else if (days < 30) {
            int weeks = days / 7;
            
            timeValue = weeks;
            
            if (timeValue == 1) {
                timeUnit = @"week";
            } 
            else {
                timeUnit = @"weeks";
            }
        } 
        else if (days < 365) {
            int months = days / 30;
            timeValue = months;
            
            if (timeValue == 1) {
                timeUnit = @"month";
            } 
            else {
                timeUnit = @"months";
            }
            
        }
        else if (days < 30000) {
            int years = days / 365;
            timeValue = years;
            
            if (timeValue == 1) {
                timeUnit = @"year";
            } 
            else {
                timeUnit = @"years";
            }
        } 
        else {
            return @"forever ago";
        }
    }
    
    return [NSString stringWithFormat:@"%d %@", timeValue, timeUnit];    
}

@end
