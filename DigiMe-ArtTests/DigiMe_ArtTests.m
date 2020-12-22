//
//  DigiMe_ArtTests.m
//  DigiMe-ArtTests
//
//  Created by LEE on 10/28/20.
//  Copyright © 2020 L. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface DigiMe_ArtTests : XCTestCase

@end

@implementation DigiMe_ArtTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
	CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent();
	NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:interval];
	NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:interval];
	NSDate *date3 = [NSDate dateWithTimeIntervalSinceNow:interval];
	NSString * str = [self currnetDate];
}
-(NSString *)currnetDate{
	CFAbsoluteTime absoluteTime = CFAbsoluteTimeGetCurrent();
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyyMMdd_HH:mm:ss:SSS";
	[formatter setTimeZone:[NSTimeZone timeZoneWithName:@"CST"]];
	NSString *currnetDate = [formatter stringFromDate:[self getDateFrom:absoluteTime]];
	NSDate* gmtDate = [formatter dateFromString:currnetDate];
	return currnetDate;
}
-(NSDate*)getDateFrom:(CFAbsoluteTime)absoluteTime
{
	NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:absoluteTime];
	return date;
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
