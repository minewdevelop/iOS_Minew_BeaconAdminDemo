//
//  DeviceListViewController.m
//  MinewBeaconAdminSDKDemo
//
//  Created by SACRELEE on 27/09/2016.
//  Copyright © 2016 minewTech. All rights reserved.
//

#import "DeviceListViewController.h"
#import <MinewBeaconAdmin/MinewBeaconAdmin.h>
#import "DeviceDetailViewController.h"


@interface DeviceListViewController ()<MinewBeaconManagerDelegate, MinewBeaconConnectionDelegate>

@end

@implementation DeviceListViewController
{
    NSArray *_scannedBeacons;
    NSDateFormatter *_dateFormatter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _dateFormatter = [[NSDateFormatter alloc]init];
    _dateFormatter.timeZone = [NSTimeZone localTimeZone];
    _dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss.SSS";
    self.title = @"Beacons in range";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@" " style:UIBarButtonItemStyleDone target:self action:@selector(none)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
}

- (void)none
{

}

- (void)refresh
{
    [[MinewBeaconManager sharedInstance] stopScan];
    [[MinewBeaconManager sharedInstance] startScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MinewBeaconManager sharedInstance].delegate = self;
    [[MinewBeaconManager sharedInstance] startScan];
}



#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _scannedBeacons.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Device Quantity: %lu", (unsigned long)_scannedBeacons.count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *identifer = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifer];
        cell.detailTextLabel.numberOfLines = 0;
    }
    
    MinewBeacon *beacon = _scannedBeacons[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - Connectable:%@", beacon.name, beacon.connectable? @"YES": @"NO"];
    
    if (beacon.connectable)
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    else
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Major:%ld Minor:%ld RSSI:%ld Battery:%ld, mac:%@", (long)beacon.major, (long)beacon.minor, (long)beacon.rssi, (long)beacon.battery, beacon.mac];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MinewBeacon *beacon = _scannedBeacons[indexPath.row];

    if (beacon.connectable)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        // create a connection
        MinewBeaconConnection *connection = [[MinewBeaconConnection alloc]initWithBeacon:beacon];
        
        connection.delegate = self;
        
        // try connect to the device
        [connection connect];
    }
    else
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        NSLog(@"this beacon isn't connectable.");
    }
}

#pragma mark ******************MinewBeaconManager Delegate
- (void)minewBeaconManager:(MinewBeaconManager *)manager didRangeBeacons:(NSArray<MinewBeacon *> *)beacons
{
  
    _scannedBeacons = beacons;
    
//    NSLog(@"%@", [beacons[0] exportJSON]);
    
    _scannedBeacons = [_scannedBeacons sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        NSInteger rssi1 = ((MinewBeacon *)obj1).rssi;
        NSInteger rssi2 = ((MinewBeacon *)obj2).rssi;
        return rssi1 > rssi2? NSOrderedAscending: NSOrderedDescending;
        
    }];
    
    [self.tableView reloadData];
}

- (void)minewBeaconManager:(MinewBeaconManager *)manager appearBeacons:(NSArray<MinewBeacon *> *)beacons
{
//    NSLog(@"===appear beacons:%@", beacons);
}

- (void)minewBeaconManager:(MinewBeaconManager *)manager disappearBeacons:(NSArray<MinewBeacon *> *)beacons
{
//    NSLog(@"---disappear beacons:%@", beacons);
}


- (void)minewBeaconManager:(MinewBeaconManager *)manager didUpdateState:(BluetoothState)state
{
     NSLog(@"the bluetooth state is %@!", state == BluetoothStatePowerOn? @"power on":( state == BluetoothStatePowerOff? @"power off": @"unknown"));
}

#pragma mark **********************Connection Delegate
- (void)beaconConnection:(MinewBeaconConnection *)connection didChangeState:(ConnectionState)state
{
    NSString *string = @"Connection state change to ";
    
    switch (state) {
        case ConnectionStateConnecting:
           string = [string stringByAppendingString:@"Connceting"];
            break;
            
        case ConnectionStateConnected:
            string = [string stringByAppendingString:@"Connected"];
            break;
            
        case ConnectionStateDisconnected:
            string = [string stringByAppendingString:@"Disconnected"];
            break;
            
        case ConnectionStateConnectFailed:
            string = [string stringByAppendingString:@"ConnectFailed"];
            break;
        default:
            break;
    }
    
    NSLog(@"%@", string);
    
    if ( (state == ConnectionStateConnectFailed || state == ConnectionStateDisconnected ) && [self.navigationController.topViewController isKindOfClass:[self class]])
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error!" message:@"Fail to connect this device." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
        [ac addAction:ok];
        
        [self presentViewController:ac animated:YES completion:nil];
    }

    if (state != ConnectionStateConnected)
        return ;
    
    DeviceDetailViewController *ddvc = [[DeviceDetailViewController alloc]init];
    ddvc.connection = connection;
    
    [self.navigationController pushViewController:ddvc animated:YES];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
