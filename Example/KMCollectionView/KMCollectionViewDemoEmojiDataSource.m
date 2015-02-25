#import "KMCollectionViewDemoEmojiDataSource.h"
#import "EmojiEmoticons.h"
#import "KMCollectionViewDemoEmojiCell.h"

@interface KMCollectionViewDemoEmojiDataSource ()
@property (nonatomic) NSArray *emoji;
@end

@implementation KMCollectionViewDemoEmojiDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.emoji = [Emoji allEmoji];
    }
    return self;
}

#pragma mark KMCollectionView Override

- (KMCollectionViewCellMapping *)collectionView:(UICollectionView *)collectionView cellInformationForIndexPath:(NSIndexPath *)indexPath
{
    static KMCollectionViewCellMapping *mapping;
    if (mapping == nil) {
        mapping = [KMCollectionViewCellMapping cellMappingWithIdentifier:@"EmojiCell" cellClass:[KMCollectionViewDemoEmojiCell class] size:CGSizeMake(0.10, 0.10) options:KMCollectionViewCellMappingWidthAsPercentage | KMCollectionViewCellMappingSquare];
    }
    return mapping;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];
    [collectionView registerClass:[KMCollectionViewDemoEmojiCell class] forCellWithReuseIdentifier:@"EmojiCell"];
}

#pragma mark UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.emoji count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewCellMapping *mapping = [self collectionView:collectionView cellInformationForIndexPath:indexPath];
    KMCollectionViewDemoEmojiCell *cell = (KMCollectionViewDemoEmojiCell *)[collectionView dequeueReusableCellWithReuseIdentifier:mapping.identifier forIndexPath:indexPath];
    cell.character = self.emoji[indexPath.row];
    return cell;
}

@end
