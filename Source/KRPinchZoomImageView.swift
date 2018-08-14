//
//  KRPinchZoomImageView.swift
//  KRPinchZoom
//
//  Created by kamalraj venkatesan on 14/08/18.
//

import UIKit

public class KRPinchZoomImageView: UIImageView, UIScrollViewDelegate {

  public var isNeedGesture = true // by default true is we need to make it as false if need from the respective class

  var scrollView : UIScrollView!
  var imageView: UIImageView!
  var blurEffectView: UIVisualEffectView!

  var pinchGesture: UIPinchGestureRecognizer? //

  var parentVC: UIViewController? // From where the KRImage view is called

  var imageViewFrame: CGRect? // Frame of image view (root image view), This frame will be used for animation when pinch zoom in ended.

  override public func awakeFromNib() {
    super.awakeFromNib()

    if (self.isNeedGesture) {
      // Yes
      self.isUserInteractionEnabled = true

      if let fromViewController = self.parentViewController {
        self.parentVC = fromViewController // Setting vc where the KRPinchZoomImageView is used

        // Gestures

        // Pinch Gesture
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(sender:)))
        self.pinchGesture?.delegate = self
        self.addGestureRecognizer(self.pinchGesture!)

        // Pan Gesture
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(self.panHandler(recognizer:)))

        panGes.delegate = self
        panGes.minimumNumberOfTouches = 2
        self.addGestureRecognizer(panGes)

      }

    } else {
      //
    }
  }


  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return self.imageView
  }

  /* Zooming the scroll view */
  @objc private func handlePinchGesture(sender: UIPinchGestureRecognizer) {

    guard (self.scrollView != nil) else {
      // no scroll view
      return
    }

    if (sender.scale > self.scrollView.minimumZoomScale) {
      // Zooming in (scale is more than min zoom scale)

      self.adjustAnchorPoint(gestureRecognizer: sender)

      self.scrollView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale) // Increases size of scrollView with respective with pinch gesture

      self.setAlphaForBackgroundView(zoomScale: sender.scale)

    }

    if (sender.state == .ended) || (sender.state == .cancelled)  {
      // Remove scroll view from parent VC
      self.removeZoomableImageView()
    }
  }

  /* This is to change the anchor point of scroll view so user can able to zoom the corner of the images also */
  private func adjustAnchorPoint(gestureRecognizer : UIGestureRecognizer) {
    if gestureRecognizer.state == .began {
      let locationInView = gestureRecognizer.location(in: self.scrollView)

      // Move the anchor point to the touch point and change the position of the view
      self.scrollView?.layer.anchorPoint = CGPoint(x: (locationInView.x / (self.scrollView?.bounds.size.width)!),
                                                   y: (locationInView.y / (self.scrollView?.bounds.size.height)!))
      self.scrollView?.center = locationInView
    }
  }

  /* This Method used to Drag the image */
  @objc func panHandler(recognizer: UIPanGestureRecognizer)
  {
    guard (self.scrollView != nil) else {
      // Scroll View is nill
      return
    }

    if recognizer.state == UIGestureRecognizerState.changed
    {
      // Move image view
      let translation = recognizer.translation(in: self.scrollView)

      self.imageView.center = CGPoint(x: self.imageView.center.x + translation.x, y: self.imageView.center.y + translation.y)

      recognizer.setTranslation(CGPoint.zero, in: self.scrollView)
    }

    if (recognizer.state == .ended) || (recognizer.state == .cancelled) {
      // Remove view from Parent VC
      self.removeZoomableImageView()
    }

  }

  /* Creating view that contains Blur effect view, scroll view and image view */
  internal func createZoomableImageView() {
    // Blur view
    self.blurEffectView = UIVisualEffectView()
    self.blurEffectView.frame = (self.parentVC?.view.frame)!
    self.blurEffectView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    self.parentVC?.view.addSubview(self.blurEffectView)

    // Scroll view
    self.scrollView  = UIScrollView()
    self.scrollView.frame = (self.parentVC?.view.frame)! // setting frame from parent vc
    self.scrollView.minimumZoomScale = 1
    self.scrollView.maximumZoomScale = 5
    self.scrollView.bounces = false
    self.scrollView.delegate = self
    self.blurEffectView.contentView.addSubview(self.scrollView)

    // Image view
    self.imageView = UIImageView()
    let frameOfImageView = self.parentVC?.view.convert(self.frame, from: self.superview)
    self.imageViewFrame = frameOfImageView!
    self.imageView.frame = frameOfImageView!
    self.imageView.image = image
    self.imageView.contentMode = self.contentMode
    self.imageView.backgroundColor = UIColor.clear
    self.scrollView.addSubview(self.imageView)

    // Remove image from source image view
    self.image = nil

  }
  /* To Remove the view over the vc which we have created. */
  internal func removeZoomableImageView() {

    guard (self.scrollView != nil) else {
      return
    }


    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {


      self.imageView.frame.origin = (self.imageViewFrame?.origin)!

      self.imageView.frame.size = (self.imageViewFrame?.size)!

      self.imageView.layoutIfNeeded()


    }) { (completed) in

      UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {

        if (self.scrollView != nil) {

          self.scrollView.transform = CGAffineTransform.identity
          self.blurEffectView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)

          self.layoutIfNeeded()

          self.setNeedsLayout()

        }

      }, completion: { (completed) in


        if (self.blurEffectView != nil) {

          self.image = self.imageView.image // setting image to source image view.

          self.blurEffectView.removeFromSuperview()


          self.pinchGesture?.delegate = nil
          self.imageViewFrame = nil
          self.pinchGesture = nil
          self.blurEffectView = nil
          self.scrollView = nil
          self.imageView = nil

        }
      })

    }

  }
  /* To Increase alpha value with zoom */
  internal func setAlphaForBackgroundView(zoomScale: CGFloat) {

    let alphaForBackground = zoomScale / 2.5

    guard alphaForBackground < 0.82 else {
      // Greater than 0.82
      return
    }

    self.blurEffectView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: alphaForBackground) // changing background color new alpha value
  }
}

extension KRPinchZoomImageView: UIGestureRecognizerDelegate {
  override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    super.gestureRecognizerShouldBegin(gestureRecognizer)

    guard gestureRecognizer.view == self else {
      // Some other view (Not KRPinchZoomImageView)
      return true
    }

    guard !(gestureRecognizer is UIPanGestureRecognizer) else {
      return true
    }

    guard self.isNeedGesture else {
      // no gesture
      return true
    }

    guard self.parentVC != nil else {
      // parent vc is nil
      return true
    }

    guard self.image != nil else {
      // No image
      return false
    }

    guard self.scrollView == nil else {
      // scroll view is already exist
      return false
    }

    self.createZoomableImageView()

    return true
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }

}

extension UIView {
  var parentViewController: UIViewController? {
    var parentResponder: UIResponder? = self
    while parentResponder != nil {
      parentResponder = parentResponder!.next
      if let viewController = parentResponder as? UIViewController {
        return viewController
      }
    }

    // if failed to fetch from herarchy
    if var topController = UIApplication.shared.keyWindow?.rootViewController {
      while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
      }

      return topController
    }

    return nil
  }
}
