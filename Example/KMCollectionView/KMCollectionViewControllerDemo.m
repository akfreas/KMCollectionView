#import "KMCollectionViewControllerDemo.h"
#import "KMCollectionViewDemoAggregateDataSource.h"


@interface KMCollectionViewControllerDemo ()
@property (nonatomic) KMCollectionViewDemoAggregateDataSource *aggregateDataSource;
@end

@implementation KMCollectionViewControllerDemo


- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.aggregateDataSource = [KMCollectionViewDemoAggregateDataSource new];
    self.collectionView.dataSource = self.aggregateDataSource;
}

@end
