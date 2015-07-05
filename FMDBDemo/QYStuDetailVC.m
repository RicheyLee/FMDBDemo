//
//  QYStuDetailVC.m
//  FMDBDemo
//
//  Created by qingyun on 14-12-5.
//  Copyright (c) 2014年 hnqingyun. All rights reserved.
//

#import "QYStuDetailVC.h"
#import "QYStudentModel.h"
#import "fmdb/FMDB.h"
#import "common.h"

@interface QYStuDetailVC ()
@property (weak, nonatomic) IBOutlet UITextField *stu_id;
@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *age;

@property (nonatomic, strong) QYStudentModel *currentStudent;

@property (nonatomic, getter = isContentChanged) BOOL contentChanged;

@property (nonatomic, strong) FMDatabase *database;

@end

@implementation QYStuDetailVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateViews
{
    _stu_id.text = _currentStudent.stu_id;
    _age.text = [@(_currentStudent.age) stringValue];
    _name.text = _currentStudent.name;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateViews];
}

- (BOOL)isContentChanged
{
    return !([_name.text isEqualToString:_currentStudent.name]
            && [_age.text isEqualToString:[@(_currentStudent.age) stringValue]]);
}

- (FMDatabase *)database
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSString *DBPath = [docPath stringByAppendingPathComponent:kDBFileName];
    if (_database == nil) {
        _database = [[FMDatabase alloc] initWithPath:DBPath];
    }
    return _database;
}

- (void)updateStudentInfo
{
    // 打开数据库
    if (![self.database open]) {
        NSLog(@"Open database failed!");
        return;
    }
    
    // 更新学生记录
    NSString *sql = @"update Students set name = ?, age = ? where stu_id = ?";
    
    [self.database executeUpdate:sql, _name.text, _age.text, _stu_id.text];
    
    // 关闭数据库
    [self.database close];
    
    _currentStudent.name = _name.text;
    _currentStudent.age = [_age.text intValue];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kStuInfoChanged object:nil];
}

- (IBAction)saveData:(id)sender {
    if (!self.isContentChanged) {
        NSLog(@"No change!");
        return;
    }
    
    // 更新学生记录到数据库
    [self updateStudentInfo];
}

@end
