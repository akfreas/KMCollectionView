#import "KMCollectionViewCellMapping.h"


@implementation KMCollectionViewCellMapping

+ (instancetype)cellMappingWithIdentifier:(NSString *)identifier cellClass:(Class)cellClass size:(CGSize)size options:(KMCollectionViewCellMappingOptions)options
{
    KMCollectionViewCellMapping *mapping = [KMCollectionViewCellMapping new];
    mapping.identifier = identifier;
    mapping.cellViewClass = cellClass;
    mapping.size = size;
    mapping.options = options;
    mapping.minimumInterItemSpacing = 5.0f;
    mapping.rowSpan = 1;
    return mapping;
}

- (NSString *)cellClassString {
    return NSStringFromClass(self.cellViewClass);
}

@end
