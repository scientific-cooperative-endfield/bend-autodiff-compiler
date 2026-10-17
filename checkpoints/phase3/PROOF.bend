import Base
import ./compiler.bend as C
import ./LAWS.bend as L

def flip(-a: Nat, -b: Nat, e: {a == b : Nat}) -> {b == a : Nat}:
  Equal.sym(Nat, a, b, e)

def L.add_zero_l(a):
  {==}

def L.add_zero_r(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %L.add_zero_r(p) : {1n+Nat.add(p, 0n) == 1n+_ : Nat}
      {==}

def L.add_succ(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %L.add_succ(p, b) : {1n+Nat.add(p, 1n+b) == 1n+_ : Nat}
      {==}

def L.add_comm(a, b):
  match a:
    case 0n:
      %L.add_zero_r(b) : {_ == Nat.add(b, 0n) : Nat}
      {==}
    case 1n+p:
      %flip(Nat.add(b, 1n+p), 1n+Nat.add(b, p), L.add_succ(b, p)) : {1n+Nat.add(p, b) == _ : Nat}
      %L.add_comm(p, b) : {1n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def L.add_assoc(a, b, c):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %L.add_assoc(p, b, c) : {1n+Nat.add(Nat.add(p, b), c) == 1n+_ : Nat}
      {==}

def L.add_swap(a, b, c):
  %L.add_assoc(b, a, c) : {Nat.add(a, Nat.add(b, c)) == _ : Nat}
  %L.add_comm(a, b) : {Nat.add(a, Nat.add(b, c)) == Nat.add(_, c) : Nat}
  flip(Nat.add(Nat.add(a, b), c), Nat.add(a, Nat.add(b, c)), L.add_assoc(a, b, c))

def L.mul_zero_l(a):
  {==}

def L.mul_zero_r(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      L.mul_zero_r(p)

def L.mul_one_l(a):
  L.add_zero_r(a)

def L.mul_one_r(a):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %L.mul_one_r(p) : {1n+Nat.mul(p, 1n) == 1n+_ : Nat}
      {==}

def L.mul_succ_r(a, b):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %L.add_swap(b, p, Nat.mul(p, b)) : {1n+Nat.add(b, Nat.mul(p, 1n+b)) == 1n+_ : Nat}
      %L.mul_succ_r(p, b) : {1n+Nat.add(b, Nat.mul(p, 1n+b)) == 1n+Nat.add(b, _) : Nat}
      {==}

def L.mul_comm(a, b):
  match a:
    case 0n:
      %L.mul_zero_r(b) : {_ == Nat.mul(b, 0n) : Nat}
      {==}
    case 1n+p:
      %flip(Nat.mul(b, 1n+p), Nat.add(b, Nat.mul(b, p)), L.mul_succ_r(b, p)) : {Nat.add(b, Nat.mul(p, b)) == _ : Nat}
      %L.mul_comm(p, b) : {Nat.add(b, Nat.mul(p, b)) == Nat.add(b, _) : Nat}
      {==}

def L.mul_add_l(a, b, c):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %flip(Nat.add(Nat.add(c, Nat.mul(p, c)), Nat.mul(b, c)), Nat.add(c, Nat.add(Nat.mul(p, c), Nat.mul(b, c))), L.add_assoc(c, Nat.mul(p, c), Nat.mul(b, c))) : {Nat.add(c, Nat.mul(Nat.add(p, b), c)) == _ : Nat}
      %L.mul_add_l(p, b, c) : {Nat.add(c, Nat.mul(Nat.add(p, b), c)) == Nat.add(c, _) : Nat}
      {==}

def L.mul_add_r(a, b, c):
  %L.mul_comm(Nat.add(b, c), a) : {_ == Nat.add(Nat.mul(a, b), Nat.mul(a, c)) : Nat}
  %L.mul_comm(b, a) : {Nat.mul(Nat.add(b, c), a) == Nat.add(_, Nat.mul(a, c)) : Nat}
  %L.mul_comm(c, a) : {Nat.mul(Nat.add(b, c), a) == Nat.add(Nat.mul(b, a), _) : Nat}
  L.mul_add_l(b, c, a)

def L.mul_assoc(a, b, c):
  match a:
    case 0n:
      {==}
    case 1n+p:
      %flip(Nat.mul(Nat.add(b, Nat.mul(p, b)), c), Nat.add(Nat.mul(b, c), Nat.mul(Nat.mul(p, b), c)), L.mul_add_l(b, Nat.mul(p, b), c)) : {_ == Nat.add(Nat.mul(b, c), Nat.mul(p, Nat.mul(b, c))) : Nat}
      %L.mul_assoc(p, b, c) : {Nat.add(Nat.mul(b, c), Nat.mul(Nat.mul(p, b), c)) == Nat.add(Nat.mul(b, c), _) : Nat}
      {==}

def L.smart_add_sound(a, b, x):
  match a b:
    case C.Const{0n} C.Const{0n}:
      {==}
    case C.Const{0n} C.Const{1n}:
      {==}
    case C.Const{0n} C.Const{2n+bp}:
      {==}
    case C.Const{0n} C.Var{}:
      {==}
    case C.Const{0n} C.Add{bl, br}:
      {==}
    case C.Const{0n} C.Mul{bl, br}:
      {==}
    case C.Const{1n} C.Const{0n}:
      flip(Nat.add(C.eval(C.Const{1n}, x), 0n), C.eval(C.Const{1n}, x), L.add_zero_r(C.eval(C.Const{1n}, x)))
    case C.Const{1n} C.Const{1n}:
      {==}
    case C.Const{1n} C.Const{2n+bp}:
      {==}
    case C.Const{1n} C.Var{}:
      {==}
    case C.Const{1n} C.Add{bl, br}:
      {==}
    case C.Const{1n} C.Mul{bl, br}:
      {==}
    case C.Const{2n+ap} C.Const{0n}:
      flip(Nat.add(C.eval(C.Const{2n+ap}, x), 0n), C.eval(C.Const{2n+ap}, x), L.add_zero_r(C.eval(C.Const{2n+ap}, x)))
    case C.Const{2n+ap} C.Const{1n}:
      {==}
    case C.Const{2n+ap} C.Const{2n+bp}:
      {==}
    case C.Const{2n+ap} C.Var{}:
      {==}
    case C.Const{2n+ap} C.Add{bl, br}:
      {==}
    case C.Const{2n+ap} C.Mul{bl, br}:
      {==}
    case C.Var{} C.Const{0n}:
      flip(Nat.add(C.eval(C.Var{}, x), 0n), C.eval(C.Var{}, x), L.add_zero_r(C.eval(C.Var{}, x)))
    case C.Var{} C.Const{1n}:
      {==}
    case C.Var{} C.Const{2n+bp}:
      {==}
    case C.Var{} C.Var{}:
      {==}
    case C.Var{} C.Add{bl, br}:
      {==}
    case C.Var{} C.Mul{bl, br}:
      {==}
    case C.Add{al, ar} C.Const{0n}:
      flip(Nat.add(C.eval(C.Add{al, ar}, x), 0n), C.eval(C.Add{al, ar}, x), L.add_zero_r(C.eval(C.Add{al, ar}, x)))
    case C.Add{al, ar} C.Const{1n}:
      {==}
    case C.Add{al, ar} C.Const{2n+bp}:
      {==}
    case C.Add{al, ar} C.Var{}:
      {==}
    case C.Add{al, ar} C.Add{bl, br}:
      {==}
    case C.Add{al, ar} C.Mul{bl, br}:
      {==}
    case C.Mul{al, ar} C.Const{0n}:
      flip(Nat.add(C.eval(C.Mul{al, ar}, x), 0n), C.eval(C.Mul{al, ar}, x), L.add_zero_r(C.eval(C.Mul{al, ar}, x)))
    case C.Mul{al, ar} C.Const{1n}:
      {==}
    case C.Mul{al, ar} C.Const{2n+bp}:
      {==}
    case C.Mul{al, ar} C.Var{}:
      {==}
    case C.Mul{al, ar} C.Add{bl, br}:
      {==}
    case C.Mul{al, ar} C.Mul{bl, br}:
      {==}

def L.smart_mul_sound(a, b, x):
  match a b:
    case C.Const{0n} C.Const{0n}:
      {==}
    case C.Const{0n} C.Const{1n}:
      {==}
    case C.Const{0n} C.Const{2n+bp}:
      {==}
    case C.Const{0n} C.Var{}:
      {==}
    case C.Const{0n} C.Add{bl, br}:
      {==}
    case C.Const{0n} C.Mul{bl, br}:
      {==}
    case C.Const{1n} C.Const{0n}:
      flip(Nat.mul(C.eval(C.Const{1n}, x), 0n), 0n, L.mul_zero_r(C.eval(C.Const{1n}, x)))
    case C.Const{1n} C.Const{1n}:
      flip(Nat.mul(1n, C.eval(C.Const{1n}, x)), C.eval(C.Const{1n}, x), L.mul_one_l(C.eval(C.Const{1n}, x)))
    case C.Const{1n} C.Const{2n+bp}:
      flip(Nat.mul(1n, C.eval(C.Const{2n+bp}, x)), C.eval(C.Const{2n+bp}, x), L.mul_one_l(C.eval(C.Const{2n+bp}, x)))
    case C.Const{1n} C.Var{}:
      flip(Nat.mul(1n, C.eval(C.Var{}, x)), C.eval(C.Var{}, x), L.mul_one_l(C.eval(C.Var{}, x)))
    case C.Const{1n} C.Add{bl, br}:
      flip(Nat.mul(1n, C.eval(C.Add{bl, br}, x)), C.eval(C.Add{bl, br}, x), L.mul_one_l(C.eval(C.Add{bl, br}, x)))
    case C.Const{1n} C.Mul{bl, br}:
      flip(Nat.mul(1n, C.eval(C.Mul{bl, br}, x)), C.eval(C.Mul{bl, br}, x), L.mul_one_l(C.eval(C.Mul{bl, br}, x)))
    case C.Const{2n+ap} C.Const{0n}:
      flip(Nat.mul(C.eval(C.Const{2n+ap}, x), 0n), 0n, L.mul_zero_r(C.eval(C.Const{2n+ap}, x)))
    case C.Const{2n+ap} C.Const{1n}:
      flip(Nat.mul(C.eval(C.Const{2n+ap}, x), 1n), C.eval(C.Const{2n+ap}, x), L.mul_one_r(C.eval(C.Const{2n+ap}, x)))
    case C.Const{2n+ap} C.Const{2n+bp}:
      {==}
    case C.Const{2n+ap} C.Var{}:
      {==}
    case C.Const{2n+ap} C.Add{bl, br}:
      {==}
    case C.Const{2n+ap} C.Mul{bl, br}:
      {==}
    case C.Var{} C.Const{0n}:
      flip(Nat.mul(C.eval(C.Var{}, x), 0n), 0n, L.mul_zero_r(C.eval(C.Var{}, x)))
    case C.Var{} C.Const{1n}:
      flip(Nat.mul(C.eval(C.Var{}, x), 1n), C.eval(C.Var{}, x), L.mul_one_r(C.eval(C.Var{}, x)))
    case C.Var{} C.Const{2n+bp}:
      {==}
    case C.Var{} C.Var{}:
      {==}
    case C.Var{} C.Add{bl, br}:
      {==}
    case C.Var{} C.Mul{bl, br}:
      {==}
    case C.Add{al, ar} C.Const{0n}:
      flip(Nat.mul(C.eval(C.Add{al, ar}, x), 0n), 0n, L.mul_zero_r(C.eval(C.Add{al, ar}, x)))
    case C.Add{al, ar} C.Const{1n}:
      flip(Nat.mul(C.eval(C.Add{al, ar}, x), 1n), C.eval(C.Add{al, ar}, x), L.mul_one_r(C.eval(C.Add{al, ar}, x)))
    case C.Add{al, ar} C.Const{2n+bp}:
      {==}
    case C.Add{al, ar} C.Var{}:
      {==}
    case C.Add{al, ar} C.Add{bl, br}:
      {==}
    case C.Add{al, ar} C.Mul{bl, br}:
      {==}
    case C.Mul{al, ar} C.Const{0n}:
      flip(Nat.mul(C.eval(C.Mul{al, ar}, x), 0n), 0n, L.mul_zero_r(C.eval(C.Mul{al, ar}, x)))
    case C.Mul{al, ar} C.Const{1n}:
      flip(Nat.mul(C.eval(C.Mul{al, ar}, x), 1n), C.eval(C.Mul{al, ar}, x), L.mul_one_r(C.eval(C.Mul{al, ar}, x)))
    case C.Mul{al, ar} C.Const{2n+bp}:
      {==}
    case C.Mul{al, ar} C.Var{}:
      {==}
    case C.Mul{al, ar} C.Add{bl, br}:
      {==}
    case C.Mul{al, ar} C.Mul{bl, br}:
      {==}

def L.optimize_sound(e, x):
  match e:
    case C.Const{v}:
      {==}
    case C.Var{}:
      {==}
    case C.Add{a, b}:
      %L.optimize_sound(a, x) : {C.eval(C.smart_add(C.optimize(a), C.optimize(b)), x) == Nat.add(_, C.eval(b, x)) : Nat}
      %L.optimize_sound(b, x) : {C.eval(C.smart_add(C.optimize(a), C.optimize(b)), x) == Nat.add(C.eval(C.optimize(a), x), _) : Nat}
      L.smart_add_sound(C.optimize(a), C.optimize(b), x)
    case C.Mul{a, b}:
      %L.optimize_sound(a, x) : {C.eval(C.smart_mul(C.optimize(a), C.optimize(b)), x) == Nat.mul(_, C.eval(b, x)) : Nat}
      %L.optimize_sound(b, x) : {C.eval(C.smart_mul(C.optimize(a), C.optimize(b)), x) == Nat.mul(C.eval(C.optimize(a), x), _) : Nat}
      L.smart_mul_sound(C.optimize(a), C.optimize(b), x)

def L.diff_const(v, x):
  {==}
def L.diff_var(x):
  {==}
def L.diff_add(a, b, x):
  {==}
def L.diff_mul(a, b, x):
  {==}

def L.diff_correct(e, x):
  match e:
    case C.Const{v}:
      {==}
    case C.Var{}:
      {==}
    case C.Add{a, b}:
      %L.diff_correct(a, x) : {Nat.add(C.eval(C.diff(a), x), C.eval(C.diff(b), x)) == Nat.add(_, C.tangent(b, x)) : Nat}
      %L.diff_correct(b, x) : {Nat.add(C.eval(C.diff(a), x), C.eval(C.diff(b), x)) == Nat.add(C.eval(C.diff(a), x), _) : Nat}
      {==}
    case C.Mul{a, b}:
      %L.diff_correct(a, x) : {C.eval(C.diff(C.Mul{a, b}), x) == Nat.add(Nat.mul(_, C.eval(b, x)), Nat.mul(C.eval(a, x), C.tangent(b, x))) : Nat}
      %L.diff_correct(b, x) : {C.eval(C.diff(C.Mul{a, b}), x) == Nat.add(Nat.mul(C.eval(C.diff(a), x), C.eval(b, x)), Nat.mul(C.eval(a, x), _)) : Nat}
      {==}

def L.diff_optimize_sound(e, x):
  L.optimize_sound(C.diff(e), x)

def add_cong(+a: C.Expr, +b: C.Expr, pa: {C.optimize(a) == a : C.Expr}, pb: {C.optimize(b) == b : C.Expr}) -> {C.smart_add(C.optimize(a), C.optimize(b)) == C.smart_add(a, b) : C.Expr}:
  %pa : {C.smart_add(C.optimize(a), C.optimize(b)) == C.smart_add(_, b) : C.Expr}
  %pb : {C.smart_add(C.optimize(a), C.optimize(b)) == C.smart_add(C.optimize(a), _) : C.Expr}
  {==}

def mul_cong(+a: C.Expr, +b: C.Expr, pa: {C.optimize(a) == a : C.Expr}, pb: {C.optimize(b) == b : C.Expr}) -> {C.smart_mul(C.optimize(a), C.optimize(b)) == C.smart_mul(a, b) : C.Expr}:
  %pa : {C.smart_mul(C.optimize(a), C.optimize(b)) == C.smart_mul(_, b) : C.Expr}
  %pb : {C.smart_mul(C.optimize(a), C.optimize(b)) == C.smart_mul(C.optimize(a), _) : C.Expr}
  {==}

def L.smart_add_stable(a, b, pa, pb):
  match a b:
    case C.Const{0n} C.Const{0n}:
      pb
    case C.Const{0n} C.Const{1n}:
      pb
    case C.Const{0n} C.Const{2n+bp}:
      pb
    case C.Const{0n} C.Var{}:
      pb
    case C.Const{0n} C.Add{bl, br}:
      pb
    case C.Const{0n} C.Mul{bl, br}:
      pb
    case C.Const{1n} C.Const{0n}:
      pa
    case C.Const{1n} C.Const{1n}:
      {==}
    case C.Const{1n} C.Const{2n+bp}:
      {==}
    case C.Const{1n} C.Var{}:
      add_cong(C.Const{1n}, C.Var{}, pa, pb)
    case C.Const{1n} C.Add{bl, br}:
      add_cong(C.Const{1n}, C.Add{bl, br}, pa, pb)
    case C.Const{1n} C.Mul{bl, br}:
      add_cong(C.Const{1n}, C.Mul{bl, br}, pa, pb)
    case C.Const{2n+ap} C.Const{0n}:
      pa
    case C.Const{2n+ap} C.Const{1n}:
      {==}
    case C.Const{2n+ap} C.Const{2n+bp}:
      {==}
    case C.Const{2n+ap} C.Var{}:
      add_cong(C.Const{2n+ap}, C.Var{}, pa, pb)
    case C.Const{2n+ap} C.Add{bl, br}:
      add_cong(C.Const{2n+ap}, C.Add{bl, br}, pa, pb)
    case C.Const{2n+ap} C.Mul{bl, br}:
      add_cong(C.Const{2n+ap}, C.Mul{bl, br}, pa, pb)
    case C.Var{} C.Const{0n}:
      pa
    case C.Var{} C.Const{1n}:
      add_cong(C.Var{}, C.Const{1n}, pa, pb)
    case C.Var{} C.Const{2n+bp}:
      add_cong(C.Var{}, C.Const{2n+bp}, pa, pb)
    case C.Var{} C.Var{}:
      add_cong(C.Var{}, C.Var{}, pa, pb)
    case C.Var{} C.Add{bl, br}:
      add_cong(C.Var{}, C.Add{bl, br}, pa, pb)
    case C.Var{} C.Mul{bl, br}:
      add_cong(C.Var{}, C.Mul{bl, br}, pa, pb)
    case C.Add{al, ar} C.Const{0n}:
      pa
    case C.Add{al, ar} C.Const{1n}:
      add_cong(C.Add{al, ar}, C.Const{1n}, pa, pb)
    case C.Add{al, ar} C.Const{2n+bp}:
      add_cong(C.Add{al, ar}, C.Const{2n+bp}, pa, pb)
    case C.Add{al, ar} C.Var{}:
      add_cong(C.Add{al, ar}, C.Var{}, pa, pb)
    case C.Add{al, ar} C.Add{bl, br}:
      add_cong(C.Add{al, ar}, C.Add{bl, br}, pa, pb)
    case C.Add{al, ar} C.Mul{bl, br}:
      add_cong(C.Add{al, ar}, C.Mul{bl, br}, pa, pb)
    case C.Mul{al, ar} C.Const{0n}:
      pa
    case C.Mul{al, ar} C.Const{1n}:
      add_cong(C.Mul{al, ar}, C.Const{1n}, pa, pb)
    case C.Mul{al, ar} C.Const{2n+bp}:
      add_cong(C.Mul{al, ar}, C.Const{2n+bp}, pa, pb)
    case C.Mul{al, ar} C.Var{}:
      add_cong(C.Mul{al, ar}, C.Var{}, pa, pb)
    case C.Mul{al, ar} C.Add{bl, br}:
      add_cong(C.Mul{al, ar}, C.Add{bl, br}, pa, pb)
    case C.Mul{al, ar} C.Mul{bl, br}:
      add_cong(C.Mul{al, ar}, C.Mul{bl, br}, pa, pb)

def L.smart_mul_stable(a, b, pa, pb):
  match a b:
    case C.Const{0n} C.Const{0n}:
      {==}
    case C.Const{0n} C.Const{1n}:
      {==}
    case C.Const{0n} C.Const{2n+bp}:
      {==}
    case C.Const{0n} C.Var{}:
      {==}
    case C.Const{0n} C.Add{bl, br}:
      {==}
    case C.Const{0n} C.Mul{bl, br}:
      {==}
    case C.Const{1n} C.Const{0n}:
      {==}
    case C.Const{1n} C.Const{1n}:
      pb
    case C.Const{1n} C.Const{2n+bp}:
      pb
    case C.Const{1n} C.Var{}:
      pb
    case C.Const{1n} C.Add{bl, br}:
      pb
    case C.Const{1n} C.Mul{bl, br}:
      pb
    case C.Const{2n+ap} C.Const{0n}:
      {==}
    case C.Const{2n+ap} C.Const{1n}:
      pa
    case C.Const{2n+ap} C.Const{2n+bp}:
      {==}
    case C.Const{2n+ap} C.Var{}:
      mul_cong(C.Const{2n+ap}, C.Var{}, pa, pb)
    case C.Const{2n+ap} C.Add{bl, br}:
      mul_cong(C.Const{2n+ap}, C.Add{bl, br}, pa, pb)
    case C.Const{2n+ap} C.Mul{bl, br}:
      mul_cong(C.Const{2n+ap}, C.Mul{bl, br}, pa, pb)
    case C.Var{} C.Const{0n}:
      {==}
    case C.Var{} C.Const{1n}:
      pa
    case C.Var{} C.Const{2n+bp}:
      mul_cong(C.Var{}, C.Const{2n+bp}, pa, pb)
    case C.Var{} C.Var{}:
      mul_cong(C.Var{}, C.Var{}, pa, pb)
    case C.Var{} C.Add{bl, br}:
      mul_cong(C.Var{}, C.Add{bl, br}, pa, pb)
    case C.Var{} C.Mul{bl, br}:
      mul_cong(C.Var{}, C.Mul{bl, br}, pa, pb)
    case C.Add{al, ar} C.Const{0n}:
      {==}
    case C.Add{al, ar} C.Const{1n}:
      pa
    case C.Add{al, ar} C.Const{2n+bp}:
      mul_cong(C.Add{al, ar}, C.Const{2n+bp}, pa, pb)
    case C.Add{al, ar} C.Var{}:
      mul_cong(C.Add{al, ar}, C.Var{}, pa, pb)
    case C.Add{al, ar} C.Add{bl, br}:
      mul_cong(C.Add{al, ar}, C.Add{bl, br}, pa, pb)
    case C.Add{al, ar} C.Mul{bl, br}:
      mul_cong(C.Add{al, ar}, C.Mul{bl, br}, pa, pb)
    case C.Mul{al, ar} C.Const{0n}:
      {==}
    case C.Mul{al, ar} C.Const{1n}:
      pa
    case C.Mul{al, ar} C.Const{2n+bp}:
      mul_cong(C.Mul{al, ar}, C.Const{2n+bp}, pa, pb)
    case C.Mul{al, ar} C.Var{}:
      mul_cong(C.Mul{al, ar}, C.Var{}, pa, pb)
    case C.Mul{al, ar} C.Add{bl, br}:
      mul_cong(C.Mul{al, ar}, C.Add{bl, br}, pa, pb)
    case C.Mul{al, ar} C.Mul{bl, br}:
      mul_cong(C.Mul{al, ar}, C.Mul{bl, br}, pa, pb)

def L.optimize_idempotent(e):
  match e:
    case C.Const{v}:
      {==}
    case C.Var{}:
      {==}
    case C.Add{a, b}:
      L.smart_add_stable(C.optimize(a), C.optimize(b), L.optimize_idempotent(a), L.optimize_idempotent(b))
    case C.Mul{a, b}:
      L.smart_mul_stable(C.optimize(a), C.optimize(b), L.optimize_idempotent(a), L.optimize_idempotent(b))

def L.vm_append(a, b, x, s):
  match a:
    case Nil{}:
      {==}
    case Con{i, rest}:
      L.vm_append(rest, b, x, C.step(i, x, s))

def L.compile_sound(e, x, s):
  match e:
    case C.Const{v}:
      {==}
    case C.Var{}:
      {==}
    case C.Add{a, b}:
      %Equal.sym(+List<Nat>, C.exec_vm(C.append(C.compile(a), C.append(C.compile(b), [C.OpAdd{}])), x, s), C.exec_vm(C.append(C.compile(b), [C.OpAdd{}]), x, C.exec_vm(C.compile(a), x, s)), L.vm_append(C.compile(a), C.append(C.compile(b), [C.OpAdd{}]), x, s)) : {_ == Con{C.eval(C.Add{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.compile(a), x, s), Con{C.eval(a, x), s}, L.compile_sound(a, x, s)) : {C.exec_vm(C.append(C.compile(b), [C.OpAdd{}]), x, _) == Con{C.eval(C.Add{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.append(C.compile(b), [C.OpAdd{}]), x, Con{C.eval(a, x), s}), C.exec_vm([C.OpAdd{}], x, C.exec_vm(C.compile(b), x, Con{C.eval(a, x), s})), L.vm_append(C.compile(b), [C.OpAdd{}], x, Con{C.eval(a, x), s})) : {_ == Con{C.eval(C.Add{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.compile(b), x, Con{C.eval(a, x), s}), Con{C.eval(b, x), Con{C.eval(a, x), s}}, L.compile_sound(b, x, Con{C.eval(a, x), s})) : {C.exec_vm([C.OpAdd{}], x, _) == Con{C.eval(C.Add{a, b}, x), s} : +List<Nat>}
      {==}
    case C.Mul{a, b}:
      %Equal.sym(+List<Nat>, C.exec_vm(C.append(C.compile(a), C.append(C.compile(b), [C.OpMul{}])), x, s), C.exec_vm(C.append(C.compile(b), [C.OpMul{}]), x, C.exec_vm(C.compile(a), x, s)), L.vm_append(C.compile(a), C.append(C.compile(b), [C.OpMul{}]), x, s)) : {_ == Con{C.eval(C.Mul{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.compile(a), x, s), Con{C.eval(a, x), s}, L.compile_sound(a, x, s)) : {C.exec_vm(C.append(C.compile(b), [C.OpMul{}]), x, _) == Con{C.eval(C.Mul{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.append(C.compile(b), [C.OpMul{}]), x, Con{C.eval(a, x), s}), C.exec_vm([C.OpMul{}], x, C.exec_vm(C.compile(b), x, Con{C.eval(a, x), s})), L.vm_append(C.compile(b), [C.OpMul{}], x, Con{C.eval(a, x), s})) : {_ == Con{C.eval(C.Mul{a, b}, x), s} : +List<Nat>}
      %Equal.sym(+List<Nat>, C.exec_vm(C.compile(b), x, Con{C.eval(a, x), s}), Con{C.eval(b, x), Con{C.eval(a, x), s}}, L.compile_sound(b, x, Con{C.eval(a, x), s})) : {C.exec_vm([C.OpMul{}], x, _) == Con{C.eval(C.Mul{a, b}, x), s} : +List<Nat>}
      {==}

def L.optimized_compile_sound(e, x, s):
  %L.optimize_sound(e, x) : {C.exec_vm(C.compile(C.optimize(e)), x, s) == Con{_, s} : +List<Nat>}
  L.compile_sound(C.optimize(e), x, s)

def L.gradient_compile_sound(e, x, s):
  %L.diff_correct(e, x) : {C.exec_vm(C.compile(C.optimize(C.diff(e))), x, s) == Con{_, s} : +List<Nat>}
  L.optimized_compile_sound(C.diff(e), x, s)
