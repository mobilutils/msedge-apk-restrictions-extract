# msedge-apk-restrictions-extract
I need, for a colleague of mine,
to keep track of Microsoft Edge APK restrictions/diff/changes
This by downloading edge apk, and extract it's app_restrictions.xml.


Install dependencies: pip install google-play-scraper packaging gplaydl
edge-monitor.py is handling the work (our main)
Test manually: python3 edge-monitor.py
Add to cron: 
### run every 2 days at 21h42m
42 21 */2 * * /usr/bin/python3 /path/to/edge-monitor.py
Monitor logs: tail -f ~/logs/edge-monitor.log
