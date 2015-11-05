#import "KMCollectionViewDemoSwipeController.h"
#import "KMCollectionViewSwipeDataSource.h"


@interface KMCollectionViewDemoSwipeController ()
@property (nonatomic) KMCollectionViewSwipeDataSource *swipeSource;
@end

@implementation KMCollectionViewDemoSwipeController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.dataSource = self.swipeSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
