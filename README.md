![GitHub code size in bytes](https://img.shields.io/badge/LOC-99-brightgreen.svg)
# har.test
## API integration test runner and reporter using .har files

### How it works
```
./main.sh http://your.host
finds queries in all .har files in the folder
which have http://your.host in their target
builds queries and runs them                 -> saves responses -> compares -> reports -> logs failures

*.har         -> ./queries.sh                   ./responses        ./expected             ./log
...other.host...
...your.host...  curl -XPOST ...1 -d '{..1}'    {"a":1}            {"a":1}     Pass       Diff at line: 2. query: curl '...'
...your.host...  curl -XPOST ...2 -d '{..2}'    {"b":1}            {"b":2}     Fail       Response: { "userId": 1, ... }
...your.host...                                                                           Expected: { "userId": 2, ... }
...other.host...

compare does sanitization both on ./responses and ./expected using ./sanitize
```

### Intro
1. Grab your favorite web browser save all the network traffic you have recorded in you current tab; and copy your [.har](https://en.wikipedia.org/wiki/.har) file to this folder.
2. Run `./main.sh https://yourdomain.here`.
3. Har.test will filter all the requests made to your domain and replays them in the original order.
4. On the first run har.test will generate the `./expected` file based on your .har files; `./expected` will be your snapshot but you can edit it; is just simply text.
5. Discover the [jq tutorial](https://stedolan.github.io/jq/tutorial/) and the local `./sanitize` file here in the repo, which serves not only as an example but har.test actively uses it.
6. Discover the source code [main.sh](https://github.com/slve/har.test/blob/master/main.sh).
7. Tip: Don't forget to check out [json.test](https://github.com/slve/json.test) a similar tool for when you don't have .har files.
8. Give it a star and fork it, create your private clone, add your `.gitignore` to your needs and link it into your [CI](https://en.wikipedia.org/wiki/Continuous_integration) flow.

### Output
* The output will go to stdout so you could pipe it into a file for example, but there is a more detailed `./log` file. Also, the exit code can be 0 if all test passed, or 1 if any of the tests have failed, so is compatible with the standard [CI](https://en.wikipedia.org/wiki/Continuous_integration) tools.

### Goal
* The original goal was to create an easy setup [integration test](https://en.wikipedia.org/wiki/Integration_testing) runner and reporter using [.har](https://en.wikipedia.org/wiki/.har) file.

### Advantages
* Small set of dependencies: some common [GNU](https://www.gnu.org/) commands plus [jq](https://stedolan.github.io/jq/),
* ~100 lines of shell script - lightweight codebase,
* and so its easy to fork and hack it to your own needs.

### Dependencies
* jq - [stedolan.github.io](https://stedolan.github.io/jq/)
* curl - you probably have one already
* diff - same here
* awk - again

### Limitations that might change in the future
* har.test is running each .har file in alphabetical order syncronously
* also, each test cases are processed syncronously
* there is no HTTP response code checking
* there is no option for any kind of timing

### References and similar or other .har tools
* https://github.com/mrichman/hargo
* http://andydude.github.io/harcurl/
* https://har.tech/

### Similar tool without .har
* https://github.com/slve/json.test
