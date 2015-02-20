#import "KMCollectionViewDataManagerDataSourceLinker.h"
#import "KMCollectionViewAggregateDataSource.h"
#import "KMCollectionViewAggregateDataManager.h"
#import "KMCollectionViewAggregateDataSource_private.h"

@implementation KMCollectionViewDataManagerDataSourceLinker

+ (void)linkAggregateDataSource:(KMCollectionViewAggregateDataSource *)aggregateDataSource toAggregateDataManager:(KMCollectionViewAggregateDataManager *)dataManager
{
    [aggregateDataSource.dataSources enumerateKeysAndObjectsUsingBlock:^(NSNumber *section, KMCollectionViewDataSource *dataSource, BOOL *stop) {
        [dataManager associateDataSource:dataSource withManagerInGlobalSection:[section integerValue]];
    }];
}


@end
