//
//  ViewController.m
//  AnimationBanner
//
//  Created by ma qi on 2020/9/2.
//  Copyright © 2020 Twist. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <SDCycleScrollView.h>
#import <Aspects.h>


#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, SDCycleScrollViewDelegate> {
    CGFloat _currentOffSet;
    NSInteger _lastIndex;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SDCycleScrollView *headerView;
@property (nonatomic, strong) UIScrollView *imageScrollView;
@property (nonatomic, strong) NSArray *imageUrlArr;
@property (nonatomic, strong) NSArray *sizeArr;
@property (nonatomic, assign) CGSize itemSize;

@end

static NSString *const cellId = @"UITableViewCell";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(@0);
    }];
    
    //hook对应的方法
    __weak typeof(self) weakSelf = self;
    [self.headerView aspect_hookSelector:@selector(scrollViewWillBeginDragging:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
        [weakSelf sd_scrollViewWillBeginDragging:self.imageScrollView];
    } error:nil];
    [self.headerView aspect_hookSelector:@selector(scrollViewDidScroll:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> aspectInfo) {
        [weakSelf sd_scrollViewDidScroll:self.imageScrollView];
    } error:nil];
}

- (CGFloat)getImageHWithImgW:(NSString *)imgW imgH:(NSString *)imgH {
    CGFloat width = [imgW floatValue];
    CGFloat height = [imgH floatValue];
    return SCREEN_WIDTH / width * height;
}

#pragma mark -
#pragma mark - hook

- (void)sd_scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //记录当前位置
    _currentOffSet = scrollView.contentOffset.x;
    //改变contentSize，一定要改变height，因为有高度变化，如果一直为0或不变的话会闪
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * self.imageUrlArr.count, self.itemSize.height);
}

- (void)sd_scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.x;
    if (offset == _currentOffSet) {
        return;
    }
    //偏移差，用来判断是左滑还是右滑
    CGFloat offsetValue = offset - _currentOffSet;
    //上一个图片的高度
    NSDictionary *lastSizeDic = self.sizeArr[_lastIndex];
    CGFloat lastHeight = [self getImageHWithImgW:lastSizeDic[@"width"] imgH:lastSizeDic[@"height"]];
    //将要滑动到的图片的高度
    NSInteger nextIndex = (offsetValue > 0) ? MIN(_lastIndex + 1, self.imageUrlArr.count - 1) : MAX(_lastIndex - 1, 0);
    NSDictionary *nextSizeDic = self.sizeArr[nextIndex];
    CGFloat nextHeight = [self getImageHWithImgW:nextSizeDic[@"width"] imgH:nextSizeDic[@"height"]];
    //偏移量：偏移差取绝对值，用来计算实时高度
    CGFloat offsetX = fabs(offsetValue);
    //2图片的高度差
    CGFloat value = lastHeight - nextHeight;
    //单位位移下的缩放的距离
    CGFloat scale = value / SCREEN_WIDTH;
    self.itemSize = CGSizeMake(SCREEN_WIDTH, lastHeight - scale * offsetX);
    NSLog(@">>>height %lf offsetValue:%lf", self.itemSize.height, offsetValue);
    
    //改变contentSize，一定要改变height，因为有高度变化，如果一直为0或不变的话会闪
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * self.imageUrlArr.count, self.itemSize.height);
    //可能丝滑了一点点
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.itemSize.height);
        self.tableView.tableHeaderView = self.headerView;
    } completion:nil];
}

#pragma mark -
#pragma mark - delegate ---> SDCycleScrollViewDelegate

/** 图片滚动回调 */
- (void)cycleScrollView:(SDCycleScrollView *)cycleScrollView didScrollToIndex:(NSInteger)index {
    NSLog(@">>>index:%zd", index);
    _lastIndex = index;
    _currentOffSet = self.imageScrollView.contentOffset.x;
}

#pragma mark -
#pragma mark - delegate ---> tableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@">>>%zd 行", indexPath.row];
    return cell;
}

#pragma mark -
#pragma mark - getter ---> data

- (NSArray *)imageUrlArr {
    if (!_imageUrlArr) {
        _imageUrlArr = @[@"http://ci.xiaohongshu.com/61b8c679-729a-41e2-90ec-ae8ae7b2b057@r_1280w_1280h.jpg",
                         @"http://ci.xiaohongshu.com/53e6dba6-a3fe-458f-9b98-e19ecb0105b7@r_1280w_1280h.jpg",
                         @"http://ci.xiaohongshu.com/dce83cb1-bf3b-4c6a-a89a-28a19c35025d@r_1280w_1280h.jpg"
        ];
    }
    return _imageUrlArr;
}

- (NSArray *)sizeArr {
    if (!_sizeArr) {
        _sizeArr = @[@{@"height":@"1178",
                       @"width":@"884"},
                     @{@"height":@"1045",
                       @"width":@"886",},
                     @{@"height":@"886",
                       @"width":@"995",}
        ];
    }
    return _sizeArr;
}

- (CGSize)itemSize {
    if (_itemSize.width == 0) {
        NSDictionary *sizeDic = [self.sizeArr firstObject];
        CGFloat height = [self getImageHWithImgW:sizeDic[@"width"] imgH:sizeDic[@"height"]];
        _itemSize = CGSizeMake(SCREEN_WIDTH, height);
    }
    return _itemSize;
}

#pragma mark -
#pragma mark - getter ---> view

- (SDCycleScrollView *)headerView {
    if (!_headerView) {
        NSDictionary *sizeDic = [self.sizeArr firstObject];
        CGFloat height = [self getImageHWithImgW:sizeDic[@"width"] imgH:sizeDic[@"height"]];
        _headerView = [SDCycleScrollView cycleScrollViewWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, height) imageURLStringsGroup:self.imageUrlArr];
        _headerView.backgroundColor = UIColor.whiteColor;
        //这里没有作者暴露出来，只能KVC了
        self.imageScrollView = [_headerView valueForKey:@"mainView"];
        self.imageScrollView.bounces = NO;
        _headerView.delegate = self;
        _headerView.autoScroll = NO;
        _headerView.infiniteLoop = NO;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellId];
        _tableView.tableHeaderView = self.headerView;
    }
    return _tableView;
}


@end
