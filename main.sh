HOST=${1:-http://api.localhost}
echo $HOST

# sanitize removes the give paths from responses and expected to ignore changes we don't care
# shellcheck disable=SC2037
sanitize(){
  IFS= read out
  while read -r jqcmd
  do
    out=$(echo $out | jq $jqcmd 2>/dev/null)
  done < ./sanitize
  echo $out
}

# ellipsis truncates long string and adds '...'
ellipsis(){
  awk -v len=120 '{
    if (length($0) > len) print substr($0, 1, len-3) "...";
    else print;
  }'
}

# log pipes the input to ./log file and adds an empty line after
log(){ tee -a log; echo >> ./log; }


# actual run
# cleanup + init
rm ./queries.sh ./responses ./log 2>/dev/null
touch ./queries.sh && chmod +x ./queries.sh

# common jq snippet to filter relevant entries from your .har files
filterRelevant='.log.entries[]
   | .request as $r
   | select(
       ($r.url | test("'"$HOST"'"))
       and ($r.method != "OPTIONS")
     )'

# generate ./expected if there is no one yet
if [ ! -r ./expected ]; then
  echo "Could not find ./expected file just generated one based on your .har files"
  for har in *.har; do
   jq -r "$filterRelevant"'
   | .response.content.text
   ' $har >> ./expected;
  done
  sed -i '/^$/d' ./expected
fi

# generate ./queries.sh
for har in *.har; do
  jq -r "$filterRelevant"'
    | $r.postData.text as $data
    | $r.headers
    | reduce .[] as $h (
        "curl -X" + $r.method
        + " \"" + $r.url + "\""
        + if $data then (" -d" + ($data? | @json)) else "" end;
        . + " -H \"" + $h.name + ":" + $h.value + "\""
      )
  ' $har >> ./queries.sh
done

# run the queries and generate ./responses
./queries.sh 2>/dev/null > ./responses

# go through each response and compare with the expected
i=0
passed=0
failed=0
exitcode=0
while IFS="$(printf '\t')" read -r resp exp query
do
  i=$[i + 1]
  respSan=$(echo $resp | sanitize)
  expSan=$(echo $exp | sanitize)
  d=$(diff <(echo "$respSan" ) <(echo "$expSan"))
  if [[ ! -z $d ]]; then
    exitcode=1
    failed=$[failed + 1]
    printf 'Diff at line: %s. query: %s\n' $i "$query" | log | ellipsis
    printf 'Response: %s\n' "$resp" | log >/dev/null
    printf 'Expected: %s\n' "$exp" | log >/dev/null
    diff -u <(echo $expSan | jq -S .) <(echo $respSan | jq -S .) | log
  else
    passed=$[passed + 1]
  fi
done <<< "$(paste ./responses ./expected ./queries.sh)"

# test report
echo "Passed: $passed  Failed: $failed"
if (($exitcode > 0)); then
  echo "Some test have failed. See more in ./log";
  echo "Hint: you can copy ./responses over ./expected to have a fresh snapshot.";
fi

exit $exitcode
