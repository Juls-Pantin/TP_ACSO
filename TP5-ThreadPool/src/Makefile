# Compiler settings
CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread -g

# Common source files
SRC_COMMON = thread-pool.cc Semaphore.cc

# Executables
EXECUTABLES = main tptest tpcustomtest

all: main tptest tpcustomtest

main: main.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o main main.cc $(SRC_COMMON)

tptest: tptest.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o tptest tptest.cc $(SRC_COMMON)

tpcustomtest: tpcustomtest.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o tpcustomtest tpcustomtest.cc $(SRC_COMMON)

clean:
	rm -f $(EXECUTABLES)

.PHONY: all clean main tptest tpcustomtest
