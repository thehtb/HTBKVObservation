//
//  ViewController.m
//  PMPKVO Sample iOS App
//
//  Created by Mark Aufflick on 11/12/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import "ViewController.h"

#import "PMPKVOTests.h"

@interface ViewController ()

@property (strong) PMPKVOTests * tests;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tests = [[PMPKVOTests alloc] init];
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
