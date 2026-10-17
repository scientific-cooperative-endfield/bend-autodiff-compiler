import Base
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
