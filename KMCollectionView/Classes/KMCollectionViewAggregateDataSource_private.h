#import "KMCollectionViewAggregateDataSource.h"

@interface KMCollectionViewAggregateDataSource (Private)
@property (nonatomic, readonly) NSMutableDictionary *dataSources;
- (id<UICollectionViewDataSource>)datasourceForIndexPath:(NSIndexPath *)indexPath;
@end
