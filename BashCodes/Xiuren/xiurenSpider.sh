#!/bin/sh
###http://www.xiuren.org spider

wget --timestamping --user-agent="Googlebot/2.1 (+http://www.googlebot.com/bot.html)" --recursive --level=inf --no-remove-listing --domains=www.xiuren.org --no-parent http://www.xiuren.org
