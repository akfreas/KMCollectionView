@interface KMCollectionViewCell : UICollectionViewCell
- (void)_invalidateCollectionViewLayout;

- (void)configureCellDataWithObject:(NSObject *)object;

- (CGSize)prepreferredLayoutSizeFittingSize:(CGSize)targetSize;
@end
