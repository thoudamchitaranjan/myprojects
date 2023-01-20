#!/bin/bash
while IFS="/" read -r _word1 _null _word2 _word3 _word4 _word5 _word6 _word7 _word8 _word9
do
echo First:$_word1 Null:$_null Second:$_word2 Third:$_word3 Fourth:$_word4 Fifth:$_word5 Sixth:$_word6 Seventh:$_word7 Eighth:$_word8 Nineth:$_word9
for _counter1 in $(seq 1 9)
do
for _counter2 in $(seq 1 9)
do
echo Counter1: $_counter1 Counter2:$_counter2
echo "$_word1//$_word2/$_word3/00$_counter1/000$_counter2.jpg"
wget --no-clobber --directory-prefix="$_word2/$_word3/00$_counter1/" --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_word1//$_word2/$_word3/00$_counter1/000$_counter2.jpg"
echo "$_word1//$_word2/$_word3/00$_counter1/000$_counter2.jpg">last.txt
done
for _counter2 in $(seq 10 99)
do
echo Counter1: $_counter1 Counter2:$_counter2
echo "$_word1//$_word2/$_word3/00$_counter1/00$_counter2.jpg"
wget --no-clobber --directory-prefix="$_word2/$_word3/00$_counter1/" --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_word1//$_word2/$_word3/00$_counter1/00$_counter2.jpg"
echo "$_word1//$_word2/$_word3/00$_counter1/00$_counter2.jpg">last.txt
done
done

for _counter1 in $(seq 10 99)
do
for _counter2 in $(seq 1 9)
do
echo Counter1: $_counter1 Counter2:$_counter2
echo "$_word1//$_word2/$_word3/0$_counter1/000$_counter2.jpg"
wget --no-clobber --directory-prefix="$_word2/$_word3/0$_counter1/" --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_word1//$_word2/$_word3/0$_counter1/000$_counter2.jpg"
echo "$_word1//$_word2/$_word3/0$_counter1/000$_counter2.jpg">last.txt
done
for _counter2 in $(seq 10 99)
do
echo Counter1: $_counter1 Counter2:$_counter2
echo "$_word1//$_word2/$_word3/0$_counter1/00$_counter2.jpg"
wget --no-clobber --directory-prefix="$_word2/$_word3/0$_counter1/" --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" "$_word1//$_word2/$_word3/0$_counter1/00$_counter2.jpg"
echo "$_word1//$_word2/$_word3/0$_counter1/00$_counter2.jpg">last.txt
done
done
done<list2.txt
