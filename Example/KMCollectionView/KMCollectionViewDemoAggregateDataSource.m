#import "KMCollectionViewDemoAggregateDataSource.h"
#import "KMCollectionViewDemoEmojiDataSource.h"
#import "KMCollectionViewSwipeDataSource.h"


@implementation KMCollectionViewDemoAggregateDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addDatasource:[KMCollectionViewSwipeDataSource new] forGlobalSection:0];
        [self addDatasource:[KMCollectionViewDemoEmojiDataSource new] forGlobalSection:1];
    }
    return self;
}

@end
