import Base
import ./compiler.bend as C

def sample() -> C.Expr:
  C.Add{C.Mul{C.Var{}, C.Var{}}, C.Add{C.Mul{C.Const{2n}, C.Var{}}, C.Const{1n}}}

def eval_sample() -> {C.eval(sample(), 2n) == 9n : Nat}:
  {==}
def diff_sample() -> {C.eval(C.diff(sample()), 2n) == 6n : Nat}:
  {==}
def optimized_diff_sample() -> {C.eval(C.optimize(C.diff(sample())), 2n) == 6n : Nat}:
  {==}
def vm_sample() -> {C.exec_vm(C.compile(sample()), 2n, [42n]) == [9n, 42n] : +List<Nat>}:
  {==}
def zero_left() -> {C.optimize(C.Add{C.Const{0n}, C.Var{}}) == C.Var{} : C.Expr}:
  {==}
def zero_right() -> {C.optimize(C.Add{C.Var{}, C.Const{0n}}) == C.Var{} : C.Expr}:
  {==}
def one_left() -> {C.optimize(C.Mul{C.Const{1n}, C.Var{}}) == C.Var{} : C.Expr}:
  {==}
def one_right() -> {C.optimize(C.Mul{C.Var{}, C.Const{1n}}) == C.Var{} : C.Expr}:
  {==}
def annihilate_left() -> {C.optimize(C.Mul{C.Const{0n}, C.Var{}}) == C.Const{0n} : C.Expr}:
  {==}
def annihilate_right() -> {C.optimize(C.Mul{C.Var{}, C.Const{0n}}) == C.Const{0n} : C.Expr}:
  {==}
def fold_add() -> {C.optimize(C.Add{C.Const{2n}, C.Const{3n}}) == C.Const{5n} : C.Expr}:
  {==}
def fold_mul() -> {C.optimize(C.Mul{C.Const{2n}, C.Const{3n}}) == C.Const{6n} : C.Expr}:
  {==}
