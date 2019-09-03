//
//  ScannerVC.swift
//  chonggou
//
//  Created by yipeng on 2019/8/29.
//  Copyright © 2019 yipeng. All rights reserved.
//


import UIKit
import AVFoundation
public class ScannerVC: UIViewController {
    var back_but:UIButton?
    var photoBut:UIButton?
    var lightBut:UIButton?
    public var callback: ((UIImage)->Void)?
    var K_Screen_width=Int(UIScreen.main.bounds.width); //屏幕宽度
    var K_Screen_height=Int(UIScreen.main.bounds.height);//屏幕高度
//
    //捕获设备，通常是前置摄像头，后置摄像头，麦克风（音频输入）
    var device:AVCaptureDevice?
    
    //AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
    var input:AVCaptureDeviceInput?
    
    
    //当启动摄像头开始捕获输入
    var output:AVCaptureMetadataOutput?
    
    var  ImageOutPut:AVCaptureStillImageOutput?
    
    //session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
    var  session:AVCaptureSession?
    
    //图像预览层，实时显示捕获的图像
    var previewLayer:AVCaptureVideoPreviewLayer?

    
    var canCa = false
    
    var imageView:UIImageView?
    var image:UIImage?

    var maskLayer:CAShapeLayer?//半透明黑色遮罩
    var effectiveRectLayer: CAShapeLayer?//有效区域框
    
     var photoWidth = Int(UIScreen.main.bounds.width)-40
     var photoHeigth = Int(Double(Int(UIScreen.main.bounds.width)-40) / 1.6)
    
    
    var focusView: UIView? //聚焦
    
    var isLightOn = false


    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
         drawCoverView()
        createView()
        canCa = canUserCamear()
        if(canCa){
            customUI()
            customCamera()
        }
    }


    //绘制遮罩层
     func drawCoverView() {
        let view = UIView(frame: self.view.bounds)
        view.backgroundColor = .black
        view.alpha = 0.5
        self.view.addSubview(view)
        let bpath = UIBezierPath(roundedRect: self.view.bounds,cornerRadius: 0)
        let bpath2 = UIBezierPath(roundedRect: CGRect(x: horizontally(viewWidth: photoWidth), y: verticalCentralization(viewHeight: photoHeigth), width: photoWidth, height: photoHeigth), cornerRadius: 0)
        bpath.append(bpath2.reversing())
        let shapeLayer = CAShapeLayer.init()
        shapeLayer.path = bpath.cgPath
        view.layer.mask = shapeLayer
        
    }
    //设置聚焦
    func customUI(){
    
        focusView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        focusView?.layer.borderWidth = 1.0
        focusView?.layer.borderColor = UIColor.green.cgColor
        focusView?.backgroundColor = .clear
        focusView?.isHidden = true
        self.view.addSubview(focusView!)
//        设置手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusGesture(gesture:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    @objc func focusGesture(gesture:UITapGestureRecognizer){
        let point = gesture.location(in: gesture.view)
        focusAtPoint(point: point)
    }
    func focusAtPoint(point:CGPoint){
        let size  = self.view.bounds.size
        let focusPorint = CGPoint(x: point.y / size.height, y: 1-point.x/size.width)
        do{
            try device?.lockForConfiguration()
            //焦点
            if((self.device?.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus))!){
                self.device?.focusPointOfInterest = focusPorint
                self.device?.focusMode = AVCaptureDevice.FocusMode.autoFocus
            }
            //曝光
            if((self.device?.isExposureModeSupported(AVCaptureDevice.ExposureMode.autoExpose))!){
                self.device?.exposurePointOfInterest = focusPorint
                self.device?.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            self.device?.unlockForConfiguration()
            focusView?.center = point
            focusView?.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.focusView?.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
            }) { (finished) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.focusView?.transform = CGAffineTransform.identity
                }, completion: { (finished) in
                    self.focusView?.isHidden = true
                })
            }
            
        }catch{
            return
        }
        
    }
    //相机初始化
    func customCamera()  {
        maskLayer = CAShapeLayer.init()
        self.view.backgroundColor = .white
        //  使用AVMediaTypeVideo 指明self.device代表视频，默认使用后置摄像头进行初始化
        self.device = AVCaptureDevice.default(for: AVMediaType.video)
        //使用设备初始化输入
        do {
             self.input = try AVCaptureDeviceInput(device: self.device!)
        }catch {
            print(error)
            return
        }
//            self.input = AVCaptureDeviceInput.init(device: self.device!)
        //生成输出对象
        self.output = AVCaptureMetadataOutput.init()
        self.ImageOutPut = AVCaptureStillImageOutput.init()
        //生成会话，用来结合输入输出
        self.session = AVCaptureSession.init()
        if((self.session?.canSetSessionPreset(AVCaptureSession.Preset.hd1920x1080))!){
            self.session?.sessionPreset = AVCaptureSession.Preset.hd1920x1080;

        }
        if(self.session!.canAddInput(self.input!)){
            self.session!.addInput(self.input!)
        }
        
        if(self.session!.canAddOutput(self.ImageOutPut!)){
            self.session!.addOutput(self.ImageOutPut!)
        }
        
        
            //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
        self.previewLayer = AVCaptureVideoPreviewLayer.init(session: session!)
        self.previewLayer?.frame = CGRect(x: 0, y: 0, width: K_Screen_width, height: K_Screen_height)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.view.layer.insertSublayer(self.previewLayer!, at: 0)
        
            //开始启动
        self.session?.startRunning()
        do{
            if(try self.device?.lockForConfiguration() ==  nil && self.device!.isFlashModeSupported(AVCaptureDevice.FlashMode.auto)){
                self.device?.flashMode = AVCaptureDevice.FlashMode.auto
                
            }
        }catch{
            print(error)
        }
        
            //自动白平衡
        if(self.device!.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance)){
            self.device?.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance
        }else{
            self.device?.unlockForConfiguration()
        }

    }
    


    func createView()  {
        let bottomSpace = UIApplication.shared.statusBarFrame.size.width == 20 ? 0 : 49; //底部安全距离
        let bottomY = K_Screen_height - bottomSpace //底部安全距离
        let topHight = Int(UIApplication.shared.statusBarFrame.size.height) + Int((self.navigationController?.navigationBar.frame.size.height)!);
        back_but = UIButton(type: .custom);
        let back=UIImage(named: "white_black");
        back_but?.frame =  CGRect(x: 20, y: CGFloat(topHight/2), width: (back?.size.width)!, height: (back?.size.height)!)
        back_but?.addTarget(self, action: #selector(backPage), for: .touchUpInside)
        back_but?.setBackgroundImage(back, for: .normal)
        
        photoBut = UIButton.init()
        photoBut?.addTarget(self, action: #selector(shutterCamera), for: .touchUpInside)
        photoBut?.setBackgroundImage(UIImage(named: "startBtn"), for: .normal)
        photoBut?.frame = CGRect(x: horizontally(viewWidth: 70), y:bottomY - 70, width: 70, height:70)
//        photoBut?.layer.cornerRadius = 35
        self.view.addSubview(photoBut!)
        self.view.addSubview(back_but!)
        
        
        
        let labele = UILabel();
        let width1 = ga_widthForComment(str: "请将身份证正面置入框中,注意光线", fontSize: 16)
        let height1 = ga_heightForComment(str: "请将身份证正面置入框中,注意光线", fontSize: 16, width: width1)
        labele.frame = CGRect(x: horizontally(viewWidth: Int(width1)), y: Int(K_Screen_height/2) - (photoHeigth/2) - Int(height1+10), width: Int(width1), height:  Int(height1))
        labele.text = "请将身份证正面置入框中,注意光线"
        labele.textColor = .white
        labele.font=UIFont.systemFont(ofSize: 16)
        self.view.addSubview(labele)
        
        let width2 = ga_widthForComment(str: "闪光灯", fontSize: 16)
        let height2 = ga_heightForComment(str: "闪光灯", fontSize: 16, width: width1)
        
        lightBut = UIButton(frame: CGRect(x: CGFloat(K_Screen_width -  Int(20 + width2)), y:  CGFloat(topHight/2), width: width2, height: height2))
        lightBut?.setTitle("闪光灯", for: .normal)
//        lightBut?.titleLabel?.textColor = .groupTableViewBackground
        lightBut?.setTitleColor(.groupTableViewBackground, for: .normal)
        lightBut?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        lightBut?.addTarget(self, action: #selector(light), for: .touchUpInside)
        

        self.view.addSubview(lightBut!)
        
        //边框线条。start
        let view2 = UIView(frame:CGRect(x: 18, y: Int(K_Screen_height/2) - (photoHeigth/2) - 4, width: 32, height: 2))
        view2.backgroundColor = .white
        self.view.addSubview(view2)
        
        let view3 = UIView(frame:CGRect(x: K_Screen_width - 50, y: Int(K_Screen_height/2) - (photoHeigth/2) - 4, width: 32, height: 2))
        view3.backgroundColor = .white
        self.view.addSubview(view3)
        
        
        
        let view4 = UIView(frame:CGRect(x: 18, y: Int(K_Screen_height/2) + (photoHeigth/2) + 2, width: 32, height: 2))
        view4.backgroundColor = .white
        self.view.addSubview(view4)
        
        let view5 = UIView(frame:CGRect(x: K_Screen_width - 50, y: Int(K_Screen_height/2) + (photoHeigth/2) + 2, width: 32, height: 2))
        view5.backgroundColor = .white
        self.view.addSubview(view5)
        
        
        let view6 = UIView(frame:CGRect(x: 16, y: Int(K_Screen_height/2) - (photoHeigth/2)-4, width: 2, height: 32))
        view6.backgroundColor = .white
        self.view.addSubview(view6)
        
        
        let view7 = UIView(frame:CGRect(x: K_Screen_width - 18, y: Int(K_Screen_height/2) - (photoHeigth/2)-4, width: 2, height: 32))
        view7.backgroundColor = .white
        self.view.addSubview(view7)
        
        
        let view8 = UIView(frame:CGRect(x: 16, y: Int(K_Screen_height/2) + (photoHeigth/2)-28, width: 2, height: 32))
        view8.backgroundColor = .white
        self.view.addSubview(view8)
        
        let view9 = UIView(frame:CGRect(x:  K_Screen_width - 18, y: Int(K_Screen_height/2) + (photoHeigth/2)-28, width: 2, height: 32))
        view9.backgroundColor = .white
        self.view.addSubview(view9)
        //--end---
    }
    
    @objc func backPage(){
        self.navigationController?.popViewController(animated: true);
    }
    
    //相机权限
    func canUserCamear() -> Bool {
                let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if(authStatus == AVAuthorizationStatus.denied){
//            let alertView = UIAlertView.init(title: "请打开相机权限", message: "设置-隐私-相机", delegate: self, cancelButtonTitle: "确定",otherButtonTitles: "取消");
//            alertView.show()
            let alertController = UIAlertController(title: " 请打开相机权限", message: "设置-隐私-相机", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "取消", style: .cancel) { (UIAlertAction) in
                self.backPage()
            }
            let okAction = UIAlertAction(title: "确定", style: .default) { (UIAlertAction) in
                let url = URL(string: UIApplication.openSettingsURLString)
                if (UIApplication.shared.canOpenURL(url!)){
                    UIApplication.shared.openURL(url!)
                }
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
            
            return false
        }else{
            return true
        }
        return true
    }
  
    @objc func light(){
        do{
            try device?.lockForConfiguration()
            if(!isLightOn){
                device?.torchMode = AVCaptureDevice.TorchMode.on
                isLightOn = true
//                self.lightBut?.titleLabel?.textColor = .green
                lightBut?.setTitleColor(.green, for: .normal)

            }else{
                device?.torchMode = AVCaptureDevice.TorchMode.off
                isLightOn = false
//                self.lightBut?.titleLabel?.textColor = .groupTableViewBackground
                lightBut?.setTitleColor(.groupTableViewBackground, for: .normal)

            }
            device?.unlockForConfiguration()
        }catch{
            return
        }
       
    }
    
    @objc func shutterCamera(){
        let videoConnection = self.ImageOutPut?.connection(with: AVMediaType.video)
        videoConnection?.videoOrientation = AVCaptureVideoOrientation.portrait
        if(!(videoConnection != nil)){
            return
        }
        self.ImageOutPut?.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { (imageDataSampleBuffer, error) in
            if(imageDataSampleBuffer == nil){
                return
            }

            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)
            
            
            self.image = UIImage.init(data: imageData!)
            self.session?.stopRunning()
            
      
            
            //计算比例
            let aspectWidth  = self.image!.size.width / CGFloat(self.K_Screen_width)
            let aspectHeight = self.image!.size.height / CGFloat(self.K_Screen_height)
//            图片绘制区域
                    var scaledImageRect = CGRect.zero
            scaledImageRect.size.width  = CGFloat(self.photoWidth) * CGFloat(aspectWidth)
            scaledImageRect.size.height = CGFloat(self.photoHeigth) * CGFloat(aspectHeight)
            scaledImageRect.origin.x    = CGFloat(horizontally(viewWidth: self.photoWidth)) * CGFloat(aspectWidth)
            scaledImageRect.origin.y    = CGFloat(verticalCentralization(viewHeight: self.photoHeigth)) * CGFloat(aspectHeight)
            
            let i = self.imageFromImage(image: self.fixOrientation(image: self.image!), rect: scaledImageRect)
            self.imageView  = UIImageView(frame:  CGRect(x: horizontally(viewWidth: self.photoWidth), y: verticalCentralization(viewHeight: self.photoHeigth), width: self.photoWidth, height: self.photoHeigth))
            self.imageView?.contentMode = UIView.ContentMode.scaleAspectFill
//            self.view.insertSubview(self.imageView!, belowSubview: but)
            self.imageView?.layer.masksToBounds = true
       
            self.imageView?.image = i
            self.callback?(i)
           self.backPage()
//            self.view.addSubview(self.imageView!)

            
        })
    }
    
    
    
    func scaled(to newSize: CGSize,size:CGSize) -> UIImage {
        //计算比例
        let aspectWidth  = newSize.width/size.width
        let aspectHeight = newSize.height/size.height
        let aspectRatio = max(aspectWidth, aspectHeight)
        
        //图片绘制区域
        var scaledImageRect = CGRect.zero
        scaledImageRect.size.width  = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x    = 0
        scaledImageRect.origin.y    = 0
        
        //绘制并获取最终图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)//图片不失真
//        drem(in: scaledImageRect)
    
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    /**
     *从图片中按指定的位置大小截取图片的一部分
     * UIImage image 原始的图片
     * CGRect rect 要截取的区域
     */
    func imageFromImage(image:UIImage,rect:CGRect) -> UIImage {
        //将UIImage转换成CGImageRef
        let sourceImageRef = image.cgImage
         //按照给定的矩形区域进行剪裁
        let newImageRef = sourceImageRef?.cropping(to: rect)
        let newImage =  UIImage.init(cgImage: newImageRef!)
        return newImage
    }

    
//    //按下的效果
//    -(void)touchDown{
//    self.saveBtn.backgroundColor = [UIColor colorFromHexValue:0x9B0000];
//    }
//
//    //按下拖出按钮松手还原
//    -(void)touchUpOutside{
//    self.saveBtn.backgroundColor = [UIColor colorFromHexValue:0xFF2741];
//    }

 
    
    
    func fixOrientation(image:UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        var transform = CGAffineTransform.identity
        
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)
            break
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
            
        default:
            break
        }
        
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
            
        default:
            break
        }
        
        let ctx = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: image.cgImage!.bitsPerComponent, bytesPerRow: 0, space: image.cgImage!.colorSpace!, bitmapInfo: image.cgImage!.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(image.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(image.size.height), height: CGFloat(image.size.width)))
            break
            
        default:
            ctx?.draw(image.cgImage!, in: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(image.size.width), height: CGFloat(image.size.height)))
            break
        }
        
        let cgimg: CGImage = (ctx?.makeImage())!
        let img = UIImage(cgImage: cgimg)
        
        return img
    }
}

///水平居中
func horizontally(viewWidth:Int) ->Int{
    return Int((Int(UIScreen.main.bounds.width)/2) - (viewWidth/2))
}
//垂直居中
func verticalCentralization(viewHeight:Int) ->Int{
    return Int((Int(UIScreen.main.bounds.height)/2) - (viewHeight/2))
}

//根据文字获取宽度
func ga_widthForComment(str: String,fontSize: CGFloat, height: CGFloat = 15) -> CGFloat {
    let font = UIFont.systemFont(ofSize: fontSize)
    let rect = NSString(string: str).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    return ceil(rect.width)
}
//根据文字获取高度
func ga_heightForComment(str: String,fontSize: CGFloat, width: CGFloat) -> CGFloat {
    let font = UIFont.systemFont(ofSize: fontSize)
    let rect = NSString(string: str).boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    return ceil(rect.height)
}
//根据文字获取高度
func ga_heightForComment(str: String,fontSize: CGFloat, width: CGFloat, maxHeight: CGFloat) -> CGFloat {
    let font = UIFont.systemFont(ofSize: fontSize)
    let rect = NSString(string: str).boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
    return ceil(rect.height)>maxHeight ? maxHeight : ceil(rect.height)
}
