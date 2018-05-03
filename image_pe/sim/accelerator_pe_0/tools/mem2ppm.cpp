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

int main (int argc, char *argv[]) { 
	if (argc != 5) {
		std::cout << "Usage:" << std::endl;
		std::cout << "./mem2ppm width height memInputFile ppmOutputFile" << std::endl;
		exit(EXIT_FAILURE);
	}
	int width = atoi(argv[1]);
	int height = atoi(argv[2]);
	std::ifstream inputFile (argv[3]);
	std::ofstream outputFile; 
	std::string buf;
	std::string valueString;
	unsigned whitespace;
	int value; 
	char red;
	char green;
	char blue;
	if (inputFile.is_open()) {
		// ignore header
		getline(inputFile, buf);
		getline(inputFile, buf);
		getline(inputFile, buf);
		outputFile.open(argv[4]);
		outputFile << "P6 " << width << " " << height << " " << "255\n";
		for (int i = 0; i < width * height; i++) {
			getline(inputFile, buf);
			whitespace = buf.find_last_of(" ");
			valueString = buf.substr(whitespace + 1);
			value = (int) strtol(valueString.c_str(), NULL, 16);
			red = (char) ((value & 0xFF0000)>> 16);
			green = (char)((value & 0xFF00)>> 8);
			blue = (char)(value & 0xFF);
			outputFile << red;
			outputFile << green;
			outputFile << blue;
		}
		outputFile.close();
	}
}
