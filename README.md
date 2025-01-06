## File structure
- The original unchanged source code can be found in folder cuda/gaussian
- Our various modifications can be found in folder impGaussian
- Example inputs can be found under data/gaussian
## Prerequisites
In the file common/make.config modify the field CUDA_DIR to your CUDA toolkit installation path.
## How to compile and run
### Original source code
- Compile with: cd cuda/gaussian && make && cd ../..
- Example execution: ./cuda/gaussian/gaussian -f  data/gaussian/matrix4096.txt -q
- To get all the different launch options run the program without any arguments
### Modified code
- In impGaussian/Makefile modify the SRC field to the file you want to execute.
    - gaussianFinal_Backsub.cu includes kernel optimizations + new Backsub function (preselected)
    - gaussianFinal.cu includes only kernel optimizations
    - cuSolver.cu for solution using cuSolver
- Compile with cd impGaussian && make && cd ..
- Example execution: impGaussian/gaussian -f  data/gaussian/matrix4096.txt -q
- To get all the different launch options run the program without any arguments (same as original source code)

Note: cuSolver.cu is a special case only has one launch option ./gaussian [inputFile] with no flags

### Comparison and validation
- In impGaussian/Makefile modify the SRC field to the program's result you want to compare with the original
- Run: ./compileAndCompareOnlyRes.sh [sizeOfInput]
    - Replace [sizeOfInput] with the matrix size you want to use to compare with, supported sizes 4,16,1024,4096
- If both programs give the same result the only difference shown should be their execution times

Note: cuSolver.cu is special case, comparison is done to the correct answer when executing the program normaly. Largest error/difference is given. Run with: impGaussian/gaussian data/gaussian/matrix4096.txt after compiling either with makefile or manually. 
