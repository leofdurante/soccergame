"""
Batch player image downloader for Fanáticos iOS.

This script:
- Uses the Wikimedia Commons API (no scraping).
- Searches for each player by name.
- Downloads the first valid image result.
- Resizes it to a maximum width of 500px (keeping aspect ratio).
- Converts to JPG if necessary.
- Saves all files into ./downloaded_players/ using lowercase snake_case filenames.
"""

from __future__ import annotations

import logging
import re
from io import BytesIO
from pathlib import Path
from typing import Optional

import requests
from PIL import Image
from requests import RequestException


# Base configuration
WIKIMEDIA_API_URL = "https://commons.wikimedia.org/w/api.php"
OUTPUT_DIR = Path(__file__).parent / "downloaded_players"
MAX_WIDTH = 500
REQUEST_TIMEOUT_SECONDS = 15

# Be a good API citizen and identify the client
HTTP_HEADERS = {
    "User-Agent": "FanaticosPlayerImageDownloader/1.0 (https://example.com)"
}


PLAYER_NAMES = [
    "Lionel Messi",
    "Cristiano Ronaldo",
    "Neymar",
    "Kylian Mbappé",
    "Kevin De Bruyne",
    "Erling Haaland",
    "Luka Modrić",
    "Robert Lewandowski",
    "Karim Benzema",
    "Vinícius Júnior",
    "Mohamed Salah",
    "Harry Kane",
    "Ronaldinho",
    "Ronaldo Nazário",
    "Zinedine Zidane",
    "Thierry Henry",
    "Andrés Iniesta",
    "Xavi",
    "Kaká",
    "David Beckham",
]


def configure_logging() -> None:
    """Configure basic console logging for clear, readable output."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )


logger = logging.getLogger(__name__)


def to_snake_case(name: str) -> str:
    """
    Convert a player name into a lowercase snake_case string suitable for filenames.

    Example:
        "Lionel Messi" -> "lionel_messi"
    """
    normalized = name.strip().lower()
    # Replace any group of non-alphanumeric characters with a single underscore
    normalized = re.sub(r"[^a-z0-9]+", "_", normalized)
    # Collapse multiple underscores and trim leading/trailing ones
    normalized = re.sub(r"_+", "_", normalized).strip("_")
    return normalized or "player"


def ensure_output_dir_exists() -> None:
    """Create the output directory if it does not already exist."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


def ensure_unique_filename(base_name: str) -> Path:
    """
    Ensure the image filename is unique in the output directory.

    Handles potential duplicate filenames by appending a numeric suffix.
    Example:
        "lionel_messi.jpg", "lionel_messi_1.jpg", "lionel_messi_2.jpg", ...
    """
    candidate = OUTPUT_DIR / f"{base_name}.jpg"
    counter = 1

    while candidate.exists():
        candidate = OUTPUT_DIR / f"{base_name}_{counter}.jpg"
        counter += 1

    return candidate


def search_player_image(player_name: str) -> Optional[dict]:
    """
    Use the Wikimedia Commons API to find the first image for a given player.

    Returns a dictionary containing imageinfo (including the original URL) or None
    if no suitable image is found.
    """
    logger.info("Searching Wikimedia Commons for '%s'...", player_name)

    # Query the API for image pages (namespace 6) that match the player name
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": player_name,
        "gsrlimit": 1,
        "gsrnamespace": 6,  # namespace 6 = File (images, media)
        "prop": "imageinfo",
        "iiprop": "url|mime|size",
    }

    try:
        response = requests.get(
            WIKIMEDIA_API_URL,
            params=params,
            headers=HTTP_HEADERS,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
    except RequestException as exc:
        logger.error("Network error while searching for '%s': %s", player_name, exc)
        return None

    data = response.json()
    pages = data.get("query", {}).get("pages")

    if not pages:
        logger.warning("No image pages found for '%s'. Skipping.", player_name)
        return None

    # Take the first page returned by the generator
    page = next(iter(pages.values()))
    imageinfo_list = page.get("imageinfo")

    if not imageinfo_list:
        logger.warning("Image page found but no imageinfo for '%s'. Skipping.", player_name)
        return None

    imageinfo = imageinfo_list[0]

    if "url" not in imageinfo:
        logger.warning("Imageinfo for '%s' does not include a URL. Skipping.", player_name)
        return None

    logger.info("Found image for '%s': %s", player_name, imageinfo["url"])
    return imageinfo


def download_image(image_url: str, player_name: str) -> Optional[Image.Image]:
    """
    Download the image from the given URL and return it as a Pillow Image.

    Handles network errors and invalid image data gracefully.
    """
    logger.info("Downloading image for '%s' from %s", player_name, image_url)

    try:
        response = requests.get(
            image_url,
            headers=HTTP_HEADERS,
            timeout=REQUEST_TIMEOUT_SECONDS,
        )
        response.raise_for_status()
    except RequestException as exc:
        logger.error("Network error while downloading image for '%s': %s", player_name, exc)
        return None

    try:
        image = Image.open(BytesIO(response.content))
        image.load()  # Ensure the image is fully loaded into memory
    except Exception as exc:
        logger.error("Failed to open downloaded image for '%s': %s", player_name, exc)
        return None

    return image


def prepare_image_for_jpeg(image: Image.Image) -> Image.Image:
    """
    Convert the image to an RGB mode suitable for saving as JPEG.

    Handles images with transparency or palette-based modes by converting them.
    """
    if image.mode in ("RGBA", "LA", "P"):
        # Convert images with alpha or palettes to plain RGB
        image = image.convert("RGB")
    elif image.mode != "RGB":
        # Normalize any other modes to RGB
        image = image.convert("RGB")

    return image


def resize_image_if_needed(image: Image.Image) -> Image.Image:
    """
    Resize the image to ensure its width does not exceed MAX_WIDTH.

    Keeps the aspect ratio by computing the corresponding height.
    """
    width, height = image.size

    if width <= MAX_WIDTH:
        # No resizing needed
        return image

    scale = MAX_WIDTH / float(width)
    new_height = int(height * scale)

    logger.info(
        "Resizing image from %dx%d to %dx%d",
        width,
        height,
        MAX_WIDTH,
        new_height,
    )

    # Use a high-quality resampling filter for better downscaling
    return image.resize((MAX_WIDTH, new_height), Image.LANCZOS)


def process_player(player_name: str) -> None:
    """
    Complete end-to-end processing for a single player:
    - Search Wikimedia Commons for an image.
    - Download the original image.
    - Resize to the maximum allowed width.
    - Convert to JPEG (if needed).
    - Save using a snake_case filename.
    """
    logger.info("----- Processing player: %s -----", player_name)

    imageinfo = search_player_image(player_name)
    if not imageinfo:
        # Search already logged a warning; nothing more to do
        return

    image_url = imageinfo.get("url")
    if not image_url:
        logger.warning("Imageinfo for '%s' had no URL. Skipping.", player_name)
        return

    image = download_image(image_url, player_name)
    if image is None:
        # Download step already logged the error
        return

    # Normalize the image mode for JPEG output
    image = prepare_image_for_jpeg(image)

    # Resize while preserving aspect ratio
    image = resize_image_if_needed(image)

    # Build a safe, snake_case filename
    base_name = to_snake_case(player_name)
    output_path = ensure_unique_filename(base_name)

    # Save as JPEG regardless of original format
    try:
        logger.info("Saving image for '%s' as %s", player_name, output_path.name)
        image.save(output_path, format="JPEG", quality=90)
    except Exception as exc:
        logger.error("Failed to save image for '%s' to %s: %s", player_name, output_path, exc)
        return

    logger.info("Successfully processed '%s'. Saved to %s", player_name, output_path)


def main() -> None:
    """
    Main entry point.

    Iterates over the predefined player list and processes each one in turn.
    """
    configure_logging()
    ensure_output_dir_exists()

    logger.info("Starting batch download of player images...")
    logger.info("Images will be saved in: %s", OUTPUT_DIR)

    for player in PLAYER_NAMES:
        process_player(player)

    logger.info("Batch image download completed.")


if __name__ == "__main__":
    main()

