//
//  XIGlobalTimer.h
//  
//
//  Created by YXLONG on 2018/7/31.
//  Copyright © 2018年 yxlong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIKIT_EXTERN NSNotificationName const XIGlobalTimerTickEventNotification;

@interface XIForegroundRepeatsTimer : NSObject
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign, getter=isActive, readonly) BOOL active;

+ (XIForegroundRepeatsTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                                              block:(dispatch_block_t)block;
- (void)pause;
- (void)resume;
- (void)reset;
@end
