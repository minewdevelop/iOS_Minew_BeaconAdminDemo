//
//  DeviceDetailViewController.h
//  MinewBeaconAdminSDKDemo
//
//  Created by SACRELEE on 27/09/2016.
//  Copyright © 2016 minewTech. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MinewBeaconConnection;

@interface DeviceDetailViewController : UITableViewController

@property (nonatomic, strong) MinewBeaconConnection *connection;

@end
