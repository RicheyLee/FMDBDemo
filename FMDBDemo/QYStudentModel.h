//
//  QYStudentModel.h
//  FMDBDemo
//
//  Created by qingyun on 14-12-5.
//  Copyright (c) 2014年 hnqingyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QYStudentModel : NSObject

@property (nonatomic, strong) NSString *stu_id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int age;

- (instancetype)initWithName:(NSString *)name age:(int)age stuID:(NSString *)stuID;

@end
