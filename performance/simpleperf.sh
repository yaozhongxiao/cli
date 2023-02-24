#!/bin/bash

pkgName="com.ss.android.perf.test.app"

SIMPLEPERF_HOME="/Users/zhongxiao.yzx/Library/Android/sdk/ndk/21.1.6352462/simpleperf"
if [ -f "perf.data"  ];then
  rm  -rf  perf.data
fi
adb shell chmod a+x /data/local/tmp/simpleperf
adb shell /data/local/tmp/simpleperf record -o /data/local/tmp/perf.data -g --app $pkgName --duration 10 -f 800
adb pull /data/local/tmp/perf.data  .
python  ${SIMPLEPERF_HOME}/report_html.py -i  perf.data -o   report.html --binary_filter binary_cache
