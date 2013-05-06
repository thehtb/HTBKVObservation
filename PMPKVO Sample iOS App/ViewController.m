//
//  ViewController.m
//  HTBKVO Sample iOS App
//
//  Created by Mark Aufflick on 11/12/12.
//  Copyright (c) 2012 The High Technology Bureau. All rights reserved.
//

#import "ViewController.h"

#import "HTBKVOTests.h"

@interface ViewController ()

@property (strong) HTBKVOTests * tests;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tests = [[HTBKVOTests alloc] init];
    [self.tests runTests];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)rerunTests:(id)sender
{
    [self.tests runTests];
}

@end
