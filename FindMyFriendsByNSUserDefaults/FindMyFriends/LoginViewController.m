//
//  LoginViewController.m
//  FindMyFriends
//
//  Created by Jeff Chen on 2016/5/22.
//  Copyright © 2016年 Jeff Chen. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *loginTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicatorView;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginBtnPressed:(UIButton *)sender {
    
    NSString *login = _loginTextField.text;
    NSString *password = _passwordTextField.text;
    
    NSString * urlstring=[NSString stringWithFormat:@"http://class.softarts.cc/FindMyFriends/updateUserLocation.php?GroupName=ap102&UserName=Jeff&Lat=24.967791&Lon=121.191613"];
    NSURL * url =[NSURL URLWithString:urlstring];
    
    //準備上傳SERVER 上的 NSURLSession
    //將NSURLSessionConfiguration設定為defaultSessionConfiguration
    NSURLSessionConfiguration *config=[NSURLSessionConfiguration defaultSessionConfiguration];
    //NSURLSession使用config設定檔
    NSURLSession * session=[NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *task=[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response,NSError * _Nullable error) {
    
        if (error) {
            NSLog(@"Error:%@",error);
            return ;
        }else{
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"JSON: %@",content);
        }
    }];
    
    [task resume];
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
