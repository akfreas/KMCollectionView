#import "KMCollectionViewCellMapping.h"
#import "KMCollectionViewDataManager.h"
#import "KMCollectionViewContentLoadingInfo.h"

@protocol KMCollectionViewDataSourceDelegate;

@interface KMCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic) KMCollectionViewDataManager *dataManager;
@property (nonatomic) NSString *cancelationID;
@property (nonatomic) BOOL obscuredByPlaceholder;
@property (nonatomic) NSString *loadingState;
@property (nonatomic) NSError *loadingError;

- (void)setNeedsLoadContent;
- (void)loadContent;
- (void)loadContentWithBlock:(void(^)(KMCollectionViewContentLoadingInfo *))block;

- (void)notifyDidReloadData;
- (void)notifyDidReloadSection:(NSInteger)section;
- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView NS_REQUIRES_SUPER;
- (void)updateMappingForGlobalSection:(NSInteger)globalSection;
- (void)notifyItemsInsertedAtIndexPaths:(NSArray *)insertedIndexPaths;
- (void)notifyItemsRefreshedAtIndexPaths:(NSArray *)refreshedIndexPaths;
- (void)notifyItemsRemovedAtIndexPaths:(NSArray *)removedIndexPaths;
- (void)notifyItemMovedFromIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
- (void)notifyBatchUpdate:(dispatch_block_t)update;
- (void)notifyBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete;
- (void)notifyWantsInvalidateLayout;
- (void)notifyWillLoadContent;
- (void)notifyWantsToIncreaseVerticalContentOffset:(CGFloat)delta;
- (void)notifyWantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position;
- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position;
- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)(UICollectionReusableView *))completion;
- (void)notifyWantsToScrollToSupplementaryView:(UICollectionReusableView *)view scrollPosition:(UICollectionViewScrollPosition)position completion:(void(^)())completion;
- (void)notifySectionsInsertedAtIndexSet:(NSIndexSet *)indexSet;
- (void)notifySectionsRemovedAtIndexSet:(NSIndexSet *)indexSet;

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath;

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForSectionAtIndex:(NSInteger)section;
- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForHeaderInSection:(NSInteger)section;
- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForFooterInSection:(NSInteger)section;



@end


@protocol KMCollectionViewDataSourceDelegate <NSObject>

@optional

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)(UICollectionReusableView *))completion;
- (void)dataSourceDidReloadData:(KMCollectionViewDataSource *)dataSource;
- (void)dataSourceWantsToIncreaseVerticalContentOffset:(CGFloat)delta;
- (void)dataSourceWantsToInvalidateLayout:(KMCollectionViewDataSource *)dataSource;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didReloadSections:(NSIndexSet *)sections;
- (void)dataSourceWillLoadContent:(KMCollectionViewDataSource *)dataSource;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didLoadContentWithError:(NSError *)error;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertSectionAtIndexSet:(NSIndexSet *)indexSet;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveSectionAtIndexSet:(NSIndexSet *)indexSet;
- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryView:(UICollectionReusableView *)view scrollPosition:(UICollectionViewScrollDirection)position completion:(void(^)())completion;
@end
