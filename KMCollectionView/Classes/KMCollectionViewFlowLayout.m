#import "KMCollectionViewFlowLayout.h"
#import "KMCollectionViewCellMapping.h"
#import "KMCollectionViewDataSource.h"

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

@end
