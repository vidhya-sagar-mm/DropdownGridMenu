//
//  DropdownGridMenuController.swift
//  DropdownGridMenu
//
//  Created by Oleg Chornenko on 11/21/17.
//  Copyright © 2017 Oleg Chornenko. All rights reserved.
//

import UIKit

class DropdownGridMenuController: UIViewController {

    private static let cell = "DropdownGridMenuCell"
    
    enum DropdownGridMenuAppear: Int {
        case fromTop
        case fromLeft
        case fromRight
    }
    
    enum DropdownGridMenuDismiss: Int {
        case toBottom
        case toLeft
        case toRight
    }
    
    private var collectionView: UICollectionView!
    private var backgroundView: UIView!
    private var isPopover = false
    private var appear = DropdownGridMenuAppear.fromTop
    private var dismiss = DropdownGridMenuDismiss.toBottom
    private var items = [DropdownGridMenuItem]()
    private var itemSize = CGSize(width: 0, height: 0)
    private var action: ((DropdownGridMenuItem) -> Void)?
    private var completion: (() -> Void)?
    
    private lazy var transitionController = DropdownGridMenuTransitionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        
        self.backgroundView = UIView(frame: self.view.frame)
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundView.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
        self.backgroundView.alpha = 0
        self.view.insertSubview(self.backgroundView, at: 0)
        
        self.collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.clipsToBounds = true
        self.collectionView.register(DropdownGridMenuCell.self, forCellWithReuseIdentifier: DropdownGridMenuController.cell)
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.isHidden = true
        self.view.addSubview(self.collectionView)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.collectionView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.collectionView.addGestureRecognizer(swipeRight)
        
        activateConstraints(true)
    }
    
    func activateConstraints(_ active: Bool) {
        self.backgroundView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = active
        self.backgroundView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = active
        
        self.collectionView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = active
        self.collectionView.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = active
    }
    
    func transformItemAtIndex(_ index: Int, negative: Bool) -> CGAffineTransform {
        let maxTranslation = self.view.frame.width / 2
        let minTranslation = self.view.frame.width / 3
        var translation = maxTranslation - (maxTranslation - minTranslation) * (CGFloat(index) / CGFloat(self.items.count))
        if negative {
            translation = -translation

            switch self.dismiss {
            case .toRight:
                return CGAffineTransform(translationX: -translation, y: 0)
                
            case .toLeft:
                return CGAffineTransform(translationX: translation, y: 0)
                
            case .toBottom:
                return CGAffineTransform(translationX: 0, y: -translation)
            }
        } else {
            switch self.appear {
            case .fromRight:
                return CGAffineTransform(translationX: translation, y: 0)
                
            case .fromLeft:
                return CGAffineTransform(translationX: -translation, y: 0)
                
            case .fromTop:
                return CGAffineTransform(translationX: 0, y: -translation)
            }
        }
    }
    
    func enterTheStage(_ completion: (() -> Swift.Void)? = nil) {
        for index in 0..<self.items.count {
            let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0))
            cell?.transform = transformItemAtIndex(index, negative: false)
            cell?.alpha = 0
        }
        
        self.collectionView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundView.alpha = 1.0
        }
        
        for index in 0..<self.items.count {
            let delay = 0.02 * CGFloat(index)
            UIView.animate(withDuration: 0.8, delay: TimeInterval(delay), usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: UIViewAnimationOptions(rawValue: 0), animations: {
                let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0))
                cell?.transform = CGAffineTransform.identity
                cell?.alpha = 1.0
            }, completion: { _ in
                if index + 1 == self.items.count {
                    completion?()
                }
            })
        }
    }
    
    func leaveTheStage(_ completion: (() -> Swift.Void)? = nil) {
        for index in 0..<self.items.count {
            UIView.animate(withDuration: 0.3, delay: 0.02, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                let cell = self.collectionView.cellForItem(at: IndexPath(row: self.items.count - index - 1, section: 0))
                cell?.transform = self.transformItemAtIndex(index, negative: true)
                cell?.alpha = 0
                if index + 1 == self.items.count {
                    self.backgroundView.alpha = 0
                }
            }, completion: { _ in
                if index + 1 == self.items.count {
                    completion?()
                }
            })
        }
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.left:
            self.dismiss = .toLeft
        case UISwipeGestureRecognizerDirection.right:
            self.dismiss = .toRight
        default:
            break
        }
        
        if self.isPopover {
            self.leaveTheStage {
                self.dismiss(animated: true, completion: {
                    self.completion?()
                })
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.completion?()
            })
        }
    }
    
    @objc func pressButton(_ button: UIButton) {
        let item = self.items[button.tag]
        item.isSelected = !item.isSelected
        let cell = self.collectionView.cellForItem(at: IndexPath(row: button.tag, section: 0))
        cell?.isSelected = item.isSelected
        
        self.action?(item)
    }
    
    @objc func dismissMenu(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: {
            self.completion?()
        })
    }
    
    static func presentFromViewController(_ viewController: UIViewController, appear: DropdownGridMenuAppear, leftBarButtonItem: UIBarButtonItem?, rightBarButtonItem: UIBarButtonItem?, items: [DropdownGridMenuItem], itemSize: CGSize, action: ((DropdownGridMenuItem) -> Swift.Void)? = nil, completion: (() -> Swift.Void)? = nil) {
        let menuController = DropdownGridMenuController()
        menuController.items = items
        menuController.itemSize = itemSize
        menuController.appear = appear
        menuController.action = action
        menuController.completion = completion
        
        if let menuImage = leftBarButtonItem?.image {
            let leftBarButtonItem = UIBarButtonItem(image: menuImage, style: UIBarButtonItemStyle.plain, target: menuController.self, action: #selector(dismissMenu(sender:)))
            menuController.navigationItem.leftBarButtonItem = leftBarButtonItem
        }
        
        if let menuImage = rightBarButtonItem?.image {
            let rightBarButtonItem = UIBarButtonItem(image: menuImage, style: UIBarButtonItemStyle.plain, target: menuController.self, action: #selector(dismissMenu(sender:)))
            menuController.navigationItem.rightBarButtonItem = rightBarButtonItem
        }
        
        let navigationController = UINavigationController(rootViewController: menuController)
        navigationController.transitioningDelegate = menuController.self
        navigationController.modalPresentationStyle = UIModalPresentationStyle.custom
        
        viewController.present(navigationController, animated: true)
    }
    
    static func presentPopover(_ viewController: UIViewController, appear: DropdownGridMenuAppear, sender: UIBarButtonItem, items: [DropdownGridMenuItem], itemSize: CGSize, contentSize: CGSize, action: ((DropdownGridMenuItem) -> Swift.Void)? = nil, completion: (() -> Swift.Void)? = nil) {
        let menuController = DropdownGridMenuController()
        menuController.items = items
        menuController.itemSize = itemSize
        menuController.appear = appear
        menuController.isPopover = true
        menuController.action = action
        menuController.completion = completion
        
        menuController.modalPresentationStyle = UIModalPresentationStyle.popover
        menuController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
        menuController.popoverPresentationController?.delegate = menuController.self
        menuController.popoverPresentationController?.barButtonItem = sender
        menuController.preferredContentSize = contentSize
        
        viewController.present(menuController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension DropdownGridMenuController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DropdownGridMenuController.cell, for: indexPath) as! DropdownGridMenuCell
        
        let item = self.items[indexPath.row]
        if !item.text.isEmpty {
            cell.textLabel.text = item.text
        } else if item.attributedText.length > 0 {
            cell.textLabel.attributedText = item.attributedText
        }
        
        cell.button.tag = indexPath.row
        cell.button.setImage(item.image, for: .normal)
        cell.button.setImage(item.image.tint(color: UIColor(white: 0.5, alpha: 0.5)), for: .selected)
        cell.button.addTarget(self, action: #selector(pressButton(_:)), for: .touchUpInside)
        cell.isSelected = item.isSelected
        
        return cell
    }
}

// MARK: - UIImage

extension UIImage {
    func tint(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        self.draw(in: rect)
        color.set()
        UIRectFillUsingBlendMode(rect, CGBlendMode.sourceAtop)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DropdownGridMenuController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return self.itemSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsetsMake(5, 0, 5, 0)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension DropdownGridMenuController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitionController.isPresenting = true
        
        return self.transitionController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transitionController.isPresenting = false
        
        return self.transitionController
    }
}

// MARK: - UIPopoverPresentationControllerDelegate

extension DropdownGridMenuController: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        OperationQueue.main.addOperation({
            self.enterTheStage()
        })
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        self.leaveTheStage {
            self.completion?()
        }
        
        return true
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
}