import requests
import pandas as pd
from bs4 import BeautifulSoup

# url ="http://sportsdatabase.com/nhl/query?output=default&sdql=+season%2C+t%3Agame+number%2C+to%3Agame+number%2C+t%3Aabbreviation%2C+to%3Aabbreviation%2C+t%3Arest%2C+to%3Arest%2C+t%3Agoals%2C+to%3Agoals%2C+t%3Aline%2C+to%3Aline%2C+t%3Awins%2C+t%3Alosses%2C+to%3Awins%2C+to%3Alosses%2C+t%3Amatchup+wins%2C+t%3Amatchup+losses%2C+t%3Aperiod+scores%2C+to%3Aperiod+scores%2C+H%40season+%3E+2005+and+playoffs+%3D+0&submit=++S+D+Q+L+%21++"
url = "http://sportsdatabase.com/nhl/query?output=default&sdql=season%2C+t%3Agame+number%2C+to%3Agame+number%2C+t%3Aabbreviation%2C+to%3Aabbreviation%2C+t%3Arest%2C+to%3Arest%2C+t%3Agoals%2C+to%3Agoals%2C+shoot+out%2C+t%3Aline%2C+to%3Aline%2C+t%3Awins%2C+to%3Awins%2C+t%3Alosses%2C+to%3Alosses%2C+t%3Amatchup+wins%2C+t%3Amatchup+losses%2C+H%2C+t%3Aperiod+scores%5B0%5D+as+t.period.scores0%2C+t%3Aperiod+scores%5B1%5D+as+t.period.scores1%2C+t%3Aperiod+scores%5B2%5D+as+t.period.scores2%2C+t%3Aperiod+scores%5B3%5D+as+t.period.scores3%2C+t%3Aperiod+scores%5B4%5D+as+t.period.scores4%2C++to%3Aperiod+scores%5B0%5D+as+to.period.scores0%2C+to%3Aperiod+scores%5B1%5D+as+to.period.scores1%2C+to%3Aperiod+scores%5B2%5D+as+to.period.scores2%2C+to%3Aperiod+scores%5B3%5D+as+to.period.scores3+%2C+to%3Aperiod+scores%5B4%5D+as+to.period.scores4+%40+season+%3E+2005+and+playoffs+%3D+0&submit=++S+D+Q+L+%21++"
headers = {'User-Agent':'Mozilla/5.0'}
response = requests.get(url, headers=headers)
soup = BeautifulSoup(response.text,'lxml')
table = soup.find_all('table')[3]


n_columns = 0
n_rows=0
column_names = []
row_marker = 0

# Find number of rows and columns
# we also find the column titles if we can
for row in table.find_all('tr'): 
    
    # Determine the number of rows in the table
    td_tags = row.find_all('td')
    if len(td_tags) > 0:
        n_rows+=1
        if n_columns == 0:
            # Set the number of columns for our table
            n_columns = len(td_tags)
            
    # Handle column names if we find them
    th_tags = row.find_all('th') 
    if len(th_tags) > 0 and len(column_names) == 0:
        for th in th_tags:
            column_names.append(th.get_text().strip())

# Safeguard on Column Titles
if len(column_names) > 0 and len(column_names) != n_columns:
    raise Exception("Column titles do not match the number of columns")

columns = column_names if len(column_names) > 0 else range(0,n_columns)
df = pd.DataFrame(columns = columns,index= range(0,n_rows))
row_marker = 0
for row in table.find_all('tr'): 
    column_marker = 0
    columns = row.find_all('td')
    for column in columns:
        df.iat[row_marker,column_marker] = column.get_text().strip()
        column_marker += 1
    if len(columns) > 0:
        row_marker += 1
# Convert to float if possible
for col in df:
    try:
        df[col] = df[col].astype(float)
    except ValueError:
        pass
df.to_csv('/mnt/c/Users/geoff/nhl-predictions/nhldata20052017.csv',index=False)
