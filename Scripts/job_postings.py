import requests
from bs4 import BeautifulSoup
import pandas as pd

def scrape_indeed_jobs(query, locations):
    base_url = 'https://www.indeed.com/jobs'
    job_data = []

    for location in locations:
        params = {
            'q': query,
            'l': location
        }
        response = requests.get(base_url, params=params)
        soup = BeautifulSoup(response.content, 'html.parser')
        job_listings = soup.find_all('div', class_='jobsearch-SerpJobCard')

        for job_listing in job_listings:
            title = job_listing.find('a', class_='jobtitle').text.strip()
            company = job_listing.find('span', class_='company').text.strip()
            description = job_listing.find('div', class_='summary').text.strip()
            location = job_listing.find('span', class_='location').text.strip()
            salary = job_listing.find('span', class_='salaryText').text.strip()

            job_data.append({
                'Title': title,
                'Company': company,
                'Description': description,
                'Location': location,
                'Salary': salary
            })

    df = pd.DataFrame(job_data)
    df.to_excel('E:\\Python\\financial_analyst_jobs.xlsx', index=False)
    print("Scraping complete. Data saved to financial_analyst_jobs.xlsx")

# Example usage
query = "financial analyst"
locations = ["New York, NY", "Orange County, CA"]
scrape_indeed_jobs(query, locations)
