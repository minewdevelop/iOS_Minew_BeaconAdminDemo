//
//  ViewController.m
//  MinewBeaconAdminSDKDemo
//
//  Created by SACRELEE on 27/09/2016.
//  Copyright © 2016 minewTech. All rights reserved.
//

#import "ViewController.h"
#import "DeviceListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    DeviceListViewController *dlv = [[DeviceListViewController alloc]init];
    [self.navigationController pushViewController:dlv animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
