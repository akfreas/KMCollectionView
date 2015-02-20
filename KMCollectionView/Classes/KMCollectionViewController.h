@interface KMCollectionViewController : UICollectionViewController

@property (nonatomic) NSString *cancelationIdentifier;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;

@end
