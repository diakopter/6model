
class Mu {
    method new() {
        self.CREATE()
    }

    method CREATE() {
        nqp::instance_of(self)
    }

    proto method Str() { * }
    multi method Str(Mu:U $self:) {
        self.HOW.name(self) ~ '()'
    }

    proto method ACCEPTS($topic) { * }
    multi method ACCEPTS(Mu:U $self: $topic) {
        nqp::type_check($topic, self.WHAT)
    }
    
    method defined() {
        nqp::repr_defined(self)
    }
    
    method isa($type) {
        self.HOW.isa(self, $type)
    }
    
    method Bool() {
        nqp::repr_defined(self)
    }
}
