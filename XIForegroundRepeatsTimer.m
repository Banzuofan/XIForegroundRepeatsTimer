//
//  XIGlobalTimer.m
//
//
//  Created by YXLONG on 2018/7/31.
//  Copyright © 2018年 yxlong. All rights reserved.
//

#import "XIForegroundRepeatsTimer.h"

NSNotificationName const XIGlobalTimerTickEventNotification = @"com.yxlong.XIGlobalTimerTickEventNotification";


@interface NSTimer (SupportBlockTimer)
+ (NSTimer *)sbt_timerWithTimeInterval:(NSTimeInterval)interval
                               repeats:(BOOL)repeats
                                 block:(void (^)(void))block;
@end

@implementation NSTimer (SupportBlockTimer)
+ (NSTimer *)sbt_timerWithTimeInterval:(NSTimeInterval)interval
                               repeats:(BOOL)repeats
                                 block:(void (^)(void))block
{
    return [NSTimer scheduledTimerWithTimeInterval:interval
                                            target:self
                                          selector:@selector(sbt_tick:)
                                          userInfo:[block copy]
                                           repeats:repeats];
}

+ (void)sbt_tick:(NSTimer *)timer {
    void(^block)(void) = timer.userInfo;
    if(block){
        block();
    }
}
@end

@interface XIGlobalTimer : NSObject
@property(nonatomic, strong) NSTimer *gTimer;
@property(nonatomic, assign) NSInteger observersCount;
@property(nonatomic, assign) NSInteger tickCounter;

+ (instancetype)sharedInstance;
- (void)prepares;
- (void)enqueue;
- (void)dequeue;
@end

@implementation XIGlobalTimer

- (void)dealloc
{
    if(_gTimer){
        [_gTimer invalidate];
        _gTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static XIGlobalTimer *_gInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _gInstance = [[XIGlobalTimer alloc] init];
    });
    return _gInstance;
}

- (void)prepares
{
    __weak XIGlobalTimer *weakSelf = self;
    _gTimer = [NSTimer sbt_timerWithTimeInterval:1 repeats:YES block:^{
        XIGlobalTimer *strongSelf = weakSelf;
        [strongSelf tick];
    }];
    [[NSRunLoop currentRunLoop] addTimer:_gTimer forMode:NSRunLoopCommonModes];
}

- (void)tick
{
    self.tickCounter++;
#if DEBUG
    NSLog(@"%s, active timer=%ld, run %lds", __FUNCTION__, (long)self.observersCount,(long)self.tickCounter);
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:XIGlobalTimerTickEventNotification
                                                        object:nil
                                                      userInfo:nil];
}

- (void)enqueue
{
    self.observersCount++;
    if(self.observersCount>0 && (!self.gTimer || [self.gTimer isValid]==NO)){
        [self prepares];
    }
}

- (void)dequeue
{
    self.observersCount--;
    if(self.observersCount<0){
        self.observersCount = 0;
    }
    if(self.observersCount==0 && [self.gTimer isValid]){
        [self.gTimer invalidate];
        self.gTimer = nil;
    }
}

- (void)didEnterBackground:(NSNotification *)notification
{
    [_gTimer setFireDate:[NSDate distantFuture]];
}

- (void)didBecomeActive:(NSNotification *)notification
{
    if([_gTimer isValid]==NO){
        _gTimer = nil;
        [self prepares];
    }
    [_gTimer setFireDate:[[NSDate date] dateByAddingTimeInterval:0.5]];
}

@end


@interface XIForegroundRepeatsTimer ()
@property(nonatomic, copy) dispatch_block_t tickHandler;
@property(nonatomic, assign) NSInteger tickCounter;
@property(nonatomic, assign) BOOL paused;
@end

@implementation XIForegroundRepeatsTimer

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:XIGlobalTimerTickEventNotification
                                                  object:nil];
    ///保证定时任务进队和出队一对一出现
    if(!self.paused){
        self.paused = YES;
    }
}

+ (void)initialize
{
    if (self == [XIForegroundRepeatsTimer class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [XIGlobalTimer sharedInstance];
        });
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.paused = NO;
        [[XIGlobalTimer sharedInstance] enqueue];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tick)
                                                     name:XIGlobalTimerTickEventNotification
                                                   object:nil];
    }
    return self;
}

+ (XIForegroundRepeatsTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                                         block:(dispatch_block_t)block
{
    XIForegroundRepeatsTimer *timer = [[XIForegroundRepeatsTimer alloc] init];
    timer.timeInterval = interval;
    timer.tickHandler = block;
    return timer;
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval
{
    _timeInterval = timeInterval;
    self.tickCounter = 0;
}

- (void)setPaused:(BOOL)paused
{
    if(_paused!=paused){
        if(paused){
            [[XIGlobalTimer sharedInstance] dequeue];
        }
        else{
            [[XIGlobalTimer sharedInstance] enqueue];
        }
        _paused = paused;
    }
}

- (BOOL)isActive
{
    return !self.paused;
}

- (void)tick
{
    if(self.paused || !self.tickHandler){
        return;
    }
    
    if(self.tickCounter>=self.timeInterval){
        self.tickCounter = 0;
        if(self.tickHandler){
            self.tickHandler();
        }
    }
    else{
        self.tickCounter++;
    }
}

- (void)pause
{
    self.paused = YES;
}

- (void)resume
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.paused = NO;
    });
}

- (void)reset
{
    self.paused = YES;
    self.tickCounter = 0;
}

@end
