#!/usr/local/bin/python3

import argparse
import datetime


def parse_command_line_args():

  parser = argparse.ArgumentParser(description = "Say hello, and spill the beans on a secret")

  parser.add_argument('-n', '--name', default = None,
                      help = 'Your name')

  args = parser.parse_args()
  return args



if __name__ == '__main__':

  args = parse_command_line_args()

  # say hello
  if args.name is not None:
    print("Howdy {}!".format(args.name))
  else:
    print("Howdy partner!")

  # print the date and time
  print("It is {}.".
        format(datetime.datetime.now().strftime("%H:%M on %A, %B %d, %Y")))

  # print the secret
  try:
    with open('/secrets/my-mounted-secret.txt', 'r') as f:
      secret = f.read()
    print("The secret is: {}".format(secret))

  except Exception as e:
    print("I couldn't read the secret :(")
    print("Exception: {}".format(e))
