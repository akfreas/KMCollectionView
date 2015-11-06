@class KMCellAction;

@interface KMCollectionViewCell : UICollectionViewCell
- (void)_invalidateCollectionViewLayout;

- (void)configureCellDataWithObject:(NSObject *)object;

- (CGSize)prepreferredLayoutSizeFittingSize:(CGSize)targetSize;
@end

@interface KMCollectionViewCell (Private)

- (void)openActionPaneWithActions:(NSArray<KMCellAction *>*)actions;
- (void)setCellActions:(NSArray<KMCellAction *>*)actions;
- (void)closeActionPane;

@end
