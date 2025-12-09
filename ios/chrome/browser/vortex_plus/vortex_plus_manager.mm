// ios/chrome/browser/vortex_plus/vortex_plus_manager.mm

#import "ios/chrome/browser/vortex_plus/vortex_plus_manager.h"
#import "third_party/revenuecat/ios/vortex_revenuecat_shim.h"

@interface VortexPlusManager ()
@property(nonatomic, assign, readwrite) BOOL isVortexPlusEnabled;
@property(nonatomic, strong) NSHashTable<id<VortexPlusObserver>>* observers;
@end

@implementation VortexPlusManager

+ (instancetype)sharedManager {
  static VortexPlusManager* instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[VortexPlusManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)init {
  NSAssert(NO, @"Use +sharedManager");
  return [self initPrivate];
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _isVortexPlusEnabled = NO;
    _observers = [NSHashTable weakObjectsHashTable];
  }
  return self;
}

- (void)addObserver:(id<VortexPlusObserver>)observer {
  if (!observer) {
    return;
  }
  @synchronized(self) {
    [self.observers addObject:observer];
  }
}

- (void)removeObserver:(id<VortexPlusObserver>)observer {
  if (!observer) {
    return;
  }
  @synchronized(self) {
    [self.observers removeObject:observer];
  }
}

- (void)notifyObservers {
  NSArray* snapshot;
  @synchronized(self) {
    snapshot = self.observers.allObjects;
  }
  for (id<VortexPlusObserver> observer in snapshot) {
    [observer vortexPlusManagerDidUpdateIsVortexPlusEnabled:self.isVortexPlusEnabled];
  }
}

#pragma mark - Fake connection logic

- (void)enablePlus {
  if (self.isVortexPlusEnabled) {
    return;
  }

    NSLog(@"[VortexPlusManager] fake enablePlus requested");
  self.isVortexPlusEnabled = YES;
  [self notifyObservers];

  // Fake async success after 0.7s
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(0.7 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    self.isVortexPlusEnabled = YES;
    NSLog(@"[VortexPlusManager] fake enablePlus success");
    [self notifyObservers];
  });
}

- (void)disablePlus {
  if (!self.isVortexPlusEnabled) {
    return;
  }

  NSLog(@"[VortexPlusManager] fake disablePlus requested");
  self.isVortexPlusEnabled = NO;
  [self notifyObservers];
}

#pragma mark - RevenueCat Integration

- (void)syncWithRevenueCat {
  NSLog(@"[VortexPlusManager] Syncing premium status with RevenueCat...");

  [VortexRevenueCatShim isUserPremiumWithCompletion:^(BOOL isPremium, NSError* error) {
    if (error) {
      NSLog(@"[VortexPlusManager] Error syncing premium status: %@", error.localizedDescription);
      return;
    }

    BOOL changed = (self.isVortexPlusEnabled != isPremium);
    self.isVortexPlusEnabled = isPremium;

    NSLog(@"[VortexPlusManager] Premium status synced: %@", isPremium ? @"YES" : @"NO");

    if (changed) {
      [self notifyObservers];
    }
  }];
}


@end
