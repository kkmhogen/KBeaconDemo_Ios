//
//  CfgSensorDataHistoryController.m
//  KBeacon
//
//  Created by hogen on 2020/11/5.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "CfgSensorDataHistoryController.h"
#import "KBHumidityDataMsg.h"
#import "string.h"
#import "MJRefresh.h"
#import "CfgHTRecordFileMgr.h"
#import "HtSensorTableViewCell.h"

#define HISTORY_LOAD_TIMEOUT_SEC 12
@interface CfgSensorDataHistoryController ()
{
    KBHumidityDataMsg* mSensorDataMsg;
    NSTimer* mTimerLoading;
    BOOL mLoadByHeadRefresh;
    BOOL mHasReadDataInfo;
    long mReadNextRecordPos;
    
    CfgHTRecordFileMgr* mRecordMgr;
}
@end

@implementation CfgSensorDataHistoryController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    mRecordMgr = [[CfgHTRecordFileMgr alloc]init:self.beacon.mac];

    self.mTableView.delegate = self;
    self.mTableView.dataSource = self;
    
    self->mHasReadDataInfo = false;
    self->mSensorDataMsg = [[KBHumidityDataMsg alloc]init];
    self.mTableView.separatorInset = UIEdgeInsetsZero;
    self.mTableView.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
    
    [self setupUpRefreshCtrl];
    [self.mTableView.mj_header beginRefreshing];
    
}


- (IBAction)onClear:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nb_clear_history_warning message:nb_clear_history_description preferredStyle:UIAlertControllerStyleAlert];
    
      UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_CANCEL style:UIAlertActionStyleDestructive handler:nil];
      [alertController addAction:OkAction];
    
    [alertController addAction:[UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [self->mSensorDataMsg clearSensorRecord:self.beacon callback:^(BOOL bConfigSuccess, NSObject * _Nullable obj, NSError * _Nullable error) {
            if (bConfigSuccess)
            {
                [self->mRecordMgr clearHistoryRecord];
                
                [self.mTableView reloadData];
                [self showDialogMsg:@"success" message:upload_data_success];
            }
            else
            {
                NSString* strFail = [NSString stringWithFormat:@"%@,code:%ld", upload_config_data_failed, (long)error.code];
                [self showDialogMsg:@"failed" message:strFail];
            }
        }];
     }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)onExport:(id)sender {
    
    NSString* strHistory = [self->mRecordMgr exportRecordsToString];
    if (strHistory == nil)
    {
        return;
    }

    NSString* email = [strHistory stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURL* emailUrl = [NSURL URLWithString:email];
    [[UIApplication sharedApplication] openURL:emailUrl options:@{} completionHandler:^(BOOL success) {
       
    }];
    
}

//setup refresh ctrl
- (void)setupUpRefreshCtrl
{
    __unsafe_unretained UITableView *tableView = self.mTableView;
    
    //start refresh
    self.mTableView.mj_header =
        [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(reloadHistoryRecord)];
    
    tableView.mj_header.automaticallyChangeAlpha = YES;
}

//reload all data
- (void)reloadHistoryRecord
{
    if (!self->mHasReadDataInfo)
    {
        [self startReadFirstPage];
    }
    else
    {
        [self startReadNextRecordPage];
    }
}

-(void) startReadFirstPage
{
    //set status to loading
    [mSensorDataMsg readSensorDataInfo:self.beacon callback:^(BOOL bConfigSuccess, NSObject * _Nullable obj, NSError * _Nullable error)
    {
        if (!bConfigSuccess)
        {
            [self->mTimerLoading invalidate];
            [self.mTableView.mj_header endRefreshing];
            [self showDialogMsg:@"failed" message:LOAD_HISTORY_DATA_FAILED];

            return;
        }

        self->mHasReadDataInfo = YES;
        ReadHTSensorInfoRsp* infRsp = (ReadHTSensorInfoRsp*)obj;
        if (infRsp.totalRecordNumber == 0)
        {
            [self showNoMoreDataMessage: 0];
        }
        else
        {
            [self startReadNextRecordPage];
        }
    }];

   [self->mTimerLoading invalidate];
   self->mTimerLoading = [NSTimer scheduledTimerWithTimeInterval:HISTORY_LOAD_TIMEOUT_SEC repeats:NO block:^(NSTimer * _Nonnull timer) {
       [self showDialogMsg:@"failed" message:LOAD_HISTORY_DATA_TIMEOUT];

        [self.mTableView.mj_header endRefreshing];
    }];
    
    [self.mTableView.mj_header beginRefreshing];
}

-(void)startReadNextRecordPage
{
    [self->mSensorDataMsg readSensorRecord:self.beacon
                                 recordNum:INVALID_DATA_RECORD_POS
                                     order:READ_RECORD_NEW_RECORD
                              maxRecordNum:30
                                  callback:^(BOOL bConfigSuccess, NSObject * _Nullable obj, NSError * _Nullable error)
     {
        if (!bConfigSuccess)
        {
            [self->mTimerLoading invalidate];
            [self showDialogMsg:@"failed" message:LOAD_HISTORY_DATA_FAILED];

            return;
        }

        ReadHTSensorDataRsp* dataRsp = (ReadHTSensorDataRsp*) obj;
        
        //add data
        if (dataRsp.readDataRspList != nil)
        {
            [self->mRecordMgr appendRecords:dataRsp.readDataRspList];
        }
        
        if ([dataRsp.readDataNextPos unsignedIntegerValue] == INVALID_DATA_RECORD_POS)
        {
            [self showNoMoreDataMessage: dataRsp.readDataRspList.count];
        }
        else
        {
            [self showLoadDataComplete: dataRsp.readDataRspList.count];
        }
    }];
}

-(void) showNoMoreDataMessage:(NSUInteger)nReadedMsgNum
{
    [self.mTableView.mj_header endRefreshing];
    [mTimerLoading invalidate];
    [self.mTableView reloadData];

    NSString* strMsg = [NSString stringWithFormat:load_data_complete_no_more_data, nReadedMsgNum];
    
    [self showDialogMsg:@"success" message:strMsg];

    [self->mRecordMgr saveRecordsToFile];
}


-(void) showLoadDataComplete:(NSUInteger)nReadedMsgNum
 {
    [self.mTableView.mj_header endRefreshing];
    [mTimerLoading invalidate];
    [self.mTableView reloadData];

    NSString* strMsg = [NSString stringWithFormat:load_data_complete, nReadedMsgNum];
     [self showDialogMsg:@"success" message:strMsg];

    [self->mRecordMgr saveRecordsToFile];
}


-(NSString*) localTimeFromUTCSeconds:(long)utcSecond
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:utcSecond];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdentifier = @"seqSensorRecordCell";
    HtSensorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        return nil;
    }
    
    KBHumidityRecord* record = [self->mRecordMgr get:indexPath.row];
    if (record != nil)
    {
        NSString* strUtcTime;

        strUtcTime = [self localTimeFromUTCSeconds: [record.utcTime longValue]];
        cell.mRecordUTCTime.text = strUtcTime;
        cell.mTemperature.text =  [NSString stringWithFormat:@"%@: %.2f%@",
                            BEACON_TEMP, [record.temperature floatValue], BEACON_TEMP_UINT];
        cell.mHumidity.text =  [NSString stringWithFormat:@"%@: %.2f%%",
                                BEACON_HUM, [record.humidity floatValue]];
    }
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
     return [self->mRecordMgr size];
}

-(void)showDialogMsg:(NSString*)title message:(NSString*)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *OkAction = [UIAlertAction actionWithTitle:DLG_OK style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:OkAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
