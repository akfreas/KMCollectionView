#import <Foundation/Foundation.h>

extern NSString *const kKMCollectionViewLoadingStateInitial;
extern NSString *const kKMCollectionViewLoadingStateLoaded;
extern NSString *const kKMCollectionViewLoadingStateLoading;
extern NSString *const kKMCollectionViewLoadingStateFailed;

typedef void (^KMLoadingUpdateBlock)(id object);


@interface KMCollectionViewContentLoadingInfo : NSObject

@property (nonatomic, getter=isCurrent) BOOL current;

+ (instancetype)loadingInfoWithCompletionHandler:(void(^)(NSString *state, NSError *err, KMLoadingUpdateBlock))completion;

- (void)ignoreLoadingResult;
- (void)doneLoadingResult;
- (void)doneLoadingResultWithEnqueuedUpdateBlock:(KMLoadingUpdateBlock)block;
- (void)doneWithError:(NSError *)error;

@end
