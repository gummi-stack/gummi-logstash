logstash
========

```
$ java -jar logstash-1.3.3-flatjar.jar agent --pluginpath . -f config.cfg
Error: Could not find any plugins in "."
I tried to find files matching the following, but found none:
./logstash/{inputs,filters,outputs}/*.rb
```

... It will be necessary to compile
