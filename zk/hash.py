# python calculate the hash function used in ./verify.code
Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583L # prime
P = 21888242871839275222246405745257275088548364400416034343698204186575808495617L # prime
def hash(x):
  x = x % P
  a = x ** 283L
  b = x ** 12L
  c = x ** 7L
  d = x ** 5L
  return (a + b + c + d + 1L) % P


if __name__ == '__main__':
  import sys
  if len(sys.argv) != 4:
    print "usage: hash <N> <I> <h>"
  N = int(sys.argv[1])
  I = long(sys.argv[2])
  h = long(sys.argv[3])
  HI = hash(h + I)
  H = h
  for i in range(N):
    H = hash(H)
  print "./target/release/zokrates compute-witness -a",H,N,HI,I
  print "# when asked to enter 'h', enter:"
  print h