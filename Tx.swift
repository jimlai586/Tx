import UIKit

protocol Redux: class {
    func action<V> (_ action: @escaping (V, Self) -> ()) -> (V) -> ()
}
extension Redux where Self: UIViewController {
    func action<V> (_ action: @escaping (V, Self) -> ()) -> (V) -> () {
        return { [weak self] v in
            if let vc = self {
                action(v, vc)
            }
        }
    }
}

infix operator >~: MultiplicationPrecedence
func >~<U, V, W> (_ lhs: @escaping (U) -> V, _ rhs: @escaping (V) -> W) -> (U) -> W {
    return { u in
        return rhs(lhs(u))
    }
}

func >~<U, V> (_ lhs: @escaping (U) -> V, _ rhs: @escaping (V) -> ()) -> (U) -> () {
    return { u in
        return rhs(lhs(u))
    }
}


infix operator ~<: AdditionPrecedence
func ~<<U>(_ lhs: inout Rx<U>, _ cls: @escaping (U) -> ()) {
    lhs.next = cls
}

struct Rx<U> {
    var rx: U {
        didSet {
            next?(rx)
        }
    }
    init(_ rx: U) {
        self.rx = rx
    }
    var next: ((U) -> ())?

}


class TfRx: UITextField, UITextFieldDelegate {
    var rxEndEditing = Rx("")
    var shouldChange: ((UITextField, NSRange, String) -> Bool)?
    var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        self.delegate = self
        addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)
    }

    @objc func textDidChange(_ sender: UITextField) {
        if let t = timer {
            t.invalidate()
            self.rxEndEditing.rx = ""
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            self.rxEndEditing.rx = self.text ?? ""
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldChange?(textField, range, string) ?? true
    }
}


