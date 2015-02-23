#import "KMCollectionViewDemoEmojiDataSource.h"
#import "EmojiEmoticons.h"
#import "KMCollectionViewDemoEmojiCell.h"

@implementation KMCollectionViewDemoEmojiDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath
{
    return [KMCollectionViewCellMapping cellMappingWithIdentifier:@"EmojiCell" cellClass:[KMCollectionViewDemoEmojiCell class] size:CGSizeMake(0.10, 0.10) options:KMCollectionViewCellMappingWidthAsPercentage];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
