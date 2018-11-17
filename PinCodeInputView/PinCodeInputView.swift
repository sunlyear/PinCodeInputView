//
//  PinCodeInputView.swift
//  PinCodeInputView
//
//  Created by Jinsei Shima on 2018/11/06.
//  Copyright © 2018 Jinsei Shima. All rights reserved.
//

import UIKit

public class PinCodeInputView<T: UIView & ItemType>: UIControl, UITextInputTraits, UIKeyInput {
    
    // MARK: - Properties
    
    private(set) public var text: String = "" {
        didSet {
            if let handler = changeTextHandler {
                handler(text)
            }
            updateText()
        }
    }
    
    public var isEmpty: Bool {
        return text.isEmpty
    }
    
    public var isFilled: Bool {
        return text.count == digit
    }
    
    private let digit: Int
    private let itemSpacing: CGFloat
    private var changeTextHandler: ((String) -> Void)? = nil
    private let stackView: UIStackView = .init()
    private var items: [ContainerItemView<T>] = []
    private let itemFactory: () -> UIView
    private var appearance: Appearance?

    // MARK: - Initializers
    
    public init(
        digit: Int,
        itemSpacing: CGFloat,
        itemFactory: @escaping (() -> T)
        ) {
        
        self.digit = digit
        self.itemSpacing = itemSpacing
        self.itemFactory = itemFactory
        
        super.init(frame: .zero)
        
        self.items = (0..<digit).map { _ in
            let item = ContainerItemView(item: itemFactory())
            item.setHandler {
                self.showCursor()
                self.becomeFirstResponder()
            }
            return item
        }
        
        addSubview(stackView)
        
        items.forEach { stackView.addArrangedSubview($0) }
        stackView.spacing = itemSpacing
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        guard let appearance = appearance else {
            stackView.frame = bounds
            return
        }
        
        stackView.bounds = CGRect(
            x: 0,
            y: 0,
            width: (appearance.itemSize.width * CGFloat(digit)) + (itemSpacing * CGFloat(digit - 1)),
            height: appearance.itemSize.height
        )
        stackView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }
    
    override public var intrinsicContentSize: CGSize {
        return stackView.bounds.size
    }

    public func set(text: String) {
        if text.isPinCode(digit: digit) {
            self.text = text
        }
    }

    public func set(changeTextHandler: @escaping (String) -> ()) {
        self.changeTextHandler = changeTextHandler
    }
    
    public func set(appearance: Appearance) {
        self.appearance = appearance
        items.forEach { $0.item.set(appearance: appearance) }
    }
    
    private func updateText() {
        
        items.enumerated().forEach { (index, item) in
            if (0..<text.count).contains(index) {
                let _index = text.index(text.startIndex, offsetBy: index)
                item.item.text = text[_index]
            } else {
                item.item.text = nil
            }
        }
        showCursor()
    }
    
    private func showCursor() {
        
        let cursorPosition = text.count
        items.enumerated().forEach { (arg) in
            
            let (index, item) = arg
            item.item.isHiddenCursor = (index == cursorPosition) ? false : true
        }
    }
    
    private func hiddenCursor() {
        
        items.forEach { $0.item.isHiddenCursor = true }
    }
    
    // MARK: - UIKeyInput
    
    public var hasText: Bool {
        return !(text.isEmpty)
    }
    
    public func insertText(_ textToInsert: String) {
        if isEnabled && text.count + textToInsert.count <= digit && textToInsert.isOnlyNumeric() {
            text.append(textToInsert)
            sendActions(for: .editingChanged)
        }
    }
    
    public func deleteBackward() {
        if isEnabled && !text.isEmpty {
            text.removeLast()
            sendActions(for: .editingChanged)
        }
    }
    
    // MARK: - UITextInputTraits
    
    public var autocapitalizationType = UITextAutocapitalizationType.none
    public var autocorrectionType = UITextAutocorrectionType.no
    public var spellCheckingType = UITextSpellCheckingType.no
    public var keyboardType = UIKeyboardType.numberPad
    public var keyboardAppearance = UIKeyboardAppearance.default
    public var returnKeyType = UIReturnKeyType.done
    public var enablesReturnKeyAutomatically = true
    
    // MARK: - UIResponder
    
    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        showCursor()
        return super.becomeFirstResponder()
    }
    
    override public var canBecomeFirstResponder: Bool {
        return true
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        hiddenCursor()
        return super.resignFirstResponder()
    }
    
}


// TODO: itemのappearanceは各itemに任せる。PincodeInputViewとしてはspacingとか全体に関するものだけ提供

public struct Appearance {
    
    // struct ItemAppearance
    
    public let itemSize: CGSize
    public let font: UIFont
    public let textColor: UIColor
    public let backgroundColor: UIColor
    public let cursorColor: UIColor
    public let cornerRadius: CGFloat
    
    public init(
        itemSize: CGSize,
        font: UIFont,
        textColor: UIColor,
        backgroundColor: UIColor,
        cursorColor: UIColor,
        cornerRadius: CGFloat
        ) {
        
        self.itemSize = itemSize
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.cursorColor = cursorColor
        self.cornerRadius = cornerRadius
    }
}

private class ContainerItemView<T: UIView & ItemType>: UIView {
    
    var item: T
    private let surface: UIView = .init()
    private var didTapHandler: (() -> ())?

    init(item: T) {
        
        self.item = item
        
        super.init(frame: .zero)
        
        addSubview(item)
        addSubview(surface)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        surface.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        item.frame = bounds
        surface.frame = bounds
    }
    
    func setHandler(handler: @escaping () -> ()) {
        didTapHandler = handler
    }
    
    @objc private func didTap() {
        if let handler = didTapHandler {
            handler()
        }
    }
}

public protocol ItemType {
    var text: Character? { get set }
    var isHiddenCursor: Bool { get set }
    func set(appearance: Appearance)
}


// Default Item View
public class ItemView: UIView, ItemType {
    
    public var text: Character? = nil {
        didSet {
            guard let text = text else {
                label.text = nil
                return
            }
            label.text = String(text)
        }
    }
    
    public var isHiddenCursor: Bool = true {
        didSet {
            cursor.isHidden = isHiddenCursor
        }
    }
    
    public let label: UILabel = .init()
    public let cursor: UIView = .init()
    
    public init() {
        
        super.init(frame: .zero)
        
        addSubview(label)
        addSubview(cursor)
        
        clipsToBounds = true
        
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        
        cursor.isHidden = true
        
        UIView.animateKeyframes(
            withDuration: 1.6,
            delay: 0.8,
            options: [.repeat],
            animations: {
                UIView.addKeyframe(
                    withRelativeStartTime: 0,
                    relativeDuration: 0.2,
                    animations: {
                        self.cursor.alpha = 0
                })
                UIView.addKeyframe(
                    withRelativeStartTime: 0.8,
                    relativeDuration: 0.2,
                    animations: {
                        self.cursor.alpha = 1
                })
        },
            completion: nil
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = bounds
        
        let width: CGFloat = 2
        let height: CGFloat = bounds.height * 0.6
        
        cursor.frame = CGRect(
            x: (bounds.width - width) / 2,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        )
    }
    
    public func set(appearance: Appearance) {
        bounds.size = appearance.itemSize
        label.font = appearance.font
        label.textColor = appearance.textColor
        cursor.backgroundColor = appearance.cursorColor
        backgroundColor = appearance.backgroundColor
        layer.cornerRadius = appearance.cornerRadius
        layoutIfNeeded()
    }
}
