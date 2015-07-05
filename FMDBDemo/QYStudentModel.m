//
//  QYStudentModel.m
//  FMDBDemo
//
//  Created by qingyun on 14-12-5.
//  Copyright (c) 2014年 hnqingyun. All rights reserved.
//

#import "QYStudentModel.h"

@implementation QYStudentModel

- (NSString *)description
{
    NSString *desc = [NSString stringWithFormat:@"StudentInfo: StudyID:<%@>, Name:<%@>, Age:<%d>", _stu_id, _name, _age];
    
    return desc;
}

- (instancetype)initWithName:(NSString *)name age:(int)age stuID:(NSString *)stuID
{
    if (self = [super init]) {
        _name = name;
        _age = age;
        _stu_id = stuID;
    }
    return self;
}

@end
