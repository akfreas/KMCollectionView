#import "KMCollectionViewAggregateDataSource.h"
#import "KMCollectionViewUtilities.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewAggregateDataManager.h"
#import "KMCollectionViewAggregateDataSource_private.h"

@interface KMCollectionViewAggregateDataSource () <KMCollectionViewDataSourceDelegate>
@property (nonatomic) NSMutableDictionary *dataSources;
@end

@implementation KMCollectionViewAggregateDataSource

#pragma mark - Public Methods

- (void)addDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section
{
    dataSource.delegate = self;
    dataSource.cancelationID = self.cancelationID;
    self.dataSources[@(section)] = dataSource;
    [self notifySectionsInsertedAtIndexSet:[NSIndexSet indexSetWithIndex:section]];
}

- (void)insertDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
    dataSource.delegate = self;
    dataSource.dataManager.delegate = self.dataManager.delegate;
    NSMutableDictionary *newDatasourceMapping = [NSMutableDictionary dictionary];
    for (NSNumber *number in [self.dataSources allKeys]) {
        if ([number unsignedIntegerValue] < section) {
            [newDatasourceMapping setObject:self.dataSources[number] forKey:number];
        } else if ([number unsignedIntegerValue] >= section) {
            [newDatasourceMapping setObject:self.dataSources[number] forKey:[NSNumber numberWithUnsignedInteger:[number unsignedIntegerValue]+1]];
        }
    }
    [newDatasourceMapping setObject:dataSource forKey:[NSNumber numberWithUnsignedInteger:section]];
    [self notifyBatchUpdate:^{
        self.dataSources = newDatasourceMapping;
        [self notifySectionsInsertedAtIndexSet:indexSet];
    }];
}

- (void)removeDatasourceForGlobalSection:(NSInteger)section notifyBatchUpdate:(BOOL)notify
{
    NSMutableDictionary *newDatasourceMapping = [NSMutableDictionary dictionary];
    KMCollectionViewDataSource *datasource = self.dataSources[@(section)];
    datasource.delegate = nil;
    for (NSNumber *number in [self.dataSources allKeys]) {
        if ([number unsignedIntegerValue] < section) {
            [newDatasourceMapping setObject:self.dataSources[number] forKey:number];
        } else if ([number unsignedIntegerValue] == section) {
            continue;
        } else {
            [newDatasourceMapping setObject:self.dataSources[number] forKey:[NSNumber numberWithUnsignedInteger:[number unsignedIntegerValue]-1]];
        }
    }
    void(^updateBlock)() = ^{
        self.dataSources = newDatasourceMapping;
        [self notifySectionsRemovedAtIndexSet:[NSIndexSet indexSetWithIndex:section]];
    };
    if (notify) {
        [self notifyBatchUpdate:updateBlock];
    } else {
        updateBlock();
    }
}

- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource
{
    [self removeDatasource:dataSource notifyBatchUpdate:YES];
}

- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource notifyBatchUpdate:(BOOL)notify
{
    __block NSNumber *section = nil;
    [self.dataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *dsSection, KMCollectionViewDataSource *existingDS, BOOL *stop) {
        if (existingDS == dataSource) {
            section = dsSection;
            *stop = YES;
        }
    }];
    if (section != nil) {
        [self removeDatasourceForGlobalSection:[section integerValue] notifyBatchUpdate:notify];
    }
}

- (void)removeAllDataSourcesWithBatchUpdate:(BOOL)notify
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        [self.dataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *dsSection, KMCollectionViewDataSource *existingDS, BOOL *stop) {
            [indexSet addIndex:[dsSection integerValue]];
        }];
    [self notifyBatchUpdate:^{
        self.dataSources = [NSMutableDictionary new];
        [self notifySectionsRemovedAtIndexSet:indexSet];
    }];
}

- (NSInteger)globalSectionForDatasourceClass:(Class)dataSourceClass
{
    NSInteger globalSection = NSNotFound;
    for (NSNumber *section in self.dataSources) {
        KMCollectionViewDataSource *dataSource = [self.dataSources objectForKey:section];
        if ([dataSource class] == dataSourceClass) {
            globalSection = [section integerValue];
            break;
        }
    }
    
    return globalSection;
}

- (void)setCancelationID:(NSString *)cancelationID
{
    [self.dataSources enumerateKeysAndObjectsUsingBlock:^(id key, KMCollectionViewDataSource *dataSource, BOOL *stop) {
        dataSource.cancelationID = cancelationID;
    }];
    [super setCancelationID:cancelationID];
}

#pragma mark - Private Methods

- (NSMutableDictionary *)dataSources
{
    if (_dataSources == nil) {
        _dataSources = [NSMutableDictionary new];
    }
    return _dataSources;
}

- (NSInteger)globalSectionForLocalSection:(NSInteger)section fromDataSource:(KMCollectionViewDataSource *)dataSource
{
    __block NSNumber *sectionNumber;
    [self.dataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, KMCollectionViewDataSource *storedDataSource, BOOL *stop) {
        if (dataSource == storedDataSource) {
            sectionNumber = index;
            *stop = YES;
        }
    }];
    NSAssert(sectionNumber != nil, @"no global section found");
    NSInteger adjustedSection = [sectionNumber integerValue] + section;
    return adjustedSection;
}

- (NSIndexPath *)globalIndexPath:(NSIndexPath *)indexPath forIndexPathFromDataSource:(KMCollectionViewDataSource *)dataSource
{
    NSInteger globalSectionNumber = [self globalSectionForLocalSection:indexPath.section fromDataSource:dataSource];
    NSIndexPath *mappedIndexPath = [NSIndexPath indexPathForItem:indexPath.item inSection:globalSectionNumber];
    return mappedIndexPath;
}

- (NSArray *)mappedIndexPathsForIndexPaths:(NSArray *)indexPaths fromDataSource:(KMCollectionViewDataSource *)dataSource
{
    __block NSMutableArray *mappedIndexPaths = [NSMutableArray new];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        [mappedIndexPaths addObject:[self globalIndexPath:indexPath forIndexPathFromDataSource:dataSource]];
    }];
    return mappedIndexPaths;
}

#pragma mark Collection View DataSource Methods
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    for (KMCollectionViewDataSource *datasource in [self.dataSources allValues]) {
        [datasource registerReusableViewsWithCollectionView:collectionView];
    }
}
#pragma clang diagnostic pop

- (id<UICollectionViewDataSource>)datasourceForSection:(NSInteger)section
{
    id <UICollectionViewDataSource> datasource = self.dataSources[@(section)];
    return datasource;
}

- (id<UICollectionViewDataSource>)datasourceForIndexPath:(NSIndexPath *)indexPath
{
    return [self datasourceForSection:indexPath.section];
}

- (NSInteger)sectionForDataSource:(id<UICollectionViewDataSource>)dataSource
{
    NSNumber *path = [[self.dataSources keysOfEntriesPassingTest:^BOOL(NSNumber *key, id<UICollectionViewDataSource>obj, BOOL *stop) {
        if (obj == dataSource) {
            *stop = YES;
            return YES;
        }
        return NO;
    }] anyObject];
    return [path integerValue];
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewDataSource *dataSource = [self datasourceForIndexPath:indexPath];
    KMCollectionViewCellMapping *mapping;
    if ([dataSource respondsToSelector:_cmd]) {
        mapping = [dataSource collectionView:collectionView cellInformationForIndexPath:[KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath]];
    }
    return mapping;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForSectionAtIndex:(NSInteger)section
{
    KMCollectionViewDataSource *dataSource = [self datasourceForSection:section];
    KMCollectionViewCellMapping *mapping;
    if ([dataSource respondsToSelector:_cmd]) {
        mapping = [dataSource collectionView:collectionView cellInformationForSectionAtIndex:section];
    }
    return mapping;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForFooterInSection:(NSInteger)section
{
    KMCollectionViewDataSource *dataSource = [self datasourceForSection:section];
    KMCollectionViewCellMapping *mapping;
    if ([dataSource respondsToSelector:_cmd]) {
        mapping = [dataSource collectionView:collectionView cellInformationForFooterInSection:0];
    }
    return mapping;
}

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForHeaderInSection:(NSInteger)section
{
    KMCollectionViewDataSource *dataSource = [self datasourceForSection:section];
    KMCollectionViewCellMapping *mapping;
    if ([dataSource respondsToSelector:_cmd]) {
        mapping = [dataSource collectionView:collectionView cellInformationForHeaderInSection:0];
    }
    return mapping;
}

- (NSObject *)collectionView:(UICollectionView *)collectionView cellDataForIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewDataSource *dataSource = [self datasourceForIndexPath:indexPath];
    NSObject *cellData = nil;
    if ([dataSource respondsToSelector:_cmd]) {
        cellData = [dataSource collectionView:collectionView cellDataForIndexPath:[KMCollectionViewUtilities mappedIndexPathForGlobalIndexPath:indexPath]];
    }
    return cellData;
}

- (NSArray<KMCellAction *> *)collectionView:(UICollectionView *)collectionView cellActionForCellAtIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewDataSource *dataSource = [self datasourceForIndexPath:indexPath];
    return [dataSource collectionView:collectionView cellActionForCellAtIndexPath:indexPath];
}


- (void)loadContent
{
    for (KMCollectionViewDataSource *dataSource in [self.dataSources allValues]) {
        [dataSource setNeedsLoadContent];
    }
}

- (NSInteger)numberOfSections
{
   return [[self.dataSources allKeys] count];
}


#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [self numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[self datasourceForSection:section] collectionView:collectionView numberOfItemsInSection:0];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self datasourceForIndexPath:indexPath] collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    return [[self datasourceForIndexPath:indexPath] collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

#pragma mark KMCollectionViewDataSourceDelegate

- (void)dataSourceWillLoadContent:(KMCollectionViewDataSource *)dataSource
{
    [self notifyWillLoadContent];
}

- (void)dataSourceWantsToInvalidateLayout:(KMCollectionViewDataSource *)dataSource
{
    [self notifyWantsInvalidateLayout];
}

- (void)dataSourceWantsToIncreaseVerticalContentOffset:(CGFloat)delta
{
    [self notifyWantsToIncreaseVerticalContentOffset:delta];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRegisterClass:(Class)cls withIdentifier:(NSString *)identifier
{
    [super notifyWantsToRegisterClass:cls forIdentifier:identifier];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didInsertItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self notifyItemsInsertedAtIndexPaths:[self mappedIndexPathsForIndexPaths:indexPaths fromDataSource:dataSource]];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRefreshItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self notifyItemsRefreshedAtIndexPaths:[self mappedIndexPathsForIndexPaths:indexPaths fromDataSource:dataSource]];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didRemoveItemsAtIndexPaths:(NSArray *)indexPaths
{
    [self notifyItemsRemovedAtIndexPaths:[self mappedIndexPathsForIndexPaths:indexPaths fromDataSource:dataSource]];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didMoveItemAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    NSIndexPath *mappedFromIndexPath = [[self mappedIndexPathsForIndexPaths:@[fromIndexPath] fromDataSource:dataSource] firstObject];
    NSIndexPath *mappedToIndexPath = [[self mappedIndexPathsForIndexPaths:@[newIndexPath] fromDataSource:dataSource] firstObject];
    [self notifyItemMovedFromIndexPath:mappedFromIndexPath toIndexPath:mappedToIndexPath];
}

- (void)dataSourceDidReloadData:(KMCollectionViewDataSource *)dataSource
{
    [self.delegate dataSourceDidReloadData:dataSource];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource didReloadSections:(NSIndexSet *)sections
{
    NSInteger pathForSource = [self sectionForDataSource:dataSource];
    [self.delegate dataSource:dataSource didReloadSections:[NSIndexSet indexSetWithIndex:pathForSource]];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource performBatchUpdate:(dispatch_block_t)update complete:(dispatch_block_t)complete
{
    [self.delegate dataSource:self performBatchUpdate:update complete:complete];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position
{
    [self.delegate dataSource:self wantsToScrollToSupplementaryViewOfType:type inSection:[self globalSectionForLocalSection:section fromDataSource:dataSource] scrollPosition:position];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryViewOfType:(NSString *)type inSection:(NSInteger)section scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)(UICollectionReusableView *))completion
{
    [self.delegate dataSource:self wantsToScrollToSupplementaryViewOfType:type inSection:[self globalSectionForLocalSection:section fromDataSource:dataSource] scrollPosition:position completion:completion];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToSupplementaryView:(UICollectionReusableView *)view scrollPosition:(UICollectionViewScrollPosition)position completion:(void (^)())completion
{
    [self.delegate dataSource:self wantsToScrollToSupplementaryView:view scrollPosition:position completion:completion];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToScrollToItemAtIndexPath:(NSIndexPath *)indexPath scrollPosition:(UICollectionViewScrollPosition)position animated:(BOOL)animated completion:(void (^)(UICollectionViewCell *))completion
{
    [self.delegate dataSource:self wantsToScrollToItemAtIndexPath:[self globalIndexPath:indexPath forIndexPathFromDataSource:dataSource] scrollPosition:position animated:animated completion:completion];
}

- (void)dataSource:(KMCollectionViewDataSource *)dataSource wantsToChangeReactOnOffsetChangesOnReload:(BOOL)reactOnOffsetChangesOnReload
{
    [self.delegate dataSource:self wantsToChangeReactOnOffsetChangesOnReload:reactOnOffsetChangesOnReload];
}

@end
