#!/usr/bin/env python

import json
import sys
import traceback

class BenchmarkRecords:
  def __init__(self, file):
      self.load_json(file)

  def load_json(self, file):
      fd = open(file, 'r')
      try:
          self.context = fd.read()
      except Exception as ex:
          traceback.print_exc()
      finally:
          fd.close()
      try:
        self.bench_list = json.loads(self.context, encoding="UTF-8")
      except Exception as ex:
        traceback.print_exc()

  def get_status(self):
      return self.fail == 0

  def verify(self, threshold):
      self.suc = 0
      self.fail = 0
      self.threshold = threshold
      for bench in self.bench_list:
          diff = bench['measurements'][0]['time']
          if(float(diff) <= float(threshold)):
            print("pass: ",bench['name'], " diff: ", bench['measurements'][0]['time'])
            self.suc += 1
          else:
            print("fail: ", bench['name'], " diff: ", bench['measurements'][0]['time'])
            self.fail += 1
      print("pass: ",  self.suc, "   fail: ", self.fail ,"  total: ", self.fail + self.suc, "  threshold:", threshold)
      return self.fail == 0

if __name__ == '__main__':
    bench_result_file = "bench_compare.json"
    threshold_value = 0.05
    if(len(sys.argv) > 1):
        bench_result_file = sys.argv[1]
    if(len(sys.argv) > 2):
	    threshold_value = sys.argv[2]
    records = BenchmarkRecords(bench_result_file)
    status = records.verify(threshold_value);
    sys.exit(not status)