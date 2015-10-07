#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewContentLoadingInfo.h"
#import "KMCollectionViewPlaceholderView.h"

NSString *const KMNeedsOverrideExceptionName = @"KMNeedsOverrideException";
NSString *const kKMCollectionElementKindPlaceHolder = @"kKMCollectionElementKindPlaceHolder";

#define KOMOOT_ASSERT_MAIN_THREAD NSAssert([NSThread isMainThread], @"This method must be called on the main thread")


@interface KMCollectionViewDataSource ()
@property (nonatomic, copy) dispatch_block_t pendingUpdateBlock;
@property (nonatomic) KMCollectionViewPlaceholderView *placeHolderView;
@property (nonatomic) KMCollectionViewContentLoadingInfo *currentLoadingInfo;
@property (nonatomic) BOOL isLoading;
@end

@implementation KMCollectionViewDataSource

@synthesize loadingState = _loadingState;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cancelationID = nil;
    }
    return self;
}

- (NSInteger)numberOfSections
{
    return 1;
}

- (void)loadContent
{
}

- (void)setLoadingState:(NSString *)loadingState
{
    _loadingState = loadingState;
}

- (NSString *)loadingState
{
    return _loadingState;
}

- (void)loadContentWithBlock:(void (^)(KMCollectionViewContentLoadingInfo *))block
{
    [self beginLoading];
    __weak typeof(&*self) weakself = self;

    KMCollectionViewContentLoadingInfo *loadingInfo = [KMCollectionViewContentLoadingInfo loadingInfoWithCompletionHandler:^(NSString *state, NSError *err, KMLoadingUpdateBlock update) {
        if (state == nil) {
            return;
        }
        [weakself endLoadingWithState:state error:err update:^{
            KMCollectionViewDataSource *me = weakself;
            if (update && me) {
                update(me);
            }
        }];
    }];
    
    self.currentLoadingInfo.current = NO;
    self.currentLoadingInfo = loadingInfo;
    block(loadingInfo);
}

- (void)endLoadingWithState:(NSString *)newState error:(NSError *)error update:(dispatch_block_t)update
{
    self.loadingState = newState;
    self.loadingError = error;
    if (self.shouldDisplayPlaceholder) {
        if (update) {
            [self enqueuePendingUpdateBlock:update];
        }
    } else {
        [self notifyBatchUpdate:^{
            [self executePendingUpdates];
            if (update) {
                update();
            }
        }];
    }
    [self notifyContentLoadedWithError:error];
}


- (void)setNeedsLoadContent
{
    KOMOOT_ASSERT_MAIN_THREAD;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadContent) object:nil];
    [self performSelector:@selector(loadContent) withObject:nil afterDelay:0];
}

- (void)notifyDidReloadSection:(NSInteger)section
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didReloadSections:)]) {
        [delegate dataSource:self didReloadSections:[NSIndexSet indexSetWithIndex:section]];
    }
}

- (void)notifyContentLoadedWithError:(NSError *)error
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didLoadContentWithError:)]) {
        [delegate dataSource:self didLoadContentWithError:error];
    }
}

- (void)notifyDidReloadData
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceDidReloadData:)]) {
        [delegate dataSourceDidReloadData:self];
    }
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [collectionView registerClass:[KMCollectionViewPlaceholderView class] forSupplementaryViewOfKind:kKMCollectionElementKindPlaceHolder withReuseIdentifier:NSStringFromClass([KMCollectionViewPlaceholderView class])];
}

- (void)updateMappingForGlobalSection:(NSInteger)globalSection
{
    [NSException raise:KMNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    [NSException raise:KMNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.numberOfSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [NSException raise:KMNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
    return 0;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath
{
    [NSException raise:KMNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
    return nil;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForFooterInSection:(NSInteger)section
{
    return nil;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForSectionAtIndex:(NSInteger)section
{
    return nil;
}


- (NSObject *)collectionView:(UICollectionView *)collectionView cellDataForIndexPath:(NSIndexPath *)indexPath
{
    [NSException raise:KMNeedsOverrideExceptionName format:@"Method: %@", NSStringFromSelector(_cmd)];
    return nil;
}


- (void)notifyBatchUpdate:(dispatch_block_t)update
{
    [self notifyBatchUpdate:update complete:nil];
}

- (void)notifyBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:performBatchUpdate:complete:)]) {
        [delegate dataSource:self performBatchUpdate:update complete:complete];
    }
    else {
        if (update) {
            update();
        }
        if (complete) {
            complete();
        }
    }
}



- (void)executePendingUpdates
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    dispatch_block_t block = _pendingUpdateBlock;
    _pendingUpdateBlock = nil;
    if (block)
        block();
}

- (void)enqueuePendingUpdateBlock:(dispatch_block_t)block
{
    dispatch_block_t update;
    
    if (_pendingUpdateBlock) {
        dispatch_block_t oldPendingUpdate = _pendingUpdateBlock;
        update = ^{
            oldPendingUpdate();
            block();
        };
    }
    else
        update = block;
    
    self.pendingUpdateBlock = update;
}


- (void)beginLoading
{
    self.isLoading = YES;
    self.loadingState = kKMCollectionViewLoadingStateLoading;
    [self notifyWillLoadContent];
}

#pragma mark Placeholder

- (BOOL)shouldDisplayPlaceholder
{
    NSString *loadingState = self.loadingState;
    if ([loadingState isEqualToString:kKMCollectionViewLoadingStateFailed])
        return YES;
    if (![loadingState isEqualToString:kKMCollectionViewLoadingStateLoading] && ![loadingState isEqualToString:kKMCollectionViewLoadingStateInitial])
        return NO;
    return YES;
}

#pragma mark Notification Methods

- (void)notifyWillLoadContent
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceWillLoadContent:)]) {
        [delegate dataSourceWillLoadContent:self];
    }
}

- (void)notifyItemsInsertedAtIndexPaths:(NSArray *)insertedIndexPaths
{
    KOMOOT_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder) {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsInsertedAtIndexPaths:insertedIndexPaths];
        }];
        return;
    }
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
        [delegate dataSource:self didInsertItemsAtIndexPaths:insertedIndexPaths];
    }
}

- (void)notifyItemsRefreshedAtIndexPaths:(NSArray *)refreshedIndexPaths
{
    KOMOOT_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder) {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsRefreshedAtIndexPaths:refreshedIndexPaths];
        }];
        return;
    }
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRefreshItemsAtIndexPaths:)]) {
        [delegate dataSource:self didRefreshItemsAtIndexPaths:refreshedIndexPaths];
    }
}

- (void)notifyItemsRemovedAtIndexPaths:(NSArray *)removedIndexPaths
{
    KOMOOT_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder) {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemsRemovedAtIndexPaths:removedIndexPaths];
        }];
        return;
    }
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRemoveItemsAtIndexPaths:)]) {
        [delegate dataSource:self didRemoveItemsAtIndexPaths:removedIndexPaths];
    }
}


- (void)notifyItemMovedFromIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    KOMOOT_ASSERT_MAIN_THREAD;
    if (self.shouldDisplayPlaceholder) {
        __weak typeof(&*self) weakself = self;
        [self enqueuePendingUpdateBlock:^{
            [weakself notifyItemMovedFromIndexPath:indexPath toIndexPath:newIndexPath];
        }];
        return;
    }
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {
        [delegate dataSource:self didMoveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
    }
}

- (void)notifySectionsInsertedAtIndexSet:(NSIndexSet *)indexSet
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didInsertSectionAtIndexSet:)]) {
        [delegate dataSource:self didInsertSectionAtIndexSet:indexSet];
    }
}

- (void)notifySectionsRemovedAtIndexSet:(NSIndexSet *)indexSet
{
    KOMOOT_ASSERT_MAIN_THREAD;
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:didRemoveSectionAtIndexSet:)]) {
        [delegate dataSource:self didRemoveSectionAtIndexSet:indexSet];
    }
}

- (void)notifyWantsToIncreaseVerticalContentOffset:(CGFloat)delta
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceWantsToIncreaseVerticalContentOffset:)]) {
        [delegate dataSourceWantsToIncreaseVerticalContentOffset:delta];
    }
}

- (void)notifyWantsInvalidateLayout
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSourceWantsToInvalidateLayout:)]) {
        [delegate dataSourceWantsToInvalidateLayout:self];
    }
}

- (void)notifyWantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated completion:(void(^)(UICollectionViewCell *))completion
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:wantsToScrollToItemAtIndexPath:scrollPosition:animated:completion:)]) {
        [delegate dataSource:self wantsToScrollToItemAtIndexPath:indexPath scrollPosition:position animated:animated completion:completion];
    } else {
        completion(nil);
    }
}

- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:wantsToScrollToSupplementaryViewOfType:inSection:scrollPosition:)]) {
        [delegate dataSource:self wantsToScrollToSupplementaryViewOfType:type inSection:section scrollPosition:position];
    }
}

- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)(UICollectionReusableView *))completion
{
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:wantsToScrollToSupplementaryViewOfType:inSection:scrollPosition:completion:)]) {
        [delegate dataSource:self wantsToScrollToSupplementaryViewOfType:type inSection:section scrollPosition:position completion:completion];
    }
}

- (void)notifyWantsToScrollToSupplementaryView:(UICollectionReusableView *)view scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)())completion
{
    
    KOMOOT_ASSERT_MAIN_THREAD;
    
    id<KMCollectionViewDataSourceDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(dataSource:wantsToScrollToSupplementaryView:scrollPosition:completion:)]) {
        [delegate dataSource:self wantsToScrollToSupplementaryView:view scrollPosition:position completion:completion];
    }
}

@end
