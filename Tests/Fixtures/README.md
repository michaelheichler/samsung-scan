# Scanner fixtures

These two files hold the `scanimage -A` option listing of the Samsung C48x at `xerox_mfp:tcp 192.0.2.10`. The checks parse them in place of a live scanner.

The captures came from a real C48x, and the maintainers replaced its network address with 192.0.2.10, an address reserved for documentation (RFC 5737).

## Files

1. `c48x-flatbed.txt` holds the listing with the flatbed as the source.
2. `c48x-adf.txt` holds the listing with the document feeder (ADF) as the source.

## What changes with the source

The maximum scan height depends on the source.

1. The flatbed allows a height up to 297.18 mm.
2. The feeder allows a height up to 355.6 mm.

Both sources allow a width up to 216.069 mm, and both report 297.18 mm as the current height. The checks read the range maximum, so the app offers Legal paper only on the feeder.

## Commands

Both files hold the standard output of these commands:

```sh
scanimage -d 'xerox_mfp:tcp 192.0.2.10' -A
scanimage -d 'xerox_mfp:tcp 192.0.2.10' --source=ADF -A
```

To refresh the files, run the commands against your own scanner address, replace that address with 192.0.2.10, and keep every other byte of the output.
