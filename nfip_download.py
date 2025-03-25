import requests
import time
import json
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

# set constant parameters
BASE_URL = 'https://www.fema.gov/api/open/v2/'
FORMAT_PARAM = '$format=json'
METADATA_PARAM = '&$metadata=off'
FILTER_PARAM = '&$filter=countyCode%20eq%20%27{}%27'
SKIP_PARAM = '&$skip={}'
TOP_PARAM = '&$top=10000'

def get_api_url(dataset, county_fips, skip):
    """Generate the API URL for the given dataset, county FIPS, and skip value."""
    url_base = f'{BASE_URL}FimaNfip{dataset.capitalize()}?'
    return f'{url_base}{FORMAT_PARAM}{METADATA_PARAM}{FILTER_PARAM}{SKIP_PARAM}{TOP_PARAM}'.format(county_fips, skip)

def make_request(url):
    """Make an HTTP request and handle potential errors."""
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logger.error(f"Error making request to {url}: {e}")
        return None

def download_data(dataset, county_fips):
    """
    Download FEMA NFIP policies or claims data for a specific county and save it to a JSON file.

    Parameters:
    - county_fips (str): County FIPS code.
    - dataset (str): Either 'policies' or 'claims'.

    Returns:
    - None
    """
    if dataset not in {'policies', 'claims'}:
        logger.error(f"Invalid dataset '{dataset}' provided. Pass either 'policies' or 'claims'.")
        raise ValueError("Invalid dataset. Pass either 'policies' or 'claims'.")

    if not isinstance(county_fips, str):
        logger.error(f"Invalid county FIPS code {county_fips}. It must be a string.")
        raise ValueError("County FIPS code must be passed as a string.")

    result_list = []
    skip = 0

    logger.info(f"Starting to download {dataset} data for county FIPS: {county_fips}")

    while True:
        logger.debug(f"Requesting data with skip={skip}")

        # make HTTP request and handle JSON response
        url = get_api_url(dataset, county_fips, skip)
        data = make_request(url)

        dataset_name = f"FimaNfip{dataset.capitalize()}"

        # check if the response is empty or contains an error
        if not data or dataset_name not in data:
            logger.warning(f"No data returned for {dataset_name} for county {county_fips} at skip={skip}. Stopping download.")
            break

        # process JSON data and extend the result list
        result_list.extend(data[dataset_name])

        rows = len(data[dataset_name])
        logger.debug(f'Fetched {rows} rows.')

        if rows < 10000:
            logger.info(f"Chunk is less than 10,000 rows returned, finishing download.")
            break

        skip += 10000
        time.sleep(5)  # avoid rate limiting

    logger.info(f"Download completed. Total rows fetched: {len(result_list)}")

    # write the result list to a JSON file
    output_filename = f"data/{dataset}-{county_fips}.json"
    try:
        with open(output_filename, 'w') as json_file:
            json.dump(result_list, json_file, indent=2)
        logger.info(f"Data saved to {output_filename}")
    except Exception as e:
        logger.error(f"Error saving data to file {output_filename}: {e}")
