#import "KMCollectionViewContentLoadingInfo.h"

NSString *const kKMCollectionViewLoadingStateInitial = @"kKMCollectionViewLoadingStateInitial";
NSString *const kKMCollectionViewLoadingStateLoaded = @"kKMCollectionViewLoadingStateLoaded";
NSString *const kKMCollectionViewLoadingStateLoading = @"kKMCollectionViewLoadingStateLoading";
NSString *const kKMCollectionViewLoadingStateFailed = @"kKMCollectionViewLoadingStateFailed";

@interface KMCollectionViewContentLoadingInfo ()
@property (nonatomic, copy) void (^completionHandler)(NSString *newState, NSError *err, KMLoadingUpdateBlock);
@end

@implementation KMCollectionViewContentLoadingInfo

+ (instancetype)loadingInfoWithCompletionHandler:(void (^)(NSString *, NSError *, KMLoadingUpdateBlock))completion
{
    KMCollectionViewContentLoadingInfo *loadingInfo = [KMCollectionViewContentLoadingInfo new];
    loadingInfo.completionHandler = completion;
    loadingInfo.current = YES;
    return loadingInfo;
}

- (void)doneWithNewState:(NSString *)state error:(NSError *)error update:(KMLoadingUpdateBlock)update
{
    void (^block)(NSString *, NSError *, KMLoadingUpdateBlock) = self.completionHandler;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        block(state, error, update);
    });
}

#pragma mark Public

- (void)doneLoadingResult
{
    [self doneWithNewState:kKMCollectionViewLoadingStateLoaded error:nil update:nil];
}

- (void)doneLoadingResultWithEnqueuedUpdateBlock:(KMLoadingUpdateBlock)block
{
    [self doneWithNewState:kKMCollectionViewLoadingStateLoaded error:nil update:block];
}

- (void)ignoreLoadingResult
{
    [self doneWithNewState:nil error:nil update:nil];
}

- (void)doneWithError:(NSError *)error
{
    [self doneWithNewState:kKMCollectionViewLoadingStateFailed error:error update:nil];
}

@end
