#!/usr/bin/env python3

import os
import argparse
from pathlib import Path
from shutil import copyfile

ios_to_crowdin_lang_mappings = {
    "ar": "ar",  # arabic
    "bg": "bg",  # bulgarian
    "cs": "cs",  # czech
    "ca-ES": "ca",  # catalan
    "da": "da",  # danish
    "de": "de",  # german
    "el": "el",  # greek
    "es-MX": "es-MX",  # spanish (mexico)
    "es": "es-ES",  # spanish (spain, other)
    "fi-FI": "fi",  # finnish
    "fr": "fr",  # french
    "he": "he",  # hebrew
    "hu": "hu",  # hungarian
    "id": "id",  # indonesian
    "it": "it",  # italiano
    "ja": "ja",  # japanese
    "ko": "ko",  # korean
    "lt": "lt",  # lithuanian
    "lv": "lv",  # latvian
    "nl": "nl",  # dutch
    "nb": "nb",  # norwegian
    "pl": "pl",  # polish
    "pt-BR": "pt-BR",  # portuguese (brazil)
    "pt": "pt-BR",  # portuguese (portugal, other)
    "ro": "ro",  # romanian
    "ru": "ru",  # russian
    "si": "si-LK",  # sinhala
    "sv": "sv-SE",  # swedish
    "th": "th",  # thai
    "tr": "tr",  # turkish
    "uk": "uk",  # ukrainian
    "zh-Hans": "zh-CN",  # simplified chinese
    "zh-Hant-HK": "zh-HK",  # traditional chinese (hong kong)
    "zh-Hant-TW": "zh-TW",  # traditional chinese (taiwan)
    "zh-Hant": "zh-TW",  # traditional chinese (other)
    "kk": "kk",  # kazakh
}

parser = argparse.ArgumentParser()
parser.add_argument(
    "--translations_dir",
    type=str,
    required=True,
    help="directory of translations from crowdin",
)
parser.add_argument(
    "--inat_ios_source_dir",
    type=str,
    required=True,
    help="root directory of inaturalistios git project",
)


def main():
    args = parser.parse_args()

    for ios, crowdin in ios_to_crowdin_lang_mappings.items():
        target_dir = (
            Path(args.inat_ios_source_dir)
            .joinpath("INaturalistIOS/User Interface")
            .joinpath(ios)
            .with_suffix(".lproj")
        )
        source_dir = (
            Path(args.translations_dir)
            .joinpath(crowdin)
            .joinpath("iOS")
        )
        source_files = os.listdir(source_dir)
        for source_file in source_files:
            source_full_path = Path(source_dir).joinpath(source_file)
            target_full_path = Path(target_dir).joinpath(source_file)
            copyfile(source_full_path, target_full_path)


if __name__ == "__main__":
    main()
