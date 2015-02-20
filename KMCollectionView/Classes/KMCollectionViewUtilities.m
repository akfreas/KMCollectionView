#import "KMCollectionViewUtilities.h"

@implementation KMCollectionViewUtilities

+ (NSIndexPath *)mappedIndexPathForGlobalIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *mapped = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    return mapped;
}
@end

@implementation NSArray (IndexPaths)

- (NSArray *)indexPathsForArray
{
    NSMutableArray *idxArray = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *idxPath = [NSIndexPath indexPathForItem:idx inSection:0];
        [idxArray addObject:idxPath];
    }];
    return idxArray;
}
@end