#!/usr/bin/env python3

import localizable
import os
import re
import argparse

parser = argparse.ArgumentParser()
parser.add_argument(
    '--translations_dir', type=str, required=True,
    help='directory of translations from crowdin'
)


def main():
    args = parser.parse_args()

    translations_basedir = args.translations_dir

    # commonly used invalid matches
        # %2$s
    invalid_match = re.compile(r'%\d*\$s')

    # realistic likely valid matches:
        # %1$.5f
        # %@
        # %3$@
        # %.5f
    valid_match = re.compile(r'%\d\$\.\df|%@|%\d\$@|%\.\df')

    for language in os.listdir(translations_basedir):
        if language in ["iNaturalist", ".DS_Store"]:
            # non-language directories that ended up in the root of 
            # the crowdin export
            continue

        lang_basedir = os.path.join(translations_basedir, language)
        lang_iosdir = os.path.join(lang_basedir, "iOS")

        for stringsfile in os.listdir(lang_iosdir):
            sf_path = os.path.join(lang_iosdir, stringsfile)
            strings = localizable.parse_strings(filename=sf_path)
            for string in strings:
                # look for invalids
                invalid_matches = re.findall(invalid_match, string["value"])
                if invalid_matches:
                    print(sf_path)
                    print(string["key"])
                    print(string["value"])
                    print()

                # assert matching valid matches in key and vlaue
                valid_key_matches = re.search(valid_match, string["key"])
                #if valid_key_matches:
                #    print(valid_key_matches)
                #print(string)
                #if valmatches:
                #    print(valmatches)

if __name__ == "__main__":
    main()

