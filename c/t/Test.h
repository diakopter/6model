/* Test.h */

/* Lightweight TAP (Test Anything Protocol) emitter in C macros. */

/* SYNOPSIS
#include "../Test.h"

int
main(int argc, char * argv[])
{
    plan(1);
    ok(1==1, "1 is equal to 1");
    is_ii(2 + 2, 4, "2 plus 2 equals 4");
    return 0;
}
*/

/* DEFINITIONS
plan(i);
diag(s);
is_ii(i1, i2, "integers match");
is_ss(s1, s2, "strings match");
ok(b, "any boolean expression");
TODO: is_pp(p1, p2, "pointers match");
TODO: done_testing();
*/


#include <stdio.h>  /* printf */

int _test_number=0; /* yes, namespace pollution. patches welcome ;-) */

#define plan(count)  printf("1..%d\n", count)

#define \
ok(flag,desc) \
    printf("%sok %d - %s\n", \
        flag?"":"not ",++_test_number,desc)

#define \
is_ii(got,expected,desc) \
    printf("%sok %d - %s\n", \
        got==expected?"":"not ",++_test_number,desc); \
    if(got!=expected) \
        printf("# got      : %d\n# expected : %d\n", got, expected)

#define \
is_ss(got,expected,desc) \
    printf("%sok %d - %s\n", \
        strcmp(got,expected)?"not ":"",++_test_number,desc)

#define \
isnt_pp(got,expected,desc) \
    printf("%sok %d - %s\n", \
        (got!=expected)?"":"not ", ++_test_number, desc)

#define \
diag(message) \
    printf("# %s\n", message)

/* end of Test.h */
