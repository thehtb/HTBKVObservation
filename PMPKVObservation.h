//
//  PMPKVO.h
//  PMPKVO Sample App
//
//  Created by Mark Aufflick on 12/03/12.
//  Copyright (c) 2012 Pumptheory Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PMPKVObservation : NSObject

@property (nonatomic, assign) id observer;
@property (nonatomic, assign) id observee;
@property (nonatomic, copy) NSString * keyPath;
@property NSKeyValueObservingOptions options;
@property (nonatomic) SEL selector;
@property (nonatomic, readonly) BOOL isValid;

- (BOOL)observe;
- (void)invalidate;

@end
