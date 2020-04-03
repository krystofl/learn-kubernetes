#!/usr/local/bin/python3

import datetime

if __name__ == '__main__':

  print("Howdy partner! It is {}.".
        format(datetime.datetime.now().strftime("%H:%M on %A, %B %d, %Y")))

  try:
    with open('my-mounted-secret.txt', 'r') as f:
      secret = f.read()
    print("The secret is: {}".format(secret))

  except Exception as e:
    print("I couldn't read the secret :(")
    print("Exception: {}".format(e))
