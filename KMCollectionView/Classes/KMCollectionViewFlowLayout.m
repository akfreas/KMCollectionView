#import "KMCollectionViewFlowLayout.h"
#import "KMCollectionViewCellMapping.h"
#import "KMCollectionViewDataSource.h"
#import "KMCollectionViewStretchyHeaderCell.h"

@implementation KMCollectionViewFlowLayout

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat proposedContentOffsetCenterX = proposedContentOffset.x + self.collectionView.bounds.size.width * 0.5f;
    
    CGRect proposedRect = self.collectionView.bounds;
    
    // Comment out if you want the collectionview simply stop at the center of an item while scrolling freely
    // proposedRect = CGRectMake(proposedContentOffset.x, 0.0, collectionViewSize.width, collectionViewSize.height);
    
    UICollectionViewLayoutAttributes* candidateAttributes;
    for (UICollectionViewLayoutAttributes* attributes in [self layoutAttributesForElementsInRect:proposedRect])
    {
        
        // == Skip comparison with non-cell items (headers and footers) == //
        if (attributes.representedElementCategory != UICollectionElementCategoryCell)
        {
            continue;
        }
        
        // == First time in the loop == //
        if(!candidateAttributes)
        {
            candidateAttributes = attributes;
            continue;
        }
        
        if (fabs(attributes.center.x - proposedContentOffsetCenterX) < fabs(candidateAttributes.center.x - proposedContentOffsetCenterX))
        {
            candidateAttributes = attributes;
        }
    }
    
    return CGPointMake(candidateAttributes.frame.origin.x, proposedContentOffset.y);
    
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    // This will schedule calls to layoutAttributesForElementsInRect: as the
    // collectionView is scrolling.
    return YES;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    
    UICollectionView *collectionView = [self collectionView];
    UIEdgeInsets insets = [collectionView contentInset];
    CGPoint offset = [collectionView contentOffset];
    CGFloat minY = -insets.top;
    
    // First get the superclass attributes.
    NSArray *attributes = [super layoutAttributesForElementsInRect:rect];
    
    // Check if we've pulled below past the lowest position
    if (offset.y < minY) {
        
        // Figure out how much we've pulled down
        CGFloat deltaY = fabsf(offset.y - minY);
        BOOL wasStretchyHeaderCell = NO;
        if ([collectionView.dataSource isKindOfClass:[KMCollectionViewDataSource class]]) {
            KMCollectionViewDataSource *dataSource = (KMCollectionViewDataSource *)collectionView.dataSource;
            KMCollectionViewCellMapping *headerMapping  = [dataSource collectionView:collectionView cellInformationForIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            if ([headerMapping.cellClass isSubclassOfClass:[KMCollectionViewStretchyHeaderCell class]]) {
                // Adjust the header's height and y based on how much the user
                // has pulled down.
                wasStretchyHeaderCell = YES;
               for (UICollectionViewLayoutAttributes *attrs in attributes) {
                   if (attrs.indexPath.section == 0 && attrs.indexPath.item == 0) {
                       CGSize cellSize = headerMapping.size;
                       CGRect cellRect = [attrs frame];
                       cellRect.size.height = MAX(minY, cellSize.height + deltaY);
                       cellRect.origin.y = cellRect.origin.y - deltaY;
                       [attrs setFrame:cellRect];
                       break;
                   }
               }
            }
        }
        
        if (wasStretchyHeaderCell == NO) {
            for (UICollectionViewLayoutAttributes *attrs in attributes) {
                
                // Locate the header attributes
                
                NSString *kind = [attrs representedElementKind];
                if (kind == UICollectionElementKindSectionHeader) {
                    
                    // Adjust the header's height and y based on how much the user
                    // has pulled down.
                    CGSize headerSize = [self headerReferenceSize];
                    CGRect headerRect = [attrs frame];
                    headerRect.size.height = MAX(minY, headerSize.height + deltaY);
                    headerRect.origin.y = headerRect.origin.y - deltaY;
                    [attrs setFrame:headerRect];
                    break;
                }
            }
        }
    }
    return attributes;
}

@end
