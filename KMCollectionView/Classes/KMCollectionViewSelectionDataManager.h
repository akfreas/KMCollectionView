#import "KMCollectionViewDataManager.h"

@interface KMCollectionViewSelectionDataManager : KMCollectionViewDataManager

@property (nonatomic, readonly) NSInteger selectedItemCount;

- (void)selectDataAtIndexPath:(NSIndexPath *)indexPath;
- (void)selectDataAtIndexPaths:(NSArray *)indexPaths;
- (void)deselectDataAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)dataIsSelectedAtIndexPath:(NSIndexPath *)indexPath;


@end
