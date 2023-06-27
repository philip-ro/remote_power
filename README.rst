
Introduction
============

This script provides a framework for remotely switching devices on and off, like
USB ports or WiFi sockets. These are the most common usage examples::

        $ remote_usb --help
        $ remote_usb list
        $ remote_usb uart-2 on
        $ remote_usb uart-2 reset
        $ remote_usb uart-2 off
        $ remote_usb all off


Implementation Example
======================

There are two implementations examples contained in this repo. But below is an
overview of what an implementation has to look like. All that has to be done, is
to define the ``send_request()`` function and a mapping from human-readable
names to device addresses::


  +--------------------------------------------------+
  |              File: remote_usb                    |
  +----+---------------------------------------------+
  |  1 | #!/bin/sh                                   |
  |  2 |                                             |
  |  3 | send_request() {                            |
  |  4 |         local addr="$1"                     |
  |  5 |         local cmd="$2"                      |
  |  6 |                                             |
  |  7 |         switch_usb ${addr} ${cmd}           |
  |  8 |                                             |
  |  9 |         if [ error ]; then                  |  The error message will
  | 10 |                 echo "ERROR such and such"  |  be caught and printed
  | 11 |                 return 1                    |  by the framework
  | 12 |         fi                                  |
  | 13 |                                             |
  | 14 |         if [ usb_is_on ]; then              |  It's important to echo
  | 15 |                 echo on                     |  the current state of
  | 16 |         else                                |  the device. An
  | 17 |                 echo off                    |  unexpected state makes
  | 18 |         fi                                  |  the script fail.
  | 19 | }                                           |
  | 20 |                                             |
  | 21 | . $(dirname $0)/_remote_common.sh           |
  +----+---------------------------------------------+


  +---------------------------------------------------+
  |              File: remote_usb.cfg                 |
  +----+----------------------------------------------+
  |  1 | 6-1.4p1 uart-1                               |
  |  2 | 6-1.4p2 uart-2                               |
  |  3 | 6-1.4p3 phone                                |
  +----+----------------------------------------------+

Hereby the command ``${2}`` can either be ``on``, ``off`` or ``status``,
likewise the value echoed by ``send_request()``.

As for remote_usb.cfg, the fist column, ``6-1.4pX``, is used as the low level
address argument for ``send_request()``. The second column is used as an
easy-to-remember command line argument for the remote_usb script.
