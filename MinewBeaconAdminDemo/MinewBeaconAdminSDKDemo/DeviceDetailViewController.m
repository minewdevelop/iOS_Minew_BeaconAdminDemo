//
//  DeviceDetailViewController.m
//  MinewBeaconAdminSDKDemo
//
//  Created by SACRELEE on 27/09/2016.
//  Copyright © 2016 minewTech. All rights reserved.
//

#import "DeviceDetailViewController.h"
#import <MinewBeaconAdmin/MinewBeaconAdmin.h>


#define sSectionOne @[@"Battery:", @"UUID:", @"Major:", @"Minor:", @"TxPower @ 1meter:", @"TxPower:", @"Broadcast Period:", @"DeviceId:", @"Name:", @"Work Mode:", @"ChangePassword:"]
#define sSectionTwo @[@"Manufuturer:", @"Model:", @"SN:", @"Hardware:", @"Software:", @"Firmware", @"SystemId:", @"IEEE Regulatory Certification:"]

@interface DeviceDetailViewController ()<MinewBeaconConnectionDelegate>

@end

@implementation DeviceDetailViewController
{
    NSArray *_sectionValues1;
    NSArray *_sectionValues2;
    MinewBeaconSetting *_beacon;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Set beacon.";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"<" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveChangesAndReboot)];
    
    NSLog(@"%@", [_beacon exportJSON]);
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshData];
    [self.tableView reloadData];
}

- (void)setConnection:(MinewBeaconConnection *)connection
{
    _connection = connection;
    _connection.delegate = self;
    _beacon = connection.setting;
}


- (void)refreshData
{
    // give SDK sometime to handle beacon data
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)( 1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!_beacon)
            return ;
        
        _sectionValues1 = @[[self stringByInteger:_beacon.battery], _beacon.uuid? _beacon.uuid: @"N/A", [self stringByInteger:_beacon.major], [self stringByInteger:_beacon.minor], [self stringByInteger:_beacon.calibratedTxPower], [self stringByInteger:_beacon.txPower], [self stringByInteger:_beacon.broadcastInterval], [self stringByInteger:_beacon.deviceId], _beacon.name? _beacon.name: @"N/A", [self stringByInteger:_beacon.mode]];
        
        _sectionValues2 = @[_beacon.manufacture, _beacon.model, _beacon.SN, _beacon.hardware, _beacon.software, _beacon.firmware, _beacon.systemId? _beacon.systemId: @" ", _beacon.certData? _beacon.certData: @""];
        
        [self.tableView reloadData];
    });

}

- (void)setBeacon:(MinewBeaconSetting *)beacon
{
    _beacon = beacon;
}

- (void)back
{
    [_connection disconnect];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveChangesAndReboot
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Input" message:@"input reboot password." preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
          textField.placeholder = @"";
    }];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *pass = ac.textFields.firstObject.text;
        
        pass = [pass stringByReplacingOccurrencesOfString:@" " withString:@""];
        
        if (pass.length)
            [_connection writeSetting:pass];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [ac addAction:ok];
    [ac addAction:cancel];
    
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark *********************Connection delegate
- (void)beaconConnection:(MinewBeaconConnection *)connection didChangeState:(ConnectionState)state
{
    if (state == ConnectionStateDisconnected)
    {
        if (![self.navigationController.topViewController isKindOfClass:[self class]])
            return ;

        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error!" message:@"your iphone has disconnect from this beacon, all your unsaved settings has been lost!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [ac addAction:ok];
        [self presentViewController:ac animated:YES completion:nil];
    }
}

- (void)beaconConnection:(MinewBeaconConnection *)connection didWriteSetting:(BOOL)success
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Tips" message:success? @"all changes has been saved, this device will disconnect!": @"failed to write data to device." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        if (![self.navigationController.topViewController isKindOfClass:[self class]])
            return ;
        
        [_connection disconnect];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [ac addAction:ok];
    
    [self presentViewController:ac animated:YES completion:nil];
}



#pragma mark - Table view data source
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   return !section? @"Base info": @"System info";
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!section)
        return 11;
    
    return 8;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *identifer = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    
    if (!cell)
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifer];
    
    
    cell.textLabel.text = [self cellTitleWithIndex:indexPath];
    cell.detailTextLabel.text = [self cellValueWithIndex:indexPath];
    
    return cell;
}

- (NSString *)cellTitleWithIndex:(NSIndexPath *)path
{
    NSArray *titles = !path.section? sSectionOne: sSectionTwo;
    
    return titles[path.row];
}

- (NSString *)cellValueWithIndex:(NSIndexPath *)path
{
    NSArray *values = !path.section? _sectionValues1: _sectionValues2;
    
    NSInteger r = path.row;
    if (r >= values.count)
        return  @"";
    else
        return values[r];
}

- (NSString *)stringByInteger:(NSInteger)integer
{
    return [NSString stringWithFormat:@"%ld", (long)integer];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"--%ld--%ld", (long)indexPath.section, (long)indexPath.row);
    
    if (indexPath.section || (!indexPath.section && !indexPath.row))
    {
        [self showAlert:YES title:@"" message:@"you can't modify this item." textCompletion:nil];
        return ;
    }

    [self showAlert:NO title:sSectionOne[indexPath.row] message:@"you should input the right information." textCompletion:^(NSString *string) {
        
        switch (indexPath.row)
        {
            case 1:  // uuid
                _beacon.uuid = string;
                break;
            case 2:  // Major
                _beacon.major = [string integerValue];
                break;
            case 3:  // minor
                _beacon.minor = [string integerValue];
                break;
            case 4:  // calibratedTxPower
                _beacon.calibratedTxPower = [string integerValue];
                break;
            case 5:  // TxPower
                _beacon.txPower = [string integerValue];
                break;
            case 6:  // BroadcastPeriod
                _beacon.broadcastInterval = [string integerValue];
                break;
            case 7:  // DeviceId
                _beacon.deviceId = [string integerValue];
                break;
            case 8:  // name
                _beacon.name = string;
                break;
            case 9:  // work mode
                _beacon.mode = [string integerValue];
                break;
            case 10: // password
                _beacon.password = string;
                break;
            default:
                break;
        }
        
        [self refreshData];
        [self.tableView reloadData];
    }];
}


- (void)showAlert:(BOOL)isTips title:(NSString *)title message:(NSString *)message textCompletion:(void(^)(NSString *string))handler
{
    
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if (!isTips)
    {
        [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"";
        }];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *pass = ac.textFields.firstObject.text;
            handler(pass);
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [ac addAction:ok];
        [ac addAction:cancel];
    }
    else
    {
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
       
        [ac addAction:ok];
    }
  
    [self presentViewController:ac animated:YES completion:nil];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
