@interface KMCollectionViewController : UICollectionViewController

@property (nonatomic) NSString *identifier;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;


@end
