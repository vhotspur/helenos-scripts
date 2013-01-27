#include <stdio.h>
#include <float.h>

#define GROUP(name) \
	printf("\n/* %s */\n", name);

#define PRINT_(name, value, specifier) \
	printf("#define %s %.200Lg%s\n", name, (long double) value, specifier)

#define PRINT(constant) \
	PRINT_(#constant, constant, "")

#define PRINTL(constant) \
	PRINT_(#constant, constant, "L")


int main(int argc, char *argv[]) {
	printf("/* Automatically generated file. Do not edit.*/\n\n");
	printf("#ifndef _FLOAT_H_INCLUDE_GUARD\n");
	printf("#define _FLOAT_H_INCLUDE_GUARD\n");
	printf("\n\n\n");

	GROUP("float limits")
	PRINT(FLT_MIN);
	PRINT(FLT_MAX);

	GROUP("double limits")
	PRINT(DBL_MIN);
	PRINT(DBL_MAX);

	GROUP("long double limits")
	PRINTL(LDBL_MIN);
	PRINTL(LDBL_MAX);

	GROUP("epsilons")
	PRINT(FLT_EPSILON);
	PRINT(DBL_EPSILON);
	PRINTL(LDBL_EPSILON);

	GROUP("float radix")
	PRINT(FLT_RADIX);

	GROUP("mantisa")
	PRINT(FLT_MANT_DIG);
	PRINT(DBL_MANT_DIG);
	PRINT(LDBL_MANT_DIG);

	GROUP("exponents")
	PRINT(DBL_MIN_EXP);
	PRINT(DBL_MAX_EXP);

	printf("\n\n\n");
	printf("#endif\n");
	return 0;
}
