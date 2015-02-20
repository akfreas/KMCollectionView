@interface KMCollectionViewUtilities : NSObject

+ (NSIndexPath *)mappedIndexPathForGlobalIndexPath:(NSIndexPath *)indexPath;

@end

@interface NSArray (IndexPaths)

- (NSArray *)indexPathsForArray;

@end
