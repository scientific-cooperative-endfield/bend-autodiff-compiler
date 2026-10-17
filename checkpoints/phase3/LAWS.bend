import Base
import ./compiler.bend as C

law add_zero_l:
  for +a: Nat
  {Nat.add(0n, a) == a : Nat}
law add_zero_r:
  for +a: Nat
  {Nat.add(a, 0n) == a : Nat}
law add_succ:
  for +a: Nat
  for +b: Nat
  {Nat.add(a, 1n+b) == 1n+Nat.add(a, b) : Nat}
law add_comm:
  for +a: Nat
  for +b: Nat
  {Nat.add(a, b) == Nat.add(b, a) : Nat}
law add_assoc:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.add(Nat.add(a, b), c) == Nat.add(a, Nat.add(b, c)) : Nat}
law add_swap:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.add(a, Nat.add(b, c)) == Nat.add(b, Nat.add(a, c)) : Nat}
law mul_zero_l:
  for +a: Nat
  {Nat.mul(0n, a) == 0n : Nat}
law mul_zero_r:
  for +a: Nat
  {Nat.mul(a, 0n) == 0n : Nat}
law mul_one_l:
  for +a: Nat
  {Nat.mul(1n, a) == a : Nat}
law mul_one_r:
  for +a: Nat
  {Nat.mul(a, 1n) == a : Nat}
law mul_succ_r:
  for +a: Nat
  for +b: Nat
  {Nat.mul(a, 1n+b) == Nat.add(a, Nat.mul(a, b)) : Nat}
law mul_comm:
  for +a: Nat
  for +b: Nat
  {Nat.mul(a, b) == Nat.mul(b, a) : Nat}
law mul_add_l:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.mul(Nat.add(a, b), c) == Nat.add(Nat.mul(a, c), Nat.mul(b, c)) : Nat}
law mul_add_r:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.mul(a, Nat.add(b, c)) == Nat.add(Nat.mul(a, b), Nat.mul(a, c)) : Nat}
law mul_assoc:
  for +a: Nat
  for +b: Nat
  for +c: Nat
  {Nat.mul(Nat.mul(a, b), c) == Nat.mul(a, Nat.mul(b, c)) : Nat}

law smart_add_sound:
  for +a: C.Expr
  for +b: C.Expr
  for +x: Nat
  {C.eval(C.smart_add(a, b), x) == Nat.add(C.eval(a, x), C.eval(b, x)) : Nat}

law smart_mul_sound:
  for +a: C.Expr
  for +b: C.Expr
  for +x: Nat
  {C.eval(C.smart_mul(a, b), x) == Nat.mul(C.eval(a, x), C.eval(b, x)) : Nat}

law optimize_sound:
  for +e: C.Expr
  for +x: Nat
  {C.eval(C.optimize(e), x) == C.eval(e, x) : Nat}

law diff_const:
  for +v: Nat
  for +x: Nat
  {C.eval(C.diff(C.Const{v}), x) == 0n : Nat}

law diff_var:
  for +x: Nat
  {C.eval(C.diff(C.Var{}), x) == 1n : Nat}

law diff_add:
  for +a: C.Expr
  for +b: C.Expr
  for +x: Nat
  {C.eval(C.diff(C.Add{a, b}), x) == Nat.add(C.eval(C.diff(a), x), C.eval(C.diff(b), x)) : Nat}

law diff_mul:
  for +a: C.Expr
  for +b: C.Expr
  for +x: Nat
  {C.eval(C.diff(C.Mul{a, b}), x) == Nat.add(Nat.mul(C.eval(C.diff(a), x), C.eval(b, x)), Nat.mul(C.eval(a, x), C.eval(C.diff(b), x))) : Nat}

law diff_correct:
  for +e: C.Expr
  for +x: Nat
  {C.eval(C.diff(e), x) == C.tangent(e, x) : Nat}

law diff_optimize_sound:
  for +e: C.Expr
  for +x: Nat
  {C.eval(C.optimize(C.diff(e)), x) == C.eval(C.diff(e), x) : Nat}

law smart_add_stable:
  for +a: C.Expr
  for +b: C.Expr
  for pa: {C.optimize(a) == a : C.Expr}
  for pb: {C.optimize(b) == b : C.Expr}
  {C.optimize(C.smart_add(a, b)) == C.smart_add(a, b) : C.Expr}

law smart_mul_stable:
  for +a: C.Expr
  for +b: C.Expr
  for pa: {C.optimize(a) == a : C.Expr}
  for pb: {C.optimize(b) == b : C.Expr}
  {C.optimize(C.smart_mul(a, b)) == C.smart_mul(a, b) : C.Expr}

law optimize_idempotent:
  for +e: C.Expr
  {C.optimize(C.optimize(e)) == C.optimize(e) : C.Expr}

law vm_append:
  for +a: +List<C.Instr>
  for +b: +List<C.Instr>
  for +x: Nat
  for +s: +List<Nat>
  {C.exec_vm(C.append(a, b), x, s) == C.exec_vm(b, x, C.exec_vm(a, x, s)) : +List<Nat>}

law compile_sound:
  for +e: C.Expr
  for +x: Nat
  for +s: +List<Nat>
  {C.exec_vm(C.compile(e), x, s) == Con{C.eval(e, x), s} : +List<Nat>}

law optimized_compile_sound:
  for +e: C.Expr
  for +x: Nat
  for +s: +List<Nat>
  {C.exec_vm(C.compile(C.optimize(e)), x, s) == Con{C.eval(e, x), s} : +List<Nat>}

law gradient_compile_sound:
  for +e: C.Expr
  for +x: Nat
  for +s: +List<Nat>
  {C.exec_vm(C.compile(C.optimize(C.diff(e))), x, s) == Con{C.tangent(e, x), s} : +List<Nat>}
