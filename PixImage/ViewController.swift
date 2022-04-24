//
//  ViewController.swift
//  PixImage
//
//  Created by 许浩渊 on 2022/4/22.
//

import UIKit
import Photos
import SnapKit
import RxSwift
import RxCocoa
import AVFoundation
import ZLPhotoBrowser
import TextAttributes
import XHYCategories
import PKHUD


class ViewController: UIViewController {

    private let pixelizationUpdateThreshold = 0.1
    private let popupDelay = 1.5
    private let imageTransitionAnimationTime = 0.5
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let backgroundImage = UIImageView(image: UIImage(named: "IMG1"))
    private let previewImage = UIImageView()
    private let previewEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let previewLabel = UILabel(text: "点击从相册内添加图片", font: UIFont.systemFont(ofSize: 20, weight: .bold), color: UIColor.gray, alignment: .center)
    private var sourceImage: UIImage?
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var slider: Slider = {
        let slider = Slider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.setThumbImage(UIImage(named: "jinbipixel"), for: .normal)
        slider.tintColor = UIColor.black
        return slider
    }()
    private let loadBtn = UIButton()
    private let saveBtn = UIButton()
    private var lastPixelizationTimestamp: TimeInterval?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        loadBtn.addTarget(self, action: #selector(cameraButtonTouched), for: UIControl.Event.touchUpInside)
        saveBtn.addTarget(self, action: #selector(photosButtonTouched), for: UIControl.Event.touchUpInside)
        makeUI()

        slider.rx.controlEvent(.valueChanged).debounce(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.asyncInstance).bind(onNext: { [weak self] s in
            guard let self = self else { return }
            self.pixelizeImage(pixelSize: CGFloat(self.slider.value))
        }).disposed(by: disposeBag)
    }

    private func makeUI() {
        backgroundImage.contentMode = .scaleAspectFill
        previewImage.backgroundColor = UIColor.clear
        previewImage.contentMode = .scaleAspectFit
        view.addSubview(backgroundImage)
        view.addSubview(backgroundView)
        backgroundView.contentView.addSubview(loadBtn)
        backgroundView.contentView.addSubview(saveBtn)
        backgroundView.contentView.addSubview(slider)
        backgroundView.contentView.addSubview(previewImage)
        previewImage.addSubview(previewEffectView)
        previewEffectView.contentView.addSubview(previewLabel)
        previewEffectView.corner = 16
        previewImage.corner = 16

        backgroundImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(0.5)
            make.bottom.equalTo(view.snp.bottom).offset(-35)
        }

        saveBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.5)
            make.bottom.equalTo(view.snp.bottom).offset(-35)
        }

        slider.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(loadBtn.snp.top).offset(-16)
        }

        previewImage.snp.makeConstraints { make in
            make.top.equalTo(backgroundView.safeAreaLayoutGuide.snp.top).offset(8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.bottom.equalTo(slider.snp.top).offset(8)
        }
        previewEffectView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalTo(8)
            make.trailing.equalTo(-8)
            make.width.equalTo(previewEffectView.snp.height)
        }

        previewLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        loadBtn.setImage(UIImage(named: "29-images"), for: .normal)
//        loadBtn.setTitle("图片", for: .normal)
        saveBtn.setImage(UIImage(named: "33-image"), for: .normal)
//        saveBtn.setTitle("保存", for: .normal)
    }

    private var workItem: DispatchWorkItem?
    private func pixelizeImage(pixelSize: CGFloat) {
        guard sourceImage != nil else { return }
        HUD.show(HUDContentType.progress, onView: self.previewImage)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            guard let sourceImage = self.sourceImage else { return }
            let pixeletedImage = sourceImage.pixelize(pixelSize: pixelSize)
            DispatchQueue.main.async {
                HUD.hide()
                self.showImage(image: pixeletedImage, animated: true)
            }
        }
    }

    private func setImage(image: UIImage, animated: Bool) {
        let scale: CGFloat = previewImage.frame.width/image.size.width
        let screenScale = UIScreen.main.scale
        let adjustedImage = image.resize(scaleX: scale/screenScale, scaleY: scale/screenScale, interpolation: .default)
        previewEffectView.isHidden = true
        backgroundImage.image = image
        sourceImage = adjustedImage
        showImage(image: image, animated: animated)
        pixelizeImage(pixelSize: CGFloat(slider.value))
    }

    private func showImage(image: UIImage, animated: Bool) {
        if animated {
            UIView.transition(with: previewImage,
                              duration: imageTransitionAnimationTime,
                              options: .transitionCrossDissolve,
                              animations: { self.previewImage.image = image },
                              completion: nil)
        } else {
            previewImage.image = image
        }
    }

    @objc private func cameraButtonTouched() {
        let config = ZLPhotoConfiguration.default()
        config.allowEditImage = true
        config.allowMixSelect = false
        config.allowSelectVideo = false
        config.maxSelectCount = 1
        let themeColor = ZLPhotoThemeColorDeploy()
//        themeColor.

        config.themeColorDeploy = themeColor
        let ps = ZLPhotoPreviewSheet()
        ps.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        ps.selectImageBlock = { [weak self] (images, assets, isOriginal) in
            guard let image = images.first else { return }
            self?.setImage(image: image, animated: true)
        }
        ps.showPhotoLibrary(sender: self)
    }

    @objc private func photosButtonTouched() {
        guard let image = previewImage.image else { return }
        ZLEditImageViewController.showEditImageVC(parentVC: self, animate: true, image: image, editModel: nil) { [weak self] img, _ in
            guard let self = self else { return }
            UIImageWriteToSavedPhotosAlbum(img, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            HUD.flash(.labeledError(title: "保存失败", subtitle: "请重试"), delay: popupDelay)
        } else {
            HUD.flash(.label("保存成功"), delay: popupDelay)
        }
    }
}

class Slider: UISlider {


}
