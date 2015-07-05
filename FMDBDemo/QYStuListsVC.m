//
//  QYStuListsVC.m
//  FMDBDemo
//
//  Created by qingyun on 14-12-5.
//  Copyright (c) 2014年 hnqingyun. All rights reserved.
//

#import "QYStuListsVC.h"
#import "common.h"
#import "AFNetworking/AFHTTPRequestOperationManager.h"
#import "FMDB.h"
#import "QYStudentModel.h"

#define kStuListsCellID     @"StudentListsCell"

@interface QYStuListsVC ()
@property (nonatomic, strong) NSMutableArray *students;
@property (nonatomic, strong) FMDatabase *database;
@end

@implementation QYStuListsVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setupDatabase
{
    // 打开数据库
    if (![self.database open]) {
        NSLog(@"Open database failed!");
        return;
    }
    
    // 创建学生表
    NSString *sql = @"create table if not exists Students(stu_id INTEGER PRIMARY KEY NOT NULL, name TEXT, age INTEGER)";
    [self.database executeUpdate:sql];
    
    // 关闭数据库
    [self.database close];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupDatabase];
    
    [self loadStudentsInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadStudentsLocal) name:kStuInfoChanged object:nil];
}


#pragma mark - network process & database process
- (FMDatabase *)database
{
    
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    
    NSLog(@"%@", docPath);
    
    NSString *DBPath = [docPath stringByAppendingPathComponent:kDBFileName];
    
    if (_database == nil) {
        _database = [[FMDatabase alloc] initWithPath:DBPath];
    }
    
    return _database;
}

- (void)updateDB
{
    // 打开数据库
    if (![self.database open]) {
        NSLog(@"Open database failed!");
        return ;
    }
    
    for (NSDictionary *student in _students) {
        // 添加学生记录
        NSString *sql = [NSString stringWithFormat:@"insert into Students(stu_id, name, age) values(:%@, :%@, :%@)", kStuIDKey, kNameKey, kAgeKey];
        [self.database executeUpdate:sql withParameterDictionary:student];
    }
    
    // 关闭数据库
    [self.database close];
}

- (void)deleteStudentFromDBByNumber:(NSString *)number
{
    // 打开数据库
    if (![self.database open]) {
        NSLog(@"Open database failed!");
        return;
    }
    
    // 根据学号删除学生记录
    NSString *sql = [NSString stringWithFormat:@"delete from Students where stu_id = %@", number];
    [self.database executeUpdate:sql];
    
    // 关闭数据库
    [self.database close];
}

- (void)loadStudentsFromServer
{
    // 从服务器请求数据
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers];
    
    NSString *urlStr = [kBaseURL stringByAppendingPathComponent:@"persons.json"];
    
    NSDictionary *parameters = @{@"person_type":@"student"};
    
    [manager POST:urlStr parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {

//        _students = (NSMutableArray *)responseObject;
        _students = (NSMutableArray *)[responseObject valueForKey:@"data"];

        
        // 刷新tableView
        [self.tableView reloadData];
        
        // 更新数据库
        [self updateDB];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
    }];
    
    // 记录标志位，标示已经保存过数据库
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kTableNotEmpty];
}

- (void)loadStudentsLocal
{
    // 打开数据库
    if (![self.database open]) {
        NSLog(@"Open database failed!");
        return;
    }
    
    // 查询学生记录
    NSString *sql = @"select * from Students";
    FMResultSet *rs = [self.database executeQuery:sql];
    if (rs) {
        _students = [NSMutableArray array];
    }
    while ([rs next]) {
        NSString *name = [rs stringForColumn:kNameKey];
        int age = [rs intForColumn:kAgeKey];
        NSString *stuID = [rs stringForColumn:kStuIDKey];
        
        // 保存学生记录到模型对象数组中(_students)
        QYStudentModel *model = [[QYStudentModel alloc] initWithName:name age:age stuID:stuID];
        [_students addObject:model];
    }
    
    // 关闭数据库
    [self.database close];
}

/**
 *  加载学生记录信息
 *  如果，数据库表里面没记录，从网络请求
 *  否则，从本地数据库获取
 */
- (void)loadStudentsInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL isNotEmpty = [defaults boolForKey:kTableNotEmpty];
    
    if (!isNotEmpty) {
        [self loadStudentsFromServer];
    } else {
        [self loadStudentsLocal];
    }
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_students) {
        return _students.count;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kStuListsCellID forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [_students[indexPath.row] valueForKey:kNameKey];
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        id student = _students[indexPath.row];
        NSString *stuID = [student valueForKey:kStuIDKey];
        
        [_students removeObject:student];
        [self deleteStudentFromDBByNumber:stuID];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    UITableViewCell *cell = (UITableViewCell *)sender;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    id student = _students[indexPath.row];
    
    NSString *name = [student valueForKey:kNameKey];
    int age = [[student valueForKey:kAgeKey] intValue];
    NSString *stuID = [student valueForKey:kStuIDKey];
    
    QYStudentModel *model = [[QYStudentModel alloc] initWithName:name age:age stuID:stuID];
    
    UIViewController *dstVC = [segue destinationViewController];
    
    [dstVC setValue:model forKey:@"currentStudent"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
