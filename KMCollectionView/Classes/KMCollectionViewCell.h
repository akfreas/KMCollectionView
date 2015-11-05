@class KMCellAction;

@interface KMCollectionViewCell : UICollectionViewCell
- (void)_invalidateCollectionViewLayout;

- (void)configureCellDataWithObject:(NSObject *)object;

- (CGSize)prepreferredLayoutSizeFittingSize:(CGSize)targetSize;
@end

@interface KMCollectionViewCell (Private)
- (void)openActionPane;
- (void)setCellActions:(NSArray<KMCellAction *>*)actions;
@end
