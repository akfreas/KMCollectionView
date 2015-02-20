#import "KMCollectionViewSelectionDataManager.h"
#import "KMCollectionViewDataManager_private.h"

static NSString *kSelectedItemCountKey = @"selectedItemCount";

@interface KMCollectionViewSelectionDataManager ()
@property (nonatomic) NSMutableDictionary *dataSelection;
@end

@implementation KMCollectionViewSelectionDataManager

+ (BOOL)automaticallyNotifiesObserversOfSelectedItemCount
{
    return NO;
}

- (NSMutableDictionary *)dataSelection
{
    if (_dataSelection == nil) {
        _dataSelection = [NSMutableDictionary dictionary];
    }
    return _dataSelection;
}

#pragma mark Public Methods

- (void)saveSection:(NSInteger)section withCompletion:(void (^)(NSArray *, KMCollectionViewDataManager *))completion
{
    NSNumber *sectionKey = @(section);
    NSDictionary *sectionData = self.dataSelection[sectionKey];
    __block NSMutableArray *rowDataArray = [NSMutableArray array];
    NSArray *arr = [[sectionData allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSNumber *key1, NSNumber *key2) {
        return [key1 compare:key2];
    }];
    for (NSNumber *key in arr) {
        [rowDataArray addObject:sectionData[key]];
    }
    completion(rowDataArray, self);
}

- (void)selectDataAtIndexPaths:(NSArray *)indexPaths
{
    for (NSIndexPath *indexPath in indexPaths) {
        [self selectDataAtIndexPath:indexPath];
    }
}

- (void)selectDataAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *selectionAtSection = self.dataSelection[@(indexPath.section)];
    if (selectionAtSection == nil) {
        self.dataSelection[@(indexPath.section)] = [NSMutableDictionary dictionary];
    }
    id selection = self.managedDataMap[@(indexPath.section)][@(indexPath.row)];
    [self willChangeValueForKey:kSelectedItemCountKey];
    self.dataSelection[@(indexPath.section)][@(indexPath.row)] = selection;
    [self didChangeValueForKey:kSelectedItemCountKey];
}

- (void)deselectDataAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.dataSelection[@(indexPath.section)][@(indexPath.row)] != nil) {
        [self willChangeValueForKey:kSelectedItemCountKey];
        [self.dataSelection[@(indexPath.section)] removeObjectForKey:@(indexPath.row)];
        [self didChangeValueForKey:kSelectedItemCountKey];
    }
}

- (BOOL)dataExistsAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.managedDataMap[@(indexPath.section)][@(indexPath.row)] != nil  ) {
        return YES;
    }
    return NO;
}

- (BOOL)dataIsSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    id selection = self.dataSelection[@(indexPath.section)][@(indexPath.row)];
    if (selection == nil) {
        return NO;
    }
    return YES;
}

#pragma mark Accessors

- (NSInteger)selectedItemCount
{
    __block NSInteger selectedCount = 0;
    [self.dataSelection enumerateKeysAndObjectsUsingBlock:^(NSNumber *section, NSDictionary *map, BOOL *stop) {
        selectedCount += [map count];
    }];
    return selectedCount;
}

#pragma mark Private Methods

- (void)toggleSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self dataIsSelectedAtIndexPath:indexPath]) {
        [self deselectDataAtIndexPath:indexPath];
    } else {
        [self selectDataAtIndexPath:indexPath];
    }
}

#pragma mark UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldRefreshItemAfterSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionExistsAtIndexPath:indexPath]) {
        return NO;
    }
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionExistsAtIndexPath:indexPath] || [self dataExistsAtIndexPath:indexPath]) {
        return YES;
    }
    
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionExistsAtIndexPath:indexPath]) {
        [self performActionAtIndexPath:indexPath];
        return;
    }
    [self toggleSelectionAtIndexPath:indexPath];
}

@end
