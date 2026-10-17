import Base
import ./compiler.bend as C

def dispatch(isx: Bool, isa: Bool, ism: Bool, isd: Bool, c: Char, s: +List<C.Expr>) -> Maybe<&2, +List<C.Expr>>:
  match isx isa ism isd s:
    case True{} _ _ _ t:
      Some{Con{C.Var{}, t}}
    case _ True{} _ _ Con{r, Con{l, t}}:
      Some{Con{C.Add{l, r}, t}}
    case _ _ True{} _ Con{r, Con{l, t}}:
      Some{Con{C.Mul{l, r}, t}}
    case _ _ _ True{} t:
      Some{Con{C.Const{U32.to_nat(U32.sub(Char.to_u32(c), 48))}, t}}
    case _ _ _ _ _:
      None{}

def token(+c: Char, s: +List<C.Expr>) -> Maybe<&2, +List<C.Expr>>:
  dispatch(Char.is_eq(c, 'x'), Char.is_eq(c, '+'), Char.is_eq(c, '*'), Char.is_digit(c), c, s)

def parse_go(text: String, s: +List<C.Expr>) -> Maybe<&2, +List<C.Expr>>:
  match text:
    case SNil{}:
      Some{s}
    case SCon{c, t}:
      do Maybe<&2, +List<C.Expr>>:
        next : +List<C.Expr> <- token(c, s)
        parse_go(t, next)

def finish(s: +List<C.Expr>) -> Maybe<&2, C.Expr>:
  match s:
    case Con{e, Nil{}}:
      Some{e}
    case _:
      None{}

def parse(text: String) -> Maybe<&2, C.Expr>:
  do Maybe<&2, C.Expr>:
    stack : +List<C.Expr> <- parse_go(text, Nil{})
    finish(stack)

def tree(e: C.Expr) -> String:
  match e:
    case C.Const{v}:
      "{\"c\":" ++ Nat.show(v) ++ "}"
    case C.Var{}:
      "{\"x\":true}"
    case C.Add{a, b}:
      "{\"a\":[" ++ tree(a) ++ "," ++ tree(b) ++ "]}"
    case C.Mul{a, b}:
      "{\"m\":[" ++ tree(a) ++ "," ++ tree(b) ++ "]}"

def stack_value(s: +List<Nat>) -> String:
  match s:
    case Con{v, Nil{}}:
      Nat.show(v)
    case _:
      "null"

def run(e: Maybe<&2, C.Expr>, n: Maybe<&2, Nat>) -> IO(Unit):
  match e n:
    case Some{+expr} Some{+x}:
      +d = C.diff(expr)
      +o = C.optimize(expr)
      +od = C.optimize(d)
      IO.print("{\"value\":" ++ Nat.show(C.eval(expr, x)) ++ ",\"gradient\":" ++ Nat.show(C.eval(od, x)) ++ ",\"vm_value\":" ++ stack_value(C.exec_vm(C.compile(o), x, Nil{})) ++ ",\"vm_gradient\":" ++ stack_value(C.exec_vm(C.compile(od), x, Nil{})) ++ ",\"derivative\":" ++ tree(od) ++ ",\"optimized\":" ++ tree(o) ++ "}")
    case _ _:
      IO.die(Unit, 2, "invalid postfix formula or natural-number input")

def args(a: List<String>) -> IO(Unit):
  match a:
    case Con{_, Con{text, Con{n, Nil{}}}}:
      run(parse(text), Nat.read(n))
    case _:
      IO.die(Unit, 2, "usage: oracle POSTFIX NAT")

def main() -> IO(Unit):
  do IO<Unit>:
    a : List<String> <- IO.args()
    args(a)
