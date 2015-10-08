#import "KMCollectionViewController.h"
#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewDataSource_private.h"
#import "KMCollectionViewFlowLayout.h"
#import "KMCollectionView.h"

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+ (id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

- (void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@implementation KMCollectionViewController

- (instancetype)init
{
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    UICollectionViewFlowLayout *flowLayout = [[KMCollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:flowLayout];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    UICollectionViewFlowLayout *flowLayout = [[KMCollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:flowLayout];
    return self;
}

- (void)loadView
{
    [super loadView];
    self.collectionView = [[KMCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewLayout];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    KMCollectionViewDataSource *dataSource = (KMCollectionViewDataSource *)self.collectionView.dataSource;
    if ([dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
        [dataSource registerReusableViewsWithCollectionView:self.collectionView];
        [dataSource setNeedsLoadContent];
    }
}

#pragma mark - Accessors

- (NSString *)identifier
{
    if (_identifier == nil) {
        _identifier = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    }
    return _identifier;
}

#pragma mark Private Methods

- (void)adjustContentOffsetToApproprate
{
    if (self.collectionView.contentSize.height <= self.collectionView.frame.size.height) {
        [UIView animateWithDuration:0.25f animations:^{
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        }];
    }
}

@end
