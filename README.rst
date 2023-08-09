
Introduction
============

This script provides a framework for remotely switching devices on and off, like
USB ports or WiFi sockets. These are the most common usage examples::

        $ remote_power --help
        $ remote_power list
        $ remote_power socket1 on
        $ remote_power socket1 reset
        $ remote_power socket1 off
        $ remote_power all off


Implementation Example
======================

There are detailed implementations examples contained in this repo. But below
is an overview of what an implementation has to look like. All that has to be
done, is to define the ``send_request()`` function and a mapping from
human-readable names to device addresses::


  +--------------------------------------------------+
  |              File: remote_power                  |
  +----+---------------------------------------------+
  |  1 | #!/bin/sh                                   |
  |  2 |                                             |
  |  3 | send_request() {                            |
  |  4 |         local addr="$1"                     |
  |  5 |         local cmd="$2"                      |
  |  6 |                                             |
  |  7 |         case ${cmd} in                      |
  |  8 |                on)     power_on;;           |
  |  9 |                off)    power_off;;          |
  | 10 |                status) get_status;;         |
  | 11 |         esac                                |
  | 12 |                                             |
  | 13 |         if [ error ]; then                  |  The error message will
  | 14 |                 echo "ERROR such and such"  |  be caught and printed
  | 15 |                 return 1                    |  by the framework
  | 16 |         fi                                  |
  | 17 |                                             |
  | 18 |         if [ power_is_on ]; then            |  It's important to echo
  | 19 |                 echo on                     |  the current state of
  | 20 |         else                                |  the device. An
  | 21 |                 echo off                    |  unexpected state makes
  | 22 |         fi                                  |  the script fail.
  | 23 | }                                           |
  | 24 |                                             |
  | 25 | . $(dirname $0)/_remote_common.sh           |
  +----+---------------------------------------------+


  +---------------------------------------------------+
  |              File: remote_power.cfg               |
  +----+----------------------------------------------+
  |  1 | 192.168.0.11 socket1                         |
  |  2 | 192.168.0.12 socket2                         |
  |  3 | 192.168.0.13 socket3                         |
  +----+----------------------------------------------+

Hereby the command ``${2}`` is either ``on``, ``off`` or ``status``.  The value
echoed by ``send_request()`` shall be ``on`` or ``off``.

As for remote_power.cfg, the fist column, ``192.168.0.XX``, is used as the low
level address argument for ``send_request()``. The second column is used as an
easy-to-remember command line argument for the remote_power script.
