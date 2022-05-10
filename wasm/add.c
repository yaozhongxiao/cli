
extern int sub(int a, int b);

int add(int a, int b) { return sub(a,b) + b; }

int main() { return add(1, 2); }

