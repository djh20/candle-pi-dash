## Libraries ##
import enum
import os
import shutil
import time
import math
import requests
import json
###############

## Config ##
API_URL = "https://maps.mail.ru/osm/tools/overpass/api/interpreter"
API_REQUEST_DATA = """
[out:json];
way[maxspeed]({0}, {1}, {2}, {3});
out geom;
"""

TILE_IMG_URL = "https://a.tile.openstreetmap.org/{0}/{1}/{2}.png"
TILE_FILE_NAME = "{0}-{1}-{2}"

SCRIPT_DIR = os.path.dirname(__file__)
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "../assets/generated/map")

ZOOM = 15
AREAS = [
    # Lat, Lng, Tile range (0 = 1 tile, 1 = 9 tiles, 2 = 16 tiles)
    [48.85846892231636, 2.294438384556573, 2] # Example (Eiffel Tower)
]
###############

## Functions ##
def worldToTile(lat_deg, lng_deg, zoom):
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    xtile = int((lng_deg + 180.0) / 360.0 * n)
    ytile = int((1.0 - math.asinh(math.tan(lat_rad)) / math.pi) / 2.0 * n)
    return (xtile, ytile)

def tileToWorld(xtile, ytile, zoom):
    n = 2.0 ** zoom
    lng_deg = xtile / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
    lat_deg = math.degrees(lat_rad)
    return (lat_deg, lng_deg)
###############

## Execution ##
output_dir_exists = os.path.exists(OUTPUT_DIR)

# Delete the output directory if it already exists.
if output_dir_exists:
    answer = input("Would you like to delete the existing map? (y/n): ").lower()
    if answer == "y":
        shutil.rmtree(OUTPUT_DIR)

else:
    # Create the output directory.
    os.makedirs(OUTPUT_DIR, exist_ok=True)

# Iterate through each area defined in the config.
for i, area in enumerate(AREAS):
    origin_lat, origin_lng, radius = area[0], area[1], area[2]
    origin_tile_x, origin_tile_y = worldToTile(origin_lat, origin_lng, ZOOM)

    for x in range(-radius, radius+1):
        for y in range(-radius, radius+1):
            # Get the current tile position by offsetting from the origin tile.
            tile_x, tile_y = (origin_tile_x + x, origin_tile_y + y)

            print("Tile {0}-{1}-{2}".format(ZOOM, tile_x, tile_y))
            
            # Construct the tile image url and path.
            img_url = TILE_IMG_URL.format(ZOOM, tile_x, tile_y)
            img_path = os.path.join(
                OUTPUT_DIR, 
                TILE_FILE_NAME.format(ZOOM, tile_x, tile_y) + ".png"
            )

            # Only download the img file if it doesn't exist yet.
            if not os.path.exists(img_path):
                # Download the tile image.
                print("- Downloading img from {0}".format(img_url))
                
                img_response = requests.get(
                    img_url,
                    headers = {
                        # This is required otherwise the request gets blocked.
                        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
                    }
                )

                # Save the tile image in the output folder.
                file = open(img_path, "wb")
                file.write(img_response.content)
                file.close()
            
            # Construct the file path for ways data to be stored in.
            ways_path = os.path.join(
                OUTPUT_DIR, 
                TILE_FILE_NAME.format(ZOOM, tile_x, tile_y) + ".json"
            )

            # Only download the ways data if it doesn't exist yet.
            if not os.path.exists(ways_path):
                # Calculate the top-left and bottom-right positions of the tile.
                tl_lat, tl_lng = tileToWorld(tile_x, tile_y, ZOOM)
                br_lat, br_lng = tileToWorld(tile_x+1, tile_y+1, ZOOM)
                
                # Calculate the min and max for lat and lng. This is required for the API call.
                min_lat = min(tl_lat, br_lat)
                min_lng = min(tl_lng, br_lng)
                max_lat = max(tl_lat, br_lat)
                max_lng = max(tl_lng, br_lng)

                # Make the request.
                print("- Fetching ways data from {0}".format(API_URL))

                ways_response = requests.get(
                    API_URL,
                    params = {
                        "data": API_REQUEST_DATA.format(min_lat, min_lng, max_lat, max_lng)
                    }
                )
                
                # Parse the json data into a python object.
                ways = json.loads(ways_response.content).get("elements")
                
                # Only include necessary data for each way to save space.
                for i, way in enumerate(ways):
                    ways[i] = {
                        "geometry": way.get("geometry"),
                        "tags": {
                            "name": way.get("tags").get("name"),
                            "maxspeed": way.get("tags").get("maxspeed")
                        }
                    }
                    
                file = open(ways_path, "w")
                json.dump(ways, file)
                file.close()

                # Small delay to reduce rate of requests to API.
                time.sleep(0.25)

            print()
###############