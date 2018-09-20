// TODO: Implement populate_array
/*
 * Convert a 9 digit int to a 9 element int array.
 */
int populate_array(int sin, int *sin_array) {
	int n = 0;
	int temp = sin;
	while (sin){
		sin /= 10;
		n++;
	}

	if (n != 9){
		return 1;
	}

	else{
		int i;
		for (i = 0; i < 9; i++){
			sin_array[8 - i] = temp % 10;
			temp = temp / 10;
		}
	}
    return 0;
}

// TODO: Implement check_sin
/* 
 * Return 0 (true) iff the given sin_array is a valid SIN.
 */
int check_sin(int *sin_array) {
	int sum = 0;
	int compare[9] = {1, 2, 1, 2, 1, 2, 1, 2, 1};

	if (sin_array[0] == 0){
		return 1;
	}
	for (int i = 0; i < 9; i++){
		if (sin_array[i] * compare[i] > 9){
			int product = sin_array[i] * compare[i];
			int first = product % 10;
			int second = product / 10;
			sin_array[i] = first + second;
		}

		else{
			sin_array[i] = sin_array[i] * compare[i];
		}
	}

	for (int j = 0; j < 9; j++){
		sum += sin_array[j];
	}

	if (sum % 10 == 0){
		return 0;
	}

	else{
		return 1;
	}
}
