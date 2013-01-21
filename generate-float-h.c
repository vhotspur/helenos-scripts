#include <stdio.h>
#include <float.h>

#define PRINT(constant) \
	printf("#define %s (%Lg)\n", #constant, (long double) constant)


int main(int argc, char *argv[]) {
	printf("/* Automatically generated file. Do not edit.*/\n\n");
	printf("#ifndef _FLOAT_H_INCLUDE_GUARD\n");
	printf("#define _FLOAT_H_INCLUDE_GUARD\n");
	printf("\n\n\n");
	PRINT(DBL_MIN);
	PRINT(DBL_MAX);
	PRINT(DBL_EPSILON);
	PRINT(LDBL_MIN);
	PRINT(LDBL_MAX);
	PRINT(LDBL_EPSILON);
	PRINT(FLT_MIN);
	PRINT(FLT_MAX);
	PRINT(FLT_EPSILON);
	PRINT(FLT_RADIX);
	PRINT(LDBL_MANT_DIG);
	PRINT(DBL_MANT_DIG);
	PRINT(FLT_MANT_DIG);
	printf("\n\n\n");
	printf("#endif\n");
	return 0;
}
