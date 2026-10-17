import Base

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
