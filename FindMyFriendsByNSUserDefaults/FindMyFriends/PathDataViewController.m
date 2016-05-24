//
//  PathDataViewController.m
//  FindMyFriends
//
//  Created by Jeff Chen on 2016/5/24.
//  Copyright © 2016年 Jeff Chen. All rights reserved.
//

#import "PathDataViewController.h"

@interface PathDataViewController ()
@property (weak, nonatomic) IBOutlet UILabel *dataCountLabelView;
@property (weak, nonatomic) IBOutlet UITextView *pathDataTextView;
@property (nonatomic) NSMutableArray *myPathLat;
@property (nonatomic) NSMutableArray *myPathLon;
@property (nonatomic) NSMutableString *show;
@property (nonatomic) NSMutableString *result;
@end

@implementation PathDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray * myPathLatUserDefault = [userDefaults objectForKey:@"myPathLat"];
    self.myPathLat = [NSMutableArray arrayWithArray:myPathLatUserDefault];
    NSMutableArray * myPathLonUserDefault = [userDefaults objectForKey:@"myPathLon"];
    self.myPathLon = [NSMutableArray arrayWithArray:myPathLonUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.result = [NSMutableString string];
    NSInteger latIndex = self.myPathLat.count;
    NSLog(@"%li筆紀錄", latIndex);
    for(int i=0; i<latIndex; i++){
        
        NSMutableString *string = [NSMutableString string];
        [string appendString:self.myPathLat[i]];
        [string appendString:@","];
        [string appendString: self.myPathLon[i]];
        [string appendString: @"\n"];
        [self.result appendString:string];
        
        //NSLog(@"第%i筆座標： lat:%@, lon:%@", i, self.myPathLat[i], self.myPathLon[i]);
        
    }
    self.pathDataTextView.text = self.result;
    NSLog(@"%@", self.result);
    
    self.dataCountLabelView.text = [NSString stringWithFormat:@"%li", latIndex];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
