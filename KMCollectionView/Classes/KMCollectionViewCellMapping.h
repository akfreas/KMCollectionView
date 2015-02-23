typedef enum : NSUInteger {
    KMCollectionViewCellMappingHeightUndefined = (1 << 0),
    KMCollectionViewCellMappingWidthUndefined = (1 << 1),
    KMCollectionViewCellMappingAutoLayoutSize = (1 << 2),
    KMCollectionViewCellMappingWidthAsPercentage = (1 << 3),
    KMCollectionViewCellMappingSquare = (1 << 4),
} KMCollectionViewCellMappingOptions;

@interface KMCollectionViewCellMapping : NSObject

@property (nonatomic) NSString *identifier;
@property (nonatomic) Class cellClass;
@property (nonatomic) CGSize size;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) CGFloat minimumInterItemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) KMCollectionViewCellMappingOptions options;


+ (instancetype)cellMappingWithIdentifier:(NSString *)identifier cellClass:(Class)cellClass size:(CGSize)size options:(KMCollectionViewCellMappingOptions)options;
- (NSString *)cellClassString;

@end
