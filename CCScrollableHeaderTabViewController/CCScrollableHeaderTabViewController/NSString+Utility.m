//
//  NSString+Utility.m
//  
//
//  Created by ddrccw on 14-2-17.
//  Copyright (c) 2014年 ddrccw. All rights reserved.
//

#import "NSString+Utility.h"

@implementation NSString (Utility)

+ (BOOL)isNilOrEmptyForString:(NSString *)aString {
    if ([aString isEqual:[NSNull null]] || !aString || !aString.length) {
        return YES;
    }
    return NO;
}

@end









































