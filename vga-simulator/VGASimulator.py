#!/usr/bin/env python3
'''VGASimulator.py - Pedro José Pereira Vieito © 2016
  View VGA output from a VHDL simulation.

  Ported from VGA Simulator:
  https://github.com/MadLittleMods/vga-simulator
  by Eric Eastwood <contact@ericeastwood.com>

  More info about how to generate VGA output from VHDL simulation here:
  http://ericeastwood.com/blog/8/vga-simulator-getting-started

Usage:
  VGASimulator.py <file> [<frames>]

Options:
  -h, --help    Show this help
'''

import sys
import os
import re
import struct
from PIL import Image
from docopt import docopt

__author__ = "Pedro José Pereira Vieito"
__email__ = "pvieito@gmail.com"


def time_conversion(unit_from, unit_to, value):
    # convert between the following:
    # fs, ps, ns, us, ms, sec, min, hr
    unit_dict = {
        "fs": .000000000000001,
        "ps": .000000000001,
        "ns": .000000001,
        "us": .000001,
        "ms": .001,
        "s": 1,
        "sec": 1,
        "min": 60,
        "hr": 3600,
    }
    return unit_dict[unit_from] / unit_dict[unit_to] * value


def bin_to_color(binary):
    # Returns a value 0-255 corresponding to the bit depth
    # of the binary number and the value.
    # This is why your rgb values need to be padded to the full bit depth
    return int(int(binary, 2) / int("1" * len(binary), 2) * 255)


def render_vga(file):

    vga_file = open(file, 'r')

    # From: http://tinyvga.com/vga-timing/
    res_x = 800
    res_y = 600

    # Pixel Clock: ~20 ns, 50 MHz
    pixel_clk = 20e-9

    back_porch_x = 64
    back_porch_y = 23

    h_counter = 0
    v_counter = 0

    back_porch_x_count = 0
    back_porch_y_count = 0

    last_hsync = -1
    last_vsync = -1

    time_last_line = 0      # Time from the last line
    time_last_pixel = 0     # Time since we added a pixel to the canvas

    frame_count = 0

    vga_output = None

    print('[ ] VGA Simulator')
    print('[ ] Resolution:', res_x, '×', res_y)

    for vga_line in vga_file:

        pattern = re.compile("^([0-9]+) (fs|ps|ns|us|ms|sec|min|hr): "
                             "(0|1) (0|1) ((?:0|1)+) ((?:0|1)+) "
                             "((?:0|1)+)")
        match = pattern.match(vga_line)

        if (match):

            time = time_conversion(match.group(2), "sec", int(match.group(1)))
            hsync = int(match.group(3))
            vsync = int(match.group(4))
            red = bin_to_color(match.group(5))
            green = bin_to_color(match.group(6))
            blue = bin_to_color(match.group(7))

            time_last_pixel += time - time_last_line

            if last_hsync == 0 and hsync == 1:
                h_counter = 0

                # Move to the next row, if past back porch
                if back_porch_y_count >= back_porch_y:
                    v_counter += 1

                # Increment this so we know how far we are
                # after the vsync pulse
                back_porch_y_count += 1

                # Set this to zero so we can count up to the actual
                back_porch_x_count = 0

                # Sync on sync pulse
                time_last_pixel = 0

            if last_vsync == 0 and vsync == 1:

                # Show frame or create new frame
                if vga_output:
                    vga_output.show("VGA Output")
                else:
                    vga_output = Image.new('RGB', (res_x, res_y), (0, 0, 0))

                if frame_count < frames_limit or frames_limit == -1:
                    print("[+] VSYNC: Decoding frame", frame_count)

                    frame_count += 1
                    h_counter = 0
                    v_counter = 0

                    # Set this to zero so we can count up to the actual
                    back_porch_y_count = 0

                    # Sync on sync pulse
                    time_last_pixel = 0

                else:
                    print("[ ]", frames_limit, "frames decoded")
                    exit(0)

            if vga_output and vsync:

                # Add a tolerance so that the timing doesn't have to be bang on
                tolerance = 5e-9
                if time_last_pixel >= (pixel_clk - tolerance) and \
                   time_last_pixel <= (pixel_clk + tolerance):
                    # Increment this so we know how far we are
                    # After the hsync pulse
                    back_porch_x_count += 1

                    # If we are past the back porch
                    # Then we can start drawing on the canvas
                    if back_porch_x_count >= back_porch_x and \
                       back_porch_y_count >= back_porch_y:

                        # Add pixel
                        if h_counter < res_x and v_counter < res_y:
                            vga_output.putpixel((h_counter, v_counter),
                                                (red, green, blue))

                    # Move to the next pixel, if past back porch
                    if back_porch_x_count >= back_porch_x:
                        h_counter += 1

                    # Reset time since we dealt with it
                    time_last_pixel = 0

            last_hsync = hsync
            last_vsync = vsync
            time_last_line = time

args = docopt(__doc__)
file = args['<file>']

if args['<frames>']:
    frames_limit = int(args['<frames>'])
else:
    frames_limit = -1

vga_extensions = ['.vga', '.txt']

if os.path.isfile(file) and os.path.splitext(file)[1] in vga_extensions:
    render_vga(file)
    print("[ ]", "Final frame decoded")
else:
    print('[x] VGA output file (.vga) not found.')
