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
        mapping = [KMCollectionViewCellMapping cellMappingWithIdentifier:@"EmojiCell" cellClass:[KMCollectionViewDemoEmojiCell class] size:CGSizeMake(0.5, 1.0) options:KMCollectionViewCellMappingAutoLayoutSize];
    }
    return mapping;
}

- (void)registerReusableViewsWithCollectionView:(UICollectionView *)collectionView
{
    [super registerReusableViewsWithCollectionView:collectionView];
    [collectionView registerClass:[KMCollectionViewDemoEmojiCell class] forCellWithReuseIdentifier:@"EmojiCell"];
}

#pragma mark UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.emoji count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    KMCollectionViewCellMapping *mapping = [self collectionView:collectionView cellInformationForIndexPath:indexPath];
    KMCollectionViewDemoEmojiCell *cell = (KMCollectionViewDemoEmojiCell *)[collectionView dequeueReusableCellWithReuseIdentifier:mapping.identifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    cell.character = self.emoji[indexPath.row];
    return cell;
}

- (NSObject *)collectionView:(UICollectionView *)collectionView cellDataForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.emoji count]) {
        return self.emoji[indexPath.row];
    }
    return nil;
}

@end
