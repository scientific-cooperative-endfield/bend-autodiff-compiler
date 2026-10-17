import Base

type Expr is Data:
  Const{val: Nat}
  Var{}
  Add{lhs: Expr, rhs: Expr}
  Mul{lhs: Expr, rhs: Expr}

def eval(e: Expr, +x: Nat) -> Nat:
  match e:
    case Const{v}:
      v
    case Var{}:
      x
    case Add{a, b}:
      av bv = eval(a, x) eval(b, x)
      Nat.add(av, bv)
    case Mul{a, b}:
      av bv = eval(a, x) eval(b, x)
      Nat.mul(av, bv)

def diff(e: Expr) -> Expr:
  match e:
    case Const{_}:
      Const{0n}
    case Var{}:
      Const{1n}
    case Add{a, b}:
      da db = diff(a) diff(b)
      Add{da, db}
    case Mul{+a, +b}:
      da db = diff(a) diff(b)
      Add{Mul{da, b}, Mul{a, db}}

def smart_add(a: Expr, b: Expr) -> Expr:
  match a b:
    case Const{0n} r:
      r
    case l Const{0n}:
      l
    case Const{av} Const{bv}:
      Const{Nat.add(av, bv)}
    case l r:
      Add{l, r}

def smart_mul(a: Expr, b: Expr) -> Expr:
  match a b:
    case Const{0n} _:
      Const{0n}
    case _ Const{0n}:
      Const{0n}
    case Const{1n} r:
      r
    case l Const{1n}:
      l
    case Const{av} Const{bv}:
      Const{Nat.mul(av, bv)}
    case l r:
      Mul{l, r}

def optimize(e: Expr) -> Expr:
  match e:
    case Const{v}:
      Const{v}
    case Var{}:
      Var{}
    case Add{a, b}:
      oa ob = optimize(a) optimize(b)
      smart_add(oa, ob)
    case Mul{a, b}:
      oa ob = optimize(a) optimize(b)
      smart_mul(oa, ob)

# Formal derivative interpretation in the polynomial semiring Nat[x].
def tangent(e: Expr, +x: Nat) -> Nat:
  match e:
    case Const{_}:
      0n
    case Var{}:
      1n
    case Add{a, b}:
      da db = tangent(a, x) tangent(b, x)
      Nat.add(da, db)
    case Mul{+a, +b}:
      da db = tangent(a, x) tangent(b, x)
      Nat.add(Nat.mul(da, eval(b, x)), Nat.mul(eval(a, x), db))

type Instr is Data:
  PushConst{val: Nat}
  PushVar{}
  OpAdd{}
  OpMul{}

def append(a: +List<Instr>, b: +List<Instr>) -> +List<Instr>:
  match a:
    case Nil{}:
      b
    case Con{h, t}:
      Con{h, append(t, b)}

def compile(e: Expr) -> +List<Instr>:
  match e:
    case Const{v}:
      [PushConst{v}]
    case Var{}:
      [PushVar{}]
    case Add{a, b}:
      ca cb = compile(a) compile(b)
      append(ca, append(cb, [OpAdd{}]))
    case Mul{a, b}:
      ca cb = compile(a) compile(b)
      append(ca, append(cb, [OpMul{}]))

# Underflow is totalized to Nil; compiled expressions never underflow.
# Operand order preserves the order of the source expression.
def step(i: Instr, x: Nat, s: +List<Nat>) -> +List<Nat>:
  match i s:
    case PushConst{v} t:
      Con{v, t}
    case PushVar{} t:
      Con{x, t}
    case OpAdd{} Con{right, Con{left, t}}:
      Con{Nat.add(left, right), t}
    case OpMul{} Con{right, Con{left, t}}:
      Con{Nat.mul(left, right), t}
    case OpAdd{} _:
      Nil{}
    case OpMul{} _:
      Nil{}

def exec_vm(code: +List<Instr>, +x: Nat, s: +List<Nat>) -> +List<Nat>:
  match code:
    case Nil{}:
      s
    case Con{i, rest}:
      exec_vm(rest, x, step(i, x, s))

def nodes(e: Expr) -> Nat:
  match e:
    case Const{_}:
      1n
    case Var{}:
      1n
    case Add{a, b}:
      1n+Nat.add(nodes(a), nodes(b))
    case Mul{a, b}:
      1n+Nat.add(nodes(a), nodes(b))
