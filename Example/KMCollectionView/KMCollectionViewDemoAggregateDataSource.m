#import "KMCollectionViewDemoAggregateDataSource.h"
#import "KMCollectionViewDemoEmojiDataSource.h"

@implementation KMCollectionViewDemoAggregateDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addDatasource:[KMCollectionViewDemoEmojiDataSource new] forGlobalSection:0];
    }
    return self;
}

@end
