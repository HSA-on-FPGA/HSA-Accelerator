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


#include <iostream>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>

int main (int argc, char *argv[]) {
	if (argc != 5) {
		std::cout << "Usage:" << std::endl;
		std::cout << "./ppm2mem width height ppmInputFile memOutputFile" << std::endl;
		exit(EXIT_FAILURE);
	}
	unsigned int PIC_WIDTH = atoi(argv[1]);
	unsigned int PIC_HEIGHT = atoi(argv[2]);
	int width;
	int height;
	int maxVal;
	std::ifstream inputFile (argv[3]);
	std::ofstream outputFile;
	std::string s;
	if (inputFile.is_open()) {
		inputFile >> s;
		if (s != "P6") {
			std::cout << "wrong input format!" << std::endl;
		}
	}
	inputFile >> s;
	if (s== "#") {
		// catch commant line;
		getline(inputFile,s);
	}
	inputFile >> s;
	std::istringstream(s) >> width;
	inputFile >> s;
	std::istringstream(s) >> height;
	inputFile >> s;
	std::istringstream(s) >> maxVal;
	if (width != PIC_WIDTH || height != PIC_HEIGHT){
		inputFile.close();
		std::cout << "picture attributes differ from given parameters" << std::endl;
		exit(EXIT_FAILURE);
	}
	
	outputFile.open(argv[4]);
	int r,g,b;

	r = inputFile.get(); // for ignoring \n or white space
	
	for (int i = 0; i < PIC_WIDTH*PIC_HEIGHT;i++){
		r = inputFile.get();
		g = inputFile.get();
		b = inputFile.get();
   if(r<16)
   {   
     outputFile << std::hex << 0;
   }   
   outputFile << std::hex << r;
   if(g<16)
   {   
     outputFile << std::hex << 0;
   }   
   outputFile << std::hex << g;
   if(b<16)
   {   
     outputFile << std::hex << 0;
   }   
   outputFile << std::hex << b;
   outputFile << "\n";
	}
	outputFile.close();

}
