# compilador
CXX = g++
CXXFLAGS = -std=c++11 -Wall -pthread -g

# archivos src comunes
SRC_COMMON = thread-pool.cc Semaphore.cc

# executables
EXECUTABLES = main tptest tpcustomtest

all: main tptest tpcustomtest

main: main.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o main main.cc $(SRC_COMMON)

tptest: tptest.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o tptest tptest.cc $(SRC_COMMON)

tpcustomtest: tpcustomtest.cc $(SRC_COMMON)
	$(CXX) $(CXXFLAGS) -o tpcustomtest tpcustomtest.cc $(SRC_COMMON)

custom:
	$(CXX) $(CXXFLAGS) -o threadpool thread-pool.cc Semaphore.cc test_custom.cc

clean:
	rm -f $(EXECUTABLES)

.PHONY: all clean main tptest tpcustomtest
