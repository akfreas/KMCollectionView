#import "KMCollectionViewLayout.h"
#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewCellMapping.h"

@interface KMCollectionViewLayout ()

@property (nonatomic) NSMutableDictionary *computedSectionContentSizes;

@end

@implementation KMCollectionViewLayout

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.computedSectionContentSizes = [NSMutableDictionary dictionary];
    }
    return self;
}


- (CGSize)collectionViewContentSize
{
    CGSize s = self.collectionView.bounds.size;
    s.width  *= 2;
    s.height *= 2;
    return s;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *arr = [NSMutableArray array];
    NSInteger numberOfSections = [self.collectionView numberOfSections];
    for (int section=0; section<numberOfSections; section++) {
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
        CGFloat currentY = 0.0f;
        CGFloat currentX = 0.0f;
        CGFloat widthSum = 0.0f;
        for (int item=0; item<numberOfItems; item++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            KMCollectionViewCellMapping *mapping = [(KMCollectionViewDataSource *)self.collectionView.dataSource collectionView:self.collectionView cellInformationForIndexPath:indexPath];
            UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            CGSize cellSize = [self sizeFromMapping:mapping forCollectionView:self.collectionView];
            widthSum += cellSize.width;
            currentX += mapping.minimumInterItemSpacing;
            
            if (currentX + cellSize.width > self.collectionView.frame.size.width) {
                currentX = 0.0f;
            }
            
            attrs.frame = CGRectMake(currentX, currentY, cellSize.width, cellSize.height);
            int row = floorf(widthSum / self.collectionView.frame.size.width);
            currentY = row * cellSize.height;
            if (row > 0) {
                currentY += mapping.minimumInterItemSpacing;
            }

            currentX += cellSize.width;
            [arr addObject:attrs];
        }
        
        UICollectionViewLayoutAttributes *firstAttrs = [arr firstObject];
        UICollectionViewLayoutAttributes *lastAttrs = [arr lastObject];
        CGRect fullRect = CGRectUnion(firstAttrs.frame, lastAttrs.frame);
        CGSize sectionContentSize = fullRect.size;
        self.computedSectionContentSizes[@(section)] = [NSValue valueWithCGSize:sectionContentSize];
    }
    return arr;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewCellMapping *mapping;
    if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        mapping = [(KMCollectionViewDataSource *)self.collectionView.dataSource collectionView:self.collectionView cellInformationForFooterInSection:indexPath.section];
    } else if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        mapping = [(KMCollectionViewDataSource *)self.collectionView.dataSource collectionView:self.collectionView cellInformationForHeaderInSection:indexPath.section];
    }
    
    UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    CGSize sectionSize = [self.computedSectionContentSizes[@(indexPath.section)] CGSizeValue];
    attrs.frame = CGRectMake(0, sectionSize.height, mapping.size.width, mapping.size.height);
    return attrs;
}


- (CGSize)sizeFromMapping:(KMCollectionViewCellMapping *)mapping forCollectionView:(UICollectionView *)collectionView
{
    CGSize cellSize = mapping.size;
    CGRect collectionViewFrame = collectionView.frame;
    if (mapping.options & KMCollectionViewCellMappingWidthUndefined) {
        cellSize.width = collectionViewFrame.size.width;
    } else if (mapping.options & KMCollectionViewCellMappingWidthAsPercentage) {
        cellSize.width = collectionViewFrame.size.width * cellSize.width;
    }
    
    if (mapping.options & KMCollectionViewCellMappingHeightUndefined) {
        cellSize.height = 44.0f;
    } else if (mapping.options & KMCollectionViewCellMappingHeightAsPercentage) {
        cellSize.height =  collectionViewFrame.size.height * cellSize.height;
    } else if (mapping.options & KMCollectionViewCellMappingSquare) {
        cellSize.height = cellSize.width;
    }
    return cellSize;
}

@end
