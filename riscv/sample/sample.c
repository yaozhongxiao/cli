volatile int result = 3;

int sum() {
  int arg = 10;
  if (arg <= 2) {
    return arg;
  }
  int isum = 0;
  for(int i = 0; i < arg; ++i) {
    isum += i;
  }
  return isum;
}

int main() {
  int ret = 10;
  ret += sum();
  result = ret;
  return ret;
}
