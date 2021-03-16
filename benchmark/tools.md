# Benchmark Regression Checking Tools

## bench_check.py

The `bench_check.py` can be used to judge the compare result with threshold.

### Dependencies

The utility relies on the tools in [tools/compare.py](tools/tools.md)

### Steps of Checking

1. Use the compare.py tool to generate the benchmark compare result.
There are three modes of compare operations, see [tools/compare.py](tools/tools.md) for details.

The program is invoked like:

``` bash
$ compare.py filters <benchmark> <filter_baseline> <filter_contender> [benchmark options]...
```
Where `<benchmark>` either specify a benchmark executable file, or a JSON output file. The type of the input file is automatically detected. If a benchmark executable is specified then the benchmark is run to obtain the results. Otherwise the results are simply loaded from the output file.

Where `<filter_baseline>` and `<filter_contender>` are the same regex filters that you would pass to the `[--benchmark_filter=<regex>]` parameter of the benchmark binary.

`[benchmark options]` will be passed to the benchmarks invocations. They can be anything that binary accepts, be it either normal `--benchmark_*` parameters, or some custom parameters your binary takes.

Example output:
```
$../scripts/tools/compare.py -d compare.json filters ./benchmark/bm_test "BM_.*Intrinsic" "BM_.*NativeSimd"
RUNNING: ./benchmark/bm_test --benchmark_filter=BM_.*Intrinsic --benchmark_out=/tmp/tmp5yu0U_
2021-03-04T14:11:17+08:00
Running ./benchmark/bm_test
Run on (96 X 3100 MHz CPU s)
CPU Caches:
  L1 Data 32 KiB (x48)
  L1 Instruction 32 KiB (x48)
  L2 Unified 1024 KiB (x48)
  L3 Unified 33792 KiB (x2)
Load Average: 0.33, 1.24, 4.89
***WARNING*** CPU scaling is enabled, the benchmark real time measurements may be noisy and will incur extra overhead.
------------------------------------------------------------------------
Benchmark                              Time             CPU   Iterations
------------------------------------------------------------------------
BM_AddIntrinsic<int64_t>/8192       2801 ns         2801 ns       239880
BM_AddIntrinsic<int64_t>/8000       2723 ns         2723 ns       253666
BM_AddIntrinsic<int64_t>/8500       2932 ns         2932 ns       239241
BM_AddIntrinsic<int64_t>/4096       1405 ns         1405 ns       498371
BM_AddIntrinsic<int64_t>/2048        707 ns          707 ns       992509
BM_AndIntrinsic<bool>/8192           220 ns          220 ns      3182819
BM_AndIntrinsic<bool>/8000           213 ns          213 ns      3272252
BM_AndIntrinsic<bool>/8500           215 ns          215 ns      3261440
RUNNING: ./benchmark/bm_test --benchmark_filter=BM_.*NativeSimd --benchmark_out=/tmp/tmpmR2unA
2021-03-04T14:11:25+08:00
Running ./benchmark/bm_test
Run on (96 X 3100 MHz CPU s)
CPU Caches:
  L1 Data 32 KiB (x48)
  L1 Instruction 32 KiB (x48)
  L2 Unified 1024 KiB (x48)
  L3 Unified 33792 KiB (x2)
Load Average: 0.58, 1.27, 4.86
***WARNING*** CPU scaling is enabled, the benchmark real time measurements may be noisy and will incur extra overhead.
--------------------------------------------------------------------------
Benchmark                                Time             CPU   Iterations
--------------------------------------------------------------------------
BM_AddNativeSimd<int64_t>/8192        2828 ns         2828 ns       246857
BM_AddNativeSimd<int64_t>/8000        2766 ns         2766 ns       253140
BM_AddNativeSimd<int64_t>/8500        2825 ns         2825 ns       249568
BM_AddNativeSimd<int64_t>/4096        1345 ns         1345 ns       512056
BM_AddNativeSimd<int64_t>/2048         672 ns          672 ns      1038851
BM_AndNativeSimd<bool>/8192            249 ns          249 ns      2811994
BM_AndNativeSimdMask<bool>/8192        251 ns          251 ns      2790189
BM_AndNativeSimd<bool>/8000            242 ns          242 ns      2884014
BM_AndNativeSimdMask<bool>/8000        244 ns          244 ns      2867521
BM_AndNativeSimd<bool>/8500            187 ns          187 ns      3752188
BM_AndNativeSimdMask<bool>/8500        237 ns          237 ns      2954939
Comparing BM_.*Intrinsic to BM_.*NativeSimd (from ./benchmark/bm_test)
Benchmark                                                            Time             CPU      Time Old      Time New       CPU Old       CPU New
-------------------------------------------------------------------------------------------------------------------------------------------------
[BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8192                +0.0095         +0.0095          2801          2828          2801          2828
[BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8000                +0.0157         +0.0157          2723          2766          2723          2766
[BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8500                -0.0366         -0.0366          2932          2825          2932          2825
[BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/4096                -0.0423         -0.0423          1405          1345          1405          1345
[BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/2048                -0.0493         -0.0493           707           672           707           672
[BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8192                   +0.1303         +0.1303           220           249           220           249
[BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8000                   +0.1352         +0.1352           213           242           213           242
[BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8500                   -0.1313         -0.1313           215           187           215           187
```

As you can see, it applies filter to the benchmarks, both when running the benchmark, and before doing the diff. And to make the diff work, the matches are replaced with some common string. Thus, you can compare two different benchmark families within one benchmark binary.
As you can note, the values in `Time` and `CPU` columns are calculated as `(new - old) / |old|`.

2. Use the bench_check.py tool to judge and report the compare result with threshold value.

The program is invoked like:

``` bash
$ bench_check.py <compare_result_json> <threshold>
```

Where `<compare_result_json>` a JSON output file generated by compare.py.

Where `<threshold>` is the maximum acceptable performance difference.

Example output:
```
$../scripts/bench_check.py compare.json 0.05
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8192  diff:  0.00950481129695
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8000  diff:  0.0157295092779
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/8500  diff:  -0.0365515122712
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/4096  diff:  -0.0422591453596
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<int64_t>/2048  diff:  -0.0493338871372
fail:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8192  diff:  0.130296740511
fail:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8000  diff:  0.135165238008
pass:  [BM_.*Intrinsic vs. BM_.*NativeSimd]<bool>/8500  diff:  -0.131280039062
pass:  6    fail:  2   total:  8   threshold: 0.05
```
This is a report and the judege result with the given threshold value where 0.05 means the 5%