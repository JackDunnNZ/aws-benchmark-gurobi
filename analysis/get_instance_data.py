# Requires demjson for decoding non-strict JSON

import demjson
import json
import os
import urllib2


AWS_PRICE_JS_URL = "http://a0.awsstatic.com/pricing/1/ec2/linux-od.min.js"
BEGIN_STR = "callback("


# Get data from Amazon
res = urllib2.urlopen(AWS_PRICE_JS_URL)
res_data = res.read()

# Filter out non-json parts of response and read in
start_index = res_data.find(BEGIN_STR) + len(BEGIN_STR)
data = demjson.decode(res_data[start_index:-2])

# Dump to file
with open(os.path.join(os.path.dirname(__file__),
          "instance-data.json"), "w") as f:
  json.dump(data, f, indent=2)
