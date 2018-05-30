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

#ifndef MY_DEF
#define MY_DEF

#include <ap_int.h>
#include <hls_stream.h>

using namespace std;

#define HW_COSIM

#define WINDOW_WIDTH 5 // should be ought
#define WINDOW_HEIGHT 5 // should be same as width
#define VEC_SIZE (WINDOW_WIDTH*WINDOW_HEIGHT)
#define SEC_WIDTH (WINDOW_WIDTH-2)
#define SEC_HEIGHT (WINDOW_HEIGHT-2)
#define SEC_SIZE (SEC_WIDTH*SEC_HEIGHT)


typedef ap_uint<8> myint_8;
typedef ap_uint<16> myint_16;
typedef ap_uint<2> uint_2;
typedef ap_int<30> int_17;
typedef ap_uint<16> uint_16;
typedef ap_uint<21> uint_21;

typedef hls::stream<myint_8> stream_8;
typedef hls::stream<myint_16> stream_16;
// index for all 4 sections of windows
static int sec_index_array_0[SEC_SIZE] = {0 ,1 ,2,5,6,7,10,11,12};

static int sec_index_array_1[SEC_SIZE]  = {2 ,3 ,4,7,8 ,9,12,13,14};

static int sec_index_array_2[SEC_SIZE] = {10 ,11 ,12,15 ,16 ,17,20 ,21 ,22};

static int sec_index_array_3[SEC_SIZE] = {12 ,13 ,14,17 ,18 ,19,22 ,23 ,24};

#endif
