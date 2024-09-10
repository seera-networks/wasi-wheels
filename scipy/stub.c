#include <stdlib.h>

void __cxa_allocate_exception() {
    abort();
}

void __cxa_throw() {
    abort();
}

int setjmp() {
    return 0;
}

void longjmp() {
    abort();
}

void _ZTHN17HighsTaskExecutor25threadLocalWorkerDequePtrE() {
    return;
}