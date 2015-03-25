#import "KMCollectionViewDataSource.h"

@interface KMCollectionViewAggregateDataSource : KMCollectionViewDataSource

- (NSInteger)globalSectionForDatasourceClass:(Class)dataSourceClass;
- (void)addDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)insertDatasource:(KMCollectionViewDataSource *)dataSource forGlobalSection:(NSInteger)section;
- (void)removeDatasourceForGlobalSection:(NSInteger)section;
- (void)removeDatasource:(KMCollectionViewDataSource *)dataSource;
@end
