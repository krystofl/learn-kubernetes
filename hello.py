#!/usr/local/bin/python3

import datetime

if __name__ == '__main__':

  print("Howdy partner! It is {}.".
        format(datetime.datetime.now().strftime("%H:%M on %A, %B %d, %Y")))
