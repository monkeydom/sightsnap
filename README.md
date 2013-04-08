# sightsnap - an OS X command line utility to snap webcam images

## Design Goals
* no memory leaks - suitable for long time time lapsing
* add text overlays or timestamps

## Requirements
* Mac OS X 10.8 or higher, 64-bit only

## Download Binary
* [sightsnap v0.4](http://cl.ly/O88U)

## License

* [MIT](http://www.opensource.org/licenses/mit-license.php)

## Usage

<pre>
sightsnap v0.4 by @monkeydom
usage: sightsnap [options] [output[.jpg|.png]] [options]

Default output filename is signtsnap.jpg - if no extension is given, jpg is used.
If you add directory in front, it will be created.
  -l, --listDevices         List all available video devices and their formats.
  -d, --device &lt;device>     Use this &lt;device>. First partial case-insensitive
                            name match is taken.
  -t, --time &lt;delay>        Takes a frame every &lt;delay> seconds and saves it as
                            outputfilename-XXXXXXX.jpg continuously.
  -z, --startAtZero         Start at frame number 0 and overwrite - otherwise start
                            with next free frame number. Time mode only.
  -k, --skipframes &lt;n>      Skips &lt;n> frames before taking a picture. Gives cam
                            warmup time. (default is 2, frames are @6fps)
  -j, --jpegQuality &lt;q>     JPEG image quality from 0.0 to 1.0 (default is 0.8).
  -x, --maxwidth &lt;w>        If image is wider than &lt;w> px, scale it down to fit.
  -y, --maxheight &lt;h>       If image is higher than &lt;h> px, scale it down to fit.
                            When &lt;w> and &lt;h> are given, the camera format used is optimized.
  -p, --timeStamp           Adds a Timestamp to the captured image.
  -T, --title &lt;text>        Adds &lt;text> to the upper right of the image.
  -C, --comment &lt;text>      Adds &lt;text> to the lower left of the image.
  -f, --fontName &lt;font>     Postscript font name to use. Use FontBook.app->Font Info
                            to find out about the available fonts on your system
                            (default is 'HelveticaNeue-Bold')
  -s, --fontSize &lt;size>     Font size for timestamp in &lt;size> px. (default is 40)
  -h, --help                Shows this help.

To make timelapse videos use ffmpeg like this:
  ffmpeg -i 'sightsnap-%07d.jpg' sightsnap.mp4</pre>

## Acknowledgements
* uses [ArgumentParser](https://github.com/NSError/ArgumentParser)

## Created by
@monkeydom [twitter](http://twitter.com/monkeydom) [adn](http://app.net/monkeydom)