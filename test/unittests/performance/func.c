typedef struct { long limbs[8]; } uint;
volatile uint bottom[2];

void f1A(uint top) {
	bottom[0] = top;
}
void f1B(uint top) {
	bottom[0] = top;
}
void f1(uint top) {
	f1A(top);
	f1B(top);
}

void f2B(uint top) {
	bottom[1] = top;
}
void f2A(uint top) {
	bottom[1] = top;
}
void f2(uint top) {
	f2A(top);
	f2B(top);
}

void f(uint top1, uint top2) {
	f1(top1);
	f2(top2);
}

int main (int argc, char** argv) {
	for (int top = 0; top < 1048576 - argc; ++top) {
		uint x = {0}, y = {0};
		x.limbs[0] = (long)top;
		y.limbs[0] = (long)top;
		f(x, y);
	}
	return !(bottom[0].limbs[0] == (long)(1048575 - argc) && bottom[1].limbs[0] == (long)(1048575 - argc));
}
