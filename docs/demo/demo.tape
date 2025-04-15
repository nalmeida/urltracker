Output demo.gif
Set FontSize 16
Set LineHeight 1.6
Set Padding 18
Set Width 800
Set Height 360

Type "./urltracker https://httpbin.org/status/200"
Enter
Wait
Sleep 4

Type "clear"
Enter

Sleep .5
Type "./urltracker --list list.txt"
Enter
Wait
Sleep 4

Type "clear"
Enter

Sleep .5
Type "./urltracker https://httpbin.org/redirect/2 --verbose"
Enter
Wait
Sleep 6

Type "clear"
Enter

Sleep 2
Ctrl+C
Enter