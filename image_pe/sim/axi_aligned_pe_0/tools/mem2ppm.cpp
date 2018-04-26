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
		// only for testing with hand.mem to skip <MATRIX> entries 
//		for (int i = 0; i < 16; i++) {
//			getline(inputFile, buf);
//		}
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
