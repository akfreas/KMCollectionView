#import "KMCollectionViewDataManager.h"
#import "KMCollectionViewDataManager_private.h"
#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewCell.h"

@interface KMCollectionViewDataManager ()

@property (nonatomic) NSMutableDictionary *managedDataMap;
@property (nonatomic) NSMutableDictionary *actionMap;

@end

static NSString *kItemCountKey = @"itemCount";

@implementation KMCollectionViewDataManager

+ (BOOL)automaticallyNotifiesObserversOfItemCount
{
    return NO;
}

#pragma mark Public Methods

- (void)addViewAction:(KMDataManagerViewActionBlock)action forIndexPath:(NSIndexPath *)indexPath
{
    self.actionMap[indexPath] = action;
}

- (void)removeViewActionAtIndexPath:(NSIndexPath *)indexPath
{
    [self.actionMap removeObjectForKey:indexPath];
}

- (void)moveViewActionAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    KMDataManagerViewActionBlock actionBlock = self.actionMap[sourceIndexPath];
    [self.actionMap removeObjectForKey:sourceIndexPath];
    self.actionMap[destinationIndexPath] = actionBlock;
}

- (void)addManagedData:(id)data atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *selectionAtSection = self.managedDataMap[@(indexPath.section)];
    if (selectionAtSection == nil) {
        self.managedDataMap[@(indexPath.section)] = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *itemAtIndexPath = self.managedDataMap[@(indexPath.section)][@(indexPath.row)];
    if (itemAtIndexPath == nil) {
        [self willChangeValueForKey:kItemCountKey];
        self.managedDataMap[@(indexPath.section)][@(indexPath.row)] = data;
        [self didChangeValueForKey:kItemCountKey];
    } else {
        self.managedDataMap[@(indexPath.section)][@(indexPath.row)] = data;
    }
}

- (NSIndexPath *)appendManagedData:(id)data inSection:(NSInteger)section
{
    NSDictionary *sectionDict = self.managedDataMap[@(section)];
    __block NSNumber *lastIndex = @(0);
    NSInteger appendedIndex = 0;
    if ([sectionDict count] > 0) {
        [sectionDict enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, id obj, BOOL *stop) {
            if ([lastIndex compare:index] == NSOrderedAscending) {
                lastIndex = index;
            }
        }];
        appendedIndex = [lastIndex integerValue] + 1;
    }
    NSIndexPath *lastIndexPathInSection = [NSIndexPath indexPathForRow:appendedIndex inSection:section];
    [self addManagedData:data atIndexPath:lastIndexPathInSection];
    return lastIndexPathInSection;
}

- (void)removeManagedDataAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.managedDataMap[@(indexPath.section)][@(indexPath.row)] != nil) {
        [self willChangeValueForKey:kItemCountKey];
        [self.managedDataMap[@(indexPath.section)] removeObjectForKey:@(indexPath.row)];
        [self didChangeValueForKey:kItemCountKey];
    }
}

- (void)resetManagedData
{
    self.managedDataMap = [NSMutableDictionary dictionary];
}

- (NSInteger)itemCount
{
    __block NSInteger itemCount = 0;
    [self.managedDataMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *section, NSDictionary *map, BOOL *stop) {
        itemCount += [map count];
    }];
    return itemCount;
}

- (void)saveAllSectionsWithCompletion:(void (^)(NSArray *, KMCollectionViewDataManager *))completion
{
    __block NSMutableArray *sectionDataArray = [NSMutableArray arrayWithArray:[self.managedDataMap allKeys]];
    [self.managedDataMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *sectionKey, NSDictionary *sectionData, BOOL *stop) {
        __block NSMutableArray *rowDataArray = [NSMutableArray arrayWithArray:[sectionData allKeys]];
        [sectionData enumerateKeysAndObjectsUsingBlock:^(NSNumber *rowKey, id rowDataItem, BOOL *stop1) {
            [rowDataArray replaceObjectAtIndex:[rowKey integerValue] withObject:rowDataItem];
        }];
        [sectionDataArray replaceObjectAtIndex:[sectionKey integerValue] withObject:rowDataArray];
    }];
    completion(sectionDataArray, self);
}

- (void)saveSection:(NSInteger)section withCompletion:(void (^)(NSArray *, KMCollectionViewDataManager *))completion
{
    NSNumber *sectionKey = @(section);
    NSDictionary *sectionData = self.managedDataMap[sectionKey];
    __block NSMutableArray *rowDataArray = [NSMutableArray arrayWithArray:[sectionData allKeys]];
    [sectionData enumerateKeysAndObjectsUsingBlock:^(NSNumber *rowKey, id rowDataItem, BOOL *stop1) {
        [rowDataArray replaceObjectAtIndex:[rowKey integerValue] withObject:rowDataItem];
    }];
    completion(rowDataArray, self);
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldRefreshItemAfterSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionExistsAtIndexPath:indexPath]) {
        [self performActionAtIndexPath:indexPath];
        return;
    }
}

#pragma mark - Private Methods


- (NSMutableDictionary *)managedDataMap
{
    if (_managedDataMap == nil) {
        _managedDataMap = [NSMutableDictionary dictionary];
    }
    return _managedDataMap;
}

- (NSMutableDictionary *)actionMap
{
    if (_actionMap == nil) {
        _actionMap = [NSMutableDictionary dictionary];
    }
    return _actionMap;
}

- (BOOL)actionExistsAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.actionMap[indexPath]) {
        return YES;
    }
    return NO;
}

- (void)performActionAtIndexPath:(NSIndexPath *)indexPath
{
    KMDataManagerViewActionBlock block = self.actionMap[indexPath];
    [self.delegate dataManager:self wantsToPerformViewAction:block];
}


#pragma mark UICollectionViewFlowLayout
/*
 This code that helps with the collection view layout should really not be in this
 class.  In the future, it should be moved to the layout itself, where the layout can
 connect to the datasource and query these methods itself.
 */

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    UIEdgeInsets insets = UIEdgeInsetsEqualToEdgeInsets(mapping.edgeInsets, UIEdgeInsetsZero) == NO ? mapping.edgeInsets : UIEdgeInsetsZero;
    return insets;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    CGFloat minimumSpacing = mapping.minimumInterItemSpacing;
    return minimumSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForIndexPath:indexPath];
    CGSize cellSize = mapping.size;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    }
    
    if (mapping.options & KMCollectionViewCellMappingWidthAsPercentage) {
        cellSize.width = collectionView.frame.size.width * cellSize.width;
    }
    if (mapping.options & KMCollectionViewCellMappingHeightUndefined) {
        cellSize.height = 44.0f;
    }
    if (mapping.options & KMCollectionViewCellMappingSquare) {
        cellSize.height = cellSize.width;
    }
    if (mapping.options & KMCollectionViewCellMappingAutoLayoutSize) {
        UICollectionViewCell *sizingCell = [[NSClassFromString(mapping.cellClassString) alloc] initWithFrame:CGRectZero];
        if ([sizingCell isKindOfClass:[KMCollectionViewCell class]]) {
            NSObject *cellData = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellDataForIndexPath:indexPath];
            KMCollectionViewCell *collectionViewCell = (KMCollectionViewCell *)sizingCell;
            [collectionViewCell configureCellDataWithObject:cellData];
            CGFloat requiredWidth = cellSize.width;
            
            // NOTE: here is where we ask our sizing cell to compute what height it needs
            CGSize targetSize = CGSizeMake(requiredWidth, 0.0);
            CGSize computedSize = [collectionViewCell prepreferredLayoutSizeFittingSize:targetSize];
            
            // collection view doesn't like cells with an height of zero
            if (computedSize.height > 0.0) {
                cellSize.height = computedSize.height;
            } else {
                cellSize.height = 44.0f;
            }
            
            if (computedSize.width > 0.0 && cellSize.width <= 1.0) {
                cellSize.width = computedSize.width;
            } else {
                cellSize.width = collectionView.frame.size.width;
            }
        } else {
            cellSize.width = collectionView.frame.size.width;
            cellSize.height = 44.0f;
        }
    }
    return cellSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    return mapping.minimumLineSpacing;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForHeaderInSection:section];
    CGSize cellSize = mapping? mapping.size : CGSizeZero;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    }
    return cellSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    
    KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)collectionView.dataSource collectionView:collectionView cellInformationForFooterInSection:section];
    CGSize cellSize = mapping? mapping.size : CGSizeZero;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionView.frame.size.width;
    }
    return cellSize;
}


@end

