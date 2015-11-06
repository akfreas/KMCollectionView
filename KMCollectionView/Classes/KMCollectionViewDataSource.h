#import "KMCollectionViewCellMapping.h"
#import "KMCollectionViewDataManager.h"
#import "KMCollectionViewContentLoadingInfo.h"
#import "KMCellAction.h"

@protocol KMCollectionViewDataSourceDelegate;

@interface KMCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, nullable) KMCollectionViewDataManager * dataManager;
@property (nonatomic, nullable) NSString *cancelationID;
@property (nonatomic) BOOL obscuredByPlaceholder;
@property (nonatomic, nullable) NSString *loadingState;
@property (nonatomic, nullable) NSError *loadingError;

- (void)setNeedsLoadContent;
- (void)loadContent;
- (void)loadContentWithBlock:(void(^ __nonnull)(KMCollectionViewContentLoadingInfo * __nonnull))block;

- (void)notifyDidReloadData;
- (void)notifyDidReloadSection:(NSInteger)section;
- (void)registerReusableViewsWithCollectionView:(UICollectionView * __nonnull)collectionView NS_REQUIRES_SUPER;
- (void)updateMappingForGlobalSection:(NSInteger)globalSection;
- (void)notifyItemsInsertedAtIndexPaths:(NSArray<NSIndexPath *> * __nonnull)insertedIndexPaths;
- (void)notifyItemsRefreshedAtIndexPaths:(NSArray<NSIndexPath *> * __nonnull)refreshedIndexPaths;
- (void)notifyItemsRemovedAtIndexPaths:(NSArray<NSIndexPath *> * __nonnull)removedIndexPaths;
- (void)notifyItemMovedFromIndexPath:(NSIndexPath * __nonnull)indexPath toIndexPath:(NSIndexPath * __nonnull)newIndexPath;
- (void)notifyBatchUpdate:(dispatch_block_t __nonnull)update;
- (void)notifyBatchUpdate:(dispatch_block_t __nonnull)update complete:(dispatch_block_t __nonnull)complete;
- (void)notifyWantsInvalidateLayout;
- (void)notifyWillLoadContent;
- (void)notifyWantsToIncreaseVerticalContentOffset:(CGFloat)delta;
- (void)notifyWantsToScrollToItemAtIndexPath:(NSIndexPath * __nonnull)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated completion:(void(^ __nullable)(UICollectionViewCell * __nonnull))completion;
- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString * __nonnull)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position;
- (void)notifyWantsToScrollToSupplementaryViewOfType:(NSString * __nonnull)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^ __nullable)(UICollectionReusableView * __nonnull))completion;
- (void)notifyWantsToScrollToSupplementaryView:(UICollectionReusableView * __nonnull)view scrollPosition:(UICollectionViewScrollPosition)position completion:(void(^ __nullable)())completion;
- (void)notifySectionsInsertedAtIndexSet:(NSIndexSet * __nonnull)indexSet;
- (void)notifySectionsRemovedAtIndexSet:(NSIndexSet * __nonnull)indexSet;
- (NSInteger)numberOfSections;
- (KMCollectionViewCellMapping * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellInformationForIndexPath:(NSIndexPath * __nonnull)indexPath;
- (NSObject * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellDataForIndexPath:(NSIndexPath * __nonnull)indexPath;
- (NSArray<KMCellAction *>* __nullable)collectionView:(UICollectionView * __nonnull)collectionView cellActionForCellAtIndexPath:(NSIndexPath * __nonnull)indexPath;
- (KMCollectionViewCellMapping * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellInformationForSectionAtIndex:(NSInteger)section;
- (KMCollectionViewCellMapping * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellInformationForHeaderInSection:(NSInteger)section;
- (KMCollectionViewCellMapping * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellInformationForFooterInSection:(NSInteger)section;



@end


@protocol KMCollectionViewDataSourceDelegate <NSObject>

@optional

- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didInsertItemsAtIndexPaths:(NSArray * __nonnull)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didRefreshItemsAtIndexPaths:(NSArray * __nonnull)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didRemoveItemsAtIndexPaths:(NSArray * __nonnull)indexPaths;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didMoveItemAtIndexPath:(NSIndexPath * __nonnull)fromIndexPath toIndexPath:(NSIndexPath * __nonnull)newIndexPath;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath * __nonnull)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated completion:(void(^ __nullable)(UICollectionViewCell * __nonnull))completion;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource wantsToScrollToSupplementaryViewOfType:(NSString * __nonnull)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource wantsToScrollToSupplementaryViewOfType:(NSString * __nonnull)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^ __nonnull)(UICollectionReusableView * __nullable))completion;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource wantsToScrollToSupplementaryView:(UICollectionReusableView * __nonnull)view scrollPosition:(UICollectionViewScrollPosition)position completion:(void(^ __nullable)())completion;

- (void)dataSourceDidReloadData:(KMCollectionViewDataSource * __nonnull)dataSource;
- (void)dataSourceWantsToIncreaseVerticalContentOffset:(CGFloat)delta;
- (void)dataSourceWantsToInvalidateLayout:(KMCollectionViewDataSource * __nonnull)dataSource;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource performBatchUpdate:(dispatch_block_t __nonnull)update complete:(dispatch_block_t __nullable)complete;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didReloadSections:(NSIndexSet * __nonnull)sections;
- (void)dataSourceWillLoadContent:(KMCollectionViewDataSource * __nonnull)dataSource;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didLoadContentWithError:(NSError * __nullable)error;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didInsertSectionAtIndexSet:(NSIndexSet * __nonnull)indexSet;
- (void)dataSource:(KMCollectionViewDataSource * __nonnull)dataSource didRemoveSectionAtIndexSet:(NSIndexSet * __nonnull)indexSet;
@end
