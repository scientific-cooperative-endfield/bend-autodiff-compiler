import Base
import ./compiler.bend as C

# depth counts Add levels; leaves are x*x + 0 (two extra levels).
def make(+depth: Nat) -> C.Expr:
  match depth:
    case 0n:
      C.Add{C.Mul{C.Var{}, C.Var{}}, C.Const{0n}}
    case 1n+p:
      a b = make(p) make(p)
      C.Add{a, b}

def bench(+depth: Nat) -> IO(Unit):
  do IO<Unit>:
    threads : U32 <- IO.thread_count()
    +e : C.Expr = make(depth)
    count : Nat = C.nodes(e)
    t0 : Nat <- IO.now()
    +d : C.Expr = C.diff(e)
    +t1 : Nat <- IO.now()
    +o : C.Expr = C.optimize(d)
    t2 : Nat <- IO.now()
    IO.print("{\"depth\":" ++ Nat.show(depth) ++ ",\"ast_nodes\":" ++ Nat.show(count) ++ ",\"diff_nodes\":" ++ Nat.show(C.nodes(d)) ++ ",\"optimized_nodes\":" ++ Nat.show(C.nodes(o)) ++ ",\"diff_ms\":" ++ Nat.show(Nat.sub(t1, t0)) ++ ",\"optimize_ms\":" ++ Nat.show(Nat.sub(t2, t1)) ++ ",\"threads\":" ++ U32.show(threads) ++ "}")

def run(d: Maybe<&2, Nat>) -> IO(Unit):
  match d:
    case Some{n}:
      bench(n)
    case None{}:
      IO.die(Unit, 2, "invalid depth")

def args(a: List<String>) -> IO(Unit):
  match a:
    case Con{_, Con{n, Nil{}}}:
      run(Nat.read(n))
    case _:
      IO.die(Unit, 2, "usage: bench DEPTH")

def main() -> IO(Unit):
  do IO<Unit>:
    a : List<String> <- IO.args()
    args(a)
