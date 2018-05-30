//
// Copyright 2017 Konrad Haeublein
//
// konrad.haeublein@fau.de
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#include "kuwahara.h"
#include <iostream>
#include <hls_stream.h>


myint_16 kuwahara(myint_16 din0[VEC_SIZE]) 
{

myint_16 dout0;
int sec_value_array[4][SEC_SIZE];
int sec_diff_sqr_array[4][SEC_SIZE];
uint_21 sec_diff_accu[4];
uint_21 sec_deviation[4];
myint_8 sec_mean[4];
uint_16 sec_accu[4];
int min_index ;
int min_value;

#pragma HLS PIPELINE II=1
#pragma HLS ARRAY_PARTITION variable=din0 complete dim=0

read_in_array: for(int i=0; i < SEC_SIZE;i++) {
	sec_value_array[0][i] = din0[sec_index_array_0[i]];
	sec_value_array[1][i] = din0[sec_index_array_1[i]];
	sec_value_array[2][i] = din0[sec_index_array_2[i]];
	sec_value_array[3][i] = din0[sec_index_array_3[i]];
}


sec_mean: for(int i=0; i < 4;i++){
	sec_accu[i]=0;
  addup_mean: for(int j=0; j < SEC_SIZE;j++) {
     sec_accu[i] += sec_value_array[i][j];
  }
     sec_mean[i] = sec_accu[i]/SEC_SIZE;
}


// calculate standard deviation for each section

sec_dev: for(int i=0; i < 4;i++){
		sec_diff_accu[i] = 0; 
  diff_dev: for(int j=0; j < SEC_SIZE;j++) {
		sec_diff_sqr_array[i][j] = (sec_value_array[i][j]-sec_mean[i])*(sec_value_array[i][j]-sec_mean[i]);
		sec_diff_accu[i] += sec_diff_sqr_array[i][j]; // accumulate value
	}
	sec_deviation[i] = sec_diff_accu[i]/sec_mean[i];
}


// determine minimum value

min_index = 0;
min_value = sec_deviation[0]; // set first deviation as start value
sec_min: for(int i=1; i< 4;i++){
	if(sec_deviation[i] < min_value){
		min_value = sec_deviation[i];
		min_index = i;
	}
}

dout0 = sec_mean[min_index];
return dout0;

}    
